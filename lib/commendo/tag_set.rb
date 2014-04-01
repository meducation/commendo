module Commendo

  class TagSet

    attr_accessor :redis, :key_base

    def initialize(redis, key_base)
      @redis, @key_base = redis, key_base
    end

    def get(resource)
      redis.smembers(resource_key(resource)).sort
    end

    def add(resource, *tags)
      redis.sadd(resource_key(resource), tags) unless tags.empty?
    end

    def set(resource, *tags)
      delete(resource)
      add(resource, *tags)
    end

    def matches(resource, *tags)
      resource_tags = get(resource)
      (resource_tags & tags).length > 0
    end

    def delete(resource)
      redis.del(resource_key(resource))
    end

    private

    def resource_key(resource)
      "#{key_base}:#{resource}"
    end

  end
end

