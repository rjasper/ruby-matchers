# frozen_string_literal: true

require 'test_helper'

describe Matcher::Reporter do
  it 'looks nice' do
    t = self

    errors = build_errors do
      error 'base wrong'
      error :nested, 'nested wrong'
      error t.expression { _[:foo].bar }, 'foobar'
      error t.expression { _ + _ }, '2 roots'
      error [:too_long, t.expression { _ + _ + _ }], '3 long roots'
      error t.expression { expr(Math).sqrt(_) }, 'square root of root'

      _or do
        error 'either correct this'

        _and do
          error 'or all of this'
          error 'and this'

          _or do
            error 1, 'or1'
            error 2, 'or2'
          end
        end
      end
    end

    assert_equal <<~TEXT, Matcher::Reporter.new.report(errors)
      root: base wrong
      root[:nested]: nested wrong
      root[:foo].bar: foobar
      root + root: 2 roots
      root[:too_long] -> actual + actual + actual: 3 long roots
      Math.sqrt(root): square root of root
      expected at least one error to be absent:
      - root: either correct this
      - root: or all of this
        root: and this
        expected at least one error to be absent:
        - root[1]: or1
        - root[2]: or2
    TEXT
  end
end
