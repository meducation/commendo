require_relative 'tests_for_tag_sets'
gem 'minitest'
require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/mock'
require 'mocha/setup'
require 'commendo'

module Commendo

  class MySqlTagSetTest < Minitest::Test

    def setup
      Commendo.config do |config|
        config.backend = :mysql
        config.host = 'localhost'
        config.port = 3306
        config.database = 'commendo_test'
        config.username = 'commendo'
        config.password = 'commendo123'
      end
      client = Mysql2::Client.new(Commendo.config.to_hash)
      %w(Groups Resources Tags).each {|table| client.query("DELETE FROM #{table};") }
      @ts = TagSet.new(key_base: 'TagSetTest')
    end

    def create_tag_set(kb)
      Commendo::TagSet.new(key_base: kb)
    end

    include TestsForTagSets

  end
end
