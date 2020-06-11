require "sources-api-client"
require "active_support/core_ext/numeric/time"
require "topological_inventory/ansible_tower/connection"
require "topological_inventory/ansible_tower/operations/core/authentication_retriever"

module TopologicalInventory
  module AnsibleTower
    module Operations
      class Source
        include Logging
        STATUS_AVAILABLE, STATUS_UNAVAILABLE = %w[available unavailable].freeze

        ERROR_MESSAGES = {
          :authentication_not_found => "Authentication not found in Sources API",
          :endpoint_not_found       => "Endpoint not found in Sources API",
        }.freeze

        LAST_CHECKED_AT_THRESHOLD = 5.minutes.freeze

        attr_accessor :params, :request_context, :source_id

        def initialize(params = {}, request_context = nil)
          self.params          = params
          self.request_context = request_context
          self.source_id       = params['source_id']
        end

        def availability_check
          return if params_missing?

          return if checked_recently?

          status, error_message = connection_status

          update_source_and_endpoint(status, error_message)

          logger.info("Source#availability_check completed: Source #{source_id} is #{status}")
        end

        private

        def required_params
          %w[source_id]
        end

        def params_missing?
          is_missing = false
          required_params.each do |attr|
            if (is_missing = params[attr].blank?)
              logger.error("Source#availability_check - Missing #{attr} for the availability_check request [Source ID: #{source_id}]")
              break
            end
          end

          is_missing
        end

        def checked_recently?
          return false if endpoint.nil?

          checked_recently = endpoint.last_checked_at.present? && endpoint.last_checked_at >= LAST_CHECKED_AT_THRESHOLD.ago
          logger.info("Source#availability_check - Skipping, last check at #{endpoint.last_checked_at} [Source ID: #{source_id}] ") if checked_recently

          checked_recently
        end

        def connection_status
          return [STATUS_UNAVAILABLE, ERROR_MESSAGES[:endpoint_not_found]] unless endpoint
          return [STATUS_UNAVAILABLE, ERROR_MESSAGES[:authentication_not_found]] unless authentication

          connection_check
        end

        def connection_check
          check_time
          connection = ::TopologicalInventory::AnsibleTower::Connection.new
          connection = connection.connect(endpoint.host, authentication.username, authentication.password)
          connection.api.version

          [STATUS_AVAILABLE, nil]
        rescue => e
          logger.error("Source#availability_check - Failed to connect to Source id:#{source_id} - #{e.message}")
          [STATUS_UNAVAILABLE, e.message]
        end

        def update_source_and_endpoint(status, error_message = nil)
          logger.info("Source#availability_check - updating source [#{source_id}] status [#{status}] message [#{error_message}]")

          update_source(status)
          update_endpoint(status, error_message)
        end

        def update_source(status)
          source = ::SourcesApiClient::Source.new
          source.availability_status = status
          source.last_checked_at     = check_time
          source.last_available_at   = check_time if status == STATUS_AVAILABLE

          api_client.update_source(source_id, source)
        rescue SourcesApiClient::ApiError => e
          logger.error("Source#availability_check - Failed to update Source id:#{source_id} - #{e.message}")
        end

        def update_endpoint(status, error_message)
          if endpoint.nil?
            logger.error("Source#availability_check - Failed to update Endpoint for Source id:#{source_id}. Endpoint not found")
            return
          end

          endpoint_update = SourcesApiClient::Endpoint.new

          endpoint_update.availability_status       = status
          endpoint_update.availability_status_error = error_message.to_s
          endpoint_update.last_checked_at           = check_time
          endpoint_update.last_available_at         = check_time if status == STATUS_AVAILABLE

          api_client.update_endpoint(endpoint.id, endpoint_update)
        rescue SourcesApiClient::ApiError => e
          logger.error("Source#availability_check - Failed to update Endpoint(ID: #{endpoint.id}) - #{e.message}")
        end

        def endpoint
          @endpoint ||= api_client.list_source_endpoints(source_id)&.data&.detect(&:default)
        end

        def authentication
          return @authentication if @authentication.present?

          endpoint_authentications = api_client.list_endpoint_authentications(endpoint.id.to_s).data || []
          return nil if endpoint_authentications.empty?

          auth_id = endpoint_authentications.first.id
          @authentication = Core::AuthenticationRetriever.new(auth_id, identity).process
        end

        def check_time
          @check_time ||= Time.now.utc
        end

        def identity
          @identity ||= {"x-rh-identity" => Base64.strict_encode64({"identity" => {"account_number" => params["external_tenant"], "user" => {"is_org_admin" => true}}}.to_json)}
        end

        def api_client
          @api_client ||= begin
            api_client = ::SourcesApiClient::ApiClient.new
            api_client.default_headers.merge!(identity)
            ::SourcesApiClient::DefaultApi.new(api_client)
          end
        end
      end
    end
  end
end
