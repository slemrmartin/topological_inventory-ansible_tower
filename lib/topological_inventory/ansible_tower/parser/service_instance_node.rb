module TopologicalInventory::AnsibleTower
  class Parser
    module ServiceInstanceNode
      def parse_service_instance_node(instance_node)
        node = instance_node[:node]

        service_instance_ref = node.summary_fields.job&.id&.to_s
        service_instance = lazy_find(:service_instances, :source_ref => service_instance_ref) if service_instance_ref

        service_inventory = lazy_find(:service_inventories, :source_ref => node.inventory_id.to_s) if node.respond_to?(:inventory_id)

        collections.service_instance_nodes.build(
          parse_base_item(node).merge(
            :source_ref            => node.id.to_s,
            :source_updated_at     => node.modified,
            :name                  => node.summary_fields.job&.name,
            :service_inventory     => service_inventory,
            :root_service_instance => lazy_find(:service_instances, :source_ref => node.summary_fields.workflow_job.id.to_s),
            :service_instance      => service_instance,
            :extra                 => {
              "job_type"      => node.job_type,
              "success_nodes" => node.success_nodes_id,
              "failure_nodes" => node.failure_nodes_id,
              "always_nodes"  => node.always_nodes_id,
              "limit"         => node.limit,
              "job_tags"      => node.job_tags,
              "skip_tags"     => node.skip_tags,
              "job_status"    => node.summary_fields.job&.status,
              "job_failed"    => node.summary_fields.job&.failed,
              "job_elapsed"   => node.summary_fields.job&.elapsed,
            }
          )
        )

        instance_node[:credentials].to_a.each do |credential|
          collections.service_instance_node_service_credentials.build(
            :service_instance_node => lazy_find(:service_instance_nodes, :source_ref => node.id.to_s),
            :service_credential    => lazy_find(:service_credentials, :source_ref => credential.id.to_s)
          )
        end
      end
    end
  end
end
