# frozen_string_literal: true

require 'test_helper'

describe Matcher::ErrorChecker do
  let(:checker) do
    Matcher::ErrorChecker.new(Matcher::ExpectedPhrasing.phrasing)
  end

  it 'recognizes simple expected errors' do
    expected = build_errors do
      error 'something went wrong'
      error :foo, msg(1).not.equal(2)
    end

    actual = build_errors do
      error 'something went wrong'
      error :foo, msg(1).not.equal(2)
    end

    assert checker.check(expected, actual)
  end

  it 'detects unexpected structure' do
    expected = build_errors do
      error 'something went wrong'
      error :foo, msg(1).not.equal(2)
    end

    actual = build_errors do
      error 'something went wrong'
    end

    refute checker.check(expected, actual)
    assert_equal 'error has not the expected structure', checker.reason
  end

  it 'detects unexpected message' do
    expected = build_errors do
      error 'something went wrong'
    end

    actual = build_errors do
      error 'something went failed'
    end

    refute checker.check(expected, actual)
    assert_equal 'error has unexpected messages', checker.reason
    assert_equal [['something went wrong', 1]], checker.missing_phrases
    assert_equal [['something went failed', 1]], checker.extra_phrases
  end

  it 'detects unexpected tree in detail' do
    expected = build_errors do
      _or do
        error 'a'
        error 'b'
      end

      _or do
        error 'c'
        error 'd'
      end
    end

    actual = build_errors do
      _or do
        error 'a'
        error 'c'
      end

      _or do
        error 'b'
        error 'd'
      end
    end

    refute checker.check(expected, actual)
    assert_equal 'error tree does not match expected', checker.reason
  end

  it 'recognizes expected phrasing in message' do
    expected = Matcher::ElementError.new('expected 2 but got 1')
    actual = Matcher::ElementError.new(msg(1).not.equal(2))

    assert checker.check(expected, actual)
  end

  it 'recognizes expected message' do
    expected = Matcher::ElementError.new(msg(1).not.equal(2))
    actual = Matcher::ElementError.new(msg(1).not.equal(2))

    assert checker.check(expected, actual)
  end

  describe 'mixed children (parents and leaves)' do
    it 'recognizes expected mixed tree' do
      expected = build_errors do
        error 'a'

        _or do
          error 'b'
          error 'c'
        end
      end

      actual = build_errors do
        error 'a'

        _or do
          error 'b'
          error 'c'
        end
      end

      assert checker.check(expected, actual)
    end

    it 'detects unexpected leaf' do
      # NOTE: msg(1).lower_than(2) and msg(1).not.greater_or_equal_than(2)
      # produce the same expected phrasing.

      expected = build_errors do
        error msg(1).lower_than(2)

        _or do
          error msg(1).not.greater_or_equal_than(2)
          error 'b'
        end
      end

      actual = build_errors do
        error msg(1).not.greater_or_equal_than(2)

        _or do
          error msg(1).lower_than(2)
          error 'b'
        end
      end

      refute checker.check(expected, actual)
    end

    it 'detects unexpected parents' do
      expected = build_errors do
        _or do
          error 'a'

          _and do
            error 'b1'
            error 'b2'
          end
        end

        _or do
          error 'c'

          _and do
            error 'd1'
            error 'd2'
          end
        end
      end

      actual = build_errors do
        _or do
          error 'c'

          _and do
            error 'b1'
            error 'b2'
          end
        end

        _or do
          error 'a'

          _and do
            error 'd1'
            error 'd2'
          end
        end
      end

      refute checker.check(expected, actual)
    end
  end

  it 'detects if unambiguous candidates dont match' do
    expected = build_errors do
      _or do
        _and do
          error 'a1'
          error 'a2'
        end

        _and do
          error 'a1'
          error 'a2'
        end

        _and do
          error 'b1'
          error 'b2'
        end
      end

      _or do
        _and do
          error 'b1'
          error 'b2'
        end

        _and do
          error 'c1'
          error 'c2'
        end

        _and do
          error 'd1'
          error 'd2'
        end
      end
    end

    actual = build_errors do
      _or do
        _and do
          error 'a1'
          error 'a2'
        end

        _and do
          error 'b1'
          error 'b2'
        end

        _and do
          error 'b1'
          error 'b2'
        end
      end

      _or do
        _and do
          error 'a1'
          error 'a2'
        end

        _and do
          error 'c1'
          error 'c2'
        end

        _and do
          error 'd1'
          error 'd2'
        end
      end
    end

    refute checker.check(expected, actual)
  end

  it 'detects if there are too few candidates for all identities' do
    expected = build_errors do
      _or do
        _and do
          error 'a1'
          error 'expected 1 but got 2'
        end

        _and do
          error 'a1'
          error msg(2).not.equal(1)
        end

        _and do
          error 'a1'
          error msg(2).not.equal(1)
        end

        _and do
          error 'b1'
          error 'b2'
        end
      end

      _or do
        _and do
          error 'a1'
          error msg(2).not.equal(1)
        end

        _and do
          error 'b1'
          error 'b2'
        end

        _and do
          error 'c1'
          error 'c2'
        end

        _and do
          error 'd1'
          error 'd2'
        end
      end
    end

    actual = build_errors do
      _or do
        _and do
          error 'a1'
          error 'expected 1 but got 2'
        end

        _and do
          error 'a1'
          error msg(2).not.equal(1)
        end

        _and do
          error 'b1'
          error 'b2'
        end

        _and do
          error 'b1'
          error 'b2'
        end
      end

      _or do
        _and do
          error 'a1'
          error msg(2).not.equal(1)
        end

        _and do
          error 'a1'
          error msg(2).not.equal(1)
        end

        _and do
          error 'c1'
          error 'c2'
        end

        _and do
          error 'd1'
          error 'd2'
        end
      end
    end

    refute checker.check(expected, actual)
  end

  it 'recognizes valid positions for ambiguous candidates' do
    expected = build_errors do
      _or do
        _and do
          error 'a'
          error 'expected a falsy value but got "a"'
        end

        _and do
          error 'b'
          error 'expected a falsy value but got "b"'
        end

        _and do
          error 'c'
          error msg('c').truthy
        end
      end

      _or do
        _and do
          error 'a'
          error msg('a').truthy
        end

        _and do
          error 'b'
          error 'expected a falsy value but got "b"'
        end

        _and do
          error 'c'
          error 'expected a falsy value but got "c"'
        end
      end

      _or do
        _and do
          error 'a'
          error 'expected a falsy value but got "a"'
        end

        _and do
          error 'b'
          error msg('b').truthy
        end

        _and do
          error 'c'
          error 'expected a falsy value but got "c"'
        end
      end
    end

    actual = build_errors do
      _or do
        _and do
          error 'a'
          error 'expected a falsy value but got "a"'
        end

        _and do
          error 'b'
          error msg('b').truthy
        end

        _and do
          error 'c'
          error msg('c').truthy
        end
      end

      _or do
        _and do
          error 'a'
          error msg('a').truthy
        end

        _and do
          error 'b'
          error 'expected a falsy value but got "b"'
        end

        _and do
          error 'c'
          error msg('c').truthy
        end
      end

      _or do
        _and do
          error 'a'
          error msg('a').truthy
        end

        _and do
          error 'b'
          error msg('b').truthy
        end

        _and do
          error 'c'
          error 'expected a falsy value but got "c"'
        end
      end
    end

    assert checker.check(expected, actual)
  end

  it 'detects valid positions impossible for ambiguous candidates' do
    expected = build_errors do
      _or do
        _and do
          error 'a'
          error 'expected a falsy value but got "a"'
        end

        _and do
          error 'b'
          error msg('b').truthy
        end

        _and do
          error 'c'
          error msg('c').truthy
        end
      end

      _or do
        _and do
          error 'a'
          error 'expected a falsy value but got "a"'
        end

        _and do
          error 'b'
          error msg('b').truthy
        end

        _and do
          error 'c'
          error msg('c').truthy
        end
      end

      _or do
        _and do
          error 'a'
          error 'expected a falsy value but got "a"'
        end

        _and do
          error 'b'
          error 'expected a falsy value but got "b"'
        end

        _and do
          error 'c'
          error 'expected a falsy value but got "c"'
        end
      end
    end

    actual = build_errors do
      _or do
        _and do
          error 'a'
          error 'expected a falsy value but got "a"'
        end

        _and do
          error 'b'
          error msg('b').truthy
        end

        _and do
          error 'c'
          error msg('c').truthy
        end
      end

      _or do
        _and do
          error 'a'
          error msg('a').truthy
        end

        _and do
          error 'b'
          error 'expected a falsy value but got "b"'
        end

        _and do
          error 'c'
          error msg('c').truthy
        end
      end

      _or do
        _and do
          error 'a'
          error msg('a').truthy
        end

        _and do
          error 'b'
          error msg('b').truthy
        end

        _and do
          error 'c'
          error 'expected a falsy value but got "c"'
        end
      end
    end

    refute checker.check(expected, actual)
  end

  it '#match_identities3' do
    [
      ['1, 2, 3', '1,2,3', true],
      ['1, 2, 1', '1,2,1', true],
      ['1, 2, 1', '1,1,1', false],
      ['1, 2, 1', '2,2,1', false],
      ['1|2, 2|3, 4|5', '1,2,3', false],
      ['1|2, 2', '1,1,2', false],
      ['1, 2|3, 4, 1|4', '1,2,3,4', false],
      ['1, 2|3, 4|2, 1|4', '1,2,3,4', true],
      ['1, 1|2|3, 1', '1,2,3', false],
      ['1|2, 2|3, 1|3', '1,2,3', true],
      ['1, 2|5, 6|3, 6|5, 4|5|6, 1|2|3|4', '1,2,3,4,5,6', true],
      ['1, 2|5, 3|4, 1|2|3, 1|2|3, 4|5|6, 4|5|7', '1,2,3,4,5,6,7', true],
    ].each do |candidates, identities, expected|
      identities = identities.split(',').map(&:to_i)
      positions = candidates.split(',').map { _1.split('|').map(&:to_i) }

      actual = checker.send(:match_identities?, positions, identities)

      assert_equal expected, actual, "candidates: #{candidates}\nidentities: #{identities.inspect}\nresult = #{actual}"
    end
  end
end
