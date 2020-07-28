module TopologicalInventory::AnsibleTower
  class Parser
    module ServiceInventorySource
      def parse_service_inventory_source(service_inventory_source)
        # TODO: add credentials
        collection.service_inventory_sources.build(
          parse_base_item(service_inventory_source).merge(
            :source_ref => service_inventory_source.id.to_s,
            :inventory  => lazy_find(:service_inventories, :source_ref => service_inventory_source.summary_fields.inventory.id.to_s)
          )
        )
      end
    end
  end
end
