# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "matcher"

require "minitest/autorun"

module Minitest
  class Spec
    include Matcher::Assertions
    include Matcher::Testing
  end
end
