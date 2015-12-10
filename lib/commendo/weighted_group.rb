module Commendo

  class WeightedGroup
    extend Forwardable

    def initialize(args)
      @backend = RedisBacked::WeightedGroup.new(args[:key_base], *args[:content_sets]) if Commendo.config.backend == :redis
      @backend = MySqlBacked::WeightedGroup.new(args[:key_base], *args[:content_sets]) if Commendo.config.backend == :mysql
      raise 'Unrecognised backend type, try :redis or :mysql' if @backend.nil?
    end

    def_delegators :@backend, :similar_to, :filtered_similar_to, :content_sets, :redis, :key_base, :tag_set, :tag_set=

  end

end
