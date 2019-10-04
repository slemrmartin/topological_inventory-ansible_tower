module TopologicalInventory::AnsibleTower
  class Parser
    module ServiceOfferingNode
      def parse_service_offering_node(node)
        service_offering_ref = node.summary_fields.unified_job_template&.id&.to_s
        service_offering = lazy_find(:service_offerings, :source_ref => service_offering_ref) if service_offering_ref

        service_inventory = lazy_find(:service_inventories, :source_ref => node.inventory_id.to_s) if node.respond_to?(:inventory_id)

        collections.service_offering_nodes.build(
          parse_base_item(node).merge(
            :source_ref            => node.id.to_s,
            :source_updated_at     => node.modified,
            :name                  => node.summary_fields.unified_job_template&.name,
            :service_inventory     => service_inventory,
            :root_service_offering => lazy_find(:service_offerings, :source_ref => node.summary_fields.workflow_job_template.id.to_s),
            :service_offering      => service_offering,
            :extra                 => {
              "job_type"      => node.job_type,
              "success_nodes" => node.success_nodes_id,
              "failure_nodes" => node.failure_nodes_id,
              "always_nodes"  => node.always_nodes_id,
              "limit"         => node.limit,
              "job_tags"      => node.job_tags,
              "skip_tags"     => node.skip_tags,
            }
          )
        )
      end
    end
  end
end
