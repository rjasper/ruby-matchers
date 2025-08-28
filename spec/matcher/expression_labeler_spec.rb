# frozen_string_literal: true

require 'test_helper'

describe Matcher::ExpressionLabeler do
  let(:labeler) { Matcher::ExpressionLabeler.new }

  it 'returns the same label for equivalent expressions' do
    a = labeler.label(expression { (vars[:foo] + [1]).sum { |x| x % 2 } })
    b = labeler.label(expression { (vars[:foo] + [1]).sum { |x| x % 2 } })
    c = labeler.label(expression { (vars[:foo] + [2]).sum { |x| x % 2 } })
    d = labeler.label(expression { (vars[:bar] + [1]).sum { |x| x % 2 } })
    e = labeler.label(expression { (vars[:foo] - [1]).sum { |x| x % 2 } })
    f = labeler.label(expression { (vars[:foo] + [1]).sum { |x| x % 10 } })

    assert_equal a, b
    refute_equal a, c
    refute_equal a, d
    refute_equal a, e
    refute_equal a, f
  end

  it 'labels data structures' do
    array_l = labeler.label(expression { [1, vars[:foo]] })
    hash_l = labeler.label(expression { { foo: vars[:foo] } })
    range_l = labeler.label(expression { (vars[:foo]..vars[:bar]) })
    string_l = labeler.label(expression { concat(vars[:foo], 'bar') })

    assert_equal array_l, labeler.label(expression { [1, vars[:foo]] })
    refute_equal array_l, labeler.label(expression { [1, vars[:bar]] })
    assert_equal hash_l, labeler.label(expression { { foo: vars[:foo] } })
    refute_equal hash_l, labeler.label(expression { { foo: vars[:bar] } })
    assert_equal range_l, labeler.label(expression { (vars[:foo]..vars[:bar]) })
    refute_equal range_l, labeler.label(expression { (vars[:foo]..vars[:baz]) })
    assert_equal string_l, labeler.label(expression { concat(vars[:foo], 'bar') })
    refute_equal string_l, labeler.label(expression { concat(vars[:foo], 'baz') })
  end

  it 'can substitute label for _' do
    a = labeler.label(expression { _.foo })
    b = labeler.label(expression { _.bar }, a)
    c = labeler.label(expression { _.foo.bar })

    assert_equal b, c

    two_times = expression { _ + _ }
    x = labeler.label(two_times)
    y = labeler.label(two_times, x)
    z = labeler.label(expression { (_ + _) + (_ + _) })

    assert_equal y, z
  end
end
