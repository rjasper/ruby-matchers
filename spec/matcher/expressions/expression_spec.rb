# frozen_string_literal: true

require "test_helper"

module Matcher
  describe Expression do
    let(:recorder) { Recorder.new(Variable.actual) }

    it "::of" do
      assert_equal Variable.actual, Expression.of(recorder)
      assert_equal Constant.new(1), Expression.of(1)
    end

    describe "::of" do
      it "Array" do
        array = Expression.build { [concat(vars[:a])] }

        var = Variable.new(:a)
        string = StringExpression.new([var])
        expected = ArrayExpression.new([string])

        assert_equal expected, array
      end

      it "Hash" do
        hash = Expression.build { { [vars[:a]] => vars[:b]..vars[:c] } }

        key = ArrayExpression.new([Variable.new(:a)])
        value = RangeExpression.new(Variable.new(:b), Variable.new(:c))
        expected = HashExpression.new([[key, value]])

        assert_equal expected, hash
      end

      it "Range" do
        range = Expression.build { expr(1)..vars[:z] }

        a = Constant.new(1)
        z = Variable.new(:z)
        expected = RangeExpression.new(a, z)

        assert_equal expected, range
      end

      it "Set" do
        set = Expression.build { Set[concat(vars[:a])] }

        var = Variable.new(:a)
        string = StringExpression.new([var])
        expected = SetExpression.new([string])

        assert_equal expected, set
      end
    end

    it "::try_recorder" do
      one = Constant.new(1)

      assert_equal one, Expression.try_recorder(one)
      assert_equal 1, Expression.try_recorder(1)
    end

    it "#given_for" do
      expr = expression { vars[:foo] + vars[:bar] }

      assert_equal(
        { foo: 1, bar: 2 },
        expr.given_for(foo: 1, bar: 2, qux: 3),
      )
    end

    it "#free_symbol" do
      expr = expression do
        vars[:foo].map { |bar| bar * 2 }
      end

      assert_equal :foo2, expr.free_symbol(:foo)
      assert_equal :bar2, expr.free_symbol(:bar)
      assert_equal :qux, expr.free_symbol(:qux)
    end
  end
end
