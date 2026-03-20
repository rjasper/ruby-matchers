# frozen_string_literal: true

module Matcher
  module OnceBefore
    def once_before(method, &)
      mod = self
      original_method = "_before_once_#{method}"
      alias_method(original_method, method)

      define_method(method) do |*args, **kwargs, &block|
        instance_exec(&)
        send(original_method, *args, **kwargs, &block)
      ensure
        mod.alias_method(method, original_method)
        mod.undef_method(original_method)
      end
    end
  end
end
