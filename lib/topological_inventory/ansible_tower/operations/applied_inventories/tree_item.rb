module TopologicalInventory
  module AnsibleTower
    module Operations
      module AppliedInventories
        class TreeItem
          attr_accessor :item, :parent, :children

          def self.is_job_template?(template)
            return false if template.nil?

            template.extra[:type] == 'job_template'
          end

          def self.is_workflow_template?(template)
            return false if template.nil?

            template.extra[:type] == 'workflow_job_template'
          end

          def self.connect(child:, parent:)
            return if child.nil? || parent.nil?

            child.parent = parent
            parent.add_child(child)
          end

          def initialize(item)
            self.item     = item
            self.parent   = nil
            self.children = []
          end

          def add_child(child_tree_item)
            children << child_tree_item # unless children.include?(child_tree_item)
          end

          def template?
            item.kind_of?(TopologicalInventoryApiClient::ServiceOffering)
          end

          def job_template?
            template? && self.class.is_job_template?(item)
          end

          def workflow_template?
            template? && self.class.is_workflow_template?(item)
          end

          def workflow_node?
            item.kind_of?(TopologicalInventoryApiClient::ServiceOfferingNode)
          end
        end
      end
    end
  end
end
