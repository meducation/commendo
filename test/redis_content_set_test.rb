require_relative 'tests_for_content_sets.rb'
gem 'minitest'
require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/mock'
require 'mocha/setup'
require 'commendo'

module Commendo

  class RedisContentSetTest < Minitest::Test

    def setup
      Commendo.config do |config|
        config.backend = :redis
        config.host = 'localhost'
        config.port = 6379
        config.database = 15
      end
      Redis.new(host: Commendo.config.host, port: Commendo.config.port, db: Commendo.config.database).flushdb
      @key_base = 'CommendoTests'
      @cs = ContentSet.new(key_base: @key_base)
    end

    def create_tag_set(kb)
      Commendo::TagSet.new(key_base: kb)
    end

    def create_content_set(key_base, ts = nil)
      Commendo::ContentSet.new(key_base: key_base, tag_set: ts)
    end

    def test_gives_similarity_key_for_resource
      key_base = 'CommendoTestsFooBarBaz'
      cs = create_content_set(nil, key_base)
      assert_equal 'CommendoTestsFooBarBaz:similar:resource-1', cs.similarity_key('resource-1')
    end

    def test_calculate_yields_after_each
      (3..23).each do |group|
        (3..23).each do |res|
          @cs.add_by_group(group, res) if res % group == 0
        end
      end
      expected_keys = ['CommendoTests:resources:3', 'CommendoTests:resources:4', 'CommendoTests:resources:5', 'CommendoTests:resources:6', 'CommendoTests:resources:7', 'CommendoTests:resources:8', 'CommendoTests:resources:9', 'CommendoTests:resources:10', 'CommendoTests:resources:11', 'CommendoTests:resources:12', 'CommendoTests:resources:13', 'CommendoTests:resources:14', 'CommendoTests:resources:15', 'CommendoTests:resources:16', 'CommendoTests:resources:17', 'CommendoTests:resources:18', 'CommendoTests:resources:19', 'CommendoTests:resources:20', 'CommendoTests:resources:21', 'CommendoTests:resources:22', 'CommendoTests:resources:23']
      actual_keys = []
      @cs.calculate_similarity { |key, index, total|
        actual_keys << key
      }
      assert_equal expected_keys.sort, actual_keys.sort
    end

    include TestsForContentSets

  end

end