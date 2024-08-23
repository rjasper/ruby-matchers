# frozen_string_literal: true

module Matcher
  module Testing
    def match(actual, &)
      Matcher.build(&).match(actual)
    end

    def v(value)
      EqualMatcher.new(value)
    end

    def a(array)
      ArrayMatcher.new(array)
    end

    def h(**hash)
      HashMatcher.new(hash)
    end

    def expr(&)
      Call.build(&)
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

      base = Array.wrap(base)

      missing_messages = actual.base - base
      missing_keys = actual.attributes.keys - attributes.keys

      flunk "missing messages at #{prefix}: \n- #{missing_messages.join("\n- ")}" unless missing_messages.empty?
      flunk "missing error at #{prefix} for: #{missing_keys.join(', ')}" unless missing_keys.empty?

      base.each do |message|
        assert_includes actual.base, message, "for #{prefix}"
      end

      attributes.each do |key, errors|
        new_prefix = case key
        when Symbol
          "#{prefix}.#{key}"
        when Call
          key.to_s(substitutions: { actual: prefix })
        else
          "#{prefix}[#{key.inspect}]"
        end

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
