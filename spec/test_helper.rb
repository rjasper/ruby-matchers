# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "matcher"
require "matcher/testing"
require "minitest/autorun"

module Minitest
  class Spec
    include Matcher::Testing
  end
end
