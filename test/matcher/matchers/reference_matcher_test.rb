# frozen_string_literal: true

require 'test_helper'

describe Matcher::ReferenceMatcher do
  it 'linked list' do
    matcher = Matcher.build do
      refs[:list] = {
        head: Integer,
        tail: imply_one(
          imply(Hash, refs[:list]),
          else: nil,
        ),
      }
    end

    list = { head: 1, tail: { head: 2, tail: { head: 3 } } }

    assert_errors matcher.match(list) do
      error %i[tail tail tail], 'expected entry for :tail but found nothing'
    end
  end

  it 'without cache' do
    matcher = Matcher.build do
      refs[:index, cache: false] = _ == index

      [refs[:index], refs[:index]]
    end

    assert_errors matcher.match([0, 0]),
      1 => 'expected _ to be i (1) but got 0'

    assert_predicate matcher.match([0, 1]), :valid?
  end

  it 'negated ref' do
    matcher = Matcher.build do
      refs[:foo] = 42

      ~refs[:foo]
    end

    assert_predicate matcher.match(25), :valid?
    assert_errors matcher.match(42), 'expected 42 to not be 42'
  end

  it 'detects cycles' do
    matcher = Matcher.build do
      list = refs[:list]

      refs[:list] = {
        head: Integer,
        tail: imply_one(
          imply(Hash, list),
          else: nil,
        ),
      }

      list
    end

    actual = { head: 1, tail: { head: 2, tail: nil } }

    assert_predicate matcher.match(actual), :valid?

    actual[:tail][:tail] = actual

    assert_errors matcher.match(actual) do
      error %i[tail tail], 'cyclic structure: actual has already been visited'
    end
  end

  it 'detects cycles: negated' do
    matcher = Matcher.build do
      list = refs[:list]

      refs[:list] = {
        head: Integer,
        tail: imply_one(
          imply(Hash, list),
          else: nil,
        ),
      }

      ~list
    end

    actual = { head: 1, tail: { head: 2, tail: nil } }

    assert_errors matcher.match(actual) do
      _or do
        error :head, 'expected 1 to be not kind of Integer'
        error %i[tail head], 'expected 2 to be not kind of Integer'
        error %i[tail tail], 'expected nil to not be nil'
      end
    end

    actual[:tail][:tail] = actual

    assert_predicate matcher.match(actual), :valid?
  end

  def ring_of(*list)
    last = { value: list.pop }
    last[:next] = list.reverse_each.reduce(last) { { value: _2, next: _1 } }
  end

  it 'allows cycles' do
    matcher = Matcher.build do
      ring = refs[:ring, cyclic: true]

      refs[:ring] = {
        value: Integer,
        next: ring,
      }

      ring
    end

    assert_predicate matcher.match(ring_of(1, 2, 3)), :valid?

    assert_errors matcher.match(ring_of(1, nil, 3)),
      next: { value: 'expected nil to be kind of Integer' }
  end

  it 'allows cycles: negated' do
    matcher = Matcher.build do
      ring = refs[:ring, cyclic: true]

      refs[:ring] = {
        value: Integer,
        next: ring,
      }

      ~ring
    end

    assert_errors matcher.match(ring_of(1, 2, 3)) do
      _or do
        error :value, 'expected 1 to be not kind of Integer'
        error %i[next value], 'expected 2 to be not kind of Integer'
        error %i[next next value], 'expected 3 to be not kind of Integer'
        error %i[next next next], 'expected not a valid cyclic structure'
      end
    end

    assert_predicate matcher.match(ring_of(1, nil, 3)), :valid?
  end

  it 'caches results' do
    matcher = Matcher.build do
      refs[:foo] = 'foo'

      [refs[:foo], refs[:foo]]
    end

    bar = 'bar'

    assert_errors matcher.match([bar, bar]),
      0 => 'expected "foo" but got "bar"',
      1 => 'actual has already failed before'
  end

  it 'caches results: negated' do
    matcher = Matcher.build do
      refs[:foo] = 'foo'

      neg([refs[:foo], refs[:foo]])
    end

    foo = 'foo'
    bar = 'bar'

    assert_predicate matcher.match([bar, bar]), :valid?

    assert_errors matcher.match([foo, foo]) do
      _or do
        error 0, 'expected "foo" to not be "foo"'
        error 1, 'actual has already failed before'
      end
    end
  end
end
