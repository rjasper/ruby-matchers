# frozen_string_literal: true

module Matcher
  class Error
    def &(other)
      case other
      when EmptyError
        self
      when AndError
        AndError.new([self].concat(other.nodes))
      else
        AndError.new([self, other])
      end
    end

    def |(other)
      case other
      when EmptyError
        self
      when OrError
        OrError.new([self].concat(other.nodes))
      else
        OrError.new([self, other])
      end
    end

    def valid?
      false
    end

    def inspect
      to_s
    end
  end
end
