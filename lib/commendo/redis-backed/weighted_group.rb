module Commendo
  module RedisBacked

    class WeightedGroup

      attr_accessor :content_sets, :redis, :key_base, :tag_set

      def initialize(key_base, *content_sets)
        @redis = Redis.new(host: Commendo.config.host, port: Commendo.config.port, db: Commendo.config.database)
        @key_base = key_base
        @content_sets = content_sets
      end

      def similar_to(resource, limit = 0)
        finish = limit -1
        resources = resource.kind_of?(Array) ? resource : [resource]
        keys = []
        weights = []
        content_sets.each do |cs|
          resources.each do |resource|
            keys << cs[:cs].similarity_key(resource)
            weights << cs[:weight]
          end
        end
        tmp_key = "#{key_base}:tmp:#{SecureRandom.uuid}"
        redis.zunionstore(tmp_key, keys, weights: weights)
        similar_resources = redis.zrevrange(tmp_key, 0, finish, with_scores: true)
        redis.del(tmp_key)

        similar_resources.map do |resource|
          {resource: resource[0], similarity: resource[1].to_f.round(3)}
        end

      end

      def filtered_similar_to(resource, options = {})
        if @tag_set.nil? || (options[:include].nil? && options[:exclude].nil?)
          return similar_to(resource, options[:limit] || 0)
        else
          similar = similar_to(resource)
          limit = options[:limit] || similar.length
          filtered = []
          similar.each do |s|
            return filtered if filtered.length >= limit
            filtered << s if @tag_set.matches(s[:resource], options[:include], options[:exclude])
          end
          return filtered
        end
      end

    end

  end
end