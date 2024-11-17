# frozen_string_literal: true

require 'test_helper'

describe Matcher::ReferenceMatcher do
  it 'is build by refs[]' do
    matcher = Matcher.build do
      refs[:foo] = { bar: refs[:foo] }
      refs[:foo]
    end

    assert_kind_of Matcher::ReferenceMatcher, matcher
  end

  it 'matches linked lists' do
    matcher = Matcher.build do
      refs[:list] = {
        head: Integer,
        tail: imply_one(
          imply(Hash, refs[:list]),
          else: nil,
        ),
      }
    end

    negated = ~matcher

    valid_list = { head: 1, tail: { head: 2, tail: nil } }

    assert_no_errors matcher.match(valid_list)
    assert_expected_errors negated.match(valid_list) do
      _or do
        error :head, 'did not expect a kind of Integer but got 1'
        error %i[tail head], 'did not expect a kind of Integer but got 2'
        error %i[tail tail], 'did not expect nil'
      end
    end

    invalid_list = { head: 1, tail: { head: 2, tail: { head: 3 } } }

    assert_expected_errors matcher.match(invalid_list),
      tail: { tail: 'expected to include key :tail but got {:head=>3}' }
    assert_no_errors negated.match(invalid_list)
  end

  it 'caches results' do
    matcher = Matcher.build do
      refs[:foo] = 'foo'

      [refs[:foo], refs[:foo]]
    end

    negated = ~matcher

    assert_no_errors matcher.match(['foo', 'foo'])
    assert_expected_errors negated.match(['foo', 'foo']) do
      _or do
        error 0, 'did not expect "foo"'
        error 1, 'actual has already failed before'
      end
    end

    assert_expected_errors matcher.match(['bar', 'bar']),
      0 => 'expected "foo" but got "bar"',
      1 => 'actual has already failed before'
    assert_no_errors negated.match(['bar', 'bar'])
  end

  it 'matches without cache' do
    matcher = Matcher.build do
      refs[:index, cache: false] = _ == index

      [refs[:index], refs[:index]]
    end

    negated = ~matcher

    assert_no_errors matcher.match([0, 1])
    assert_expected_errors negated.match([0, 1]) do
      _or do
        error 0, 'expected _ != i but got 0 != 0'
        error 1, 'expected _ != i but got 1 != 1'
      end
    end

    assert_expected_errors matcher.match([0, 0]),
      1 => 'expected _ == i but got 0 == 1'
    assert_no_errors negated.match([0, 0])
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

    negated = ~matcher

    actual = { head: 1, tail: { head: 2, tail: nil } }

    assert_no_errors matcher.match(actual)
    assert_expected_errors negated.match(actual) do
      _or do
        error :head, 'did not expect a kind of Integer but got 1'
        error %i[tail head], 'did not expect a kind of Integer but got 2'
        error %i[tail tail], 'did not expect nil'
      end
    end

    actual[:tail][:tail] = actual

    assert_expected_errors matcher.match(actual) do
      error %i[tail tail], 'did not expect a cyclic structure but actual has already been visited'
    end
    assert_no_errors negated.match(actual)
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

    negated = ~matcher

    ring_of = lambda do |*list|
      last = { value: list.pop }
      last[:next] = list.reverse_each.reduce(last) { { value: _2, next: _1 } }
    end

    ring1 = ring_of[1, 2, 3]

    assert_no_errors matcher.match(ring1)
    assert_expected_errors negated.match(ring1) do
      _or do
        error :value, 'did not expect a kind of Integer but got 1'
        error %i[next value], 'did not expect a kind of Integer but got 2'
        error %i[next next value], 'did not expect a kind of Integer but got 3'
        error %i[next next next], 'did not expect a cyclic structure but actual has already been visited'
      end
    end

    ring2 = ring_of[1, nil, 3]

    assert_expected_errors matcher.match(ring2),
      next: { value: 'expected a kind of Integer but got nil' }
    assert_no_errors negated.match(ring2)
  end

  it '#to_s' do
    matcher = Matcher.build do
      refs[:foo] = { bar: refs[:foo] }
      refs[:foo]
    end

    assert_equal 'refs[:foo]', matcher.to_s
    assert_equal '~refs[:foo]', matcher.~.to_s
  end
end
