module Commendo
  module RedisBacked
    class TagSet

      attr_accessor :redis, :key_base

      def initialize(redis, key_base)
        @redis, @key_base = redis, key_base
      end

      def empty?
        cursor, keys = redis.scan(0, match: "#{key_base}:*", count: 1)
        cursor.to_i == 0 && keys.empty?
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

      def matches(resource, include, exclude = [])
        resource_tags = get(resource)
        can_include = include.nil? || include.empty? || (resource_tags & include).length > 0
        should_exclude = !exclude.nil? && !exclude.empty? && (resource_tags & exclude).length > 0
        return can_include && !should_exclude
      end

      def delete(resource, *tags)
        if tags.empty?
          redis.del(resource_key(resource))
        else
          redis.srem(resource_key(resource), tags)
        end
      end

      private

      def resource_key(resource)
        "#{key_base}:#{resource}"
      end

    end
  end
end

