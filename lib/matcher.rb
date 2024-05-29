# frozen_string_literal: true

require 'active_support/all'

require_relative "matcher/version"
require 'matcher/base'

require 'matcher/all_matcher'
require 'matcher/any_matcher'
require 'matcher/array_matcher'
require 'matcher/assertions'
require 'matcher/block_matcher'
require 'matcher/builder'
require 'matcher/errors'
require 'matcher/expression'
require 'matcher/expression_matcher'
require 'matcher/expression_recorder'
require 'matcher/hash_matcher'
require 'matcher/value_matcher'

module Matcher
  def self.build(&)
    object = Builder.new.instance_exec(&)

    of(object)
  end

  def self.of(object)
    # rubocop:disable Style/ClassEqualityComparison
    if object.class == ExpressionRecorder
      expression = ExpressionRecorder.to_expression(object)
      return ExpressionMatcher.new(expression)
    end
    # rubocop:enable Style/ClassEqualityComparison

    case object
    when Base
      object
    when Expression
      ExpressionMatcher.new(object)
    when Proc
      BlockMatcher.new(object)
    when Hash
      HashMatcher.new(
        object.transform_values { of(_1) },
        **settings.slice(:all_entries),
      )
    when Array
      ArrayMatcher.new(object.map { of(_1) })
    else
      ValueMatcher.new(object)
    end
  end

  def self.settings
    Thread.current[:matcher_settings_stack]&.last || {}
  end

  def self.with_settings(**settings)
    stack = (Thread.current[:matcher_settings_stack] ||= [])
    stack << (stack.last || {}).merge(settings)

    begin
      yield
    ensure
      stack.pop
      Thread.current[:matcher_settings_stack] = nil if stack.empty?
    end
  end
end
