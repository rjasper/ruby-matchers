# frozen_string_literal: true

require 'test_helper'

Call = Matcher::Call
Variable = Matcher::Variable

describe Matcher::Call do
  # rubocop:disable Style/CaseEquality, Layout/SpaceBeforeBrackets, Style/SymbolProc
  it '#to_s' do
    examine = lambda do |expected, &block|
      assert_equal expected, Call.build(&block).to_s
    end

    examine.call('_') { _1 }
    examine.call('!_') { !_1 }
    examine.call('~_') { ~_1 }
    examine.call('+_') { +_1 }
    examine.call('-_') { -_1 }

    examine.call('_ + 2') { _1 + 2 }
    examine.call('_ - 2') { _1 - 2 }
    examine.call('_ * 2') { _1 * 2 }
    examine.call('_ / 2') { _1 / 2 }
    examine.call('_ % 2') { _1 % 2 }
    examine.call('_ < 2') { _1 < 2 }
    examine.call('_ > 2') { _1 > 2 }
    examine.call('_ <= 2') { _1 <= 2 }
    examine.call('_ >= 2') { _1 >= 2 }
    examine.call('_ <=> 2') { _1 <=> 2 }
    examine.call('_ == 2') { _1 == 2 }
    examine.call('_ === 2') { _1 === 2 }
    examine.call('_ != 2') { _1 != 2 }
    examine.call('_ =~ 2') { _1 =~ 2 }
    examine.call('_ !~ 2') { _1 !~ 2 }
    examine.call('_ & 2') { _1 & 2 }
    examine.call('_ | 2') { _1 | 2 }
    examine.call('_ ^ 2') { _1 ^ 2 }
    examine.call('_ << 2') { _1 << 2 }
    examine.call('_ >> 2') { _1 >> 2 }

    Matcher.with_settings(logical_operators: true) do
      examine.call('_ && 2') { _1 & 2 }
      examine.call('_ || 2') { _1 | 2 }
    end

    examine.call('_**2') { _1**2 }

    examine.call('_[1, 2, a: 3]') { _1[1, 2, a: 3] }
    examine.call('_[1, 2, a: 3] { ... }') { _1[1, 2, a: 3] { 4 } }

    examine.call('_[1] = 2') { _1.[]=(1, 2) }
    examine.call('_[1, 2] = 3') { _1.[]=(1, 2, 3) }

    assert_equal '_.foo = "bar"',
      Call.new(Variable.actual, :foo=, ['bar']).to_s

    examine.call('_.foo') { _1.foo }
    examine.call('_.foo(1, a: 2)') { _1.foo(1, a: 2) }
    examine.call('_.foo { 2 }') { _1.foo { 2 } }
    examine.call('_.foo(1, a: 2) { 3 }') { _1.foo(1, a: 2) { 3 } }

    examine.call('_.+@(1)') { _1.+@(1) }
    examine.call('_.+@ { "" }') { _1.+@ { '' } }

    examine.call('_.+') { _1.+ }
    examine.call('_.+(1, 2)') { _1.+(1, 2) }
    examine.call('_.+ { 1 }') { _1.+ { 1 } }

    examine.call('_.**') { _1.** }
    examine.call('_.**(1, 2)') { _1.**(1, 2) }
    examine.call('_.** { 1 }') { _1.** { 1 } }

    examine.call('_.[]=') { _1.[]= }
    examine.call('_.[]=(1)') { _1.[]=(1) }
    examine.call('_.[]=(1, 2, a: 3)') { _1.[]=(1, 2, a: 3) }
    examine.call('_.[]=(1, 2) { 3 }') { _1.[]=(1, 2) { 3 } }
    examine.call('_.[]= { 1 }') { _1.[]= { 1 } }

    # precedence and parentheses
    examine.call('(_ + 1) * 2') { |x| (x + 1) * 2 }
    examine.call('_ + 1') { |x| x + 1 }
    examine.call('_ + _ * 2') { |x| x + x * 2 }
    examine.call('_ * (_ + 2)') { |x| x * (x + 2) }
    examine.call('_ + _ - 1') { |x| x + x - 1 }
    examine.call('-(_ + 1)') { |x| -(x + 1) }
    examine.call('-_ + 1') { |x| -x + 1 }
    examine.call('(_ + [1])[0]') { |x| (x + [1])[0] }
    examine.call('(_ + 1).foo') { |x| (x + 1).foo }
    examine.call('_[0] + [1]') { |x| x[0] + [1] }
  end
  # rubocop:enable Style/CaseEquality, Layout/SpaceBeforeBrackets, Style/SymbolProc

  it 'negated' do
    examine = lambda do |expected, &block|
      assert_equal expected, Call.build(&block).negated.to_s
    end

    examine.call('!_') { _1 }
    examine.call('_') { !_1 }
    examine.call('_ != 2') { _1 == 2 }
    examine.call('_ == 2') { _1 != 2 }
    examine.call('_ !~ 2') { _1 =~ 2 }
    examine.call('_ =~ 2') { _1 !~ 2 }
    examine.call('_ >= 2') { _1 < 2 }
    examine.call('_ <= 2') { _1 > 2 }
    examine.call('_ > 2') { _1 <= 2 }
    examine.call('_ < 2') { _1 >= 2 }

    Matcher.with_settings(logical_operators: true) do
      examine.call('!_ || false') { _1 & 2 }
      examine.call('!_ && false') { _1 | 2 }
    end
  end

  it 'logical operators' do
    call = Matcher.with_settings(logical_operators: true) do
      Call.build(:a, :b, :c) do |a, b, c|
        a | b & c
      end
    end

    a = Variable.new(:a)
    b = Variable.new(:b)
    c = Variable.new(:c)

    assert_equal Call.new(a, :'||', [Call.new(b, :'&&', [c])]), call
  end

  it '#to_s: root' do
    expression = Call.build { _1.bar + 1 }

    assert_equal 'foo.bar + 1', expression.to_s(substitutions: { actual: 'foo' })
  end

  it 'records class' do
    expression = Call.build { _1.class } # rubocop:disable Style/SymbolProc

    assert_equal :class, expression.method
  end

  it 'records instance_exec' do
    klass = Class.new do
      def initialize
        @foo = 'foo'
      end
    end

    expression = Call.build do |obj|
      obj.instance_exec { @foo }
    end

    assert_equal 'foo', expression.evaluate({ actual: klass.new })
  end
end
