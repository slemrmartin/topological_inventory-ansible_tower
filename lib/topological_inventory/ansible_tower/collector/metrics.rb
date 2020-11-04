require "prometheus_exporter"
require "prometheus_exporter/server"
require "prometheus_exporter/client"
require 'prometheus_exporter/instrumentation'

module TopologicalInventory
  module AnsibleTower
    class Collector
      class Metrics < TopologicalInventory::Providers::Common::Metrics
        def initialize(port = 9394)
          super(port)
        end

        def default_prefix
          "topological_inventory_ansible_tower_collector_"
        end
      end
    end
  end
end
