# frozen_string_literal: true

require "test_helper"

describe Matcher::ParseJsonMatcher do
  let(:json_parse) do
    expression { expr(JSON).parse(_) }
  end

  it "is built by parse_json" do
    klass = Matcher::ParseJsonMatcher

    assert_kind_of(klass, Matcher.build { parse_json(Hash) })
    assert_kind_of(klass, Matcher.build { parse_json ^ Hash })
    assert_kind_of(klass, Matcher.build { json_format })
  end

  it "matches JSON" do
    matcher = Matcher.build { parse_json(Hash) }
    negated = ~matcher

    assert matcher.match?('{"a": 1}')
    assert_no_errors matcher.match('{"a": 1}')
    refute negated.match?('{"a": 1}')
    assert_errors negated.match('{"a": 1}'),
      json_parse => msg({ "a" => 1 }).kind_of(Hash)

    refute matcher.match?(nil)
    assert_errors matcher.match(nil),
      msg(nil).not.kind_of(String)
    assert negated.match?(nil)
    assert_no_errors negated.match(nil)

    refute matcher.match?("")
    assert_errors matcher.match(""),
      msg("").not.valid_format(:json)
    assert negated.match?("")
    assert_no_errors negated.match("")

    refute matcher.match?("1")
    assert_errors matcher.match("1"),
      json_parse => msg(1).not.kind_of(Hash)
    assert negated.match?("1")
    assert_no_errors negated.match("1")
  end

  it "validates JSON format" do
    matcher = Matcher.build { json_format }
    negated = ~matcher

    assert matcher.match?('{"a": 1}')
    assert_no_errors matcher.match('{"a": 1}')
    refute negated.match?('{"a": 1}')
    assert_errors negated.match('{"a": 1}'),
      msg('{"a": 1}').valid_format(:json)

    refute matcher.match?(nil)
    assert_errors matcher.match(nil),
      msg(nil).not.kind_of(String)
    assert negated.match?(nil)
    assert_no_errors negated.match(nil)

    refute matcher.match?("")
    assert_errors matcher.match(""),
      msg("").not.valid_format(:json)
    assert negated.match?("")
    assert_no_errors negated.match("")
  end

  it "passes options to JSON.parse" do
    matcher = Matcher.build do
      parse_json(symbolize_names: true) ^ { foo: "bar" }
    end

    refute matcher.match?('{"foo": "qux"}')
    assert_errors matcher.match('{"foo": "qux"}'),
      json_parse => { foo: msg("qux").not.equal("bar") }
  end

  it "#to_s" do
    assert_equal "parse_json(Hash)", Matcher.build { parse_json(Hash) }.to_s
    assert_equal "~parse_json(Hash)", Matcher.build { ~parse_json(Hash) }.to_s
    assert_equal "json_format", Matcher.build { json_format }.to_s
    assert_equal "~json_format", Matcher.build { ~json_format }.to_s
  end
end
