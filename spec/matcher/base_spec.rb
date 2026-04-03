# frozen_string_literal: true

require "test_helper"

describe Matcher::Base do
  def setup
    @max_reference_depth_bak = Matcher.max_reference_depth
    Matcher.max_reference_depth = 2
  end

  def teardown
    Matcher.max_reference_depth = @max_reference_depth_bak
  end

  it "checks match level" do
    matcher = Matcher.build do
      refs[:obj] = project(_.dup) ^ refs[:obj]
    end

    assert_errors matcher.match(Object.new),
      expression { _.dup.dup.dup } => "match level too deep: 3"
  end

  it "scopes values" do
    matcher = Matcher.build do
      declare :foo

      let(foo: 1) ^ [
        _ == foo,
        let(foo: 2) ^ (_ == foo),
        _ == foo,
      ]
    end

    assert_no_errors matcher.match([1, 2, 1])
  end

  it "#~: caches negated matchers" do
    Matcher.with_build_session do
      matcher = Matcher.build { "foo" }
      negated = ~matcher

      assert_same negated, ~matcher
      assert_same matcher, ~negated
    end
  end
end
