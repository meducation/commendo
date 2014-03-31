module Commendo

  class ContentSet

    attr_accessor :redis, :key_base

    def initialize(redis, key_base)
      @redis, @key_base = redis, key_base
    end

    def add_by_group(group, *resources)
      resources.each do |res|
        redis.sadd("#{set_key_base}:#{res}", group)
      end
    end

    def add(resource, *groups)
      redis.sadd("#{set_key_base}:#{resource}", groups)
    end

    def calculate_similarity(threshold = 0)
      keys = redis.keys("#{set_key_base}:*")
      keys.each_with_index do |outer_key,i|
        outer_res = outer_key.gsub(/^#{set_key_base}:/, '')
        calculate_similarity_in_redis(outer_key, similarity_key(outer_res), threshold)
        yield(outer_key,i,keys.length) if block_given?
      end

    end

    def calculate_similarity_in_redis(set_key, similiarity_key, threshold)
      #TODO maybe consider using ary.combination to get finer grained operation in lua
      redis.eval(similarity_lua, [set_key, similiarity_key], [set_key_base, threshold])
    end

    def similar_to(resource)
      similar = []
      similar_resources = redis.zrevrange(similarity_key(resource), 0, -1, with_scores: true)
      #TODO change to .map
      similar_resources.each do |resource|
        similar << {resource: resource[0], similarity: resource[1].to_f}
      end
      similar
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

    def set_key_base
      "#{key_base}:sets"
    end

    def similar_key_base
      "#{key_base}:similar"
    end

  end

end