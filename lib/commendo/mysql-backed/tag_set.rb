module Commendo
  module MySqlBacked
    class TagSet

      attr_accessor :mysql, :key_base

      def initialize(key_base)
        config_hash = Commendo.config.to_hash
        config_hash[:flags] = Mysql2::Client::MULTI_STATEMENTS
        @mysql = Mysql2::Client.new(config_hash)
        @key_base = key_base
      end

      def empty?
        result = @mysql.query("SELECT t.name FROM Tags t JOIN ResourceTag rt ON t.id=rt.tag_id WHERE t.keybase='#{@key_base}'")
        result.count.zero?
      end

      def get(resource)
        result = @mysql.query("SELECT t.name FROM Tags t JOIN ResourceTag rt ON t.id=rt.tag_id JOIN Resources r ON r.id=rt.resource_id WHERE t.keybase='#{@key_base}' AND r.Name='#{resource}'")
        result.map { |r| r['name'] }
      end

      def add(resource, *tags)
        @mysql.transaction do |client|
          insert_tags(client, resource, tags)
        end
      end

      def set(resource, *tags)
        @mysql.transaction do |client|
          delete_all_tags(client, resource)
          insert_tags(client, resource, tags)
        end
      end

      def matches(resource, include, exclude = [])
        resource_tags = get(resource)
        can_include = include.nil? || include.empty? || (resource_tags & include).length > 0
        should_exclude = !exclude.nil? && !exclude.empty? && (resource_tags & exclude).length > 0
        return can_include && !should_exclude
      end

      def delete(resource, *tags)
        return delete_all_tags(@mysql, resource) if tags.empty?
        query = "
DELETE rt FROM ResourceTag rt
JOIN Resources r ON rt.resource_id=r.id
JOIN Tags t ON rt.tag_id=t.id
WHERE t.keybase='#{@key_base}'
AND r.name='#{resource}'
AND t.name IN (#{tags.map { |t| "'#{t}'" }.join(',')})"
        @mysql.query(query)
      end

      private

      def delete_all_tags(client, resource)
        client.query("DELETE rt FROM ResourceTag rt JOIN Resources r ON rt.resource_id=r.id WHERE r.keybase='#{@key_base}' AND r.name='#{resource}'")
      end

      def insert_tags(client, resource, tags)
        return if tags.empty?
        client.query("INSERT IGNORE INTO Resources (keybase, name) VALUES ('#{@key_base}', '#{resource}');")
        tags.each { |t| client.query("INSERT IGNORE INTO Tags (keybase, name) VALUES ('#{@key_base}', '#{t}');") }
        tags.each { |t| client.query("INSERT IGNORE INTO ResourceTag (resource_id, tag_id) VALUES ((SELECT id FROM Resources WHERE keybase='#{@key_base}' AND name='#{resource}'), (SELECT id FROM Tags WHERE keybase='#{@key_base}' AND name='#{t}'));") }
      end


    end
  end
end

