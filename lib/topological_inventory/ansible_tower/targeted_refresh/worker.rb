require "topological_inventory/ansible_tower/operations/worker"
require "topological_inventory/ansible_tower/targeted_refresh/processor"

module TopologicalInventory
  module AnsibleTower
    module TargetedRefresh
      class Worker < TopologicalInventory::AnsibleTower::Operations::Worker
        private

        def client
          @client ||= TopologicalInventory::AnsibleTower::MessagingClient.default.targeted_refresh_listener
        end

        def queue_opts
          TopologicalInventory::AnsibleTower::MessagingClient.default.targeted_refresh_listener_queue_opts
        end

        def process_message(message)
          model, method = message.message.to_s.split(".")
          payload = JSON.parse(payload) if payload.kind_of?(String)

          TargetedRefresh::Processor.process!(message, payload)
        rescue JSON::ParserError => e
          logger.error("#{model}##{method}: Failed to parse payload: #{payload}")
          raise
        rescue StandardError => err
          task_id = payload&.fetch_path('params', 'task_id')
          logger.error("#{model}##{method}: Task(id: #{task_id}) #{err.cause}\n#{err}\n#{err.backtrace.join("\n")}")
          raise
        ensure
          message.ack
        end
      end
    end
  end
end
