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
      Commendo.config do |config|
        config.backend = :redis
        config.host = 'localhost'
        config.port = 6379
        config.database = 15
      end
      Redis.new(host: Commendo.config.host, port: Commendo.config.port, db: Commendo.config.database).flushdb
      @ts = TagSet.new(key_base: 'TagSetTest')
    end

    def create_tag_set(kb)
      Commendo::TagSet.new(key_base: kb)
    end

    include TestsForTagSets

  end
end
