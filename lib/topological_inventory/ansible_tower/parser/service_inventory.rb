module TopologicalInventory::AnsibleTower
  class Parser
    module ServiceInventory
      def parse_service_inventory(inventory)
        collections.service_inventories.build(
          parse_base_item(inventory).merge(
            :source_ref        => inventory.id.to_s,
            :source_updated_at => inventory.modified,
            :description       => inventory.description,
            :extra             => {
              "type"                            => inventory.type,
              "organization_id"                 => inventory.organization_id,
              "kind"                            => inventory.kind,
              "host_filter"                     => inventory.host_filter,
              "variables"                       => inventory.variables,
              "total_inventory_sources"         => inventory.total_inventory_sources,
              "inventory_sources_with_failures" => inventory.inventory_sources_with_failures,
              "insights_credential"             => inventory.insights_credential,
              "pending_deletion"                => inventory.pending_deletion,
            }
          )
        )
      end
    end
  end
end
