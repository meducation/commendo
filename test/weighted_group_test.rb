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

    def test_calls_each_content_set
      weighted_group = WeightedGroup.new(
        @redis,
        'CommendoTests:WeightedGroup',
        {cs: @cs1, weight: 1.0},
        {cs: @cs2, weight: 10.0},
        {cs: @cs3, weight: 100.0}
      )
      expected = [
        {resource: '6', similarity: 74.037},
        {resource: '12', similarity: 55.5},
        {resource: '9', similarity: 6.67},
        {resource: '3', similarity: 4.0},
        {resource: '21', similarity: 2.86},
        {resource: '15', similarity: 2.86}
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
      expected = [{resource: '15', similarity: 2.86}]
      weighted_group.tag_set = @tag_set
      assert_equal expected, weighted_group.filtered_similar_to(18, include: ['mod5'])
    end

    def test_filters_exclude_recommendations
      weighted_group = WeightedGroup.new(
        @redis,
        'CommendoTests:WeightedGroup',
        {cs: @cs1, weight: 1.0},
        {cs: @cs2, weight: 10.0},
        {cs: @cs3, weight: 100.0}
      )
      expected = [
        {resource: '6', similarity: 74.037},
        {resource: '12', similarity: 55.5},
        {resource: '9', similarity: 6.67},
        {resource: '3', similarity: 4.0}
      ]
      weighted_group.tag_set = @tag_set
      assert_equal expected, weighted_group.filtered_similar_to(18, exclude: ['mod5', 'mod7'])
    end

    def test_filters_include_and_exclude_recommendations
      weighted_group = WeightedGroup.new(
        @redis,
        'CommendoTests:WeightedGroup',
        {cs: @cs1, weight: 100.0},
        {cs: @cs2, weight: 10.0},
        {cs: @cs3, weight: 1.0}
      )
      expected = [
        {resource: '16', similarity: 80.0},
        {resource: '4', similarity: 66.7},
        {resource: '12', similarity: 33.3}
      ]
      weighted_group.tag_set = @tag_set
      assert_equal expected, weighted_group.filtered_similar_to(8, include: ['mod4'], exclude: ['mod5'])
    end

    def test_similar_to_mutliple_items
      weighted_group = WeightedGroup.new(
        @redis,
        'CommendoTests:WeightedGroup',
        {cs: @cs1, weight: 100.0},
        {cs: @cs2, weight: 10.0},
        {cs: @cs3, weight: 1.0}
      )
      expected = [
        {resource: '12', similarity: 118.037},
        {resource: '18', similarity: 78.037},
        {resource: '8', similarity: 66.7},
        {resource: '16', similarity: 50.0},
        {resource: '20', similarity: 40.0},
        {resource: '9', similarity: 11.67},
        {resource: '21', similarity: 9.0},
        {resource: '15', similarity: 9.0},
        {resource: '6', similarity: 6.67},
        {resource: '3', similarity: 6.67}
      ]
      weighted_group.tag_set = @tag_set
      assert_equal expected, weighted_group.similar_to([3,4,5,6,7])
    end

    def test_filtered_similar_to_mutliple_items
      weighted_group = WeightedGroup.new(
        @redis,
        'CommendoTests:WeightedGroup',
        {cs: @cs1, weight: 100.0},
        {cs: @cs2, weight: 10.0},
        {cs: @cs3, weight: 1.0}
      )
      expected = [
        {resource: '12', similarity: 118.037},
        {resource: '8', similarity: 66.7},
        {resource: '16', similarity: 50.0},
      ]
      weighted_group.tag_set = @tag_set
      assert_equal expected, weighted_group.filtered_similar_to([3,4,5,6,7], include: ['mod4'], exclude: ['mod5'])
    end

    def test_precalculates
      skip
    end


  end

end
