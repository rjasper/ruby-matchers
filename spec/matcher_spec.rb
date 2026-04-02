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
    assert_equal "1", Matcher.parenthesize(Matcher.of(1))
    assert_equal "(actual > 10)", Matcher.parenthesize(Matcher.build { _ > 10 })
    assert_equal "neg(actual > 10)", Matcher.parenthesize(~Matcher.build { _ > 10 })
    assert_equal({ foo: "bar" }.to_s, Matcher.parenthesize(Matcher.build { { foo: "bar" } }))
    assert_equal "any(String, Integer)", Matcher.parenthesize(Matcher.build { any(String, Integer) })
  end
end
