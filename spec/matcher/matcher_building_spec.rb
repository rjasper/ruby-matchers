# frozen_string_literal: true

require 'test_helper'

describe Matcher::MatcherBuilding do
  it '#of' do
    assert_kind_of(Matcher::Base, build { of(1) })
  end

  describe 'present' do
    it 'matches with given matcher if present' do
      matcher = build { present(1) }

      assert_no_errors matcher.match(1)
      assert_errors matcher.~.match(1) do
        _or do
          error 'expected value to be nil but got 1'
          error 'did not expect 1'
        end
      end
    end

    it 'complains when actual is nil' do
      got_it_from_somewhere = nil
      matcher = build { present(got_it_from_somewhere) }

      assert_errors matcher.match(nil),
        'did not expect value to be nil but got nil'
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
