# frozen_string_literal: true

require 'test_helper'
require 'matcher/archive/nested_expression_normalizer'

describe Matcher::NestedExpressionNormalizer do
  def examine(keys, recorder)
    expected = keys.map do |obj|
      if Matcher::Recorder.recorder?(obj)
        Matcher::Recorder.to_expression(obj)
      else
        obj
      end
    end

    recorder = Matcher::Recorder.to_expression(recorder)
    actual = Matcher::NestedExpressionNormalizer.normalize(recorder)

    assert_equal expected, actual
  end

  it 'normalizes nested expressions' do
    t = self

    Matcher::Builder.new.instance_exec do
      t.examine [], _
      t.examine [:a], _[:a]
      t.examine [_.a], _.a
      t.examine [_.a, :b], _.a[:b]

      t.examine [_.a('foo').b, :c, :d],
        _.a('foo').b[:c][:d]
      t.examine [_.a.b, :c, :d],
        _.a.b[:c][:d]
      t.examine [_.a, _ + _],
        _.a + _.a
      t.examine [_.a, _ + _.b],
        _.a + _.a.b
      t.examine [:a, _ + _],
        _[:a] + _[:a]
      t.examine [:a, expr(Math).sqrt(_)],
        expr(Math).sqrt(_[:a])
      t.examine [_.a, :b, _.c.d, :e, :f, _.g],
        _.a[:b].c.d[:e][:f].g
      t.examine [:a, _.z, (_ + _.b(k: _)).c(_)],
        (_[:a].z + _[:a].z.b(k: _[:a].z)).c(_[:a].z)

      block = proc { |_| _ + 1 }
      t.examine [_[:a] + expr(&block)],
        _[:a] + expr(&block)
    end
  end
end
