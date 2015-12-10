module Commendo
  module MySqlBacked

    class WeightedGroup

      attr_accessor :mysql, :content_sets, :key_base, :tag_set

      def initialize(key_base, *content_sets)
        @mysql = Mysql2::Client.new(Commendo.config.to_hash)
        @key_base = key_base
        @content_sets = content_sets
      end

      def similar_to(resource, limit = 0)
      end

      def filtered_similar_to(resource, options = {})
        if @tag_set.nil? || (options[:include].nil? && options[:exclude].nil?)
          return similar_to(resource, options[:limit] || 0)
        else
        end
      end

    end

  end
end