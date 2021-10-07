require "./spec_helper"

describe Parser do
  describe ".get_tokens" do
    context "when source input contains allowed whitespace" do
      source_with_empty_space : String = "(701/ z)* ( 2x+ 3y^ 2- 1)"
      source_with_tab : String = "(701	/z)		*(2	x+		3y	^	2	-1)"
      source_with_empty_space_and_tab : String = "(701	/ z)	 	* ( 2	x+ 	3y	^	2	- 1 )"

      expected_tokens : Array(Token) = [
          Token.lbrack,
          Token[701],
          Token.by,
          Token.new("z", TokenType::VARIABLE),
          Token.rbrack,
          Token.into,
          Token.lbrack,
          Token.new("2", TokenType::CONSTANT),
          Token.new("x", TokenType::VARIABLE),
          Token.plus,
          Token.new("3", TokenType::CONSTANT),
          Token.new("y", TokenType::VARIABLE),
          Token.power,
          Token.new("2", TokenType::CONSTANT),
          Token.minus,
          Token.new("1", TokenType::CONSTANT),
          Token.rbrack,
          Token.null
        ]

      get_tokens_matcher = ->(src : String) do
        -> {
          extracted_tokens = Parser.get_tokens src
          extracted_tokens.should eq expected_tokens
        }
      end

      it "gets tokens from source #{source_with_empty_space}", &get_tokens_matcher.call(source_with_empty_space)
      it "gets tokens from source #{source_with_tab}", &get_tokens_matcher.call(source_with_tab)
      it "gets tokens from source #{source_with_empty_space_and_tab}", &get_tokens_matcher.call(source_with_empty_space_and_tab)
    end

  end

  describe ".term" do
    context "when tokens don't parse to an expression" do
      context "when tokens parse to a term with non-prime coefficient" do
        it "creates term_ir from tokens with minus sign" do
          tokens = [
            Token.minus,
            Token.new("36", TokenType::CONSTANT),
            Token.new("x", TokenType::VARIABLE),
            Token.power,
            Token.new("2", TokenType::CONSTANT),
            Token.new("y", TokenType::VARIABLE),
            Token.null
          ]
          term_ir, i = Parser.term tokens, 0

          i.should eq tokens.size-1

          term_ir.should eq Term.new(Multiset.new([
            Power(Base).new(Const[2], Rational[2]),
            Power(Base).new(Const[3], Rational[2]),
            Power(Base).new(Var["x"], Rational[2]),
            Power(Base).new(Var["y"], Rational[1])
          ]), negative: true)
        end

        it "creates term_ir from tokens with no sign" do
          tokens = [
            Token.new("36", TokenType::CONSTANT),
            Token.new("x", TokenType::VARIABLE),
            Token.power,
            Token.new("2", TokenType::CONSTANT),
            Token.new("y", TokenType::VARIABLE),
            Token.null
          ]
          term_ir, i = Parser.term tokens, 0

          i.should eq tokens.size-1

          term_ir.should eq Term.new(Multiset.new [
            Power(Base).new(Const[2], Rational[2]),
            Power(Base).new(Const[3], Rational[2]),
            Power(Base).new(Var["x"], Rational[2]),
            Power(Base).new(Var["y"], Rational[1])
          ])
        end

        it "creates term_ir from tokens with plus sign" do
          tokens = [
            Token.plus,
            Token.new("36", TokenType::CONSTANT),
            Token.new("x", TokenType::VARIABLE),
            Token.power,
            Token.new("2", TokenType::CONSTANT),
            Token.new("y", TokenType::VARIABLE),
            Token.null
          ]
          term_ir, i = Parser.term tokens, 0

          i.should eq tokens.size-1

          term_ir.should eq Term.new(Multiset.new [
            Power(Base).new(Const[2], Rational[2]),
            Power(Base).new(Const[3], Rational[2]),
            Power(Base).new(Var["x"], Rational[2]),
            Power(Base).new(Var["y"], Rational[1])
          ])
        end
      end

      context "when tokens parse to a term with prime coefficient" do
        it "creates term_ir from tokens with minus sign" do
          tokens = [
            Token.minus,
            Token.new("7", TokenType::CONSTANT),
            Token.new("x", TokenType::VARIABLE),
            Token.power,
            Token.new("2", TokenType::CONSTANT),
            Token.new("y", TokenType::VARIABLE),
            Token.null
          ]
          term_ir, i = Parser.term tokens, 0

          i.should eq tokens.size-1

          term_ir.should eq Term.new(Multiset.new([
            Power(Base).new(Const[7], Rational[1]),
            Power(Base).new(Var["x"], Rational[2]),
            Power(Base).new(Var["y"], Rational[1])
          ]), negative: true)
        end

        it "creates term_ir from tokens with no sign" do
          tokens = [
            Token.new("7", TokenType::CONSTANT),
            Token.new("x", TokenType::VARIABLE),
            Token.power,
            Token.new("2", TokenType::CONSTANT),
            Token.new("y", TokenType::VARIABLE),
            Token.null
          ]
          term_ir, i = Parser.term tokens, 0

          i.should eq tokens.size-1
          term_ir.should eq Term.new(Multiset.new [
            Power(Base).new(Const[7], Rational[1]),
            Power(Base).new(Var["x"], Rational[2]),
            Power(Base).new(Var["y"], Rational[1])
          ])
        end

        it "creates term_ir from tokens with plus sign" do
          tokens = [
            Token.plus,
            Token.new("7", TokenType::CONSTANT),
            Token.new("x", TokenType::VARIABLE),
            Token.power,
            Token.new("2", TokenType::CONSTANT),
            Token.new("y", TokenType::VARIABLE),
            Token.null
          ]
          term_ir, i = Parser.term tokens, 0

          i.should eq tokens.size-1
          term_ir.should eq Term.new(Multiset.new [
            Power(Base).new(Const[7], Rational[1]),
            Power(Base).new(Var["x"], Rational[2]),
            Power(Base).new(Var["y"], Rational[1])
          ])
        end
      end
    end

    context "when tokens parse to term having expression base" do
      it "creates term_ir from tokens with minus sign" do
        tokens = [
          Token.minus,
          Token[:x],
          Token.lbrack,
          Token.minus,
          Token[7],
          Token[:x],
          Token.power,
          Token[2],
          Token.plus,
          Token[3],
          Token.rbrack,
          Token.power,
          Token[2],
          Token[:y],
          Token.power,
          Token[3],
          Token.null
        ]
        term_ir, i = Parser.term tokens, 0

        i.should eq tokens.size-1

        term_ir.should eq Term.new(Multiset.new([
          Power(Base).new(Var["x"], Rational[1]),
          Power(Base).new(Expr.new(Multiset.new([
            Term.new(Multiset.new([
              Power(Base).new(Const[7], Rational[1]),
              Power(Base).new(Var["x"], Rational[2]),
            ]), negative: true),
            Term.new(Multiset.new([
              Power(Base).new(Const[3], Rational[1])
            ]))
          ])), Rational[2]),
          Power(Base).new(Var["y"], Rational[3])
        ]), negative: true)
      end
    end

  end

  describe ".expr" do
    it "creates expr_ir from tokens" do
      tokens = [
        Token['-'],
        Token[36],
        Token[:x],
        Token['^'],
        Token[2],
        Token[:y],
        Token['+'],
        Token[3],
        Token[:z],
        Token.null
      ]
      expr_ir, _ = Parser.expr tokens, 0

      puts expr_ir
    end
  end
end