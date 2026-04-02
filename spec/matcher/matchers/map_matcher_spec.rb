# frozen_string_literal: true

require "test_helper"

describe Matcher::MapMatcher do
  it "is built by map" do
    assert_kind_of(
      Matcher::MapMatcher,
      Matcher.build { map(_.length, [1, 2]) },
    )

    assert_kind_of(
      Matcher::MapMatcher,
      Matcher.build { map(_.length) ^ [1, 2] },
    )
  end

  it "expects actual to respond to :each" do
    matcher = Matcher.build { map(_.length, [1, 2]) }

    refute matcher.match?(nil)
    assert_errors matcher.match(nil),
      msg(nil).not.responding_to(:each)
    assert matcher.~.match?(nil)
    assert_no_errors matcher.~.match(nil)
  end

  it "rescues from call errors" do
    matcher = Matcher.build { map(_.length, [1]) }

    refute matcher.match?([nil])
    assert_errors matcher.match([nil]),
      0 => msg(nil).not.responding_to(:length)
    assert matcher.~.match?([nil])
    assert_no_errors matcher.~.match([nil])
  end

  it "matches mapped matcher" do
    matcher = Matcher.build { map(_.length, [1, 2]) }
    negated = ~matcher
    t = self

    assert matcher.match?([[1], [1, 2]])
    assert_no_errors matcher.match([[1], [1, 2]])
    refute negated.match?([[1], [1, 2]])
    assert_errors negated.match([[1], [1, 2]]) do
      _or do
        error t.expression { _[0].length }, msg(1).equal(1)
        error t.expression { _[1].length }, msg(2).equal(2)
      end
    end

    refute matcher.match?([[1], [1, 2, 3]])
    assert_errors matcher.match([[1], [1, 2, 3]]),
      expression { _[1].length } => msg(3).not.equal(2)
    assert negated.match?([[1], [1, 2, 3]])
    assert_no_errors negated.match([[1], [1, 2, 3]])
  end

  it "maps base errors" do
    matcher = Matcher.build { map(_.length, _.sum == 4) }
    negated = ~matcher
    key = expression { _.map(&:length) }

    assert_no_errors matcher.match([[1], [2, 3], [4]])
    assert_errors negated.match([[1], [2, 3], [4]]),
      key => "expected actual.sum != 4 but got 4 != 4, where actual = [1, 2, 1]"

    assert_errors matcher.match([[1], [2, 3]]),
      key => "expected actual.sum == 4 but got 3 == 4, where actual = [1, 2]"
    assert_no_errors negated.match([[1], [2, 3]])
  end

  it "maps functional error key" do
    matcher = Matcher.build do
      map(_ + index * 10 + original.length * 100, [209, 218])
    end

    assert_errors matcher.match([9, 8, 7]),
      expression { _.map.with_index { |e, index| e + index * 10 + _.length * 100 } } =>
        msg([309, 318, 327]).not.length_of(2, 3),
      expression { _[0] + index * 10 + original.length * 100 } =>
        msg(309).not.equal(209),
      expression { _[1] + index * 10 + original.length * 100 } =>
        msg(318).not.equal(218)
  end

  it "maps projection with block" do
    matcher = Matcher.build do
      map(_.sum(&:to_i), [1, 2, 3])
    end

    assert_no_errors matcher.match([%w[0 1], %w[1 1], %w[1 2]])
    assert_errors matcher.match([%w[0 1], %w[1 1], %w[1 3]]),
      2 => { expression { _.sum(&:to_i) } => msg(4).not.equal(3) }
  end

  it "passes index" do
    matcher = Matcher.build { map(_[:a] + i, [10, 21, 32]) }

    assert_errors matcher.match([{ a: 10 }, { a: 20 }, { a: 40 }]),
      expression { _[2][:a] + i } => msg(42).not.equal(32)
  end

  it "passes original" do
    matcher = Matcher.build do
      map(_[:a], [_ == original])
    end

    array = []
    array << { a: array }

    assert_no_errors matcher.match(array)
    assert_errors matcher.match([{ a: 1 }]),
      0 => { a: "expected actual == original but got 1 == #{[{ a: 1 }]}" }
  end

  it "#to_s" do
    matcher = Matcher.build { map(_.length, _.sum == 4) }

    assert_equal "map(actual.length, actual.sum == 4)", matcher.to_s
    assert_equal "~map(actual.length, actual.sum == 4)", matcher.~.to_s
  end
end
