module TopologicalInventory
  module AnsibleTower
    module Operations
      module Core
        module TopologyApiClient
          def topology_api_client
            @topology_api_client ||=
              begin
                api_client = TopologicalInventoryApiClient::ApiClient.new
                api_client.default_headers.merge!(identity) if identity.present?
                TopologicalInventoryApiClient::DefaultApi.new(api_client)
              end
          end

          def update_task(task_id, state:, status:, context: nil)
            params = {"state" => state, "status" => status }
            params["context"] = context if context
            task = TopologicalInventoryApiClient::Task.new(params)
            topology_api_client.update_task(task_id, task)
          end
        end
      end
    end
  end
end
