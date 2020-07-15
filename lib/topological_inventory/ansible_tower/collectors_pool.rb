require "topological_inventory/providers/common/collectors_pool"
require "topological_inventory/ansible_tower/cloud/collector"
require "topological_inventory/ansible_tower/receptor/collector"
require "topological_inventory/ansible_tower/logging"

module TopologicalInventory::AnsibleTower
  class CollectorsPool < TopologicalInventory::Providers::Common::CollectorsPool
    include Logging

    def path_to_config
      File.expand_path("../../../config", File.dirname(__FILE__))
    end

    def path_to_secrets
      File.expand_path("../../../secret", File.dirname(__FILE__))
    end

    def source_valid?(source, secret)
      data = if source.receptor_node.to_s.strip.present?
               [source.source,
                source.receptor_node]
             else
               [source.source,
                source.host,
                secret["username"],
                secret["password"]]
             end
      missing_data = data.select { |val| val.to_s.strip.blank? }
      missing_data.empty?
    end

    def new_collector(source, secret)
      if source.receptor_node.to_s.strip.blank?
        url = URI::Generic.build(:scheme => source.scheme.to_s.strip.presence || 'https',
                                 :host   => source.host.to_s.strip,
                                 :port   => source.port.to_s.strip)

        TopologicalInventory::AnsibleTower::Cloud::Collector.new(source.source,
                                                                 url.to_s,
                                                                 secret["username"],
                                                                 secret["password"],
                                                                 metrics,
                                                                 :standalone_mode => false)
      else
        TopologicalInventory::AnsibleTower::Receptor::Collector.new(source.source,
                                                                    source.receptor_node.to_s.strip,
                                                                    source.account_number.to_s.strip,
                                                                    metrics,
                                                                    :standalone_mode => false)
      end
    end
  end
end
