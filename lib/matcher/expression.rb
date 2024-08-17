# frozen_string_literal: true

module Matcher
  class Expression
    def initialize
      raise 'abstract class' if instance_of?(Expression)
    end
  end
end
