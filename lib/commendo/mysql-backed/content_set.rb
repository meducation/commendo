module Commendo
  module MySqlBacked

    class ContentSet

      attr_accessor :mysql, :key_base, :tag_set

      def initialize(key_base, tag_set = nil)
        @mysql = Mysql2::Client.new(Commendo.config.to_hash)
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
        @mysql.query("INSERT IGNORE INTO Resources (Name) VALUES ('#{resource}');")
        @mysql.query("INSERT IGNORE INTO Groups (Name) VALUES ('#{group}');")
        query = "INSERT INTO ResourceGroup (Resources_id, Groups_id, Score) VALUES (
                     (SELECT id FROM Resources WHERE Name = '#{resource}'),
                     (SELECT id FROM Groups WHERE Name = '#{group}'),
                     #{score})
                 ON DUPLICATE KEY UPDATE Score = Score + #{score}"
        # $stderr.puts query
        @mysql.query(query)
      end

      def add_and_calculate(resource, *groups)
        add(resource, *groups)
        calculate_similarity_for_resource(resource, 0)
      end

      def groups(resource)
        result = @mysql.query("
SELECT DISTINCT Groups.Name FROM Groups
INNER JOIN ResourceGroup ON ResourceGroup.Groups_id=Groups.id
INNER JOIN Resources ON ResourceGroup.Resources_id=Resources.id
WHERE Resources.Name = '#{resource}';")
        result.map { |r| r['Name'] }
      end

      def delete(resource)
        @mysql.query("DELETE FROM Resources WHERE Resources.Name = '#{resource}'")
      end

      def calculate_similarity(threshold = 0)
        resources = @mysql.query('SELECT id FROM Resources ORDER BY id ASC')
        resources.each do |r|
          co_resources = @mysql.query("
SELECT co.Resources_id AS id FROM ResourceGroup AS co
INNER JOIN ResourceGroup src ON co.Groups_id = src.Groups_id
WHERE src.Resources_id = #{r['id']}
AND co.Resources_id > src.Resources_id;")
          co_resources = co_resources.map { |r| r['id'] }
          co_resources.each do |cr|
            calculate_similarity_for_pair(r['id'], cr, threshold)
          end
        end
      end

      def calculate_similarity_for_resource(resource, threshold)
        r = @mysql.query("SELECT id FROM Resources WHERE Name = '#{resource}'").first
        return if r.nil?
        co_resources = @mysql.query("
SELECT co.Resources_id AS id FROM ResourceGroup AS co
INNER JOIN ResourceGroup src ON co.Groups_id = src.Groups_id
WHERE src.Resources_id = #{r['id']};")
        co_resources = co_resources.map { |r| r['id'] }
        co_resources.each do |cr|
          calculate_similarity_for_pair(r['id'], cr, threshold)
        end
      end

      def similar_to(resource, limit = 0)
        resource = [resource] unless resource.is_a? Array
        query = "SELECT DISTINCT Similar.Name, Similarity.Similarity FROM Resources AS Similar
JOIN Similarity ON Similarity.Similar_ID=Similar.id
JOIN Resources AS src ON Similarity.Resources_ID=src.id
WHERE src.Name IN (#{resource.map { |r| "'#{r}'" }.join(',')})
ORDER BY Similarity.Similarity DESC, Similar.Name DESC;"
        results = @mysql.query(query)
        similar = results.map { |r| {resource: r['Name'], similarity: r['Similarity']} }
        return similar if resource.length == 1
        grouped = similar.group_by { |r| r[:resource] }
        grouped.map { |resource, similar| {resource: resource, similarity: similar.inject(0.0) { |sum, s| sum += s[:similarity] }} }

      end

      def filtered_similar_to(resource, options = {})
      end

      def remove_from_groups(resource, *groups)
        r = @mysql.query("SELECT id FROM Resources WHERE Name = '#{resource}';").first
        return if r.nil?
        group_ids = @mysql.query("SELECT id FROM Groups WHERE Name IN (#{groups.map { |g| "'#{g}'" }.join(',')});")
        group_ids = group_ids.map { |r| r['id'] }
        return if group_ids.empty?
        result = @mysql.query("DELETE FROM ResourceGroup WHERE Resources_ID=#{r['id']} AND Groups_ID IN (#{group_ids.join(',')})")
        result
      end

      def remove_from_groups_and_calculate(resource, *groups)
        remove_from_groups(resource, *groups)
        calculate_similarity_for_resource(resource, 0)
      end

      private

      def calculate_similarity_for_pair(left_id, right_id, threshold)
        intersect_count = @mysql.query("
SELECT SUM(l.Score) + SUM(r.Score) AS score FROM ResourceGroup AS l
INNER JOIN ResourceGroup r ON l.Groups_id = r.Groups_id
WHERE l.Resources_id = #{left_id} AND r.Resources_id = #{right_id};").first['score']
        union_count = @mysql.query("
SELECT SUM(score) AS score FROM (
	SELECT SUM(Score) AS score FROM ResourceGroup
	WHERE Resources_id = #{left_id}
	UNION ALL
	SELECT SUM(Score) AS score FROM ResourceGroup
	WHERE Resources_id = #{right_id}) AS Scores;").first['score']

        similarity = (intersect_count.to_f / union_count.to_f).round(3)
        if similarity > threshold
          @mysql.query("INSERT INTO Similarity (Resources_id, Similar_id, Similarity) VALUES (#{left_id}, #{right_id}, #{similarity}) ON DUPLICATE KEY UPDATE Similarity = #{similarity};")
          @mysql.query("INSERT INTO Similarity (Resources_id, Similar_id, Similarity) VALUES (#{right_id}, #{left_id}, #{similarity}) ON DUPLICATE KEY UPDATE Similarity = #{similarity};")
        else
          @mysql.query("DELETE FROM Similarity WHERE Resources_id=#{left_id} AND Similar_id=#{right_id};")
          @mysql.query("DELETE FROM Similarity WHERE Resources_id=#{right_id} AND Similar_id=#{left_id};")
        end

      end

    end

  end
end