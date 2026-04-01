# frozen_string_literal: true

require 'test_helper'

describe Matcher::Block do
  include Matcher::Compatibility

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

    it 'raises on rest args' do
      err = assert_raises StandardError do
        Matcher::Block.build { |*args| args }
      end

      assert_equal '*args not allowed', err.message
    end

    it 'raises on rest kwargs' do
      err = assert_raises StandardError do
        Matcher::Block.build { |**kwargs| kwargs }
      end

      assert_equal '**kwargs not allowed', err.message
    end

    it 'raises on given block' do
      err = assert_raises StandardError do
        Matcher::Block.build { |&block| block }
      end

      assert_equal '&block not allowed', err.message
    end

    it 'raises when a outer variable is shadowed' do
      outer_a = Matcher::Variable.new(:a)

      e = assert_raises StandardError do
        Matcher::Block.build { |a| a + outer_a.to_recorder }
      end

      assert_equal "parameter #{quote_method(:a)} shadows an outer variable", e.message
    end

    it 'creates SymbolProc from symbol notation' do
      block = Matcher::Block.build(&:foo)
      struct = Struct.new(:foo).new('foo')

      assert_equal 'foo', block.to_proc.call(struct)
    end

    it 'simplifies a block to a SymbolProc' do
      # rubocop:disable Style/SymbolProc
      block = Matcher::Block.build { |x| x.foo }
      # rubocop:enable Style/SymbolProc

      symbol_proc = Matcher::SymbolProc.new(:foo)

      assert_kind_of Matcher::SymbolProc, block
      assert_equal symbol_proc, block
    end
  end

  it '#variables' do
    foo = Matcher::Variable.new(:foo)
    block = Matcher::Block.build { |bar| foo.to_recorder + bar }

    assert_equal [:foo], block.variables
  end

  it '#substitute' do
    x = Matcher::Variable.new(:x)
    z = Matcher::Variable.new(:z)
    block = Matcher::Block.build { |y| x.to_recorder + y }

    substituted = block.substitute(x: :z)

    assert_equal Matcher::Block.build { |y| z.to_recorder + y }, substituted
    assert_equal 5, substituted.to_proc(values: { z: 2 }).call(3)
  end

  describe '#to_proc' do
    it 'evaluates simple expressions' do
      block = Matcher::Block.build { |a, b| a * 10 + b }

      assert_equal 23, block.to_proc[2, 3]
    end

    it 'evaluates context sensitive expressions' do
      x = Matcher::Variable.new(:x)
      block = Matcher::Block.build { |y| x.to_recorder * 10 + y }

      assert_equal 42, block.to_proc(values: { x: 4 }).call(2)
    end
  end

  describe '#to_s' do
    it 'without args' do
      foo = Matcher::Variable.new(:foo)
      block = Matcher::Block.build { foo.to_recorder + 1 }

      assert_equal '-> { foo + 1 }', block.to_s
      assert_equal '{ foo + 1 }', block.to_s(as_block: true)
    end

    it 'with args' do
      block = Matcher::Block.build { |foo, bar:| foo + bar }

      assert_equal '->(foo, bar:) { foo + bar }', block.to_s
      assert_equal '{ |foo, bar:| foo + bar }', block.to_s(as_block: true)
    end
  end
end
