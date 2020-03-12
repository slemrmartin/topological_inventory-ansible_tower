require "manageiq/loggers"

module TopologicalInventory
  module AnsibleTower
    class << self
      attr_writer :logger
    end

    def self.logger
      @logger ||= ManageIQ::Loggers::CloudWatch.new
      @logger
    end

    module Logging
      def logger
        TopologicalInventory::AnsibleTower.logger
      end

      def log_with(request_id)
        old_request_id = Thread.current[:request_id]
        Thread.current[:request_id] = request_id

        yield
      ensure
        Thread.current[:request_id] = old_request_id
      end
    end
  end
end
