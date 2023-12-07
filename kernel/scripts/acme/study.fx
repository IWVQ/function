... script for testing new ideas

Phi :: Nat -> Nat
Phi n := Length [m | m |< [1 .. n], Gcd(m, n) = 1]

Ackermann :: (Nat, Nat) -> Nat
Ackermann(0, n) := n + 1
Ackermann(m, 0) := Ackermann(m - 1, 1)
Ackermann(m, n) := Ackermann(m - 1, Ackermann(m, n - 1))

DigitsCount :: Nat -> Nat
DigitsCount 0 := 1
DigitsCount n := 1 + Trunc(Ln(n)/Ln(10))

Mirror :: Nat -> Nat
Mirror 0 := 0
Mirror n := (n Rem 10)*10^((DigitsCount n) - 1) + Mirror(n Quot 10)

LimR :: Real -> (Real -> Real) -> (Real -> Real)
LimR a f := f(a + e) where e <- 0.000000001

LimL :: Real -> (Real -> Real) -> (Real -> Real)
LimL a f := f(a - e) where e <- 0.000000001

Lim :: Real -> (Real -> Real) -> (Real -> Real)
Lim := (LimR + LimL)/2 ... iff exists

Deriv :: (Real -> Real) -> Real -> Real
Deriv f x := Lim 0 g
    where g <- \h -> (f(x + h) - f(x))/h

NewtonRaphson :: (Real -> Real) -> Real -> Nat -> Real
NewtonRaphson f x0 0 := x0
NewtonRaphson f x0 n := NewtonRaphson f (x - f(x)/(Deriv f x)) (n - 1)

EraseList :: Nat -> [_] -> [_]
EraseList _ [] := Error "Invalid list index"
EraseList 0 (x >| xs) := xs
EraseList n (x >| xs) := EraseList xs (n - 1)

Matrix ::= [[Real]]
MinorMat :: Matrix -> Nat -> Nat -> Matrix
MinorMat m r c := EraseList r [EraseList c v | v |< m]
    
Cofactor :: Matrix -> Nat -> Nat -> Matrix
Cofactor m r c := (-1)^(r + c) * Det(MinorMat m r c)

Dim :: Matrix -> Nat
Dim m := Length m

Det :: Matrix -> Real
Det [[]] := 0
Det [[x]] := x
Det m := Sum[m{0, k} * Cofactor m 0 k | k |< [0 .. Dim m - 1]]


