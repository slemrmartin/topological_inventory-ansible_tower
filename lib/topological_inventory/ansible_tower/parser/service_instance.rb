module TopologicalInventory::AnsibleTower
  class Parser
    module ServiceInstance
      def parse_service_instance(job_hash)
        job = job_hash[:job]

        root_service_instance_ref = job.summary_fields.source_workflow_job&.id&.to_s if job.summary_fields.respond_to?(:source_workflow_job)
        root_service_instance = lazy_find(:service_instances, :source_ref => root_service_instance_ref) if root_service_instance_ref

        service_inventory = lazy_find(:service_inventories, :source_ref => job.inventory_id.to_s) if job.respond_to?(:inventory_id)

        # Set to tower UI url
        path         = job.type == 'workflow_job' ? 'workflows' : 'jobs/playbook'
        external_url = File.join(self.tower_url, "/#/#{path}", job.id.to_s)

        collections.service_instances.build(
          parse_base_item(job).merge(
            :source_ref       => job.id.to_s,
            :service_offering => lazy_find(:service_offerings, :source_ref => job.unified_job_template_id.to_s),
            # it creates skeletal service_plans because not all jobs have corresponding survey
            :service_plan          => lazy_find(:service_plans, :source_ref => job.unified_job_template_id.to_s),
            :service_inventory     => service_inventory,
            :root_service_instance => root_service_instance,
            :external_url          => external_url
          )
        )
      end
    end
  end
end
