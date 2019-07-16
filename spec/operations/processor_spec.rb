require "topological_inventory/ansible_tower/operations/processor"

RSpec.describe TopologicalInventory::AnsibleTower::Operations::Processor do
  let(:payload) do
    {
      'request_context' => {"x-rh-identity" => 'abcd'},
      'params'          => {
        'order_params'    => {
          'service_plan_id'             => 1,
          'service_parameters'          => { :name   => "Job 1",
                                             :param1 => "Test Topology",
                                             :param2 => 50 },
          'provider_control_parameters' => {}
        },
        'service_plan_id' => 1,
        'task_id'         => 1 # in tp-inv api (Task)
      }
    }
  end
  let(:topology_api_client) { double }
  let(:source_id) { 1 }
  let(:source_ref) { 1000 }

  before do
    @processor = described_class.new(nil, nil, payload)
    allow(@processor).to receive(:logger).and_return(double('null_object').as_null_object)

    service_plan = double("TopologicalInventoryApiClient::ServicePlan")
    allow(service_plan).to receive(:service_offering_id).and_return(1)
    allow(service_plan).to receive(:name).and_return(double)
    allow(service_plan).to receive(:source_id).and_return(source_id)

    service_offering = double("TopologicalInventoryApiClient::ServiceOffering")
    allow(service_offering).to receive(:name).and_return(double)
    allow(service_offering).to receive(:source_ref).and_return(source_ref)

    @ansible_tower_client = double
    allow(@ansible_tower_client).to receive(:order_service_plan)

    allow(@processor).to receive(:ansible_tower_client).and_return(@ansible_tower_client)
    allow(@processor).to receive(:topology_api_client).and_return(topology_api_client)
    allow(topology_api_client).to receive(:update_task)
    allow(topology_api_client).to receive(:show_service_plan).and_return(service_plan)
    allow(topology_api_client).to receive(:show_service_offering).and_return(service_offering)
  end

  describe "#order_service" do
    it "orders job" do
      allow(@processor).to receive(:poll_order_complete_thread).and_return(double)

      expect(@ansible_tower_client).to receive(:order_service_plan).with(source_ref, payload['params']['order_params'])
      @processor.send(:order_service, payload['params'])
    end

    it "updates task on error" do
      err_message = "Sample error"

      allow(@processor).to receive(:poll_order_complete_thread).and_return(double)
      allow(@processor).to receive(:update_task).and_return(double)
      allow(@ansible_tower_client).to receive(:order_service_plan).and_raise(err_message)

      expect(@processor).to receive(:update_task).with(payload['params']['task_id'], :state => "completed", :status => "error", :context => { :error => err_message })

      @processor.send(:order_service, payload['params'])
    end
  end
end
