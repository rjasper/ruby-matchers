# frozen_string_literal: true

require 'test_helper'

describe Matcher::SymbolProc do
  it 'initializes from Proc' do
    symbol_proc = Matcher::SymbolProc.new(proc(&:upcase))

    assert_equal :upcase, symbol_proc.symbol
    assert_equal 'FOO', symbol_proc.to_proc.call('foo')
  end

  it 'initializes from Symbol' do
    symbol_proc = Matcher::SymbolProc.new(:upcase)

    assert_equal :upcase, symbol_proc.symbol
    assert_equal 'FOO', symbol_proc.to_proc.call('foo')
  end

  it '#to_s' do
    assert_equal '&:upcase', Matcher::SymbolProc.new(:upcase).to_s
  end
end
