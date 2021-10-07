require "multiset"

require "./ir"

include IR
include Numbers

module Parser

  class InvalidTokensForPowerConversion < Exception
    def initialize(t : Token, e : Token)
      super "Tokens #{t} and #{e} can't be converted to powers"
    end
  end

  class InvalidTokenSequence < Exception
    def initialize(msg : String)
      super msg
    end
  end

  def self.get_tokens(source : String) : Array(Token)
    tokens = [] of Token | Nil
    alphabets = 'a'..'z'
    digits = '0'..'9'
    len = source.size

    i = 0
    while i < len
      tokens << case source[i]
      when ' ', '\t'
        nil
      when '+', '-', '*', '/', '^', '(', ')'
        Token.get source[i]
      when alphabets
        Token.new source[i].to_s, TokenType::VARIABLE
      when digits
        constant = ""
        while digits.covers? source[i+1]
          constant += source[i]
          i += 1
        end
        constant += source[i]
        Token.new constant, TokenType::CONSTANT
      else
        raise UnknownChararacterException.new source[i], i
      end
      i += 1
    end

    tokens.compact + [Token.null]
  end

  def self.get_ir(src : String) : Expr
    tokens = get_tokens src

    expr_ir, _ = expr tokens, 0
    expr_ir
  end

  def self.expr(tokens : Array(Token), i : UInt16) : Tuple(Expr, UInt16)
    expr_ir = Expr.new

    if !tokens[i].plus? && !tokens[i].minus?
      term_ir, i = term tokens, i
      expr_ir << term_ir
    end

    while tokens[i].plus? || tokens[i].minus?
      term_ir, i = term tokens, i
      expr_ir << term_ir
    end

    {expr_ir, i}
  end

  def self.const_tokens_to_powers(base_token : Token, exponent_token : Token = Token.null) : Hash(Int32, Rational)

    unless base_token.const? && (exponent_token.const? || exponent_token.null?)
      raise InvalidTokensForPowerConversion.new base_token, exponent_token
    end

    constant = exponent_token.null? ? Rational[base_token.value] : Rational[base_token.value.to_i ** exponent_token.value.to_i]
    Factorization.prime(constant).powers
  end

  def self.term(tokens, i : UInt16) : Tuple(Term, UInt16)
    term_ir : Term = Term.new

    if tokens[i].plus? || tokens[i].minus?
      term_ir.negate! if tokens[i].minus?
      i += 1
    end

    while tokens[i].const? || tokens[i].var? || tokens[i].lbrack?

      if tokens[i].const? && !tokens[i+1].power?
        const_tokens_to_powers(tokens[i]).each{|k, v| term_ir << Power.new(Const[k], v) }
        i += 1
      end

      if tokens[i].const? && tokens[i+1].power?
        const_tokens_to_powers(tokens[i], tokens[i+2]).each{|k, v| term_ir << Power.new(Const[k], v) }
        i += 3
      end

      if tokens[i].var? && !tokens[i+1].power?
        term_ir << Power.new(Var[tokens[i].value], Rational[1])
        i += 1
      end

      if tokens[i].var? && tokens[i+1].power?
        term_ir << Power.new(Var[tokens[i].value], Rational[tokens[i+2].value])
        i += 3
      end

      if tokens[i].lbrack?
        i += 1
        expr_ir, i = expr tokens, i

        unless tokens[i].rbrack?
          raise InvalidTokenSequence.new "Invalid token sequence: #{tokens[i]} found at index #{i}, #{Token.rbrack} expected"
        end
        i += 1

        unless tokens[i].power?
          term_ir << Power.new expr_ir, Rational[1]
        else
          term_ir << Power.new expr_ir, Rational[tokens[i+1].value]
          i += 2
        end
      end
    end

    {term_ir, i}

  end

end