module Commendo
  class TagSet
    extend Forwardable

    def_delegators :@backend, :empty?, :get, :add, :set, :matches, :delete, :redis, :key_base

    def initialize(args)
      @backend = RedisBacked::TagSet.new(args[:key_base]) if Commendo.config.backend == :redis
      raise 'Unrecognised backend type, try :redis or :mysql' if @backend.nil?
    end


  end
end

