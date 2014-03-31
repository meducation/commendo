module Commendo

  class WeightedGroup

    attr_accessor :content_sets, :redis, :key_base

    def initialize(redis, key_base, *content_sets)
      @content_sets, @redis, @key_base = content_sets, redis, key_base
    end

    def similar_to(resource)
      keys = content_sets.map do |cs|
        cs[:cs].similarity_key(resource)
      end
      weights = content_sets.map do |cs|
        cs[:weight]
      end
      tmp_key = "#{key_base}:tmp:#{SecureRandom.uuid}"
      redis.zunionstore(tmp_key, keys, weights: weights)
      similar_resources = redis.zrevrange(tmp_key, 0, -1, with_scores: true)
      redis.del(tmp_key)

      similar_resources.map do |resource|
        {resource: resource[0], similarity: resource[1].to_f}
      end

    end

  end

end