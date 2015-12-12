require_relative 'tests_for_content_sets.rb'
gem 'minitest'
require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/mock'
require 'mocha/setup'
require 'commendo'

module Commendo

  class MySqlContentSetTest < Minitest::Test

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
      %w(Tags Resource).each {|table| client.query("DELETE FROM #{table};") }
      @key_base = 'CommendoTests'
      @cs = ContentSet.new(key_base: @key_base)
    end

    def create_tag_set(kb)
      Commendo::TagSet.new(key_base: kb)
    end

    def create_content_set(key_base, ts = nil)
      Commendo::ContentSet.new(key_base: key_base, tag_set: ts)
    end

    include TestsForContentSets

  end

end