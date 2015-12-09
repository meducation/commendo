module Commendo

  class WeightedGroup
    extend Forwardable

    def initialize(redis, key_base, *content_sets)
      @redis_backed = RedisBacked::WeightedGroup.new(redis, key_base, *content_sets)
    end

    def_delegators :@redis_backed, :similar_to, :filtered_similar_to, :content_sets, :redis, :key_base, :tag_set, :tag_set=

  end

end
