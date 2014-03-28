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
      keys.each do |outer_key|
        outer_res = outer_key.gsub(/^#{set_key_base}:/, '')
        outer_similarity_key = "#{similar_key_base}:#{outer_res}"
        calculate_similarity_in_redis(outer_key, outer_similarity_key, threshold)
        yield(outer_key) if block_given?
      end

    end

    def calculate_similarity_in_redis(set_key, similiarity_key, threshold)
      redis.eval(similarity_lua, [set_key, similiarity_key], [set_key_base, threshold])
    end

    def similar_to(resource)
      similar = []
      similar_resources = redis.hgetall("#{similar_key_base}:#{resource}")
      similar_resources.each do |resource, similarity|
        similar << {resource: resource, similarity: similarity.to_f}
      end
      similar.sort! do |x, y|
        if y[:similarity] != x[:similarity]
          y[:similarity] <=> x[:similarity]
        else
          y[:resource] <=> x[:resource]
        end
      end
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