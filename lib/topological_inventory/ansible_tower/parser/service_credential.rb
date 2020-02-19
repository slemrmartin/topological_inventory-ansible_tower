module TopologicalInventory::AnsibleTower
  class Parser
    module ServiceCredential
      def parse_service_credential(credential)
        service_credential_type = lazy_find(:service_credential_types, :source_ref => credential.credential_type_id.to_s) if credential.respond_to?(:credential_type_id)

        collections.service_credentials.build(
          parse_base_item(credential).merge(
            :source_ref              => credential.id.to_s,
            :name                    => credential.name.to_s,
            :description             => credential.description.to_s,
            :service_credential_type => service_credential_type
          )
        )
      end
    end
  end
end
