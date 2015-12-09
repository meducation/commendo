module Commendo

  class ContentSet
    extend Forwardable

    def_delegators :@backend,
                   :add_by_group, :add, :add_single, :add_and_calculate,
                   :groups, :delete,
                   :calculate_similarity, :calculate_similarity_for_resource, :calculate_similarity_for_key_resource,
                   :similar_to, :filtered_similar_to,
                   :similarity_key,
                   :remove_from_groups, :remove_from_groups_and_calculate

    def initialize(args)
      @backend = Commendo::RedisBacked::ContentSet.new(args[:key_base], args[:tag_set]) if Commendo.config.backend == :redis
      raise 'Unrecognised backend type, try :redis or :mysql' if @backend.nil?
    end

  end

end
