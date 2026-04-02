# frozen_string_literal: true

require "test_helper"

describe Matcher::MessageRule do
  let(:matcher) do
    Matcher::Base.new
  end

  let(:pattern) do
    Matcher::Pattern.build { hole(:a) + hole(:b) }
  end

  let(:exp) do
    expression { _ + vars[:foo] * 2 }
  end

  let(:match) do
    pattern.match(exp)
  end

  describe "#apply" do
    it "creates a working MessageFactory" do
      block = proc { |v, e| Matcher::Message.new(:test, false, nil, v, e) }
      message_rule = Matcher::MessageRule.new([pattern], block)

      factory = message_rule.apply(match)

      assert_kind_of Matcher::MessageFactory, factory
      assert_kind_of Matcher::Message,
        factory.create(matcher, exp.evaluate_tree(actual: 2, foo: 3))
    end

    it "works with block arity == 1" do
      block = proc { |v| Matcher::Message.new(:test, false, nil, v) }
      message_rule = Matcher::MessageRule.new([pattern], block)

      factory = message_rule.apply(match)

      assert_kind_of Matcher::MessageFactory, factory
      assert_kind_of Matcher::Message,
        factory.create(matcher, exp.evaluate_tree(actual: 2, foo: 3))
    end
  end
end
