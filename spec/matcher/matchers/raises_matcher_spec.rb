# frozen_string_literal: true

require "test_helper"

describe Matcher::RaisesMatcher do
  include Matcher::Compatibility

  it "is built by raises" do
    examine = lambda do |block|
      assert_kind_of Matcher::RaisesMatcher, Matcher.build(&block)
    end

    examine.call -> { raises(_.foo, StandardError) }
    examine.call -> { raises(_.foo, StandardError, message: /oops/) }
    examine.call -> { raises(_.foo, message: /oops/) }
    examine.call -> { raises(StandardError, &:foo) }
    examine.call -> { raises(StandardError, message: /oops/, &:foo) }
    examine.call -> { raises(_.foo) ^ StandardError }
    examine.call -> { raises(_.foo, message: /oops/) ^ StandardError }
    examine.call -> { raises(&:foo) ^ StandardError }
    examine.call -> { raises(message: /oops/, &:foo) ^ StandardError }

    err = assert_raises(ArgumentError) do
      Matcher.build { raises }
    end

    assert_equal "neither expression nor block given", err.message

    err = assert_raises(ArgumentError) do
      Matcher.build { raises(_.foo, StandardError, &:foo) }
    end

    assert_equal "both expression and block given", err.message
  end

  it "matches raised exceptions" do
    matcher = Matcher.build { raises(_.fetch(:foo), KeyError) }
    negated = ~matcher

    fetch_foo = expression { _.fetch(:foo) }
    rescue_last_exception = expression { rescue_exception(_.fetch(:foo)) }

    assert matcher.match?({})
    assert_no_errors matcher.match({})
    refute negated.match?({})
    assert_errors negated.match({}),
      rescue_last_exception => "did not expect a kind of KeyError " \
        "but got #<KeyError: key not found: :foo>"

    refute matcher.match?({ foo: 1 })
    assert_errors matcher.match({ foo: 1 }),
      msg({ foo: 1 }).namespace(:expression).not.raising(
        fetch_foo, StandardError, { actual: { foo: 1 } }
      )
    assert negated.match?({ foo: 1 })
    assert_no_errors negated.match({ foo: 1 })

    refute matcher.match?(nil)
    assert_errors matcher.match(nil),
      rescue_last_exception => "expected a kind of KeyError but got " \
        "#<NoMethodError: undefined method #{quote_method(:fetch)} for nil>"
    assert negated.match?(nil)
    assert_no_errors negated.match(nil)
  end

  it "matches raises exception from block" do
    matcher = Matcher.build do
      raises(ZeroDivisionError) { |x| 1 / x }
    end

    assert matcher.match?(0)
    refute matcher.match?(1)
  end

  it "matches raised exceptions with message" do
    matcher = Matcher.build { raises(_.call, message: /something went wrong/) }
    negated = ~matcher
    klass = Class.new do
      def initialize(message)
        @message = message
      end

      def call
        raise @message
      end
    end

    obj = klass.new("something went wrong")
    rescue_message = expression { rescue_exception(_.call).message }

    assert matcher.match?(obj)
    assert_no_errors matcher.match(obj)
    refute negated.match?(obj)
    assert_errors negated.match(obj),
      rescue_message => msg("something went wrong")
        .matching(/something went wrong/)

    obj = klass.new("something else went wrong")

    refute matcher.match?(obj)
    assert_errors matcher.match(obj),
      rescue_message => msg("something else went wrong")
        .not.matching(/something went wrong/)
    assert negated.match?(obj)
    assert_no_errors negated.match(obj)
  end

  it "matches message lazily" do
    my_error_klass = Class.new(StandardError)
    matcher = Matcher.build do
      raises(_.call, my_error_klass, message: /something went wrong/)
    end
    klass = Class.new do
      def initialize(error)
        @error = error
      end

      attr_reader :error

      def call
        raise @error
      end
    end

    obj = klass.new(my_error_klass.new("something went wrong"))

    assert matcher.match?(obj)
    assert_no_errors matcher.match(obj)

    obj = klass.new(my_error_klass.new("something else went wrong"))
    rescue_message = expression { rescue_exception(_.call).message }

    refute matcher.match?(obj)
    assert_errors matcher.match(obj),
      rescue_message => msg("something else went wrong")
        .not.matching(/something went wrong/)

    obj = klass.new(StandardError.new("something else went wrong"))
    rescue_from_call = expression { rescue_exception(_.call) }

    refute matcher.match?(obj)
    assert_errors matcher.match(obj),
      rescue_from_call => msg(obj.error).not.kind_of(my_error_klass)
  end

  it "rescues standard errors" do
    matcher = Matcher.build do
      raises(kernel.raise(_))
    end

    e = assert_raises(Exception) { matcher.match(Exception) }
    assert_instance_of Exception, e

    assert matcher.match?(StandardError)
  end

  it "rescues non-standard exceptions" do
    matcher = Matcher.build do
      raises(kernel.raise(_), rescue: Exception)
    end

    assert matcher.match?(Exception)
  end

  it "#to_s" do
    matcher = Matcher.build { raises(_.foo, StandardError) }

    assert_equal "raises(actual.foo, StandardError)", matcher.to_s
    assert_equal "~raises(actual.foo, StandardError)", matcher.~.to_s
  end
end
