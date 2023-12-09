unit fxPrimFunctions;

interface

uses
    fxMath, fxUtils, fxStorage, fxError, fxStrUtils, fxBasicStructure, fxPrimFuncUtils,
    fxInterpreterUtils, fxStrConverter, fxTypeInferencer;

type
    
    TPrimitiveFunction = function(AArgument: TValueExpr; var AReturn: TValueExpr): Word of object;
    
    TPrimitiveFunctionArray = array of TPrimitiveFunction;
    
    TPrimitiveFunctionList = class
    private
        FrontEnd: IFrontEndListener;
        Interpreter: IInterpreterListener;
        Storage: TStorage;
        Error: TErrorRegister;
        
        FList: TPrimitiveFunctionArray;
        FStrConverter: TStrConverter;
        FTypeInferencer: TTypeInferencer;
        
        //
        
        function __Primitive_NONE             (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // _ -> _
        function __Primitive_ADD              (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // (Real, Real) -> Real
        function __Primitive_SUB              (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // (Real, Real) -> Real
        function __Primitive_MUL              (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // (Real, Real) -> Real
        function __Primitive_DIV              (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // (Real, Real) -> Real
        function __Primitive_POW              (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // (Real, Real) -> Real
        function __Primitive_EQUAL            (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // (Real, Real) -> Bool
        function __Primitive_LESS             (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // (Real, Real) -> Bool
        function __Primitive_GREATER          (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // (Real, Real) -> Bool
        function __Primitive_ISNAN            (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // Real -> Bool
        function __Primitive_TRUNC            (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // Real -> Int
        function __Primitive_FRAC             (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // Real -> Real
        function __Primitive_SIN              (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // Real -> Real
        function __Primitive_COS              (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // Real -> Real
        function __Primitive_TAN              (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // Real -> Real
        function __Primitive_ASIN             (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // Real -> Real
        function __Primitive_ACOS             (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // Real -> Real
        function __Primitive_ATAN             (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // Real -> Real
        function __Primitive_LN               (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // Real -> Real
        function __Primitive_EXP              (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // Real -> Real
        function __Primitive_REM              (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // (Int, Int) -> Int
        function __Primitive_QUOT             (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // (Int, Int) -> Int
        function __Primitive_BITNOT           (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // Int -> Int
        function __Primitive_BITAND           (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // (Int, Int) -> Int
        function __Primitive_BITOR            (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // (Int, Int) -> Int
        function __Primitive_BITSHL           (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // (Int, Int) -> Int
        function __Primitive_BITSHR           (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // (Int, Int) -> Int
        function __Primitive_RANDOM           (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // Int -> Int
        function __Primitive_ENCODECHAR       (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // Nat -> Char
        function __Primitive_DECODECHAR       (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // Char -> Nat
        function __Primitive_LENGTH           (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // [_] -> Nat
        function __Primitive_GET              (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // ([_], Nat) -> _
        function __Primitive_SET              (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // (_, [_], Nat) -> [_]
        function __Primitive_ARITY            (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // _ -> Nat
        function __Primitive_SELECT           (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // (_, Nat) -> _
        function __Primitive_PUT              (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // (_, _, Nat) -> _
        function __Primitive_INPUT            (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // () -> [Char]
        function __Primitive_OUTPUT           (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // [Char] -> ()
        function __Primitive_CLEARSCREEN      (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // () -> ()
        function __Primitive_GETDATETIME      (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // () -> (Nat, Nat, Nat, Nat, Nat, Nat, Nat, Nat)
        function __Primitive_SETDATETIME      (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // () -> (Nat, Nat, Nat, Nat, Nat, Nat, Nat, Nat)
        function __Primitive_ANSWER           (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // () -> _
        function __Primitive_ERROR            (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // [Char] -> _
        function __Primitive_TRYSTRTONUM      (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // [Char] -> (Real, Bool)
        function __Primitive_VALUETOSTR       (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // _ -> [Char]
        function __Primitive_TYPETOSTR        (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // _ -> [Char]
        function __Primitive_VALUETOSTRFULL   (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // _ -> [Char]
        function __Primitive_ISANONYMOUS      (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // _ -> Bool
        function __Primitive_ISFREEIDENTIFIER (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // _ -> Bool
        function __Primitive_ISTUPLE          (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // _ -> Bool
        function __Primitive_ISLAMBDA         (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // _ -> Bool
        function __Primitive_LANGUAGE         (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // () -> Nat
        function __Primitive_QUIT             (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // () -> ()
        function __Primitive_INTERRUPT        (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // () -> ()
        function __Primitive_RESTART          (AArgument: TValueExpr; var AReturn: TValueExpr): Word; // () -> ()
        
        function CheckValidStr(ABranch: TValueExpr; var S: TFxString): Boolean;
        function PrimitiveError(AIdCode: Integer; AMsg: TFxString; const AArgs: array of const): Word;
        //
        
        function GetFunction(Index: Integer): TPrimitiveFunction;
    protected
        STOP: BOOLEAN;  
        SLEEP: BOOLEAN;
    public
        constructor Create(AFrontEnd: IFrontEndListener; AInterpreter: IInterpreterListener;
            AStorage: TStorage; AError: TErrorRegister);
        destructor Destroy; override;
        procedure Init;
        
        function Count: Integer;
        property __Item[Index: Integer]: TPrimitiveFunction read GetFunction; default;
        procedure Interrupt;
        procedure Pause;
        procedure Resume;
    end;
    
implementation

{ TPrimitiveFunctionList }

constructor TPrimitiveFunctionList.Create(AFrontEnd: IFrontEndListener; AInterpreter: IInterpreterListener;
    AStorage: TStorage; AError: TErrorRegister);
begin
    inherited Create;
    FrontEnd := AFrontEnd;
    Interpreter := AInterpreter;
    Storage := AStorage;
    Error := AError;
    
    Init;
    FStrConverter := TStrConverter.Create(FrontEnd, Interpreter, Storage, Error);
    FTypeInferencer := TTypeInferencer.Create(FrontEnd, Interpreter, Storage, Error);
    
    STOP := FALSE;
end;

destructor TPrimitiveFunctionList.Destroy;
begin
    FList := nil;
    FStrConverter.Free;
    FTypeInferencer.Free;
    inherited;
end;

procedure TPrimitiveFunctionList.Init;
begin
    SetLength(FList, Count);
    
    FList[FX_PRIM_NONE             ] := @__Primitive_NONE             ;
    FList[FX_PRIM_ADD              ] := @__Primitive_ADD              ;
    FList[FX_PRIM_SUB              ] := @__Primitive_SUB              ;
    FList[FX_PRIM_MUL              ] := @__Primitive_MUL              ;
    FList[FX_PRIM_DIV              ] := @__Primitive_DIV              ;
    FList[FX_PRIM_POW              ] := @__Primitive_POW              ;
    FList[FX_PRIM_EQUAL            ] := @__Primitive_EQUAL            ;
    FList[FX_PRIM_LESS             ] := @__Primitive_LESS             ;
    FList[FX_PRIM_GREATER          ] := @__Primitive_GREATER          ;
    FList[FX_PRIM_ISNAN            ] := @__Primitive_ISNAN            ;
    FList[FX_PRIM_TRUNC            ] := @__Primitive_TRUNC            ;
    FList[FX_PRIM_FRAC             ] := @__Primitive_FRAC             ;
    FList[FX_PRIM_SIN              ] := @__Primitive_SIN              ;
    FList[FX_PRIM_COS              ] := @__Primitive_COS              ;
    FList[FX_PRIM_TAN              ] := @__Primitive_TAN              ;
    FList[FX_PRIM_ASIN             ] := @__Primitive_ASIN             ;
    FList[FX_PRIM_ACOS             ] := @__Primitive_ACOS             ;
    FList[FX_PRIM_ATAN             ] := @__Primitive_ATAN             ;
    FList[FX_PRIM_LN               ] := @__Primitive_LN               ;
    FList[FX_PRIM_EXP              ] := @__Primitive_EXP              ;
    FList[FX_PRIM_REM              ] := @__Primitive_REM              ;
    FList[FX_PRIM_QUOT             ] := @__Primitive_QUOT             ;
    FList[FX_PRIM_BITNOT           ] := @__Primitive_BITNOT           ;
    FList[FX_PRIM_BITAND           ] := @__Primitive_BITAND           ;
    FList[FX_PRIM_BITOR            ] := @__Primitive_BITOR            ;
    FList[FX_PRIM_BITSHL           ] := @__Primitive_BITSHL           ;
    FList[FX_PRIM_BITSHR           ] := @__Primitive_BITSHR           ;
    FList[FX_PRIM_RANDOM           ] := @__Primitive_RANDOM           ;
    FList[FX_PRIM_ENCODECHAR       ] := @__Primitive_ENCODECHAR       ;
    FList[FX_PRIM_DECODECHAR       ] := @__Primitive_DECODECHAR       ;
    FList[FX_PRIM_LENGTH           ] := @__Primitive_LENGTH           ;
    FList[FX_PRIM_GET              ] := @__Primitive_GET              ;
    FList[FX_PRIM_SET              ] := @__Primitive_SET              ;
    FList[FX_PRIM_ARITY            ] := @__Primitive_ARITY            ;
    FList[FX_PRIM_SELECT           ] := @__Primitive_SELECT           ;
    FList[FX_PRIM_PUT              ] := @__Primitive_PUT              ;
    FList[FX_PRIM_INPUT            ] := @__Primitive_INPUT            ;
    FList[FX_PRIM_OUTPUT           ] := @__Primitive_OUTPUT           ;
    FList[FX_PRIM_CLEARSCREEN      ] := @__Primitive_CLEARSCREEN      ;
    FList[FX_PRIM_GETDATETIME      ] := @__Primitive_GETDATETIME      ;
    FList[FX_PRIM_SETDATETIME      ] := @__Primitive_SETDATETIME      ;
    FList[FX_PRIM_ANSWER           ] := @__Primitive_ANSWER           ;
    FList[FX_PRIM_ERROR            ] := @__Primitive_ERROR            ;
    FList[FX_PRIM_TRYSTRTONUM      ] := @__Primitive_TRYSTRTONUM      ;
    FList[FX_PRIM_VALUETOSTR       ] := @__Primitive_VALUETOSTR       ;
    FList[FX_PRIM_TYPETOSTR        ] := @__Primitive_TYPETOSTR        ;
    FList[FX_PRIM_VALUETOSTRFULL   ] := @__Primitive_VALUETOSTRFULL   ;
    FList[FX_PRIM_ISANONYMOUS      ] := @__Primitive_ISANONYMOUS      ;
    FList[FX_PRIM_ISFREEIDENTIFIER ] := @__Primitive_ISFREEIDENTIFIER ;
    FList[FX_PRIM_ISTUPLE          ] := @__Primitive_ISTUPLE          ;
    FList[FX_PRIM_ISLAMBDA         ] := @__Primitive_ISLAMBDA         ;
    FList[FX_PRIM_LANGUAGE         ] := @__Primitive_LANGUAGE        ;
    FList[FX_PRIM_QUIT             ] := @__Primitive_QUIT             ;
    FList[FX_PRIM_INTERRUPT        ] := @__Primitive_INTERRUPT        ;
    FList[FX_PRIM_RESTART          ] := @__Primitive_RESTART          ;
    
end;

function TPrimitiveFunctionList.Count: Integer;
begin
    Result := FX_PRIMITIVE_COUNT;
end;

function TPrimitiveFunctionList.GetFunction(Index: Integer): TPrimitiveFunction;
begin
    if (Index >= 0) and (Index < Count) then
        Result := FList[Index]
    else
        Result := nil;
end;

//--

function TPrimitiveFunctionList.__Primitive_NONE           (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

begin // _ -> _
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    MakeHeadValueBranch(FX_VN_NONE, AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_ADD            (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A, B: TFxNumber;

begin // (Real, Real) -> Real
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if (AArgument^.vKind = FX_VN_TUPLE) and (Length(AArgument^.Childs) = 2) then begin
        if ValueIsRealNumber(AArgument^.Childs[0], A) then begin
            if ValueIsRealNumber(AArgument^.Childs[1], B) then
                MakeNumberValueBranch(fxMath.nAdd(A, B), AReturn)
            else
                MakeFailValueBranch(AReturn);
        end
        else
            MakeFailValueBranch(AReturn);
    end
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_SUB            (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A, B: TFxNumber;
    
begin // (Real, Real) -> Real
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if (AArgument^.vKind = FX_VN_TUPLE) and (Length(AArgument^.Childs) = 2) then begin
        if ValueIsRealNumber(AArgument^.Childs[0], A) then begin
            if ValueIsRealNumber(AArgument^.Childs[1], B) then
                MakeNumberValueBranch(fxMath.nSub(A, B), AReturn)
            else
                MakeFailValueBranch(AReturn);
        end
        else
            MakeFailValueBranch(AReturn);
    end
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_MUL            (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A, B: TFxNumber;

begin // (Real, Real) -> Real
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if (AArgument^.vKind = FX_VN_TUPLE) and (Length(AArgument^.Childs) = 2) then begin
        if ValueIsRealNumber(AArgument^.Childs[0], A) then begin
            if ValueIsRealNumber(AArgument^.Childs[1], B) then
                MakeNumberValueBranch(fxMath.nMul(A, B), AReturn)
            else
                MakeFailValueBranch(AReturn);
        end
        else
            MakeFailValueBranch(AReturn);
    end
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_DIV            (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A, B: TFxNumber;

begin // (Real, Real) -> Real
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if (AArgument^.vKind = FX_VN_TUPLE) and (Length(AArgument^.Childs) = 2) then begin
        if ValueIsRealNumber(AArgument^.Childs[0], A) then begin
            if ValueIsRealNumber(AArgument^.Childs[1], B) then
                MakeNumberValueBranch(fxMath.nDiv(A, B), AReturn)
            else
                MakeFailValueBranch(AReturn);
        end
        else
            MakeFailValueBranch(AReturn);
    end
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_POW            (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A, B: TFxNumber;

begin // (Real, Real) -> Real
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if (AArgument^.vKind = FX_VN_TUPLE) and (Length(AArgument^.Childs) = 2) then begin
        if ValueIsRealNumber(AArgument^.Childs[0], A) then begin
            if ValueIsRealNumber(AArgument^.Childs[1], B) then
                MakeNumberValueBranch(fxMath.nPow(A, B), AReturn)
            else
                MakeFailValueBranch(AReturn);
        end
        else
            MakeFailValueBranch(AReturn);
    end
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_EQUAL          (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A, B: TFxNumber;

begin // (Real, Real) -> Bool
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if (AArgument^.vKind = FX_VN_TUPLE) and (Length(AArgument^.Childs) = 2) then begin
        if ValueIsRealNumber(AArgument^.Childs[0], A) then begin
            if ValueIsRealNumber(AArgument^.Childs[1], B) then
                MakeBoolValueBranch(fxMath.nEqual(A, B), AReturn)
            else
                MakeFailValueBranch(AReturn);
        end
        else
            MakeFailValueBranch(AReturn);
    end
    else
        MakeFailValueBranch(AReturn);

LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_LESS           (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A, B: TFxNumber;

begin // (Real, Real) -> Bool
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if (AArgument^.vKind = FX_VN_TUPLE) and (Length(AArgument^.Childs) = 2) then begin
        if ValueIsRealNumber(AArgument^.Childs[0], A) then begin
            if ValueIsRealNumber(AArgument^.Childs[1], B) then
                MakeBoolValueBranch(fxMath.nLess(A, B), AReturn)
            else
                MakeFailValueBranch(AReturn);
        end
        else
            MakeFailValueBranch(AReturn);
    end
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_GREATER        (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A, B: TFxNumber;

begin // (Real, Real) -> Bool
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if (AArgument^.vKind = FX_VN_TUPLE) and (Length(AArgument^.Childs) = 2) then begin
        if ValueIsRealNumber(AArgument^.Childs[0], A) then begin
            if ValueIsRealNumber(AArgument^.Childs[1], B) then
                MakeBoolValueBranch(fxMath.nGreater(A, B), AReturn)
            else
                MakeFailValueBranch(AReturn);
        end
        else
            MakeFailValueBranch(AReturn);
    end
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_ISNAN            (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A: TFxNumber;

begin // Real -> Bool
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    // siempre encaja
    if ValueIsRealNumber(AArgument, A) then begin
        MakeBoolValueBranch(fxMath.nIsNaN(A), AReturn);
    end
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_TRUNC          (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A: TFxNumber;

begin // Real -> Int
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if  ValueIsRealNumber(AArgument, A) then
        MakeNumberValueBranch(fxMath.nTrunc(A), AReturn)
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_FRAC           (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A: TFxNumber;

begin // Real -> Real
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if  ValueIsRealNumber(AArgument, A) then
        MakeNumberValueBranch(fxMath.nFrac(A), AReturn)
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_SIN            (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A: TFxNumber;

begin // Real -> Real
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if  ValueIsRealNumber(AArgument, A) then
        MakeNumberValueBranch(fxMath.nSin(A), AReturn)
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_COS            (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A: TFxNumber;

begin // Real -> Real
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if  ValueIsRealNumber(AArgument, A) then
        MakeNumberValueBranch(fxMath.nCos(A), AReturn)
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_TAN            (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A: TFxNumber;

begin // Real -> Real
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if  ValueIsRealNumber(AArgument, A) then
        MakeNumberValueBranch(fxMath.nTan(A), AReturn)
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_ASIN           (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A: TFxNumber;

begin // Real -> Real
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if  ValueIsRealNumber(AArgument, A) then
        MakeNumberValueBranch(fxMath.nASin(A), AReturn)
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_ACOS           (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A: TFxNumber;

begin // Real -> Real
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if  ValueIsRealNumber(AArgument, A) then
        MakeNumberValueBranch(fxMath.nACos(A), AReturn)
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_ATAN           (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A: TFxNumber;

begin // Real -> Real
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if  ValueIsRealNumber(AArgument, A) then
        MakeNumberValueBranch(fxMath.nATan(A), AReturn)
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_LN             (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A: TFxNumber;

begin // Real -> Real
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if  ValueIsRealNumber(AArgument, A) then
        MakeNumberValueBranch(fxMath.nLn(A), AReturn)
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_EXP            (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A: TFxNumber;

begin // Real -> Real
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if  ValueIsRealNumber(AArgument, A) then
        MakeNumberValueBranch(fxMath.nExp(A), AReturn)
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_REM            (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A, B: TFxInteger;

begin // (Int, Int) -> Int
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if (AArgument^.vKind = FX_VN_TUPLE) and (Length(AArgument^.Childs) = 2) then begin
        if ValueIsIntegerNumber(AArgument^.Childs[0], A) then begin
            if ValueIsIntegerNumber(AArgument^.Childs[1], B) then
                MakeNumberValueBranch(fxMath.nRem(A, B), AReturn)
            else
                MakeFailValueBranch(AReturn);
        end
        else
            MakeFailValueBranch(AReturn);
    end
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_QUOT           (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A, B: TFxInteger;

begin // (Int, Int) -> Int
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if (AArgument^.vKind = FX_VN_TUPLE) and (Length(AArgument^.Childs) = 2) then begin
        if ValueIsIntegerNumber(AArgument^.Childs[0], A) then begin
            if ValueIsIntegerNumber(AArgument^.Childs[1], B) then
                MakeNumberValueBranch(fxMath.nQuot(A, B), AReturn)
            else
                MakeFailValueBranch(AReturn);
        end
        else
            MakeFailValueBranch(AReturn);
    end
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_BITNOT         (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A: TFxInteger;

begin // Int -> Int
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if  ValueIsIntegerNumber(AArgument, A) then
        MakeNumberValueBranch(fxMath.iNot(A), AReturn)
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_BITAND         (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A, B: TFxInteger;

begin // (Int, Int) -> Int
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if (AArgument^.vKind = FX_VN_TUPLE) and (Length(AArgument^.Childs) = 2) then begin
        if ValueIsIntegerNumber(AArgument^.Childs[0], A) then begin
            if ValueIsIntegerNumber(AArgument^.Childs[1], B) then
                MakeNumberValueBranch(fxMath.iAnd(A, B), AReturn)
            else
                MakeFailValueBranch(AReturn);
        end
        else
            MakeFailValueBranch(AReturn);
    end
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_BITOR          (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A, B: TFxInteger;

begin // (Int, Int) -> Int
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if (AArgument^.vKind = FX_VN_TUPLE) and (Length(AArgument^.Childs) = 2) then begin
        if ValueIsIntegerNumber(AArgument^.Childs[0], A) then begin
            if ValueIsIntegerNumber(AArgument^.Childs[1], B) then
                MakeNumberValueBranch(fxMath.iOr(A, B), AReturn)
            else
                MakeFailValueBranch(AReturn);
        end
        else
            MakeFailValueBranch(AReturn);
    end
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_BITSHL         (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A, B: TFxInteger;

begin // (Int, Int) -> Int
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if (AArgument^.vKind = FX_VN_TUPLE) and (Length(AArgument^.Childs) = 2) then begin
        if ValueIsIntegerNumber(AArgument^.Childs[0], A) then begin
            if ValueIsIntegerNumber(AArgument^.Childs[1], B) then
                MakeNumberValueBranch(fxMath.iShl(A, B), AReturn)
            else
                MakeFailValueBranch(AReturn);
        end
        else
            MakeFailValueBranch(AReturn);
    end
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_BITSHR         (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A, B: TFxInteger;

begin // (Int, Int) -> Int
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if (AArgument^.vKind = FX_VN_TUPLE) and (Length(AArgument^.Childs) = 2) then begin
        if ValueIsIntegerNumber(AArgument^.Childs[0], A) then begin
            if ValueIsIntegerNumber(AArgument^.Childs[1], B) then
                MakeNumberValueBranch(fxMath.iShr(A, B), AReturn)
            else
                MakeFailValueBranch(AReturn);
        end
        else
            MakeFailValueBranch(AReturn);
    end
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_RANDOM         (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A: TFxInteger;

begin // Int -> Int
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;

    if  ValueIsIntegerNumber(AArgument, A) then
        MakeNumberValueBranch(fxMath.iRandom(A), AReturn)
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:

end;

function TPrimitiveFunctionList.__Primitive_ENCODECHAR     (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A: TFxInteger;

begin // Nat -> Char
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if  ValueIsNaturalNumber(AArgument, A) then
        MakeCharValueBranch(fxMath.cEncode(A), AReturn)
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_DECODECHAR     (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A: TFxChar;

begin // Char -> Nat
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if  AArgument^.vKind = FX_VN_CHARACTER then begin
        A := AArgument^.D.cValue;
        MakeNumberValueBranch(fxMath.cDecode(A), AReturn);
    end
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_LENGTH         (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    L: TFxInteger;
    TailBranch: TValueExpr;

begin // [_] -> Nat
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if AArgument^.vKind = FX_VN_LIST_CONS then begin
        TailBranch := AArgument;
        L := 0;
        while TailBranch^.vKind = FX_VN_LIST_CONS do begin
            TailBranch := TailBranch^.Childs[1];
            Inc(L);
        end;
        MakeNumberValueBranch(L, AReturn);
    end
    else if AArgument^.vKind = FX_VN_NULL then
        MakeNumberValueBranch(0, AReturn)
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_GET            (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A: TFxInteger;
    TailBranch, HeadBranch: TValueExpr;

begin // ([_], Nat) -> _
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if (AArgument^.vKind = FX_VN_TUPLE) and (Length(AArgument^.Childs) = 2) then begin
        if AArgument^.Childs[0]^.vKind = FX_VN_LIST_CONS then begin
            if ValueIsNaturalNumber(AArgument^.Childs[1], A) then begin
                if (A >= 0) then begin
                    TailBranch := AArgument^.Childs[0];
                    while (TailBranch <> nil) and (A > 0) do begin
                        if TailBranch^.Childs[1]^.vKind = FX_VN_LIST_CONS then
                            TailBranch := TailBranch^.Childs[1]
                        else
                            Break;
                        Dec(A);
                    end;
                    if A = 0 then
                        CopyValueBranch(TailBranch^.Childs[0], AReturn)
                    else
                        Result := PrimitiveError(FX_PRIM_GET, ListIndexOutOfBoundsStr, []);
                end
                else
                    Result := PrimitiveError(FX_PRIM_GET, ListIndexOutOfBoundsStr, []);
            end
            else
                MakeFailValueBranch(AReturn);
        end     
        else if AArgument^.Childs[0]^.vKind = FX_VN_NULL then
            Result := PrimitiveError(FX_PRIM_GET, ListIndexOutOfBoundsStr, [])
        else
            MakeFailValueBranch(AReturn);
    end
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_SET            (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A: TFxInteger;
    TailBranch, AuxBranch: TValueExpr;

begin // (_, [_], Nat) -> _
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if (AArgument^.vKind = FX_VN_TUPLE) and (Length(AArgument^.Childs) = 3) then begin
        if AArgument^.Childs[1]^.vKind = FX_VN_LIST_CONS then begin
            if ValueIsNaturalNumber(AArgument^.Childs[2], A) then begin
                if (A >= 0) then begin
                    TailBranch := AArgument^.Childs[1];
                    while (TailBranch <> nil) and (A > 0) do begin
                        if TailBranch^.Childs[1]^.vKind = FX_VN_LIST_CONS then
                            TailBranch := TailBranch^.Childs[1]
                        else
                            Break;
                        Dec(A);
                    end;
                    if A = 0 then begin
                        CopyValueBranch(AArgument^.Childs[1], AReturn);
                        AuxBranch := AReturn;
                        AReturn := AArgument^.Childs[1];
                        AArgument^.Childs[1] := AuxBranch;
                        AuxBranch := nil;
                        
                        EraseValueBranch(TailBranch^.Childs[0]);
                        CopyValueBranch(AArgument^.Childs[0], TailBranch^.Childs[0]);
                    end
                    else
                        Result := PrimitiveError(FX_PRIM_SET, ListIndexOutOfBoundsStr, []);
                end
                else
                    Result := PrimitiveError(FX_PRIM_SET, ListIndexOutOfBoundsStr, []);
            end
            else
                MakeFailValueBranch(AReturn);
        end
        else if AArgument^.Childs[1]^.vKind = FX_VN_NULL then
            Result := PrimitiveError(FX_PRIM_SET, ListIndexOutOfBoundsStr, [])
        else
            MakeFailValueBranch(AReturn);
    end
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_ARITY          (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

begin // _ -> Nat
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if AArgument^.vKind = FX_VN_TUPLE then
        MakeNumberValueBranch(Int64(Length(AArgument^.Childs)), AReturn)
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_SELECT         (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A: TFxInteger;

begin // (_, Nat) -> _
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if (AArgument^.vKind = FX_VN_TUPLE) and (Length(AArgument^.Childs) = 2) then begin
        if (AArgument^.Childs[0]^.vKind = FX_VN_TUPLE) then begin
            if  ValueIsNaturalNumber(AArgument^.Childs[1], A) then begin
                if (A >= 0) and (A < Int64(Length(AArgument^.Childs[0]^.Childs))) then
                    CopyValueBranch(AArgument^.Childs[0]^.Childs[A], AReturn)
                else
                    Result := PrimitiveError(FX_PRIM_SELECT, TupleIndexOutOfBoundsStr, []);
            end
            else
                MakeFailValueBranch(AReturn);
        end
        else
            MakeFailValueBranch(AReturn);
    end
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_PUT            (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    A: TFxInteger;

begin // (_, _, Nat) -> _
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if (AArgument^.vKind = FX_VN_TUPLE) and (Length(AArgument^.Childs) = 3) then begin
        if (AArgument^.Childs[1]^.vKind = FX_VN_TUPLE) then begin
            if  ValueIsNaturalNumber(AArgument^.Childs[2], A) then begin
                if (A >= 0) and (A < Int64(Length(AArgument^.Childs[1]^.Childs))) then begin
                    CopyValueBranch(AArgument^.Childs[1], AReturn);
                    EraseValueBranch(AReturn^.Childs[A]);
                    CopyValueBranch(AArgument^.Childs[0], AReturn^.Childs[A]);
                end
                else
                    Result := PrimitiveError(FX_PRIM_PUT, TupleIndexOutOfBoundsStr, []);
            end
            else
                MakeFailValueBranch(AReturn);
        end
        else
            MakeFailValueBranch(AReturn);
    end
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_INPUT          (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

begin // () -> [Char]
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if (AArgument^.vKind = FX_VN_TUPLE) and (Length(AArgument^.Childs) = 0) then
        MakeStrValueBranch(FrontEnd.InputStr, AReturn)
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_OUTPUT         (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    Str: TFxString;

begin // [Char] -> ()
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if CheckValidStr(AArgument, Str) then begin
        FrontEnd.OutputStr(Str);
        MakeTrivialValueBranch(AReturn);
    end
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_CLEARSCREEN    (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

begin // () -> ()
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if (AArgument^.vKind = FX_VN_TUPLE) and (Length(AArgument^.Childs) = 0) then begin
        FrontEnd.ClearScreen;
        MakeTrivialValueBranch(AReturn);
    end
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_GETDATETIME    (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    Year, Month, DayOfWeek, Day, Hour, Minute, Second, Milliseconds: TFxInteger;

begin // () -> (Nat, Nat, Nat, Nat, Nat, Nat, Nat, Nat)
    Result := FX_RES_SUCCESS;

    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;

    if (AArgument^.vKind = FX_VN_TUPLE) and (Length(AArgument^.Childs) = 0) then begin
        GetNowDateTime(Year, Month, DayOfWeek, Day, Hour, Minute, Second, Milliseconds);
        MakeHeadValueBranch(FX_VN_TUPLE, AReturn);
        AddValueBranchChilds(AReturn, 8);
        MakeNumberValueBranch(Year, AReturn^.Childs[0]);
        MakeNumberValueBranch(Month, AReturn^.Childs[1]);
        MakeNumberValueBranch(DayOfWeek, AReturn^.Childs[2]);
        MakeNumberValueBranch(Day, AReturn^.Childs[3]);
        MakeNumberValueBranch(Hour, AReturn^.Childs[4]);
        MakeNumberValueBranch(Minute, AReturn^.Childs[5]);
        MakeNumberValueBranch(Second, AReturn^.Childs[6]);
        MakeNumberValueBranch(Milliseconds, AReturn^.Childs[7]);
    end
    else
        MakeFailValueBranch(AReturn);

LBL_END:

end;

function TPrimitiveFunctionList.__Primitive_SETDATETIME    (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    Year, Month, DayOfWeek, Day, Hour, Minute, Second, Milliseconds: TFxInteger;

begin // (Nat, Nat, Nat, Nat, Nat, Nat, Nat, Nat) -> ()
    Result := FX_RES_SUCCESS;

    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;

    if  (AArgument^.vKind = FX_VN_TUPLE) and (Length(AArgument^.Childs) = 8) and
        ValueIsIntegerNumber(AArgument^.Childs[0], Year        ) and
        ValueIsIntegerNumber(AArgument^.Childs[1], Month       ) and
        ValueIsIntegerNumber(AArgument^.Childs[2], DayOfWeek   ) and
        ValueIsIntegerNumber(AArgument^.Childs[3], Day         ) and
        ValueIsIntegerNumber(AArgument^.Childs[4], Hour        ) and
        ValueIsIntegerNumber(AArgument^.Childs[5], Minute      ) and
        ValueIsIntegerNumber(AArgument^.Childs[6], Second      ) and
        ValueIsIntegerNumber(AArgument^.Childs[7], Milliseconds)
        then begin
        SetNowDateTime(Year, Month, DayOfWeek, Day, Hour, Minute, Second, Milliseconds);
        MakeTrivialValueBranch(AReturn);
    end
    else
        MakeFailValueBranch(AReturn);

LBL_END:

end;

function TPrimitiveFunctionList.__Primitive_ANSWER         (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

begin // () -> _
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if (AArgument^.vKind = FX_VN_TUPLE) and (Length(AArgument^.Childs) = 0) then begin
        if Storage.HasAnswer then 
            CopyValueBranch(Storage.Answer, AReturn)
        else
            Result := PrimitiveError(FX_PRIM_ANSWER, ThereIsNotPreviousAnswerStr, []);
    end
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_ERROR          (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    Str: TFxString;

begin // [Char] -> _
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if CheckValidStr(AArgument, Str) then begin
        Result := FX_RES_ERR_SINGLE;
        Error.Code := Result;
        Error.Msg := Str;
        MakeFailValueBranch(AReturn);
    end
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_TRYSTRTONUM    (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    N: TFxNumber;
    B: TFxBool;
    Str: TFxString;
    
begin // [Char] -> (Real, Bool)
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if CheckValidStr(AArgument, Str) then begin
        B := fxStrUtils.TryStrToNumber(Str, N);
        if not B then N := NAN;
        MakeHeadValueBranch(FX_VN_TUPLE, AReturn);
        AddValueBranchChilds(AReturn, 2);
        MakeNumberValueBranch(N, AReturn^.Childs[0]);
        MakeBoolValueBranch(B, AReturn^.Childs[1]);
    end
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_VALUETOSTR     (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    ArgStr: TFxString;

begin // _ -> [Char]
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    // siempre encaja
    ArgStr := FStrConverter.__ValueToStr(AArgument);
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    MakeStrValueBranch(ArgStr, AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_TYPETOSTR      (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    AuxTypeBranch: TTypeExpr;
    ArgStr: TFxString;

begin // _ -> [Char]
    Result := FX_RES_SUCCESS;
    AuxTypeBranch := nil;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    // siempre encaja
    Result := FTypeInferencer.__Infer(AArgument, AuxTypeBranch);
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    if Result = FX_RES_SUCCESS then begin
        ArgStr := FStrConverter.__TypeToStr(AuxTypeBranch);
        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
        MakeStrValueBranch(ArgStr, AReturn);
    end;
    
LBL_END:
    
    EraseTypeBranch(AuxTypeBranch);
    
end;

function TPrimitiveFunctionList.__Primitive_VALUETOSTRFULL (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    ArgStr: TFxString;

begin // _ -> [Char]
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    // siempre encaja
    ArgStr := FStrConverter.__ValueToStrFullForm(AArgument);
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    MakeStrValueBranch(ArgStr, AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_ISANONYMOUS      (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

begin // _ -> Bool
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    // siempre encaja
    if (AArgument^.vKind = FX_VN_ANONYMOUS) then begin
        MakeBoolValueBranch(True, AReturn);
    end
    else
        MakeBoolValueBranch(False, AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_ISFREEIDENTIFIER (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

begin // _ -> Bool
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    // siempre encaja
    if (AArgument^.vKind = FX_VN_IDENTIFIER) then begin
        MakeBoolValueBranch(True, AReturn);
    end
    else
        MakeBoolValueBranch(False, AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_ISTUPLE          (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

begin // _ -> Bool
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    // siempre encaja
    if (AArgument^.vKind = FX_VN_TUPLE) then begin
        MakeBoolValueBranch(True, AReturn);
    end
    else
        MakeBoolValueBranch(False, AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_ISLAMBDA         (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

begin // _ -> Bool
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    // siempre encaja
    if (AArgument^.vKind = FX_VN_LAMBDA) then begin
        MakeBoolValueBranch(True, AReturn);
    end
    else
        MakeBoolValueBranch(False, AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_LANGUAGE         (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

begin // () -> Nat
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if (AArgument^.vKind = FX_VN_TUPLE) and (Length(AArgument^.Childs) = 0) then begin
        MakeNumberValueBranch(GetLanguage, AReturn);
    end
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_QUIT             (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

begin // () -> ()
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if (AArgument^.vKind = FX_VN_TUPLE) and (Length(AArgument^.Childs) = 0) then begin
        FrontEnd.DoQuit;
        MakeTrivialValueBranch(AReturn);
    end
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_INTERRUPT        (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

begin // () -> ()
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if (AArgument^.vKind = FX_VN_TUPLE) and (Length(AArgument^.Childs) = 0) then begin
        FrontEnd.DoInterrupt;
        MakeTrivialValueBranch(AReturn);
    end
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

function TPrimitiveFunctionList.__Primitive_RESTART          (AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

begin // () -> ()
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if (AArgument^.vKind = FX_VN_TUPLE) and (Length(AArgument^.Childs) = 0) then begin
        FrontEnd.DoRestart;
        MakeTrivialValueBranch(AReturn);
    end
    else
        MakeFailValueBranch(AReturn);
    
LBL_END:
    
end;

//--

function TPrimitiveFunctionList.CheckValidStr(ABranch: TValueExpr; var S: TFxString): Boolean;
var
    TailBranch, HeadBranch: TValueExpr;
begin
    
    Result := False;
    S := '';
    TailBranch := ABranch;
    while TailBranch <> nil do begin
        if TailBranch^.vKind = FX_VN_LIST_CONS then begin
            HeadBranch := TailBranch^.Childs[0];
            TailBranch := TailBranch^.Childs[1];
            if HeadBranch^.vKind = FX_VN_CHARACTER then
                S := S + HeadBranch^.D.cValue
            else
                Break;
        end
        else if TailBranch^.vKind = FX_VN_NULL then begin
            Result := True;
            Break;
        end
        else
            Break;
    end;
    
end;

function TPrimitiveFunctionList.PrimitiveError(AIdCode: Integer; AMsg: TFxString; const AArgs: array of const): Word;
begin
    Result := FX_RES_ERR_SINGLE;
    Error.Code := Result;
    AMsg := FormatMessage(AMsg, AArgs);
    Error.Msg := FormatMessage(PrimitiveErrorStr, [GetPrimFunctionFromCode(AIdCode), AMsg]);
end;

//--

procedure TPrimitiveFunctionList.Interrupt;
begin
    STOP := TRUE;
    FStrConverter.Interrupt;
    FTypeInferencer.Interrupt;
end;

procedure TPrimitiveFunctionList.Pause;
begin
    SLEEP := TRUE;
    FStrConverter.Pause;
    FTypeInferencer.Pause;
end;

procedure TPrimitiveFunctionList.Resume;
begin
    SLEEP := FALSE;
    FStrConverter.Resume;
    FTypeInferencer.Resume;
end;

end.
