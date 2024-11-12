# frozen_string_literal: true

module Matcher
  class Constant < Expression
    attr_reader :constant

    def initialize(constant)
      super()

      @constant = constant
    end

    def negated
      Constant.new(!@constant)
    end

    def variables
      []
    end

    def evaluate(_values)
      @constant
    end

    def ==(other)
      return true if equal?(other)

      other.instance_of?(Constant) &&
        @constant.eql?(other.constant)
    end
    alias eql? ==

    def hash
      @constant.hash
    end

    def substitute(_replacements)
      self
    end

    def to_s(substitutions: nil)
      @constant.inspect
    end
  end
end
