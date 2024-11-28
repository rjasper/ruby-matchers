# frozen_string_literal: true

require 'test_helper'

describe Matcher::ExpressionRecorder do
  let(:recorder) { Matcher::ExpressionRecorder.new(Matcher::Variable.actual) }

  it '::recorder?' do
    assert Matcher::ExpressionRecorder.recorder?(recorder)
    refute Matcher::ExpressionRecorder.recorder?(42)
  end

  it '::to_expression' do
    assert_equal Matcher::Variable.actual,
      Matcher::ExpressionRecorder.to_expression(recorder)
  end

  it '::transform' do
    assert_equal Matcher::Variable.actual,
      Matcher::ExpressionRecorder.transform(recorder)
    assert_equal Matcher::Constant.new(1),
      Matcher::ExpressionRecorder.transform(1)
  end

  it 'works as Hash key' do
    hash = { recorder => 1 }

    assert_equal 1, hash[recorder]
  end

  it 'works as Set element' do
    set = Set[recorder]

    assert set.include?(recorder)
  end

  it 'records an expression' do
    exp = Matcher::ExpressionRecorder.to_expression(
      recorder.foo(1, bar: 2) { |x| x },
    )

    block = Matcher::Block.new([%i[opt x]], Matcher::Variable.new(:x), context: nil)
    call = Matcher::Call.new(
      Matcher::Variable.actual,
      :foo,
      [Matcher::Constant.new(1)],
      { bar: Matcher::Constant.new(2) },
      block,
    )

    assert_equal call, exp
  end
end
