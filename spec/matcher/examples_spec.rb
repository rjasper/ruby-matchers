# frozen_string_literal: true

require 'test_helper'

describe 'examples' do
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
      }
    }

    assert_errors matcher.match(tree) do
      _or(:right) do
        error 'expected nil but got {:key=>7, :left=>{:key=>5, :left=>nil, :right=>nil}, :right=>{:key=>10, :left=>nil, :right=>nil}}'
        _or(:left) do
          error 'expected nil but got {:key=>5, :left=>nil, :right=>nil}'
          error :key, 'expected _ > low && _ < high to be truthy but got false, where _ = 5, low = 5, high = 7'
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
    graph = { vertices: [a, b, c]}

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

    assert_equal 'Math.sqrt(_) > 2', matcher.inspect

    assert_no_errors matcher.match(9)
    assert_errors matcher.match(4),
      'expected Math.sqrt(_) > 2 but got 2.0 > 2, where _ = 4'
  end

  it 'expressions: array' do
    matcher = Matcher.build do
      expr([_, 10]).sum >= 15
    end

    assert_equal '[_, 10].sum >= 15', matcher.inspect
    assert_no_errors matcher.match(10)
    assert_errors matcher.match(2),
      'expected [_, 10].sum >= 15 but got 12 >= 15, where _ = 2'
  end

  it 'expression: hash' do
    expression = Matcher::Expression.build { expr(_ => 1) }

    assert_equal({ 'foo' => 1 }, expression.evaluate(actual: 'foo'))
  end
end
