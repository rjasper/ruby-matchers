# frozen_string_literal: true

require 'test_helper'

describe Matcher::Block do
  describe '::build' do
    it 'records expression inside block' do
      block = Matcher::Block.build { |a, b:| a + b }

      assert_equal expression { vars[:a] + vars[:b] }, block.expression
    end

    it 'records constant' do
      block = Matcher::Block.build { 42 }
      constant = Matcher::Constant.new(42)

      assert_equal constant, block.expression
    end

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
