module TestsForWeightedGroups

  def test_calls_each_content_set
    expected = [
        {resource: '6', similarity: 74.037},
        {resource: '12', similarity: 55.5},
        {resource: '9', similarity: 6.67},
        {resource: '3', similarity: 4.0},
        {resource: '21', similarity: 2.86},
        {resource: '15', similarity: 2.86}
    ]
    assert_equal expected, @weighted_group.similar_to(18)
  end

  def test_calls_each_content_set_with_limits
    expected = [
        {resource: '6', similarity: 74.037},
        {resource: '12', similarity: 55.5},
        {resource: '9', similarity: 6.67},
        {resource: '3', similarity: 4.0},
        {resource: '21', similarity: 2.86},
        {resource: '15', similarity: 2.86}
    ]
    assert_equal expected[0..0], @weighted_group.similar_to(18, 1)
    assert_equal expected[0..2], @weighted_group.similar_to(18, 3)
    assert_equal expected, @weighted_group.similar_to(18, 6)
    assert_equal expected, @weighted_group.similar_to(18, 99)
  end

  def test_filters_include_recommendations
    expected = [{resource: '15', similarity: 2.86}]
    @weighted_group.tag_set = @tag_set
    assert_equal expected, @weighted_group.filtered_similar_to(18, include: ['mod5'])
  end

  def test_filters_exclude_recommendations
    expected = [
        {resource: '6', similarity: 74.037},
        {resource: '12', similarity: 55.5},
        {resource: '9', similarity: 6.67},
        {resource: '3', similarity: 4.0}
    ]
    @weighted_group.tag_set = @tag_set
    assert_equal expected, @weighted_group.filtered_similar_to(18, exclude: ['mod5', 'mod7'])
  end

  def test_filters_include_and_exclude_recommendations
    expected = [
        {resource: '16', similarity: 0.8},
        {resource: '4', similarity: 0.667},
        {resource: '12', similarity: 0.333}
    ]
    @weighted_group.tag_set = @tag_set
    assert_equal expected, @weighted_group.filtered_similar_to(8, include: ['mod4'], exclude: ['mod5'])
  end

  def test_filters_include_and_exclude_recommendations_and_limits
    expected = [
        {resource: '16', similarity: 0.8},
        {resource: '4', similarity: 0.667},
        {resource: '12', similarity: 0.333}
    ]
    @weighted_group.tag_set = @tag_set
    assert_equal expected[0..0], @weighted_group.filtered_similar_to(8, include: ['mod4'], exclude: ['mod5'], limit: 1)
    assert_equal expected[0..1], @weighted_group.filtered_similar_to(8, include: ['mod4'], exclude: ['mod5'], limit: 2)
    assert_equal expected, @weighted_group.filtered_similar_to(8, include: ['mod4'], exclude: ['mod5'], limit: 3)
    assert_equal expected, @weighted_group.filtered_similar_to(8, include: ['mod4'], exclude: ['mod5'], limit: 99)
  end

  def test_similar_to_mutliple_items
    expected = [
        {resource: '12', similarity: 78.437},
        {resource: '18', similarity: 78.037},
        {resource: '9', similarity: 11.67},
        {resource: '21', similarity: 9.0},
        {resource: '15', similarity: 9.0},
        {resource: '6', similarity: 6.67},
        {resource: '3', similarity: 6.67},
        {resource: '8', similarity: 0.667},
        {resource: '16', similarity: 0.5},
        {resource: '20', similarity: 0.4}
    ]
    @weighted_group.tag_set = @tag_set
    assert_equal expected, @weighted_group.similar_to([3, 4, 5, 6, 7])
  end

  def test_filtered_similar_to_mutliple_items
    expected = [
        {resource: '12', similarity: 78.437},
        {resource: '8', similarity: 0.667},
        {resource: '16', similarity: 0.5},
    ]

    @weighted_group.tag_set = @tag_set
    assert_equal expected, @weighted_group.filtered_similar_to([3, 4, 5, 6, 7], include: ['mod4'], exclude: ['mod5'])
  end

  def test_weightings_affect_scores
    skip
  end

  def test_precalculates
    skip
  end

end