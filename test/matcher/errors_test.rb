# frozen_string_literal: true

require 'test_helper'

module Matcher
  class ErrorsTest < ActiveSupport::TestCase
    test '#add: base error' do
      errors = Errors.new

      assert_predicate errors, :valid?

      errors.add('something went wrong')
      errors.add('more errors')

      assert_not_predicate errors, :valid?
      assert_equal ['something went wrong', 'more errors'], errors.base
    end

    test '#add: field error' do
      errors = Errors.new

      assert_predicate errors, :valid?

      errors.add(:foo, 'foo is not a bar')
      errors.add(:foo, 'you did wrong')

      assert_not_predicate errors, :valid?
      assert_kind_of Errors, errors.attributes[:foo]
      assert_equal ['foo is not a bar', 'you did wrong'],
        errors.attributes[:foo].base
    end

    test '#add: empty errors' do
      errors = Errors.new
      errors.add(Errors.new)

      assert_predicate errors, :valid?
    end

    test '#add: merge errors' do
      errors1 = Errors.new
      errors1.add('base1')
      errors1.add(:a, 'a1')
      errors1.add(:b, 'b1')

      errors2 = Errors.new
      errors2.add('base2')
      errors2.add(:b, 'b2')
      errors2.add(:c, 'c2')

      errors3 = Errors.new
      errors3.add('c3')

      errors2.add(:c, errors3)
      errors1.add(errors2)

      assert_equal %w[base1 base2], errors1.base
      assert_equal %w[a1], errors1.attributes[:a].base
      assert_equal %w[b1 b2], errors1.attributes[:b].base
      assert_equal %w[c2 c3], errors1.attributes[:c].base
    end

    test '#add: simple expression key' do
      errors = Errors.new
      errors.add(Expression.build { _1[:foo] }, 'foo is wrong')

      assert_equal ['foo is wrong'], errors.attributes[:foo].base
    end

    test '#add: chained expression key' do
      errors = Errors.new
      errors.add(Expression.build { _1[:foo][:bar] }, 'foo bar is wrong')

      assert_equal ['foo bar is wrong'],
        errors.attributes[:foo].attributes[:bar].base
    end

    test '#add: advanced expression key' do
      errors = Errors.new
      expression = Expression.build { _1 + 1 }
      errors.add(expression, 'something went wrong')

      assert_equal ['something went wrong'], errors.attributes[expression].base
    end

    test '#add: root expression key' do
      errors = Errors.new
      expression = Expression.build { _1 }
      errors.add(expression, 'something went wrong')

      assert_equal ['something went wrong'], errors.base
    end

    test '#<<' do
      errors = Errors.new
      errors << "that's not right"

      assert_equal ["that's not right"], errors.base
    end

    test '#[] <<' do
      errors = Errors.new
      errors[:foo] << "that's incorrect"

      assert_equal ["that's incorrect"], errors.attributes[:foo].base
    end

    test '#message' do
      errors1 = Errors.new
      errors1.add('base 1')
      errors1.add(:a, 'a1')
      errors1.add(:a, 'a2')

      errors2 = Errors.new
      errors2.add(:b, 'b1')
      errors2.add('c', 'c1')
      errors2.add(1, 'one')

      errors1.add(:a, errors2)

      assert_equal <<~TEXT.chomp, errors1.message
        - base 1
        a: a1
        a: a2
        a.b: b1
        a["c"]: c1
        a[1]: one
      TEXT
    end
  end
end
