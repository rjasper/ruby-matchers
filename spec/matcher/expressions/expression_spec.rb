# frozen_string_literal: true

require 'test_helper'

describe Matcher::Expression do
  let(:recorder) { Matcher::Recorder.new(Matcher::Variable.actual) }

  it '::of' do
    assert_equal Matcher::Variable.actual,
      Matcher::Expression.of(recorder)
    assert_equal Matcher::Constant.new(1),
      Matcher::Expression.of(1)
  end

  it '::try_recorder' do
    one = Matcher::Constant.new(1)

    assert_equal one, Matcher::Expression.try_recorder(one)
    assert_equal 1, Matcher::Expression.try_recorder(1)
  end
end
