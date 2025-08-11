# frozen_string_literal: true

module Matcher
  module OnceBefore
    def once_before(method, &)
      original_method = "_before_once_#{method}"
      alias_method(original_method, method)

      define_method(method) do |*args, **kwargs, &block|
        instance_exec(&)
        send(original_method, *args, **kwargs, &block)
      ensure
        self.class.alias_method(method, original_method)
        self.class.undef_method(original_method)
      end
    end
  end
end
