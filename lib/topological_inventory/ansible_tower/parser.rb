module TopologicalInventory::AnsibleTower
  class Parser < TopologicalInventoryIngressApiClient::Collector::Parser
    require "topological_inventory/ansible_tower/parser/service_instance"
    require "topological_inventory/ansible_tower/parser/service_plan"
    require "topological_inventory/ansible_tower/parser/service_offering"

    include TopologicalInventory::AnsibleTower::Parser::ServiceInstance
    include TopologicalInventory::AnsibleTower::Parser::ServicePlan
    include TopologicalInventory::AnsibleTower::Parser::ServiceOffering

    def initialize(tower_host:)
      super()

      host_url = tower_host
      host_url = "https://#{host_url}" unless host_url =~ %r{\Ahttps?:\/\/}
      self.tower_host = host_url
    end

    def parse_base_item(entity)
      props = { :resource_timestamp => resource_timestamp }
      props[:name]              = entity.name    if entity.respond_to?(:name)
      props[:source_created_at] = entity.created if entity.respond_to?(:created)
      props
    end

    protected

    attr_accessor :tower_host
  end
end
