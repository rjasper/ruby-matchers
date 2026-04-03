# frozen_string_literal: true

require "test_helper"

describe Matcher do
  it "assert_structure" do
    assert_structure({ foo: 42 }) do
      { foo: 42 }
    end

    assert_raises(Minitest::Assertion) do
      assert_structure({ bar: 1 }) do
        { bar: _.even? }
      end
    end
  end

  it "checks unused refs" do
    assert_raises StandardError, match: "unused ref: foo" do
      Matcher.build do
        refs[:foo] = "foo"
        1
      end
    end
  end

  it "checks undefined refs" do
    assert_raises StandardError, match: "undefined ref: foo" do
      Matcher.build { refs[:foo] }
    end
  end

  it "::parenthesize" do
    examine = lambda do |expected, block|
      matcher = Matcher.build(&block)

      assert_equal expected, Matcher.parenthesize(matcher)
    end

    examine["1", -> { 1 }]
    examine["(actual > 10)", -> { _ > 10 }]
    examine["neg(actual > 10)", -> { neg(_ > 10) }]
    examine["any(String, Integer)", -> { any(String, Integer) }]
    examine[{ foo: "bar" }.to_s, -> { { foo: "bar" } }]
  end
end
