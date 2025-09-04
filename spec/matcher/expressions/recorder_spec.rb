# frozen_string_literal: true

require 'test_helper'

describe Matcher::Recorder do
  let(:recorder) { Matcher::Recorder.new(Matcher::Variable.actual) }

  it '::recorder?' do
    assert Matcher::Recorder.recorder?(recorder)
    refute Matcher::Recorder.recorder?(42)
  end

  it '::to_expression' do
    assert_equal Matcher::Variable.actual,
      Matcher::Recorder.to_expression(recorder)
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
    exp = Matcher::Recorder.to_expression(
      recorder.foo(1, bar: 2) { |x| x },
    )

    block = Matcher::Block.new([%i[opt x]], Matcher::Variable.new(:x))
    call = Matcher::Call.new(
      Matcher::Variable.actual,
      :foo,
      [Matcher::Constant.new(1)],
      { bar: Matcher::Constant.new(2) },
      block,
    )

    assert_equal call, exp
  end

  it 'records object_id call' do
    call = Matcher::Expression.build { _.object_id }

    assert_kind_of Matcher::Call, call
    assert_equal :object_id, call.method
  end
end
