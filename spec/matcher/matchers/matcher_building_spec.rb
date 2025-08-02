# frozen_string_literal: true

require 'test_helper'

describe Matcher::MatcherBuilding do
  it '#of' do
    assert_kind_of(Matcher::Base, build { of(1) })
  end

  it '#neg' do
    inner_matcher = Class.new(Matcher::Base).new

    assert_kind_of Matcher::NegatedMatcher,
      (Matcher.build { neg(inner_matcher) })
    assert_kind_of Matcher::NegatedMatcher,
      (Matcher.build { neg ^ inner_matcher })
  end

  describe 'present' do
    it 'matches with given matcher if present' do
      matcher = build { present(1) }

      assert_no_errors matcher.match(1)
      assert_errors matcher.~.match(1) do
        _or do
          error msg(1).not.predicate(:nil?)
          error msg(1).equal(1)
        end
      end
    end

    it 'complains when actual is nil' do
      got_it_from_somewhere = nil
      matcher = build { present(got_it_from_somewhere) }

      assert_errors matcher.match(nil),
        msg(nil).predicate(:nil?)
      assert_no_errors matcher.~.match(1)
    end

    it 'is chainable' do
      matcher = build { present ^ { foo: 'bar' } }

      assert_no_errors matcher.match({ foo: 'bar' })
    end
  end

  private

  def build(&)
    Matcher.build(&)
  end
end
