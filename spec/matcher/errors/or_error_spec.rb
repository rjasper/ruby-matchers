# frozen_string_literal: true

require 'test_helper'

describe Matcher::OrError do
  include Matcher::ErrorsTesting

  describe '#&' do
    it 'does not modify itself' do
      a = element('a')
      b = element('b')
      c = element('c')
      d = element('d')

      or1 = _or(a, b)
      or2 = _or(c, d)

      or3 = or1 | or2

      assert_equal _or(a, b), or1
      assert_equal _or(a, b, c, d), or3
    end
  end
end
