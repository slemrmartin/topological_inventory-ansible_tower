require "topological_inventory/ansible_tower/operations/ansible_tower_client"

module TopologicalInventory::AnsibleTower
  class Parser < TopologicalInventory::Providers::Common::Collector::Parser
    require "topological_inventory/ansible_tower/parser/service_credential"
    require "topological_inventory/ansible_tower/parser/service_instance"
    require "topological_inventory/ansible_tower/parser/service_instance_node"
    require "topological_inventory/ansible_tower/parser/service_inventory"
    require "topological_inventory/ansible_tower/parser/service_plan"
    require "topological_inventory/ansible_tower/parser/service_offering"
    require "topological_inventory/ansible_tower/parser/service_offering_node"
    require "topological_inventory/ansible_tower/parser/service_credential_type"

    include TopologicalInventory::AnsibleTower::Parser::ServiceInstance
    include TopologicalInventory::AnsibleTower::Parser::ServiceInstanceNode
    include TopologicalInventory::AnsibleTower::Parser::ServiceInventory
    include TopologicalInventory::AnsibleTower::Parser::ServicePlan
    include TopologicalInventory::AnsibleTower::Parser::ServiceOffering
    include TopologicalInventory::AnsibleTower::Parser::ServiceOfferingNode
    include TopologicalInventory::AnsibleTower::Parser::ServiceCredential
    include TopologicalInventory::AnsibleTower::Parser::ServiceCredentialType

    def initialize(tower_url:)
      super()
      self.tower_url = tower_client_class.tower_url(tower_url)
    end

    def parse_base_item(entity)
      props = { :resource_timestamp => resource_timestamp }
      props[:name]              = entity.name    if entity.respond_to?(:name)
      props[:source_created_at] = entity.created if entity.respond_to?(:created)
      props
    end

    # Filtering of fields by JMESPath language (implemented by receptor_catalog plugin)
    # Option 'apply_filter' of collector's receptor_params
    def self.receptor_filter_list(fields:, related: nil, summary_fields: nil)
      filter = []
      filter << fields.collect { |col| "#{col}:#{col}" }.join(',') if fields
      filter << "related:{#{related.collect { |col| "#{col}:related.#{col}" }.join(',')}}" if related
      filter << "summary_fields:{#{summary_fields.collect { |col| "#{col}:summary_fields.#{col}" }.join(',')}}" if summary_fields

      {:results => "results[].{#{filter.join(',')}}"}
    end

    protected

    attr_accessor :tower_url

    def tower_client_class
      TopologicalInventory::AnsibleTower::Operations::AnsibleTowerClient
    end
  end
end
