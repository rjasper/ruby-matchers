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

    assert_expected_errors matcher.match(list) do
      error %i[tail tail tail], 'expected to include key :tail but got {:head=>3}'
    end
  end

  it 'without cache' do
    matcher = Matcher.build do
      refs[:index, cache: false] = _ == index

      [refs[:index], refs[:index]]
    end

    assert_expected_errors matcher.match([0, 0]),
      1 => 'expected _ == i but got 0 == 1'

    assert_no_errors matcher.match([0, 1])
  end

  it 'negated ref' do
    matcher = Matcher.build do
      refs[:foo] = 42

      ~refs[:foo]
    end

    assert_no_errors matcher.match(25)
    assert_expected_errors matcher.match(42), 'did not expect 42'
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

    assert_no_errors matcher.match(actual)

    actual[:tail][:tail] = actual

    assert_expected_errors matcher.match(actual) do
      error %i[tail tail], 'expected a cyclic structure but actual has already been visited'
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

    assert_expected_errors matcher.match(actual) do
      _or do
        error :head, 'did not expect a kind of Integer but got 1'
        error %i[tail head], 'did not expect a kind of Integer but got 2'
        error %i[tail tail], 'did not expect nil'
      end
    end

    actual[:tail][:tail] = actual

    assert_no_errors matcher.match(actual)
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

    assert_no_errors matcher.match(ring_of(1, 2, 3))

    assert_expected_errors matcher.match(ring_of(1, nil, 3)),
      next: { value: 'expected a kind of Integer but got nil' }
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

    assert_expected_errors matcher.match(ring_of(1, 2, 3)) do
      _or do
        error :value, 'did not expect a kind of Integer but got 1'
        error %i[next value], 'did not expect a kind of Integer but got 2'
        error %i[next next value], 'did not expect a kind of Integer but got 3'
        error %i[next next next], 'did not expect a valid cyclic structure'
      end
    end

    assert_no_errors matcher.match(ring_of(1, nil, 3))
  end

  it 'caches results' do
    matcher = Matcher.build do
      refs[:foo] = 'foo'

      [refs[:foo], refs[:foo]]
    end

    bar = 'bar'

    assert_expected_errors matcher.match([bar, bar]),
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

    assert_no_errors matcher.match([bar, bar])

    assert_expected_errors matcher.match([foo, foo]) do
      _or do
        error 0, 'did not expect "foo"'
        error 1, 'actual has already failed before'
      end
    end
  end
end
