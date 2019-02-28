module TopologicalInventory::AnsibleTower
  class Iterator
    include Logging

    attr_reader :block, :error_message

    def initialize(blk, error_message)
      @block         = blk
      @error_message = error_message
    end

    def each
      block.call do |entity|
        yield(entity)
      end
    rescue => e
      logger.warn("#{error_message}. Message: #{e.message}")
      logger.debug(e.backtrace)
      []
    end
  end
end
