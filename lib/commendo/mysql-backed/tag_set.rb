module Commendo
  module MySqlBacked
    class TagSet

      attr_accessor :mysql, :key_base

      def initialize(key_base)
        config_hash = Commendo.config.to_hash
        @mysql = Mysql2::Client.new(config_hash)
        @key_base = key_base
      end

      def empty?
        result = empty_prepared_query.execute(@key_base)
        result.count.zero?
      end

      def get(resource)
        result = get_tags_prepared_query.execute(@key_base, resource)
        result.map { |r| r['tag'] }
      end

      def add(resource, *tags)
        return if tags.empty?
        @mysql.transaction do |client|
          insert_tags(resource, tags)
        end
      end

      def set(resource, *tags)
        @mysql.transaction do |client|
          delete(resource)
          insert_tags(resource, tags) unless tags.empty?
        end
      end

      def matches(resource, include, exclude = [])
        resource_tags = get(resource)
        can_include = include.nil? || include.empty? || (resource_tags & include).length > 0
        should_exclude = !exclude.nil? && !exclude.empty? && (resource_tags & exclude).length > 0
        return can_include && !should_exclude
      end

      def delete(resource, *tags)
        if tags.empty?
          delete_all_tags_prepared_query.execute(@key_base, resource)
        else
          tags.each { |t| delete_tags_prepared_query.execute(@key_base, resource, t) }
        end
      end

      private

      def insert_tags(resource, tags)
        tags.each { |t| insert_prepared_query.execute(@key_base, resource, t) }
      end

      def get_tags_prepared_query
        @get_tags_prepared_query ||= @mysql.prepare('SELECT tag FROM Tags t WHERE keybase = ? AND name = ?')
      end

      def delete_all_tags_prepared_query
        @delete_all_tags_prepared_query ||= @mysql.prepare('DELETE FROM Tags WHERE keybase = ? AND name = ?')
      end

      def delete_tags_prepared_query
        @delete_tags_prepared_query ||= @mysql.prepare('DELETE FROM Tags WHERE keybase = ? AND name = ? AND tag = ?')
      end

      def insert_prepared_query
        @insert_prepared_query ||= @mysql.prepare('INSERT IGNORE INTO Tags (keybase, name, tag) VALUES (?,?,?)')
      end

      def empty_prepared_query
        @empty_prepared_query ||= @mysql.prepare('SELECT tag FROM Tags WHERE keybase = ? LIMIT 1')
      end

    end
  end
end

