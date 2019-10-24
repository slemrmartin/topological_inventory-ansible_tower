require "topological_inventory-api-client"
require "topological_inventory/ansible_tower/operations/core/ansible_tower_client"
require "topological_inventory/ansible_tower/operations/core/service_order_mixin"
require "topological_inventory/ansible_tower/operations/core/topology_api_client"
require "topological_inventory/ansible_tower/operations/approval_inventories/parser"

module TopologicalInventory
  module AnsibleTower
    module Operations
      class ServiceOffering
        include Logging
        include Core::TopologyApiClient
        include Core::ServiceOrderMixin

        attr_accessor :params, :identity

        def initialize(params = {}, identity = nil)
          @params   = params
          @identity = identity
        end

        def approval_inventories
          task_id, service_offering_id, inventory_params = params.values_at("task_id", "service_offering_id", "inventory_params")

          service_offering = topology_api_client.show_service_offering(service_offering_id.to_s)
          prompted_inventory_id = inventory_params['prompted_inventory_id']

          parser = TopologicalInventory::AnsibleTower::Operations::ApprovalInventories::Parser.new(service_offering, prompted_inventory_id)
          inventories = if parser.is_workflow_template?(service_offering)
                          parser.load_workflow_template_inventories
                        else
                          [ parser.load_job_template_inventory ]
                        end

          update_task(task_id, :state => "completed", :status => "ok", :context => { :approval_inventories => inventories })
        rescue StandardError => err
          logger.error("[Task #{task_id}] ApprovalInventories error: #{err}\n#{err.backtrace.join("\n")}")
          update_task(task_id, :state => "completed", :status => "error", :context => { :error => err.to_s })
        end
      end
    end
  end
end
