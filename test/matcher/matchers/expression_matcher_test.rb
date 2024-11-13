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
  it 'evaluates expressions' do
    refute_predicate match(2) { _ > 2 }, :valid?
    assert_no_errors match(3) { _.odd? }
    assert_no_errors match(3) { _ + _ * 2 == 9 }
    assert_no_errors match('Hello World') { _.upcase.gsub(' ', '_') == 'HELLO_WORLD' }

    assert_no_errors not_match(4) { _.odd? }
    refute_predicate not_match(5) { _.odd? }, :valid?
  end

  it 'matches truthy and falsy' do
    assert_expected_errors match(nil) { _ },
      'expected a truthy value but got nil'
    assert_expected_errors not_match(1) { _ },
      'expected a falsy value but got 1'
    assert_expected_errors match(1) { !_ },
      'expected a falsy value but got 1'
    assert_expected_errors not_match(nil) { !_ },
      'expected a truthy value but got nil'

    assert_expected_errors Matcher.build { vars[:foo] }.match(nil, foo: false),
      'expected foo to be truthy but got false'
    assert_expected_errors Matcher.build { !vars[:foo] }.match(nil, foo: true),
      'expected foo to be falsy but got true'
  end

  it 'matches same' do
    assert_expected_errors match(1) { _.equal?(2) },
      "expected same as 2 (id=#{2.object_id}) but got 1 (id=#{1.object_id})"
    assert_expected_errors not_match(1) { _.equal?(1) },
      "did not expect same as 1 (id=#{1.object_id})"

    assert_expected_errors match(2) { (_ + 1).equal?(_ * 2) },
      'expected _ + 1 to be same as _ * 2 but got 3 (id=7) and 4 (id=9), where _ = 2'
    assert_expected_errors not_match(1) { (_ + 1).equal?(_ * 2) },
      'did not expect _ + 1 to be same as _ * 2 but got 2 (id=5), where _ = 1'
  end

  it 'matches equal' do
    assert_expected_errors match(1) { _ == 0 },
      'expected 0 but got 1'
    assert_expected_errors not_match(0) { _ == 0 },
      'did not expect 0'

    assert_expected_errors match(0) { _ != 0 },
      'did not expect 0'
    assert_expected_errors not_match(1) { _ != 0 },
      'expected 0 but got 1'

    assert_expected_errors match(7) { _ % 3 == 0 },
      'expected _ % 3 == 0 but got 1 == 0, where _ = 7'
    assert_expected_errors not_match(7) { _ % 3 == 1 },
      'expected _ % 3 != 1 but got 1 != 1, where _ = 7'

    assert_expected_errors not_match(1) { _ * 2 != 0 },
      'expected _ * 2 == 0 but got 2 == 0, where _ = 1'

    # flip
    assert_expected_errors match(1) { expr(0) == _ },
      'expected 0 but got 1'
    assert_expected_errors match(0) { expr(0) != _ },
      'did not expect 0'
  end

  it 'matches comparisons' do
    assert_expected_errors match(0) { _ < 0 },
      'expected a value < 0 but got 0'
    assert_expected_errors not_match(-1) { _ < 0 },
      'expected a value >= 0 but got -1'
    assert_expected_errors match(0) { _ > 0 },
      'expected a value > 0 but got 0'
    assert_expected_errors not_match(1) { _ > 0 },
      'expected a value <= 0 but got 1'
    assert_expected_errors match(1) { _ <= 0 },
      'expected a value <= 0 but got 1'
    assert_expected_errors not_match(0) { _ <= 0 },
      'expected a value > 0 but got 0'
    assert_expected_errors match(-1) { _ >= 0 },
      'expected a value >= 0 but got -1'
    assert_expected_errors not_match(0) { _ >= 0 },
      'expected a value < 0 but got 0'

    assert_expected_errors match(1) { _ * 2 < 0 },
      'expected _ * 2 < 0 but got 2 < 0, where _ = 1'
    assert_expected_errors not_match(-1) { _ * 2 < 0 },
      'expected _ * 2 >= 0 but got -2 >= 0, where _ = -1'
    assert_expected_errors match(-1) { _ * 2 > 0 },
      'expected _ * 2 > 0 but got -2 > 0, where _ = -1'
    assert_expected_errors not_match(1) { _ * 2 > 0 },
      'expected _ * 2 <= 0 but got 2 <= 0, where _ = 1'
    assert_expected_errors match(1) { _ * 2 <= 0 },
      'expected _ * 2 <= 0 but got 2 <= 0, where _ = 1'
    assert_expected_errors not_match(-1) { _ * 2 <= 0 },
      'expected _ * 2 > 0 but got -2 > 0, where _ = -1'
    assert_expected_errors match(-1) { _ * 2 >= 0 },
      'expected _ * 2 >= 0 but got -2 >= 0, where _ = -1'
    assert_expected_errors not_match(1) { _ * 2 >= 0 },
      'expected _ * 2 < 0 but got 2 < 0, where _ = 1'

    # flip
    assert_expected_errors match(-1) { expr(0) < _ },
      'expected a value > 0 but got -1'
    assert_expected_errors match(1) { expr(0) > _ },
      'expected a value < 0 but got 1'
    assert_expected_errors match(-1) { expr(0) <= _ },
      'expected a value >= 0 but got -1'
    assert_expected_errors match(1) { expr(0) >= _ },
      'expected a value <= 0 but got 1'
  end

  it 'matches comparable to' do
    assert_expected_errors match(Set[2]) { _ <=> Set[1] },
      'expected a value comparable to #<Set: {1}> but got #<Set: {2}>'
    assert_expected_errors not_match(Set[1, 2]) { _ <=> Set[1] },
      'did not expect a value comparable to #<Set: {1}> but got #<Set: {1, 2}>'

    assert_expected_errors match([2]) { _.to_set <=> Set[1] },
      'expected _.to_set to be comparable to #<Set: {1}> but got #<Set: {2}>, where _ = [2]'
    assert_expected_errors not_match([1, 2]) { _.to_set <=> Set[1] },
      'did not expect _.to_set to be comparable to #<Set: {1}> but got #<Set: {1, 2}>, where _ = [1, 2]'
  end

  it 'matches between expressions' do
    assert_expected_errors match(15) { _.between?(0, 10) },
      'expected value to be between 0 and 10 but got 15'
    assert_expected_errors match(15) { lo { (_ >= 0) & (_ <= 10) } },
      'expected value to be between 0 and 10 but got 15'
    assert_expected_errors match(15) { (_ * 2).between?(0, 10) },
      'expected _ * 2 to be between 0 and 10 but got 30, where _ = 15'
    assert_expected_errors match(15) { lo { (_ * 2 >= 0) & (_ * 2 <= 10) } },
      'expected _ * 2 to be between 0 and 10 but got 30, where _ = 15'
  end

  it 'matches length expressions' do
    assert_expected_errors match([1]) { _.length == 2 },
      'expected length of 2 but was 1'
    assert_expected_errors not_match([1]) { _.length == 1 },
      'did not expect length of 1'

    assert_expected_errors match([1, 2]) { (_ + [3]).length == 2 },
      'expected _ + [3] to have length of 2 but was 3, where _ = [1, 2]'
    assert_expected_errors not_match([1, 2]) { (_ + [3]).length == 3 },
      'did not expect _ + [3] to have length of 3, where _ = [1, 2]'
  end

  it 'matches having key' do
    assert_expected_errors match({}) { _.key?(:foo) },
      'expected to include key :foo but got {}'
    assert_expected_errors not_match({ foo: true }) { _.key?(:foo) },
      'did not expect to include key :foo but got {:foo=>true}'

    assert_expected_errors match([]) { _.to_h.key?(:foo) },
      'expected _.to_h to include key :foo but got {}, where _ = []'
    assert_expected_errors not_match([[:foo, true]]) { _.to_h.key?(:foo) },
      'did not expect _.to_h to include key :foo but got {:foo=>true}, where _ = [[:foo, true]]'
  end

  it 'matches including' do
    assert_expected_errors match([]) { _.include?(1) },
      'expected 1 to be included but got []'
    assert_expected_errors not_match([1]) { _.include?(1) },
      'did not expect 1 to be included but got [1]'

    assert_expected_errors match([0, 1, 2]) { _[0..1].include?(4) },
      'expected _[0..1] to include 4 but got [0, 1], where _ = [0, 1, 2]'
    assert_expected_errors not_match([0, 1, 2]) { _[0..1].include?(1) },
      'did not expect _[0..1] to include 1 but got [0, 1], where _ = [0, 1, 2]'

    foo_in = String.new('foo')
    def foo_in.in?(collection)
      collection.include?(self)
    end

    assert_expected_errors match([]) { expr(foo_in).in?(_) },
      'expected "foo" to be included but got []'
    assert_expected_errors not_match(['foo']) { expr(foo_in).in?(_) },
      'did not expect "foo" to be included but got ["foo"]'
  end

  it 'matches in' do
    foo_in = String.new('foo')
    def foo_in.in?(collection)
      collection.include?(self)
    end

    assert_expected_errors match(foo_in) { _.in?(['bar']) },
      'expected object to be included in ["bar"] but got "foo"'
    assert_expected_errors not_match(foo_in) { _.in?(['foo']) },
      'did not expect object to be included in ["foo"] but got "foo"'

    assert_expected_errors match(foo_in) { _.itself.in?(['bar']) },
      'expected _.itself to be included in ["bar"] but got "foo", where _ = "foo"'
    assert_expected_errors not_match(foo_in) { _.itself.in?(['foo']) },
      'did not expect _.itself to be included in ["foo"] but got "foo", where _ = "foo"'

    # flip
    assert_expected_errors match(foo_in) { expr(['bar']).include?(_) },
      'expected object to be included in ["bar"] but got "foo"'
    assert_expected_errors not_match(foo_in) { expr(['foo']).include?(_) },
      'did not expect object to be included in ["foo"] but got "foo"'
  end

  it 'matches regexp' do
    assert_expected_errors match('Hi!') { _ =~ /Hello/ },
      'expected value to match /Hello/ but got "Hi!"'
    assert_expected_errors not_match('Hello World!') { _ =~ /Hello/ },
      'did not expect value to match /Hello/ but got "Hello World!"'
    assert_expected_errors match('Hello World!') { _ !~ /Hello/ },
      'did not expect value to match /Hello/ but got "Hello World!"'
    assert_expected_errors not_match('Hi!') { _ !~ /Hello/ },
      'expected value to match /Hello/ but got "Hi!"'

    assert_expected_errors match('Hi!') { _.downcase =~ /hello/ },
      'expected _.downcase to match /hello/ but got "hi!", where _ = "Hi!"'
    assert_expected_errors match('Hi!') { expr(/hello/) =~ _.downcase },
      'expected _.downcase to match /hello/ but got "hi!", where _ = "Hi!"'
    assert_expected_errors not_match('Hello World!') { _.downcase =~ /hello/ },
      'did not expect _.downcase to match /hello/ but got "hello world!", where _ = "Hello World!"'
    assert_expected_errors match('Hello World!') { _.downcase !~ /hello/ },
      'did not expect _.downcase to match /hello/ but got "hello world!", where _ = "Hello World!"'
    assert_expected_errors not_match('Hi!') { _.downcase !~ /hello/ },
      'expected _.downcase to match /hello/ but got "hi!", where _ = "Hi!"'

    assert_expected_errors match(Unmatchable.new) { _.itself =~ 'foo' },
      'expected _.itself =~ "foo" to be truthy but got nil, where _ = unmatchable'
    assert_expected_errors not_match(Unmatchable.new) { _.itself !~ 'foo' },
      'expected _.itself !~ "foo" to be falsy but got true, where _ = unmatchable'
    assert_expected_errors match(Matchable.new) { _.itself !~ 'foo' },
      'expected _.itself !~ "foo" to be truthy but got false, where _ = matchable'
    assert_expected_errors not_match(Matchable.new) { _.itself =~ 'foo' },
      'expected _.itself =~ "foo" to be falsy but got 0, where _ = matchable'
  end

  it 'matches regexp at' do
    assert_expected_errors match('abcd') { (_ =~ /b/) == 2 },
      'expected _ to match /b/ at 2 but was at 1 for "abcd"'
    assert_expected_errors match('abcd') { (_ =~ /b/) != 1 },
      'expected _ to match /b/ not at 1 for "abcd"'
    assert_expected_errors match('abcd') { (_ =~ /b/) > 2 },
      'expected _ to match /b/ after 2 but was at 1 for "abcd"'
    assert_expected_errors match('abcd') { (_ =~ /b/) < 1 },
      'expected _ to match /b/ before 1 but was at 1 for "abcd"'
    assert_expected_errors match('abcd') { (_ =~ /b/) <= 0 },
      'expected _ to match /b/ at or before 0 but was at 1 for "abcd"'
    assert_expected_errors match('abcd') { (_ =~ /b/) >= 2 },
      'expected _ to match /b/ at or after 2 but was at 1 for "abcd"'

    assert_expected_errors not_match('abcd') { (_ =~ /b/) == 1 },
      'did not expect _ to match /b/ at 1 for "abcd"'
    assert_expected_errors not_match('abcd') { (_ =~ /b/) != 2 },
      'did not expect _ to match /b/ not at 2 but was at 1 for "abcd"'
    assert_expected_errors not_match('abcd') { (_ =~ /b/) > 0 },
      'did not expect _ to match /b/ after 0 but was at 1 for "abcd"'
    assert_expected_errors not_match('abcd') { (_ =~ /b/) < 2 },
      'did not expect _ to match /b/ before 2 but was at 1 for "abcd"'
    assert_expected_errors not_match('abcd') { (_ =~ /b/) <= 2 },
      'did not expect _ to match /b/ at or before 2 but was at 1 for "abcd"'
    assert_expected_errors not_match('abcd') { (_ =~ /b/) >= 1 },
      'did not expect _ to match /b/ at or after 1 but was at 1 for "abcd"'

    assert_expected_errors match(Unmatchable.new) { (_.itself =~ 'foo') == 1 },
      'expected (_.itself =~ "foo") == 1 to be truthy but got false, where _ = unmatchable'
  end

  it 'matches instance_of' do
    assert_expected_errors match('string') { _.instance_of?(Integer) },
      'expected an instance of Integer but got "string"'
    assert_expected_errors not_match(1) { _.instance_of?(Integer) },
      'did not expect an instance of Integer but got 1'

    assert_expected_errors match(0.0) { (_ + 1).instance_of?(Integer) },
      'expected _ + 1 to be an instance of Integer but got 1.0, where _ = 0.0'
    assert_expected_errors not_match(0) { (_ + 1).instance_of?(Integer) },
      'did not expect _ + 1 to be an instance of Integer but got 1, where _ = 0'

    assert_expected_errors match('string') { _.class == Integer },
      'expected an instance of Integer but got "string"'
    assert_expected_errors match('string') { expr(Integer) == _.class },
      'expected an instance of Integer but got "string"'
  end

  it 'matches kind_of' do
    assert_expected_errors match('string') { _.kind_of?(Numeric) },
      'expected a kind of Numeric but got "string"'
    assert_expected_errors not_match(1) { _.kind_of?(Numeric) },
      'did not expect a kind of Numeric but got 1'
    assert_expected_errors match('string') { _.is_a?(Numeric) },
      'expected a kind of Numeric but got "string"'
    assert_expected_errors not_match(1) { _.is_a?(Numeric) },
      'did not expect a kind of Numeric but got 1'

    assert_expected_errors match(1.0) { (_ + 1).kind_of?(Integer) },
      'expected _ + 1 to be a kind of Integer but got 2.0, where _ = 1.0'
    assert_expected_errors not_match(1) { (_ + 1).kind_of?(Integer) },
      'did not expect _ + 1 to be a kind of Integer but got 2, where _ = 1'
    assert_expected_errors match(1.0) { (_ + 1).is_a?(Integer) },
      'expected _ + 1 to be a kind of Integer but got 2.0, where _ = 1.0'
    assert_expected_errors not_match(1) { (_ + 1).is_a?(Integer) },
      'did not expect _ + 1 to be a kind of Integer but got 2, where _ = 1'
  end

  it 'matches responding_to' do
    assert_expected_errors match(nil) { _.respond_to?(:+) },
      "expected an object responding to `+' but got nil"
    assert_expected_errors not_match(1) { _.respond_to?(:+) },
      "did not expect an object responding to `+' but got 1"

    assert_expected_errors match('a') { (_ * 2).respond_to?(:**) },
      "expected _ * 2 to respond to `**' but got \"aa\", where _ = \"a\""
    assert_expected_errors not_match(1) { (_ * 2).respond_to?(:**) },
      "did not expect _ * 2 to respond to `**' but got 2, where _ = 1"
  end

  it 'matches predicate' do
    assert_expected_errors match(1) { _.even? },
      'expected value to be even but got 1'
    assert_expected_errors not_match(2) { _.even? },
      'did not expect value to be even but got 2'

    assert_expected_errors match(6) { (_ / 2).even? },
      'expected _ / 2 to be even but got 3, where _ = 6'
    assert_expected_errors not_match(8) { (_ / 2).even? },
      'did not expect _ / 2 to be even but got 4, where _ = 8'
  end

  it 'matches unrecognized expressions' do
    assert_expected_errors match([nil]) { _.first },
      'expected _.first to be truthy but got nil, where _ = [nil]'
  end

  it 'handles exceptions' do
    matcher = Matcher.build { (expr(1) / _).is_a?(Integer) }

    assert_expected_errors matcher.match(0),
      'did not expect 1 / _ to raise ZeroDivisionError, where _ = 0: divided by 0'

    assert_no_errors (~matcher).match(0)
  end

  it '#to_s' do
    matcher = Matcher.build { _ * 3 > 9 }

    assert_equal '_ * 3 > 9', matcher.to_s
    assert_equal 'neg(_ * 3 > 9)', (~matcher).to_s
  end
end
