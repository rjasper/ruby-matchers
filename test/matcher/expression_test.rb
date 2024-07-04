# frozen_string_literal: true

require 'test_helper'

module Matcher
  class ExpressionTest < ActiveSupport::TestCase
    # rubocop:disable Style/CaseEquality, Layout/SpaceBeforeBrackets, Style/SymbolProc
    test '#to_s' do
      examine = lambda do |expected, &block|
        assert_equal expected, expr(&block).to_s
      end

      examine.call('value') { _1 }
      examine.call('!value') { !_1 }
      examine.call('~value') { ~_1 }
      examine.call('+value') { +_1 }
      examine.call('-value') { -_1 }

      examine.call('(value + 2)') { _1 + 2 }
      examine.call('(value - 2)') { _1 - 2 }
      examine.call('(value * 2)') { _1 * 2 }
      examine.call('(value / 2)') { _1 / 2 }
      examine.call('(value % 2)') { _1 % 2 }
      examine.call('(value < 2)') { _1 < 2 }
      examine.call('(value > 2)') { _1 > 2 }
      examine.call('(value <= 2)') { _1 <= 2 }
      examine.call('(value >= 2)') { _1 >= 2 }
      examine.call('(value <=> 2)') { _1 <=> 2 }
      examine.call('(value == 2)') { _1 == 2 }
      examine.call('(value === 2)') { _1 === 2 }
      examine.call('(value != 2)') { _1 != 2 }
      examine.call('(value =~ 2)') { _1 =~ 2 }
      examine.call('(value !~ 2)') { _1 !~ 2 }
      examine.call('(value & 2)') { _1 & 2 }
      examine.call('(value | 2)') { _1 | 2 }
      examine.call('(value ^ 2)') { _1 ^ 2 }
      examine.call('(value << 2)') { _1 << 2 }
      examine.call('(value >> 2)') { _1 >> 2 }

      examine.call('(value**2)') { _1**2 }

      examine.call('value[1, 2, a: 3]') { _1[1, 2, a: 3] }
      examine.call('value[1, 2, a: 3] { ... }') { _1[1, 2, a: 3] { 4 } }

      examine.call('(value[1] = 2)') { _1.[]=(1, 2) }
      examine.call('(value[1, 2] = 3)') { _1.[]=(1, 2, 3) }

      assert_equal '(value.foo = "bar")',
        Expression.new(Expression.new, :foo=, 'bar').to_s

      examine.call('value.foo') { _1.foo }
      examine.call('value.foo(1, a: 2)') { _1.foo(1, a: 2) }
      examine.call('value.foo { ... }') { _1.foo { 2 } }
      examine.call('value.foo(1, a: 2) { ... }') { _1.foo(1, a: 2) { 3 } }

      examine.call('value.+@(1)') { _1.+@(1) }
      examine.call('value.+@ { ... }') { _1.+@ { '' } }

      examine.call('value.+') { _1.+ }
      examine.call('value.+(1, 2)') { _1.+(1, 2) }
      examine.call('value.+ { ... }') { _1.+ { 1 } }

      examine.call('value.**') { _1.** }
      examine.call('value.**(1, 2)') { _1.**(1, 2) }
      examine.call('value.** { ... }') { _1.** { 1 } }

      examine.call('value.[]=') { _1.[]= }
      examine.call('value.[]=(1)') { _1.[]=(1) }
      examine.call('value.[]=(1, 2, a: 3)') { _1.[]=(1, 2, a: 3) }
      examine.call('value.[]=(1, 2) { ... }') { _1.[]=(1, 2) { 3 } }
      examine.call('value.[]= { ... }') { _1.[]= { 1 } }
    end
    # rubocop:enable Style/CaseEquality, Layout/SpaceBeforeBrackets, Style/SymbolProc

    private

    def expr
      recorder = yield ExpressionRecorder.new

      ExpressionRecorder.to_expression(recorder)
    end
  end
end
