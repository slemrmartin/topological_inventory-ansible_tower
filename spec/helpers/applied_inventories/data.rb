module AppliedInventories
  module Data
    # Structure of Job Template / Workflow with Inventories and Nodes
    # Hash of samples <Name, Workflow>, each key-pair is one test case
    # Results are in :applied_inventories array
    def templates_and_workflows_data
      job_templates.merge(simple_workflows).merge(nested_workflows)
    end

    # :applied_inventories results are shown for each leaf (job template) in order defined by `workflow_child_nodes`
    def nested_workflows
      {
        'Nested Workflow 1' => {
          :applied_inventories => [ inventory('1'), inventory('10001'), inventory('3'), inventory('10001'), inventory('10001'), inventory('10001') ].uniq,
          :prompted_inventory => inventory('0'),
          :template => workflow('10001', inventory('10001').id),
          :inventory => inventory('10001'),
          :child_nodes => [
            {
              :node => node('1101', workflow('10001').id, workflow('1001').id, inventory('1101').id),
              :inventory => inventory('1101'),
              :template => {
                :template => workflow('1001', nil, true),
                :inventory => nil,
                :child_nodes => workflow_child_nodes('1001')
              }
            }
          ]
        },
        'Nested Workflow 2' => {
          :applied_inventories => [ inventory('1'), nil, inventory('3'), inventory('104'), inventory('5'), inventory('106') ].compact.uniq,
          :prompted_inventory => nil,
          :template => workflow('10002'),
          :inventory => nil,
          :child_nodes => [
            {
              :node => node('1101', workflow('10002').id, '1001', nil),
              :inventory => nil,
              :template => {
                :template => workflow('1001', nil, true),
                :inventory => nil,
                :child_nodes => workflow_child_nodes('1001')
              }
            }
          ]
        },
        'Nested Workflow 3' => {
          :applied_inventories => [ inventory('1'), inventory('1101'), inventory('3'), inventory('1101'), inventory('1101'), inventory('1101') ].uniq,
          :prompted_inventory => inventory('0'),
          :template => workflow('10003'),
          :inventory => nil,
          :child_nodes => [
            {
              :node => node('1101', workflow('10003').id, '1001', inventory('1101').id),
              :inventory => inventory('1101'),
              :template => {
                :template => workflow('1001', nil, true),
                :inventory => nil,
                :child_nodes => workflow_child_nodes('1001')
              }
            }
          ]
        },
        'Nested Workflow 4' => {
          :applied_inventories => [ inventory('1'), inventory('0'), inventory('3'), inventory('0'), inventory('0'), inventory('0') ].uniq,
          :prompted_inventory => inventory('0'),
          :template => workflow('10003', inventory('10003').id, true),
          :inventory => inventory('10003'),
          :child_nodes => [
            {
              :node => node('1101', workflow('10003').id, '1001', inventory('1101').id),
              :inventory => inventory('1101'),
              :template => {
                :template => workflow('1001', inventory('1001').id, true),
                :inventory => inventory('1001'),
                :child_nodes => workflow_child_nodes('1001')
              }
            }
          ]
        }
      }
    end

    # :applied_inventories results are shown for each leaf (job template) in order defined by `workflow_child_nodes`
    def simple_workflows
      {
        'Workflow 1' => {
          :applied_inventories => [ inventory('1'), nil, inventory('3'), inventory('104'), inventory('5'), inventory('106') ].compact,
          :prompted_inventory => nil,
          :template => workflow('1001'),
          :inventory => nil,
          :child_nodes => workflow_child_nodes('1001')
        },
        'Workflow 2' => {
          :applied_inventories => [ inventory('1'), inventory('1002'), inventory('3'), inventory('1002'), inventory('1002'), inventory('1002') ].uniq,
          :prompted_inventory => nil,
          :template => workflow('1002', inventory('1002').id),
          :inventory => inventory('1002'),
          :child_nodes => workflow_child_nodes('1002')
        },
        'Workflow 3' => {
          :applied_inventories => [ inventory('1'), inventory('1003'), inventory('3'), inventory('1003'), inventory('1003'), inventory('1003') ].uniq,
          :prompted_inventory => inventory('0'),
          :template => workflow('1003', inventory('1003').id),
          :inventory => inventory('1003'),
          :child_nodes => workflow_child_nodes('1003')
        },
        'Workflow 4' => {
          :applied_inventories => [ inventory('1'), inventory('0'), inventory('3'), inventory('0'), inventory('0'), inventory('0') ].uniq,
          :prompted_inventory => inventory('0'),
          :template => workflow('1004', inventory('1004').id, true),
          :inventory => inventory('1004'),
          :child_nodes => workflow_child_nodes('1004')
        },
        'Workflow 5' => {
          :applied_inventories => [ inventory('1'), inventory('1005'), inventory('3'), inventory('1005'), inventory('1005'), inventory('1005') ].uniq,
          :prompted_inventory => nil,
          :template => workflow('1005', inventory('1005').id, true),
          :inventory => inventory('1005'),
          :child_nodes => workflow_child_nodes('1005')
        },
        'Workflow 6' => {
          :applied_inventories => [ inventory('1'), nil, inventory('3'), inventory('104'), inventory('5'), inventory('106') ].compact,
          :prompted_inventory => nil,
          :template => workflow('1006', nil, true),
          :inventory => nil,
          :child_nodes => workflow_child_nodes('1006')
        }
      }
    end

    def job_templates
      {
        'Job Template 1' => {
          :applied_inventories => [ inventory('1') ],
          :template => job_template('1', inventory('1').id),
          :inventory => inventory('1'),
        },
        'Job Template 2' => {
          :applied_inventories => [ inventory('1') ],
          :prompted_inventory => inventory('1'),
          :template => job_template('1', inventory('1').id),
          :inventory => inventory('1')
        },
        'Job Template 3' => {
          :applied_inventories => [],
          :prompted_inventory => nil, # This combination isn't possible to launch in Tower
          :template => job_template('1', nil, true),
        },
        'Job Template 4' => {
          :applied_inventories => [ inventory('1') ],
          :prompted_inventory => inventory('1'),
          :template => job_template('1', nil, true)
        },
      }
    end

    def workflow_child_nodes(root_service_offering_id)
      [
        {
          :node => node('101', root_service_offering_id, job_template('1').id),
          :inventory => nil,
          :template => {
            :template => job_template('1', inventory('1').id),
            :inventory => inventory('1')
          }
        },
        {
          :node => node('102', root_service_offering_id, '2'),
          :inventory => nil,
          :template => {
            :template => job_template('2', nil, true)
          }
        },
        {
          :node => node('103', root_service_offering_id, '3', inventory('103').id),
          :inventory => inventory('103'),
          :template => {
            :template => job_template('3', inventory('3').id, false),
            :inventory => inventory('3')
          }
        },
        {
          :node => node('104', root_service_offering_id, '4', inventory('104').id),
          :inventory => inventory('104'),
          :template => {
            :template => job_template('4', inventory('4').id, true),
            :inventory => inventory('4')
          }
        },
        {
          :node => node('105', root_service_offering_id, '5'),
          :inventory => nil,
          :template => {
            :template => job_template('5', inventory('5').id, true),
            :inventory => inventory('5')
          }
        },
        {
          :node => node('106', root_service_offering_id, '6', inventory('106').id),
          :inventory => inventory('106'),
          :template => {
            :template => job_template('6', nil, true)
          }
        }
      ]
    end

    #################
    # H E L P E R S #
    #################

    def job_template(id, service_inventory_id = nil, prompt_on_launch = false)
      add_job_template(:id                   => id,
                       :service_inventory_id => service_inventory_id,
                       :prompt_on_launch     => prompt_on_launch)
    end

    def workflow(id, service_inventory_id = nil, prompt_on_launch = false)
      add_workflow_template(:id                   => id,
                            :service_inventory_id => service_inventory_id,
                            :prompt_on_launch     => prompt_on_launch)
    end

    def node(id, root_service_offering_id, service_offering_id, service_inventory_id = nil)
      add_node(:id => id, :service_inventory_id => service_inventory_id, :root_service_offering_id => root_service_offering_id, :service_offering_id => service_offering_id)
    end

    def inventory(id)
      add_inventory(:id => id.to_s)
    end

    def inventory_collection(inventories)
      TopologicalInventoryApiClient::ServiceInventoriesCollection.new(:data => inventories)
    end

    def node_collection(nodes)
      TopologicalInventoryApiClient::ServiceOfferingNodesCollection.new(:data => nodes)
    end

    def template_collection(templates)
      TopologicalInventoryApiClient::ServiceOfferingsCollection.new(:data => templates)
    end

    private

    def add_inventory(id:)
      TopologicalInventoryApiClient::ServiceInventory.new(:id         => id,
                                                          :source_id  => source_id,
                                                          :name       => "Inventory #{id}")
    end

    def add_node(id:, service_inventory_id:, service_offering_id:, root_service_offering_id:)
      TopologicalInventoryApiClient::ServiceOfferingNode.new(:id => id,
                                                             :name => "Node #{id}",
                                                             :source_id => source_id,
                                                             :root_service_offering_id => root_service_offering_id,
                                                             :service_offering_id => service_offering_id,
                                                             :service_inventory_id => service_inventory_id)
    end

    def add_template(id:, service_inventory_id:, prompt_on_launch:, type:)
      TopologicalInventoryApiClient::ServiceOffering.new(:id => id,
                                                         :name => "ServiceOffering #{id}",
                                                         :source_id => source_id,
                                                         :service_inventory_id => service_inventory_id,
                                                         :extra => { :type => type, :ask_inventory_on_launch => prompt_on_launch})
    end

    def add_job_template(id:, service_inventory_id:, prompt_on_launch:)
      add_template(:id => id,
                   :service_inventory_id => service_inventory_id,
                   :prompt_on_launch => prompt_on_launch,
                   :type => 'job_template')
    end

    def add_workflow_template(id:, service_inventory_id:, prompt_on_launch:)
      add_template(:id => id,
                   :service_inventory_id => service_inventory_id,
                   :prompt_on_launch => prompt_on_launch,
                   :type => 'workflow_job_template')
    end

    def source_id
      '1'
    end
  end
end
