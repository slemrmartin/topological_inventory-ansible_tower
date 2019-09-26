require "topological_inventory/ansible_tower/logging"
require "topological_inventory/ansible_tower/operations/service_offering"
require "topological_inventory/ansible_tower/operations/service_plan"

module TopologicalInventory
  module AnsibleTower
    module Operations
      class Processor
        include Logging

        def self.process!(message)
          model, method = message.headers['message_type'].to_s.split(".")
          new(model, method, message.payload).process
        end

        # @param payload [Hash] https://github.com/ManageIQ/topological_inventory-api/blob/master/app/controllers/api/v0/service_plans_controller.rb#L32-L41
        def initialize(model, method, payload)
          self.model    = model
          self.method   = method
          self.params   = payload["params"]
          self.identity = payload["request_context"]
        end

        def process
          logger.info("Processing #{model}##{method} [#{params}]...")

          impl = "#{Operations}::#{model}".safe_constantize&.new(params, identity)
          result = impl&.send(method) if impl&.respond_to?(method)

          logger.info("Processing #{model}##{method} [#{params}]...Complete")
          result
        end

        private

        attr_accessor :identity, :model, :method, :params
      end
    end
  end
end
