# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

module Matcher
  class CaseEqualityMatcherTest < ActiveSupport::TestCase
    include Testing

    test '#matches case equality' do
      examine = -> { CaseEqualityMatcher.new(_1).match(_2).valid? }

      assert examine.call(String, 'asdf')
      assert_not examine.call(String, 1)
      assert examine.call(1..3, 2)
      assert_not examine.call(1..3, 4)
      assert examine.call(/f/, 'foo')
      assert_not examine.call(/f/, 'bar')
      assert examine.call(Set[1, 2], 1)
      assert_not examine.call(Set[1, 2], 3)
    end

    test 'generates error messages' do
      assert_errors match('hi') { Integer },
        'expected "hi" to be kind of Integer'
      assert_errors match('foo') { /bar/ },
        'expected "foo" to match /bar/'
      assert_errors CaseEqualityMatcher.new(Set[2, 3]).match(1),
        'expected 1 to be member of {2, 3}'
      assert_errors match(1) { 2..3 },
        'expected 1 to be within 2..3'
    end

    test '#inspect' do
      assert_equal 'Integer', CaseEqualityMatcher.new(Integer).inspect
    end
  end
end
