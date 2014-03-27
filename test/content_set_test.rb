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
      cs.add('resource-1', 'group-1', 'group-2')
      cs.add('resource-2', 'group-1')
      cs.add('resource-3', 'group-1', 'group-2')
      cs.add('resource-4', 'group-2')
      assert redis.sismember("#{key_base}:sets:resource-1", 'group-1')
      assert redis.sismember("#{key_base}:sets:resource-2", 'group-1')
      assert redis.sismember("#{key_base}:sets:resource-3", 'group-1')
      refute redis.sismember("#{key_base}:sets:resource-4", 'group-1')

      assert redis.sismember("#{key_base}:sets:resource-1", 'group-2')
      refute redis.sismember("#{key_base}:sets:resource-2", 'group-2')
      assert redis.sismember("#{key_base}:sets:resource-3", 'group-2')
      assert redis.sismember("#{key_base}:sets:resource-4", 'group-2')
    end

    def test_stores_sets_by_group
      redis = Redis.new(db: 15)
      redis.flushdb
      key_base = 'CommendoTests'
      cs = ContentSet.new(redis, key_base)
      cs.add_by_group('group-1', 'resource-1', 'resource-2', 'resource-3')
      cs.add_by_group('group-2', 'resource-1', 'resource-3', 'resource-4')
      assert redis.sismember("#{key_base}:sets:resource-1", 'group-1')
      assert redis.sismember("#{key_base}:sets:resource-2", 'group-1')
      assert redis.sismember("#{key_base}:sets:resource-3", 'group-1')
      refute redis.sismember("#{key_base}:sets:resource-4", 'group-1')

      assert redis.sismember("#{key_base}:sets:resource-1", 'group-2')
      refute redis.sismember("#{key_base}:sets:resource-2", 'group-2')
      assert redis.sismember("#{key_base}:sets:resource-3", 'group-2')
      assert redis.sismember("#{key_base}:sets:resource-4", 'group-2')
    end

    def test_calculates_similarity_scores
      redis = Redis.new(db: 15)
      redis.flushdb
      key_base = 'CommendoTests'
      cs = ContentSet.new(redis, key_base)
      (3..23).each do |group|
        (3..23).each do |res|
          cs.add_by_group(group, res) if res % group == 0
        end
      end
      cs.calculate_similarity
      expected = [
        { resource:  '9', similarity: 0.5 },
        { resource:  '6', similarity: 0.5 },
        { resource: '12', similarity: 0.333 },
        { resource:  '3', similarity: 0.25 },
        { resource: '21', similarity: 0.166 },
        { resource: '15', similarity: 0.166 }
      ]
      assert_equal expected, cs.similar_to(18)
    end

    def test_calculates_with_threshold
      skip
    end

    def test_calculate_yields_after_each
      skip
    end

    def test_calculate_deletes_old_values_first
      skip
    end

  end

end