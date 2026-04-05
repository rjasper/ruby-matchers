# frozen_string_literal: true

require "test_helper"

describe Matcher::ImplySomeMatcher do
  it "is built by imply_one" do
    matcher = Matcher.build do
      imply_one(
        of(String) >> "string",
        of(Integer) >> 1,
      )
    end

    assert_kind_of Matcher::ImplySomeMatcher, matcher
  end

  it "matches none" do
    matcher = Matcher.build do
      imply_one(
        of(String) >> "string",
        of(Integer) >> 1,
      )
    end

    negated = ~matcher

    refute matcher.match?(:a)
    assert_or_errors matcher.match(:a),
      msg(:a).not.kind_of(String),
      msg(:a).not.kind_of(Integer)
    assert negated.match?(:a)
    assert_no_errors negated.match(:a)
  end

  it "matches one" do
    matcher = Matcher.build do
      imply_one(
        of(String) >> "string",
        of(Integer) >> 1,
      )
    end

    negated = ~matcher

    assert matcher.match?("string")
    assert_no_errors matcher.match("string")
    refute negated.match?("string")
    assert_errors negated.match("string"),
      msg("string").equal("string")

    assert matcher.match?(1)
    assert_no_errors matcher.match(1)
    refute negated.match?(1)
    assert_errors negated.match(1),
      msg(1).equal(1)

    refute matcher.match?("text")
    assert_errors matcher.match("text"),
      msg("text").not.equal("string")
    assert negated.match?("text")
    assert_no_errors negated.match("text")

    refute matcher.match?(2)
    assert_errors matcher.match(2),
      msg(2).not.equal(1)
    assert negated.match?(2)
    assert_no_errors negated.match(2)
  end

  it "matches one: without matchers" do
    matcher = Matcher.build { imply_one }
    negated = ~matcher

    refute matcher.match?(1)
    assert negated.match?(1)

    matcher = Matcher.build { imply_one(else: 1) }
    negated = ~matcher

    assert matcher.match?(1)
    refute negated.match?(1)
    refute matcher.match?(2)
    assert negated.match?(2)
  end

  it "matches any" do
    matcher = Matcher.build do
      imply_any(
        partial(divisible_by: Integer) >>
          partial(value: _ % parent[:divisible_by] == 0),
        partial(odd: true) >> partial(value: _.odd?),
      )
    end

    negated = ~matcher

    assert matcher.match?({ divisible_by: 3, value: 6 })
    assert_no_errors matcher.match({ divisible_by: 3, value: 6 })
    refute negated.match?({ divisible_by: 3, value: 6 })
    assert_errors negated.match({ divisible_by: 3, value: 6 }),
      value: "expected actual % parent[:divisible_by] != 0 but got 0 != 0, " \
        "where actual = 6, parent = #{{ divisible_by: 3, value: 6 }}"

    refute matcher.match?({ divisible_by: 3, odd: true, value: 6 })
    assert_errors matcher.match({ divisible_by: 3, odd: true, value: 6 }),
      value: msg(6).not.predicate(:odd?)
    assert negated.match?({ divisible_by: 3, odd: true, value: 6 })
    assert_no_errors negated.match({ divisible_by: 3, odd: true, value: 6 })

    refute matcher.match?({ divisible_by: 3, odd: true, value: 5 })
    assert_errors matcher.match({ divisible_by: 3, odd: true, value: 5 }),
      value: "expected actual % parent[:divisible_by] == 0 but got 2 == 0, " \
        "where actual = 5, parent = #{{ divisible_by: 3, odd: true, value: 5 }}"
    assert negated.match?({ divisible_by: 3, odd: true, value: 5 })
    assert_no_errors negated.match({ divisible_by: 3, odd: true, value: 5 })

    refute matcher.match?({})
    assert_or_errors matcher.match({}),
      msg({}).not.having_key(:divisible_by),
      msg({}).not.having_key(:odd)
    assert negated.match?({})
    assert_no_errors negated.match({})
  end

  it "matches any: without matchers" do
    matcher = Matcher.build { imply_any }
    negated = ~matcher

    refute matcher.match?(1)
    assert negated.match?(1)

    matcher = Matcher.build { imply_any(else: 1) }
    negated = ~matcher

    assert matcher.match?(1)
    refute negated.match?(1)
    refute matcher.match?(2)
    assert negated.match?(2)
  end

  it "matches multiple" do
    matcher = Matcher.build do
      imply_one(
        partial(foo: true) >> partial(data: "foo"),
        partial(bar: true) >> partial(data: "bar"),
      )
    end

    negated = ~matcher

    refute matcher.match?({ foo: true, bar: true, data: "bar" })
    assert_or_errors matcher.match({ foo: true, bar: true, data: "bar" }),
      foo: msg(true).equal(true),
      bar: msg(true).equal(true)
    assert negated.match?({ foo: true, bar: true, data: "bar" })
    assert_no_errors negated.match({ foo: true, bar: true, data: "bar" })
  end

  it "matches with else" do
    matcher = Matcher.build do
      imply_one(
        of(String) >> "string",
        else: nil,
      )
    end

    negated = ~matcher

    assert matcher.match?("string")
    assert_no_errors matcher.match("string")
    refute negated.match?("string")
    assert_errors negated.match("string"),
      msg("string").equal("string")

    assert matcher.match?(nil)
    assert_no_errors matcher.match(nil)
    refute negated.match?(nil)
    assert_errors negated.match(nil),
      msg(nil).equal(nil)

    refute matcher.match?("foo")
    assert_errors matcher.match("foo"),
      msg("foo").not.equal("string")
    assert negated.match?("foo")
    assert_no_errors negated.match("foo")

    refute matcher.match?(1)
    assert_errors matcher.match(1),
      msg(1).not.equal(nil)
    assert negated.match?(1)
    assert_no_errors negated.match(1)
  end

  it "matches some" do
    matcher = Matcher.build do
      imply_some(
        partial(foo: true) >> partial(list: _.include?("foo")),
        partial(bar: true) >> partial(list: _.include?("bar")),
        partial(qux: true) >> partial(list: _.include?("qux")),
        count: 2,
      )
    end

    negated = ~matcher

    foo_bar = { foo: true, bar: true, list: %w[foo bar] }

    assert matcher.match?(foo_bar)
    assert_no_errors matcher.match(foo_bar)
    refute negated.match?(foo_bar)
    assert_errors negated.match(foo_bar) do
      _or(:list) do
        error msg(%w[foo bar]).including("foo")
        error msg(%w[foo bar]).including("bar")
      end
    end

    foo_bar_qux = { foo: true, bar: true, qux: true, list: %w[foo bar qux] }

    refute matcher.match?(foo_bar_qux)
    assert_or_errors matcher.match(foo_bar_qux),
      foo: msg(true).equal(true),
      bar: msg(true).equal(true),
      qux: msg(true).equal(true)
    assert negated.match?(foo_bar_qux)
    assert_no_errors negated.match(foo_bar_qux)
  end

  it "matches some with insufficient matchers" do
    matcher = Matcher.build do
      imply_some(
        of(Integer) >> (_ > 0),
        count: 2,
      )
    end

    negated = ~matcher

    refute matcher.match?(1)
    assert negated.match?(1)
  end

  it "#to_s" do
    assert_equal 'imply_one(imply(String, "string"), imply(Integer, 1))',
      Matcher.build { imply_one(of(String) >> "string", of(Integer) >> 1) }.to_s
    assert_equal 'imply_any(imply(String, "string"), imply(Integer, 1))',
      Matcher.build { imply_any(of(String) >> "string", of(Integer) >> 1) }.to_s
    assert_equal 'imply_one(imply(String, "string"), else: nil)',
      Matcher.build { imply_one(of(String) >> "string", else: nil) }.to_s

    expected =
      'imply_some(imply(String, "string"), imply(Integer, 1), count: 2)'
    matcher = Matcher.build do
      imply_some(of(String) >> "string", of(Integer) >> 1, count: 2)
    end

    assert_equal expected, matcher.to_s

    expected = '~imply_one(imply(String, "string"), imply(Integer, 1))'
    matcher = Matcher.build do
      ~imply_one(of(String) >> "string", of(Integer) >> 1)
    end

    assert_equal expected, matcher.to_s
  end
end
