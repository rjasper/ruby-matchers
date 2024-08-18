# frozen_string_literal: true

require 'test_helper'
require 'matcher/testing'

module Matcher
  class ReferenceMatcherTest < ActiveSupport::TestCase
    include Testing

    test 'linked list' do
      matcher = Matcher.build do
        refs[:list] = {
          head: Integer,
          tail: any(nil, refs[:list]),
        }
      end

      list = { head: 1, tail: { head: 2, tail: { head: 3 } } }

      assert_errors matcher.match(list),
        tail: { tail: { tail: 'expected entry for :tail but found nothing' } }
    end
  end
end
