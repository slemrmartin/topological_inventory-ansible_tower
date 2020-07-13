require "topological_inventory/ansible_tower/connection"
require "receptor_controller-client"
require "topological_inventory/ansible_tower/receptor/connection"

module TopologicalInventory::AnsibleTower
  # Connection manager provides connection either for public or on-premise towers
  # depending on provided parameters
  class ConnectionManager
    include Logging

    delegate :api_url, :to => :connection

    attr_reader :connection

    @sync = Mutex.new
    @receptor_client = nil

    # Receptor client needs to be singleton due to processing of kafka responses
    def self.receptor_client
      @sync.synchronize do
        return @receptor_client if @receptor_client.present?

        @receptor_client = ReceptorController::Client.new(:logger => TopologicalInventory::AnsibleTower.logger)
        @receptor_client.start
      end
      @receptor_client
    end

    # Stops thread with response worker
    def self.stop_receptor_client
      @sync.synchronize do
        @receptor_client&.stop
      end
    end

    def initialize(source)
      @connection = nil
      @source = source
    end

    # Chooses type of client depending on provided params.
    # If `receptor_node` and `account_number` set, Receptor API Client is returned (on-premise), AnsibleTowerClient otherwise
    #
    # @return [AnsibleTowerClient::Connection | TopologicalInventory::AnsibleTower::Receptor::ApiClient]
    def connect(base_url: nil, username: nil, password: nil, verify_ssl: ::OpenSSL::SSL::VERIFY_NONE,
                receptor_node: nil, account_number: nil)
      if receptor_node
        receptor_api_client(receptor_node, account_number)
      elsif base_url
        ansible_tower_api_client(base_url, username, password, :verify_ssl => verify_ssl)
      else
        logger.error("ConnectionManager: Invalid connection data; :source_uid => #{@source}")
        nil
      end
    end

    def receptor_client
      self.class.receptor_client
    end

    private

    def receptor_api_client(receptor_node, account_number)
      @connection = TopologicalInventory::AnsibleTower::Receptor::Connection.new(
        receptor_client, receptor_node, account_number
      )
    end

    def ansible_tower_api_client(base_url, username, password, verify_ssl:)
      @connection = TopologicalInventory::AnsibleTower::Connection.new
      @connection.connect(
        base_url, username, password,
        :verify_ssl => verify_ssl
      )
    end
  end
end
