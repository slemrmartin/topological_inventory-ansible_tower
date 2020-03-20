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
      logger.error("#{error_message}. Message: #{e.message} #{e.backtrace.join('\n')}")
      []
    end
  end
end
