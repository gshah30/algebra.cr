require "./spec_helper"

describe Parser do
  describe ".get_tokens" do
    it "gets tokens from source string" do

      extracted_tokens = Parser.get_tokens "(71/z)*(2x+3y^2-1)"
      # puts extracted_tokens.map &.to_s

      expected_tokens = [
        Token.lbrack,
        Token.new("71", TokenType::CONSTANT),
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

      extracted_tokens.should eq expected_tokens
    end
  end

  describe ".term" do
    it "creates term_ir" do
      tokens = [
        Token.new("36", TokenType::CONSTANT),
        Token.new("x", TokenType::VARIABLE),
        Token.power,
        Token.new("2", TokenType::CONSTANT),
        Token.new("y", TokenType::VARIABLE),
        Token.null
      ]
      term_ir = Parser.term(tokens, 0)

      puts term_ir
    end
  end
end