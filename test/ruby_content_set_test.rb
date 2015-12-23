require_relative 'tests_for_content_sets.rb'
gem 'minitest'
require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/mock'
require 'mocha/setup'
require 'commendo'

module Commendo

  class RubyContentSetTest < Minitest::Test

    def setup
      Commendo.config do |config|
        config.backend = :ruby
      end
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