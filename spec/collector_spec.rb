RSpec.describe TopologicalInventory::AnsibleTower::Collector do
  let(:source_uid) { '7b901ca3-5414-4476-8d48-a722c1493de0' }
  let(:logger) { double('Logger').as_null_object }
  let(:client) { double('Ingress API Client') }

  subject do
    described_class.new(source_uid,
                        'tower.example.com',
                        'user',
                        'passwd',
                        nil)

  end

  before do
    allow(subject).to receive(:logger).and_return(logger)
    allow(subject).to receive(:ingress_api_client).and_return(client)
  end
end
