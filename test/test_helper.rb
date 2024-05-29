# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "matcher"

require "minitest/autorun"

module ActiveSupport
  class TestCase
    include Matcher::Assertions
  end
end
