module TopologicalInventory::AnsibleTower
  class Parser
    module ServiceProject
      def parse_service_project(service_project)
        collection.service_projects.build(
          parse_base_item(service_project).merge(
            :source_ref => service_project.id.to_s
          )
        )
      end
    end
  end
end
