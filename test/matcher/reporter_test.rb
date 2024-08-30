# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

module Matcher
  class ReporterTest < ActiveSupport::TestCase
    include Testing

    test 'looks nice' do
      errors = _and(
        element('base wrong'),
        nested(:nested, element('nested wrong')),
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

      assert_equal <<~TEXT, Reporter.new.report(errors)
        root: base wrong
        root[:nested]: nested wrong
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
end
