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
          @cs1.add_by_group(group, res) if (res % group == 0) && (res % 2 == 0)
          @cs2.add_by_group(group, res) if (res % group == 0) && (res % 3 == 0)
          @cs3.add_by_group(group, res) if (res % group == 0) && (res % 6 == 0)
          @tag_set.add(res, 'mod3') if res.modulo(3).zero?
          @tag_set.add(res, 'mod5') if res.modulo(5).zero?
          @tag_set.add(res, 'mod7') if res.modulo(7).zero?
        end
      end
      [@cs1, @cs2, @cs3].each { |cs| cs.calculate_similarity }
    end

    def test_calls_each_content_set
      weighted_group = WeightedGroup.new(
        @redis,
        'CommendoTests:WeightedGroup',
        {cs: @cs1, weight: 1.0},
        {cs: @cs2, weight: 10.0},
        {cs: @cs3, weight: 100.0}
      )
      expected = [
        {resource: '6', similarity: 55.5},
        {resource: '12', similarity: 36.963},
        {resource: '9', similarity: 5.0},
        {resource: '3', similarity: 2.5},
        {resource: '21', similarity: 1.67},
        {resource: '15', similarity: 1.67}
      ]
      assert_equal expected, weighted_group.similar_to(18)
    end

    def test_filters_include_recommendations
      weighted_group = WeightedGroup.new(
        @redis,
        'CommendoTests:WeightedGroup',
        {cs: @cs1, weight: 1.0},
        {cs: @cs2, weight: 10.0},
        {cs: @cs3, weight: 100.0}
      )
      expected = [
        #{resource: '6', similarity: 55.5},
        #{resource: '12', similarity: 36.963},
        #{resource: '9', similarity: 5.0},
        #{resource: '3', similarity: 2.5},
        #{resource: '21', similarity: 1.67},
        {resource: '15', similarity: 1.67}
      ]
      weighted_group.tag_set = @tag_set
      assert_equal expected, weighted_group.filtered_similar_to(18, include: ['mod5'])
    end

    def test_similar_to_mutliple_items
      skip
    end

    def test_filtered_similar_to_mutliple_items
      skip
    end

    def test_precalculates
      skip
    end


  end

end
