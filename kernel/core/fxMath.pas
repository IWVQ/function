unit fxMath;

interface

uses
    SysUtils, Math, Types, fxUtils;

const
    NAN = NaN;
    INF = Infinity;
    NEGINF = NegInfinity;
    
    FX_MININTEGER       = -9223372036854775808;
    FX_MAXINTEGER       = 9223372036854775807;
    FX_MINNATURAL       = 0;
    FX_MAXNATURAL       = 9223372036854775807;
    
function nNeg(A: TFxNumber): TFxNumber;
function nAdd(A, B: TFxNumber): TFxNumber;
function nSub(A, B: TFxNumber): TFxNumber;
function nMul(A, B: TFxNumber): TFxNumber;
function nDiv(A, B: TFxNumber): TFxNumber;
function nPow(A, B: TFxNumber): TFxNumber;
function nEqual(A, B: TFxNumber): TFxBool;
function nUnEqual(A, B: TFxNumber): TFxBool;
function nLess(A, B: TFxNumber): TFxBool;
function nLessOrEqual(A, B: TFxNumber): TFxBool;
function nGreater(A, B: TFxNumber): TFxBool;
function nGreaterOrEqual(A, B: TFxNumber): TFxBool;
function nTrunc(A: TFxNumber): TFxNumber;
function nFrac(A: TFxNumber): TFxNumber;
function nSin(A: TFxNumber): TFxNumber;
function nCos(A: TFxNumber): TFxNumber;
function nTan(A: TFxNumber): TFxNumber;
function nASin(A: TFxNumber): TFxNumber;
function nACos(A: TFxNumber): TFxNumber;
function nATan(A: TFxNumber): TFxNumber;
function nLn(A: TFxNumber): TFxNumber;
function nExp(A: TFxNumber): TFxNumber;
function nRem(A, B: TFxInteger): TFxNumber;
function nQuot(A, B: TFxInteger): TFxNumber;
function iNot(A: TFxInteger): TFxInteger;
function iAnd(A, B: TFxInteger): TFxInteger;
function iOr(A, B: TFxInteger): TFxInteger;
function iShl(A, B: TFxInteger): TFxInteger;
function iShr(A, B: TFxInteger): TFxInteger;
function iRandom(A: TFxInteger): TFxInteger;
function cEncode(A: TFxInteger): TFxChar;
function cDecode(C: TFxChar): TFxInteger;

function nITrunc(A: TFxNumber): TFxInteger;
function nIRem(A, B: TFxInteger): TFxInteger;
function nIQuot(A, B: TFxInteger): TFxInteger;

function nIsNaN(A: TFxNumber): TFxBool;
function nIsInfinite(A: TFxNumber): TFxBool;
function nIsPosInfinity(A: TFxNumber): TFxBool;
function nIsNegInfinity(A: TFxNumber): TFxBool;
function nSign(A: TFxNumber): TValueSign;

function nIsZero(A: TFxNumber): TFxBool;
function nIsByte(A: TFxNumber): TFxBool;
function nIsInt(A: TFxNumber): TFxBool;
function nIsNat(A: TFxNumber): TFxBool;
function nInRange(A, Mn, Mx: TFxNumber): TFxBool;

procedure iRandomize;

implementation

const
    NN = 312;
    MM = 156;
    UM = UInt64($FFFFFFFF80000000);
    LM = UInt64($7FFFFFFF);

type
    TExtended = packed record
        Mantissa: UInt64;
        Exponent: Word;
    end;
    PExtended = ^TExtended;
    
var
    RandomStateVector: array[0 .. NN - 1] of UInt64;
    RandomStateIndex: Word;
    M: TFPUExceptionMask;

procedure InitializeRandom64(Seed: UInt64);
begin
    RandomStateVector[0] := Seed;
    RandomStateIndex := 1;
    while RandomStateIndex < NN do begin
        RandomStateVector[RandomStateIndex] := UInt64(UInt64(6364136223846793005)*
            (RandomStateVector[RandomStateIndex - 1] xor (RandomStateVector[RandomStateIndex - 1] shr 62)) + 
            RandomStateIndex);
        Inc(RandomStateIndex);
    end;
end;

function GenerateRandom64: UInt64;
const
    MAG: array[0..1] of UInt64 = (0, UInt64($B5026F5AA96619E9));
var
    I: Integer;
    X: UInt64;
begin
    if RandomStateIndex >= NN then begin
        I := 0;
        while I < NN - MM do begin
            X := (RandomStateVector[I] and UM) or (RandomStateVector[I + 1] and LM);
            RandomStateVector[I] := RandomStateVector[I + MM] xor (X shr 1) xor MAG[X and 1];
            Inc(I);
        end;
        while I < NN - 1 do begin
            X := (RandomStateVector[I] and UM) or (RandomStateVector[I + 1] and LM);
            RandomStateVector[I] := RandomStateVector[I + MM - NN] xor (X shr 1) xor MAG[X and 1];
            Inc(I);
        end;
        X := (RandomStateVector[NN - 1] and UM) or (RandomStateVector[0] and LM);
        RandomStateVector[NN - 1] := RandomStateVector[MM - 1] xor (X shr 1) xor MAG[X and 1];
        RandomStateIndex := 0;
    end;
    X := RandomStateVector[RandomStateIndex];
    Inc(RandomStateIndex);
    X := X xor ((X shr 29) and $5555555555555555);
    X := X xor ((X shl 17) and $71D67FFFEDA60000);
    X := X xor ((X shl 37) and $FFF7EEE000000000);
    X := X xor ((X shr 43)                      );
    Result := X;
end;

procedure BeginOperation;
begin
    M := SetExceptionMask([exInvalidOp, exDenormalized, exZeroDivide,
        exOverflow, exUnderflow, exPrecision])
end;

procedure EndOperation;
begin
    SetExceptionMask(M);
end;

//---

function nNeg(A: TFxNumber): TFxNumber;
begin
    BeginOperation;
    
    Result := -A;
    
    EndOperation;
end;

function nAdd(A, B: TFxNumber): TFxNumber;    
begin
    BeginOperation;
    
    Result := A + B;
    
    EndOperation;
end;

function nSub(A, B: TFxNumber): TFxNumber;    
begin
    BeginOperation;
    
    Result := A - B;
    
    EndOperation;
end;

function nMul(A, B: TFxNumber): TFxNumber;    
begin
    BeginOperation;
    
    Result := A*B;
    
    EndOperation;
end;

function nDiv(A, B: TFxNumber): TFxNumber;    
begin
    BeginOperation;
    
    Result := A/B;
    
    EndOperation;
end;

function nPow(A, B: TFxNumber): TFxNumber;   
begin
    BeginOperation;
    
    if nIsZero(nFrac(B)) then
        Result := IntPower(A, nITrunc(B))
    else
        Result := Power(A, B);
    
    EndOperation;
end;

function nEqual(A, B: TFxNumber): TFxBool;    
begin
    BeginOperation;
    
    if nIsNaN(A) or nIsNaN(B) then
        Result := False // NaN no se puede comparar(ni para patrones)
    else if nIsInfinite(A) then begin
        if nIsInfinite(B) then
            Result := nSign(A) = nSign(B)
        else
            Result := False;
    end
    else begin
        if nIsInfinite(B) then
            Result := False
        else
            Result := SameValue(A, B, 0);
    end;
    
    EndOperation;
end;

function nUnEqual(A, B: TFxNumber): TFxBool;
begin
    Result := not(nEqual(A, B));
end;

function nLess(A, B: TFxNumber): TFxBool;     
begin
    BeginOperation;
    
    if nIsNaN(A) or nIsNaN(B) then
        Result := False // NaN no se puede comparar
    else if nIsInfinite(A) and nIsInfinite(B) then
        Result := nSign(A) < nSign(B)
    else
        Result := CompareValue(A, B, 0) = LessThanValue;
    
    EndOperation;
end;

function nLessOrEqual(A, B: TFxNumber): TFxBool;
begin
    Result := nLess(A, B) or nEqual(A, B);
end;

function nGreater(A, B: TFxNumber): TFxBool;  
begin
    BeginOperation;
    
    if nIsNaN(A) or nIsNaN(B) then
        Result := False // NaN no se puede comparar
    else if nIsInfinite(A) and nIsInfinite(B) then
        Result := nSign(A) > nSign(B)
    else
        Result := CompareValue(A, B, 0) = GreaterThanValue;
    
    EndOperation;
end;

function nGreaterOrEqual(A, B: TFxNumber): TFxBool;
begin
    Result := nGreater(A, B) or nEqual(A, B);
end;

function nTrunc(A: TFxNumber): TFxNumber;    
begin
    BeginOperation;
    
    if nIsNaN(A) then Result := NAN
    else Result := Int64(Trunc(Int(A)));
    
    EndOperation;
end;

function nFrac(A: TFxNumber): TFxNumber;      
begin
    BeginOperation;
    
    Result := Frac(A); //! falla para numeros grandes
    
    EndOperation;
end;

function nSin(A: TFxNumber): TFxNumber;       
begin
    BeginOperation;
    
    Result := Sin(A);
    
    EndOperation;
end;

function nCos(A: TFxNumber): TFxNumber;       
begin
    BeginOperation;
    
    Result := Cos(A);
    
    EndOperation;
end;

function nTan(A: TFxNumber): TFxNumber;       
begin
    BeginOperation;
    
    Result := Tan(A);
    
    EndOperation;
end;

function nASin(A: TFxNumber): TFxNumber;      
begin
    BeginOperation;
    
    Result := ArcSin(A);
    
    EndOperation;
end;

function nACos(A: TFxNumber): TFxNumber;      
begin
    BeginOperation;
    
    Result := ArcCos(A);
    
    EndOperation;
end;

function nATan(A: TFxNumber): TFxNumber;      
begin
    BeginOperation;
    
    Result := ArcTan(A);
    
    EndOperation;
end;

function nLn(A: TFxNumber): TFxNumber;        
begin
    BeginOperation;
    
    Result := Ln(A);
    
    EndOperation;
end;

function nExp(A: TFxNumber): TFxNumber;       
begin
    BeginOperation;
    
    if nIsNaN(A) then Result := NaN
    else if nIsInfinite(A) then begin
        if nSign(A) = 1 then Result := Infinity
        else if nSign(A) = -1 then Result := 0
        else Result := NaN;
    end
    else
        Result := Exp(A);
    
    EndOperation;
end;

function nRem(A, B: TFxInteger): TFxNumber;  
begin
    BeginOperation;
    if B = 0 then Result := NAN
    else Result := Int64(A mod B);
    EndOperation;
end;

function nQuot(A, B: TFxInteger): TFxNumber; 
begin
    BeginOperation;
    if B = 0 then begin
        if A = 0 then Result := NAN
        else if A > 0 then Result := INF
        else Result := NEGINF;
    end
    else Result := Int64(A div B);
    EndOperation;
end;

function iNot(A: TFxInteger): TFxInteger;     
begin
    Result := Int64(not A);
end;

function iAnd(A, B: TFxInteger): TFxInteger;  
begin
    Result := Int64(A and B);
end;

function iOr(A, B: TFxInteger): TFxInteger;   
begin
    Result := Int64(A or B);
end;

function iShl(A, B: TFxInteger): TFxInteger;  
begin
    Result := Int64(A shl B);
end;

function iShr(A, B: TFxInteger): TFxInteger;  
begin
    Result := Int64(A shr B);
end;

function iRandom(A: TFxInteger): TFxInteger;
begin
    if A = 0 then Result := 0
    else begin
        Result := GenerateRandom64;
        if Result < 0 then Result := -Result;
        if A < 0 then
            Result := -nIRem(Result, -A)
        else
            Result := nIRem(Result, A);
    end;
end;

function cEncode(A: TFxInteger): TFxChar;
begin
    Result := Chr(A);
end;

function cDecode(C: TFxChar): TFxInteger;
begin
    Result := Int64(Ord(C));
end;

function nITrunc(A: TFxNumber): TFxInteger;
begin
    BeginOperation;
    
    Result := Int64(Trunc(Int(A)));
    
    EndOperation;
end;

function nIRem(A, B: TFxInteger): TFxInteger;
begin
    BeginOperation;
    Result := Int64(A mod B);
    EndOperation;
end;

function nIQuot(A, B: TFxInteger): TFxInteger;
begin
    BeginOperation;
    Result := Int64(A div B);
    EndOperation;
end;

function nIsNaN(A: TFxNumber): TFxBool;
begin
    Result := IsNaN(A);
end;

function nIsInfinite(A: TFxNumber): TFxBool;
begin
    Result := ((PExtended(@A)^.Exponent and $7FFF) = $7FFF) and
              (PExtended(@A)^.Mantissa = $8000000000000000);
end;

function nIsPosInfinity(A: TFxNumber): TFxBool;
begin
    Result := (PExtended(@A)^.Exponent = $7FFF) and
              (PExtended(@A)^.Mantissa = $8000000000000000);
end;

function nIsNegInfinity(A: TFxNumber): TFxBool;
begin
    Result := (PExtended(@A)^.Exponent = $FFFF) and
              (PExtended(@A)^.Mantissa = $8000000000000000);
end;

function nSign(A: TFxNumber): TValueSign;
begin
    if  ((PExtended(@A)^.Exponent and $7FFF) = $0000) and
        ((PExtended(@A)^.Mantissa = $0000000000000000)) then
        Result := 0
    else if
        ((PExtended(@A)^.Exponent and $8000) = $8000) and
        ((PExtended(@A)^.Mantissa and $0000000000000000) = $0000000000000000) then
        Result := -1
    else
        Result := 1;
end;

function nIsZero(A: TFxNumber): TFxBool;
begin
    Result := nEqual(A, 0);
end;

function nIsByte(A: TFxNumber): TFxBool;
begin
    Result := nGreaterOrEqual(A, 0) and nLessOrEqual(A, 255) and nIsZero(nFrac(A));
end;

function nIsInt(A: TFxNumber): TFxBool;
begin
    Result := nGreaterOrEqual(A, FX_MININTEGER) and nLessOrEqual(A, FX_MAXINTEGER) and nIsZero(nFrac(A));
end;

function nIsNat(A: TFxNumber): TFxBool;
begin
    Result := nGreaterOrEqual(A, FX_MINNATURAL) and nLessOrEqual(A, FX_MAXNATURAL) and nIsZero(nFrac(A));
end;

function nInRange(A, Mn, Mx: TFxNumber): TFxBool;
begin
    Result := nGreaterOrEqual(A, Mn) and nLessOrEqual(A, Mx);
end;

procedure iRandomize;
begin
    System.Randomize;
    InitializeRandom64(UInt64(System.RandSeed));
end;

initialization
    iRandomize;

end.
