# frozen_string_literal: true

require_relative "matcher/version"

require 'singleton'
require 'forwardable'

module Matcher
  module NoMatcher; end
  module NoExpression; end
  module NoKey; end
end

require_relative 'matcher/once_before'
require_relative 'matcher/expressions/expression_building'
require_relative 'matcher/matchers/matcher_building'
require_relative 'matcher/patterns/pattern_building'
require_relative 'matcher/utils/mapping_utils'

require_relative 'matcher/assertions'
require_relative 'matcher/base'
require_relative 'matcher/builder'
require_relative 'matcher/debug'
require_relative 'matcher/expression_labeler'
require_relative 'matcher/expression_cache'
require_relative 'matcher/hash_stack'
require_relative 'matcher/list'
require_relative 'matcher/matcher_cache'
require_relative 'matcher/optional_pipe'
require_relative 'matcher/pipe'
require_relative 'matcher/reporter'
require_relative 'matcher/state'
require_relative 'matcher/undefined'
require_relative 'matcher/utils'

require_relative 'matcher/errors/error'
require_relative 'matcher/errors/and_error'
require_relative 'matcher/errors/element_error'
require_relative 'matcher/errors/empty_error'
require_relative 'matcher/errors/error_collector'
require_relative 'matcher/errors/nested_error'
require_relative 'matcher/errors/or_error'

require_relative 'matcher/expressions/expression'
require_relative 'matcher/expressions/array_expression'
require_relative 'matcher/expressions/block'
require_relative 'matcher/expressions/call'
require_relative 'matcher/expressions/call_error'
require_relative 'matcher/expressions/constant'
require_relative 'matcher/expressions/expression_walker'
require_relative 'matcher/expressions/hash_expression'
require_relative 'matcher/expressions/proc_expression'
require_relative 'matcher/expressions/range_expression'
require_relative 'matcher/expressions/recorder'
require_relative 'matcher/expressions/rescue_last_error_expression'
require_relative 'matcher/expressions/set_expression'
require_relative 'matcher/expressions/string_expression'
require_relative 'matcher/expressions/symbol_proc'
require_relative 'matcher/expressions/variable'

require_relative 'matcher/markers/optional'
require_relative 'matcher/markers/others'

require_relative 'matcher/matchers/all_matcher'
require_relative 'matcher/matchers/always_matcher'
require_relative 'matcher/matchers/any_matcher'
require_relative 'matcher/matchers/array_matcher'
require_relative 'matcher/matchers/block_matcher'
require_relative 'matcher/matchers/dig_matcher'
require_relative 'matcher/matchers/each_matcher'
require_relative 'matcher/matchers/each_pair_matcher'
require_relative 'matcher/matchers/equal_matcher'
require_relative 'matcher/matchers/equal_set_matcher'
require_relative 'matcher/matchers/expression_matcher'
require_relative 'matcher/matchers/filter_matcher'
require_relative 'matcher/matchers/hash_matcher'
require_relative 'matcher/matchers/index_by_matcher'
require_relative 'matcher/matchers/inline_matcher'
require_relative 'matcher/matchers/imply_matcher'
require_relative 'matcher/matchers/imply_some_matcher'
require_relative 'matcher/matchers/keys_matcher'
require_relative 'matcher/matchers/kind_of_matcher'
require_relative 'matcher/matchers/lazy_all_matcher'
require_relative 'matcher/matchers/lazy_any_matcher'
require_relative 'matcher/matchers/let_matcher'
require_relative 'matcher/matchers/map_matcher'
require_relative 'matcher/matchers/negated_array_matcher'
require_relative 'matcher/matchers/negated_each_matcher'
require_relative 'matcher/matchers/negated_each_pair_matcher'
require_relative 'matcher/matchers/negated_imply_some_matcher'
require_relative 'matcher/matchers/negated_matcher'
require_relative 'matcher/matchers/negated_project_matcher'
require_relative 'matcher/matchers/never_matcher'
require_relative 'matcher/matchers/one_matcher'
require_relative 'matcher/matchers/optional_matcher'
require_relative 'matcher/matchers/parse_float_matcher'
require_relative 'matcher/matchers/parse_integer_matcher'
require_relative 'matcher/matchers/parse_iso8601_matcher'
require_relative 'matcher/matchers/parse_json_matcher'
require_relative 'matcher/matchers/project_matcher'
require_relative 'matcher/matchers/raises_matcher'
require_relative 'matcher/matchers/range_matcher'
require_relative 'matcher/matchers/reference_matcher'
require_relative 'matcher/matchers/reference_matcher_collection'
require_relative 'matcher/matchers/regexp_matcher'

require_relative 'matcher/messages/phrasing'
require_relative 'matcher/messages/message_builder'
require_relative 'matcher/messages/expected_phrasing'
require_relative 'matcher/messages/message'
require_relative 'matcher/messages/namespaced_message_builder'
require_relative 'matcher/messages/standard_message_builder'

require_relative 'matcher/patterns/hole'
require_relative 'matcher/patterns/ast_mapping'
require_relative 'matcher/patterns/capture_hole'
require_relative 'matcher/patterns/constant_hole'
require_relative 'matcher/patterns/method_hole'
require_relative 'matcher/patterns/pattern'
require_relative 'matcher/patterns/pattern_capture'
require_relative 'matcher/patterns/pattern_match'
require_relative 'matcher/patterns/variable_hole'

require_relative 'matcher/rules/message_factory'
require_relative 'matcher/rules/message_rule'
require_relative 'matcher/rules/message_rule_context'
require_relative 'matcher/rules/rule_builder'
require_relative 'matcher/rules/rule_set'
require_relative 'matcher/rules/transform_builder'
require_relative 'matcher/rules/transform_mapping'
require_relative 'matcher/rules/transform_rule'

require_relative 'matcher/testing/error_builder'
require_relative 'matcher/testing/error_checker'
require_relative 'matcher/testing/error_testing'
require_relative 'matcher/testing/pattern_testing'
require_relative 'matcher/testing/pattern_testing_scope'

module Matcher
  UNDEFINED = Undefined.instance

  def self.undefined?(object)
    # Note that for an ExpressionRecorder object == UNDEFINED won't work.
    UNDEFINED == object
  end

  def self.build(&block)
    with_build_session do |build_session|
      builder = Builder.new(block.binding.receiver, build_session:)
      object = builder.instance_exec(&block)
      builder.refs.check

      matcher = if builder.refs? && builder.refs.last_object_id == object.object_id
        builder.refs.last_matcher
      else
        builder.matcher_of(object)
      end

      if (assigns = builder.assigns)
        LetMatcher.new(assigns, matcher)
      else
        matcher
      end
    end
  end

  def self.max_reference_depth
    @max_reference_depth ||= 100
  end

  def self.max_reference_depth=(value)
    @max_reference_depth = value
  end

  def self.of(object, matcher_cache: nil, expression_cache: nil)
    object = Recorder.to_expression(object) if Recorder.recorder?(object)

    case object
    when NoMatcher
      raise ArgumentError, "Cannot use #{object.class} as matcher"
    when Module
      KindOfMatcher.cache(object, matcher_cache)
    when OptionalPipe
      object.fallback
    when Base
      object
    when Expression
      ExpressionMatcher.cache(object, matcher_cache, expression_cache)
    when Proc
      BlockMatcher.new(object)
    when Range
      RangeMatcher.cache(object, matcher_cache)
    when Regexp
      RegexpMatcher.cache(object, matcher_cache)
    when Hash
      hash = object.to_h do |k, v|
        k = Expression.try_recorder(k)

        if Recorder.recorder?(k)
          k = Recorder.to_expression(k)
        elsif k.is_a?(Optional)
          k = Optional.cache(k.value, matcher_cache)
        end

        [k, of(v, matcher_cache:, expression_cache:)]
      end

      HashMatcher.new(hash)
    when Array
      ArrayMatcher.new(object.map { of(_1, matcher_cache:, expression_cache:) })
    when Optional
      matcher = of(object.value, matcher_cache:, expression_cache:)

      OptionalMatcher.cache(matcher, matcher_cache)
    else
      EqualMatcher.cache(object, matcher_cache)
    end
  end

  def self.cache(object)
    build_session = Matcher.build_session
    matcher_cache = MatcherCache.current(build_session)
    expression_cache = Expression.current_cache(build_session)

    of(object, matcher_cache:, expression_cache:)
  end

  def self.parenthesize(matcher)
    matcher_to_s = matcher.to_s

    matcher_to_s = "(#{matcher_to_s})" if
      case matcher
      when ExpressionMatcher
        !matcher.negated && matcher.expression.precedence > Call::OPERATOR_PRECEDENCE[:^]
      when EqualMatcher, KindOfMatcher, RangeMatcher, RegexpMatcher, ArrayMatcher, HashMatcher
        false
      else
        matcher_to_s !~ /\A(~?\w+(\(.*\)|\[.*\])?|-> \{.*})\z/
      end

    matcher_to_s
  end

  def self.settings
    Thread.current[:matcher_settings_stack] || {}
  end

  def self.with_settings(**settings)
    stack = (Thread.current[:matcher_settings_stack] ||= HashStack.new)
    stack.push(settings)

    begin
      yield
    ensure
      stack.pop(settings)
      Thread.current[:matcher_settings_stack] = nil if stack.empty?
    end
  end

  def self.session
    Thread.current[:matcher_session]
  end

  def self.with_session(initial = {})
    return yield if Thread.current[:matcher_session]

    begin
      Thread.current[:matcher_session] = initial

      yield
    ensure
      Thread.current[:matcher_session] = nil
    end
  end

  def self.build_session
    Thread.current[:matcher_build_session]
  end

  def self.with_build_session(initial = {})
    build_session = Thread.current[:matcher_build_session]

    return yield build_session if build_session

    begin
      Thread.current[:matcher_build_session] = initial

      yield initial
    ensure
      Thread.current[:matcher_build_session] = nil
    end
  end

  Debug.init
end

require_relative 'matcher/messages/message_rules'
