require "topological_inventory-api-client"
require "topological_inventory/providers/common/operations/topology_api_client"

module TopologicalInventory
  module AnsibleTower
    module Operations
      module Core
        #
        # Terminology:
        #
        # * Workflow Template                      = ServiceOffering with extra[:type] == 'workflow_job_template'
        # * Job Template                           = ServiceOffering with extra[:type] == 'job_template'
        # * Workflow Job Template Node (or "Node") = ServiceOfferingNode
        # * Inventory                              = ServiceInventory
        #
        class ApprovalInventoriesParser
          include Logging
          include TopologyApiClient

          def initialize(root_wf_template, prompted_inventory_id = nil)
            self.root_wf_template = root_wf_template
            self.prompted_inventory = load_inventory(prompted_inventory_id)

            self.nodes                = {} # { node_id      => { template:, node:, inventory:, root_template: }}
            self.templates            = {} # { template_id  => { template:, node:, inventory: }}
            self.template_child_nodes = {} # { template_id  => Array<nodes> }
            self.template_inventories = {} # { inventory_id => { template:, inventory:} }
            self.node_inventories     = {} # { inventory_id => { node:, inventory: } }
          end

          # Entrypoint for standalone JobTemplate
          #
          # @param job_template [TopologicalInventoryApiClient::ServiceOffering]
          # @return [TopologicalInventoryApiClient::ServiceInventory, nil]
          def load_job_template_inventory(job_template)
            self.templates[job_template.id] = { :template => job_template }

            if job_template.service_inventory_id
              self.template_inventories[job_template.service_inventory_id] = { :template => job_template }
              load_inventories
            end

            compute_used_inventories(job_template).first
          end

          # Entrypoint for Workflow Template
          #
          # @param wf_template [TopologicalInventoryApiClient::ServiceOffering]
          # @return [Array<TopologicalInventoryApiClient::ServiceInventory>]
          def load_workflow_template_inventories(wf_template)
            load_nodes_and_templates(wf_template)
            load_inventories

            compute_used_inventories(wf_template)
          end

          def is_job_template?(template)
            template.extra[:type] == 'job_template'
          end

          def is_workflow_template?(template)
            template.extra[:type] == 'workflow_job_template'
          end

          private

          attr_accessor :nodes, :node_inventories, :prompted_inventory, :root_wf_template,
                        :templates, :template_child_nodes, :template_inventories

          # Loads nodes, templates and IDs of all inventories
          def load_nodes_and_templates(wf_template)
            load_child_nodes(wf_template)
            load_templates_for_nodes(wf_template)
          end

          # @param root_wf_template [TopologicalInventoryApiClient::ServiceOffering] Workflow Template
          def load_child_nodes(root_wf_template)
            topology_api_client.list_service_offering_service_nodes(root_wf_template.id).data.each do |node|
              self.nodes[node.id] = { :node          => node,
                                      :root_template => root_wf_template }

              self.template_child_nodes[root_wf_template.id].to_a << node
              self.node_inventories[node.service_inventory_id] = { :node => node } if node.service_inventory_id
            end
          end

          def load_templates_for_nodes(root_wf_template)
            child_nodes = self.template_child_nodes[root_wf_template.id].to_a
            child_node_ids = child_nodes.map(&:id)

            # TODO: node_ids should be strings, check if they aren't integers
            topology_api_client.list_service_offerings(:filter => { :eq => { :id => child_node_ids }}).data.each do |template|
              child_nodes.each do |node|
                self.nodes[node.id][:template] = template if template.id == node.service_offering_id
                self.templates[template.id] = { :template => template, :node => node }
                self.template_inventories[template.service_inventory_id] = { :template => template} if template.service_inventory_id
              end
              #
              # Load tree for each child template which is workflow template
              #
              if is_workflow_template?(template)
                load_nodes_and_templates(template) # recursive call
              end
            end
          end

          def load_inventories
            load_node_inventories
            load_template_inventories
          end

          # Loads inventories for nodes
          def load_node_inventories
            if (node_inventory_ids = self.node_inventories.keys).present?
              topology_api_client.list_service_inventories(:filter => { :eq => { :id => node_inventory_ids }}).data.each do |inventory|
                node = self.node_inventories[inventory.id][:node]

                self.node_inventories[inventory.id][:inventory] = inventory
                self.nodes[node.id][:inventory] = inventory
              end
            end
          end

          # Loads inventories for templates
          def load_template_inventories
            if (template_inventory_ids = self.template_inventories.keys).present?
              topology_api_client.list_service_inventories(:filter => { :eq => { :id => template_inventory_ids }}).data.each do |inventory|
                template = self.template_inventories[inventory.id][:template]

                self.template_inventories[inventory.id][:inventory] = inventory
                self.templates[template.id][:inventory] = inventory
              end
            end
          end

          # Computes used inventory for each Job Template in root Workflow template
          # *Recursive* method
          def compute_used_inventories(template)
            self.template_child_nodes[template.id].collect do |node|
              child_template = self.nodes[node.id][:template]
              raise "Template for Node not loaded! [Node: #{node.id}]" if child_template.nil?

              if is_job_template?(child_template)
                get_inventory(child_template)
              elsif is_workflow_template?(child_template)
                compute_used_inventories(child_template) # recursive call
              end
            end.compact.uniq
          end

          #
          # Computes inventory for given Job/Workflow template
          # *Recursive* method
          #
          def get_inventory(template)
            # node is nil if template is standalone JobTemplate or root WorkflowTemplate
            if (node = node_for(template)).nil?
              inventory_for(template) || self.prompted_inventory
            else
              if prompt_on_launch?(template)
                root_template = root_template_for(node)
                root_inventory = if prompt_on_launch?(root_template) && !loop_detected?(template, root_template)
                                   get_inventory(root_template) # recursive call
                                 else
                                   inventory_for(root_template)
                                 end
                root_inventory || inventory_for(node) || inventory_for(template)
              else
                inventory_for(template)
              end
            end
          end

          # @param template [] Workflow Template or Job Template
          def prompt_on_launch?(template)
            template.extra[:ask_inventory_on_launch]
          end

          # workflow loop detection, TODO not working for 2+level cycles
          def loop_detected?(template, root_template)
            template.id == root_template.id
          end

          def load_inventory(inventory_id)
            topology_api_client.show_service_inventory(inventory_id)
          end

          def inventory_for(node_or_template)
            if node_or_template.kind_of?(TopologicalInventoryApiClient::ServiceOfferingNode)
              self.node_inventories[node_or_template.id][:inventory]
            else
              self.template_inventories[node_or_template.id][:inventory]
            end
          end

          def node_for(template)
            self.templates[template.id][:node]
          end

          def root_template_for(node)
            self.nodes[node.id][:root_template]
          end
        end
      end
    end
  end
end