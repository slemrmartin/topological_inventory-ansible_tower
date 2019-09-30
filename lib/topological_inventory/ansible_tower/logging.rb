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
    end
  end
end
