# frozen_string_literal: true

require 'test_helper'

describe Matcher::ProjectMatcher do
  it 'is build by project' do
    assert_kind_of Matcher::ProjectMatcher,
      (Matcher.build { project(_.sum => 4) })
    assert_kind_of Matcher::ProjectMatcher,
      (Matcher.build { project(_.sum) ^ 4 })
  end

  it 'expects no call errors' do
    matcher = Matcher.build { project(_.sum => 4) }

    assert_errors matcher.match(nil),
      msg(nil).not.responding_to(:sum)
    assert_no_errors matcher.~.match(nil)
  end

  it 'matches projected object' do
    matcher = Matcher.build { project(_.sum => 4) }
    negated = ~matcher

    assert_no_errors matcher.match([2, 2])
    assert_errors negated.match([2, 2]),
      expression { _.sum } => msg(4).equal(4)

    assert_errors matcher.match([2, 3]),
      expression { _.sum } => msg(5).not.equal(4)
    assert_no_errors negated.match([2, 3])
  end

  it 'matches multiple projections' do
    matcher = Matcher.build { project(_.sum => 10, _.min => 1, _.max => 5) }
    negated = ~matcher
    t = self

    assert_no_errors matcher.match([1, 4, 5])
    assert_errors negated.match([1, 4, 5]) do
      _or do
        error t.expression { _.sum }, msg(10).equal(10)
        error t.expression { _.min }, msg(1).equal(1)
        error t.expression { _.max }, msg(5).equal(5)
      end
    end

    assert_errors matcher.match([0, 4, 5]),
      expression { _.sum } => msg(9).not.equal(10),
      expression { _.min } => msg(0).not.equal(1)
    assert_no_errors negated.match([0, 4, 5])

    assert_errors matcher.match([1, 2, 3, 4]),
      expression { _.max } => msg(4).not.equal(5)
    assert_no_errors negated.match([1, 2, 3, 4])
  end

  it '#to_s' do
    matcher = Matcher.build { project(_.my_method => 42) }

    assert_equal 'project(_.my_method => 42)', matcher.to_s
    assert_equal '~project(_.my_method => 42)', matcher.~.to_s
  end
end
