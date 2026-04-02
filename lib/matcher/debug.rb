# frozen_string_literal: true

module Matcher
  module Debug
    class << self
      DEBUGGERS = %w[/bin/irb: ruby-debug-ide].freeze

      def enable
        init(force: true)
      end

      def init(force: false)
        return if @initialized

        main_caller = caller[-1]

        return if !force && DEBUGGERS.none? { main_caller.include?(_1) }

        Recorder.prepend(ExpressionRecorderDebug)
        @initialized = true
      end

      def debugging?(trace)
        last_trace_item = trace[0]

        %w[puts p].any? { call_from?(last_trace_item, _1) } ||
          last_trace_item.include?("ruby-debug-ide") ||
          trace.any? { call_from?(_1, "output_value") }
      end

      # rubocop:disable Style/ClassVars

      @@method_quote_delimiter = caller[0].include?("`") ? "`" : "#"

      # rubocop:enable Style/ClassVars

      def call_from?(trace_item, method)
        trace_item.end_with?("#{@@method_quote_delimiter}#{method}'")
      end
    end
  end

  module ExpressionRecorderDebug
    private

    def method_missing(method, ...)
      if Debug.debugging?(caller)
        return @expression.to_s if %i[to_s inspect].include?(method)

        Object.instance_method(method).bind_call(self, ...)
      else
        super
      end
    end

    def respond_to_missing?(method, _include_private = false)
      return Object.method_defined?(method) if Debug.debugging?(caller)

      super
    end
  end
end
