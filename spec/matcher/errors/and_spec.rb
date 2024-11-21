# frozen_string_literal: true

require 'test_helper'

describe Matcher::Errors::And do
  include Matcher::ErrorsHelpers

  describe '#&' do
    it 'does not modify itself' do
      a = element('a')
      b = element('b')
      c = element('c')
      d = element('d')

      and1 = _and(a, b)
      and2 = _and(c, d)

      and3 = and1 & and2

      assert_equal _and(a, b), and1
      assert_equal _and(a, b, c, d), and3
    end
  end
end
