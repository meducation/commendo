gem 'minitest'
require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/mock'
require 'mocha/setup'
require 'commendo'

module Commendo

  class TagSetTest < Minitest::Test

    def test_adds_tags_for_resource
      redis = Redis.new(db: 15)
      redis.flushdb
      ts = TagSet.new(redis, 'TagSetTest')
      assert_equal [], ts.get(1)
      ts.add(1, 'foo', 'bar', 'baz')
      assert_equal ['bar', 'baz','foo'], ts.get(1)
      ts.add(1, 'qux', 'qip')
      assert_equal ['bar', 'baz', 'foo', 'qip', 'qux'], ts.get(1)
    end

    def test_sets_tags_for_resource
      redis = Redis.new(db: 15)
      redis.flushdb
      ts = TagSet.new(redis, 'TagSetTest')
      assert_equal [], ts.get(1)
      ts.set(1, 'foo', 'bar', 'baz')
      assert_equal ['bar', 'baz', 'foo'], ts.get(1)
      ts.set(1, 'qux', 'qip')
      assert_equal ['qip', 'qux'], ts.get(1)
    end

    def test_deletes_tags_for_resource
      redis = Redis.new(db: 15)
      redis.flushdb
      ts = TagSet.new(redis, 'TagSetTest')
      ts.set(1, 'foo', 'bar', 'baz')
      ts.set(2, 'qux', 'qip')
      assert_equal ['bar', 'baz', 'foo'], ts.get(1)
      assert_equal ['qip', 'qux'], ts.get(2)
      ts.delete(1)
      assert_equal [], ts.get(1)
      assert_equal ['qip', 'qux'], ts.get(2)
    end

  end
end