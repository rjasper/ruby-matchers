# frozen_string_literal: true

require 'test_helper'

describe Matcher::BaseMessageBuilder do
  let(:klass) { Matcher::BaseMessageBuilder }

  it 'builds a ErrorMessage' do
    builder = klass.new(false, 42)
    message = builder.hello('World', foo: 'bar')

    assert_kind_of Matcher::ErrorMessage, message
    assert_equal false, message.negated
    assert_equal 42, message.actual
    assert_equal :hello, message.key
    assert_equal ['World'], message.args
    assert_equal({ foo: 'bar' }, message.kwargs)
  end

  describe '#not' do
    it 'negates messages' do
      builder = klass.new(false, 42)

      assert_equal false, builder.my_message.negated
      assert_equal true, builder.not.my_message.negated
    end
  end

  describe '#not_if' do
    it 'conditionally negates messages' do
      builder = klass.new(false, 42)

      assert_equal false, builder.not_if(false).my_message.negated
      assert_equal true, builder.not_if(true).my_message.negated
    end
  end
end
