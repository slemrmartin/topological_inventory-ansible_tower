require "topological_inventory/ansible_tower/logging"
require "topological_inventory-ingress_api-client/collector"
require "topological_inventory/ansible_tower/connection"
require "topological_inventory/ansible_tower/parser"
require "topological_inventory/ansible_tower/iterator"

module TopologicalInventory::AnsibleTower
  class Collector < TopologicalInventoryIngressApiClient::Collector
    include Logging

    require "topological_inventory/ansible_tower/collector/service_catalog"
    include TopologicalInventory::AnsibleTower::Collector::ServiceCatalog

    def initialize(source, tower_hostname, tower_user, tower_passwd, metrics, sleep_poll = 60)
      super(source, :default_limit => 5)

      self.connection_manager = TopologicalInventory::AnsibleTower::Connection.new
      self.tower_hostname = tower_hostname
      self.tower_user = tower_user
      self.tower_passwd = tower_passwd
      self.metrics = metrics
      self.sleep_poll = sleep_poll
    end

    def collect!
      until finished?
        ensure_collector_threads

        collector_threads.each_value do |thread|
          thread.join
        end
        sleep(sleep_poll)
      end
    end

    private

    attr_accessor :connection_manager, :tower_hostname, :tower_user, :tower_passwd,
                  :metrics, :sleep_poll

    def endpoint_types
      %w[service_catalog]
    end

    def service_catalog_entity_types
      %w[service_offerings service_instances]
    end

    # Connection to endpoint (for each entity type the same)
    def connection_for_entity_type(_entity_type)
      connection_manager.connect(tower_hostname, tower_user, tower_passwd)
    end

    # Thread's main for collecting one entity type's data
    def collector_thread(connection, entity_type)
      refresh_state_uuid = SecureRandom.uuid
      logger.info("[START] Collecting #{entity_type} with :refresh_state_uuid => '#{refresh_state_uuid}'")
      parser = TopologicalInventory::AnsibleTower::Parser.new(tower_host: tower_hostname)

      total_parts = 0
      cnt = 0

      # each on ansible_tower_client's enumeration makes pagination requests by itself
      send("get_#{entity_type}", connection).each do |entity|
        cnt += 1

        parser.send("parse_#{entity_type.singularize}", entity)

        if cnt >= limits[entity_type]
          total_parts += 1
          refresh_state_part_uuid = SecureRandom.uuid
          save_inventory(parser.collections.values, inventory_name, schema_name, refresh_state_uuid, refresh_state_part_uuid)

          # re-init
          parser = TopologicalInventory::AnsibleTower::Parser.new(tower_host: tower_hostname)
          cnt = 0
        end
      end

      if parser.collections.values.present?
        total_parts += 1
        refresh_state_part_uuid = SecureRandom.uuid
        save_inventory(parser.collections.values, inventory_name, schema_name, refresh_state_uuid, refresh_state_part_uuid)
      end

      logger.info("[END] Collecting #{entity_type} with :refresh_state_uuid => '#{refresh_state_uuid}' - Parts [#{total_parts}]")

      # Sweeping inactive records

      logger.info("[START] Sweeping inactive records for #{entity_type} with :refresh_state_uuid => '#{refresh_state_uuid}'...")
      sweep_inventory(inventory_name, schema_name, refresh_state_uuid, total_parts, parser.collections.inventory_collections_names)
      logger.info("[END] Sweeping inactive records for #{entity_type} with :refresh_state_uuid => '#{refresh_state_uuid}'")
    rescue => e
      metrics.record_error
      logger.error("Error collecting :#{entity_type}, message => #{e.message}")
      logger.error(e)
    end

    def inventory_name
      "AnsibleTower"
    end
  end

  # Used for Save & Sweep Inventory
  def inventory_name
    "AnsibleTower"
  end
end

