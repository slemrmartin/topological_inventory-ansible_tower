module TopologicalInventory::AnsibleTower
  class Parser
    module ServiceOffering
      def parse_service_offering(template_hash)
        template = template_hash[:template]

        service_inventory = lazy_find(:service_inventories, :source_ref => template.inventory_id.to_s) if template.respond_to?(:inventory_id)

        extra = {
          :type                    => template.type.to_sym,
          :ask_inventory_on_launch => template.ask_inventory_on_launch,
          :survey_enabled          => template.survey_enabled,
        }

        if template_hash[:template_type].to_s == 'job_template'
          extra = extra.merge(
            :ask_credential_on_launch => template.ask_credential_on_launch,
          )
        end

        service_offering = collections.service_offerings.build(
          parse_base_item(template).merge(
            :source_ref        => template.id.to_s,
            :name              => template.name.to_s,
            :description       => template.description.to_s,
            :service_inventory => service_inventory,
            :extra             => extra
          )
        )
        parse_service_plan(template, template_hash[:survey_spec]) if template_hash[:survey_spec].present?

        if template.summary_fields && template_hash[:template_type] == :job_template
          template.summary_fields.credentials.each do |credential|
            collections.service_offering_service_credentials.build(
              :service_offering   => lazy_find(:service_offerings, :source_ref => template.id.to_s),
              :service_credential => lazy_find(:service_credentials, :source_ref => credential.id.to_s)
            )
          end
        end

        service_offering
      end

      def self.included(klass)
        klass.extend(ClassMethods)
      end

      module ClassMethods
        def receptor_filter_service_offerings
          receptor_filter_list(:fields         => %i[id
                                                     ask_credential_on_launch
                                                     ask_inventory_on_launch
                                                     created
                                                     description
                                                     name
                                                     inventory
                                                     survey_enabled
                                                     type],
                               :related        => %i[inventory],
                               :summary_fields => %i[credentials])
        end
      end
    end
  end
end
