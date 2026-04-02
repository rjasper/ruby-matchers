# frozen_string_literal: true

require "test_helper"

describe Matcher::ReferenceMatcher do
  it "is build by refs[]" do
    matcher = Matcher.build do
      refs[:foo] = { bar: refs[:foo] }
      refs[:foo]
    end

    assert_kind_of Matcher::ReferenceMatcher, matcher
  end

  describe "MatcherBuilding#refs" do
    it "returns target matcher if last line was refs[]=" do
      ref_matcher = nil

      matcher = Matcher.build do
        ref_matcher = refs[:loop]
        refs[:loop] = { next: refs[:loop] }
      end

      assert_same ref_matcher.send(:target), matcher
    end

    it "checks for undefined refs" do
      err = assert_raises StandardError do
        Matcher.build { [refs[:foo]] }
      end

      assert_equal "undefined ref: foo", err.message
    end

    it "checks for unused refs" do
      err = assert_raises StandardError do
        Matcher.build { refs[:foo] = Integer }
      end

      assert_equal "unused ref: foo", err.message
    end
  end

  it "matches linked lists" do
    matcher = Matcher.build do
      refs[:list] = {
        head: Integer,
        tail: imply_one(
          of(Hash) >> refs[:list],
          else: nil,
        ),
      }
    end

    negated = ~matcher

    valid_list = { head: 1, tail: { head: 2, tail: nil } }

    assert matcher.match?(valid_list)
    assert_no_errors matcher.match(valid_list)
    refute negated.match?(valid_list)
    assert_errors negated.match(valid_list) do
      _or do
        error :head, msg(1).kind_of(Integer)
        error %i[tail head], msg(2).kind_of(Integer)
        error %i[tail tail], msg(nil).equal(nil)
      end
    end

    invalid_list = { head: 1, tail: { head: 2, tail: { head: 3 } } }

    refute matcher.match?(invalid_list)
    assert_errors matcher.match(invalid_list),
      tail: { tail: msg({ head: 3 }).not.having_key(:tail) }
    assert negated.match?(invalid_list)
    assert_no_errors negated.match(invalid_list)
  end

  it "caches results" do
    matcher = Matcher.build do
      refs[:foo] = "foo"

      [refs[:foo], refs[:foo]]
    end

    negated = ~matcher

    assert matcher.match?(["foo", "foo"])
    assert_no_errors matcher.match(["foo", "foo"])
    refute negated.match?(["foo", "foo"])
    assert_errors negated.match(["foo", "foo"]) do
      _or do
        error 0, msg("foo").equal("foo")
        error 1, "actual has already failed before"
      end
    end

    refute matcher.match?(["bar", "bar"])
    assert_errors matcher.match(["bar", "bar"]),
      0 => msg("bar").not.equal("foo"),
      1 => "actual has already failed before"
    assert negated.match?(["bar", "bar"])
    assert_no_errors negated.match(["bar", "bar"])
  end

  it "matches without cache" do
    matcher = Matcher.build do
      refs[:index, { cache: false }] = _ == index

      [refs[:index], refs[:index]]
    end

    negated = ~matcher

    assert matcher.match?([0, 1])
    assert_no_errors matcher.match([0, 1])
    refute negated.match?([0, 1])
    assert_errors negated.match([0, 1]) do
      _or do
        error 0, "expected actual != index but got 0 != 0"
        error 1, "expected actual != index but got 1 != 1"
      end
    end

    refute matcher.match?([0, 0])
    assert_errors matcher.match([0, 0]),
      1 => "expected actual == index but got 0 == 1"
    assert negated.match?([0, 0])
    assert_no_errors negated.match([0, 0])
  end

  it "detects cycles" do
    matcher = Matcher.build do
      list = refs[:list]

      refs[:list] = {
        head: Integer,
        tail: imply_one(
          of(Hash) >> list,
          else: nil,
        ),
      }

      list
    end

    negated = ~matcher

    actual = { head: 1, tail: { head: 2, tail: nil } }

    assert matcher.match?(actual)
    assert_no_errors matcher.match(actual)
    refute negated.match?(actual)
    assert_errors negated.match(actual) do
      _or do
        error :head, msg(1).kind_of(Integer)
        error %i[tail head], msg(2).kind_of(Integer)
        error %i[tail tail], msg(nil).equal(nil)
      end
    end

    actual[:tail][:tail] = actual

    refute matcher.match?(actual)
    assert_errors matcher.match(actual) do
      error %i[tail tail], "did not expect a cyclic structure but actual has already been visited"
    end
    assert negated.match?(actual)
    assert_no_errors negated.match(actual)
  end

  it "allows cycles" do
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

    assert matcher.match?(ring1)
    assert_no_errors matcher.match(ring1)
    refute negated.match?(ring1)
    assert_errors negated.match(ring1) do
      _or do
        error :value, msg(1).kind_of(Integer)
        error %i[next value], msg(2).kind_of(Integer)
        error %i[next next value], msg(3).kind_of(Integer)
        error %i[next next next], "did not expect a cyclic structure but actual has already been visited"
      end
    end

    ring2 = ring_of[1, nil, 3]

    refute matcher.match?(ring2)
    assert_errors matcher.match(ring2),
      next: { value: msg(nil).not.kind_of(Integer) }
    assert negated.match?(ring2)
    assert_no_errors negated.match(ring2)
  end

  it "#to_s" do
    matcher = Matcher.build do
      refs[:foo] = { bar: refs[:foo] }
      refs[:foo]
    end

    assert_equal "refs[:foo]", matcher.to_s
    assert_equal "~refs[:foo]", matcher.~.to_s
  end
end
