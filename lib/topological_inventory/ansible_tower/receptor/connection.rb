require "topological_inventory/ansible_tower/receptor/exception"
require "topological_inventory/ansible_tower/receptor/api_object"
require "topological_inventory/ansible_tower/receptor/template"
require "topological_inventory/ansible_tower/receptor/response"
require "topological_inventory/ansible_tower/receptor/api"

module TopologicalInventory::AnsibleTower
  module Receptor
    # On-premise connection through Receptor
    class Connection
      include Logging

      RECEPTOR_REQUEST_PATH = "job".freeze

      attr_reader :account_number, :receptor_client, :receptor_node

      def initialize(receptor_client, receptor_node, account_number)
        self.receptor_client   = receptor_client

        self.receptor_node     = receptor_node
        self.account_number    = account_number
        receptor_client.identity_header = identity_header
      end

      def api
        @api ||= Api.new(self)
      end

      # For logging purposes (compatible with AnsibleTowerClient connection)
      def api_url(base_url)
        File.join(base_url, default_api_path)
      end

      def default_api_path
        "/api/v2".freeze
      end

      # This header is used only when ReceptorController::Client::Configuration.pre_shared_key is blank (x-rh-rbac-psk)
      # org_id with any number is required by receptor_client controller
      def identity_header(account = account_number)
        @identity ||= {
          "x-rh-identity" => Base64.strict_encode64(
            {"identity" => {"account_number" => account, "user" => {"is_org_admin" => true}, "internal" => {"org_id" => '000001'}}}.to_json
          )
        }
      end

      protected

      attr_writer :account_number, :receptor_client, :receptor_node
    end
  end
end
