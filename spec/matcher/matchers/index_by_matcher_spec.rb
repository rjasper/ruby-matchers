# frozen_string_literal: true

require "test_helper"

describe Matcher::IndexByMatcher do
  it "is built by index_by" do
    assert_kind_of(
      Matcher::IndexByMatcher,
      Matcher.build { index_by(_[:id], always) },
    )

    assert_kind_of(
      Matcher::IndexByMatcher,
      Matcher.build { index_by(_[:id]) ^ always },
    )
  end

  it "expects an object responding to :each" do
    matcher = Matcher.build { index_by(_[:id], always) }

    refute matcher.match?(nil)
    assert_errors matcher.match(nil),
      msg(nil).not.responding_to(:each)
    assert matcher.~.match?(nil)
    assert_no_errors matcher.~.match(nil)
  end

  it "rescues from call errors" do
    matcher = Matcher.build { index_by(_[:id], always) }

    refute matcher.match?([nil])
    assert_errors matcher.match([nil]),
      0 => msg(nil).not.responding_to(:[])
    assert matcher.~.match?([nil])
    assert_no_errors matcher.~.match([nil])
  end

  it "matches indexed array with matcher and maps errors" do
    matcher = Matcher.build do
      index_by(_[:id]) ^ {
        41 => { id: 41, name: "foo" },
        42 => { id: 42, name: "bar" },
      }
    end

    negated = ~matcher

    actual1 = [{ id: 41, name: "foo" }, { id: 42, name: "bar" }]

    assert matcher.match?(actual1)
    assert_no_errors matcher.match([
      { id: 41, name: "foo" },
      { id: 42, name: "bar" },
    ])
    refute negated.match?(actual1)
    assert_or_errors negated.match(actual1),
      0 => {
        id: msg(41).equal(41),
        name: msg("foo").equal("foo"),
      },
      1 => {
        id: msg(42).equal(42),
        name: msg("bar").equal("bar"),
      }

    actual2 = [{ id: 41, name: "foo" }, { id: 42, name: "baz" }]

    refute matcher.match?(actual2)
    assert_errors matcher.match(actual2),
      1 => { name: msg("baz").not.equal("bar") }
    assert negated.match?(actual2)
    assert_no_errors negated.match([
      { id: 41, name: "foo" },
      { id: 42, name: "baz" },
    ])
  end

  it "detects duplicate keys" do
    matcher = Matcher.build do
      index_by(_[:id]) ^ {
        41 => { id: 41, name: "foo" },
        42 => { id: 42, name: "bar" },
      }
    end

    negated = ~matcher
    get_id = expression { _[:id] }
    actual = [
      { id: 41, name: "foo" },
      { id: 42, name: "bar" },
      { id: 41, name: "qux" },
    ]

    refute matcher.match?(actual)
    assert_errors matcher.match(actual),
      2 => msg({ id: 41, name: "qux" }).duplicate_by(get_id, 41, 0)
    assert negated.match?(actual)
    assert_no_errors negated.match(actual)
  end

  it "maps base errors" do
    subset = {
      41 => { id: 41, name: "foo" },
      42 => { id: 42, name: "bar" },
    }

    superset = {
      41 => { id: 41, name: "foo" },
      42 => { id: 42, name: "bar" },
      43 => { id: 43, name: "qux" },
    }

    matcher = Matcher.build { index_by(_[:id]) ^ (_ > subset) }
    negated = ~matcher

    to_h = expression { _.to_h { |e| [e[:id], e] } }

    assert_no_errors matcher.match(superset.values)
    assert_or_errors negated.match(superset.values),
      to_h => "did not expect a value > #{subset} but got #{superset}"

    assert_errors matcher.match(subset.values),
      to_h => "expected a value > #{subset} but got #{subset}"
    assert_no_errors negated.match(subset.values)
  end

  it "passes index to projection" do
    matcher = Matcher.build do
      index_by(_[:id] + index) ^ {
        10 => { id: 10, name: "foo" },
        21 => { id: 20, name: "bar" },
      }
    end

    assert_no_errors matcher.match([
      { id: 10, name: "foo" },
      { id: 20, name: "bar" },
    ])
  end

  it "passes original to projection" do
    matcher = Matcher.build do
      index_by(_[:id] + original.size) ^ {
        12 => { id: 10, name: "foo" },
        22 => { id: 20, name: "bar" },
      }
    end

    assert_no_errors matcher.match([
      { id: 10, name: "foo" },
      { id: 20, name: "bar" },
    ])
  end

  it "passes original to matcher" do
    matcher = Matcher.build do
      index_by(_[:id]) ^ all(
        original.is_a?(Array),
        original.length == 2,
      )
    end

    assert_no_errors matcher.match([
      { id: 1, name: "foo" },
      { id: 2, name: "bar" },
    ])
  end

  it "#to_s" do
    assert_equal "index_by(actual[:id], always)",
      Matcher.build { index_by(_[:id], always) }.to_s
    assert_equal "~index_by(actual[:id], always)",
      Matcher.build { ~index_by(_[:id], always) }.to_s
  end
end
