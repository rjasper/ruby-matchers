# frozen_string_literal: true

module Matcher
  class EmptyError < Error
    include Singleton

    def &(other)
      other
    end

    def |(other)
      other
    end

    def valid?
      true
    end

    def to_s
      "<>"
    end
  end
end
