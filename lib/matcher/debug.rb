# frozen_string_literal: true

module Matcher
  module Debug
    def self.enable
      init(force: true)
    end

    DEBUGGERS = %w[/bin/irb: ruby-debug-ide].freeze

    def self.init(force: false)
      return if @initialized

      main_caller = caller[-1]

      return if !force && DEBUGGERS.none? { main_caller.include?(_1) }

      ExpressionRecorder.prepend(ExpressionRecorderDebug)
      @initialized = true
    end

    def self.debugging?(last_caller)
      %w[puts p].any? { last_caller.end_with?(":in `#{_1}'") } ||
        last_caller.include?('ruby-debug-ide')
    end
  end

  module ExpressionRecorderDebug
    private

    def method_missing(method, *args, **kwargs, &block)
      if Debug.debugging?(caller[0])
        return @expression.to_s if %i[to_s inspect].include?(method)

        return Object.instance_method(method)
          .bind_call(self, *args, **kwargs, &block)
      end

      super
    end

    def respond_to_missing?(method, _include_private = false)
      return Object.instance_methods.include?(method) if Debug.debugging?(caller[0])

      super
    end
  end
end
