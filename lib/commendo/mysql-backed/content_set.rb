module Commendo
  module MySqlBacked

    class ContentSet

      attr_accessor :mysql, :key_base, :tag_set

      def initialize(key_base, tag_set = nil)
        @key_base = key_base
        @tag_set = tag_set
      end

      def add_by_group(group, *resources)
      end

      def add(resource, *groups)
      end

      def add_single(resource, group, score)
      end

      def add_and_calculate(resource, *groups)
      end

      def groups(resource)
      end

      def delete(resource)
      end

      def calculate_similarity(threshold = 0)
      end

      def calculate_similarity_for_resource(resource, threshold)
      end

      def similar_to(resource, limit = 0)
      end

      def filtered_similar_to(resource, options = {})
      end

      def remove_from_groups(resource, *groups)
      end

      def remove_from_groups_and_calculate(resource, *groups)
      end

    end

  end
end