# frozen_string_literal: true

require 'active_support/all'

require_relative "matcher/version"
require 'matcher/base'
require 'matcher/expression'
require 'matcher/call'
require 'matcher/constant'
require 'matcher/variable'

require 'matcher/all_matcher'
require 'matcher/any_matcher'
require 'matcher/array_matcher'
require 'matcher/assertions'
require 'matcher/block_matcher'
require 'matcher/builder'
require 'matcher/case_equality_matcher'
require 'matcher/each_matcher'
require 'matcher/equal_matcher'
require 'matcher/errors'
require 'matcher/expression_matcher'
require 'matcher/expression_recorder'
require 'matcher/hash_matcher'
require 'matcher/iso8601_matcher'
require 'matcher/map_matcher'
require 'matcher/set_matcher'

module Matcher
  def self.build(&)
    object = Builder.new.instance_exec(&)

    of(object)
  end

  CASE_EQUALITY_CLASSES = [Class, Range, Regexp].freeze

  def self.of(object)
    if ExpressionRecorder.recorder?(object)
      expression = ExpressionRecorder.to_expression(object)
      return ExpressionMatcher.new(expression)
    end

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
    when *CASE_EQUALITY_CLASSES
      CaseEqualityMatcher.new(object)
    else
      EqualMatcher.new(object)
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
