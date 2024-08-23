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
require 'matcher/block_expression'
require 'matcher/block_matcher'
require 'matcher/builder'
require 'matcher/case_equality_matcher'
require 'matcher/each_matcher'
require 'matcher/equal_matcher'
require 'matcher/errors'
require 'matcher/expression_matcher'
require 'matcher/expression_recorder'
require 'matcher/hash_matcher'
require 'matcher/imply_matcher'
require 'matcher/imply_one_matcher'
require 'matcher/iso8601_matcher'
require 'matcher/map_matcher'
require 'matcher/pipe'
require 'matcher/project_matcher'
require 'matcher/reference_matcher'
require 'matcher/set_matcher'
require 'matcher/set_variables_matcher'
require 'matcher/utils'

module Matcher
  NULL = Object.new.freeze

  def self.build(&)
    with_build_session do
      builder = Builder.new
      object = builder.instance_exec(&)

      builder.refs.check

      return builder.refs.last_matcher if
        builder.refs? && builder.refs.last_object_id == object.object_id

      of(object)
    end
  end

  CASE_EQUALITY_CLASSES = [Class, Range, Regexp].freeze

  cattr_accessor :max_depth, default: 5000

  def self.of(object)
    if ExpressionRecorder.recorder?(object)
      expression = ExpressionRecorder.to_expression(object)
      return ExpressionMatcher.new(expression)
    end

    case object
    when Pipe
      raise "Cannot build Matcher from Pipe"
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

  def self.session
    Thread.current[:matcher_session]
  end

  def self.with_session
    return yield if Thread.current[:matcher_session]

    begin
      Thread.current[:matcher_session] = {}

      yield
    ensure
      Thread.current[:matcher_session] = nil
    end
  end

  def self.build_session
    Thread.current[:matcher_build_session]
  end

  def self.with_build_session
    return yield if Thread.current[:matcher_build_session]

    begin
      Thread.current[:matcher_build_session] = {}

      yield
    ensure
      Thread.current[:matcher_build_session] = nil
    end
  end
end
