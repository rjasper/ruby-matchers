# frozen_string_literal: true

require "test_helper"

describe Matcher::EachPairMatcher do
  it "is built by each_pair" do
    assert_kind_of(
      Matcher::EachPairMatcher,
      Matcher.build { each_pair(key == value.to_sym) },
    )

    assert_kind_of(
      Matcher::EachPairMatcher,
      Matcher.build { each_pair ^ (key == value.to_sym) },
    )
  end

  it "is built by each_key" do
    assert_kind_of(
      Matcher::EachPairMatcher,
      Matcher.build { each_key(Symbol) },
    )

    assert_kind_of(
      Matcher::EachPairMatcher,
      Matcher.build { each_key ^ Symbol },
    )
  end

  it "is built by each_value" do
    assert_kind_of(
      Matcher::EachPairMatcher,
      Matcher.build { each_value(String) },
    )

    assert_kind_of(
      Matcher::EachPairMatcher,
      Matcher.build { each_value ^ String },
    )
  end

  it "expects an object responding to :each_pair" do
    matcher = Matcher.build do
      each_pair([:key, "value"])
    end

    refute matcher.match?(nil)
    assert_errors matcher.match(nil),
      msg(nil).not.responding_to(:each_pair)
    assert matcher.~.match?(nil)
    assert_no_errors matcher.~.match(nil)
  end

  it "matches each pair" do
    matcher = Matcher.build do
      each_pair(key == value.to_s)
    end

    negated = ~matcher

    assert matcher.match?({ "1" => 1, "a" => :a })
    assert_no_errors matcher.match({ "1" => 1, "a" => :a })
    refute negated.match?({ "1" => 1, "a" => :a })
    assert_errors negated.match({ "1" => 1, "a" => :a }) do
      _or do
        error "1",
          'expected key != value.to_s but got "1" != "1", where value = 1'
        error "a",
          'expected key != value.to_s but got "a" != "a", where value = :a'
      end
    end

    refute matcher.match?({ "1" => 1, "a" => :a, 0 => "0" })
    assert_errors matcher.match({ "1" => 1, "a" => :a, 0 => "0" }),
      0 => 'expected key == value.to_s but got 0 == "0", where value = "0"'
    assert negated.match?({ "1" => 1, "a" => :a, 0 => "0" })
    assert_no_errors negated.match({ "1" => 1, "a" => :a, 0 => "0" })
  end

  it "matches each key" do
    matcher = Matcher.build { each_key(Symbol) }

    assert matcher.match?({ foo: 1, bar: 2 })
    assert_no_errors matcher.match({ foo: 1, bar: 2 })

    refute matcher.match?({ foo: 1, "bar" => 2 })
    assert_errors matcher.match({ foo: 1, "bar" => 2 }),
      "bar" => { expression { key } => msg("bar").not.kind_of(Symbol) }
  end

  it "matches each value" do
    matcher = Matcher.build { each_value(Integer) }

    assert matcher.match?({ foo: 1, bar: 2 })
    assert_no_errors matcher.match({ foo: 1, bar: 2 })

    refute matcher.match?({ foo: 1, bar: "2" })
    assert_errors matcher.match({ foo: 1, bar: "2" }),
      bar: msg("2").not.kind_of(Integer)
  end

  it "#to_s" do
    matcher = Matcher.build { each_pair({ "a" => 1 }) }

    assert_equal "each_pair(#{{ "a" => 1 }})", matcher.to_s
    assert_equal "~each_pair(#{{ "a" => 1 }})", matcher.~.to_s
  end
end
