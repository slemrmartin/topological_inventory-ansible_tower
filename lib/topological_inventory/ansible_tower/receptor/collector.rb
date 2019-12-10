require "topological_inventory/ansible_tower/collector"
require "topological_inventory/ansible_tower/receptor/async_receiver"

module TopologicalInventory::AnsibleTower
  module Receptor
    class Collector < TopologicalInventory::AnsibleTower::Collector
      def initialize(source, receptor_node, external_tenant, metrics)
        super(source, "receptor://#{receptor_node}", nil, nil, metrics)
        self.receptor_node      = receptor_node
        self.tenant             = external_tenant # eq Tenant.external_tenant or account_number in x-rh-identity
      end

      def connection_for_entity_type(_entity_type)
        connection_manager.connect(:receptor_node  => receptor_node,
                                   :account_number => tenant)
      end

      def collector_thread(connection, entity_type)
        refresh_state_uuid, refresh_state_started_at = SecureRandom.uuid, Time.now.utc

        logger.collecting(:start, source, entity_type, refresh_state_uuid)

        receiver = AsyncReceiver.new(self, connection, entity_type, refresh_state_uuid, refresh_state_started_at)

        # opts = {:fetch_all_pages => true, :accept_encoding => 'gzip', :apply_filter => nil}
        receptor_params = {:fetch_all_pages => true}
        query_params    = {:page_size => limits[entity_type]}
        send("get_#{entity_type}", connection, query_params,
             :on_premise => true, :receptor_receiver => receiver, :receptor_params => receptor_params)
      end

      def async_collecting_finished(entity_type, refresh_state_uuid, total_parts)
        logger.collecting(:finish, source, entity_type, refresh_state_uuid, total_parts)
      end

      def async_save_inventory(refresh_state_uuid, parser)
        refresh_state_part_collected_at = Time.now.utc
        refresh_state_part_uuid = SecureRandom.uuid
        save_inventory(parser.collections.values, inventory_name, schema_name, refresh_state_uuid, refresh_state_part_uuid, refresh_state_part_collected_at)
      end

      def async_sweep_inventory(refresh_state_uuid, sweep_scope, total_parts, refresh_state_started_at)
        logger.sweeping(:start, source, sweep_scope, refresh_state_uuid)
        sweep_inventory(inventory_name, schema_name, refresh_state_uuid, total_parts, sweep_scope, refresh_state_started_at)
        logger.sweeping(:finish, source, sweep_scope, refresh_state_uuid)
      end
    end
  end
end
