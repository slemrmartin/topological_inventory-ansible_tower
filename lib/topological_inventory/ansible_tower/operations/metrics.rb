require 'topological_inventory/providers/common/metrics'

module TopologicalInventory
  module AnsibleTower
    module Operations
      class Metrics < TopologicalInventory::Providers::Common::Metrics
        ERROR_TYPES = %i[general applied_inventories order sources_api].freeze
        OPERATIONS = %w[Source.availability_check ServiceOffering.order ServiceOffering.applied_inventories].freeze

        def initialize(port = 9394)
          super(port)
        end

        def default_prefix
          "topological_inventory_ansible_tower_operations_"
        end
      end
    end
  end
end
