# frozen_string_literal: true

require "test_helper"
require "matcher/archive/error_labeler"

describe Matcher::ErrorLabeler do
  include Matcher::ErrorTesting

  let(:labeler) { Matcher::ErrorLabeler.new }

  it "returns the same label for equivalent errors" do
    foo = expression { _[:foo] }
    bar = expression { _[:bar] }
    foobar = expression { _[:foo][:bar] }

    bar_bax_or_bar_qux =
      _or(nested(bar, element("baz")), nested(bar, element("qux")))

    error1 = nested(foo, bar_bax_or_bar_qux)
    error2 = nested(foo, nested(bar, _or(element("baz"), element("qux"))))
    error3 = nested(foobar, _or(element("baz"), element("qux")))
    error4 = nested(foobar, _or(element("baz"), element("qucks")))

    label1, = labeler.label_tree(error1)
    label2, = labeler.label_tree(error2)
    label3, = labeler.label_tree(error3)
    label4, = labeler.label_tree(error4)

    assert_kind_of Integer, label1
    assert_equal label1, label2
    assert_equal label1, label3
    refute_equal label1, label4
  end

  it "returns all leaves" do
    foo = expression { _[:foo] }
    bar = expression { _[:bar] }
    bar_baz_or_bar_qux =
      _or(nested(bar, element("baz")), nested(bar, element("qux")))
    error = nested(foo, bar_baz_or_bar_qux)

    *, leaves = labeler.label_tree(error)

    assert_equal 2, leaves.length
    assert_equal "baz", leaves[0].message
    assert_equal [bar, foo], leaves[0].path.to_a
    assert_equal "qux", leaves[1].message
    assert_equal [bar, foo], leaves[1].path.to_a
  end
end
