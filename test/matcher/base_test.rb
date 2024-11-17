# frozen_string_literal: true

require 'test_helper'

describe Matcher::Base do
  it 'checks match level' do
    matcher = Matcher.build do
      refs[:obj] = project(_.dup) ^ refs[:obj]
    end

    Matcher.stub(:max_depth, 2) do
      assert_expected_errors matcher.match(Object.new),
        expression { _.dup.dup } => 'match level too deep: 3'
    end
  end
end
