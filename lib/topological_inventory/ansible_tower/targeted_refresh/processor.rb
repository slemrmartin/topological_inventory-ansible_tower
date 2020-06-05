require "topological_inventory/ansible_tower/operations/processor"

module TopologicalInventory
  module AnsibleTower
    module TargetedRefresh
      class Processor < TopologicalInventory::AnsibleTower::Operations::Processor
        def self.process!(message, payload)
          model, method = message.message.to_s.split(".")
          new(model, method, payload).process
        end
      end
    end
  end
end