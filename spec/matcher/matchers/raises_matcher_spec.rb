# frozen_string_literal: true

require 'test_helper'

describe Matcher::RaisesMatcher do
  it 'is built by raises' do
    kind = Matcher::RaisesMatcher

    assert_instance_of(kind, Matcher.build { raises(_.foo, StandardError) })
    assert_instance_of(kind, Matcher.build { raises(StandardError, &:foo) })
    assert_instance_of(kind, Matcher.build { raises(_.foo) ^ StandardError })
    assert_instance_of(kind, Matcher.build { raises(&:foo) ^ StandardError })

    err = assert_raises(ArgumentError) do
      Matcher.build { raises }
    end

    assert_equal 'neither expression nor block given', err.message

    err = assert_raises(ArgumentError) do
      Matcher.build { raises(_.foo, StandardError, &:foo) }
    end

    assert_equal 'both expression and block given', err.message
  end

  it 'matches raised exceptions' do
    matcher = Matcher.build { raises(_.fetch(:foo), KeyError) }
    negated = ~matcher

    fetch_foo = expression { _.fetch(:foo) }
    rescue_last_exception = expression { rescue_exception(_.fetch(:foo)) }

    assert_no_errors matcher.match({})
    assert_errors negated.match({}),
      rescue_last_exception => 'did not expect a kind of KeyError but got #<KeyError: key not found: :foo>'

    assert_errors matcher.match({ foo: 1 }),
      msg({ foo: 1 }).namespace(:expression).not.raising(fetch_foo, StandardError, { actual: { foo: 1 } })
    assert_no_errors negated.match({ foo: 1 })

    assert_errors matcher.match(nil),
      rescue_last_exception => "expected a kind of KeyError but got #<NoMethodError: undefined method `fetch' for nil>"
    assert_no_errors negated.match(nil)
  end

  it '#to_s' do
    matcher = Matcher.build { raises(_.foo, StandardError) }

    assert_equal 'raises(_.foo, StandardError)', matcher.to_s
    assert_equal '~raises(_.foo, StandardError)', matcher.~.to_s
  end
end
