require_relative 'tests_for_content_sets.rb'
gem 'minitest'
require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/mock'
require 'mocha/setup'
require 'commendo'

module Commendo

  class ContentSetTest < Minitest::Test

    def setup
      @redis = Redis.new(db: 15)
      @redis.flushdb
      @key_base = 'CommendoTests'
      @cs = ContentSet.new(:redis, redis: @redis, key_base: @key_base)
    end

    def create_tag_set(kb)
      Commendo::TagSet.new(:redis, redis: @redis, key_base: kb)
    end

    def create_content_set(ts, key_base = @key_base)
      Commendo::ContentSet.new(:redis, redis: @redis, key_base: key_base, tag_set: ts)
    end

    include TestsForContentSets

  end

end