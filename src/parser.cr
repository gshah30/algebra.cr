require "./ir"

include IR

module Parser

  def self.get_tokens(source : String)
    tokens = [] of Token | Nil
    alphabets = 'a'..'z'
    digits = '0'..'9'
    len = source.size

    i = 0
    while i < len
      tokens << case source[i]
      when ' ', '\t', '\r'
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

  def self.get_ir(src : String)
    tokens = get_tokens src

    expr_ir = expr tokens, 0
    expr_ir
  end

  def self.expr(tokens, i) : Tuple(Expr, UInt16)
    # term tokens, 0

    term_irs = Multiset(Term).new

    if tokens[i].plus? && tokens[i].minus?
      term_ir, i = term tokens, i
      term_irs << term_ir
    end

    while tokens[i].plus? || tokens[i].minus?
      term_ir, i = term tokens, i
      term_irs << term_ir
    end

    {Expr.new term_irs, i}
  end

  def self.term(tokens, i : UInt16) : Tuple(Term, UInt16)
    term_ir : Term = Term.new

    if tokens[i].plus? || tokens[i].minus?
      term_ir.<< **{ base: Const[-1], exponent: Rational[1] } if tokens[i].minus?
      i += 1
    end

    while tokens[i].const? || tokens[i].var? || tokens[i].lbrack?

      if tokens[i].const? && !tokens[i+1].power?
        term_ir << Factorization.prime(Rational[tokens[i].value]).wrap_base(Const)
        i += 1
      end

      if tokens[i].const? && tokens[i+1].power?
        term_ir << Factorization.prime(Rational[tokens[i].value.to_i ** tokens[i+2].value.to_i]).wrap_base(Const)
        i += 3
      end

      if tokens[i].var? && !tokens[i+1].power?
        term_ir.<< **{ base: Var[tokens[i].value], exponent: Rational[1] }
        i += 1
      end

      if tokens[i].var? && tokens[i+1].power?
        term_ir.<< **{ base: Var[tokens[i].value], exponent: Rational[tokens[i+2].value] }
        i += 3
      end

      # if tokens[i].lbrack?
      #   i += 1
      #   expr_ir, index = expr tokens, index
      #   raise ArgumentError, "Invalid token: #{tokens[index]} found at index: #{index}" if tokens[index].type != TokenType[:RBRACK]
      #   index += 1

      #   if tokens[index].type != TokenType[:POWER]
      #     expr_power_ir_map[expr_ir] = 1
      #   else
      #     expr_power_ir_map[expr_ir] = tokens[index+1].value.to_i
      #     index += 2
      #   end
      # end

    end

    {term_ir, i}

    # if tokens[i].constant?
    #   puts Factorization.prime(tokens[i].value.to_i).wrap_base(Constant)
    # end
  end

end