# frozen_string_literal: true

require 'test_helper'

describe Matcher::Pipe do
  it 'builds up and reduces chain of pipes' do
    matcher = pipe(divisible_by(2)) ^ pipe(divisible_by(3)) ^ divisible_by(5)

    assert_no_errors matcher.match(30)

    assert_errors matcher.match(7),
      'expected _ % 2 == 0 but got 1 == 0, where _ = 7',
      'expected _ % 3 == 0 but got 1 == 0, where _ = 7',
      'expected _ % 5 == 0 but got 2 == 0, where _ = 7'
  end

  private

  def divisible_by(n)
    Matcher.build { _ % n == 0 }
  end

  def pipe(matcher)
    Matcher::Pipe.new { |rhs| matcher * rhs }
  end
end
