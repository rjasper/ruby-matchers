# frozen_string_literal: true

require 'test_helper'

describe Matcher::Errors do
  it 'el1 & el2 => and(el1, el2)' do
    e1, e2 = %w[e1 e2].map { element(_1) }

    assert_equal _and(e1, e2), e1 & e2
  end

  it 'el1 | el2 => or(el1, el2)' do
    e1, e2 = %w[e1 e2].map { element(_1) }

    assert_equal _or(e1, e2), e1 | e2
  end

  it 'nested & . => and(nested, .)' do
    a, b = %w[a b].map { element(_1) }

    assert_equal _and(nested(:foo, a), b),
      nested(:foo, a) & b
  end

  it 'nested(:foo, a) & nested(:foo, b) => nested(:foo, and(a, b))' do
    a, b = %w[a b].map { element(_1) }

    assert_equal nested(:foo, _and(a, b)),
      nested(:foo, a) & nested(:foo, b)
  end

  it 'nested(:foo, a) & nested(:bar, b) => and(nested(:foo, a), nested(:bar, b))' do
    a, b = %w[a b].map { element(_1) }

    assert_equal _and(nested(:foo, a), nested(:bar, b)),
      nested(:foo, a) & nested(:bar, b)
  end

  it 'nested(:foo, a) & and(nested(:foo, b), *c) => and(nested(:foo, and(a, b), *c)' do
    a, b, c = %w[a b c].map { element(_1) }

    assert_equal _and(nested(:foo, _and(a, b)), c),
      nested(:foo, a) & _and(nested(:foo, b), c)
  end

  it 'nested(:bar, a) & and(nested(:foo, b), *c) => and(nested(:foo, a), nested(:bar, b), *c)' do
    a, b, c = %w[a b c].map { element(_1) }

    assert_equal _and(nested(:foo, a), nested(:bar, b), c),
      nested(:foo, a) & _and(nested(:bar, b), c)
  end

  it 'nested | . => or(nested, .)' do
    a, b = %w[a b].map { element(_1) }

    assert_equal _or(nested(:foo, a), b),
      nested(:foo, a) | b
  end

  it 'nested(:foo, a) | nested(:foo, b) => nested(:foo, or(a, b))' do
    a, b = %w[a b].map { element(_1) }

    assert_equal nested(:foo, _or(a, b)),
      nested(:foo, a) | nested(:foo, b)
  end

  it 'nested(:foo, a) | nested(:bar, b) => or(nested(:foo, a), nested(:bar, b))' do
    a, b = %w[a b].map { element(_1) }

    assert_equal _or(nested(:foo, a), nested(:bar, b)),
      nested(:foo, a) | nested(:bar, b)
  end

  it 'nested(:foo, a) | or(nested(:foo, b), *c) => or(nested(:foo, or(a, b), *c)' do
    a, b, c = %w[a b c].map { element(_1) }

    assert_equal _or(nested(:foo, _or(a, b)), c),
      nested(:foo, a) | _or(nested(:foo, b), c)
  end

  it 'nested(:bar, a) | or(nested(:foo, b), *c) => or(nested(:foo, a), nested(:bar, b), *c)' do
    a, b, c = %w[a b c].map { element(_1) }

    assert_equal _or(nested(:foo, a), nested(:bar, b), c),
      nested(:foo, a) | _or(nested(:bar, b), c)
  end

  it 'and(*a) & b => and(*a, b)' do
    a1 = element('a1')
    a2 = element('a2')
    b = element('b')

    assert_equal _and(a1, a2, b),
      _and(a1, a2) & b
  end

  it 'and | . => or(and, .)' do
    a1, a2, b = %w[a1 a2 b].map { element(_1) }

    assert_equal _or(_and(a1, a2), b),
      _and(a1, a2) | b
  end

  it 'and(*a) | or(*b) => or(and(*a), *b)' do
    a1, a2, b1, b2 = %w[a1 a2 b1 b2].map { element(_1) }

    assert_equal _or(_and(a1, a2), b1, b2),
      _and(a1, a2) | _or(b1, b2)
  end

  it 'and(*a) & and(*b) => and(*a, *b)' do
    a1 = element('a1')
    a2 = element('a2')
    b1 = element('b1')
    b2 = element('b2')

    assert_equal _and(a1, a2, b1, b2),
      _and(a1, a2) & _and(b1, b2)
  end

  it 'and(nested(:foo, a), *b) & nested(:foo, c) => and(nested(:foo, and(a, c), *b)' do
    a, b, c = %w[a b c].map { element(_1) }

    assert_equal _and(nested(:foo, _and(a, c)), b),
      _and(nested(:foo, a), b) & nested(:foo, c)
  end

  it 'and(nested(:foo, a), *b) & nested(:bar, c) => and(nested(:foo, a), *b, nested(:bar, c))' do
    a, b, c = %w[a b c].map { element(_1) }

    assert_equal _and(nested(:foo, a), b, nested(:bar, c)),
      _and(nested(:foo, a), b) & nested(:bar, c)
  end

  it 'and(nested(:foo, a), *b) & and(nested(:foo, c), *d) => and(nested(:foo, and(a, c), *b, *d)' do
    a, b, c, d = %w[a b c d].map { element(_1) }

    assert_equal _and(nested(:foo, _and(a, c)), b, d),
      _and(nested(:foo, a), b) & _and(nested(:foo, c), d)
  end

  it 'and(nested(:foo, a), *b) & and(nested(:bar, c), *d) => and(nested(:foo, a), *b, nested(:bar, c), *d)' do
    a, b, c, d = %w[a b c d].map { element(_1) }

    assert_equal _and(nested(:foo, a), b, nested(:bar, c), d),
      _and(nested(:foo, a), b) & _and(nested(:bar, c), d)
  end

  it 'or(*a) & and(*b) => and(or(*a), *b)' do
    a1 = element('a1')
    a2 = element('a2')
    b1 = element('b1')
    b2 = element('b2')

    assert_equal _and(_or(a1, a2), b1, b2),
      _or(a1, a2) & _and(b1, b2)
  end

  it 'or(*a) & b => and(or(*a), b)' do
    a1 = element('a1')
    a2 = element('a2')
    b = element('b')

    assert_equal _and(_or(a1, a2), b),
      _or(a1, a2) & b
  end

  it 'or(*a) | b => or(*a, b)' do
    a1 = element('a1')
    a2 = element('a2')
    b = element('b')

    assert_equal _or(a1, a2, b),
      _or(a1, a2) | b
  end

  it 'or(*a) | or(*b) => or(*a, *b)' do
    a1 = element('a1')
    a2 = element('a2')
    b1 = element('b1')
    b2 = element('b2')

    assert_equal _or(a1, a2, b1, b2),
      _or(a1, a2) | _or(b1, b2)
  end

  it 'or(nested(:foo, a), *b) | nested(:foo, c) => or(nested(:foo, or(a, c), *b)' do
    a, b, c = %w[a b c].map { element(_1) }

    assert_equal _or(nested(:foo, _or(a, c)), b),
      _or(nested(:foo, a), b) | nested(:foo, c)
  end

  it 'or(nested(:foo, a), *b) | nested(:bar, c) => or(nested(:foo, a), *b, nested(:bar, c))' do
    a, b, c = %w[a b c].map { element(_1) }

    assert_equal _or(nested(:foo, a), b, nested(:bar, c)),
      _or(nested(:foo, a), b) | nested(:bar, c)
  end

  it 'or(nested(:foo, a), *b) | or(nested(:foo, c), *d) => or(nested(:foo, or(a, c), *b, *d)' do
    a, b, c, d = %w[a b c d].map { element(_1) }

    assert_equal _or(nested(:foo, _or(a, c)), b, d),
      _or(nested(:foo, a), b) | _or(nested(:foo, c), d)
  end

  it 'or(nested(:foo, a), *b) | or(nested(:bar, c), *d) => or(nested(:foo, a), *b, nested(:bar, c), *d)' do
    a, b, c, d = %w[a b c d].map { element(_1) }

    assert_equal _or(nested(:foo, a), b, nested(:bar, c), d),
      _or(nested(:foo, a), b) | _or(nested(:bar, c), d)
  end
end
