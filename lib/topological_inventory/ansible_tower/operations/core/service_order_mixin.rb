module TopologicalInventory
  module AnsibleTower
    module Operations
      module Core
        module ServiceOrderMixin
          SLEEP_POLL = 10
          POLL_TIMEOUT = 1800


          def order
            task_id, service_offering_id, service_plan_id, order_params = params.values_at(
              "task_id", "service_offering_id", "service_plan_id", "order_params")

            logger.info("ServiceOffering#order: Task(id: #{task_id}), ServiceOffering(:id #{service_offering_id}): order method entered")

            update_task(task_id, :state => "running", :status => "ok")

            service_plan          = topology_api_client.show_service_plan(service_plan_id.to_s) if service_plan_id
            service_offering_id ||= service_plan.service_offering_id
            service_offering      = topology_api_client.show_service_offering(service_offering_id.to_s)

            source_id = service_offering.source_id
            client    = ansible_tower_client(source_id, task_id, identity)

            job_type = parse_svc_offering_type(service_offering)

            logger.info("ServiceOffering#order: Task(id: #{task_id}): Ordering ServiceOffering(id: #{service_offering.id}, source_ref: #{service_offering.source_ref})...")
            job = client.order_service(job_type, service_offering.source_ref, order_params)
            logger.info("ServiceOffering#order: Task(id: #{task_id}): Ordering ServiceOffering(id: #{service_offering.id}, source_ref: #{service_offering.source_ref})...Complete, Job(:id #{job&.id}) has launched.")

            poll_order_complete_thread(task_id, source_id, job, service_offering)
          rescue StandardError => err
            logger.error("ServiceOffering#order: Task(id: #{task_id}), ServiceOffering(id: #{service_offering} source_ref: #{service_offering.source_ref}): Ordering error: #{err.cause} #{err}\n#{err.backtrace.join("\n")}")
            update_task(task_id, :state => "completed", :status => "error", :context => {:error => err.to_s})
          end

          def poll_order_complete_thread(task_id, source_id, job, service_offering)
            Thread.new(Thread.current[:request_id]) do |request_id|
              log_with(request_id) do
                begin
                  poll_order_complete(task_id, source_id, job, service_offering)
                rescue StandardError => err
                  logger.error("ServiceOffering#order: Task(id: #{task_id}) Job(:id #{job.id}) ServiceOffering(id: #{service_offering.id}, source_ref: #{service_offering.source_ref}) Waiting for complete: #{err}\n#{err.backtrace.join("\n")}")
                  update_task(task_id, :state => "completed", :status => "warn", :context => {:error => err.to_s})
                end
              end
            end
          end

          # @param job [AnsibleTowerClient::Job]
          def poll_order_complete(task_id, source_id, job, service_offering)
            context = {
              :service_instance => {
                :source_id  => source_id,
                :source_ref => job.id
              }
            }

            logger.info("ServiceOffering#order: Task(id: #{task_id}), ServiceOffering(id: #{service_offering.id}, source_ref: #{service_offering.source_ref}): Entering poll_order_complete with #{context.inspect}")

            client = ansible_tower_client(source_id, task_id, identity)

            logger.info("ServiceOffering#order: Task(id: #{task_id}), ServiceOffering(id: #{service_offering.id}, source_ref: #{service_offering.source_ref}): Waiting for finishing Job(id: #{job.id}) has started.")

            job = client.wait_for_job_finished(task_id, job, context)

            logger.info("ServiceOffering#order: Task(id: #{task_id}), ServiceOffering(id: #{service_offering.id}, source_ref: #{service_offering.source_ref}): Waiting has finished for Job(id: #{job.id}, status: #{job.status}).")

            context[:remote_status] = job.status
            task_status = client.job_status_to_task_status(job.status)

            logger.info("ServiceOffering#order: Task(id: #{task_id}), ServiceOffering(id: #{service_offering.id}, source_ref: #{service_offering.source_ref}): Waiting to appear Job(id: #{job.id}), Source(id: #{source_id}) has started in Topological Inventory.")
            svc_instance = wait_for_service_instance(source_id, job.id)
            logger.info("ServiceOffering#order: Task(id: #{task_id}), ServiceOffering(id: #{service_offering.id}, source_ref: #{service_offering.source_ref}): Waiting to appear Job(id: #{job.id}), Source(id: #{source_id}) has finished in Topological Inventory.")

            if svc_instance.present?
              logger.info("ServiceOffering#order: Task(id: #{task_id}), ServiceOffering(id: #{service_offering.id}, source_ref: #{service_offering.source_ref}): Job(id: #{job.id}) has appeared as ServiceInstance(id: #{svc_instance.id}) in Topological Inventory")
              context[:service_instance][:id] = svc_instance.id
              context[:service_instance][:url] = svc_instance.external_url
            else
              # If we failed to find the service_instance in the topological-inventory-api
              # within 30 minutes then something went wrong.
              task_status = "error"
              error_message = "Failed to find Job(id: #{job.id}) as ServiceInstance by Source(id: #{source_id}) in Topological Inventory"
              logger.error("ServiceOffering#order: Task(id: #{task_id}), ServiceOffering(id: #{service_offering.id}, source_ref: #{service_offering.source_ref}): #{error_message} in Topological Inventory")
              context[:error] = error_message
            end

            update_task(task_id, :state => "completed", :status => task_status, :context => context)
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
end
