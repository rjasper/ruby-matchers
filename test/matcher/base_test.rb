# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

module Matcher
  class BaseTest < ActiveSupport::TestCase
    include Matcher::Testing

    test 'check match level' do
      matcher = Matcher.build do
        refs[:obj] = project(_.dup) ^ refs[:obj]
      end

      Matcher.with(max_depth: 2) do
        assert_errors matcher.match(Object.new),
          expr { _1.dup } => { expr { _1.dup } => 'match level too deep: 3' }
      end
    end
  end
end
