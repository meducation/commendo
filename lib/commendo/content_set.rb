module Commendo

  class ContentSet

    attr_accessor :redis, :key_base

    def initialize(redis, key_base)
      @redis, @key_base = redis, key_base
    end

    def add_by_group(group, *resources)
      resources.each do |res|
        redis.sadd("#{set_key_base}:#{res}", group)
      end
    end

    def add(resource, *groups)
      redis.sadd("#{set_key_base}:#{resource}", groups)
    end

    def calculate_similarity(threshold = 0)
      outer_cursor = '0'
      outer_count = 0
      begin
        outer_cursor, outer_keys = redis.scan(outer_cursor, match: "#{set_key_base}:*", count: 1000)
        outer_keys.each do |outer_key|
          outer_count += 1
          outer_res = outer_key.gsub(/^#{set_key_base}:/, '')
          outer_similarity_key = "#{similar_key_base}:#{outer_res}"
          redis.del(outer_similarity_key)
          inner_cursor = '0'
          similar = []
          begin
            inner_cursor, inner_keys = redis.scan(inner_cursor, match: "#{set_key_base}:*", count: 1000)
            inner_keys.each do |inner_key|
              next if inner_key == outer_key
              similarity = calculate_similarity_pair(outer_key, inner_key)
              if similarity > threshold
                inner_res = inner_key.gsub(/^#{set_key_base}:/, '')
                similar << inner_res
                similar << similarity
              end
            end
          end while (inner_cursor != '0')
          redis.hmset(outer_similarity_key, similar) unless similar.empty?
          yield(outer_count, outer_key) if block_given?
        end
      end while (outer_cursor != '0')
    end

    def calculate_similarity_pair(key1, key2)
      #intersect = redis.sinter(key1, key2).length
      #if intersect > 0
      #  union = redis.sunion(key1, key2).length
      #  return intersect / union.to_f
      #else
      #  return 0
      #end
      sim = redis.eval("return table.getn(redis.call('sinter', KEYS[1], KEYS[2])) / table.getn(redis.call('sunion', KEYS[1], KEYS[2])) * 1000", [key1, key2])
      sim.to_f / 1000.0
    end


    #eval  2 ['CommendoTests:sets:3', 'CommendoTests:sets:9']

    def similar_to(resource)
      similar = []
      similar_resources = redis.hgetall("#{similar_key_base}:#{resource}")
      similar_resources.each do |resource, similarity|
        similar << {resource: resource, similarity: similarity.to_f}
      end
      similar.sort! { |x, y| y[:similarity] <=> x[:similarity] }
    end

    private

    def set_key_base
      "#{key_base}:sets"
    end

    def similar_key_base
      "#{key_base}:similar"
    end

  end

end