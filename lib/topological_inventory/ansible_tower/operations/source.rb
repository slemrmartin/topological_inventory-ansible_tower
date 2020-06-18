require "topological_inventory/ansible_tower/logging"
require "topological_inventory/providers/common/operations/source"
require "topological_inventory/ansible_tower/connection"

module TopologicalInventory
  module AnsibleTower
    module Operations
      class Source < TopologicalInventory::Providers::Common::Operations::Source
        include Logging

        private

        def connection_check
          connection = ::TopologicalInventory::AnsibleTower::Connection.new
          connection = connection.connect(endpoint.host, authentication.username, authentication.password)
          connection.api.version

          [STATUS_AVAILABLE, nil]
        rescue => e
          logger.availability_check("Failed to connect to Source id:#{source_id} - #{e.message}", :error)
          [STATUS_UNAVAILABLE, e.message]
        end
      end
    end
  end
end
