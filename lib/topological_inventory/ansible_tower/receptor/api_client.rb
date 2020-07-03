require "topological_inventory/ansible_tower/connection"
require "topological_inventory/ansible_tower/receptor/exception"
require "topological_inventory/ansible_tower/receptor/api_object"
require "topological_inventory/ansible_tower/receptor/template"
require "topological_inventory/ansible_tower/receptor/response"
require "topological_inventory/ansible_tower/receptor/tower_api"

module TopologicalInventory::AnsibleTower
  module Receptor
    class ApiClient < TopologicalInventory::AnsibleTower::Connection
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
        self
      end

      # For logging purposes (compatible with AnsibleTowerClient connection)
      def api_url(base_url)
        File.join(base_url, default_api_path)
      end

      def tower_api
        @tower_api ||= TowerApi.new(api)
      end

      def receptor_endpoint_url
        return @receptor_endpoint if @receptor_endpoint.present?

        @receptor_endpoint = receptor_client.config.job_url
      end

      # Not applicable to config object
      def class_from_type(type)
        tower_api.send("#{type}_class") if tower_api.respond_to?("#{type}_class")
      end

      def get(path)
        Receptor::ApiObject.new(api, path).get
      end

      def config(receiver = nil)
        Receptor::ApiObject.new(api, 'config', receiver)
      end

      def credentials(receiver = nil)
        Receptor::ApiObject.new(api, 'credentials', receiver)
      end

      def credential_types(receiver = nil)
        Receptor::ApiObject.new(api, 'credential_types', receiver)
      end

      def job_templates(receiver = nil)
        Receptor::Template.new(api, 'job_templates', receiver)
      end

      def workflow_job_templates(receiver = nil)
        Receptor::Template.new(api,'workflow_job_templates', receiver)
      end

      def workflow_job_template_nodes(receiver = nil)
        Receptor::ApiObject.new(api,'workflow_job_template_nodes', receiver)
      end

      def jobs(receiver = nil)
        Receptor::ApiObject.new(api,'jobs', receiver)
      end

      def workflow_jobs(receiver = nil)
        Receptor::ApiObject.new(api,'workflow_jobs', receiver)
      end

      def workflow_job_nodes(receiver = nil)
        Receptor::ApiObject.new(api,'workflow_job_nodes', receiver)
      end

      def inventories(receiver = nil)
        Receptor::ApiObject.new(api, 'inventories', receiver)
      end

      def default_api_path
        "/api/v2".freeze
      end

      # org_id with any number is required by receptor_client controller
      def identity_header(account = account_number)
        @identity ||= {
          "x-rh-identity" => Base64.strict_encode64(
            {"identity" => {"account_number" => account, "user" => { "is_org_admin" => true }, "internal" => {"org_id" => '000001'}}}.to_json
          )
        }
      end

      protected

      attr_writer :account_number, :base_url, :username, :password,
                  :receptor_client, :receptor_node,
                  :verify_ssl
    end
  end
end
