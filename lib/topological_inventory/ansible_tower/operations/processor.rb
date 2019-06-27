require "topological_inventory/ansible_tower/logging"

module TopologicalInventory
  module AnsibleTower
    module Operations
      class Processor
        include Logging

        def self.process!(message)
          new(message).process
        end

        def initialize(message)
          self.message = message
        end

        def process
          # TODO: handle the operation
        end

        private
        attr_accessor :message
      end
    end
  end
end
