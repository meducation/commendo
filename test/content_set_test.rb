gem 'minitest'
require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/mock'
require 'mocha/setup'
require 'commendo'

module Commendo

  class ContentSetTest < Minitest::Test

    def test_gives_similarity_key_for_resource
      redis = Redis.new(db: 15)
      key_base = 'CommendoTests'
      cs = ContentSet.new(redis, key_base)
      assert_equal 'CommendoTests:similar:resource-1', cs.similarity_key('resource-1')
    end

    def test_stores_sets_by_resource
      redis = Redis.new(db: 15)
      redis.flushdb
      key_base = 'CommendoTests'
      cs = ContentSet.new(redis, key_base)
      cs.add('resource-1', 'group-1', 'group-2')
      cs.add('resource-2', 'group-1')
      cs.add('resource-3', 'group-1', 'group-2')
      cs.add('resource-4', 'group-2')
      assert redis.sismember("#{key_base}:resources:resource-1", 'group-1')
      assert redis.sismember("#{key_base}:resources:resource-2", 'group-1')
      assert redis.sismember("#{key_base}:resources:resource-3", 'group-1')
      refute redis.sismember("#{key_base}:resources:resource-4", 'group-1')

      assert redis.sismember("#{key_base}:resources:resource-1", 'group-2')
      refute redis.sismember("#{key_base}:resources:resource-2", 'group-2')
      assert redis.sismember("#{key_base}:resources:resource-3", 'group-2')
      assert redis.sismember("#{key_base}:resources:resource-4", 'group-2')
    end

    def test_stores_sets_by_group
      redis = Redis.new(db: 15)
      redis.flushdb
      key_base = 'CommendoTests'
      cs = ContentSet.new(redis, key_base)
      cs.add_by_group('group-1', 'resource-1', 'resource-2', 'resource-3')
      cs.add_by_group('group-2', 'resource-1', 'resource-3', 'resource-4')
      assert redis.sismember("#{key_base}:resources:resource-1", 'group-1')
      assert redis.sismember("#{key_base}:resources:resource-2", 'group-1')
      assert redis.sismember("#{key_base}:resources:resource-3", 'group-1')
      refute redis.sismember("#{key_base}:resources:resource-4", 'group-1')

      assert redis.sismember("#{key_base}:resources:resource-1", 'group-2')
      refute redis.sismember("#{key_base}:resources:resource-2", 'group-2')
      assert redis.sismember("#{key_base}:resources:resource-3", 'group-2')
      assert redis.sismember("#{key_base}:resources:resource-4", 'group-2')
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
        {resource: '9', similarity: 0.5},
        {resource: '6', similarity: 0.5},
        {resource: '12', similarity: 0.333},
        {resource: '3', similarity: 0.25},
        {resource: '21', similarity: 0.167},
        {resource: '15', similarity: 0.167}
      ]
      assert_equal expected, cs.similar_to(18)
    end

    def test_calculates_with_threshold
      redis = Redis.new(db: 15)
      redis.flushdb
      key_base = 'CommendoTests'
      cs = ContentSet.new(redis, key_base)
      (3..23).each do |group|
        (3..23).each do |res|
          cs.add_by_group(group, res) if res % group == 0
        end
      end
      cs.calculate_similarity(0.4)
      expected = [
        {resource: '9', similarity: 0.5},
        {resource: '6', similarity: 0.5},
      ]
      assert_equal expected, cs.similar_to(18)
    end

    def test_calculate_yields_after_each
      redis = Redis.new(db: 15)
      redis.flushdb
      key_base = 'CommendoTests'
      cs = ContentSet.new(redis, key_base)
      (3..23).each do |group|
        (3..23).each do |res|
          cs.add_by_group(group, res) if res % group == 0
        end
      end
      expected_keys = ['CommendoTests:resources:3', 'CommendoTests:resources:4', 'CommendoTests:resources:5', 'CommendoTests:resources:6', 'CommendoTests:resources:7', 'CommendoTests:resources:8', 'CommendoTests:resources:9', 'CommendoTests:resources:10', 'CommendoTests:resources:11', 'CommendoTests:resources:12', 'CommendoTests:resources:13', 'CommendoTests:resources:14', 'CommendoTests:resources:15', 'CommendoTests:resources:16', 'CommendoTests:resources:17', 'CommendoTests:resources:18', 'CommendoTests:resources:19', 'CommendoTests:resources:20', 'CommendoTests:resources:21', 'CommendoTests:resources:22', 'CommendoTests:resources:23']
      actual_keys = []
      cs.calculate_similarity { |key, index, total|
        actual_keys << key
      }
      assert_equal expected_keys.sort, actual_keys.sort
    end

    def test_calculate_deletes_old_values_first
      skip
    end

    def test_deletes_resource_from_everywhere
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
      assert similar_to(cs, 18, 12)

      cs.delete(12)
      assert_equal [], cs.similar_to(12)
      refute similar_to(cs, 18, 12)

      cs.calculate_similarity
      assert_equal [], cs.similar_to(12)
      refute similar_to(cs, 18, 12)

    end

    def test_accepts_incremental_updates
      redis = Redis.new(db: 15)
      redis.flushdb
      key_base = 'CommendoTests'
      cs = ContentSet.new(redis, key_base)
      (3..23).each do |group|
        (3..23).each do |res|
          cs.add(res, group) if res % group == 0
        end
      end
      cs.calculate_similarity
      assert similar_to(cs, 18, 12)
      refute similar_to(cs, 10, 12)

      cs.add_and_calculate(12, 'foo', true)
      cs.add_and_calculate(10, 'foo', true)
      assert similar_to(cs, 10, 12)
    end

    def test_filters_include_by_tag_collection
      redis = Redis.new(db: 15)
      redis.flushdb
      ts = TagSet.new(redis, 'CommendoTests:tags')
      cs = ContentSet.new(redis, 'CommendoTests', ts)
      (3..23).each do |group|
        (3..23).each do |res|
          cs.add(res, group) if res % group == 0
          ts.add(res, 'mod3') if res.modulo(3).zero?
          ts.add(res, 'mod4') if res.modulo(4).zero?
          ts.add(res, 'mod5') if res.modulo(5).zero?
        end
      end
      cs.calculate_similarity

      actual = cs.filtered_similar_to(10, include: ['mod5'])
      assert_equal 3, actual.length
      assert contains_resource('5', actual)
      assert contains_resource('15', actual)
      assert contains_resource('20', actual)

    end

    def test_filters_exclude_by_tag_collection
      redis = Redis.new(db: 15)
      redis.flushdb
      ts = TagSet.new(redis, 'CommendoTests:tags')
      cs = ContentSet.new(redis, 'CommendoTests', ts)
      (3..23).each do |group|
        (3..23).each do |res|
          cs.add(res, group) if res % group == 0
          ts.add(res, 'mod3') if res.modulo(3).zero?
          ts.add(res, 'mod4') if res.modulo(4).zero?
          ts.add(res, 'mod5') if res.modulo(5).zero?
        end
      end
      cs.calculate_similarity

      actual = cs.filtered_similar_to(10, exclude: ['mod3'])
      assert_equal 2, actual.length
      assert contains_resource('5', actual)
      assert contains_resource('20', actual)
      refute contains_resource('15', actual)

    end

    def test_filters_includes_and_exclude_by_tag_collection
      redis = Redis.new(db: 15)
      redis.flushdb
      ts = TagSet.new(redis, 'CommendoTests:tags')
      cs = ContentSet.new(redis, 'CommendoTests', ts)
      (3..23).each do |group|
        (3..23).each do |res|
          cs.add(res, group) if res % group == 0
          ts.add(res, 'mod3') if res.modulo(3).zero?
          ts.add(res, 'mod4') if res.modulo(4).zero?
          ts.add(res, 'mod5') if res.modulo(5).zero?
        end
      end
      cs.calculate_similarity

      actual = cs.filtered_similar_to(12, include: ['mod4'], exclude: ['mod3', 'mod5'])
      assert_equal 3, actual.length

      refute contains_resource('6', actual)
      refute contains_resource('18', actual)
      assert contains_resource('4', actual)
      refute contains_resource('3', actual)
      refute contains_resource('9', actual)
      assert contains_resource('8', actual)
      refute contains_resource('21', actual)
      assert contains_resource('16', actual)
      refute contains_resource('15', actual)
      refute contains_resource('20', actual)

    end

    def similar_to(cs, resource, similar)
      contains_resource(similar, cs.similar_to(resource))
    end

    def contains_resource(resource, similarities)
      similarities.select { |sim| sim[:resource] == "#{resource}" }.length > 0
    end

  end

end