require_relative 'tests_for_tag_sets'
gem 'minitest'
require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/mock'
require 'mocha/setup'
require 'commendo'

module Commendo

  class RedisTagSetTest < Minitest::Test

    def setup
      @redis = Redis.new(db: 15)
      @redis.flushdb
      @ts = TagSet.new(:redis, redis: @redis, key_base: 'TagSetTest')
    end

    include TestsForTagSets

  end
end
