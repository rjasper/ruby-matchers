# frozen_string_literal: true

require 'test_helper'

describe Matcher::OneMatcher do
  it 'is built by one' do
    matcher = Matcher.build { one(String, Integer) }

    assert_kind_of Matcher::OneMatcher, matcher
  end

  it 'matches one' do
    matcher = Matcher.build { one(_.odd?, _ % 3 == 0) }
    negated = ~matcher

    assert_no_errors matcher.match(1)
    assert_errors negated.match(1),
      msg(1).predicate(:odd?)

    assert_no_errors matcher.match(6)
    assert_errors negated.match(6),
      'expected _ % 3 != 0 but got 0 != 0, where _ = 6'

    assert_errors matcher.match(2) do
      _or do
        error msg(2).not.predicate(:odd?)
        error 'expected _ % 3 == 0 but got 2 == 0, where _ = 2'
      end
    end

    assert_no_errors negated.match(2)
  end

  it '#to_s' do
    matcher = Matcher.build { one(String, Integer) }

    assert_equal 'one(String, Integer)', matcher.to_s
    assert_equal '~one(String, Integer)', matcher.~.to_s
  end
end
