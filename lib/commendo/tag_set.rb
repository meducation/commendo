module Commendo
  class TagSet
    extend Forwardable

    def_delegators :@redis_backed, :empty?, :get, :add, :set, :matches, :delete, :redis, :key_base

    def initialize(redis, key_base)
      @redis_backed = RedisBacked::TagSet.new(redis, key_base)
    end


  end
end

