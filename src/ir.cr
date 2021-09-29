module IR

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

  class Token

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

    def initialize(value : String, type : TokenType)
      raise InvalidTokenTypeException.new type unless [TokenType::VARIABLE, TokenType::CONSTANT].includes? type

      @value = value
      @type = type
    end

    getter value, type

    define_singleton_tokens({plus: '+', minus: '-', into: '*', by: '/', power: '^', lbrack: '(', rbrack: ')', null: '\0'})

    define_token_type_checkers(constant, variable, null, plus, minus, power, into, by, lbrack, rbrack)

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

    def ==(t : Token)
      @type == t.type && @value == t.value
    end

    def to_s
      "|#{@type} #{@value}|"
    end
  end

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

  class Constant
    def initialize(value : UInt32)
      @value = value
    end
  end

end