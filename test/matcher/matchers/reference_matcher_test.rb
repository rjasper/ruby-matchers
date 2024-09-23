# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

describe Matcher::ReferenceMatcher do
  it 'linked list' do
    matcher = Matcher.build do
      refs[:list] = {
        head: Integer,
        tail: any(nil, refs[:list]),
      }
    end

    list = { head: 1, tail: { head: 2, tail: { head: 3 } } }

    assert_errors matcher.match(list) do
      _or(:tail) do
        error 'expected nil but got {:head=>2, :tail=>{:head=>3}}'
        _or(:tail) do
          error 'expected nil but got {:head=>3}'
          error :tail, 'expected entry for :tail but found nothing'
        end
      end
    end
  end

  it 'negated ref' do
    matcher = Matcher.build do
      refs[:foo] = 42

      ~refs[:foo]
    end

    assert_predicate matcher.match(25), :valid?
    assert_errors matcher.match(42), 'expected 42 to not be 42'
  end
end
