require "topological_inventory/ansible_tower/collector"
require "topological_inventory/providers/common/operations/sources_api_client"

module TopologicalInventory
  module AnsibleTower
    module TargetedRefresh
      class ServiceInstance < TopologicalInventory::AnsibleTower::Collector
        def initialize(payload = {})
          self.params    = payload['params']
          self.source_id = payload['source_id']

          # TODO: add metrics exporter
          super(payload['source_uid'], nil, nil, nil, nil)
        end

        # Entrypoint for 'ServiceInstance.refresh' operation
        def refresh
          tasks_id = params.to_a.collect { |task| task['task_id'] }.compact.join(' | ')
          service_instance_refs = params&.collect { |task| task['source_ref'] }

          set_connection_data!
          logger.info("ServiceInstance#refresh - Task(id: #{tasks_id}: Connection data set successfully")

          parser = TopologicalInventory::AnsibleTower::Parser.new(tower_url: tower_hostname)

          child_service_instance_refs = []
          get_service_instances(connection, :refs => service_instance_refs).each do |service_instance|
            parser.parse_service_instance(service_instance)
            next unless service_instance[:job_type] == 'workflow_job'

            get_service_instance_nodes(connection, :workflow => service_instance[:job]).each do |service_instance_node|
              parser.parse_service_instance_node(service_instance_node)
              service_instance_ref = service_instance_node.summary_fields.job&.id&.to_s
              child_service_instance_refs << service_instance_ref if service_instance_ref.present?
            end

            # Can be recursive for child workflow jobs if needed
            get_service_instances(connection, :refs => child_service_instance_refs).each do |service_instance|
              parser.parse_service_instance(service_instance)
            end
          end

          logger.info("ServiceInstance#refresh - Task(id: #{tasks_id}: Sending to Ingress API...")
          save_inventory(parser.collections.values, inventory_name, schema_name, SecureRandom.uuid, SecureRandom.uuid, Time.now.utc)
          logger.info("ServiceInstance#refresh - Task(id: #{tasks_id}: Sending to Ingress API...Complete")
        rescue StandardError => err
          logger.error("ServiceInstance#refresh - Task(id: #{tasks_id}: Error: #{err.message}\n#{err.backtrace.join("\n")}")
        end

        private

        attr_accessor :params, :source_id

        # Queries Sources API in the context of first task
        def identity
          @identity ||= params.to_a.first['request_context']
        end

        def connection
          connection_for_entity_type(nil)
        end

        def set_connection_data!
          raise TopologicalInventory::Providers::Common::Operations::Source::ERROR_MESSAGES[:endpoint_not_found] unless endpoint
          raise TopologicalInventory::Providers::Common::Operations::Source::ERROR_MESSAGES[:authentication_not_found] unless authentication

          self.tower_hostname = endpoint.host # TODO taken from operations/source, but it's more complex in collectors_pool.rb
          self.tower_user = authentication.username
          self.tower_passwd = authentication.password
        end

        # TODO: Deduplicate
        def endpoint
          @endpoint ||= api_client.fetch_default_endpoint(source_id)
        end

        # TODO: Deduplicate
        def authentication
          @authentication ||= api_client.fetch_authentication(source_id, endpoint)
        end

        # TODO: Deduplicate
        def api_client
          @api_client ||= TopologicalInventory::Providers::Common::Operations::SourcesApiClient.new(identity)
        end
      end
    end
  end
end