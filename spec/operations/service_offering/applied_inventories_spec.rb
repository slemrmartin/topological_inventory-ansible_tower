require "topological_inventory-api-client"
require "topological_inventory/ansible_tower/operations/service_offering"

RSpec.describe TopologicalInventory::AnsibleTower::Operations::ServiceOffering do
  include AppliedInventories::Methods
  extend AppliedInventories::Data

  let(:topology_api_client) { double('Topological API Client') }

  subject do
    operation = described_class.new
    allow(operation).to receive(:topology_api_client).and_return(topology_api_client)
    operation
  end

  before do
    allow_any_instance_of(TopologicalInventory::AnsibleTower::Operations::AppliedInventories::Parser).to receive(:topology_api_client).and_return(topology_api_client)
  end

  context "#applied_inventories" do
    templates_and_workflows_data.each_pair do |sample_name, workflow_definition|
      it "processing service_offering '#{sample_name}'" do
        stub_api_init(workflow_definition)
        subject.params = { 'service_offering_id' => workflow_definition[:template].id, 'service_parameters' => {}}
        subject.params['service_parameters']['prompted_inventory_id'] = workflow_definition[:prompted_inventory].id if workflow_definition[:prompted_inventory]

        expect(subject).to receive(:update_task).with(nil,
                                                      :state => "completed",
                                                      :status => "ok",
                                                      :context => { :applied_inventories => match_array(workflow_definition[:applied_inventories].map(&:id))})
        subject.send(:applied_inventories)
      end
    end
  end
end
