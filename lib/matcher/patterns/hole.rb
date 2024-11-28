# frozen_string_literal: true

module Matcher
  class Hole
    def initialize(key)
      @key = key
    end

    attr_reader :key

    def match?(_expression)
      true
    end

    def ==(other)
      other.instance_of?(self.class) && key == other.key
    end
    alias eql? ==

    def to_s
      "hole(#{@key.inspect})"
    end
    alias inspect to_s

    def to_recorder
      Constant.new(self).to_recorder
    end
  end
end
