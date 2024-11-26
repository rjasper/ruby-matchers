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
    assert_equal [:receiver], receiver.path.to_a
  end

  it '#args' do
    arg = mapping.args[0]

    assert_kind_of Matcher::AstMapping, arg
    assert_equal [0, :args], arg.path.to_a
  end

  it '#kwargs' do
    kwarg = mapping.kwargs[:foo]

    assert_kind_of Matcher::AstMapping, kwarg
    assert_equal %i[foo kwargs], kwarg.path.to_a
  end
end
