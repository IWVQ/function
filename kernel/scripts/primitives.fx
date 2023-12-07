...primitives.fx
...     This is an informative script only, please don't run it

... Basic types

bool ::= ...
char ::= ...
nat  ::= ...
int  ::= ...
real ::= ...

... Primitive functions

PrimAdd              :: (real, real) -> real 
PrimSub              :: (real, real) -> real 
PrimMul              :: (real, real) -> real 
PrimDiv              :: (real, real) -> real 
PrimPow              :: (real, real) -> real 

PrimEqual            :: (real, real) -> bool 
PrimLess             :: (real, real) -> bool 
PrimGreater          :: (real, real) -> bool 
PrimIsNaN            :: real -> bool

PrimTrunc            :: real -> int  
PrimFrac             :: real -> real

PrimSin              :: real -> real 
PrimCos              :: real -> real 
PrimTan              :: real -> real 
PrimASin             :: real -> real 
PrimACos             :: real -> real 
PrimATan             :: real -> real 

PrimLn               :: real -> real 
PrimExp              :: real -> real 

PrimRem              :: (int, int) -> int
PrimQuot             :: (int, int) -> int

PrimBitNot           :: int -> int
PrimBitAnd           :: (int, int) -> int
PrimBitOr            :: (int, int) -> int
PrimBitShl           :: (int, int) -> int
PrimBitShr           :: (int, int) -> int

PrimRandom           :: int -> int

PrimEncodeChar       :: nat -> char
PrimDecodeChar       :: char -> nat

PrimLength           :: [_] -> nat
PrimGet              :: ([_], nat) -> _
PrimSet              :: (_, [_], nat) -> _

PrimArity            :: _ -> nat
PrimSelect           :: (_, nat) -> _
PrimPut              :: (_, _, nat) -> _

PrimInput            :: () -> [char] 
PrimOutput           :: [char] -> () 
PrimClearScreen      :: () -> () 

PrimGetDateTime      :: () -> (nat, nat, nat, nat, nat, nat, nat, nat)
PrimSetDateTime      :: (nat, nat, nat, nat, nat, nat, nat, nat) -> ()

PrimAnswer           :: () -> _ 
PrimError            :: [char] -> _ 

PrimTryStrToNum      :: [char] -> (real, bool) 
PrimValueToStr       :: _ -> [char] 
PrimTypeToStr        :: _ -> [char] 
PrimValueToStrFull   :: _ -> [char] 

PrimIsAnonymous      :: _ -> bool
PrimIsFreeIdentifier :: _ -> bool
PrimIsTuple          :: _ -> bool
PrimIsLambda         :: _ -> bool
PrimLanguage         :: () -> nat

PrimQuit             :: () -> ()
PrimInterrupt        :: () -> ()
PrimRestart          :: () -> ()

...... Required definitions

...IfThenElse :: (bool, _, _) -> _
...GetElm :: [nat] -> [_] -> _
...GetElm :: [nat] -> _ -> _
...IfFalse :: bool -> _ -> _
...ListFromTo :: real -> real -> [real]
...ListFromThenTo :: real -> real -> real -> [real]
...FlatMap :: (_ -> [_]) -> [_] -> [_]
...NotEmpty :: [_] -> bool
... WhileSkeleton :: _ -> _
...a + b :: (real, real) -> real
... a - b :: (real, real) -> real
   
   