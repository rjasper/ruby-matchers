# frozen_string_literal: true

require 'test_helper'

describe Matcher::Call do
  describe '#evaluate' do
    it 'evaluates basic call' do
      call = expression { _ + vars[:foo] }

      assert_equal 5, call.evaluate(actual: 2, foo: 3)
    end

    it 'evaluates kwargs' do
      call = expression { _.merge(foo: vars[:foo]) }

      assert_equal({ foo: 'foo' }, call.evaluate(actual: {}, foo: 'foo'))
    end

    it 'evaluates && and ||' do
      tru = Matcher::Constant.new(true)
      fals = Matcher::Constant.new(false)
      null = Matcher::Constant.new(nil)
      one = Matcher::Constant.new(1)

      assert_nil Matcher::Call.new(null, :'&&', [one]).evaluate({})
      assert_equal false, Matcher::Call.new(fals, :'&&', [one]).evaluate({})
      assert_equal 1, Matcher::Call.new(tru, :'&&', [one]).evaluate({})

      assert_equal 1, Matcher::Call.new(null, :'||', [one]).evaluate({})
      assert_equal true, Matcher::Call.new(fals, :'||', [tru]).evaluate({})
      assert_equal 1, Matcher::Call.new(one, :'||', [fals]).evaluate({})
    end

    it 'returns operand of assignment' do
      call = expression do
        assign { _.foo = 2 }
      end

      struct = Struct.new(:foo).new

      assert_equal 2, call.evaluate(actual: struct)
      assert_equal 2, struct.foo
    end

    it 'returns operand of index assignment' do
      call = expression do
        assign { _[:foo] = 2 }
      end

      struct = Struct.new(:foo).new

      assert_equal 2, call.evaluate(actual: struct)
      assert_equal 2, struct.foo
    end

    it 'raises CallError' do
      err = assert_raises Matcher::CallError do
        expression { _.foo }.evaluate(actual: nil)
      end

      assert_equal "_.foo raised NoMethodError: undefined method `foo' for nil", err.message

      err = assert_raises Matcher::CallError do
        expression { (_ - 1) / 0 }.evaluate(actual: 1)
      end

      assert_equal '(_ - 1) / 0 raised ZeroDivisionError: divided by 0', err.message
    end
  end

  describe '#evaluate_tree' do
    it 'evaluates basic call' do
      call = expression { _ + vars[:foo] }

      assert_equal [[2], [[3]], {}, 5], call.evaluate_tree(actual: 2, foo: 3)
    end

    it 'evaluates kwargs' do
      call = expression { _.merge(foo: vars[:foo]) }

      assert_equal [[{}], [], { :foo => ["foo"] }, { :foo => "foo" }],
        call.evaluate_tree(actual: {}, foo: 'foo')
    end

    it 'evaluates && and ||' do
      tru = Matcher::Constant.new(true)
      fals = Matcher::Constant.new(false)
      null = Matcher::Constant.new(nil)
      one = Matcher::Constant.new(1)

      assert_equal [[nil], nil, nil, nil],
        Matcher::Call.new(null, :'&&', [one]).evaluate_tree({})
      assert_equal [[false], nil, nil, false],
        Matcher::Call.new(fals, :'&&', [one]).evaluate_tree({})
      assert_equal [[true], [[1]], {}, 1],
        Matcher::Call.new(tru, :'&&', [one]).evaluate_tree({})

      assert_equal [[nil], [[1]], {}, 1],
        Matcher::Call.new(null, :'||', [one]).evaluate_tree({})
      assert_equal [[false], [[true]], {}, true],
        Matcher::Call.new(fals, :'||', [tru]).evaluate_tree({})
      assert_equal [[1], nil, nil, 1],
        Matcher::Call.new(one, :'||', [fals]).evaluate_tree({})
    end
  end

  it 'substitutes' do
    call = expression { vars[:a] * 100 + vars[:b] * 10 + _ }
    call = call.substitute(a: :actual, b: :c, actual: :d)

    assert_equal 123, call.evaluate(actual: 1, c: 2, d: 3)
    assert_equal %i[actual c d], call.variables
    assert_equal '_ * 100 + c * 10 + d', call.to_s
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
    examine['_[1, 2, a: 3, &:four]'] { _[1, 2, a: 3, &:four] }

    examine['_[1] = 2'] { _.[]=(1, 2) }
    examine['_[1, 2] = 3'] { _.[]=(1, 2, 3) }
    examine['_.foo = "bar"'] { assign { _.foo = 'bar' } }

    examine['_.foo'] { _.foo }
    examine['_.foo(1, a: 2)'] { _.foo(1, a: 2) }
    examine['_.foo { 2 }'] { _.foo { 2 } }
    examine['_.foo(&:bar)'] { _.foo(&:bar) }
    examine['_.foo(&:"42")'] { _.foo(&:'42') }
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

  it 'logical operators' do
    call = Matcher.with_settings(logical_operators: true) do
      expression do
        vars[:a] | vars[:b] & vars[:c]
      end
    end

    a = Matcher::Variable.new(:a)
    b = Matcher::Variable.new(:b)
    c = Matcher::Variable.new(:c)

    ampersand = Matcher::Call.new(b, :'&&', [c])
    chain = Matcher::Call.new(a, :'||', [ampersand])

    assert_equal chain, call
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
