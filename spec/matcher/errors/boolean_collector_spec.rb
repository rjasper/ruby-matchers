# frozen_string_literal: true

require "test_helper"

describe Matcher::BooleanCollector do
  include Matcher::ErrorTesting

  let(:collector) { Matcher::BooleanCollector.new }

  it "empty" do
    assert_equal empty, collector.error
    assert collector.empty?
  end

  it "add empty" do
    collector << empty

    assert_equal empty, collector.error
  end

  it "and error" do
    assert_throws(:mismatch) do
      collector << element("foo")
    end

    assert_equal element("invalid"), collector.error
  end

  it "or error" do
    collector.or!
    collector << element("foo")

    assert_equal element("invalid"), collector.error
  end

  it "nested" do
    assert_throws(:mismatch) do
      collector[0] << element("foo")
    end

    assert_equal element("invalid"), collector.error
  end

  it "clear" do
    collector.or!
    collector << element("foo")

    assert_equal element("invalid"), collector.error

    collector.clear

    assert_equal empty, collector.error
  end
end
