module Commendo

  class ContentSet

    attr_accessor :redis, :key_base

    def initialize(redis, key_base)
      @redis, @key_base = redis, key_base
    end

    def add(group, *resources)
      resources.each do |res|
        redis.sadd("#{key_base}:#{res}", group)
      end
    end


  end

end