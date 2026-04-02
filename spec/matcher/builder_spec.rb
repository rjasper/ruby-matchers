# frozen_string_literal: true

require "test_helper"

describe Matcher::Builder do
  it "#outside" do
    my_klass = Class.new do
      def initialize
        @foo = "foo"
      end

      def bar
        "bar"
      end

      def build_matcher
        Matcher.build do
          [outside { @foo }, outside.bar]
        end
      end
    end

    matcher = my_klass.new.build_matcher

    assert_no_errors matcher.match(["foo", "bar"])
  end
end
