# frozen_string_literal: true

require 'test_helper'

describe 'examples' do
  it 'showcase' do
    matcher = Matcher.build do
      {
        name: String,
        checksum: /\A[0-9a-f]{32}\z/,
        count: 1..10,
        size: [32, _.even?],
        value: _ < 100,
      }
    end

    assert_no_errors matcher.match({
      name: 'test',
      checksum: '912ec803b2ce49e4a541068d495ab570',
      count: 2,
      size: [32, 16],
      value: 42,
    })

    assert_errors matcher.match({
      name: nil,
      checksum: 'kS7IA7LOSeSlQQaNSVq1cA==',
      count: 0,
      size: [30, 15],
      value: 1337,
    }),
      name: msg(nil).not.kind_of(String),
      checksum: msg('kS7IA7LOSeSlQQaNSVq1cA==').not.matching(/\A[0-9a-f]{32}\z/),
      count: msg(0).not.between(1, 10),
      size: {
        0 => msg(30).not.equal(32),
        1 => msg(15).not.predicate(:even?),
      },
      value: msg(1337).not.less_than(100)
  end

  it 'tree' do
    matcher = Matcher.build do
      inf = Float::INFINITY
      declare low: -inf, high: inf

      child = of(nil) + refs[:node]

      refs[:node] = {
        key: of(Integer) & lo { (_ > low) & (_ < high) },
        left: let(high: expr([parent[:key], high]).min) ^ child,
        right: let(low: expr([parent[:key], low]).max) ^ child,
      }
    end

    tree = {
      key: 5,
      left: {
        key: 3,
        left: { key: 1, left: nil, right: nil },
        right: { key: 4, left: nil, right: nil },
      },
      right: {
        key: 7,
        left: { key: 5, left: nil, right: nil }, # error: key equal to root key
        right: { key: 10, left: nil, right: nil },
      },
    }

    assert_errors matcher.match(tree) do
      _or(:right) do
        actual7 = {
          key: 7,
          left: { key: 5, left: nil, right: nil },
          right: { key: 10, left: nil, right: nil },
        }

        error "expected nil but got #{actual7}"
        _or(:left) do
          error "expected nil but got #{{ key: 5, left: nil, right: nil }}"
          error :key, "expected actual > low && actual < high to be truthy " \
            "but got false, where actual = 5, low = 5, high = 7"
        end
      end
    end
  end

  it 'cyclic graph' do
    matcher = Matcher.build do
      refs[:vertex] = {
        name: String,
        edges: each(refs[:edge, cyclic: true]),
      }

      refs[:edge] = {
        weight: Integer,
        destination: refs[:vertex, cyclic: true],
      }

      # graph
      { vertices: each(refs[:vertex]) }
    end

    a = { name: 'a', edges: [] }
    b = { name: 'b', edges: [] }
    c = { name: 'c', edges: [] }
    graph = { vertices: [a, b, c] }

    a[:edges] << { weight: 1, destination: b }
    b[:edges] << { weight: 2, destination: c }

    assert_no_errors matcher.match(graph)

    c[:edges] << { weight: 3, destination: a }

    assert_no_errors matcher.match(graph)
  end

  it 'chain' do
    matcher = Matcher.build do
      declare :c

      let(c: 1) ^ let(c: c + 1) ^ {
        value: _ == vars[:c],
      }
    end

    assert_no_errors matcher.match({ value: 2 })
  end

  it 'map ^ each' do
    matcher = Matcher.build do
      map(_.length) ^ each(3)
    end

    assert_no_errors matcher.match(%w[123 456])

    assert_errors matcher.match(%w[123 456 7890]),
      2 => { expression { _.length } => 'expected 3 but got 4' }
  end

  it 'expressions: constant receiver' do
    matcher = Matcher.build do
      expr(Math).sqrt(_) > 2
    end

    assert_equal 'Math.sqrt(actual) > 2', matcher.inspect

    assert_no_errors matcher.match(9)
    assert_errors matcher.match(4),
      'expected Math.sqrt(actual) > 2 but got 2.0 > 2, where actual = 4'
  end

  it 'expressions: array' do
    matcher = Matcher.build do
      expr([_, 10]).sum >= 15
    end

    assert_equal '[actual, 10].sum >= 15', matcher.inspect
    assert_no_errors matcher.match(10)
    assert_errors matcher.match(2),
      'expected [actual, 10].sum >= 15 but got 12 >= 15, where actual = 2'
  end

  it 'expression: hash' do
    expression = Matcher::Expression.build { expr(_ => 1) }

    assert_equal({ 'foo' => 1 }, expression.evaluate(actual: 'foo'))
  end
end
