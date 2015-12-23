require_relative 'tests_for_tag_sets'
gem 'minitest'
require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/mock'
require 'mocha/setup'
require 'commendo'

module Commendo

  class RubyTagSetTest < Minitest::Test

    def setup
      Commendo.config do |config|
        config.backend = :ruby
      end
      @ts = TagSet.new(key_base: 'TagSetTest')
    end

    def create_tag_set(kb)
      Commendo::TagSet.new(key_base: kb)
    end

    include TestsForTagSets

  end
end
