# frozen_string_literal: true

require 'test_helper'

class Matchable
  def =~(_other)
    0
  end

  def !~(_other)
    false
  end

  def to_s
    'matchable'
  end
  alias inspect to_s
end

class Unmatchable
  def =~(_other)
    nil
  end

  def !~(_other)
    true
  end

  def to_s
    'unmatchable'
  end
  alias inspect to_s
end

describe Matcher::ExpressionMatcher do
  it 'is built from ExpressionRecorder' do
    matcher = Matcher.build { _ + 1 }

    assert_kind_of Matcher::ExpressionMatcher, matcher
  end

  it '#match?' do
    matcher = Matcher.build { _ > 5 }
    negated = ~matcher

    assert matcher.match?(10)
    refute negated.match?(10)

    refute matcher.match?(2)
    assert negated.match?(2)
  end

  it 'matches truthy and falsy' do
    assert_errors match(nil) { _ },
      msg(nil).not.truthy
    assert_errors not_match(1) { _ },
      msg(1).truthy
    assert_errors match(1) { !_ },
      msg(1).truthy
    assert_errors not_match(nil) { !_ },
      msg(nil).not.truthy

    assert_errors match(nil, foo: false) { vars[:foo] },
      'expected foo to be truthy but got false'
    assert_errors match(nil, foo: true) { !vars[:foo] },
      'expected foo to be falsy but got true'
  end

  it 'matches same' do
    assert_errors match(1) { _.equal?(2) },
      msg(1).not.same(2)
    assert_errors not_match(1) { _.equal?(1) },
      msg(1).same(1)

    assert_errors match(2) { (_ + 1).equal?(_ * 2) },
      "expected actual + 1 to be same as actual * 2 but got 3 (id=#{3.object_id}) and 4 (id=#{4.object_id}), where actual = 2"
    assert_errors not_match(1) { (_ + 1).equal?(_ * 2) },
      "did not expect actual + 1 to be same as actual * 2 but got 2 (id=#{2.object_id}), where actual = 1"
  end

  it 'matches equal' do
    assert_errors match(1) { _ == 0 },
      msg(1).not.equal(0)
    assert_errors not_match(0) { _ == 0 },
      msg(0).equal(0)

    assert_errors match(0) { _ != 0 },
      msg(0).equal(0)
    assert_errors not_match(1) { _ != 0 },
      msg(1).not.equal(0)

    assert_errors match(7) { _ % 3 == 0 },
      'expected actual % 3 == 0 but got 1 == 0, where actual = 7'
    assert_errors not_match(7) { _ % 3 == 1 },
      'expected actual % 3 != 1 but got 1 != 1, where actual = 7'

    assert_errors not_match(1) { _ * 2 != 0 },
      'expected actual * 2 == 0 but got 2 == 0, where actual = 1'

    # flip
    assert_errors match(1) { expr(0) == _ },
      msg(1).not.equal(0)
    assert_errors match(0) { expr(0) != _ },
      msg(0).equal(0)
  end

  it 'matches comparisons' do
    assert_errors match(0) { _ < 0 },
      msg(0).not.less_than(0)
    assert_errors not_match(-1) { _ < 0 },
      msg(-1).less_than(0)
    assert_errors match(0) { _ > 0 },
      msg(0).not.greater_than(0)
    assert_errors not_match(1) { _ > 0 },
      msg(1).greater_than(0)
    assert_errors match(1) { _ <= 0 },
      msg(1).not.less_than_or_equal(0)
    assert_errors not_match(0) { _ <= 0 },
      msg(0).less_than_or_equal(0)
    assert_errors match(-1) { _ >= 0 },
      msg(-1).not.greater_than_or_equal(0)
    assert_errors not_match(0) { _ >= 0 },
      msg(0).greater_than_or_equal(0)

    assert_errors match(1) { _ * 2 < 0 },
      'expected actual * 2 < 0 but got 2 < 0, where actual = 1'
    assert_errors not_match(-1) { _ * 2 < 0 },
      'expected actual * 2 >= 0 but got -2 >= 0, where actual = -1'
    assert_errors match(-1) { _ * 2 > 0 },
      'expected actual * 2 > 0 but got -2 > 0, where actual = -1'
    assert_errors not_match(1) { _ * 2 > 0 },
      'expected actual * 2 <= 0 but got 2 <= 0, where actual = 1'
    assert_errors match(1) { _ * 2 <= 0 },
      'expected actual * 2 <= 0 but got 2 <= 0, where actual = 1'
    assert_errors not_match(-1) { _ * 2 <= 0 },
      'expected actual * 2 > 0 but got -2 > 0, where actual = -1'
    assert_errors match(-1) { _ * 2 >= 0 },
      'expected actual * 2 >= 0 but got -2 >= 0, where actual = -1'
    assert_errors not_match(1) { _ * 2 >= 0 },
      'expected actual * 2 < 0 but got 2 < 0, where actual = 1'

    # flip
    assert_errors match(-1) { expr(0) < _ },
      msg(-1).not.greater_than(0)
    assert_errors match(1) { expr(0) > _ },
      msg(1).not.less_than(0)
    assert_errors match(-1) { expr(0) <= _ },
      msg(-1).not.greater_than_or_equal(0)
    assert_errors match(1) { expr(0) >= _ },
      msg(1).not.less_than_or_equal(0)
  end

  it 'matches comparable to' do
    assert_errors match(Set[2]) { _ <=> Set[1] },
      msg(Set[2]).not.comparable_to(Set[1])
    assert_errors not_match(Set[1, 2]) { _ <=> Set[1] },
      msg(Set[1, 2]).comparable_to(Set[1])

    assert_errors match([2]) { _.to_set <=> Set[1] },
      'expected actual.to_set to be comparable to #<Set: {1}> but got #<Set: {2}>, where actual = [2]'
    assert_errors not_match([1, 2]) { _.to_set <=> Set[1] },
      'did not expect actual.to_set to be comparable to #<Set: {1}> but got #<Set: {1, 2}>, where actual = [1, 2]'
  end

  it 'matches between expressions' do
    assert_no_errors match(5) { _.between?(0, 10) }
    assert_errors not_match(5) { _.between?(0, 10) },
      msg(5).between(0, 10)
    assert_errors match(15) { _.between?(0, 10) },
      msg(15).not.between(0, 10)
    assert_no_errors not_match(15) { _.between?(0, 10) }

    assert_errors match(15) { (_ * 2).between?(0, 10) },
      'expected actual * 2 to be between 0 and 10 but got 30, where actual = 15'

    assert_no_errors match(5) { (_ * 2).between?(0, 20) }
    assert_errors not_match(5) { (_ * 2).between?(0, 20) },
      'did not expect actual * 2 to be between 0 and 20 but got 10, where actual = 5'
    assert_errors match(15) { (_ * 2).between?(0, 20) },
      'expected actual * 2 to be between 0 and 20 but got 30, where actual = 15'
    assert_no_errors not_match(15) { (_ * 2).between?(0, 20) }

    assert_errors match(15) { lo { (_ >= 0) & (_ <= 10) } },
      msg(15).not.between(0, 10)
    assert_errors match(15) { lo { (_ * 2 >= 0) & (_ * 2 <= 10) } },
      'expected actual * 2 to be between 0 and 10 but got 30, where actual = 15'
  end

  it 'matches length expressions' do
    assert_errors match([1]) { _.length == 2 },
      msg([1]).not.length_of(2, 1)
    assert_errors not_match([1]) { _.length == 1 },
      msg([1]).length_of(1, 1)

    assert_errors match([1, 2]) { (_ + [3]).length == 2 },
      'expected actual + [3] to have length of 2 but was 3, where actual = [1, 2]'
    assert_errors not_match([1, 2]) { (_ + [3]).length == 3 },
      'did not expect actual + [3] to have length of 3, where actual = [1, 2]'
  end

  it 'matches having key' do
    assert_errors match({}) { _.key?(:foo) },
      msg({}).not.having_key(:foo)
    assert_errors not_match({ foo: true }) { _.key?(:foo) },
      msg({ foo: true }).having_key(:foo)

    assert_errors match([]) { _.to_h.key?(:foo) },
      'expected actual.to_h to include key :foo but got {}, where actual = []'
    assert_errors not_match([[:foo, true]]) { _.to_h.key?(:foo) },
      "did not expect actual.to_h to include key :foo but got #{{ foo: true }}, where actual = [[:foo, true]]"
  end

  it 'matches including' do
    assert_errors match([]) { _.include?(1) },
      msg([]).not.including(1)
    assert_errors not_match([1]) { _.include?(1) },
      msg([1]).including(1)

    assert_errors match([0, 1, 2]) { _[0..1].include?(4) },
      'expected actual[0..1] to include 4 but got [0, 1], where actual = [0, 1, 2]'
    assert_errors not_match([0, 1, 2]) { _[0..1].include?(1) },
      'did not expect actual[0..1] to include 1 but got [0, 1], where actual = [0, 1, 2]'

    foo_in = String.new('foo')
    def foo_in.in?(collection)
      collection.include?(self)
    end

    assert_errors match([]) { expr(foo_in).in?(_) },
      msg([]).not.including("foo")
    assert_errors not_match(['foo']) { expr(foo_in).in?(_) },
      msg(['foo']).including("foo")
  end

  it 'matches in' do
    foo_in = String.new('foo')
    def foo_in.in?(collection)
      collection.include?(self)
    end

    assert_errors match(foo_in) { _.in?(['bar']) },
      msg('foo').not.in(['bar'])
    assert_errors not_match(foo_in) { _.in?(['foo']) },
      msg('foo').in(['foo'])

    assert_errors match(foo_in) { _.itself.in?(['bar']) },
      'expected actual.itself to be included in ["bar"] but got "foo", where actual = "foo"'
    assert_errors not_match(foo_in) { _.itself.in?(['foo']) },
      'did not expect actual.itself to be included in ["foo"] but got "foo", where actual = "foo"'

    # flip
    assert_errors match(foo_in) { expr(['bar']).include?(_) },
      msg('foo').not.in(['bar'])
    assert_errors not_match(foo_in) { expr(['foo']).include?(_) },
      msg('foo').in(['foo'])
  end

  it 'matches regexp' do
    assert_errors match('Hi!') { _ =~ /Hello/ },
      msg('Hi!').not.matching(/Hello/)
    assert_errors not_match('Hello World!') { _ =~ /Hello/ },
      msg('Hello World!').matching(/Hello/)
    assert_errors match('Hello World!') { _ !~ /Hello/ },
      msg('Hello World!').matching(/Hello/)
    assert_errors not_match('Hi!') { _ !~ /Hello/ },
      msg('Hi!').not.matching(/Hello/)

    assert_errors match('Hi!') { _.downcase =~ /hello/ },
      'expected actual.downcase to match /hello/ but got "hi!", where actual = "Hi!"'
    assert_errors match('Hi!') { expr(/hello/) =~ _.downcase },
      'expected actual.downcase to match /hello/ but got "hi!", where actual = "Hi!"'
    assert_errors not_match('Hello World!') { _.downcase =~ /hello/ },
      'did not expect actual.downcase to match /hello/ but got "hello world!", where actual = "Hello World!"'
    assert_errors match('Hello World!') { _.downcase !~ /hello/ },
      'did not expect actual.downcase to match /hello/ but got "hello world!", where actual = "Hello World!"'
    assert_errors not_match('Hi!') { _.downcase !~ /hello/ },
      'expected actual.downcase to match /hello/ but got "hi!", where actual = "Hi!"'

    assert_errors match(Unmatchable.new) { _.itself =~ 'foo' },
      'expected actual.itself =~ "foo" to be truthy but got nil, where actual = unmatchable'
    assert_errors not_match(Unmatchable.new) { _.itself !~ 'foo' },
      'expected actual.itself !~ "foo" to be falsy but got true, where actual = unmatchable'
    assert_errors match(Matchable.new) { _.itself !~ 'foo' },
      'expected actual.itself !~ "foo" to be truthy but got false, where actual = matchable'
    assert_errors not_match(Matchable.new) { _.itself =~ 'foo' },
      'expected actual.itself =~ "foo" to be falsy but got 0, where actual = matchable'
  end

  it 'matches regexp at' do
    assert_errors match('abcd') { (_ =~ /b/) == 2 },
      'expected actual to match /b/ at 2 but was at 1 for "abcd"'
    assert_errors match('abcd') { (_ =~ /b/) != 1 },
      'expected actual to match /b/ not at 1 for "abcd"'
    assert_errors match('abcd') { (_ =~ /b/) > 2 },
      'expected actual to match /b/ after 2 but was at 1 for "abcd"'
    assert_errors match('abcd') { (_ =~ /b/) < 1 },
      'expected actual to match /b/ before 1 but was at 1 for "abcd"'
    assert_errors match('abcd') { (_ =~ /b/) <= 0 },
      'expected actual to match /b/ at or before 0 but was at 1 for "abcd"'
    assert_errors match('abcd') { (_ =~ /b/) >= 2 },
      'expected actual to match /b/ at or after 2 but was at 1 for "abcd"'

    assert_errors not_match('abcd') { (_ =~ /b/) == 1 },
      'did not expect actual to match /b/ at 1 for "abcd"'
    assert_errors not_match('abcd') { (_ =~ /b/) != 2 },
      'did not expect actual to match /b/ not at 2 but was at 1 for "abcd"'
    assert_errors not_match('abcd') { (_ =~ /b/) > 0 },
      'did not expect actual to match /b/ after 0 but was at 1 for "abcd"'
    assert_errors not_match('abcd') { (_ =~ /b/) < 2 },
      'did not expect actual to match /b/ before 2 but was at 1 for "abcd"'
    assert_errors not_match('abcd') { (_ =~ /b/) <= 2 },
      'did not expect actual to match /b/ at or before 2 but was at 1 for "abcd"'
    assert_errors not_match('abcd') { (_ =~ /b/) >= 1 },
      'did not expect actual to match /b/ at or after 1 but was at 1 for "abcd"'

    assert_errors match(Unmatchable.new) { (_.itself =~ 'foo') == 1 },
      'expected (actual.itself =~ "foo") == 1 to be truthy but got false, where actual = unmatchable'
  end

  it 'matches instance_of' do
    assert_errors match('string') { _.instance_of?(Integer) },
      msg('string').not.instance_of(Integer)
    assert_errors not_match(1) { _.instance_of?(Integer) },
      msg(1).instance_of(Integer)

    assert_errors match(0.0) { (_ + 1).instance_of?(Integer) },
      'expected actual + 1 to be an instance of Integer but got 1.0, where actual = 0.0'
    assert_errors not_match(0) { (_ + 1).instance_of?(Integer) },
      'did not expect actual + 1 to be an instance of Integer but got 1, where actual = 0'

    assert_errors match('string') { _.class == Integer },
      msg('string').not.instance_of(Integer)
    assert_errors match('string') { expr(Integer) == _.class },
      msg('string').not.instance_of(Integer)
  end

  it 'matches kind_of' do
    assert_errors match('string') { _.kind_of?(Numeric) },
      msg('string').not.kind_of(Numeric)
    assert_errors not_match(1) { _.kind_of?(Numeric) },
      msg(1).kind_of(Numeric)
    assert_errors match('string') { _.is_a?(Numeric) },
      msg('string').not.kind_of(Numeric)
    assert_errors not_match(1) { _.is_a?(Numeric) },
      msg(1).kind_of(Numeric)

    assert_errors match(1.0) { (_ + 1).kind_of?(Integer) },
      'expected actual + 1 to be a kind of Integer but got 2.0, where actual = 1.0'
    assert_errors not_match(1) { (_ + 1).kind_of?(Integer) },
      'did not expect actual + 1 to be a kind of Integer but got 2, where actual = 1'
    assert_errors match(1.0) { (_ + 1).is_a?(Integer) },
      'expected actual + 1 to be a kind of Integer but got 2.0, where actual = 1.0'
    assert_errors not_match(1) { (_ + 1).is_a?(Integer) },
      'did not expect actual + 1 to be a kind of Integer but got 2, where actual = 1'
  end

  it 'matches responding_to' do
    assert_errors match(nil) { _.respond_to?(:+) },
      msg(nil).not.responding_to(:+)
    assert_errors not_match(1) { _.respond_to?(:+) },
      msg(1).responding_to(:+)

    assert_errors match('a') { (_ * 2).respond_to?(:**) },
      "expected actual * 2 to respond to `**' but got \"aa\", where actual = \"a\""
    assert_errors not_match(1) { (_ * 2).respond_to?(:**) },
      "did not expect actual * 2 to respond to `**' but got 2, where actual = 1"
  end

  it 'matches predicate' do
    assert_errors match(1) { _.even? },
      msg(1).not.predicate(:even?)
    assert_errors not_match(2) { _.even? },
      msg(2).predicate(:even?)

    assert_errors match(6) { (_ / 2).even? },
      'expected actual / 2 to be even but got 3, where actual = 6'
    assert_errors not_match(8) { (_ / 2).even? },
      'did not expect actual / 2 to be even but got 4, where actual = 8'
  end

  it 'matches unrecognized expressions' do
    assert_errors match([nil]) { _.first },
      'expected actual.first to be truthy but got nil, where actual = [nil]'
  end

  it 'handles exceptions' do
    matcher = Matcher.build { (expr(1) / _).is_a?(Integer) }

    assert_errors matcher.match(0),
      'did not expect 1 / actual to raise ZeroDivisionError, where actual = 0: divided by 0'

    assert_no_errors (~matcher).match(0)
  end

  it '#to_s' do
    matcher = Matcher.build { _ * 3 > 9 }

    assert_equal 'actual * 3 > 9', matcher.to_s
    assert_equal 'neg(actual * 3 > 9)', (~matcher).to_s
  end

  private

  def match(actual, **, &)
    Matcher.build(&).match(actual, **)
  end

  def not_match(actual, &)
    matcher = ~Matcher.build(&)
    matcher.match(actual)
  end
end
