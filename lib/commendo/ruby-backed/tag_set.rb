module Commendo
  module RubyBacked
    class TagSet

      attr_accessor :key_base

      def initialize(key_base)
        @key_base = key_base
        @resource_to_tags = Hash.new { |h, k| h[k] = [] }
      end

      def empty?
        @resource_to_tags.keys.empty?
      end

      def get(resource)
        @resource_to_tags[resource.to_s]
      end

      def add(resource, *tags)
        @resource_to_tags[resource.to_s] += tags
      end

      def set(resource, *tags)
        @resource_to_tags[resource.to_s] = tags
      end

      def matches(resource, include, exclude = [])
        resource_tags = get(resource)
        can_include = include.nil? || include.empty? || (resource_tags & include).length > 0
        should_exclude = !exclude.nil? && !exclude.empty? && (resource_tags & exclude).length > 0
        return can_include && !should_exclude
      end

      def delete(resource, *tags)
        @resource_to_tags.delete(resource.to_s) if tags.empty?
        @resource_to_tags[resource.to_s] -= tags unless tags.empty?
      end

    end
  end
end

