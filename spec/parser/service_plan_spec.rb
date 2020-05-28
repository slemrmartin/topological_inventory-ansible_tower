describe TopologicalInventory::AnsibleTower::Parser do
  let(:parser) { described_class.new(:tower_url => 'example.com') }
  let(:survey) do
    {"description" => "",
     "name"        => "",
     "spec"        =>
       [
         {
           "question_description" => "my text desc",
           "min"                  => 1,
           "default"              => "Aa",
           "max"                  => 1025,
           "required"             => true,
           "choices"              => "",
           "new_question"         => true,
           "variable"             => "my_text",
           "question_name"        => "My Text",
           "type"                 => "text"
         },
         {
           "question_description" => "Text area desc",
           "min"                  => 1,
           "default"              => "multi\nline\ncontent",
           "max"                  => 4096,
           "required"             => false,
           "choices"              => "",
           "new_question"         => true,
           "variable"             => "my_text_area",
           "question_name"        => "My text area",
           "type"                 => "textarea"
         },
         {
           "question_description" => "pwd desc",
           "min"                  => 0,
           "default"              => "$encrypted$",
           "max"                  => 32,
           "required"             => true,
           "choices"              => "",
           "variable"             => "my_password",
           "question_name"        => "My password",
           "type"                 => "password"
         },
         {
           "question_description" => "Single select",
           "min"                  => nil,
           "default"              => "",
           "max"                  => nil,
           "required"             => true,
           "choices"              => "one\ntwo\nthree",
           "new_question"         => true,
           "variable"             => "my_multichoice_single",
           "question_name"        => "My multichoice single",
           "type"                 => "multiplechoice"
         },
         {
           "question_description" => "Single select - Array choices",
           "min"                  => nil,
           "default"              => "",
           "max"                  => nil,
           "required"             => true,
           "choices"              => %w[one two three],
           "new_question"         => true,
           "variable"             => "my_multichoice_single",
           "question_name"        => "My multichoice single",
           "type"                 => "multiplechoice"
         },
         {
           "question_description" => "Multiselect",
           "min"                  => nil,
           "default"              => "six\neight",
           "max"                  => nil,
           "required"             => true,
           "choices"              => "five\nsix\nseven\neight",
           "new_question"         => true,
           "variable"             => "my_multiselect",
           "question_name"        => "My Multichoice multi",
           "type"                 => "multiselect"
         },
         {
           "question_description" => "int desc",
           "min"                  => 1,
           "default"              => "",
           "max"                  => 100,
           "required"             => false,
           "choices"              => "",
           "new_question"         => true,
           "variable"             => "my_int",
           "question_name"        => "My Int",
           "type"                 => "integer"
         },
         {
           "question_description" => "float desc",
           "min"                  => -1,
           "default"              => 35.82,
           "max"                  => 100.54,
           "required"             => false,
           "choices"              => "",
           "new_question"         => true,
           "variable"             => "my_float",
           "question_name"        => "My float",
           "type"                 => "float"
         }
       ]
    }
  end

  it "converts survey to data-driven forms format" do
    data_driven_forms_hash = parser.send(:convert_survey, survey)
    expect(data_driven_forms_hash).to eq(
      :schemaType => "default",
      :schema     => {
        :title       => "",
        :description => "",
        :fields      => [
          {
            :component    => "text-field",
            :name         => "my_text",
            :initialValue => "Aa",
            :label        => "My Text",
            :helperText   => "my text desc",
            :isRequired   => true,
            :validate     => [
              {:type => "required-validator"},
              {:type => "min-length-validator", :threshold => 1},
              {:type => "max-length-validator", :threshold => 1025}
            ]
          },
          {
            :component    => "textarea-field",
            :name         => "my_text_area",
            :initialValue => "multi\nline\ncontent",
            :label        => "My text area",
            :helperText   => "Text area desc",
            :validate     => [
              {:type => "min-length-validator", :threshold => 1},
              {:type => "max-length-validator", :threshold => 4096}
            ]
          },
          {
            :component    => "text-field",
            :name         => "my_password",
            :initialValue => "$encrypted$",
            :label        => "My password",
            :helperText   => "pwd desc",
            :isRequired   => true,
            :validate     => [
              {:type => "required-validator"},
              {:type => "min-length-validator", :threshold => 0},
              {:type => "max-length-validator", :threshold => 32}
            ],
            :type         => "password"
          },
          {
            :component    => "select-field",
            :name         => "my_multichoice_single",
            :initialValue => "",
            :label        => "My multichoice single",
            :helperText   => "Single select",
            :isRequired   => true,
            :validate     => [{:type => "required-validator"}],
            :options      => [
              {:label => "one", :value => "one"},
              {:label => "two", :value => "two"},
              {:label => "three", :value => "three"}
            ]
          },
          {
            :component    => "select-field",
            :name         => "my_multichoice_single",
            :initialValue => "",
            :label        => "My multichoice single",
            :helperText   => "Single select - Array choices",
            :isRequired   => true,
            :validate     => [{:type => "required-validator"}],
            :options      => [
              {:label => "one", :value => "one"},
              {:label => "two", :value => "two"},
              {:label => "three", :value => "three"}
            ]
          },
          {
            :component    => "select-field",
            :name         => "my_multiselect",
            :initialValue => ["six", "eight"],
            :label        => "My Multichoice multi",
            :helperText   => "Multiselect",
            :isRequired   => true,
            :validate     => [{:type => "required-validator"}],
            :options      => [
              {:label => "five", :value => "five"},
              {:label => "six", :value => "six"},
              {:label => "seven", :value => "seven"},
              {:label => "eight", :value => "eight"}
            ],
            :multi        => true
          },
          {
            :component    => "text-field",
            :name         => "my_int",
            :initialValue => "",
            :label        => "My Int",
            :helperText   => "int desc",
            :validate     => [
              {:type => "min-number-value", :value => 1},
              {:type => "max-number-value", :value => 100}
            ],
            :type         => "number",
            :dataType     => "integer"
          },
          {
            :component    => "text-field",
            :name         => "my_float",
            :initialValue => 35.82,
            :label        => "My float",
            :helperText   => "float desc",
            :validate     => [
              {:type => "min-number-value", :value => -1},
              {:type => "max-number-value", :value => 100.54}
            ],
            :type         => "number",
            :dataType     => "float"
          }
        ]
      }
    )
  end
end
