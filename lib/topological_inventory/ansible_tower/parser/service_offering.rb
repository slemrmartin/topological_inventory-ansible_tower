module TopologicalInventory::AnsibleTower
  class Parser
    module ServiceOffering
      def parse_service_offering(template_hash)
        template = template_hash[:template]

        service_offering = collections.service_offerings.build(
          parse_base_item(template).merge(
            :source_ref  => template.id,
            :name        => template.name,
            :description => template.description,
            #:extra     => {:type => template_hash[:type]} # TODO
          )
        )
        parse_service_plan(template, template_hash[:survey_spec])
        service_offering
      end
    end
  end
end
