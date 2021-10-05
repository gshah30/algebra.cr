require "./spec_helper"

include IR

macro describe_singleton_tokens(hash_node)
  {% for type, value in hash_node %}
  describe ".{{type}}" do
    it "creates a TokenType::{{type.stringify.upcase.id}} token" do
      Token.{{type}}.tap do |t|
        t.value.should eq {{value}}.to_s
        t.type.should eq TokenType::{{type.stringify.upcase.id}}
      end
    end
  end
  {% end %}
end

macro describe_singleton_token_getters_and_type_checkers(hash_node)
  {% for type, value in hash_node %}
  describe ".get" do
    context "\#{{type}}?" do
      it "checks if a token represents {{value}}" do
        Token.get({{value}}).{{type}}?.should be_true
      end
    end
  end
  {% end %}

  describe "#constant?" do
    it "checks if a token represents a constant" do
      Token.new("707", TokenType::CONSTANT).constant?.should be_true
    end
  end

  describe "#variable?" do
    it "checks if a token represents a variable" do
      Token.new("x", TokenType::VARIABLE).variable?.should be_true
    end
  end
end

macro describe_string_representation_of_tokens(hash_node)
  describe "#to_s" do
  {% for type, value in hash_node %}
    context "when token type is {{type}}" do
      it "prints token value and type" do
        Token.{{type}}.to_s.should eq "|#{TokenType::{{type.stringify.upcase.id}}} #{{{value}}.to_s}|"
      end
    end
  {% end %}

    context "when token type is constant" do
      it "prints token value and type" do
        Token.new("707", TokenType::CONSTANT).to_s.should eq "|#{TokenType::CONSTANT} 707|"
      end
    end

    context "when token type is variable" do
      it "prints token value and type" do
        Token.new("x", TokenType::VARIABLE).to_s.should eq "|#{TokenType::VARIABLE} x|"
      end
    end
  end
end

describe IR do
  describe Token do
    describe "#initialize" do
      {
        '+' => TokenType::PLUS,
        '-' => TokenType::MINUS,
        '*' => TokenType::INTO,
        '/' => TokenType::BY,
        '^' => TokenType::POWER,
        '(' => TokenType::LBRACK,
        ')' => TokenType::RBRACK
      }.each do |value, type|
        context "when valid single character argument is #{value}" do
          it "initializes token type to #{type}" do
            (Token.get value).tap do |t|
              t.value.should eq value.to_s
              t.type.should eq type
            end
          end
        end
      end

      context "when string and valid type are arguments" do
        {
          "235" => TokenType::CONSTANT,
          "x" => TokenType::VARIABLE
        }
        .each do |value, type|
          it "initializes a token from the string #{value} with type #{type}" do
            (Token.new value, type).tap do |t|
              t.value.should eq value
              t.type.should eq type
            end
          end
        end
      end

      context "when string and invalid type are arguments" do
        [
          TokenType::PLUS,
          TokenType::MINUS,
          TokenType::POWER,
          TokenType::BY,
          TokenType::INTO,
          TokenType::LBRACK,
          TokenType::RBRACK
        ]
        .each do |type|
          it "raises InvalidTokenTypeException" do
            expect_raises InvalidTokenTypeException, "Invalid token type #{type} used to initialize token." do
              Token.new "some string", type
            end
          end
        end
      end
    end

    describe ".get" do
      context "when single character argument is invalid" do
        invalid_character_token = ['~', '@', '!', '#', '$', '%', '&', '_', '='].sample

        it "raises an exception" do
          expect_raises InvalidChararacterTokenException, "Character #{invalid_character_token} does not correspond to any token type" do
            Token.get invalid_character_token
          end
        end
      end
    end

    describe_singleton_tokens({plus: '+', minus: '-', into: '*', by: '/', power: '^', lbrack: '(', rbrack: ')', null: '\0'})

    describe_singleton_token_getters_and_type_checkers({plus: '+', minus: '-', into: '*', by: '/', power: '^', lbrack: '(', rbrack: ')', null: '\0'})

    describe_string_representation_of_tokens({plus: '+', minus: '-', into: '*', by: '/', power: '^', lbrack: '(', rbrack: ')', null: '\0'})

  end
end