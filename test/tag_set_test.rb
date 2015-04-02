gem 'minitest'
require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/mock'
require 'mocha/setup'
require 'commendo'

module Commendo

  class TagSetTest < Minitest::Test

    def setup
      @redis = Redis.new(db: 15)
      @redis.flushdb
      @ts = TagSet.new(@redis, 'TagSetTest')
    end

    def test_adds_tags_for_resource
      assert_equal [], @ts.get(1)
      @ts.add(1, 'foo', 'bar', 'baz')
      assert_equal ['bar', 'baz','foo'], @ts.get(1)
      @ts.add(1, 'qux', 'qip')
      assert_equal ['bar', 'baz', 'foo', 'qip', 'qux'], @ts.get(1)
    end

    def test_empty?
      assert @ts.respond_to? :empty?
      assert @ts.empty?
      @ts.add(1, 'qux', 'qip')
      refute @ts.empty?
      @ts.delete(1)
      assert @ts.empty?
    end

    def test_sets_tags_for_resource
      assert_equal [], @ts.get(1)
      @ts.set(1, 'foo', 'bar', 'baz')
      assert_equal ['bar', 'baz', 'foo'], @ts.get(1)
      @ts.set(1, 'qux', 'qip')
      assert_equal ['qip', 'qux'], @ts.get(1)
    end

    def test_sets_tags_when_empty
      @ts.set(1, 'foo', 'bar', 'baz')
      @ts.set(2, 'qux', 'qip')
      assert_equal ['bar', 'baz', 'foo'], @ts.get(1)
      assert_equal ['qip', 'qux'], @ts.get(2)
      @ts.set(1, *[])
      assert_equal [], @ts.get(1)
      assert_equal ['qip', 'qux'], @ts.get(2)
    end

    def test_deletes_all_tags_for_resource
      @ts.set(1, 'foo', 'bar', 'baz')
      @ts.set(2, 'qux', 'qip')
      assert_equal ['bar', 'baz', 'foo'], @ts.get(1)
      assert_equal ['qip', 'qux'], @ts.get(2)
      @ts.delete(1)
      assert_equal [], @ts.get(1)
      assert_equal ['qip', 'qux'], @ts.get(2)
    end

    def test_deletes_given_tags_for_resource
      assert_equal [], @ts.get(1)
      @ts.set(1, 'foo', 'bar', 'baz', 'qux', 'qip')
      @ts.delete(1, 'qux', 'qip')
      assert_equal ['bar', 'baz', 'foo'], @ts.get(1)
    end

    def test_matches_tags
      @ts.set(1, 'foo', 'bar', 'baz')
      @ts.set(2, 'qux', 'qip')

      assert @ts.matches(1, ['foo'])
      assert @ts.matches(1, ['bar', 'baz'])
      assert @ts.matches(1, ['bar', 'baz', 'foo'])
      refute @ts.matches(1, ['qux'])
      refute @ts.matches(1, ['qip'])

      refute @ts.matches(2, ['foo'])
      refute @ts.matches(2, ['bar', 'baz'])
      refute @ts.matches(2, ['bar', 'baz', 'foo'])
      assert @ts.matches(2, ['qux', 'qip'])
      assert @ts.matches(2, ['qux'])
      assert @ts.matches(2, ['qip'])
    end

    def test_matches_exclude_tags
      @ts.set(1, 'foo', 'bar', 'baz')
      @ts.set(2, 'qux', 'qip')

      refute @ts.matches(1, nil, ['foo'])
      refute @ts.matches(1, [], ['foo'])
      refute @ts.matches(1, [], ['bar', 'baz'])
      refute @ts.matches(1, [], ['bar', 'baz', 'foo'])
      assert @ts.matches(1, [], ['qux'])
      assert @ts.matches(1, [], ['qip'])

      assert @ts.matches(2, nil, ['foo'])
      assert @ts.matches(2, [], ['foo'])
      assert @ts.matches(2, [], ['bar', 'baz'])
      assert @ts.matches(2, [], ['bar', 'baz', 'foo'])
      refute @ts.matches(2, [], ['qux', 'qip'])
      refute @ts.matches(2, [], ['qux'])
      refute @ts.matches(2, [], ['qip'])
    end

    def test_matches_include_and_exclude_tags
      @ts.set(1, 'foo', 'bar', 'baz')
      @ts.set(2, 'qux', 'qip')

      refute @ts.matches(1, ['foo'], ['bar'])
      refute @ts.matches(1, ['bar'], ['foo'])

      assert @ts.matches(1, ['foo'], [])
      assert @ts.matches(1, ['foo'], nil)
      assert @ts.matches(1, ['foo'], ['qux'])

      assert @ts.matches(2, ['qip'], ['foo'])
      assert @ts.matches(2, ['qux'], ['bar', 'baz'])
      assert @ts.matches(2, ['qip'], ['bar', 'baz', 'foo'])
      refute @ts.matches(2, ['qip'], ['qux', 'qip'])
      refute @ts.matches(2, ['qip'], ['qux'])
      refute @ts.matches(2, ['qux'], ['qip'])
    end

  end
end
