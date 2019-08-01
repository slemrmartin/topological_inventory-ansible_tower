module TopologicalInventory::AnsibleTower
  class Parser
    module ServiceInstance
      def parse_service_instance(job_hash)
        job = job_hash[:job]

        external_url = URI.join(self.tower_host, job.url)

        collections.service_instances.build(
          parse_base_item(job).merge(
            :source_ref       => job.id.to_s,
            :service_offering => lazy_find(:service_offerings, :source_ref => job.unified_job_template_id.to_s),
            # it creates skeletal service_plans because not all jobs have corresponding survey
            :service_plan     => lazy_find(:service_plans, :source_ref => job.unified_job_template_id.to_s),
            :external_url     => external_url.to_s
          )
        )
      end
    end
  end
end
