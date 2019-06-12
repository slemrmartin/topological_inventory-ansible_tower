module TopologicalInventory::AnsibleTower
  class Parser
    module ServiceOffering
      def parse_service_offering(template_hash)
        template = template_hash[:template]

        service_offering = collections.service_offerings.build(
          parse_base_item(template).merge(
            :source_ref  => template.id.to_s,
            :name        => template.name.to_s,
            :description => template.description.to_s,
            :extra       => { :type => template_hash[:template_type] }
          )
        )
        parse_service_plan(template, template_hash[:survey_spec])
        service_offering
      end
    end
  end
end
