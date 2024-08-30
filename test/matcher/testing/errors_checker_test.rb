# frozen_string_literal: true

require 'test_helper'

module Matcher
  module Testing
    class ErrorsCheckerTest < ActiveSupport::TestCase
      test 'compare trees' do
        expected = ErrorBuilder.build_node do
          _or(:foo) do
            error(:bar, 'error1')
            error('error2')
          end
        end

        actual = ErrorBuilder.build_node do
          _or do
            error(:foo, 'error2')
            error(%i[foo bar], 'error1')
          end
        end

        assert_nil ErrorsChecker.check(expected, actual)
      end

      test 'hierarchie mismatch' do
        expected = ErrorBuilder.build_node do
          _and do
            error 'a'
            error 'b'
          end
        end

        actual = ErrorBuilder.build_node do
          _or do
            error 'a'
            error 'b'
          end
        end

        assert_equal <<~TEXT, ErrorsChecker.check(expected, actual)
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
  end
end
