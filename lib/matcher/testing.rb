# frozen_string_literal: true

module Matcher
  module Testing
    def match(actual, &)
      Matcher.build(&).match(actual)
    end

    def v(value)
      ValueMatcher.new(value)
    end

    def h(**hash)
      HashMatcher.new(hash)
    end

    def assert_errors(actual, *base, **attributes)
      if actual.empty?
        flunk 'expected an error but match result was valid'
      else
        check_errors('root', base, attributes, actual)
      end
    end

    def check_errors(prefix, base, attributes, actual)
      flunk "expected an error at #{prefix} but got nothing" unless actual

      Array.wrap(base).each do |message|
        assert_includes actual.base, message, "for #{prefix}"
      end

      attributes.each do |key, errors|
        new_prefix = "#{prefix}[#{key.inspect}]"
        new_actual = actual.attributes[key]

        if errors.is_a?(Hash)
          check_errors(new_prefix, [], errors, new_actual)
        else
          check_errors(new_prefix, errors, {}, new_actual)
        end
      end
    end
  end
end
