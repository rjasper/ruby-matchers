# frozen_string_literal: true

require 'test_helper'

describe Matcher::ErrorCollector do
  include Matcher::ErrorTesting

  let(:collector) { Matcher::ErrorCollector.new(nil) }

  it 'empty' do
    assert_equal empty, collector.error
  end

  it 'add empty' do
    collector << empty

    assert_equal empty, collector.error
  end

  it 'one' do
    collector << element('foo')

    assert_equal element('foo'), collector.error
  end

  it 'and + and' do
    a1, a2, b1, b2 = %w[a1 a2 b1 b2].map { element(_1) }

    collector << _and(a1, a2)
    collector << _and(b1, b2)

    assert_equal _and(a1, a2, b1, b2), collector.error
  end

  it 'or + or' do
    a1, a2, b1, b2 = %w[a1 a2 b1 b2].map { element(_1) }

    collector.or!
    collector << _or(a1, a2)
    collector << _or(b1, b2)

    assert_equal _or(a1, a2, b1, b2), collector.error
  end

  it 'nested' do
    collector[:foo] << element('foo')

    assert_equal nested(expression { _[:foo] }, element('foo')), collector.error
  end

  it 'deeply nested' do
    collector[:foo][:bar] << element('foobar')

    foo = expression { _[:foo] }
    bar = expression { _[:bar] }

    assert_equal nested(foo, nested(bar, element('foobar'))), collector.error
  end

  it 'nested via expression' do
    collector[expression { _[:foo] }] << element('foobar')

    foo = expression { _[:foo] }

    assert_equal nested(foo, element('foobar')), collector.error
  end

  it 'binds nested values' do
    collector = Matcher::ErrorCollector.new(foo: 1)
    collector[expression { _ + vars[:foo] }] << 'something went wrong'

    key = collector.error.key

    assert_equal 3, key.evaluate(actual: 2)
  end

  it '#<<: base error' do
    assert_equal empty, collector.error

    collector << 'something went wrong'
    collector << 'more errors'

    expected = _and(
      element('something went wrong'),
      element('more errors'),
    )

    assert_equal expected, collector.error
  end

  it '#<<: returns collector error' do
    assert_equal element('something went wrong'),
      collector << 'something went wrong'
  end

  it '#<<: field error' do
    assert_equal empty, collector.error

    collector[:foo] << 'something went wrong'
    collector[:foo] << 'more errors'

    expected = nested(
      expression { _[:foo] },
      _and(
        element('something went wrong'),
        element('more errors'),
      ),
    )

    assert_equal expected, collector.error
  end

  it '#<<: empty errors' do
    collector << empty

    assert_equal empty, collector.error

    collector << 'something went wrong'

    assert_equal element('something went wrong'), collector.error
  end
end
