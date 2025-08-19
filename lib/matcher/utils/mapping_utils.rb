# frozen_string_literal: true

module Matcher
  module MappingUtils
    def unary_call?(expression)
      expression.unary? && expression.receiver == Variable.actual
    end

    def index_call?(expression)
      expression.binary? &&
        expression.receiver == Variable.actual &&
        expression.args[0].is_a?(Constant)
    end

    def operand_of(expression)
      expression.args[0].value
    end

    def index_call_to(operand)
      Call.new(Variable.actual, :[], [Constant.new(operand)])
    end

    def map_errors(error, &)
      case error
      when EmptyError
        error
      when AndError, OrError
        children = error.children.map { map_errors(_1, &) }
        error.class.new(children)
      when NestedError
        yield(error) || error
      when ElementError
        NestedError.new(mapped_base, error)
      else
        raise "Unexpected error: #{error.inspect}"
      end
    end

    def map_base(method, expression)
      with_index = expression.variables.include?(:index)

      block = if unary_call?(expression)
        SymbolProc.new(expression.method)
      else
        element = expression.free_symbol(:e)
        parameters = [[:opt, element]]
        parameters << %i[opt index] if with_index
        substituted = expression.substitute(actual: element, original: :actual)

        Block.new(parameters, substituted)
      end

      if with_index
        enum_for = Call.new(Variable.actual, method)
        Call.new(enum_for, :with_index, [], {}, block)
      else
        Call.new(Variable.actual, method, [], {}, block)
      end
    end
  end
end
