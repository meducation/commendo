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
        groups.each { |g| add_single(resource, g[0], g[1]) }
      end

      def add_single(resource, group, score)
        # $stderr.puts "Adding #{resource} to #{group}"
        @mysql.query("INSERT IGNORE INTO Resources (keybase, name) VALUES ('#{@key_base}', '#{resource}');")
        @mysql.query("INSERT IGNORE INTO Groups (keybase, name) VALUES ('#{@key_base}', '#{group}');")
        query = "INSERT INTO ResourceGroup (resource_id, group_id, score) VALUES (
                     (SELECT id FROM Resources WHERE keybase='#{@key_base}' AND name='#{resource}'),
                     (SELECT id FROM Groups WHERE keybase='#{@key_base}' AND name='#{group}'),
                     #{score})
                 ON DUPLICATE KEY UPDATE score = score + #{score}"
        # $stderr.puts query
        @mysql.query(query)
      end

      def add_and_calculate(resource, *groups)
        add(resource, *groups)
        calculate_similarity_for_resource(resource)
      end

      def groups(resource)
        result = @mysql.query("
SELECT DISTINCT Groups.name FROM Groups
INNER JOIN ResourceGroup ON ResourceGroup.group_id=Groups.id
INNER JOIN Resources ON ResourceGroup.resource_id=Resources.id
WHERE Resources.name='#{resource}';")
        result.map { |r| r['name'] }
      end

      def delete(resource)
        @mysql.query("DELETE FROM Resources WHERE Resources.name='#{resource}'")
      end

      def calculate_similarity(threshold = 0)
        update_union_scores()
        update_intersect_scores()
        update_similarity()
      end

      def calculate_similarity_for_resource(resource, threshold = 0)
        calculate_similarity(threshold)
      end

      def similar_to(resource, limit = 0)
        resource = [resource] unless resource.is_a? Array
        query = "SELECT Similar.name, Similarity.similarity FROM Resources AS Similar
JOIN Similarity ON Similarity.similar_id=Similar.id
JOIN Resources AS src ON Similarity.resource_id=src.id
WHERE src.keybase='#{@key_base}' AND src.name IN (#{resource.map { |r| "'#{r}'" }.join(',')})
ORDER BY Similarity.similarity DESC, Similar.name DESC"
        query += "\nLIMIT #{limit}" if limit > 0
        results = @mysql.query(query)
        similar = results.map { |r| {resource: r['name'], similarity: r['similarity'].round(3)} }
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
        r = @mysql.query("SELECT id FROM Resources WHERE name='#{resource}';").first
        return if r.nil?
        group_ids = @mysql.query("SELECT id FROM Groups WHERE name IN (#{groups.map { |g| "'#{g}'" }.join(',')});")
        group_ids = group_ids.map { |r| r['id'] }
        return if group_ids.empty?
        result = @mysql.query("DELETE FROM ResourceGroup WHERE resource_id=#{r['id']} AND group_id IN (#{group_ids.join(',')})")
        result
      end

      def remove_from_groups_and_calculate(resource, *groups)
        remove_from_groups(resource, *groups)
        calculate_similarity_for_resource(resource)
      end

      private

      def update_union_scores(resource = nil)
        query = '
UPDATE Resources
JOIN (
  SELECT resource_id, SUM(score) AS score
  FROM ResourceGroup
  GROUP BY resource_id
) AS rg_scores ON rg_scores.resource_id=Resources.id
SET Resources.score = rg_scores.score;'
        @mysql.query(query)
      end

      def update_intersect_scores(resource = nil)
        @mysql.transaction do |client|
          client.query("DELETE Similarity FROM Similarity JOIN Resources ON Similarity.resource_id=Resources.id WHERE Resources.keybase='#{@key_base}'")
          query = '
INSERT INTO Similarity (resource_id, similar_id, intersect)
SELECT intersect.l_id, intersect.r_id, intersect.score FROM
(
  SELECT l.resource_id AS l_id, r.resource_id AS r_id, SUM(l.Score) + SUM(r.Score) AS score
  FROM ResourceGroup AS l
  INNER JOIN ResourceGroup r ON l.group_id = r.group_id
  WHERE l.resource_id <> r.resource_id
  GROUP BY l.resource_id, r.resource_id
) AS intersect
ON DUPLICATE KEY UPDATE intersect = score;'
          client.query(query)
        end
      end

      def update_similarity(resource = nil)
        query = '
UPDATE Similarity
JOIN Resources AS l ON Similarity.resource_id=l.id
JOIN Resources AS r ON Similarity.similar_id=r.id
SET Similarity.similarity = Similarity.intersect / (l.score + R.score);'
        @mysql.query(query)
      end

    end

  end
end