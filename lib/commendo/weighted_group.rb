module Commendo

  class WeightedGroup

    attr_accessor :content_sets, :redis, :key_base, :tag_set

    def initialize(redis, key_base, *content_sets)
      @content_sets, @redis, @key_base = content_sets, redis, key_base
    end

    def similar_to(resource)
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
      similar_resources = redis.zrevrange(tmp_key, 0, -1, with_scores: true)
      redis.del(tmp_key)

      similar_resources.map do |resource|
        {resource: resource[0], similarity: resource[1].to_f.round(3)}
      end

    end

    def filtered_similar_to(resource, options = {})
      similar = similar_to(resource)
      return similar if @tag_set.nil? || options[:include].nil? && options[:exclude].nil?
      similar.delete_if { |s| !options[:exclude].nil? && @tag_set.matches(s[:resource], options[:exclude]) }
      similar.delete_if { |s| !options[:include].nil? && !@tag_set.matches(s[:resource], options[:include]) }
      similar
    end

  end

end