# frozen_string_literal: true

module Matcher
  module Testing
    class ErrorBuilder
      def self.build(&)
        errors = build_errors(&)

        AndError.from(errors)
      end

      def self.build_errors(&)
        builder = ErrorBuilder.new
        builder.instance_exec(&)
        builder.errors
      end

      attr_reader :errors

      def initialize
        @errors = []
      end

      def _or(*path, &)
        errors = ErrorBuilder.build_errors(&)
        error = OrError.from(errors)

        @errors << nest(path, error)
      end

      def _and(*path, &)
        errors = ErrorBuilder.build_errors(&)
        error = AndError.from(errors)

        @errors << nest(path, error)
      end

      def error(path_or_message, message = nil)
        if message.nil?
          @errors << ElementError.new(path_or_message)
        else
          path = Array(path_or_message)
          element = ElementError.new(message)

          @errors << nest(path, element)
        end
      end

      private

      def nest(path, error)
        path.reverse_each.reduce(error) { NestedError.from(_2, _1) }
      end
    end
  end
end
