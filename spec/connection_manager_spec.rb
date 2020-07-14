RSpec.describe TopologicalInventory::AnsibleTower::ConnectionManager do
  let(:source_uid) { SecureRandom.uuid }
  let(:receptor_client) { double("Receptor Client", :identity_header= => nil) }
  subject { described_class.new(source_uid) }

  it "sets Receptor connection if node id provided" do
    allow(subject).to receive(:receptor_client).and_return(receptor_client)

    subject.connect(:account_number => '1', :receptor_node => 'test-node')
    expect(subject.connection).to be_kind_of(TopologicalInventory::AnsibleTower::Receptor::Connection)
  end

  it "sets AnsibleTower connection if base_url provided" do
    subject.connect(:base_url => 'www.example.com', :username => 'User1', :password => 'redhat')
    expect(subject.connection).to be_kind_of(TopologicalInventory::AnsibleTower::Connection)
  end

  it "logs error and return nil if neither receptor node or base url provided" do
    expect(subject.logger).to receive(:error).with("ConnectionManager: Invalid connection data; :source_uid => #{source_uid}")
    expect(subject.connect(:username => 'User1')).to be_nil
    expect(subject.connection).to be_nil
  end
end
