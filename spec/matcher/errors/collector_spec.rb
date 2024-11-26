# frozen_string_literal: true

require 'test_helper'

describe Matcher::Errors::Collector do
  include Matcher::ErrorsHelpers

  let(:collector) { Matcher::Errors::Collector.new }

  it 'empty' do
    assert_equal empty, collector.node
  end

  it 'add empty' do
    collector << empty

    assert_equal empty, collector.node
  end

  it 'one' do
    collector << element('foo')

    assert_equal element('foo'), collector.node
  end

  it 'and + and' do
    a1, a2, b1, b2 = %w[a1 a2 b1 b2].map { element(_1) }

    collector << _and(a1, a2)
    collector << _and(b1, b2)

    assert_equal _and(a1, a2, b1, b2), collector.node
  end

  it 'nested' do
    collector[:foo] << element('foo')

    assert_equal nested(expression { _[:foo] }, element('foo')), collector.node
  end

  it 'deeply nested' do
    collector[:foo][:bar] << element('foobar')

    foo = expression { _[:foo] }
    bar = expression { _[:bar] }

    assert_equal nested(foo, nested(bar, element('foobar'))), collector.node
  end

  it 'nested via expression' do
    collector[expression { _[:foo] }] << element('foobar')

    foo = expression { _[:foo] }

    assert_equal nested(foo, element('foobar')), collector.node
  end

  it '#<<: base error' do
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
    assert_equal empty, collector.node

    collector[:foo] << 'something went wrong'
    collector[:foo] << 'more errors'

    expected = nested(
      expression { _[:foo] },
      _and(
        element('something went wrong'),
        element('more errors'),
      ),
    )

    assert_equal expected, collector.node
  end

  it '#<<: empty errors' do
    collector << empty

    assert_equal empty, collector.node

    collector << 'something went wrong'

    assert_equal element('something went wrong'), collector.node
  end
end
