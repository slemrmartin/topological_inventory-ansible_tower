require "topological_inventory/ansible_tower/logging"
require "topological_inventory-api-client"
require "topological_inventory/ansible_tower/operations/core/ansible_tower_client"
require "topological_inventory/ansible_tower/operations/core/topology_api_client"

module TopologicalInventory
  module AnsibleTower
    module Operations
      class Processor
        include Logging
        include Core::TopologyApiClient

        SLEEP_POLL = 10
        POLL_TIMEOUT = 1800

        def self.process!(message)
          model, method = message.headers['message_type'].to_s.split(".")
          new(model, method, message.payload).process
        end

        # @param payload [Hash] https://github.com/ManageIQ/topological_inventory-api/blob/master/app/controllers/api/v0/service_plans_controller.rb#L32-L41
        def initialize(model, method, payload)
          self.model           = model
          self.method          = method
          self.params          = payload["params"]
          self.identity        = payload["request_context"]
        end

        def process
          logger.info("Processing #{model}##{method} [#{params}]...")
          result = order_service(params)
          logger.info("Processing #{model}##{method} [#{params}]...Complete")

          result
        end

        private

        attr_accessor :identity, :model, :method, :params

        def order_service(params)
          task_id, service_offering_id, service_plan_id, order_params = params.values_at("task_id", "service_offering_id", "service_plan_id", "order_params")

          # @deprecated, ordering by service plan will be removed
          if service_offering_id.nil? && service_plan_id.present?
            service_plan     = topology_api_client.show_service_plan(service_plan_id)
            service_offering_id = service_plan.service_offering_id
          end
          service_offering = topology_api_client.show_service_offering(service_offering_id)

          source_id        = service_offering.source_id

          client = ansible_tower_client(source_id, task_id, identity)

          job_type = parse_svc_offering_type(service_offering)

          logger.info("Ordering #{service_offering.name}...")
          job = client.order_service_plan(job_type, service_offering.source_ref, order_params)
          logger.info("Ordering #{service_offering.name}...Complete")

          poll_order_complete_thread(task_id, source_id, job)
        rescue StandardError => err
          logger.error("[Task #{task_id}] Ordering error: #{err}\n#{err.backtrace.join("\n")}")
          update_task(task_id, :state => "completed", :status => "error", :context => {:error => err.to_s})
        end

        def poll_order_complete_thread(task_id, source_id, job)
          Thread.new do
            begin
              poll_order_complete(task_id, source_id, job)
            rescue StandardError => err
              logger.error("[Task #{task_id}] Waiting for complete: #{err}\n#{err.backtrace.join("\n")}")
              update_task(task_id, :state => "completed", :status => "warn", :context => {:error => err.to_s})
            end
          end
        end

        # @param job [AnsibleTowerClient::Job]
        def poll_order_complete(task_id, source_id, job)
          context = {
            :service_instance => {
              :source_id  => source_id,
              :source_ref => job.id
            }
          }

          client = ansible_tower_client(source_id, task_id, identity)
          job = client.wait_for_job_finished(task_id, job, context)
          context[:remote_status] = job.status

          if job.status == "successful"
            svc_instance = wait_for_service_instance(source_id, job.id)
            if svc_instance.present?
              context[:service_instance][:id] = svc_instance.id
              context[:service_instance][:url] = svc_instance_url(svc_instance)
            end
          end

          update_task(task_id, :state => "completed", :status => client.job_status_to_task_status(job.status), :context => context)
        end

        def wait_for_service_instance(source_id, source_ref)
          api = topology_api_client.api_client

          count = 0
          timeout_count = POLL_TIMEOUT / SLEEP_POLL

          header_params = { 'Accept' => api.select_header_accept(['application/json']) }
          query_params = { :'source_id' => source_id, :'source_ref' => source_ref }
          return_type = 'ServiceInstancesCollection'

          service_instance = nil
          loop do
            data, _status_code, _headers = api.call_api(:GET, "/service_instances",
                                                        :header_params => header_params,
                                                        :query_params  => query_params,
                                                        :auth_names    => ['UserSecurity'],
                                                        :return_type   => return_type)

            service_instance = data.data&.first if data.meta.count > 0
            break if service_instance.present?

            break if (count += 1) >= timeout_count

            sleep(SLEEP_POLL) # seconds
          end

          if service_instance.nil?
            logger.error("Failed to find service_instance by source_id [#{source_id}] source_ref [#{source_ref}]")
          end

          service_instance
        end

        def ansible_tower_client(source_id, task_id, identity)
          Core::AnsibleTowerClient.new(source_id, task_id, identity)
        end

        # Type defined by collector here:
        # lib/topological_inventory/ansible_tower/parser/service_offering.rb:12
        def parse_svc_offering_type(service_offering)
          job_type = service_offering.extra[:type] if service_offering.extra.present?

          raise "Missing service_offering's type: #{service_offering.inspect}" if job_type.blank?
          job_type
        end
      end
    end
  end
end
