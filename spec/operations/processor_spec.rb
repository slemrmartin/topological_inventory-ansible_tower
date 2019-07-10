require "topological_inventory/ansible_tower/operations/processor"

RSpec.describe TopologicalInventory::AnsibleTower::Operations::Processor do
  let(:message) do
    {
      :request_context => {"x-rh-identity" => ''},
      :params => {
        :order_params => {
          :service_plan_id => 1,
          :service_parameters => { "name": "Job 1",
                                   "quest": "Test Topology",
                                   "airspeed": 50 },
          :provider_control_parameters => {}
        },
        :service_plan_id => 1,
        :task_id => 1 # in tp-inv api (Task)
      }
    }
  end
  describe "#process" do
  end
end
