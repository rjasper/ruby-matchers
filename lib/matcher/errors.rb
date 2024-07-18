# frozen_string_literal: true

module Matcher
  class Errors
    attr_reader :base, :attributes

    class Brackets
      def initialize(parent, key)
        @parent = parent
        @key = key
      end

      def <<(error)
        @parent.add(@key, error)
      end
    end

    def initialize
      @base = []
      @attributes = {}
    end

    def empty?
      @base.empty? && @attributes.empty?
    end

    def valid?
      empty?
    end

    def <<(error)
      add(error)
    end

    def [](key)
      Brackets.new(self, key)
    end

    def add(key_or_error, error = nil)
      if error
        return self if error.is_a?(Errors) && error.empty?

        normalize_key(key_or_error)
          .reduce(self) { _1.attributes[_2] ||= Errors.new }
          .add(error)
      elsif key_or_error.is_a?(Errors)
        merge!(key_or_error)
      else
        @base << key_or_error
      end

      self
    end

    def clear
      @base.clear
      @attributes.clear
    end

    def message
      io = StringIO.new
      message_recursive('', self, io)

      io.string.chomp
    end

    protected

    def merge!(errors)
      merger = ->(_k, l, r) { l.merge!(r, &merger) }

      @base.concat(errors.base)
      @attributes.merge!(errors.attributes, &merger)

      self
    end

    private

    def normalize_key(key)
      return [key] unless key.is_a?(Expression)

      keys = []
      expression = key

      until expression.root?
        key = if expression.method == :[] && expression.binary?
          expression.args[0]
        else
          expression.rooted
        end

        keys.unshift(key)
        expression = expression.receiver
      end

      keys
    end

    def message_recursive(path, errors, io)
      errors.base.each do |message|
        if path.empty?
          io.print('- ')
        else
          io.print("#{path}: ")
        end

        io.puts(message)
      end

      errors.attributes.each do |key, attribute_errors|
        new_path = path

        case key
        when Symbol
          new_path += '.' unless path.empty?
          new_path += key.to_s
        when Expression
          new_path = key.to_s(root: path)
        else
          new_path += "[#{key.inspect}]"
        end

        message_recursive(new_path, attribute_errors, io)
      end
    end
  end
end
