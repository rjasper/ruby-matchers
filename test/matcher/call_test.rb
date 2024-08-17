# frozen_string_literal: true

require 'test_helper'

module Matcher
  class CallTest < ActiveSupport::TestCase
    # rubocop:disable Style/CaseEquality, Layout/SpaceBeforeBrackets, Style/SymbolProc
    test '#to_s' do
      examine = lambda do |expected, &block|
        assert_equal expected, Matcher::Call.build(&block).to_s
      end

      examine.call('actual') { _1 }
      examine.call('!actual') { !_1 }
      examine.call('~actual') { ~_1 }
      examine.call('+actual') { +_1 }
      examine.call('-actual') { -_1 }

      examine.call('actual + 2') { _1 + 2 }
      examine.call('actual - 2') { _1 - 2 }
      examine.call('actual * 2') { _1 * 2 }
      examine.call('actual / 2') { _1 / 2 }
      examine.call('actual % 2') { _1 % 2 }
      examine.call('actual < 2') { _1 < 2 }
      examine.call('actual > 2') { _1 > 2 }
      examine.call('actual <= 2') { _1 <= 2 }
      examine.call('actual >= 2') { _1 >= 2 }
      examine.call('actual <=> 2') { _1 <=> 2 }
      examine.call('actual == 2') { _1 == 2 }
      examine.call('actual === 2') { _1 === 2 }
      examine.call('actual != 2') { _1 != 2 }
      examine.call('actual =~ 2') { _1 =~ 2 }
      examine.call('actual !~ 2') { _1 !~ 2 }
      examine.call('actual & 2') { _1 & 2 }
      examine.call('actual | 2') { _1 | 2 }
      examine.call('actual ^ 2') { _1 ^ 2 }
      examine.call('actual << 2') { _1 << 2 }
      examine.call('actual >> 2') { _1 >> 2 }

      examine.call('actual**2') { _1**2 }

      examine.call('actual[1, 2, a: 3]') { _1[1, 2, a: 3] }
      examine.call('actual[1, 2, a: 3] { ... }') { _1[1, 2, a: 3] { 4 } }

      examine.call('actual[1] = 2') { _1.[]=(1, 2) }
      examine.call('actual[1, 2] = 3') { _1.[]=(1, 2, 3) }

      assert_equal 'actual.foo = "bar"',
        Call.new(Variable.new(:actual), :foo=, 'bar').to_s

      examine.call('actual.foo') { _1.foo }
      examine.call('actual.foo(1, a: 2)') { _1.foo(1, a: 2) }
      examine.call('actual.foo { ... }') { _1.foo { 2 } }
      examine.call('actual.foo(1, a: 2) { ... }') { _1.foo(1, a: 2) { 3 } }

      examine.call('actual.+@(1)') { _1.+@(1) }
      examine.call('actual.+@ { ... }') { _1.+@ { '' } }

      examine.call('actual.+') { _1.+ }
      examine.call('actual.+(1, 2)') { _1.+(1, 2) }
      examine.call('actual.+ { ... }') { _1.+ { 1 } }

      examine.call('actual.**') { _1.** }
      examine.call('actual.**(1, 2)') { _1.**(1, 2) }
      examine.call('actual.** { ... }') { _1.** { 1 } }

      examine.call('actual.[]=') { _1.[]= }
      examine.call('actual.[]=(1)') { _1.[]=(1) }
      examine.call('actual.[]=(1, 2, a: 3)') { _1.[]=(1, 2, a: 3) }
      examine.call('actual.[]=(1, 2) { ... }') { _1.[]=(1, 2) { 3 } }
      examine.call('actual.[]= { ... }') { _1.[]= { 1 } }

      # precedence and parentheses
      examine.call('(actual + 1) * 2') { |x| (x + 1) * 2 }
      examine.call('actual + 1') { |x| x + 1 }
      examine.call('actual + actual * 2') { |x| x + x * 2 }
      examine.call('actual * (actual + 2)') { |x| x * (x + 2) }
      examine.call('actual + actual - 1') { |x| x + x - 1 }
      examine.call('-(actual + 1)') { |x| -(x + 1) }
      examine.call('-actual + 1') { |x| -x + 1 }
      examine.call('(actual + [1])[0]') { |x| (x + [1])[0] }
      examine.call('(actual + 1).foo') { |x| (x + 1).foo }
      examine.call('actual[0] + [1]') { |x| x[0] + [1] }
    end
    # rubocop:enable Style/CaseEquality, Layout/SpaceBeforeBrackets, Style/SymbolProc

    test '#to_s: root' do
      expression = Matcher::Call.build { _1.bar + 1 }

      assert_equal 'foo.bar + 1', expression.to_s(substitutions: { actual: 'foo' })
    end

    test 'records class' do
      expression = Matcher::Call.build { _1.class } # rubocop:disable Style/SymbolProc

      assert_equal :class, expression.method
    end

    test 'records instance_exec' do
      klass = Class.new do
        def initialize
          @foo = 'foo'
        end
      end

      expression = Matcher::Call.build do |obj|
        obj.instance_exec { @foo }
      end

      assert_equal 'foo', expression.evaluate({ actual: klass.new })
    end
  end
end
