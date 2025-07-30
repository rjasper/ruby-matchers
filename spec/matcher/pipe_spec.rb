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

  it 'can negate itself' do
    # divisible by 2 and not (by 3 and 5)
    matcher = pipe(divisible_by(2)) ^ ~pipe(divisible_by(3)) ^ divisible_by(5)

    assert_no_errors matcher.match(4) # divisible by 2 but not 3 or 5
    assert_no_errors matcher.match(6) # divisible by 2 and 3 but not 5
    assert_no_errors matcher.match(10) # divisible by 2 and 5 but not 3

    assert_errors matcher.match(15) do
      error 'expected _ % 2 == 0 but got 1 == 0, where _ = 15'
      _or do
        error 'expected _ % 3 != 0 but got 0 != 0, where _ = 15'
        error 'expected _ % 5 != 0 but got 0 != 0, where _ = 15'
      end
    end
  end

  private

  def divisible_by(n)
    Matcher.build { _ % n == 0 }
  end

  def pipe(matcher)
    Matcher::Pipe.new { |rhs| matcher * rhs }
  end
end
