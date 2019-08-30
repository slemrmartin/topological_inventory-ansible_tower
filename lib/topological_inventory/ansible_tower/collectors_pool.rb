require "topological_inventory-ingress_api-client/collectors_pool"
require "topological_inventory/ansible_tower/collector"
require "topological_inventory/ansible_tower/logging"

module TopologicalInventory::AnsibleTower
  class CollectorsPool < TopologicalInventoryIngressApiClient::CollectorsPool
    include Logging

    def initialize(config_name, metrics, poll_time: 10)
      super
    end

    def path_to_config
      File.expand_path("../../../config", File.dirname(__FILE__))
    end

    def path_to_secrets
      File.expand_path("../../../secret", File.dirname(__FILE__))
    end

    def source_valid?(source, secret)
      missing_data = [source.source,
                      source.host,
                      secret["username"],
                      secret["password"]].select do |data|
        data.to_s.strip.blank?
      end
      missing_data.empty?
    end

    def new_collector(source, secret)
      TopologicalInventory::AnsibleTower::Collector.new(source.source, source.host, secret["username"], secret["password"], metrics)
    end
  end
end
