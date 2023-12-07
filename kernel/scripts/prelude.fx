... prelude.fx

... Types

Nat      ::= nat
Int      ::= int
Real     ::= real
Bool     ::= bool
Char     ::= char
String   ::= [Char]
Function ::= _ -> _
Pair     ::= (_, _)
List     ::= [_]
Degree   ::= real ... 0..360
Radian   ::= real ... 0..2pi

... Notation

prefix ~
posfix !
infixr 240 @
infixr 180 ^
infixl 175 /
infixl 175 Div
infixl 175 Quot
infixr 175 %
infixl 170 Mod
infixl 170 Rem
infixl 170 *
infixl 165 -
infixl 160 +
infixr 150 And
infixr 145 Or Xor
infixl 140 Shl Shr
infixl 130 ++
infix  110 Elm
infix  100 < > = <> <= >=
infixr 80  &&
infixr 75  ||
infixl 5   >>=
infixr 5   =<<

... Required definitions ...

IfThenElse :: (bool, _, _) -> _
IfThenElse(true, y, _) := y
IfThenElse(false, _, n) := n

GetElm :: [nat] -> _ -> _
GetElm [] a := a
GetElm :: [nat] -> [_] -> _
GetElm (i >| is) xs := GetElm is (PrimGet(xs, i))

GetElm :: [nat] -> _ -> _ ... para tuplas
GetElm (i >| is) xt := GetElm is (PrimSelect(xt, i))

ListFromTo :: real -> real -> [real]
ListFromTo a b := GenerateUntil a b 1 (>)

ListFromThenTo :: real -> real -> real -> [real]
ListFromThenTo a b c := GenerateUntil a c (b-a) ((a < b)?(>); (<))

IfFalse :: bool -> _ -> _
IfFalse true _ := fail
IfFalse false x := x

FlatMap :: (_ -> [_]) -> [_] -> [_]
FlatMap f [] := []
FlatMap f (x >| xs) := (f x) ++ (FlatMap f xs)

NotEmpty :: [_] -> bool
NotEmpty [] := false
NotEmpty _  := true

WhileSkeleton vt := InsertLambda((\w -> w (WhileSkeleton vt)), InsertLambda(IfThenElse, vt))

... Required for required definitions

++ :: ([_], [_]) -> [_]
[] ++ ys := ys
(x >| xs) ++ ys:= x >| (xs ++ ys)

SetElm :: _ -> [nat] -> _ -> [_]
SetElm a [] _ := a
SetElm :: _ -> [nat] -> [_] -> [_]
SetElm a (i >| is) xs := PrimSet(SetElm a is (PrimGet(xs, i)), xs, i)

GenerateUntil :: real -> real -> real -> ((_, _) -> bool) -> [real]
GenerateUntil a b s f := (f(a, b))? []; a >| (GenerateUntil (a+s) b s f)

InsertLambda(f, l) := \x -> f(l x)

Case :: _ -> [_ -> _] -> _
Case _ [] := fail ... use "fail" for many reasons
Case a (f >| fs) := f a ; Case a fs

... type testing

IsNat :: Nat -> Bool
IsNat n := true
IsNat _ := false ... if pattern is _ then any values of any types matchs with

IsInt :: Int -> Bool
IsInt n := true
IsInt _ := false

IsReal :: Real -> Bool
IsReal x := true
IsReal _ := false

IsNum := IsReal

IsBool :: Bool -> Bool
IsBool b := true
IsBool _ := false

IsChar :: Char -> Bool
IsChar c := true
IsChar _ := false

IsString :: String -> Bool
IsString s := true
IsString _ := false

IsList :: [_] -> Bool
IsList [] := true
IsList (_ >| _) := true
IsList _ := false

IsAnonymous :: _ -> Bool
IsAnonymous a := PrimIsAnonymous a

IsFreeIdentifier :: _ -> Bool
IsFreeIdentifier v := PrimIsFreeIdentifier v

IsTuple :: _ -> Bool
IsTuple t := PrimIsTuple t

IsLambda :: _ -> Bool
IsLambda l := PrimIsLambda l

IsFunction :: Function -> Bool
IsFunction f := true
IsFunction _ := false

... System

Quit :: () -> ()
Quit() := PrimQuit()

Interrupt :: () -> ()
Interrupt() := PrimInterrupt()

Restart :: () -> ()
Restart() := PrimRestart()

Ans :: () -> _
Ans() := PrimAnswer()

... IO

Write :: _ -> ()
Write v := PrimOutput(ValueToStr v)

ReadStr :: () -> String
ReadStr() := PrimInput()

ReadNum :: () -> Real
ReadNum() := StrToNum(PrimInput())

ReadChar :: () -> Char
ReadChar() := StrToChar(PrimInput())

ReadBool :: () -> Bool
ReadBool() := StrToBool(PrimInput())

ClrScr :: () -> ()
ClrScr() := PrimClearScreen()

Output :: String -> ()
Output s := PrimOutput s

Input :: () -> String
Input() := PrimInput()

Input :: String -> String
Input s :=
    begin
        Output s
        return Input()
    end

Print :: String -> ()
Print s := Output(s ++ "\n")

... String casting

ValueToStr :: _ -> String
ValueToStr v := PrimValueToStr v

TypeToStr :: _ -> String
TypeToStr t := PrimTypeToStr t

ValueToStrFull :: _ -> String
ValueToStrFull v := PrimValueToStrFull v

TryStrToNum :: String -> (Real, Bool)
TryStrToNum s := PrimTryStrToNum s

StrToNum :: String -> Real
StrToNum s := n where (n, _) <- TryStrToNum s

StrToChar :: String -> Char
StrToChar "" := Error "String is not character"
StrToChar [c] := c
StrToChar _ := Error "String is not character"

StrToBool :: String -> Bool
StrToBool "true" := true
StrToBool "false" := false
StrToBool _ := Error "String is not boolean"

NumToStr :: Real -> String
NumToStr n := ValueToStr n

CharToStr :: Char -> String
CharToStr c := [c]

BoolToStr :: Bool -> String
BoolToStr true := "true"
BoolToStr false := "false"

... Messages

Error :: String -> _
Error s := PrimError s

Failure :: String -> _
Failure s :=
    begin
        Print("\nFailure: " ++ s)
        return fail
    end

Message :: String -> ()
Message s := Print("\nMessage: " ++ s)

... Boolean

DecodeBool :: Bool -> Nat
DecodeBool true := 1
DecodeBool false := 0

EncodeBool :: Nat -> Bool
EncodeBool n := (n Rem 2) = 1

~ :: Bool -> Bool
~true := false
~false := true

&& :: (Bool, Bool) -> Bool
false && x := false
true && x := x

|| :: (Bool, Bool) -> Bool
false || x := x
true || x := true

= :: (Bool, Bool) -> Bool
true = x := x
false = x := ~x

< :: (Bool, Bool) -> Bool
false < true := true
p < q := false

> :: (Bool, Bool) -> Bool
true > false := true
p > q := false

ListFromTo :: Bool -> Bool -> [Bool]
ListFromTo a b := Map EncodeBool [DecodeBool a .. DecodeBool b]

Otherwise := true

Next :: Bool -> Bool
Next b := EncodeBool(Next(DecodeBool b))

Prev :: Bool -> Bool
Prev b := EncodeBool(Prev(DecodeBool b))

... Numeric

+ :: (Real, Real) -> Real
a + b := PrimAdd(a, b)

- :: (Real, Real) -> Real
a - b := PrimSub(a, b)

* :: (Real, Real) -> Real
a * b := PrimMul(a, b)

/ :: (Real, Real) -> Real
a / b := PrimDiv(a, b)

^ :: (Real, Real) -> Real
a ^ b := PrimPow(a, b)

< :: (Real, Real) -> Bool
a < b := PrimLess(a, b)

> :: (Real, Real) -> Bool
a > b := PrimGreater(a, b)

= :: (Real, Real) -> Real
a = b := PrimEqual(a, b)

IsNaN :: Real -> Bool
IsNaN n := PrimIsNaN n

Neg :: Real -> Real
Neg n := -n

Trunc :: Real -> Int
Trunc x := PrimTrunc x

Frac :: Real -> Real
Frac x := PrimFrac x

Sqrt :: Real -> Real
Sqrt(x) := x^(1/2)

Root :: Real -> Real -> Real
Root n x := x^(1/n)

Abs :: Real -> Real
Abs x := x > 0? x;
         x = 0? 0;
         x < 0? -x

Rem :: (Int, Int) -> Int
a Rem b := PrimRem(a, b)

Quot :: (Int, Int) -> Int
a Quot b := PrimQuot(a, b)

Not :: Int -> Int
Not p := PrimBitNot p

And :: (Int, Int) -> Int
p And q := PrimBitAnd(p, q)

Or :: (Int, Int) -> Int
p Or q := PrimBitOr(p, q)

Xor :: (Int, Int) -> Int
p Xor q := (p And Not(q)) Or (Not(p) And q)

Shl :: (Int, Int) -> Int
p Shl b := PrimBitShl(p, b)

Shr :: (Int, Int) -> Int
p Shr b := PrimBitShr(p, b)

Sin :: Real -> Real
Sin x := PrimSin x

Cos :: Real -> Real
Cos x := PrimCos x

Tan :: Real -> Real
Tan x := PrimTan x

Cot :: Real -> Real
Cot x := 1 / Tan x

Sec :: Real -> Real
Sec x := 1 / Cos x 

Csc :: Real -> Real
Csc x := 1 / Sin x 

ASin :: Real -> Real
ASin x := PrimASin x

ACos :: Real -> Real
ACos x := PrimACos x

ATan :: Real -> Real
ATan x := PrimATan x

ACot :: Real -> Real
ACot 0 := Pi/2
ACot x := ATan(1/x)

ASec :: Real -> Real
ASec x := ACos(1/x)

ACsc :: Real -> Real
ACsc x := ASin(1/x)

ATan2 :: (Real, Real) -> Real
ATan2(y, 0) := Sign(y)*Pi/2
ATan2(y, x) := ATan(y/x)

Ln :: Real -> Real
Ln x := PrimLn x

Exp :: Real -> Real
Exp x := PrimExp x

Log :: Real -> Real -> Real
Log b x := Ln(x) / Ln(b)

SinH :: Real -> Real
SinH x := (Exp(x) - Exp(-x)) / 2

CosH :: Real -> Real
CosH x := (Exp(x) + Exp(-x)) / 2

TanH :: Real -> Real
TanH x := SinH x / CosH x

CotH :: Real -> Real
CotH(x) := 1 / TanH(x)

SecH :: Real -> Real
SecH x := 1 / CosH x

CscH :: Real -> Real
CscH x := 1 / SinH x

ASinH :: Real -> Real
ASinH x := Ln(x + Sqrt(x^2 + 1))

ACosH :: Real -> Real
ACosH x := Ln(x + Sqrt(x^2 - 1))

ATanH :: Real -> Real
ATanH x := Ln((1 + x)/(1 - x)) / 2

ACotH :: Real -> Real
ACotH x := Ln((x + 1)/(x - 1)) / 2

ASecH :: Real -> Real
ASecH x := Ln((1 + Sqrt(1 - x^2))/x)

ACscH :: Real -> Real
ACscH x := Ln((1 + Sqrt(1 + x^2))/x)

Pi := 4*ATan(1) ... 3.141592653589793

E  := Exp(1) ... 2.718281828459045

Prev :: Int -> Int
Prev n := n - 1

Next :: Int -> Int
Next n := n + 1

! :: Nat -> Nat
0! := 1
n! := n*(n-1)!

Odd :: Int -> Bool
Odd n := (n Rem 2) = 1

Even :: Int -> Bool
Even n := (n Rem 2) = 0

% :: (Real, Real) -> Real
a % b := (a*b)/100

Sign :: Real -> Real
Sign x := x > 0? 1;
          x = 0? 0;
          x < 0? -1

... a = bq + r , 0 <= r < |b|
DivMod :: (Int, Int) -> (Int, Int)
DivMod(a, b) :=
    begin
        r <- a Rem b
        r <- r < 0? r + Abs(b) ; r
        q <- (a - r) Quot b
        return(r, q)
    end
    
Mod :: (Int, Int) -> Int
a Mod b := r where (r, _) <- DivMod(a, b)

Div :: (Int, Int) -> Int
a Div b := q where (_, q) <- DivMod(a, b)

Max :: (Real, Real) -> Real
Max(a, b) := a > b ? a ; b

Min :: (Real, Real) -> Real
Min(a, b) := a < b ? a ; b

Gcd :: (Nat, Nat) -> Nat
Gcd(0, 0) := Error "Undefined gcd for (0,0)"
Gcd(x, 0) := x
Gcd(x, y) := Gcd(y, x Rem y)

Gcd :: (Int, Int) -> Int
Gcd(x, y) := Gcd(Abs(x), Abs(y))

Lcm :: (Int, Int) -> Int
Lcm(_, 0) := 0
Lcm(0, _) := 0
Lcm(x, y) := Abs((x Quot Gcd(x, y))*y)

Floor :: Real -> Int
Floor x := Frac(x) < 0 ? Trunc(x) - 1 ; Trunc(x)

Ceil :: Real -> Int
Ceil x := Frac(x) > 0 ? Trunc(x) + 1 ; Trunc(x)

Round :: Real -> Int
Round x := begin
        n <- Trunc x
        r <- Frac x
        m <- r < 0 ? n - 1 ; n + 1
        return
            Case (Sign(Abs(r) - 0.5)) [
                \ -1 -> n,
                \  0 -> (Even n ? n ; m),
                \  1 -> m
                ] 
    end

Recip :: Real -> Real
Recip x := 1 / x

IsPrime(n: Nat) :=
    begin
        if n < 2 then
            return false
        else
            for i in [2 .. Sqrt(n)] do
                if (n Rem i) = 0 then
                    return false
            return true
    end

... Generic comparison

<> :: (_, _) -> Bool
a <> b := ~(a = b)

<= :: (_, _) -> Bool
a <= b := (a < b) || (a = b)

>= :: (_, _) -> Bool
a >= b := (a > b) || (a = b)

InRange :: (_, _, _) -> Bool
InRange(a, mn, mx) := (a >= mn) && (a <= mx)

... List

Length :: [_] -> Nat
Length xs := PrimLength xs

Map :: (_ -> _) -> [_] -> [_]
Map f xs := [f x | x |< xs]

= :: ([_], [_]) -> Bool
[] = [] := true
_  = [] := false
[] = _  := false
(x >| xs) = (y >| ys) := (x = y) && (xs = ys)

> :: ([_], [_]) -> Bool
[] > [] := false
_ > [] := true
[] > _ := false
(x >| xs) > (y >| ys) := x = y ? xs > ys ; x > y

< :: ([_], [_]) -> Bool
[] < [] := false
_ < [] := false
[] < _ := true
(x >| xs) < (y >| ys) := x = y ? xs < ys ; x < y

Elm :: (_, [_]) -> Bool
a Elm [] := false
a Elm (x >| xs) := a = x ? true ; a Elm xs

Null :: [_] -> Bool
Null [] := true
Null _  := false

Reverse :: [_] -> [_]
Reverse [] := []
Reverse (x >| xs) := (Reverse xs) ++ [x]

Head :: [_] -> _
Head (x >| _) := x

Last :: [_] -> _
Last [x] := x
Last (_ >| xs) := Last xs

Tail :: [_] -> _
Tail(_ >| xs) := xs

Init :: [_] -> _
Init [_] := []
Init (x >| xs) := x >| Init xs

Filter :: (_ -> Bool) -> [_] -> [_]
Filter p xs := [x | x |< xs, p x]

Replicate :: Nat -> _ -> [_]
Replicate 0 _ := []
Replicate n x := x >| Replicate (n - 1) x

Take :: Nat -> [_] -> [_]
Take 0 xs := []
Take _ [] := []
Take n (x >| xs) := x >| Take (n - 1) xs

Drop :: Nat -> [_] -> [_]
Drop 0 xs := xs
Drop _ [] := []
Drop n (_ >| xs) := Drop (n - 1) xs

Split :: Nat -> [_] -> ([_], [_])
Split 0 xs := ([], xs)
Split _ [] := ([], [])
Split n (x >| xs) := (x >| ys, zs) where (ys, zs) <- Split (n - 1) xs

TakeWhile :: (_ -> Bool) -> [_] -> [_]
TakeWhile p [] := []
TakeWhile p (x >| xs) :=
    Case (p x) [
        \true  -> (x >| TakeWhile p xs),
        \false -> []
        ]

DropWhile :: (_ -> Bool) -> [_] -> [_]
DropWhile p [] := []
DropWhile p (x >| xs) :=
    Case (p x) [
        \true  -> DropWhile p xs,
        \false -> x >| xs
        ]

Zip :: ([_], [_]) -> [(_, _)]
Zip ([], []) := []
Zip ((x >| xs), (y >| ys)) := (x, y) >| Zip xs ys

UnZip :: [(_, _)] -> ([_], [_])
UnZip [] := ([], [])
UnZip ((x, y) >| xys) := (x >| xs, y >| ys) where (xs, ys) <- UnZip xys

Sort :: [_] -> [_]
Sort [] := []
Sort (p >| xs) := Sort[x | x |< xs, x < p] ++ [p] ++ Sort[x | x |< xs, x >= p]

Find :: _ -> [_] -> Nat
Find _ [] := 0
Find a (x >| xs) := a = x ? 0 ; 1 + Find a xs

IsInit :: [_] -> [_] -> Bool
IsInit [] _ := true
IsInit _ [] := false
IsInit (x >| xs) (y >| ys) := (x = y) ? IsInit xs ys ; false

Pos :: [_] -> [_] -> Nat
Pos [] [] := 0
Pos xs [] := 0
Pos xs (y >| ys) := IsInit xs (y >| ys) ? 0 ; 1 + Pos xs ys

Copy :: [_] -> Nat -> Nat -> [_]
Copy [] n l := []
Copy xs 0 l := Take l xs
Copy (x >| xs) n l := Copy xs (n - 1) l

Delete :: [_] -> Nat -> Nat -> [_]
Delete [] n l := []
Delete xs 0 l := Drop l xs
Delete (x >| xs) n l := Delete xs (n - 1) l

Insert :: [_] -> [_] -> Nat -> [_]
Insert xs ys 0 := xs ++ ys
Insert xs [] n := []
Insert xs (y >| ys) n := y >| Insert xs ys (n - 1)

ReplaceInit :: [_] -> [_] -> [_]
ReplaceInit xs [] := xs
ReplaceInit [] ys := ys
ReplaceInit (x >| xs) (y >| ys) := y >| ReplaceInit xs ys

Replace :: [_] -> [_] -> [_] -> [_]
Replace [] as bs := []
Replace (x >| xs) as bs := IsInit as (x >| xs) ? ReplaceInit (x >| xs) bs ; Replace xs as bs

Sum :: [_] -> _
Sum [] := 0
Sum (x >| xs) := x + Sum xs

Prod :: [_] -> _
Prod [] := 1
Prod (x >| xs) := x * Prod xs

Minimum :: [_] -> _
Minimum [x] := x
Minimum (x >| xs) := Min(x, Minimum xs)

Maximum :: [_] -> _
Maximum [x] := x
Maximum (x >| xs) := Max(x, Maximum xs)

... Character and Strings

EncodeChar :: Nat -> Char
EncodeChar n := PrimEncodeChar n

DecodeChar :: Char -> Nat
DecodeChar c := PrimDecodeChar c

UpperCase :: Char -> Char
UpperCase c := (c >= 'a' && c <= 'z') ? EncodeChar(DecodeChar(c) - 32) ; c

LowerCase :: Char -> Char
LowerCase c := (c >= 'A' && c <= 'Z') ? EncodeChar(DecodeChar(c) + 32) ; c

IsDigit :: Char -> Bool
IsDigit c := c >= '0' && c <= '9'

IsSmallLetter :: Char -> Bool
IsSmallLetter c := c >= 'a' && c <= 'z'

IsCapitalLetter :: Char -> Bool
IsCapitalLetter c := c >= 'A' && c <= 'Z'

IsLetter :: Char -> Bool
IsLetter c := IsSmallLetter c || IsCapitalLetter c

IsSpace :: Char -> Bool
IsSpace c := c = ' ' || c = '\9' || c = '\0'

IsEoL c := c = '\r' || c = '\n'

IsPunct :: Char -> Bool
IsPunct c := (c > ' ' && c < '0') || (c > '9' && c < 'A') || (c > 'Z' && c < 'a') || (c > 'z' && c < '\127')

IsAsciiCtrl :: Char -> Bool
IsAsciiCtrl c := c >= '\0' && c <= '\31'

ListFromTo :: Char -> Char -> [Char]
ListFromTo a b := Map EncodeChar [DecodeChar a .. DecodeChar b]

= :: (Char, Char) -> Bool
a = b := DecodeChar(a) = DecodeChar(b)

> :: (Char, Char) -> Bool
a > b := DecodeChar(a) > DecodeChar(b)

< :: (Char, Char) -> Bool
a < b := DecodeChar(a) < DecodeChar(b)

Prev :: Char -> Char
Prev c := EncodeChar(Prev(DecodeChar(c)))

Next :: Char -> Char
Next c := EncodeChar(Next(DecodeChar(c)))

Ascii :: String
Ascii := ['\0' .. '\255']

UpperCase :: String -> String
UpperCase "" := ""
UpperCase(c >| cs) := (UpperCase c) >| (UpperCase cs)

LowerCase :: String -> String
LowerCase "" := ""
LowerCase(c >| cs) := (LowerCase c) >| (LowerCase cs)

CR := '\10'
LF := '\13'

... Random

Random :: Int -> Int
Random n := PrimRandom n

RandomRange :: (Int, Int) -> Int
RandomRange (a, b) := a + Random(b - a)

... Date

GetDateTime :: () -> (Nat, Nat, Nat, Nat, Nat, Nat, Nat, Nat)
GetDateTime() := PrimGetDateTime()

Date :: () -> (Nat, Nat, Nat)
Date() := (y, m, d)
          where (y, m, _, d, _, _, _, _) <- GetDateTime()

Time :: () -> (Nat, Nat, Nat)
Time() := (h, m, s, ss)
          where (_, _, _, _, h, m, s, ss) <- GetDateTime()

Year :: () -> Nat
Year() := y where (y, _, _) <- Date()

Month :: () -> Nat
Month() := m where (_, m, _) <- Date()

DayOfWeek :: () -> Nat
DayOfWeek() := dow where (_, _, dow, _, _, _, _, _) <- GetDateTime()

Day :: () -> Nat
Day() := d where (_, _, d) <- Date()

Hour :: () -> Nat
Hour() := h where (h, _, _, _) <- Time()

Minute :: () -> Nat
Minute() := m where (_, m, _, _) <- Time()

Second :: () -> Nat
Second() := s where (_, _, s, _) <- Time()

Milliseconds :: () -> Nat
Milliseconds() := ss where (_, _, _, ss) <- Time()

SetDateTime :: (Nat, Nat, Nat, Nat, Nat, Nat, Nat, Nat) -> ()
SetDateTime dt := PrimSetDateTime dt

SetDate :: (Nat, Nat, Nat) -> ()
SetDate (y, m, d) := SetDateTime(y, m, 0, d, 0, 0, 0, 0)

SetTime :: (Nat, Nat, Nat, Nat) -> ()
SetTime (h, m, s, ss) := SetDateTime(_y, _m, _dow, _d, h, m, s, ss)
    where (_y, _m, _dow, _d) <- Date()

... Tuple

Arity :: _ -> Nat
Arity t := PrimArity t

Trivial :: () -> Bool
Trivial () := true
Trivial _ := false

IsPair :: Pair -> Bool
IsPair (a, b) := true
IsPair _ := false

PairX :: Pair -> _
PairX (a, _) := a

PairY :: Pair -> _
PairY (_, b) := b

= :: (Pair, Pair) -> Bool
(a, b) = (c, d) := (a = c) && (b = d)

FindInTuple :: _ -> _ -> Nat
FindInTuple x t :=
    begin
        l <- Arity t
        i <- 0
        while i < l do
            if t{i} = x then
                return i
            i <- Next i
        return i
    end

IsInTuple :: _ -> _ -> Bool
IsInTuple x t := (FindInTuple x t) < Arity t

... Function

@ :: (Function, Function) -> Function
(f@g)(x) := f(g(x))

Ident :: _ -> _
Ident x := x

Const :: _ -> _ -> _
Const k _ := k

Curry :: ((_, _) -> _) -> (_ -> _ -> _)
Curry f x y := f(x, y)

UnCurry :: (_ -> _ -> _) -> ((_, _) -> _)
UnCurry f (x, y) := f x y

Until :: (_ -> Bool) -> (_ -> _) -> _ -> _
Until p f x := p x ? x ; Until p f (f x)

+ :: (Function, Function) -> Function
f + g := \x -> f(x) + g(x)

- :: (Function, Function) -> Function
f - g := \x -> f(x) - g(x)

* :: (Function, Function) -> Function
f * g := \x -> f(x) * g(x)

/ :: (Function, Function) -> Function
f / g := \x -> f(x) / g(x)

^ :: (Function, Function) -> Function
f ^ g := \x -> f(x) ^ g(x)

>>= :: (_, Function) -> _
p >>= f := f p

=<< :: (Function, _) -> _
f =<< p := p >>= f

Failer f g := f g ; g f

... Standard lambda terms



LambdaI  := \x -> x
LambdaK  := \x y -> x
LambdaS  := \x y z -> (x z (y z))

... Miscelaneous

    