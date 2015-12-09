module Commendo
  module RedisBacked

    class ContentSet

      attr_accessor :redis, :key_base, :tag_set

      def initialize(key_base, tag_set = nil)
        @redis = Redis.new(host: Commendo.config.host, port: Commendo.config.port, db: Commendo.config.database)
        @key_base = key_base
        @tag_set = tag_set
      end

      def add_by_group(group, *resources)
        resources.each do |resource|
          if resource.kind_of?(Array)
            add_single(resource[0], group, resource[1])
          else
            add_single(resource, group, 1)
          end
        end
      end

      def add(resource, *groups)
        groups.each do |group|
          if group.kind_of?(Array)
            add_single(resource, group[0], group[1])
          else
            add_single(resource, group, 1)
          end
        end
      end

      def add_single(resource, group, score)
        redis.zincrby(group_key(group), score, resource)
        redis.zincrby(resource_key(resource), score, group)
      end

      def add_and_calculate(resource, *groups)
        add(resource, *groups)
        calculate_similarity_for_resource(resource, 0)
      end

      def groups(resource)
        redis.zrange(resource_key(resource), 0, -1)
      end

      def delete(resource)
        similar = similar_to(resource)
        similar.each do |other_resource|
          redis.zrem(similarity_key(other_resource[:resource]), "#{resource}")
        end
        #TODO delete from groups?
        redis.del(similarity_key(resource))
        redis.del(resource_key(resource))
      end

      SET_TOO_LARGE_FOR_LUA = 999

      def calculate_similarity(threshold = 0)
        #TODO make this use scan for scaling
        keys = redis.keys("#{resource_key_base}:*")
        keys.each_with_index do |key, i|
          resource = key.gsub(/^#{resource_key_base}:/, '')
          similarity_key = similarity_key(resource)
          redis.del(similarity_key)
          yield(key, i, keys.length) if block_given?
          completed = redis.eval(similarity_lua, keys: [key], argv: [tmp_key_base, resource_key_base, similar_key_base, group_key_base, threshold])
          if completed == SET_TOO_LARGE_FOR_LUA
            calculate_similarity_for_key_resource(key, resource, threshold)
          end
        end
      end


      def calculate_similarity_for_resource(resource, threshold)
        key = resource_key(resource)
        calculate_similarity_for_key_resource(key, resource, threshold)
      end

      def calculate_similarity_for_key_resource(key, resource, threshold)
        groups = groups(resource)
        return if groups.empty?
        group_keys = groups.map { |group| group_key(group) }
        tmp_key = "#{tmp_key_base}:#{SecureRandom.uuid}"
        redis.zunionstore(tmp_key, group_keys)
        resources = redis.zrange(tmp_key, 0, -1)
        redis.del(tmp_key)
        similarity_key = similarity_key(resource)
        redis.del(similarity_key)
        resources.each do |to_compare|
          next if resource == to_compare
          redis.eval(pair_comparison_lua, keys: [key, resource_key(to_compare), similarity_key(resource), similarity_key(to_compare)], argv: [tmp_key_base, resource, to_compare, threshold])
        end
      end

      def similar_to(resource, limit = 0)
        finish = limit -1
        if resource.kind_of? Array
          keys = resource.map do |res|
            similarity_key(res)
          end
          tmp_key = "#{key_base}:tmp:#{SecureRandom.uuid}"
          redis.zunionstore(tmp_key, keys)
          similar_resources = redis.zrevrange(tmp_key, 0, finish, with_scores: true)
          redis.del(tmp_key)
        else
          similar_resources = redis.zrevrange(similarity_key(resource), 0, finish, with_scores: true)
        end
        similar_resources.map do |resource|
          {resource: resource[0], similarity: resource[1].to_f}
        end
      end

      def filtered_similar_to(resource, options = {})
        if @tag_set.nil? || (options[:include].nil? && options[:exclude].nil?) || @tag_set.empty?
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

      def similarity_key(resource)
        "#{similar_key_base}:#{resource}"
      end

      def remove_from_groups(resource, *groups)
        resource_key = resource_key(resource)
        redis.zrem(resource_key, groups)
        groups.each do |group|
          group_key = group_key(group)
          redis.zrem(group_key, resource)
        end
      end

      def remove_from_groups_and_calculate(resource, *groups)
        remove_from_groups(resource, *groups)
        calculate_similarity_for_resource(resource, 0)
      end

      private

      def similarity_lua
        @similarity_lua ||= load_similarity_lua
      end

      def load_similarity_lua
        file = File.open(File.expand_path('../similarity.lua', __FILE__), "r")
        file.read
      end

      def pair_comparison_lua
        @pair_comparison_lua ||= load_pair_comparison_lua
      end

      def load_pair_comparison_lua
        file = File.open(File.expand_path('../pair_comparison.lua', __FILE__), "r")
        file.read
      end

      def tmp_key_base
        "#{key_base}:tmp"
      end

      def similar_key_base
        "#{key_base}:similar"
      end

      def resource_key_base
        "#{key_base}:resources"
      end

      def resource_key(resource)
        "#{resource_key_base}:#{resource}"
      end

      def group_key_base
        "#{key_base}:groups"
      end

      def group_key(group)
        "#{group_key_base}:#{group}"
      end

    end

  end
end