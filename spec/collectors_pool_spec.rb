RSpec.describe TopologicalInventory::AnsibleTower::CollectorsPool do
  let(:source) { double("Source") }

  subject { described_class.new(nil, nil) }

  describe ".source_valid?" do
    it "returns false if any of source, host, username, password are blank" do
      (-1..3).each do |nil_index|
        data = (0..3).collect { |j| nil_index == j ? nil : 'some_data' }
        allow(source).to receive_messages(:source => data[0],
                                          :host   => data[1])
        secret = { "username" => data[2], "password" => data[3] }

        expect(subject.source_valid?(source, secret)).to eq(nil_index == -1)
      end
    end
  end
end
