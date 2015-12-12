module TestsForTagSets

  def test_adds_tags_for_resource
    assert_equal [], @ts.get(1)
    @ts.add(1, 'foo', 'bar', 'baz')
    expected = @ts.get(1)
    assert_equal %w(bar baz foo).sort, expected.sort
    @ts.add(1, 'qux', 'qip')
    expected = @ts.get(1)
    assert_equal %w(bar baz foo qip qux).sort, expected.sort
  end

  def test_isolates_by_key_base
    ts1 = create_tag_set('TagSetOne')
    ts2 = create_tag_set('TagSetTwo')
    assert_equal [], ts1.get(1)
    assert_equal [], ts2.get(1)

    ts1.add(1, 'foo', 'bar', 'baz')

    assert_equal %w(bar baz foo).sort, ts1.get(1).sort
    assert_equal [], ts2.get(1)

    ts2.add(1, 'qux', 'qip')
    assert_equal %w(bar baz foo).sort, ts1.get(1).sort
    assert_equal %w(qux qip).sort, ts2.get(1).sort
  end

  def test_empty?
    assert @ts.respond_to? :empty?
    assert @ts.empty?
    @ts.add(1, 'qux', 'qip')
    refute @ts.empty?
    @ts.delete(1)
    assert @ts.empty?
  end

  def test_sets_tags_for_resource
    assert_equal [], @ts.get(1)
    @ts.set(1, 'foo', 'bar', 'baz')
    assert_equal %w(bar baz foo).sort, @ts.get(1).sort
    @ts.set(1, 'qux', 'qip')
    assert_equal %w(qip qux).sort, @ts.get(1).sort
  end

  def test_sets_tags_when_empty
    @ts.set(1, 'foo', 'bar', 'baz')
    @ts.set(2, 'qux', 'qip')
    assert_equal %w(bar baz foo).sort, @ts.get(1).sort
    assert_equal %w(qip qux).sort, @ts.get(2).sort
    @ts.set(1, *[])
    assert_equal [], @ts.get(1)
    assert_equal %w(qip qux).sort, @ts.get(2).sort
  end

  def test_deletes_all_tags_for_resource
    @ts.set(1, 'foo', 'bar', 'baz')
    @ts.set(2, 'qux', 'qip')
    assert_equal %w(bar baz foo).sort, @ts.get(1).sort
    assert_equal %w(qip qux).sort, @ts.get(2).sort
    @ts.delete(1)
    assert_equal [], @ts.get(1)
    assert_equal %w(qip qux).sort, @ts.get(2).sort
  end

  def test_deletes_given_tags_for_resource
    assert_equal [], @ts.get(1)
    @ts.set(1, 'foo', 'bar', 'baz', 'qux', 'qip')
    @ts.delete(1, 'qux', 'qip')
    assert_equal %w(bar baz foo).sort, @ts.get(1).sort
  end

  def test_matches_tags
    @ts.set(1, 'foo', 'bar', 'baz')
    @ts.set(2, 'qux', 'qip')

    assert @ts.matches(1, ['foo'])
    assert @ts.matches(1, %w(bar baz))
    assert @ts.matches(1, %w(bar baz foo))
    refute @ts.matches(1, ['qux'])
    refute @ts.matches(1, ['qip'])

    refute @ts.matches(2, ['foo'])
    refute @ts.matches(2, %w(bar baz))
    refute @ts.matches(2, %w(bar baz foo))
    assert @ts.matches(2, %w(qux qip))
    assert @ts.matches(2, ['qux'])
    assert @ts.matches(2, ['qip'])
  end

  def test_matches_exclude_tags
    @ts.set(1, 'foo', 'bar', 'baz')
    @ts.set(2, 'qux', 'qip')

    refute @ts.matches(1, nil, ['foo'])
    refute @ts.matches(1, [], ['foo'])
    refute @ts.matches(1, [], %w(bar baz))
    refute @ts.matches(1, [], %w(bar baz foo))
    assert @ts.matches(1, [], ['qux'])
    assert @ts.matches(1, [], ['qip'])

    assert @ts.matches(2, nil, ['foo'])
    assert @ts.matches(2, [], ['foo'])
    assert @ts.matches(2, [], %w(bar baz))
    assert @ts.matches(2, [], %w(bar baz foo))
    refute @ts.matches(2, [], %w(qux qip))
    refute @ts.matches(2, [], ['qux'])
    refute @ts.matches(2, [], ['qip'])
  end

  def test_matches_include_and_exclude_tags
    @ts.set(1, 'foo', 'bar', 'baz')
    @ts.set(2, 'qux', 'qip')

    refute @ts.matches(1, ['foo'], ['bar'])
    refute @ts.matches(1, ['bar'], ['foo'])

    assert @ts.matches(1, ['foo'], [])
    assert @ts.matches(1, ['foo'], nil)
    assert @ts.matches(1, ['foo'], ['qux'])

    assert @ts.matches(2, ['qip'], ['foo'])
    assert @ts.matches(2, ['qux'], %w(bar baz))
    assert @ts.matches(2, ['qip'], %w(bar baz foo))
    refute @ts.matches(2, ['qip'], %w(qux qip))
    refute @ts.matches(2, ['qip'], ['qux'])
    refute @ts.matches(2, ['qux'], ['qip'])
  end

end