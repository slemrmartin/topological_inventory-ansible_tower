require "topological_inventory/ansible_tower/collector"
require "topological_inventory/providers/common/operations/sources_api_client"

# TODO: make a mixin
require "topological_inventory/providers/common/operations/source"

module TopologicalInventory
  module AnsibleTower
    module TargetedRefresh
      class ServiceInstance < TopologicalInventory::AnsibleTower::Collector
        def initialize(params = {}, identity = nil)
          self.params   = params
          self.identity = identity
          # TODO: add metrics exporter
          super(params['source_uid'], nil, nil, nil, nil)
        end

        # Entrypoint for 'ServiceInstance.refresh' operation
        def refresh
          self.source_id, service_instance_refs = params.values_at("source_id", "service_instances")

          set_connection_data!

          parser = TopologicalInventory::AnsibleTower::Parser.new(tower_url: tower_hostname)

          child_service_instance_refs = []
          get_service_instances(service_instance_refs, connection).each do |service_instance|
            parser.parse_service_instance(service_instance)
            get_service_instance_nodes(service_instance, connection).each do |service_instance_node|
              parser.parse_service_instance_node(service_instance_node)
              service_instance_ref = node.summary_fields.job&.id&.to_s
              child_service_instance_refs << service_instance_ref if service_instance_ref
            end

            # Can be recursive for child workflow jobs (if needed)
            get_service_instances(child_service_instance_refs, connection).each do |service_instance|
              parser.parse_service_instance(service_instance)
            end
          end

          save_inventory(parser.connection.values, inventory_name, schema_name, SecureRandom.uuid, SecureRandom.uuid, Time.now.utc)
        end

        private

        attr_accessor :source_id

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