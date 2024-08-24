# frozen_string_literal: true

require 'test_helper'

module Matcher
  class EqualMatcherTest < ActiveSupport::TestCase
    test '#inspect' do
      assert_equal '1', EqualMatcher.new(1).inspect
      assert_equal 'equal(1..10)', EqualMatcher.new(1..10).inspect
    end
  end
end
