require "topological_inventory/ansible_tower/operations/worker"

RSpec.describe TopologicalInventory::AnsibleTower::Operations::Worker do
  describe "#run" do
    let(:client) { double("ManageIQ::Messaging::Client") }
    let(:subject) { described_class.new }
    before do
      require "manageiq-messaging"
      allow(ManageIQ::Messaging::Client).to receive(:open).and_return(client)
      allow(client).to receive(:close)
    end

    it "calls subscribe_messages on the right queue" do
      operations_topic = "platform.topological-inventory.operations-ansible-tower"
      expect(client).to receive(:subscribe_messages)
        .with(hash_including(:service => operations_topic))
      subject.run
    end
  end
end
