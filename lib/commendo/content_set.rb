module Commendo

  class ContentSet

    attr_accessor :redis, :key_base, :tag_set

    def initialize(redis, key_base, tag_set = nil)
      @redis, @key_base, @tag_set = redis, key_base, tag_set
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
      #TODO delete from groups?
      redis.del(similarity_key(resource))
      redis.del(resource_key(resource))
    end

    def calculate_similarity(threshold = 0)
      #TODO make this use scan for scaling
      keys = redis.keys("#{resource_key_base}:*")
      keys.each_with_index do |key, i|
        yield(key, i, keys.length) if block_given?
        completed = redis.eval(similarity_lua, keys: [key], argv: [resource_key_base, similar_key_base, group_key_base, threshold])
        if completed == 999
          resource = key.gsub(/^#{resource_key_base}:/, '')
          groups = redis.smembers(resource_key(resource))
          group_keys = groups.map { |group| group_key(group) }
          resources = redis.sunion(*group_keys)
          resources.each do |to_compare|
            next if resource == to_compare
            redis.eval(pair_comparison_lua, keys: [key, resource_key(to_compare), similarity_key(resource), similarity_key(to_compare)], argv: [resource, to_compare, threshold])
          end
        end
      end
    end

    def similar_to(resource)
      similar_resources = redis.zrevrange(similarity_key(resource), 0, -1, with_scores: true)

      similar_resources.map do |resource|
        {resource: resource[0], similarity: resource[1].to_f}
      end
    end

    def filtered_similar_to(resource, options = {})
      similar = similar_to(resource)
      return similar if options[:include].nil? && options[:exclude].nil?
      similar.delete_if { |s| !options[:exclude].nil? && tags_match(s[:resource], options[:exclude]) }
      similar.delete_if { |s| !options[:include].nil? && !tags_match(s[:resource], options[:include]) }
      similar
    end

    def tags_match(resource, tags)
      resource_tags = tag_set.get(resource)
      (resource_tags & tags).length > 0
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

    def pair_comparison_lua
      @pair_comparison_lua ||= load_pair_comparison_lua
    end

    def load_pair_comparison_lua
      file = File.open(File.expand_path('../pair_comparison.lua', __FILE__), "r")
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

    def group_key_base
      "#{key_base}:groups"
    end


    def group_key(group)
      "#{group_key_base}:#{group}"
    end

  end

end