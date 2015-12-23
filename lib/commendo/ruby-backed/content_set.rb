module Commendo
  module RubyBacked

    class ContentSet

      attr_accessor :key_base, :tag_set

      DEFAULT_LIMIT = 1000

      def initialize(key_base, tag_set = nil)
        @resource_group_score = Hash.new { |h, k| h[k] = Hash.new { |h, k| h[k] = 0 } }
        @key_base = key_base
        @tag_set = tag_set
      end

      def add_by_group(group, *resources)
        resources.map! { |r| r.is_a?(Array) ? r : [r, 1] } #sets default score of 1
        resources.each { |r| add_single(r[0], group, r[1]) }
      end

      def add(resource, *groups)
        resource = resource.to_s
        groups.map! { |g| g.is_a?(Array) ? g : [g, 1] } #sets default score of 1
        groups.each do |(group, score)|
          @resource_group_score[resource][group.to_s] += score
        end
      end

      def add_single(resource, group, score)
        add(resource, [group, score])
      end

      def add_and_calculate(resource, *groups)
        add(resource, *groups)
        calculate_similarity
      end

      def groups(resource)
        resource = resource.to_s
        @resource_group_score[resource].keys
      end

      def delete(resource)
        resource = resource.to_s
        @resource_group_score.delete(resource)
      end

      def calculate_similarity_for_resource(resource, threshold = 0)
        calculate_similarity(threshold)
      end

      def calculate_similarity(threshold = nil)
        @resource_totals = Hash[@resource_group_score.map { |resource, groups| [resource, groups.map { |group, score| score }.inject(0, :+)] }]
        flat_resource_group_score = @resource_group_score.flat_map do |resource, groups|
          groups.map do |group, score|
            [resource, group, score]
          end
        end
        @group_resource_scores = Hash.new { |h, k| h[k] = {} }
        flat_resource_group_score.each { |(resource, group, score)| @group_resource_scores[group][resource] = score }

        @threshold = threshold
      end

      def similar_to(resource, limit = DEFAULT_LIMIT)
        resource = resource.to_s
        my_groups = @resource_group_score[resource]

        similar = Hash.new { |h, k| h[k] = 0 }

        my_groups.each do |group, my_score|
          @group_resource_scores[group].each do |other_resource, score|
            next if other_resource == resource
            similarity = (my_score + score).to_f / (@resource_totals[resource] + @resource_totals[other_resource]).to_f
            similar[other_resource] += similarity
          end
        end

        similar.map { |resource, similarity| {resource: resource, similarity: similarity.round(3)} }.sort_by { |h| [h[:similarity], h[:resource]] }.reverse.first(limit)

      end

      def filtered_similar_to(resource, options = {})
        if @tag_set.nil? || (options[:include].nil? && options[:exclude].nil?) || @tag_set.empty?
          return similar_to(resource, options[:limit] || DEFAULT_LIMIT)
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

      def remove_from_groups(resource, *groups)
        resource = resource.to_s
        groups.each { |g| @resource_group_score[resource].delete(g.to_s) }
      end

      def remove_from_groups_and_calculate(resource, *groups)
        remove_from_groups(resource, *groups)
        calculate_similarity_for_resource(resource)
      end

    end

  end
end