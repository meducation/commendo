require_relative 'tests_for_weighted_groups'
gem 'minitest'
require 'minitest/autorun'
require 'minitest/pride'
require 'minitest/mock'
require 'mocha/setup'
require 'commendo'

module Commendo

  class WeightedGroupTest < Minitest::Test

    def setup
      super
      @redis ||= Redis.new(db: 15)
      @redis.flushdb
      @tag_set = TagSet.new(@redis, 'CommendoTests:Tags')
      @cs1 = ContentSet.new(@redis, 'CommendoTests:ContentSet1', @tag_set)
      @cs2 = ContentSet.new(@redis, 'CommendoTests:ContentSet2', @tag_set)
      @cs3 = ContentSet.new(@redis, 'CommendoTests:ContentSet3', @tag_set)
      (3..23).each do |group|
        (3..23).each do |res|
          @cs1.add_by_group(group, res) if res.modulo(group).zero? && res.modulo(2).zero?
          @cs2.add_by_group(group, res) if res.modulo(group).zero? && res.modulo(3).zero?
          @cs3.add_by_group(group, res) if res.modulo(group).zero? && res.modulo(6).zero?
          @tag_set.add(res, 'mod3') if res.modulo(3).zero?
          @tag_set.add(res, 'mod4') if res.modulo(4).zero?
          @tag_set.add(res, 'mod5') if res.modulo(5).zero?
          @tag_set.add(res, 'mod7') if res.modulo(7).zero?
        end
      end
      [@cs1, @cs2, @cs3].each { |cs| cs.calculate_similarity }
    end

    include TestsForWeightedGroups

  end

end
