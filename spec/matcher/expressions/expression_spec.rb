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

  it '#given_for' do
    expr = expression { vars[:foo] + vars[:bar] }

    assert_equal(
      { foo: 1, bar: 2 },
      expr.given_for(foo: 1, bar: 2, qux: 3),
    )
  end

  it '#free_symbol' do
    expr = expression do
      vars[:foo].map { |bar| bar * 2 }
    end

    assert_equal :foo2, expr.free_symbol(:foo)
    assert_equal :bar2, expr.free_symbol(:bar)
    assert_equal :qux, expr.free_symbol(:qux)
  end
end
