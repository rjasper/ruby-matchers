# frozen_string_literal: true

require 'test_helper'

describe Matcher::OnceBefore do
  it 'adds a one-time action before method' do
    my_class = Class.new do
      extend Matcher::OnceBefore

      def initialize
        @list = []
      end

      attr_reader :list

      def foo
        @list << 'foo'
      end

      once_before :foo do
        @list << 'bar'
      end
    end

    obj = my_class.new

    assert_equal [], obj.list

    obj.foo

    assert_equal %w[bar foo], obj.list

    obj.foo

    assert_equal %w[bar foo foo], obj.list

    other_obj = my_class.new
    other_obj.foo

    assert_equal %w[foo], other_obj.list
  end
end
