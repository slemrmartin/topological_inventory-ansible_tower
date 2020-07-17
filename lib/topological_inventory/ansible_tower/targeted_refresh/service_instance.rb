require "topological_inventory/ansible_tower/cloud/collector"
require "topological_inventory/providers/common/operations/sources_api_client"

module TopologicalInventory
  module AnsibleTower
    module TargetedRefresh
      class ServiceInstance < TopologicalInventory::AnsibleTower::Cloud::Collector
        REFS_PER_REQUEST_LIMIT = 20

        def initialize(payload = {})
          self.params    = payload['params']
          self.source_id = payload['source_id']

          # TODO: add metrics exporter
          super(payload['source_uid'], nil, nil, nil, nil)
        end

        # Entrypoint for 'ServiceInstance.refresh' operation
        def refresh
          return if params_missing?

          # Connection settings
          set_connection_data!
          logger.info("ServiceInstance#refresh - Connection set successfully")

          # Get all tasks
          tasks, refresh_state_uuid = {}, SecureRandom.uuid
          params.to_a.each do |task|
            if task['task_id'].blank? || task['source_ref'].blank?
              logger.warn("ServiceInstance#refresh - missing data for task: #{task}")
              next
            end
            tasks[task['task_id']] = task['source_ref']

            if tasks.length == REFS_PER_REQUEST_LIMIT
              refresh_part(tasks, refresh_state_uuid, SecureRandom.uuid)
              tasks = {}
            end
          end

          refresh_part(tasks, refresh_state_uuid, SecureRandom.uuid) unless tasks.empty?
        rescue => err
          logger.error("ServiceInstance#refresh - Error: #{err.message}\n#{err.backtrace.join("\n")}")
        end

        private

        attr_accessor :params, :source_id

        def required_params
          %w[source_id source params]
        end

        def params_missing?
          is_missing = false
          required_params.each do |attr|
            if (is_missing = send(attr).blank?)
              logger.error("ServiceInstance#refresh - Missing #{attr} for the availability_check request [Source ID: #{source_id}]")
              break
            end
          end

          is_missing
        end

        def refresh_part(tasks, refresh_state_uuid, refresh_state_part_uuid)
          tasks_id = tasks.keys.join(' | id: ')

          parser = TopologicalInventory::AnsibleTower::Parser.new(:tower_url => tower_hostname)

          # API request, nodes and jobs under workflow job not needed
          query_params = {
            :id__in    => tasks.values.join(','),
            :page_size => limits['service_instances']
          }
          get_service_instances(connection, query_params).each do |service_instance|
            parser.parse_service_instance(service_instance)
          end

          # Sending to Ingress API
          logger.info("ServiceInstance#refresh - Task[ id: #{tasks_id} ] Sending to Ingress API...")
          save_inventory(parser.collections.values, inventory_name, schema_name, refresh_state_uuid, refresh_state_part_uuid)
          logger.info("ServiceInstance#refresh - Task[ id: #{tasks_id} ] Sending to Ingress API...Complete")
        end

        # TODO: add support for on-premise connection
        def connection
          connection_for_entity_type(nil)
        end

        def set_connection_data!
          raise TopologicalInventory::Providers::Common::Operations::Source::ERROR_MESSAGES[:endpoint_not_found] unless endpoint
          raise TopologicalInventory::Providers::Common::Operations::Source::ERROR_MESSAGES[:authentication_not_found] unless authentication

          self.tower_hostname = endpoint.host # TODO: taken from operations/source, but it's more complex in collectors_pool.rb
          self.tower_user = authentication.username
          self.tower_passwd = authentication.password
        end

        def endpoint
          @endpoint ||= api_client.fetch_default_endpoint(source_id)
        end

        def authentication
          @authentication ||= api_client.fetch_authentication(source_id, endpoint)
        end

        # Queries Sources API in the context of first task
        def identity
          @identity ||= params.to_a.first['request_context']
        end

        def api_client
          @api_client ||= TopologicalInventory::Providers::Common::Operations::SourcesApiClient.new(identity)
        end
      end
    end
  end
end
