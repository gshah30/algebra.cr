struct Proc
  def <<(block : Proc(*U, V)) forall U, V
    Proc(*T, V).new { |arg| call(block.call(arg)) }
  end
end

# def add(x : Int32)
#   x + 1
# end

# def sub(x : Int32)
#   x - 1
# end

# def mult(x : Int32)
#   x * 9
# end

add = ->(x : Int32) { x+ 1 }
mult = ->(x : Int32) { x * 10 }

x = add << mult
p! x.call(10)