# frozen_string_literal: true

module Matcher
  class List
    include Enumerable

    def self.empty
      EmptyList.instance
    end

    def self.one(item)
      NonEmptyList.new(item)
    end

    def to_s
      to_a.to_s
    end
    alias inspect to_s
  end

  class EmptyList < List
    include Singleton

    def add(item)
      NonEmptyList.new(item)
    end
    alias << add

    def empty?
      true
    end

    def last
      nil
    end

    def each
      self
    end

    def reverse_each
      return to_enum(:reverse_each) unless block_given?

      self
    end

    def to_a
      []
    end
  end

  class NonEmptyList < List
    attr_reader :head, :tail

    def initialize(head, tail = nil)
      super()

      @head = head
      @tail = tail
    end

    def empty?
      false
    end

    def add(item)
      NonEmptyList.new(item, self)
    end
    alias << add

    def last
      @tail&.last || @head
    end

    def hash
      @hash ||= [self.class, @head, @tail].hash
    end

    def ==(other)
      return true if equal?(other)

      other.instance_of?(NonEmptyList) &&
        @head.eql?(other.head) &&
        @tail.eql?(other.tail)
    end
    alias eql? ==

    def each
      c = self

      while c
        yield c.head
        c = c.tail
      end
    end

    def reverse_each(&)
      @tail&.reverse_each(&)
      yield @head
    end
  end
end
