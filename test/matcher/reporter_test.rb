# frozen_string_literal: true

require 'test_helper'

describe Matcher::Reporter do
  it 'looks nice' do
    math = Matcher::Constant.new(Math)

    errors = _and(
      element('base wrong'),
      nested(:nested, element('nested wrong')),
      nested(:foo, nested(Matcher::Call.build(&:bar), element('foobar'))),
      nested(Matcher::Call.build { |_| _ + _ }, element('2 roots')),
      nested(:too_long,
        nested(Matcher::Call.build { |_| _ + _ + _ }, element('3 long roots'))),
      nested(Matcher::Call.build { |_| Matcher::ExpressionRecorder.new(math).sqrt(_) }, element('square root of root')),
      _or(
        element('either correct this'),
        _and(
          element('or all of this'),
          element('and this'),
        ),
        _or(
          nested(1, element('or1')),
          nested(2, element('or2')),
        ),
      ),
    )

    assert_equal <<~TEXT, Matcher::Reporter.new.report(errors)
      root: base wrong
      root[:nested]: nested wrong
      root[:foo].bar: foobar
      root + root: 2 roots
      root[:too_long] -> _ + _ + _: 3 long roots
      Math.sqrt(root): square root of root
      expected at least one error to be absent:
      - root: either correct this
      - root: or all of this
        root: and this
      - expected at least one error to be absent:
        - root[1]: or1
        - root[2]: or2
    TEXT
  end
end
