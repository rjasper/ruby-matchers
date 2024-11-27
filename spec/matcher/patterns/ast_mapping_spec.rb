# frozen_string_literal: true

require 'test_helper'

describe Matcher::AstMapping do
  let(:mapping) { Matcher::AstMapping.new }

  it 'empty' do
    assert_equal [], mapping.path.to_a
  end

  it '#receiver' do
    receiver = mapping.receiver

    assert_kind_of Matcher::AstMapping, receiver
    assert_equal [Matcher::AstMapping::RECEIVER], receiver.path.to_a
  end

  it '#args' do
    arg = mapping.args[0]

    assert_kind_of Matcher::AstMapping, arg
    assert_equal [0, Matcher::AstMapping::ARGS], arg.path.to_a
  end

  it '#kwargs' do
    kwarg = mapping.kwargs[:foo]

    assert_kind_of Matcher::AstMapping, kwarg
    assert_equal [:foo, Matcher::AstMapping::KWARGS], kwarg.path.to_a
  end
end
