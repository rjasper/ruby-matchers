# frozen_string_literal: true

require 'test_helper'
require 'matcher/archive/old_error_checker'
require 'matcher/archive/error_labeler'

describe Matcher::OldErrorChecker do
  let(:error_checker) do
    Matcher::OldErrorChecker.new
  end

  it 'compare trees' do
    expected = build_errors do
      _or(:foo) do
        error(:bar, 'error1')
        error('error2')
      end
    end

    actual = build_errors do
      _or do
        error(:foo, 'error2')
        error(%i[foo bar], 'error1')
      end
    end

    assert_nil error_checker.check(expected, actual)
  end

  it 'hierarchie mismatch' do
    expected = build_errors do
      _and do
        error 'a'
        error 'b'
      end
    end

    actual = build_errors do
      _or do
        error 'a'
        error 'b'
      end
    end

    assert_equal <<~TEXT, error_checker.check(expected, actual)
      expected:

      root: a
      root: b

      but got:

      expected at least one error to be absent:
      - root: a
      - root: b
    TEXT
  end
end
