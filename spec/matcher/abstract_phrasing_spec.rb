# frozen_string_literal: true

require 'test_helper'

describe Matcher::AbstractPhrasing do
  let(:klass) { Class.new(Matcher::AbstractPhrasing) }

  it 'phrases a defined message' do
    klass.define(:hello) { |you| "Hello #{you}!" }
    message = Matcher::Message.new(:hello, false, nil, 'World')
    my_phrasing = klass.new(nil, message)

    assert_equal 'Hello World!', my_phrasing.apply
  end

  it 'supports namespaces' do
    klass.namespace(:polite) do
      klass.define(:greeting) { |you| "Welcome #{you}!" }
    end

    message = Matcher::Message.new(%i[polite greeting], false, nil, 'World')
    my_phrasing = klass.new(nil, message)

    assert_equal 'Welcome World!', my_phrasing.apply
  end

  it 'provides context (path, actual, negated)' do
    klass.define(:expected) { "#{path}: expected#{' not' if negated} #{actual}" }
    message = Matcher::Message.new(:expected, true, 42)
    path = expression { _.foo }
    my_phrasing = klass.new(path, message)

    assert_equal '_.foo: expected not 42', my_phrasing.apply
  end

  it 'phrases other message' do
    klass.define(:hello) { |you| phrase(:welcome, you) }
    klass.define(:welcome) { |you| "Welcome #{you}!" }
    message = Matcher::Message.new(:hello, false, nil, 'World')
    my_phrasing = klass.new(nil, message)

    assert_equal 'Welcome World!', my_phrasing.apply
  end

  it 'negates message' do
    klass.define(:yes) { negated ? 'No' : 'Yes' }
    klass.define(:negate) { phrase_negated(:yes) }

    message1 = Matcher::Message.new(:negate, false, nil)
    message2 = Matcher::Message.new(:negate, true, nil)

    assert_equal 'No', klass.new(nil, message1).apply
    assert_equal 'Yes', klass.new(nil, message2).apply
  end

  it 'phrases fallback message' do
    message = Matcher::Message.new(:got, true, 42)
    my_phrasing = klass.new(nil, message)

    assert_equal 'got 42 but found no message for :got (negated)', my_phrasing.apply
  end
end
