module Commendo

  class ContentSet

    attr_accessor :redis, :key_base

    def initialize(redis, key_base)
      @redis, @key_base = redis, key_base
    end

    def add(group, *resources)
      resources.each do |res|
        redis.sadd("#{set_key_base}:#{res}", group)
      end
    end

    def calculate_similarity
      outer_cursor = '0'
      begin
        outer_cursor, outer_keyources = redis.scan(outer_cursor, match: "#{set_key_base}:*")
        outer_keyources.each do |outer_key|

          inner_cursor = '0'
          begin
            inner_cursor, inner_keyources = redis.scan(inner_cursor, match: "#{set_key_base}:*")
            similar = []
            inner_keyources.each do |inner_key|
              next if inner_key == outer_key
              intersect = redis.sinter(outer_key, inner_key).length
              if intersect > 0
                union = redis.sunion(outer_key, inner_key).length
                similarity = intersect / union.to_f
                similar << inner_key.gsub(/^#{set_key_base}:/, '')
                similar << similarity
              end
              outer_res = outer_key.gsub(/^#{set_key_base}:/, '')
              redis.hmset("#{similar_key_base}:#{outer_res}", similar) unless similar.empty?
            end
          end while (inner_cursor != '0')

        end
      end while (outer_cursor != '0')
    end

    def similar_to(resource)
      similar = []
      similar_resources = redis.hgetall("#{similar_key_base}:#{resource}")
      similar_resources.each do |resource, similarity|
        similar << {resource: resource, similarity: similarity.to_f}
      end
      similar.sort! { |x,y| y[:similarity] <=> x[:similarity] }
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