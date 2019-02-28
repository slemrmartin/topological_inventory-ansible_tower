module TopologicalInventory::AnsibleTower
  class Parser < TopologicalInventoryIngressApiClient::Collector::Parser
    require "topological_inventory/ansible_tower/parser/service_instance"
    require "topological_inventory/ansible_tower/parser/service_plan"
    require "topological_inventory/ansible_tower/parser/service_offering"

    include TopologicalInventory::AnsibleTower::Parser::ServiceInstance
    include TopologicalInventory::AnsibleTower::Parser::ServicePlan
    include TopologicalInventory::AnsibleTower::Parser::ServiceOffering

    def parse_base_item(entity)
      props = { :resource_timestamp => resource_timestamp }
      props[:name]              = entity.name    if entity.respond_to?(:name)
      props[:source_created_at] = entity.created if entity.respond_to?(:created)
      props
    end
  end
end
