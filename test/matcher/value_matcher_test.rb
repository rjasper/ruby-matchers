# frozen_string_literal: true

require 'test_helper'

module Matcher
  class ValueMatcherTest < ActiveSupport::TestCase
    test '#inspect' do
      assert_equal '1', ValueMatcher.new(1).inspect
    end
  end
end
