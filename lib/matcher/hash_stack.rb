# frozen_string_literal: true

module Matcher
  class HashStack
    extend Forwardable

    def initialize
      @stacks = {}
    end

    def_delegators :@stacks, :empty?, :key?, :keys
    def_delegators :to_h, :merge

    def [](key)
      @stacks[key]&.last
    end

    def push(hash)
      hash.each do |k, v|
        (@stacks[k] ||= []) << v
      end
    end

    def pop(hash)
      hash.each_key do |k|
        array = @stacks[k]
        array.pop

        @stacks.delete(k) if array.empty?
      end
    end

    def slice(*keys)
      keys.each_with_object({}) do |k, h|
        pair = @stacks.assoc(k)

        next unless pair

        h[k] = pair[1].last
      end
    end

    def merge(hash)
      hash.default_proc = ->(h, k) { h[k] = self[k] }
      hash
    end

    def to_h
      @stacks.transform_values(&:last)
    end
    alias to_hash to_h
  end
end
