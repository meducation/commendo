module Commendo

  class ContentSet
    extend Forwardable

    def_delegators :@redis_backed,
                   :add_by_group, :add, :add_single, :add_and_calculate,
                   :groups, :delete,
                   :calculate_similarity, :calculate_similarity_for_resource, :calculate_similarity_for_key_resource,
                   :similar_to, :filtered_similar_to,
                   :similarity_key,
                   :remove_from_groups, :remove_from_groups_and_calculate

    def initialize(redis, key_base, tag_set = nil)
      @redis_backed = Commendo::RedisBacked::ContentSet.new(redis, key_base, tag_set)
    end


  end

end
