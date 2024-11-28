# frozen_string_literal: true

require 'test_helper'

describe Matcher::NotRespondingError do
  it 'provides standard message for simple expression' do
    exp = expression { _.foo }

    err = assert_raises Matcher::NotRespondingError do
      exp.evaluate(actual: 1)
    end

    assert_equal msg(1).not.responding_to(:foo), err.message_for_errors
  end

  it 'provides expression message for receiver other than actual' do
    exp = expression { (_ + 1).foo }

    err = assert_raises Matcher::NotRespondingError do
      exp.evaluate(actual: 1)
    end

    plus_one = expression { _ + 1 }
    message = msg(1).namespace(:expression)
      .not.responding_to(plus_one, 2, :foo, { actual: 1 })

    assert_equal message, err.message_for_errors
  end
end
