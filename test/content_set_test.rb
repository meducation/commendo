gem 'minitest'
require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/mock'
require 'mocha/setup'
require 'commendo'

module Commendo

  class ContentSetTest < Minitest::Test

    def test_stores_sets_by_resource
      redis = Redis.new(db: 15)
      redis.flushdb
      key_base = 'CommendoTests'
      cs = ContentSet.new(redis, key_base)
      cs.add('group-1', 'resource-1', 'resource-2', 'resource-3')
      cs.add('group-2', 'resource-1', 'resource-3', 'resource-4')
      assert redis.sismember("#{key_base}:resource-1", 'group-1')
      assert redis.sismember("#{key_base}:resource-2", 'group-1')
      assert redis.sismember("#{key_base}:resource-3", 'group-1')
      refute redis.sismember("#{key_base}:resource-4", 'group-1')

      assert redis.sismember("#{key_base}:resource-1", 'group-2')
      refute redis.sismember("#{key_base}:resource-2", 'group-2')
      assert redis.sismember("#{key_base}:resource-3", 'group-2')
      assert redis.sismember("#{key_base}:resource-4", 'group-2')
    end

  end

end