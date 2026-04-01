# frozen_string_literal: true

module Matcher
  module Utils
    def self.to_string(obj)
      case obj
      when Hash
        return '{}' if obj.empty?

        body = obj.map do |k, v|
          if k.is_a?(Symbol)
            "#{k}: #{to_string(v)}"
          else
            "#{k.inspect} => #{to_string(v)}"
          end
        end

        "{ #{body.join(', ')} }"
      when Array
        "[#{obj.map { |v| to_string(v) }.join(', ')}]"
      else
        obj.inspect
      end
    end

    def self.call_block(block, values, parameters: block.parameters)
      args = []
      kwargs = {}

      parameters.each do |type, name|
        case type
        when :req, :opt, :rest
          args << values[:actual] if args.length == 0
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

    def self.inspect_block_params(block)
      arg_names = []
      kwarg_names = []

      block.parameters.each do |type, name|
        case type
        when :req, :opt, :rest
          arg_names << name
        when :keyreq, :key, :keyrest
          kwarg_names << name
        end
      end

      arg_parts = arg_names.all? { _1.match?(/^_[1-9]$/) } ? [] : arg_names
      kwarg_parts = kwarg_names.map { "#{_1}:" }

      (arg_parts + kwarg_parts).join(', ')
    end

    def self.block_location(block)
      file, line = block.source_location

      "#{File.basename(file)}:#{line}"
    end
  end
end
