module Commendo
  module MySqlBacked

    class ContentSet

      attr_accessor :mysql, :key_base, :tag_set

      def initialize(key_base, tag_set = nil)
        config_hash = Commendo.config.to_hash
        config_hash[:flags] = Mysql2::Client::MULTI_STATEMENTS
        @mysql = Mysql2::Client.new(config_hash)
        @key_base = key_base
        @tag_set = tag_set
      end

      def add_by_group(group, *resources)
        resources.map! { |r| r.is_a?(Array) ? r : [r, 1] } #sets default score of 1
        resources.each { |r| add_single(r[0], group, r[1]) }
      end

      def add(resource, *groups)
        groups.map! { |g| g.is_a?(Array) ? g : [g, 1] } #sets default score of 1
        query = add_single_prepared_query
        groups.each { |(g, s)| query.execute(@key_base, resource, g, s, s) }
      end

      def add_single(resource, group, score)
        add(resource, [group, score])
      end

      def add_and_calculate(resource, *groups)
        add(resource, *groups)
      end

      def groups(resource)
        groups_prepared_query.execute(@key_base, resource).map {|r| r['groupname']}
      end

      def delete(resource)
        delete_prepared_query.execute(@key_base, resource)
      end

      def calculate_similarity(threshold = 0)
      end

      def calculate_similarity_for_resource(resource, threshold = 0)
      end

      def similar_to(resource, limit = 1000)
        resource = [resource] unless resource.is_a? Array
        results = @mysql.query(similar_to_prepared_query(@key_base, resource, limit))
        similar = results.map { |r| {resource: r['similar'], similarity: r['similarity'].round(3)} }
        return similar if resource.length == 1
        grouped = similar.group_by { |r| r[:resource] }
        grouped.map { |resource, similar| {resource: resource, similarity: similar.inject(0.0) { |sum, s| sum += s[:similarity] }} }.sort_by { |h| [h[:similarity], h[:resource]] }.reverse
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

      def remove_from_groups(resource, *groups)
        @mysql.query(remove_from_groups_prepared_query(@key_base, resource, groups))
      end

      def remove_from_groups_and_calculate(resource, *groups)
        remove_from_groups(resource, *groups)
        calculate_similarity_for_resource(resource)
      end

      private

      def add_single_prepared_query
        @add_single_prepared_query ||= @mysql.prepare('INSERT INTO Resource (keybase, name, groupname, score) VALUES (?,?,?,?) ON DUPLICATE KEY UPDATE score = score + ?')
      end

      def groups_prepared_query
        @groups_prepared_query ||= @mysql.prepare('SELECT DISTINCT groupname FROM Resource WHERE keybase=? AND name=?')
      end

      def delete_prepared_query
        @delete_prepared_query ||= @mysql.prepare('DELETE FROM Resource WHERE keybase = ? AND name = ?')
      end

      def remove_from_groups_prepared_query(keybase, name, groups)
        "
DELETE FROM Resource WHERE keybase = '#{keybase}' AND name = '#{name}' AND groupname IN (#{groups.map { |r| "'#{r}'" }.join(',')})"
      end

      def similar_to_prepared_query(keybase, resources, limit)
        "
SELECT similar, intersect_score, l_union, r_union, intersect_score / (l_union + r_union) AS similarity
FROM (
  SELECT r.name AS similar,
  SUM(l.score + r.score) AS intersect_score,
  (SELECT SUM(score) FROM Resource WHERE keybase = l.keybase AND name = l.name) AS l_union,
  (SELECT SUM(score) FROM Resource WHERE keybase = r.keybase AND name = r.name) AS r_union
  FROM Resource AS l
  JOIN Resource AS r ON l.keybase = r.keybase AND l.groupname = r.groupname
  WHERE l.keybase = '#{keybase}'
  AND l.name IN (#{resources.map { |r| "'#{r}'" }.join(',')})
  AND l.name <> r.name
  GROUP BY l.name, r.name
) AS similar_resources
ORDER BY similarity DESC, similar DESC
LIMIT #{limit}"
      end

    end

  end
end