# frozen_string_literal: true

require 'test_helper'

describe Matcher::Block do
  describe '::build' do
    it 'raises when a outer variable is shadowed' do
      outer_a = Matcher::Variable.new(:a)

      e = assert_raises StandardError do
        Matcher::Block.build { |a| a + outer_a.to_recorder }
      end

      assert_equal "parameter `a' shadows an outer variable", e.message
    end

    it 'creates SymbolProc from symbol notation' do
      block = Matcher::Block.build(&:foo)
      struct = Struct.new(:foo).new('foo')

      assert_equal 'foo', block.to_proc.call(struct)
    end
  end
end
