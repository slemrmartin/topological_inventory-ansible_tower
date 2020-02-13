module TopologicalInventory::AnsibleTower
  class Parser
    module ServiceCredentialType
      def parse_service_credential_type(credential_type)
        collections.service_credential_types.build(
          parse_base_item(credential_type).merge(
            :source_ref        => credential_type.id.to_s,
            :name              => credential_type.name.to_s,
            :description       => credential_type.description.to_s,
            :kind              => credential_type.kind.to_s,
            :namespace         => credential_type.namespace.to_s,
          )
        )
      end
    end
  end
end
