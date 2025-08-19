# frozen_string_literal: true

require 'test_helper'

describe Matcher::ExpectedPhrasing do
  include Matcher::ErrorTesting

  describe 'standard messages' do
    it 'truthy' do
      assert_phrase 'expected a truthy value but got nil',
        msg(nil).not.truthy
      assert_phrase 'expected a falsy value but got 1',
        msg(1).truthy
    end

    it 'same' do
      assert_phrase "expected same as 2 (id=#{2.object_id}) but got 1 (id=#{1.object_id})",
        msg(1).not.same(2)
      assert_phrase "did not expect same as 1 (id=#{1.object_id})",
        msg(1).same(1)
    end

    it 'equal' do
      assert_phrase 'expected 0 but got 1',
        msg(1).not.equal(0)
      assert_phrase 'did not expect 0',
        msg(0).equal(0)
    end

    it 'less_than' do
      assert_phrase 'expected a value < 0 but got 0',
        msg(0).not.less_than(0)
      assert_phrase 'expected a value >= 0 but got -1',
        msg(-1).less_than(0)
    end

    it 'greater_than' do
      assert_phrase 'expected a value > 0 but got 0',
        msg(0).not.greater_than(0)
      assert_phrase 'expected a value <= 0 but got 1',
        msg(1).greater_than(0)
    end

    it 'less_or_equal_than' do
      assert_phrase 'expected a value <= 0 but got 1',
        msg(1).not.less_or_equal_than(0)
      assert_phrase 'expected a value > 0 but got 0',
        msg(0).less_or_equal_than(0)
    end

    it 'greater_or_equal_than' do
      assert_phrase 'expected a value >= 0 but got -1',
        msg(-1).not.greater_or_equal_than(0)
      assert_phrase 'expected a value < 0 but got 0',
        msg(0).greater_or_equal_than(0)
    end

    it 'comparable_to' do
      assert_phrase 'expected a value comparable to #<Set: {1}> but got #<Set: {2}>',
        msg(Set[2]).not.comparable_to(Set[1])
      assert_phrase 'did not expect a value comparable to #<Set: {1}> but got #<Set: {1, 2}>',
        msg(Set[1, 2]).comparable_to(Set[1])
    end

    it 'between' do
      assert_phrase 'expected value to be between 0 and 10 but got 15',
        msg(15).not.between(0, 10)
      assert_phrase 'did not expect value to be between 0 and 10 but got 15',
        msg(15).between(0, 10)
    end

    it 'length_of' do
      assert_phrase 'expected length of 2 but was 1',
        msg([1]).not.length_of(2, 1)
      assert_phrase 'did not expect length of 1',
        msg([1]).length_of(1, 1)
    end

    it 'having_index' do
      assert_phrase 'expected to have index 0 but got []',
        msg([]).not.having_index(0)
      assert_phrase 'did not expect to have index 0 but got [1]',
        msg([1]).having_index(0)
    end

    it 'having_key' do
      assert_phrase 'expected to include key :foo but got {}',
        msg({}).not.having_key(:foo)
      assert_phrase 'did not expect to include key :foo but got {:foo=>true}',
        msg({ foo: true }).having_key(:foo)
    end

    it 'exist' do
      assert_phrase 'expected index to exist',
        msg(nil).not.exist
      assert_phrase 'did not expect index to exist but got 1',
        msg(1).exist
    end

    it 'in' do
      assert_phrase 'expected object to be included in ["bar"] but got "foo"',
        msg('foo').not.in(['bar'])
      assert_phrase 'did not expect object to be included in ["foo"] but got "foo"',
        msg('foo').in(['foo'])
    end

    it 'including' do
      assert_phrase 'expected 1 to be included but got []',
        msg([]).not.including(1)
      assert_phrase 'did not expect 1 to be included but got [1]',
        msg([1]).including(1)
    end

    it 'duplicate_by' do
      actual = { id: 5 }
      expr = expression { _[:id] }

      assert_phrase "expected duplicate by _[:id]=5 originally at index 7 but got #{actual.inspect}",
        msg(actual).not.duplicate_by(expr, 5, 7)
      assert_phrase "did not expect duplicate by _[:id]=5 originally at index 7 but got #{actual.inspect}",
        msg(actual).duplicate_by(expr, 5, 7)
    end

    it 'matching' do
      assert_phrase 'expected value to match /Hello/ but got "Hi!"',
        msg('Hi!').not.matching(/Hello/)
      assert_phrase 'did not expect value to match /Hello/ but got "Hello World!"',
        msg('Hello World!').matching(/Hello/)
    end

    it 'valid_format' do
      assert_phrase 'expected a valid integer string but got "foo"',
        msg('foo').not.valid_format(:integer)
      assert_phrase 'did not expect a valid integer string but got "42"',
        msg('42').valid_format(:integer)
    end

    it 'instance_of' do
      assert_phrase 'expected an instance of Integer but got "string"',
        msg('string').not.instance_of(Integer)
      assert_phrase 'did not expect an instance of Integer but got 1',
        msg(1).instance_of(Integer)
    end

    it 'kind_of' do
      assert_phrase 'expected a kind of Numeric but got "string"',
        msg('string').not.kind_of(Numeric)
      assert_phrase 'did not expect a kind of Numeric but got 1',
        msg(1).kind_of(Numeric)
    end

    it 'responding_to' do
      assert_phrase "expected an object responding to `+' but got nil",
        msg(nil).not.responding_to(:+)
      assert_phrase "did not expect an object responding to `+' but got 1",
        msg(1).responding_to(:+)
    end

    it 'predicate' do
      assert_phrase 'expected value to be even but got 1',
        msg(1).not.predicate(:even?)
      assert_phrase 'did not expect value to be even but got 2',
        msg(2).predicate(:even?)
    end

    it 'described_by' do
      assert_phrase 'expected an answer to everything but got 3',
        msg(3).not.described_by('an answer to everything')
      assert_phrase 'did not expect an answer to everything but got 42',
        msg(42).described_by('an answer to everything')
    end
  end

  describe 'expression' do
    it 'truthy' do
      assert_phrase 'expected foo to be truthy but got false',
        msg(nil).namespace(:expression).not.truthy(expression { vars[:foo] }, false, { foo: false })
      assert_phrase 'expected foo to be falsy but got true',
        msg(nil).namespace(:expression).truthy(expression { vars[:foo] }, true, { foo: true })
    end

    it 'same' do
      assert_phrase "expected _ + 1 to be same as _ * 2 but got 3 (id=#{3.object_id}) and 4 (id=#{4.object_id}), where _ = 2",
        msg(nil).namespace(:expression).not.same(expression { _ + 1 }, expression { _ * 2 }, 3, 4, { actual: 2 })
      assert_phrase "did not expect _ + 1 to be same as _ * 2 but got 2 (id=#{2.object_id}), where _ = 1",
        msg(nil).namespace(:expression).same(expression { _ + 1 }, expression { _ * 2 }, 2, 2, { actual: 1 })
    end

    it 'comparison' do
      assert_phrase 'expected _ % 3 == 0 but got 1 == 0, where _ = 7',
        msg(7).namespace(:expression).not.comparison(expression { _ % 3 == 0 }, 1, 0, { actual: 7 })
      assert_phrase 'expected _ % 3 != 1 but got 1 != 1, where _ = 7',
        msg(7).namespace(:expression).comparison(expression { _ % 3 == 1 }, 1, 1, { actual: 7 })

      assert_phrase 'expected _ * 2 < 0 but got 2 < 0, where _ = 1',
        msg(1).namespace(:expression).not.comparison(expression { _ * 2 < 0 }, 2, 0, { actual: 1 })
      assert_phrase 'expected _ * 2 >= 0 but got -2 >= 0, where _ = -1',
        msg(-1).namespace(:expression).comparison(expression { _ * 2 < 0 }, -2, 0, { actual: -1 })

      assert_phrase 'expected _ * 2 > 0 but got -2 > 0, where _ = -1',
        msg(-1).namespace(:expression).not.comparison(expression { _ * 2 > 0 }, -2, 0, { actual: -1 })
      assert_phrase 'expected _ * 2 <= 0 but got 2 <= 0, where _ = 1',
        msg(1).namespace(:expression).comparison(expression { _ * 2 > 0 }, 2, 0, { actual: 1 })

      assert_phrase 'expected _ * 2 <= 0 but got 2 <= 0, where _ = 1',
        msg(1).namespace(:expression).not.comparison(expression { _ * 2 <= 0 }, 2, 0, { actual: 1 })
      assert_phrase 'expected _ * 2 > 0 but got -2 > 0, where _ = -1',
        msg(-1).namespace(:expression).comparison(expression { _ * 2 <= 0 }, -2, 0, { actual: -1 })

      assert_phrase 'expected _ * 2 >= 0 but got -2 >= 0, where _ = -1',
        msg(-1).namespace(:expression).not.comparison(expression { _ * 2 >= 0 }, -2, 0, { actual: -1 })
      assert_phrase 'expected _ * 2 < 0 but got 2 < 0, where _ = 1',
        msg(1).namespace(:expression).comparison(expression { _ * 2 >= 0 }, 2, 0, { actual: 1 })
    end

    it 'comparable_to' do
      assert_phrase 'did not expect _.to_set to be comparable to #<Set: {1}> but got #<Set: {1, 2}>, where _ = [1, 2]',
        msg([1, 2]).namespace(:expression).comparable_to(expression { _.to_set }, Set[1, 2], Set[1], { actual: [1, 2] })
      assert_phrase 'expected _.to_set to be comparable to #<Set: {1}> but got #<Set: {2}>, where _ = [2]',
        msg([2]).namespace(:expression).not.comparable_to(expression { _.to_set }, Set[2], Set[1], { actual: [2] })
    end

    it 'between' do
      assert_phrase 'expected _ * 2 to be between 0 and 20 but got 30, where _ = 15',
        msg(15).namespace(:expression).not.between(expression { _ * 2 }, 30, 0, 20, { actual: 15 })
      assert_phrase 'did not expect _ * 2 to be between 0 and 20 but got 10, where _ = 5',
        msg(5).namespace(:expression).between(expression { _ * 2 }, 10, 0, 20, { actual: 5 })
    end

    it 'length_of' do
      assert_phrase 'expected _ + [3] to have length of 2 but was 3, where _ = [1, 2]',
        msg([1, 2]).namespace(:expression).not.length_of(expression { _ + [3] }, 2, 3, { actual: [1, 2] })
      assert_phrase 'did not expect _ + [3] to have length of 3, where _ = [1, 2]',
        msg([1, 2]).namespace(:expression).length_of(expression { _ + [3] }, 3, 3, { actual: [1, 2] })
    end

    it 'having_key' do
      assert_phrase 'expected _.to_h to include key :foo but got {}, where _ = []',
        msg([]).namespace(:expression).not.having_key(expression { _.to_h }, {}, :foo, { actual: [] })
      assert_phrase 'did not expect _.to_h to include key :foo but got {:foo=>true}, where _ = [[:foo, true]]',
        msg([[:foo, true]]).namespace(:expression).having_key(expression { _.to_h }, { foo: true }, :foo, { actual: [[:foo, true]] })
    end

    it 'in' do
      assert_phrase 'expected _.itself to be included in ["bar"] but got "foo", where _ = "foo"',
        msg('foo').namespace(:expression).not.in(expression { _.itself }, 'foo', ['bar'], { actual: 'foo' })
      assert_phrase 'did not expect _.itself to be included in ["foo"] but got "foo", where _ = "foo"',
        msg('foo').namespace(:expression).in(expression { _.itself }, 'foo', ['foo'], { actual: 'foo' })
    end

    it 'including' do
      assert_phrase 'expected _[0..1] to include 4 but got [0, 1], where _ = [0, 1, 2]',
        msg([0, 1, 2]).namespace(:expression).not.including(expression { _[0..1] }, [0, 1], 4, { actual: [0, 1, 2] })
      assert_phrase 'did not expect _[0..1] to include 1 but got [0, 1], where _ = [0, 1, 2]',
        msg([0, 1, 2]).namespace(:expression).including(expression { _[0..1] }, [0, 1], 1, { actual: [0, 1, 2] })
    end

    it 'matching' do
      assert_phrase 'expected _.downcase to match /hello/ but got "hi!", where _ = "Hi!"',
        msg('Hi!').namespace(:expression).not.matching(expression { _.downcase }, 'hi!', /hello/, { actual: 'Hi!' })
      assert_phrase 'did not expect _.downcase to match /hello/ but got "hello world!", where _ = "Hello World!"',
        msg('Hello World!').namespace(:expression).matching(expression { _.downcase }, 'hello world!', /hello/, { actual: 'Hello World!' })
    end

    it 'match_at' do
      actual = Matcher::Variable.actual

      assert_phrase 'expected _ to match /b/ at 2 but was at 1 for "abcd"',
        msg('abcd').namespace(:expression).not.match_at(actual, 'abcd', /b/, 1, :==, 2, { actual: 'abcd' })
      assert_phrase 'did not expect _ to match /b/ at 1 for "abcd"',
        msg('abcd').namespace(:expression).match_at(actual, 'abcd', /b/, 1, :==, 1, { actual: 'abcd' })

      assert_phrase 'expected _ to match /b/ not at 1 for "abcd"',
        msg('abcd').namespace(:expression).not.match_at(actual, 'abcd', /b/, 1, :!=, 1, { actual: 'abcd' })
      assert_phrase 'did not expect _ to match /b/ not at 2 but was at 1 for "abcd"',
        msg('abcd').namespace(:expression).match_at(actual, 'abcd', /b/, 1, :!=, 2, { actual: 'abcd' })

      assert_phrase 'expected _ to match /b/ after 2 but was at 1 for "abcd"',
        msg('abcd').namespace(:expression).not.match_at(actual, 'abcd', /b/, 1, :>, 2, { actual: 'abcd' })
      assert_phrase 'did not expect _ to match /b/ after 0 but was at 1 for "abcd"',
        msg('abcd').namespace(:expression).match_at(actual, 'abcd', /b/, 1, :>, 0, { actual: 'abcd' })

      assert_phrase 'expected _ to match /b/ before 1 but was at 1 for "abcd"',
        msg('abcd').namespace(:expression).not.match_at(actual, 'abcd', /b/, 1, :<, 1, { actual: 'abcd' })
      assert_phrase 'did not expect _ to match /b/ before 2 but was at 1 for "abcd"',
        msg('abcd').namespace(:expression).match_at(actual, 'abcd', /b/, 1, :<, 2, { actual: 'abcd' })

      assert_phrase 'expected _ to match /b/ at or before 0 but was at 1 for "abcd"',
        msg('abcd').namespace(:expression).not.match_at(actual, 'abcd', /b/, 1, :<=, 0, { actual: 'abcd' })
      assert_phrase 'did not expect _ to match /b/ at or before 2 but was at 1 for "abcd"',
        msg('abcd').namespace(:expression).match_at(actual, 'abcd', /b/, 1, :<=, 2, { actual: 'abcd' })

      assert_phrase 'expected _ to match /b/ at or after 2 but was at 1 for "abcd"',
        msg('abcd').namespace(:expression).not.match_at(actual, 'abcd', /b/, 1, :>=, 2, { actual: 'abcd' })
      assert_phrase 'did not expect _ to match /b/ at or after 1 but was at 1 for "abcd"',
        msg('abcd').namespace(:expression).match_at(actual, 'abcd', /b/, 1, :>=, 1, { actual: 'abcd' })
    end

    it 'instance_of' do
      assert_phrase 'expected _ + 1 to be an instance of Integer but got 1.0, where _ = 0.0',
        msg(0.0).namespace(:expression).not.instance_of(expression { _ + 1 }, 1.0, Integer, { actual: 0.0 })
      assert_phrase 'did not expect _ + 1 to be an instance of Integer but got 1, where _ = 0',
        msg(0).namespace(:expression).instance_of(expression { _ + 1 }, 1, Integer, { actual: 0 })
    end

    it 'kind_of' do
      assert_phrase 'expected _ + 1 to be a kind of Integer but got 2.0, where _ = 1.0',
        msg(1.0).namespace(:expression).not.kind_of(expression { _ + 1 }, 2.0, Integer, { actual: 1.0 })
      assert_phrase 'did not expect _ + 1 to be a kind of Integer but got 2, where _ = 1',
        msg(1).namespace(:expression).kind_of(expression { _ + 1 }, 2, Integer, { actual: 1 })
    end

    it 'responding_to' do
      assert_phrase "expected _ * 2 to respond to `**' but got \"aa\", where _ = \"a\"",
        msg('a').namespace(:expression).not.responding_to(expression { _ * 2 }, 'aa', :**, { actual: 'a' })
      assert_phrase "did not expect _ * 2 to respond to `**' but got 2, where _ = 1",
        msg(1).namespace(:expression).responding_to(expression { _ * 2 }, 2, :**, { actual: 1 })
    end

    it 'predicate' do
      assert_phrase 'expected _ / 2 to be even but got 3, where _ = 6',
        msg(6).namespace(:expression).not.predicate(expression { _ / 2 }, 3, :even?, { actual: 6 })
      assert_phrase 'did not expect _ / 2 to be even but got 4, where _ = 8',
        msg(8).namespace(:expression).predicate(expression { _ / 2 }, 4, :even?, { actual: 8 })
    end

    it 'raising' do
      error = assert_raises(ZeroDivisionError) { 1 / 0 }

      assert_phrase 'did not expect 1 / _ to raise ZeroDivisionError, where _ = 0: divided by 0',
        msg(0).namespace(:expression).raising(expression { expr(1) / _ }, error, { actual: 0 })
    end
  end

  describe 'negated' do
    it 'valid' do
      is_one = Matcher.build { 1 }

      assert_phrase 'did not expect 1 to be valid but got 1',
        msg(1).namespace(:negated).valid(is_one)
    end
  end

  describe 'block' do
    it 'satisfied' do
      assert_phrase "expected to satisfy condition block_matcher_spec.rb:1337 but got 0",
        msg(0).namespace(:block).not.satisfied("block_matcher_spec.rb:1337")
      assert_phrase "did not expect to satisfy condition block_matcher_spec.rb:1337 but got 4",
        msg(4).namespace(:block).satisfied("block_matcher_spec.rb:1337")
    end
  end

  describe 'imply_one' do
    let(:conditions) { [expression { _.even? }, expression { _ % 3 == 0 }] }

    it 'no_condition_satisfied' do
      assert_phrase 'expected to satisfy one condition but got 5 and met none of these: _.even?, _ % 3 == 0',
        msg(5).namespace(:imply_some).no_condition_satisfied(conditions, 1)
    end

    it 'multiple_conditions_satisfied' do
      assert_phrase 'expected to satisfy one condition but got 6 and met these: _.even?, _ % 3 == 0',
        msg(6).namespace(:imply_some).x_conditions_satisfied(conditions, 1)
    end
  end

  describe 'reference' do
    it 'cyclic' do
      assert_phrase 'expected a cyclic structure',
        msg(nil).namespace(:reference).not.cyclic
      assert_phrase 'did not expect a cyclic structure but actual has already been visited',
        msg(nil).namespace(:reference).cyclic
    end

    it 'failed_from_cache' do
      assert_phrase 'actual has already failed before',
        msg(nil).namespace(:reference).failed_from_cache
    end
  end

  describe 'set' do
    it 'equal' do
      assert_phrase 'expected object to be an equal set to [1, 2, 3] but got [0, 2, 1]',
        msg([0, 2, 1]).namespace(:set).not.equal([1, 2, 3])
      assert_phrase 'did not expect object to be an equal set to [1, 2, 3] but got [3, 2, 1]',
        msg([3, 2, 1]).namespace(:set).equal([1, 2, 3])
    end
  end
end
