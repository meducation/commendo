module Commendo

  class ContentSet

    attr_accessor :redis, :key_base

    def initialize(redis, key_base)
      @redis, @key_base = redis, key_base
    end

    def add_by_group(group, *resources)
      redis.sadd(group_key(group), resources)
      resources.each do |resource|
        redis.sadd(resource_key(resource), group)
      end
    end

    def add(resource, *groups)
      redis.sadd(resource_key(resource), groups)
      groups.each do |group|
        redis.sadd(group_key(group), resource)
      end
    end

    def add_and_calculate(resource, *groups)
      add(resource, *groups)
      groups = redis.smembers(resource_key(resource))
      group_keys = groups.map { |group| group_key(group) }
      resources = redis.sunion(*group_keys)
      resources.combination(2) do |l, r|
        intersect = redis.sinter(resource_key(l), resource_key(r))
        if (intersect.length > 0)
          union = redis.sunion(resource_key(l), resource_key(r))
          jaccard = intersect.length / union.length.to_f
          puts jaccard
          redis.zadd(similarity_key(l), jaccard, r)
          redis.zadd(similarity_key(r), jaccard, l)
        end
      end
    end

    def delete(resource)
      similar = similar_to(resource)
      similar.each do |other_resource|
        redis.zrem(similarity_key(other_resource[:resource]), "#{resource}")
      end
      redis.del(similarity_key(resource))
      redis.del(resource_key(resource))
    end

    def calculate_similarity(threshold = 0)
      #TODO make this use scan for scaling
      keys = redis.keys("#{resource_key_base}:*")
      keys.each_with_index do |outer_key, i|
        outer_res = outer_key.gsub(/^#{resource_key_base}:/, '')
        calculate_similarity_in_redis(outer_key, similarity_key(outer_res), threshold)
        yield(outer_key, i, keys.length) if block_given?
      end
    end

    def calculate_similarity_in_redis(set_key, similiarity_key, threshold)
      #TODO maybe consider using ary.combination to get finer grained operation in lua
      redis.eval(similarity_lua, [set_key, similiarity_key], [resource_key_base, threshold])
    end

    def similar_to(resource)
      similar_resources = redis.zrevrange(similarity_key(resource), 0, -1, with_scores: true)

      similar_resources.map do |resource|
        {resource: resource[0], similarity: resource[1].to_f}
      end

    end

    def similarity_key(resource)
      "#{similar_key_base}:#{resource}"
    end

    private

    def similarity_lua
      @similarity_lua ||= load_similarity_lua
    end

    def load_similarity_lua
      file = File.open(File.expand_path('../similarity.lua', __FILE__), "r")
      file.read
    end

    def similar_key_base
      "#{key_base}:similar"
    end

    def resource_key_base
      "#{key_base}:resources"
    end

    def resource_key(resource)
      "#{resource_key_base}:#{resource}"
    end

    def group_key(group)
      "#{key_base}:groups:#{group}"
    end

  end

end