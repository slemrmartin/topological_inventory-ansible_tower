module TopologicalInventory::AnsibleTower
  module Receptor
    class Error         < StandardError; end
    class ClientError   < Error; end
    class ReceptorConnectionError < Error; end

    # Receptor node returned response without 'status' or 'body'
    # Or status is non-200
    class ReceptorKafkaResponseError < Error; end
    # Receptor node returned response in String format
    class ReceptorNodeError < ReceptorKafkaResponseError; end
    # Receptor node returned response in non-hash, non-string format
    class ReceptorUnknownResponseError < ReceptorKafkaResponseError; end
  end
end
