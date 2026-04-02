# frozen_string_literal: true

require "test_helper"

describe Matcher::PatternMatch do
  let(:match) do
    Matcher::PatternMatch.new
  end

  let(:exp) do
    expression { _ + 1 }
  end

  let(:mapping) do
    Matcher::AstMapping.new.receiver.args[0]
  end

  it "#[]" do
    match.capture(:foo, exp, mapping)

    capture = match[:foo]

    assert_kind_of Matcher::PatternCapture, capture
    assert_equal exp, capture.expression
    assert_equal mapping, capture.mapping
  end

  it "#include?" do
    refute match.include?(:foo)

    match.capture(:foo, exp, mapping)

    assert match.include?(:foo)
  end

  it "#value_paths" do
    match.capture(:foo, exp, mapping)

    expected = [
      Matcher::AstMapping::RECEIVER,
      Matcher::AstMapping::ARGS,
      0,
      -1,
    ]

    assert_equal({ foo: expected }, match.value_paths)
  end

  it "#expression" do
    match.capture(:foo, exp, mapping)

    assert_equal({ foo: exp }, match.expressions)
  end
end
