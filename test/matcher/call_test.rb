# frozen_string_literal: true

require 'test_helper'

Call = Matcher::Call
Variable = Matcher::Variable

describe Matcher::Call do
  it 'returns operand of assignment' do
    call = expression do
      assign { _.foo = 2 }
    end

    struct = Struct.new(:foo).new

    assert_equal 2, call.evaluate({ actual: struct })
    assert_equal 2, struct.foo
  end

  # rubocop:disable Style/CaseEquality, Layout/SpaceBeforeBrackets
  it '#to_s' do
    examine = lambda do |expected, &block|
      assert_equal expected, expression(&block).to_s
    end

    examine['_'] { _ }
    examine['!_'] { !_ }
    examine['~_'] { ~_ }
    examine['+_'] { +_ }
    examine['-_'] { -_ }

    examine['_ + 2'] { _ + 2 }
    examine['_ - 2'] { _ - 2 }
    examine['_ * 2'] { _ * 2 }
    examine['_ / 2'] { _ / 2 }
    examine['_ % 2'] { _ % 2 }
    examine['_ < 2'] { _ < 2 }
    examine['_ > 2'] { _ > 2 }
    examine['_ <= 2'] { _ <= 2 }
    examine['_ >= 2'] { _ >= 2 }
    examine['_ <=> 2'] { _ <=> 2 }
    examine['_ == 2'] { _ == 2 }
    examine['_ === 2'] { _ === 2 }
    examine['_ != 2'] { _ != 2 }
    examine['_ =~ 2'] { _ =~ 2 }
    examine['_ !~ 2'] { _ !~ 2 }
    examine['_ & 2'] { _ & 2 }
    examine['_ | 2'] { _ | 2 }
    examine['_ ^ 2'] { _ ^ 2 }
    examine['_ << 2'] { _ << 2 }
    examine['_ >> 2'] { _ >> 2 }

    examine['_ && 2'] { logical_operators { _ & 2 } }
    examine['_ || 2'] { logical_operators { _ | 2 } }

    examine['_**2'] { _**2 }

    examine['_[1, 2, a: 3]'] { _[1, 2, a: 3] }
    examine['_[1, 2, a: 3] { |x| x * 4 }'] { _[1, 2, a: 3] { |x| x * 4 } }

    examine['_[1] = 2'] { _.[]=(1, 2) }
    examine['_[1, 2] = 3'] { _.[]=(1, 2, 3) }
    examine['_.foo = "bar"'] { assign { _.foo = 'bar' } }

    examine['_.foo'] { _.foo }
    examine['_.foo(1, a: 2)'] { _.foo(1, a: 2) }
    examine['_.foo { 2 }'] { _.foo { 2 } }
    examine['_.foo(&:bar)'] { _.foo(&:bar) }
    examine['_.foo(1, a: 2) { 3 }'] { _.foo(1, a: 2) { 3 } }

    examine['_.+@(1)'] { _.+@(1) }
    examine['_.+@ { "" }'] { _.+@ { '' } }

    examine['_.+'] { _.+ }
    examine['_.+(1, 2)'] { _.+(1, 2) }
    examine['_.+ { 1 }'] { _.+ { 1 } }

    examine['_.**'] { _.** }
    examine['_.**(1, 2)'] { _.**(1, 2) }
    examine['_.** { 1 }'] { _.** { 1 } }

    examine['_.[]='] { _.[]= }
    examine['_.[]=(1)'] { _.[]=(1) }
    examine['_.[]=(1, 2, a: 3)'] { _.[]=(1, 2, a: 3) }
    examine['_.[]=(1, 2) { 3 }'] { _.[]=(1, 2) { 3 } }
    examine['_.[]= { 1 }'] { _.[]= { 1 } }

    # precedence and parentheses
    examine['(_ + 1) * 2'] { (_ + 1) * 2 }
    examine['_ + 1'] { _ + 1 }
    examine['_ + _ * 2'] { _ + _ * 2 }
    examine['_ * (_ + 2)'] { _ * (_ + 2) }
    examine['_ + _ - 1'] { _ + _ - 1 }
    examine['-(_ + 1)'] { -(_ + 1) }
    examine['-_ + 1'] { -_ + 1 }
    examine['(_ + [1])[0]'] { (_ + [1])[0] }
    examine['(_ + 1).foo'] { (_ + 1).foo }
    examine['_[0] + [1]'] { _[0] + [1] }
    examine['_ - _ - _'] { _ - _ - _ }
    examine['_ - (_ - _)'] { _ - (_ - _) }
    examine['(_ == _) == _'] { (_ == _) == _ }
    examine['_ == (_ == _)'] { _ == (_ == _) }
  end
  # rubocop:enable Style/CaseEquality, Layout/SpaceBeforeBrackets

  it 'negated' do
    examine = lambda do |expected, &block|
      assert_equal expected, expression(&block).negated.to_s
    end

    examine['!_'] { _ }
    examine['_'] { !_ }
    examine['_ != 2'] { _ == 2 }
    examine['_ == 2'] { _ != 2 }
    examine['_ !~ 2'] { _ =~ 2 }
    examine['_ =~ 2'] { _ !~ 2 }
    examine['_ >= 2'] { _ < 2 }
    examine['_ <= 2'] { _ > 2 }
    examine['_ > 2'] { _ <= 2 }
    examine['_ < 2'] { _ >= 2 }

    Matcher.with_settings(logical_operators: true) do
      examine['!_ || false'] { _ & 2 }
      examine['!_ && false'] { _ | 2 }
    end
  end

  it 'logical operators' do
    call = Matcher.with_settings(logical_operators: true) do
      expression do
        vars[:a] | vars[:b] & vars[:c]
      end
    end

    a = Variable.new(:a)
    b = Variable.new(:b)
    c = Variable.new(:c)

    assert_equal Call.new(a, :'||', [Call.new(b, :'&&', [c])]), call
  end

  it '#to_s: root' do
    exp = expression { _.bar + 1 }

    assert_equal 'foo.bar + 1', exp.to_s(substitutions: { actual: 'foo' })
  end

  it 'records class' do
    assert_equal :class, expression { _.class }.method
  end

  it 'records instance_exec' do
    klass = Class.new do
      def initialize
        @foo = 'foo'
      end
    end

    exp = expression do
      pass_through_blocks { _.instance_exec { @foo } }
    end

    assert_equal 'foo', exp.evaluate({ actual: klass.new })
  end
end
