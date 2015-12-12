module Commendo
  module MySqlBacked

    class WeightedGroup

      attr_accessor :mysql, :content_sets, :key_base, :tag_set

      def initialize(key_base, *content_sets)
        config_hash = Commendo.config.to_hash
        @mysql = Mysql2::Client.new(config_hash)
        @key_base = key_base
        @content_sets = content_sets
      end

      def similar_to(resource, limit = 0)
        similar = @content_sets.flat_map { |cs| cs[:cs].similar_to(resource).map { |s| {resource: s[:resource], similarity: (s[:similarity] * cs[:weight]).round(3)} } }
        grouped = similar.group_by { |r| r[:resource] }
        totaled_similar = grouped.map { |resource, similar| {resource: resource, similarity: similar.inject(0.0) { |sum, s| sum += s[:similarity] }} }.sort_by { |h| [h[:similarity], h[:resource]] }.reverse
        limit > 0 ? totaled_similar[0..limit-1] : totaled_similar
      end

      def filtered_similar_to(resource, options = {})
        if @tag_set.nil? || (options[:include].nil? && options[:exclude].nil?)
          return similar_to(resource, options[:limit] || 0)
        else
          similar = similar_to(resource)
          limit = options[:limit] || similar.length
          filtered = []
          similar.each do |s|
            return filtered if filtered.length >= limit
            filtered << s if @tag_set.matches(s[:resource], options[:include], options[:exclude])
          end
          return filtered
        end
      end

    end

  end
end