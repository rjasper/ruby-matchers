# frozen_string_literal: true

require "test_helper"

describe Matcher::PatternCapture do
  it "#value_path" do
    mapping = Matcher::AstMapping.new
    capture = Matcher::PatternCapture.new

    capture.mapping = mapping.args[1].kwargs[:foo].receiver

    expected = [
      Matcher::AstMapping::ARGS,
      1,
      Matcher::AstMapping::KWARGS,
      :foo,
      Matcher::AstMapping::RECEIVER,
      -1,
    ]

    assert_equal expected, capture.value_path
  end
end
