module TopologicalInventory::AnsibleTower
  class Parser
    module ServicePlan
      def parse_service_plan(template, survey_spec_hash)
        return if survey_spec_hash.nil?

        collections.service_plans.build(
          parse_base_item(template).merge(
            :source_ref         => template.id.to_s,
            :name               => survey_spec_hash['name'] || '',
            :description        => survey_spec_hash['description'] || '',
            :create_json_schema => convert_survey(survey_spec_hash),
            :service_offering   => lazy_find(:service_offerings, :source_ref => template.id.to_s),
            :source_created_at  => template.created,
          )
        )
      end

      private

      # service plan's survey -> Data driven forms (DDF)
      # http://data-driven-forms.surge.sh
      #
      # create_json_schema should contain this structure:
      #             :type   => 'data-driven-forms',
      #             :description => 'http://data-driven-forms.surge.sh/renderer/form-schemas',
      #             :schema => {
      #               :title => 'optional',
      #               :description => 'optional',
      #               :fields => [
      #                 # ...
      #               ]
      #             }
      #           }
      def convert_survey(survey)
        converted = add_header(survey)

        survey['spec'].to_a.each do |input_hash|
          field = input_common(input_hash)
          send("add_#{input_hash['type']}_properties!".to_sym, input_hash, field) if respond_to?("add_#{input_hash['type']}_properties!".to_sym, true)
          converted[:schema][:fields] << field
        end
        converted
      end

      def add_header(survey)
        {
          :schemaType => 'default',
          :schema     => {
            :title       => survey['name'] || '',
            :description => survey['description'] || '',
            :fields      => []
          }
        }
      end

      def input_common(survey_input)
        output = {
          :component    => component_types_map[survey_input['type']],
          :name         => survey_input['variable'],
          :initialValue => survey_input['default'],
          :label        => survey_input['question_name'],
          :helperText   => survey_input['question_description'],
        }
        add_required_validator!(survey_input, output) if survey_input['required']
        add_min_validator!(survey_input, output) unless survey_input['min'].nil?
        add_max_validator!(survey_input, output) unless survey_input['max'].nil?
        add_choices!(survey_input, output) if survey_input['choices'].present?

        output
      end

      def add_password_properties!(_survey_input, output)
        output[:type] = 'password'
      end

      def add_integer_properties!(_survey_input, output)
        output[:type] = 'number'
        output[:dataType] = 'integer'
      end

      def add_float_properties!(_survey_input, output)
        output[:type] = 'number'
        output[:dataType] = 'float'
      end

      def add_multiselect_properties!(survey_input, output)
        output[:initialValue] = survey_input['default'].split("\n")
        output[:multi] = true
      end

      def add_required_validator!(survey_input, output)
        output[:isRequired] = survey_input['required']
        output[:validate] ||= []
        output[:validate] << { :type => 'required-validator' }
      end

      def add_min_validator!(survey_input, output)
        if %w[integer float].include?(survey_input['type'])
          add_value_validator!('min-number-value', survey_input['min'], output)
        else
          add_length_validator!('min-length-validator', survey_input['min'], output)
        end
      end

      def add_max_validator!(survey_input, output)
        if %w[integer float].include?(survey_input['type'])
          add_value_validator!('max-number-value', survey_input['max'], output)
        else
          add_length_validator!('max-length-validator', survey_input['max'], output)
        end
      end

      def add_value_validator!(type, value, output)
        output[:validate] ||= []
        output[:validate] << {
          :type  => type,
          :value => value
        }
      end

      def add_length_validator!(type, threshold, output)
        output[:validate] ||= []
        output[:validate] << {
          :type      => type,
          :threshold => threshold
        }
      end

      # choices for (multi)select
      def add_choices!(survey_input, output)
        output[:options] ||= []
        # choices are string up to tower version 3.5
        choices = case survey_input['choices']
                  when String then survey_input['choices'].split("\n")
                  when Array then survey_input['choices']
                  else []
                  end
        choices.each do |choice|
          output[:options] << {:label => choice, :value => choice}
        end
      end

      def component_types_map
        {
          'text'           => 'text-field',
          'textarea'       => 'textarea-field',
          'password'       => 'text-field',
          'integer'        => 'text-field',
          'float'          => 'text-field',
          'multiplechoice' => 'select-field',
          'multiselect'    => 'select-field'
        }
      end
    end
  end
end
