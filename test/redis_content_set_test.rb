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

    def create_content_set(ts, key_base = @key_base)
      Commendo::ContentSet.new(key_base: key_base, tag_set: ts)
    end

    def test_gives_similarity_key_for_resource
      key_base = 'CommendoTestsFooBarBaz'
      cs = create_content_set(nil, key_base)
      assert_equal 'CommendoTestsFooBarBaz:similar:resource-1', cs.similarity_key('resource-1')
    end

    include TestsForContentSets

  end

end