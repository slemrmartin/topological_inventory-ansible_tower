RSpec.describe TopologicalInventory::AnsibleTower::Parser do
  describe '#receptor_filter_list' do
    it "creates JMESPath filter from 'fields' arg" do
      filter = described_class.receptor_filter_list(:fields => %i[f1 f2 f3])
      expect(filter).to eq(:results => 'results[].{f1:f1,f2:f2,f3:f3}')
    end

    it "creates JMESPath filter from 'related' arg" do
      filter = described_class.receptor_filter_list(:fields => [], :related => %i[r1 r2 r3])
      expect(filter).to eq(:results => 'results[].{related:{r1:related.r1,r2:related.r2,r3:related.r3}}')
    end

    it "creates JMESPath filter from 'summary_field' arg" do
      filter = described_class.receptor_filter_list(:fields => nil, :summary_fields => %i[s1 s2])
      expect(filter).to eq(:results => 'results[].{summary_fields:{s1:summary_fields.s1,s2:summary_fields.s2}}')
    end

    it "creates JMESPath filter from all args" do
      filter = described_class.receptor_filter_list(:fields         => %i[f1 f2],
                                                    :related        => %i[r1 r2],
                                                    :summary_fields => %i[s1])
      expect(filter).to eq(:results => 'results[].{f1:f1,f2:f2,related:{r1:related.r1,r2:related.r2},summary_fields:{s1:summary_fields.s1}}')
    end
  end

  %w[service_credential
     service_credential_type
     service_instance
     service_instance_node
     service_inventory
     service_offering
     service_offering_node].each do |entity_type|
    describe "#receptor_filter_#{entity_type.pluralize}" do
      let(:data) { double(entity_type) }
      let(:summary_fields) { double("Summary Fields object") }

      subject { described_class.new(:tower_url => 'tower.example.com') }

      before do
        allow(data).to receive(:summary_fields).and_return(summary_fields)

        allow(described_class).to receive(:receptor_filter_list) do |args|
          args[:fields].each do |field|
            if args[:related].to_a.include?(field)
              #
              # All fields in 'related' are called as <field>_id (AnsibleTowerClient transformation)
              #
              expect(data).to receive("#{field}_id".to_sym).at_least(:once).and_return(42)
            else
              method_name = field == :extra_vars ? :extra_vars_hash : field # Job specific
              return_value = case field
                             when :type
                               case entity_type
                               when 'service_instance' then 'job'
                               when 'service_offering' then 'job_template'
                               end
                             else field.to_s
                             end
              expect(data).to receive(method_name.to_sym).at_least(:once).and_return(return_value)
            end
          end

          args[:summary_fields].to_a.each do |summary_field|
            returned_object = if summary_field == :credentials
                                []
                              else
                                double("summary_field #{summary_field}").as_null_object
                              end
            expect(summary_fields).to receive(summary_field).at_least(:once).and_return(returned_object)
          end
        end

        described_class.send("receptor_filter_#{entity_type.pluralize}")
      end

      it "covers all fields from parse_#{entity_type}" do
        input_arg = case entity_type
                    when 'service_instance'
                      {:job => data, :job_type => :job}
                    when 'service_instance_node'
                      {:node => data, :credentials => nil}
                    when 'service_offering'
                      {:template => data, :template_type => :job_template, :survey_spec => nil}
                    when 'service_offering_node'
                      {:node => data, :credentials => nil}
                    else
                      data
                    end
        subject.send("parse_#{entity_type}", input_arg)
      end
    end
  end
end
