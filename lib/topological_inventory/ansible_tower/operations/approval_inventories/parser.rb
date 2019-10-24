require "topological_inventory-api-client"
require "topological_inventory/providers/common/operations/topology_api_client"
require "topological_inventory/ansible_tower/operations/approval_inventories/tree_item"
module TopologicalInventory
  module AnsibleTower
    module Operations
      module ApprovalInventories
        #
        # Terminology:
        #
        # * Workflow Template                      = ServiceOffering with extra[:type] == 'workflow_job_template'
        # * Job Template                           = ServiceOffering with extra[:type] == 'job_template'
        # * Workflow Job Template Node (or "Node") = ServiceOfferingNode
        # * Inventory                              = ServiceInventory
        #
        class Parser
          include Logging
          include TopologyApiClient

          def initialize(root_wf_template, prompted_inventory_id = nil)
            self.root_tree_item = TreeItem.new(root_wf_template)

            self.prompted_inventory = load_inventory(prompted_inventory_id)

            self.template_inventories = {} # { inventory_id => { template:, inventory:} }
            self.node_inventories     = {} # { inventory_id => { node:, inventory: } }
          end

          # Entrypoint for standalone JobTemplate
          #
          # @param tree_item [TopologicalInventory::AnsibleTower::Operations::ApprovalInventories::TreeItem] tree node with Job Template
          # @return [TopologicalInventoryApiClient::ServiceInventory, nil]
          def load_job_template_inventory(tree_item = root_tree_item)
            job_template = tree_item.item
            if job_template.service_inventory_id
              self.template_inventories[job_template.service_inventory_id] = { :template => job_template }
              load_inventories
            end

            compute_used_inventories(tree_item).first
          end

          # Entrypoint for Workflow Template
          #
          # @param tree_item [TopologicalInventory::AnsibleTower::Operations::ApprovalInventories::TreeItem] tree node with Workflow Template
          # @return [Array<TopologicalInventoryApiClient::ServiceInventory>]
          def load_workflow_template_inventories(tree_item = root_tree_item)
            load_nodes_and_templates(tree_item)
            load_inventories

            compute_used_inventories(tree_item)
          end

          def is_job_template?(template)
            TopologicalInventory::AnsibleTower::Operations::ApprovalInventories::TreeItem.is_job_template?(template)
          end

          def is_workflow_template?(template)
            TopologicalInventory::AnsibleTower::Operations::ApprovalInventories::TreeItem.is_workflow_template?(template)
          end

          private

          attr_accessor :node_inventories, :prompted_inventory, :root_tree_item,
                        :template_child_nodes, :template_inventories

          # Loads nodes, templates and IDs of all inventories
          # @param wf_template_tree_item [TopologicalInventory::AnsibleTower::Operations::ApprovalInventories::TreeItem] tree item with Workflow Template
          def load_nodes_and_templates(wf_template_tree_item)
            load_child_nodes(wf_template_tree_item)
            load_templates_for_nodes(wf_template_tree_item)
          end

          # @param parent_wf_template_tree_item [TopologicalInventory::AnsibleTower::Operations::ApprovalInventories::TreeItem] tree item with Workflow Template
          def load_child_nodes(parent_wf_template_tree_item)
            root_wf_template = parent_wf_template_tree_item.item
            topology_api_client.list_service_offering_service_nodes(root_wf_template.id).data.each do |node|

              node_tree_item = TreeItem.new(node)
              TreeItem.connect(:child  => node_tree_item,
                               :parent => parent_wf_template_tree_item)

              # Set node inventory key for latter one-query load
              self.node_inventories[node.service_inventory_id] = { :node => node } if node.service_inventory_id
            end
          end

          def load_templates_for_nodes(parent_wf_template_tree_item)
            child_node_ids = parent_wf_template_tree_item.children.collect { |tree_item| tree_item.item&.id }

            # TODO: node_ids should be strings, check if they aren't integers
            topology_api_client.list_service_offerings(:filter => { :eq => { :id => child_node_ids }}).data.each do |template|
              template_tree_item = TreeItem.new(template)

              parent_wf_template_tree_item.children.each do |node_tree_item|
                if template.id == node_tree_item.item.service_offering_id
                  TreeItem.connect(:child  => template_tree_item,
                                   :parent => node_tree_item)
                  break
                end
              end

              if template_tree_item.parent.nil?
                raise "Workflow Node for Template not found! [Template: #{template.id}]"
              end

              # Set template inventory key for latter one-query load
              self.template_inventories[template.service_inventory_id] = { :template => template } if template.service_inventory_id
              #
              # Load tree for each child template which is workflow template
              #
              if is_workflow_template?(template)
                load_nodes_and_templates(template_tree_item) # recursive call
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
                self.node_inventories[inventory.id][:inventory] = inventory
              end
            end
          end

          # Loads inventories for templates
          def load_template_inventories
            if (template_inventory_ids = self.template_inventories.keys).present?
              topology_api_client.list_service_inventories(:filter => { :eq => { :id => template_inventory_ids }}).data.each do |inventory|
                self.template_inventories[inventory.id][:inventory] = inventory
              end
            end
          end

          # Computes used inventory for each Job Template in root Workflow template
          # *Recursive* method
          def compute_used_inventories(template_tree_item)
            template_tree_item.children.each do |child_node_tree_item|
              child_template_tree_item = child_node_tree_item.children.first
              raise "Template for Node not loaded! [Node: #{child_node_tree_item.item.id}]" if child_template_tree_item.nil?

              if child_template_tree_item.job_template?
                get_inventory(child_template_tree_item)
              elsif child_template_tree_item.workflow_template?
                compute_used_inventories(child_template_tree_item) # recursive call
              end
            end.compact.uniq
          end

          #
          # Computes inventory for given Job/Workflow template
          # *Recursive* method
          #
          def get_inventory(template_tree_item)
            template = template_tree_item.item

            # node is nil if template is standalone JobTemplate or root WorkflowTemplate
            if (node_tree_item = template_tree_item.parent).nil?
              inventory_for(template) || self.prompted_inventory
            else
              node = node_tree_item.item
              if prompt_on_launch?(template)
                root_template_tree_item = node.parent
                root_template = root_template_tree_item.item

                root_inventory = if prompt_on_launch?(root_template) && !loop_detected?(template, root_template)
                                   get_inventory(root_template_tree_item) # recursive call
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