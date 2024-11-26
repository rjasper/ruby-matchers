# frozen_string_literal: true

require 'test_helper'

Collector = Matcher::Errors::Collector

describe Matcher::Errors::Collector do
  include Matcher::ErrorsHelpers

  it 'empty' do
    assert_equal empty, Collector.new.node
  end

  it 'add empty' do
    collector = Collector.new
    collector << empty

    assert_equal empty, collector.node
  end

  it 'one' do
    collector = Collector.new
    collector << element('foo')

    assert_equal element('foo'), collector.node
  end

  it 'and + and' do
    a1, a2, b1, b2 = %w[a1 a2 b1 b2].map { element(_1) }

    collector = Collector.new
    collector << _and(a1, a2)
    collector << _and(b1, b2)

    assert_equal _and(a1, a2, b1, b2), collector.node
  end

  it 'nested' do
    collector = Collector.new
    collector[:foo] << element('foo')

    assert_equal nested(:foo, element('foo')), collector.node
  end

  it 'deeply nested' do
    collector = Collector.new
    collector[:foo][:bar] << element('foobar')

    assert_equal nested(:foo, nested(:bar, element('foobar'))), collector.node
  end

  it 'nested via expression' do
    collector = Collector.new
    collector[expression { _[:foo] }] << element('foobar')

    assert_equal nested(:foo, element('foobar')), collector.node
  end

  it '#<<: base error' do
    collector = Collector.new

    assert_equal empty, collector.node

    collector << 'something went wrong'
    collector << 'more errors'

    expected = _and(
      element('something went wrong'),
      element('more errors'),
    )

    assert_equal expected, collector.node
  end

  it '#<<: field error' do
    collector = Collector.new

    assert_equal empty, collector.node

    collector[:foo] << 'something went wrong'
    collector[:foo] << 'more errors'

    expected = nested(
      :foo,
      _and(
        element('something went wrong'),
        element('more errors'),
      )
    )

    assert_equal expected, collector.node
  end

  it '#<<: empty errors' do
    collector = Collector.new
    collector << empty

    assert_equal empty, collector.node

    collector << 'something went wrong'

    assert_equal element('something went wrong'), collector.node
  end
end
