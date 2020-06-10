require "manageiq-messaging"

module TopologicalInventory
  module AnsibleTower
    class MessagingClient
      OPERATIONS_QUEUE_NAME  = "platform.topological-inventory.operations-ansible-tower".freeze
      REFRESH_QUEUE_NAME = "platform.topological-inventory.collector-ansible-tower".freeze

      # Kafka host name
      attr_accessor :queue_host
      # Kafka port
      attr_accessor :queue_port

      def initialize
        @queue_host = 'localhost'
        @queue_port = 9092
      end

      def self.default
        @@default ||= new
      end

      def self.configure
        if block_given?
          yield(default)
        else
          default
        end
      end

      # Instance of messaging client for Worker
      def worker_listener
        @worker_listener ||= ManageIQ::Messaging::Client.open(worker_listener_opts)
      end

      def targeted_refresh_listener
        @targeted_refresh_listener ||= ManageIQ::Messaging::Client.open(targeted_refresh_listener_opts)
      end

      def worker_listener_queue_opts
        {
          :auto_ack    => false,
          :max_bytes   => 50_000,
          :service     => OPERATIONS_QUEUE_NAME,
          :persist_ref => "topological-inventory-operations-ansible-tower"
        }
      end

      def targeted_refresh_listener_queue_opts
        {
          :service     => REFRESH_QUEUE_NAME,
          :persist_ref => "topological-inventory-collector-ansible-tower"
        }
      end

      private

      def worker_listener_opts
        {
          :client_ref => default_client_ref,
          :host       => @queue_host,
          :port       => @queue_port,
          :protocol   => :Kafka
        }
      end

      def targeted_refresh_listener_opts
        {
          :client_ref => default_client_ref,
          :encoding   => 'json',
          :host       => @queue_host,
          :port       => @queue_port,
          :protocol   => :Kafka
        }
      end

      def default_client_ref
        ENV['HOSTNAME'].presence || SecureRandom.hex(4)
      end
    end
  end
end
