# frozen_string_literal: true

require "test_helper"

describe Matcher::NamespacedMessageBuilder do
  it "produces messages in a namespace" do
    builder = Matcher::NamespacedMessageBuilder.new(false, 1, :my_realm)

    message = builder.hello("world", from: "aliens")

    refute builder.hello.negated
    assert_equal %i[my_realm hello], message.key
    assert_equal ["world"], message.args
    assert_equal({ from: "aliens" }, message.kwargs)
  end

  it "#not" do
    builder = Matcher::NamespacedMessageBuilder.new(false, 1, :my_realm).not

    assert_kind_of Matcher::NamespacedMessageBuilder, builder
    assert builder.hello.negated
  end
end
