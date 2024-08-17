# frozen_string_literal: true

module Matcher
  class Constant < Expression
    attr_reader :constant

    def initialize(constant)
      super()

      @constant = constant
    end

    def variables
      []
    end

    def evaluate(_values, chain = nil)
      chain << @constant if chain

      @constant
    end

    def ==(other)
      other.equal?(self) ||
        other.instance_of?(Constant) && other.constant == @constant
    end

    def eql?(other)
      other.equal?(self) ||
        other.instance_of?(Constant) && other.constant.eql?(@constant)
    end

    def hash
      @constant.hash
    end

    def to_s(substitutions: nil)
      @constant.inspect
    end
    alias inspect to_s
  end
end
