module TopologicalInventory::AnsibleTower
  class Parser
    module ServicePlan

      # service plan's extra
      # http://data-driven-forms.surge.sh

      def parse_service_plan(template, survey_spec_hash)
        return if survey_spec_hash.blank?

        collections.service_plans.build(
          parse_base_item(template).merge(
            :source_ref         => template.id.to_s,
            :name               => survey_spec_hash['name'] || '',
            :description        => survey_spec_hash['description'] || '',
            :create_json_schema => survey_spec_hash['spec'],
            :service_offering   => lazy_find(:service_offerings, :source_ref => template.id.to_s),
            :source_created_at  => template.created,
          )
        )
      end
    end
  end
end
