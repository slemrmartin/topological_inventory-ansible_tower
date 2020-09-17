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
              "pending_deletion"                => inventory.pending_deletion,
            }
          )
        )
      end

      def self.included(klass)
        klass.extend(ClassMethods)
      end

      module ClassMethods
        def receptor_filter_service_inventories
          receptor_filter_list(:fields  => %i[id
                                              created
                                              description
                                              host_filter
                                              inventory_sources_with_failures
                                              kind
                                              modified
                                              name
                                              organization
                                              pending_deletion
                                              total_inventory_sources
                                              type
                                              variables],
                               :related => %i[organization])
        end
      end
    end
  end
end
