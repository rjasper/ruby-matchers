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

        attribute_errors = (@attributes[key_or_error] ||= Errors.new)
        attribute_errors.add(error)
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

    ATTRIBUTES_MERGER = lambda do |_k, l, r|
      l.merge!(r, &ATTRIBUTES_MERGER)
    end
    private_constant :ATTRIBUTES_MERGER

    def merge!(errors)
      @base.concat(errors.base)
      @attributes.merge!(errors.attributes, &ATTRIBUTES_MERGER)

      self
    end

    private

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

        if key.is_a?(Symbol)
          new_path += '.' unless path.empty?
          new_path += key.to_s
        else
          new_path += "[#{key.inspect}]"
        end

        message_recursive(new_path, attribute_errors, io)
      end
    end
  end
end
