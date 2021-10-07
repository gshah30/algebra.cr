require "arithmatic"

module IR

  alias Base = (Const | Var | Expr)

  class InvalidChararacterTokenException < Exception
    def initialize(value : Char | String)
      super "Character #{value} does not correspond to any token type"
    end
  end

  class UnknownChararacterException < Exception
    def initialize(value, index)
      super "Invalid character #{value} in the source at index #{index}."
    end
  end

  class InvalidTokenTypeException < Exception
    def initialize(token_type : TokenType)
      super "Invalid token type #{token_type} used to initialize token."
    end
  end

  enum TokenType : UInt8
    # operands
    CONSTANT = 1
    VARIABLE = 2
    # operators
    PLUS = 101
    MINUS = 102
    INTO = 103
    BY = 104
    POWER = 105
    # special tokens
    LBRACK = 200
    RBRACK = 201
    # null
    NULL = 0
  end

  struct Token

    def initialize(value : String, type : TokenType)
      raise InvalidTokenTypeException.new type unless [TokenType::VARIABLE, TokenType::CONSTANT].includes? type

      @value = value
      @type = type
    end

    getter value, type

    macro define_singleton_tokens(hash_node)
      # defines a class instance hash var from the hash_node HashLiteral ASTNode
      @@token_registry = Hash(Symbol, Token).new
      {% for type, value in hash_node %}
      @@token_registry[:{{type}}] = self.new({{value}})
      {% end %}

      # Expands to .methods like
      #
      # def self.plus
      #   @@token_registry[:plus]
      # end
      {% for type, value in hash_node %}
        def self.{{type}}
          @@token_registry[:{{type}}]
        end
      {% end %}
    end

    # Expands to #methods like
    #
    # def plus?
    #   type == TokenType::PLUS
    # end
    macro define_token_type_checkers(*types)
      {% for type in types %}
        def {{type}}?
          type == TokenType::{{type.stringify.upcase.id}}
        end
      {% end %}
    end

    private def initialize(value : Char)
      @value = value.to_s
      @type = case value
      when '+'
        TokenType::PLUS
      when '-'
        TokenType::MINUS
      when '*'
        TokenType::INTO
      when '/'
        TokenType::BY
      when '^'
        TokenType::POWER
      when '('
        TokenType::LBRACK
      when ')'
        TokenType::RBRACK
      when '\0'
        TokenType::NULL
      else
        raise InvalidChararacterTokenException.new @value
      end
    end

    define_singleton_tokens({plus: '+', minus: '-', into: '*', by: '/', power: '^', lbrack: '(', rbrack: ')', null: '\0'})

    define_token_type_checkers(constant, variable, null, plus, minus, power, into, by, lbrack, rbrack)

    def const?
      constant?
    end

    def var?
      variable?
    end

    def self.get(single_character : Char)
      case single_character
      when '+'
        @@token_registry[:plus]
      when '-'
        @@token_registry[:minus]
      when '*'
        @@token_registry[:into]
      when '/'
        @@token_registry[:by]
      when '^'
        @@token_registry[:power]
      when '('
        @@token_registry[:lbrack]
      when ')'
        @@token_registry[:rbrack]
      when '\0'
        @@token_registry[:null]
      else
        raise InvalidChararacterTokenException.new single_character
      end
    end

    def self.[](n : Int32) : Token
      Token.new n.to_s, TokenType::CONSTANT
    end

    def self.[](s : Symbol | String) : Token
      Token.new s.to_s, TokenType::VARIABLE
    end

    def self.[](c : Char)
      Token.get c
    end

    def ==(t : Token)
      @type == t.type && @value == t.value
    end

    def to_s : String
      "|#{@type} #{@value}|"
    end

    def to_s(io : IO) : IO
      io << to_s
    end
  end

  struct Constant

    def initialize(value : Int32)
      @value = value
    end

    def to_s(io : IO)
      io << @value.to_s
    end

    def self.[](value) : Constant
      Constant.new value
    end

    def evaluate
      @value
    end
  end
  alias Const = Constant

  struct Variable
    @name : String

    def initialize(name : String)
      @name = name
    end

    def to_s : String
      @name
    end

    def to_s(io : IO) : IO
      io << @name
    end

    def self.[](name) : Variable
      Variable.new name
    end
  end
  alias Var = Variable

  struct Power(T)

    def initialize(base : T, exponent : Rational)
      @base = base
      @exponent = exponent
    end

    getter base : T, exponent : Rational

    def to_s : String
      "#{@base}^#{@exponent}"
    end

    def to_s(io : IO) : IO
      io << to_s
    end

  end

  struct Term
    @negative : Bool = false
    @powers : Multiset(Power(Base))
    @representation : Hash(Base, Rational) = {} of Base => Rational

    def initialize
      @powers = Multiset(Power(Base)).new
    end

    def initialize(powers : Multiset(Power(Base)), negative : Bool = false)
      @negative = negative

      @powers = powers
      @powers.each{|p| accommodate p }
    end

    def powers
      @powers.dup
    end

    def rep
      representation
    end

    def representation
      @representation.dup
    end

    def negative?
      @negative
    end

    def negate!
      @negative = !@negative
    end

    def <<(p : Power(Base)) : Term
      @powers << p
      accommodate p

      self
    end

    def ===(t : Term)
      @negative == t.negative? && @powers == t.powers
    end

    def ==(t : Term) : Bool
      @negative == t.negative? && @representation == t.representation
    end

    def =~(t : Term) : Bool
      efficient == t.efficient
    end

    def coefficient : Hash(Const, Rational)
      @representation.compact_map do |b, e|
        b.is_a?(Const) ? {b.as Const, e} : nil
      end.to_h
    end

    def efficient : Hash(Var | Expr, Rational)
      @representation.compact_map do |b, e|
        b.is_a?(Const) ? nil : {b.as(Var | Expr), e}
      end.to_h
    end

    def to_s : String
      "T[#{("-1." if @negative)}#{@powers.map(&.to_s).join('.')}]"
    end

    def to_s(io : IO) : IO
      io << to_s
    end

    private def accommodate(p : Power(Base))
      @representation[p.base] = @representation.has_key?(p.base) ? @representation[p.base] + p.exponent : p.exponent
    end
  end

  # struct Term
  #   @power_product : PowerProduct(Base)

  #   def initialize
  #     @power_product = PowerProduct(Base).new({} of Base => Rational)
  #   end

  #   def initialize(pp : PowerProduct(Base))
  #     @power_product = pp
  #   end

  #   def <<(base : Base, exponent : Rational) : Term
  #     @power_product.<< **{ base: base, exponent: exponent }
  #     self
  #   end

  #   def <<(pp : PowerProduct(Base)) : Term
  #     pp.powers.each do |p|
  #       @power_product.<< **{ base: p[0], exponent: p[1] }
  #     end
  #     self
  #   end

  #   def to_s(io : IO)
  #     @power_product.to_s io
  #   end
  # end

  struct Expression
    @terms : Multiset(Term)
    @representation : Hash(Hash(Var | Expr, Rational),Hash(Const, Rational)) = {} of Hash(Var | Expr, Rational) => Hash(Const, Rational)

    def initialize
      @terms = Multiset(Term).new
      @representation = {} of Hash(Var | Expr, Rational) => Hash(Const, Rational)
    end

    def initialize(terms : Multiset(Term))
      @terms = terms
      @terms.each{|t| accommodate t }
    end

    def terms
      @terms.clone
    end

    def <<(t : Term) : Expr
      @terms << t
      accommodate t

      self
    end

    def rep
      representation
    end

    def representation
      @representation.clone
    end

    def ===(e : Expr)
      @terms == e.terms
    end

    def ==(e : Expr)
      @representation == e.representation
    end

    def to_s : String
      "E[#{@terms.map(&.to_s).join(' ')}]"
    end

    def to_s(io : IO) : IO
      io << to_s
    end

    private def accommodate(t : Term)
      @representation[t.efficient] = @representation.has_key?(t.efficient) ? add_coef_representations(@representation[t.efficient], t.coefficient.as Hash(Const, Rational)) : t.coefficient
    end

    private def add_coef_representations(rep1 : Hash(Const,Rational), rep2 : Hash(Const,Rational)) : Hash(Const, Rational)
      coef1 = rep1.reduce(1) do |acc, (k, v)|
        acc * (k.evaluate ** v.to_i)
      end

      coef2 = rep2.reduce(1) do |acc, (k, v)|
        acc * (k.evaluate ** v.to_i)
      end

      Factorization.prime(coef1 + coef2).wrap_base(Const).powers
    end
  end
  alias Expr = Expression

end