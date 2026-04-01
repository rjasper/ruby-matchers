# frozen_string_literal: true

require 'test_helper'

module Matcher
  describe Message do
    describe '#to_s' do
      it 'key only' do
        assert_equal 'report(1).hello', msg(1).hello.to_s
      end

      it 'namespace' do
        assert_equal 'report(1).namespace(:extraterrestrial).hello_world',
          msg(1).namespace(:extraterrestrial).hello_world.to_s
      end

      it 'negated' do
        assert_equal 'report(1).not.expected',
          msg(1).not.expected.to_s
      end

      it 'args and kwargs' do
        assert_equal 'report(1).hello("world", tone: "friendly")',
          msg(1).hello('world', tone: 'friendly').to_s
      end

      describe '#to_standard' do
        it 'truthy' do
          matcher = Matcher.build { _[0] }
          message = matcher.match([false]).message
          expected = Message.new(:truthy, true, false)

          assert_equal :expression, message.namespace
          assert_equal expected, message.to_standard
        end

        it 'same' do
          matcher = Matcher.build { _[0].equal?(vars[:a]) }
          message = matcher.match([2], a: 1).message
          expected = Message.new(:same, true, 2, 1)

          assert_equal :expression, message.namespace
          assert_equal expected, message.to_standard
        end

        it 'comparable_to' do
          matcher = Matcher.build { _[0] <=> vars[:a] }
          message = matcher.match(['hi'], a: 1).message
          expected = Message.new(:comparable_to, true, 'hi', 1)

          assert_equal :expression, message.namespace
          assert_equal expected, message.to_standard
        end

        it 'having_key' do
          matcher = Matcher.build { _[0].key?(vars[:a]) }
          message = matcher.match([{}], a: 1).message
          expected = Message.new(:having_key, true, {}, 1)

          assert_equal :expression, message.namespace
          assert_equal expected, message.to_standard
        end

        it 'in' do
          matcher = Matcher.build { vars[:collection].include?(_.upcase) }
          message = matcher.match('c', collection: %w[A B]).message
          expected = Message.new(:in, true, 'C', %w[A B])

          assert_equal :expression, message.namespace
          assert_equal expected, message.to_standard
        end

        it 'including' do
          matcher = Matcher.build { (_ + [3]).include?(vars[:a]) }
          message = matcher.match([1, 2], a: 4).message
          expected = Message.new(:including, true, [1, 2, 3], 4)

          assert_equal :expression, message.namespace
          assert_equal expected, message.to_standard
        end

        it 'matching' do
          matcher = Matcher.build { concat(_, '!') =~ vars[:a] }
          message = matcher.match('Hi', a: /Hello/).message
          expected = Message.new(:matching, true, 'Hi!', /Hello/)

          assert_equal :expression, message.namespace
          assert_equal expected, message.to_standard
        end

        it 'instance_of' do
          matcher = Matcher.build { _[0].instance_of?(vars[:a]) }
          message = matcher.match([1], a: String).message
          expected = Message.new(:instance_of, true, 1, String)

          assert_equal :expression, message.namespace
          assert_equal expected, message.to_standard
        end

        it 'kind_of' do
          matcher = Matcher.build { _[0].is_a?(vars[:a]) }
          message = matcher.match([1], a: String).message
          expected = Message.new(:kind_of, true, 1, String)

          assert_equal :expression, message.namespace
          assert_equal expected, message.to_standard
        end

        it 'responding_to' do
          matcher = Matcher.build { _[0].respond_to?(vars[:a]) }
          message = matcher.match([1], a: :some_method).message
          expected = Message.new(:responding_to, true, 1, :some_method)

          assert_equal :expression, message.namespace
          assert_equal expected, message.to_standard
        end

        it 'predicate' do
          matcher = Matcher.build { _[0].even? }
          message = matcher.match([1]).message
          expected = Message.new(:predicate, true, 1, :even?)

          assert_equal :expression, message.namespace
          assert_equal expected, message.to_standard
        end

        it 'between' do
          matcher = Matcher.build { _[0].between?(vars[:min], vars[:max]) }
          message = matcher.match([-1], min: 0, max: 10).message
          expected = Message.new(:between, true, -1, 0, 10)

          assert_equal :expression, message.namespace
          assert_equal expected, message.to_standard
        end

        it 'length_of' do
          matcher = Matcher.build { (_ + [3]).length == vars[:a] }
          message = matcher.match([1, 2], a: 2).message
          expected = Message.new(:length_of, true, [1, 2, 3], 2, 3)

          assert_equal :expression, message.namespace
          assert_equal expected, message.to_standard
        end

        it '==' do
          matcher = Matcher.build { _ * 2 == vars[:a] }
          message = matcher.match(2, a: 6).message
          expected = Message.new(:equal, true, 4, 6)

          assert_equal :expression, message.namespace
          assert_equal expected, message.to_standard
        end

        it '!=' do
          matcher = Matcher.build { _ * 2 != vars[:a] }
          message = matcher.match(2, a: 4).message
          expected = Message.new(:equal, false, 4, 4)

          assert_equal :expression, message.namespace
          assert_equal expected, message.to_standard
        end

        it '<' do
          matcher = Matcher.build { _ * 2 < vars[:a] }
          message = matcher.match(4, a: 6).message
          expected = Message.new(:less_than, true, 8, 6)

          assert_equal :expression, message.namespace
          assert_equal expected, message.to_standard
        end

        it '>' do
          matcher = Matcher.build { _ * 2 > vars[:a] }
          message = matcher.match(2, a: 6).message
          expected = Message.new(:greater_than, true, 4, 6)

          assert_equal :expression, message.namespace
          assert_equal expected, message.to_standard
        end

        it '<=' do
          matcher = Matcher.build { _ * 2 <= vars[:a] }
          message = matcher.match(4, a: 6).message
          expected = Message.new(:less_than_or_equal, true, 8, 6)

          assert_equal :expression, message.namespace
          assert_equal expected, message.to_standard
        end

        it '>=' do
          matcher = Matcher.build { _ * 2 >= vars[:a] }
          message = matcher.match(2, a: 6).message
          expected = Message.new(:greater_than_or_equal, true, 4, 6)

          assert_equal :expression, message.namespace
          assert_equal expected, message.to_standard
        end
      end
    end
  end
end
