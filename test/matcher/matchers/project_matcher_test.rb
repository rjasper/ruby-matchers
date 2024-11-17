# frozen_string_literal: true

require 'test_helper'

describe Matcher::ProjectMatcher do
  it 'is build by project' do
    matcher = Matcher.build { project(_.sum, 4) }

    assert_kind_of Matcher::ProjectMatcher, matcher
  end

  it 'expects no call errors' do
    matcher = Matcher.build { project(_.sum, 4) }

    assert_expected_errors matcher.match(nil),
      "expected an object responding to `sum' but got nil"
    assert_no_errors matcher.~.match(nil)
  end
  it 'matches projected object' do
    matcher = Matcher.build { project(_.sum, 4) }
    negated = ~matcher

    assert_no_errors matcher.match([2, 2])
    assert_expected_errors negated.match([2, 2]),
      expression { _.sum } => 'did not expect 4'

    assert_expected_errors matcher.match([2, 3]),
      expression { _.sum } => 'expected 4 but got 5'
    assert_no_errors negated.match([2, 3])
  end

  it '#to_s' do
    matcher = Matcher.build { project(_.my_method, 42) }

    assert_equal 'project(_.my_method, 42)', matcher.to_s
    assert_equal '~project(_.my_method, 42)', matcher.~.to_s
  end
end
