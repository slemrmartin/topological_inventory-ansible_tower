require "topological_inventory/ansible_tower/operations/core/ansible_tower_client"

RSpec.describe TopologicalInventory::AnsibleTower::Operations::Core::AnsibleTowerClient do
  let(:order_params) do
    {
      'service_plan_id'             => 1,
      'service_parameters'          => {:name   => "Job 1",
                                        :param1 => "Test Topology",
                                        :param2 => 50},
      'provider_control_parameters' => {}
    }
  end

  let(:source_id) { 1 }
  let(:identity) { {'x-rh-identity' => '1234567890'} }
  let(:task_id) { 10 }
  let(:ansible_tower_client) { described_class.new(source_id, task_id, identity) }

  before do
    ansible_tower, @api = double, double
    allow(ansible_tower_client).to receive(:ansible_tower).and_return(ansible_tower)
    allow(ansible_tower).to receive(:api).and_return(@api)

    allow(ansible_tower_client).to receive(:logger).and_return(double('null_object').as_null_object)
  end

  describe "#order_service_plan" do
    let(:job_templates) { double }
    let(:job_template) { double }
    let(:job) { double }

    before do
      allow(job_templates).to receive(:find).and_return(job_template)
      allow(job_template).to receive(:launch).and_return(job)
      expect(job_template).to receive(:launch).with(:extra_vars => order_params['service_parameters'])
    end

    it "launches job_template and returns job" do
      allow(@api).to receive(:job_templates).and_return(job_templates)

      expect(@api).to receive(:job_templates).once

      svc_instance = ansible_tower_client.order_service("job_template", 1, order_params)
      expect(svc_instance).to eq(job)
    end

    it "launches workflow and returns workflow job" do
      allow(@api).to receive(:workflow_job_templates).and_return(job_templates)

      expect(@api).to receive(:workflow_job_templates).once

      svc_instance = ansible_tower_client.order_service("workflow_job_template", 1, order_params)
      expect(svc_instance).to eq(job)
    end
  end
end
