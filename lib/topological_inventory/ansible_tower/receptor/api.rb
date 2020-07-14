require 'ansible_tower_client'

module TopologicalInventory::AnsibleTower
  module Receptor
    class Api < ::AnsibleTowerClient::Api
      attr_accessor :connection

      def initialize(receptor_connection)
        super(nil)
        self.connection = receptor_connection
      end

      def get(path)
        Receptor::ApiObject.new(self, connection, path).get
      end

      def config
        JSON.parse(get('config').body)
      end

      # Not applicable to config object
      def class_from_type(type)
        send("#{type}_class") if respond_to?("#{type}_class")
      end

      # JobTemplate v1 is for Tower version < 3 which we don't support
      # https://bugzilla.redhat.com/show_bug.cgi?id=1369842
      def job_template_class
        @job_template_class ||= AnsibleTowerClient::JobTemplateV2
      end

      def credentials(receiver = nil)
        Receptor::ApiObject.new(self, connection, 'credentials', receiver)
      end

      def credential_types(receiver = nil)
        Receptor::ApiObject.new(self, connection, 'credential_types', receiver)
      end

      def job_templates(receiver = nil)
        Receptor::Template.new(self, connection, 'job_templates', receiver)
      end

      def workflow_job_templates(receiver = nil)
        Receptor::Template.new(self, connection, 'workflow_job_templates', receiver)
      end

      def workflow_job_template_nodes(receiver = nil)
        Receptor::ApiObject.new(self, connection, 'workflow_job_template_nodes', receiver)
      end

      def jobs(receiver = nil)
        Receptor::ApiObject.new(self, connection, 'jobs', receiver)
      end

      def workflow_jobs(receiver = nil)
        Receptor::ApiObject.new(self, connection, 'workflow_jobs', receiver)
      end

      def workflow_job_nodes(receiver = nil)
        Receptor::ApiObject.new(self, connection, 'workflow_job_nodes', receiver)
      end

      def inventories(receiver = nil)
        Receptor::ApiObject.new(self, connection, 'inventories', receiver)
      end
    end
  end
end
