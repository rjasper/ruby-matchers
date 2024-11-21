# frozen_string_literal: true

require_relative "matcher/version"

require 'singleton'
require 'forwardable'

require 'matcher/expressions/expression_building'
require 'matcher/patterns/pattern_building'
require 'matcher/matcher_building'

require 'matcher/base'
require 'matcher/abstract_phrasing'
require 'matcher/base_message_builder'

require 'matcher/expressions/expression'
require 'matcher/expressions/block'
require 'matcher/expressions/proc_expression'
require 'matcher/expressions/call'
require 'matcher/expressions/constant'
require 'matcher/expressions/expression_recorder'
require 'matcher/expressions/expression_walker'
require 'matcher/expressions/symbol_proc'
require 'matcher/expressions/variable'

require 'matcher/patterns/hole'
require 'matcher/patterns/call_hole'
require 'matcher/patterns/capture_hole'
require 'matcher/patterns/constant_hole'
require 'matcher/patterns/method_hole'
require 'matcher/patterns/pattern'
require 'matcher/patterns/variable_hole'

require 'matcher/assertions'
require 'matcher/ast_mapping'
require 'matcher/builder'
require 'matcher/debug'
require 'matcher/expected_phrasing'
require 'matcher/expression_labeler'
require 'matcher/list'
require 'matcher/namespaced_message_builder'
require 'matcher/nested_expression_normalizer'
require 'matcher/pipe'
require 'matcher/reporter'
require 'matcher/rule_set'
require 'matcher/standard_message_builder'
require 'matcher/utils'

require 'matcher/errors/node'
require 'matcher/errors/message'
require 'matcher/errors/and'
require 'matcher/errors/collector'
require 'matcher/errors/element'
require 'matcher/errors/empty'
require 'matcher/errors/nested'
require 'matcher/errors/or'

require 'matcher/testing/error_builder'
require 'matcher/testing/error_node_labeler'
require 'matcher/testing/errors_checker'

require 'matcher/matchers/all_matcher'
require 'matcher/matchers/any_matcher'
require 'matcher/matchers/array_matcher'
require 'matcher/matchers/block_matcher'
require 'matcher/matchers/case_equality_matcher'
require 'matcher/matchers/each_matcher'
require 'matcher/matchers/each_pair_matcher'
require 'matcher/matchers/equal_matcher'
require 'matcher/matchers/expression_matcher'
require 'matcher/matchers/hash_matcher'
require 'matcher/matchers/imply_matcher'
require 'matcher/matchers/imply_one_matcher'
require 'matcher/matchers/iso8601_matcher'
require 'matcher/matchers/map_matcher'
require 'matcher/matchers/negated_array_matcher'
require 'matcher/matchers/negated_each_matcher'
require 'matcher/matchers/negated_each_pair_matcher'
require 'matcher/matchers/negated_hash_matcher'
require 'matcher/matchers/negated_imply_matcher'
require 'matcher/matchers/negated_imply_one_matcher'
require 'matcher/matchers/negated_map_matcher'
require 'matcher/matchers/negated_matcher'
require 'matcher/matchers/negated_project_matcher'
require 'matcher/matchers/project_matcher'
require 'matcher/matchers/reference_matcher'
require 'matcher/matchers/reference_matcher/collection'
require 'matcher/matchers/set_matcher'
require 'matcher/matchers/set_variables_matcher'

module Matcher
  NULL = Object.new.freeze

  def self.null?(object)
    # Note that for an ExpressionRecorder object == NULL won't work.
    NULL == object
  end

  def self.build(thread_safe: false, &)
    with_build_session(thread_safe:) do
      builder = Builder.new
      object = builder.instance_exec(&)

      builder.refs.check

      return builder.refs.last_matcher if
        builder.refs? && builder.refs.last_object_id == object.object_id

      of(object)
    end
  end

  CASE_EQUALITY_CLASSES = [Module, Range, Regexp].freeze

  def self.max_depth
    @max_depth ||= 5000
  end

  def self.max_depth=(val)
    @max_depth = val
  end

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
      HashMatcher.new(object.transform_values { of(_1) })
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

  def self.with_build_session(initial = {})
    return yield if Thread.current[:matcher_build_session]

    begin
      Thread.current[:matcher_build_session] = initial

      yield
    ensure
      Thread.current[:matcher_build_session] = nil
    end
  end

  Debug.init
end

require 'matcher/matchers/expression_matcher/message_rules'
