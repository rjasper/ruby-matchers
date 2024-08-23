# frozen_string_literal: true

module Matcher
  module Utils
    def self.call_block(block, actual = nil, **values)
      args = []
      kwargs = {}

      block.parameters.each do |type, name|
        case type
        when :req, :opt, :rest
          args << (actual || values[:actual]) if args.length == 0
        when :keyreq
          kwargs[name] = values[name]
        when :key
          value = values[name]
          kwargs[name] = value if !value.nil? || values.key?(name)
        when :keyrest
          kwargs.merge!(values.except(*kwargs.keys))
        end
      end

      block.call(*args, **kwargs)
    end
  end
end
