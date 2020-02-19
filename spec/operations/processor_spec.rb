require "topological_inventory/ansible_tower/operations/processor"

RSpec.describe TopologicalInventory::AnsibleTower::Operations::Processor do
  context "#process" do
    it "updates task with not_implemented error if operation not supported" do
      # Non-existing class
      task_id = '1'
      processor = described_class.new('SomeModel', 'some_method', {'params' => {'task_id' => task_id}})
      expect(processor).to receive(:update_task).with(task_id,
                                                      :state   => 'completed',
                                                      :status  => 'error',
                                                      :context => {:error => "SomeModel#some_method not implemented"})
      processor.process

      # Non-existing method
      task_id = '2'
      processor = described_class.new('ServiceOffering', 'some_method', {'params' => {'task_id' => task_id}})
      expect(processor).to receive(:update_task).with(task_id,
                                                      :state   => 'completed',
                                                      :status  => 'error',
                                                      :context => {:error => "ServiceOffering#some_method not implemented"})
      processor.process
    end
  end
end
