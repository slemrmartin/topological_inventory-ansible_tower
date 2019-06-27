require "topological_inventory/ansible_tower/logging"
require "topological_inventory/ansible_tower/operations/processor"

module TopologicalInventory
  module AnsibleTower
    module Operations
      class Worker
        include Logging

        def initialize(messaging_client_opts = {})
          self.messaging_client_opts = default_messaging_opts.merge(messaging_client_opts)
        end

        def run
          # Open a connection to the messaging service
          require "manageiq-messaging"
          client = ManageIQ::Messaging::Client.open(messaging_client_opts)

          logger.info("Topological Inventory AnsibleTower Operations worker started...")
          client.subscribe_messages(queue_opts) do |messages|
            messages.each { |message| process_message(message) }
          end
        ensure
          client&.close
        end

        private

        attr_accessor :messaging_client_opts

        def process_message(message)
          Processor.process!(message)
        rescue => err
          logger.error(err)
          logger.error(err.backtrace.join("\n"))
          raise
        ensure
          message.ack
        end

        def queue_opts
          {
            :auto_ack  => false,
            :max_bytes => 50_000,
            :service   => "platform.topological-inventory.operations-ansible-tower"
          }
        end

        def default_messaging_opts
          {
            :protocol   => :Kafka,
            :client_ref => "ansible_tower-operations-worker",
            :group_ref  => "ansible_tower-operations-worker"
          }
        end
      end
    end
  end
end
