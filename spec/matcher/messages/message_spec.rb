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
    end
  end
end
