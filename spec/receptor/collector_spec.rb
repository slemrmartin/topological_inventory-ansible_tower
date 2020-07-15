RSpec.describe TopologicalInventory::AnsibleTower::Receptor::Collector do
  let(:account_number) { '1234' }
  let(:inventory_name) { 'AnsibleTower' }
  let(:schema_name) { 'Default' }
  let(:metrics) { double('metrics') }
  let(:receptor_node) { 'sample-node' }
  let(:source_uid) { '7b901ca3-5414-4476-8d48-a722c1493de0' }

  subject { described_class.new(source_uid, receptor_node, account_number, metrics) }

  describe "#connection_for_entity_type" do
    before do
      allow(TopologicalInventory::AnsibleTower::ConnectionManager).to receive(:receptor_client).and_return(double(:identity_header= => nil))
    end

    it "initializes receptor connection" do
      expect(subject.connection_for_entity_type('')).to be_instance_of(TopologicalInventory::AnsibleTower::Receptor::Connection)
    end
  end

  describe "#collector_thread" do
    let(:connection) { double('Connection') }
    let(:entity_type) { 'service_offerings' }
    let(:receiver) { double('Async receiver') }

    it "invokes on-premise requests" do
      expect(TopologicalInventory::AnsibleTower::Receptor::AsyncReceiver).to receive(:new).and_return(receiver)

      expect(subject).to(receive(:get_service_offerings)
                           .with(connection,
                                 {:page_size => subject.send(:limits)[entity_type]},
                                 :on_premise        => true,
                                 :receptor_receiver => receiver,
                                 :receptor_params   => {:accept_encoding => 'gzip', :fetch_all_pages => true}))

      subject.collector_thread(connection, entity_type)
    end
  end

  describe "#async_collecting_finished" do
    it "only logs finish message" do
      expect(TopologicalInventory::AnsibleTower.logger).to receive(:collecting)

      subject.async_collecting_finished('some_entity', '1', '1')
    end
  end

  describe "#async_save_inventory" do
    let(:now) { Time.now.utc }
    let(:parser) { double('Parser', :collections => {:k1 => :v1, :k2 => :v2}) }

    it "saves data in parser" do
      allow(Time).to receive(:now).and_return(now)
      allow(SecureRandom).to receive(:uuid).and_return('refresh_state_part_uuid')

      expect(subject).to receive(:save_inventory).with(%i[v1 v2], inventory_name, schema_name, 'refresh_state_uuid', 'refresh_state_part_uuid', now)
      subject.async_save_inventory('refresh_state_uuid', parser)
    end
  end

  describe "#async_sweep_inventory" do
    let(:total_parts) { 5 }
    it "logs and calls sweep" do
      now = Time.now.utc
      expect(TopologicalInventory::AnsibleTower.logger).to receive(:sweeping).twice

      expect(subject).to receive(:sweep_inventory).with(inventory_name, schema_name, 'refresh_state_uuid', total_parts, 'sweep_scope', now)
      subject.async_sweep_inventory('refresh_state_uuid', 'sweep_scope', total_parts, now)
    end
  end
end
