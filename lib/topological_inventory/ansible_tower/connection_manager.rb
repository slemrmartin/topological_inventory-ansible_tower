require "topological_inventory/ansible_tower/connection"
require "receptor_controller-client"
require "topological_inventory/ansible_tower/receptor/api_client"

module TopologicalInventory::AnsibleTower
  class ConnectionManager
    include Logging

    delegate :api_url, :to => :connection

    attr_reader :connection

    @@sync = Mutex.new
    @@receptor_client = nil

    def self.receptor_client
      @@sync.synchronize do
        return @@receptor_client if @@receptor_client.present?

        @@receptor_client = ReceptorController::Client.new(:logger => TopologicalInventory::AnsibleTower.logger)
        @@receptor_client.start
      end
      @@receptor_client
    end

    def self.stop_receptor_client
      @@sync.synchronize do
        if @@receptor_client.present?
          @@receptor_client.stop
        end
      end
    end

    def initialize
      @connection = nil
    end

    def connect(base_url: nil, username: nil, password: nil, verify_ssl: ::OpenSSL::SSL::VERIFY_NONE,
                receptor_node: nil, account_number: nil)
      if receptor_node && account_number
        receptor_api_client(receptor_node, account_number)
      else
        ansible_tower_api_client(base_url, username, password, :verify_ssl => verify_ssl)
      end
    end

    def receptor_client
      self.class.receptor_client
    end

    private

    def receptor_api_client(receptor_node, account_number)
      @connection = TopologicalInventory::AnsibleTower::Receptor::ApiClient.new(
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
