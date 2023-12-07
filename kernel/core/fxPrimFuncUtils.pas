unit fxPrimFuncUtils;

interface

uses
    fxUtils, fxBasicStructure;

const

    FX_PRIMITIVE_COUNT       = 55;
    
    FX_PRIM_NONE             = 00; // _ -> _
    FX_PRIM_ADD              = 01; // (Real, Real) -> Real
    FX_PRIM_SUB              = 02; // (Real, Real) -> Real
    FX_PRIM_MUL              = 03; // (Real, Real) -> Real
    FX_PRIM_DIV              = 04; // (Real, Real) -> Real
    FX_PRIM_POW              = 05; // (Real, Real) -> Real
    FX_PRIM_EQUAL            = 06; // (Real, Real) -> Bool
    FX_PRIM_LESS             = 07; // (Real, Real) -> Bool
    FX_PRIM_GREATER          = 08; // (Real, Real) -> Bool
    FX_PRIM_ISNAN            = 09; // Real -> Bool
    FX_PRIM_TRUNC            = 10; // Real -> Int
    FX_PRIM_FRAC             = 11; // Real -> Real
    FX_PRIM_SIN              = 12; // Real -> Real
    FX_PRIM_COS              = 13; // Real -> Real
    FX_PRIM_TAN              = 14; // Real -> Real
    FX_PRIM_ASIN             = 15; // Real -> Real
    FX_PRIM_ACOS             = 16; // Real -> Real
    FX_PRIM_ATAN             = 17; // Real -> Real
    FX_PRIM_LN               = 18; // Real -> Real
    FX_PRIM_EXP              = 19; // Real -> Real
    FX_PRIM_REM              = 20; // (Int, Int) -> Int
    FX_PRIM_QUOT             = 21; // (Int, Int) -> Int
    FX_PRIM_BITNOT           = 22; // Int -> Int
    FX_PRIM_BITAND           = 23; // (Int, Int) -> Int
    FX_PRIM_BITOR            = 24; // (Int, Int) -> Int
    FX_PRIM_BITSHL           = 25; // (Int, Int) -> Int
    FX_PRIM_BITSHR           = 26; // (Int, Int) -> Int
    FX_PRIM_RANDOM           = 27; // Int -> Int
    FX_PRIM_ENCODECHAR       = 28; // Nat -> Char
    FX_PRIM_DECODECHAR       = 29; // Char -> Nat
    FX_PRIM_LENGTH           = 30; // [_] -> Nat
    FX_PRIM_GET              = 31; // ([_], Nat) -> _
    FX_PRIM_SET              = 32; // (_, [_], Nat) -> [_]
    FX_PRIM_ARITY            = 33; // _ -> Nat
    FX_PRIM_SELECT           = 34; // (_, Nat) -> _
    FX_PRIM_PUT              = 35; // (_, _, Nat) -> _
    FX_PRIM_INPUT            = 36; // () -> [Char]
    FX_PRIM_OUTPUT           = 37; // [Char] -> ()
    FX_PRIM_CLEARSCREEN      = 38; // () -> ()
    FX_PRIM_GETDATETIME      = 39; // () -> (Nat, Nat, Nat, Nat, Nat, Nat, Nat, Nat)
    FX_PRIM_SETDATETIME      = 40; // (Nat, Nat, Nat, Nat, Nat, Nat, Nat, Nat) -> ()
    FX_PRIM_ANSWER           = 41; // () -> _
    FX_PRIM_ERROR            = 42; // [Char] -> _
    FX_PRIM_TRYSTRTONUM      = 43; // [Char] -> (Real, Bool)
    FX_PRIM_VALUETOSTR       = 44; // _ -> [Char]
    FX_PRIM_TYPETOSTR        = 45; // _ -> [Char]
    FX_PRIM_VALUETOSTRFULL   = 46; // _ -> [Char]
    FX_PRIM_ISANONYMOUS      = 47; // _ -> Bool
    FX_PRIM_ISFREEIDENTIFIER = 48; // _ -> Bool
    FX_PRIM_ISTUPLE          = 49; // _ -> Bool
    FX_PRIM_ISLAMBDA         = 50; // _ -> Bool
    FX_PRIM_LANGUAGE         = 51; // () -> Nat
    FX_PRIM_QUIT             = 52; // () -> ()
    FX_PRIM_INTERRUPT        = 53; // () -> ()
    FX_PRIM_RESTART          = 54; // () -> ()
    
function GetPrimFunctionCode(AStr: TFxString): Integer;
function GetPrimFunctionFromCode(AIdCode: Integer): TFxString;
procedure GetPrimitiveFunctionType(AIdCode: Integer; var AType: TTypeExpr);

implementation

function GetPrimFunctionCode(AStr: TFxString): Integer;
begin
         if AStr = 'PrimAdd'              then Result := FX_PRIM_ADD            
    else if AStr = 'PrimSub'              then Result := FX_PRIM_SUB            
    else if AStr = 'PrimMul'              then Result := FX_PRIM_MUL            
    else if AStr = 'PrimDiv'              then Result := FX_PRIM_DIV            
    else if AStr = 'PrimPow'              then Result := FX_PRIM_POW            
    else if AStr = 'PrimEqual'            then Result := FX_PRIM_EQUAL          
    else if AStr = 'PrimLess'             then Result := FX_PRIM_LESS           
    else if AStr = 'PrimGreater'          then Result := FX_PRIM_GREATER        
    else if AStr = 'PrimIsNaN'            then Result := FX_PRIM_ISNAN      
    else if AStr = 'PrimTrunc'            then Result := FX_PRIM_TRUNC          
    else if AStr = 'PrimFrac'             then Result := FX_PRIM_FRAC           
    else if AStr = 'PrimSin'              then Result := FX_PRIM_SIN            
    else if AStr = 'PrimCos'              then Result := FX_PRIM_COS            
    else if AStr = 'PrimTan'              then Result := FX_PRIM_TAN            
    else if AStr = 'PrimASin'             then Result := FX_PRIM_ASIN           
    else if AStr = 'PrimACos'             then Result := FX_PRIM_ACOS           
    else if AStr = 'PrimATan'             then Result := FX_PRIM_ATAN           
    else if AStr = 'PrimLn'               then Result := FX_PRIM_LN             
    else if AStr = 'PrimExp'              then Result := FX_PRIM_EXP            
    else if AStr = 'PrimRem'              then Result := FX_PRIM_REM            
    else if AStr = 'PrimQuot'             then Result := FX_PRIM_QUOT           
    else if AStr = 'PrimBitNot'           then Result := FX_PRIM_BITNOT         
    else if AStr = 'PrimBitAnd'           then Result := FX_PRIM_BITAND         
    else if AStr = 'PrimBitOr'            then Result := FX_PRIM_BITOR          
    else if AStr = 'PrimBitShl'           then Result := FX_PRIM_BITSHL         
    else if AStr = 'PrimBitShr'           then Result := FX_PRIM_BITSHR         
    else if AStr = 'PrimRandom'           then Result := FX_PRIM_RANDOM         
    else if AStr = 'PrimEncodeChar'       then Result := FX_PRIM_ENCODECHAR     
    else if AStr = 'PrimDecodeChar'       then Result := FX_PRIM_DECODECHAR     
    else if AStr = 'PrimLength'           then Result := FX_PRIM_LENGTH         
    else if AStr = 'PrimGet'              then Result := FX_PRIM_GET            
    else if AStr = 'PrimSet'              then Result := FX_PRIM_SET            
    else if AStr = 'PrimArity'            then Result := FX_PRIM_ARITY          
    else if AStr = 'PrimSelect'           then Result := FX_PRIM_SELECT         
    else if AStr = 'PrimPut'              then Result := FX_PRIM_PUT            
    else if AStr = 'PrimInput'            then Result := FX_PRIM_INPUT          
    else if AStr = 'PrimOutput'           then Result := FX_PRIM_OUTPUT         
    else if AStr = 'PrimClearScreen'      then Result := FX_PRIM_CLEARSCREEN    
    else if AStr = 'PrimGetDateTime'      then Result := FX_PRIM_GETDATETIME         
    else if AStr = 'PrimSetDateTime'      then Result := FX_PRIM_SETDATETIME         
    else if AStr = 'PrimAnswer'           then Result := FX_PRIM_ANSWER         
    else if AStr = 'PrimError'            then Result := FX_PRIM_ERROR         
    else if AStr = 'PrimTryStrToNum'      then Result := FX_PRIM_TRYSTRTONUM       
    else if AStr = 'PrimValueToStr'       then Result := FX_PRIM_VALUETOSTR     
    else if AStr = 'PrimTypeToStr'        then Result := FX_PRIM_TYPETOSTR      
    else if AStr = 'PrimValueToStrFull'   then Result := FX_PRIM_VALUETOSTRFULL     
    else if AStr = 'PrimIsAnonymous'      then Result := FX_PRIM_ISANONYMOUS           
    else if AStr = 'PrimIsFreeIdentifier' then Result := FX_PRIM_ISFREEIDENTIFIER
    else if AStr = 'PrimIsTuple'          then Result := FX_PRIM_ISTUPLE               
    else if AStr = 'PrimIsLambda'         then Result := FX_PRIM_ISLAMBDA              
    else if AStr = 'PrimLanguage'         then Result := FX_PRIM_LANGUAGE     
    else if AStr = 'PrimQuit'             then Result := FX_PRIM_QUIT              
    else if AStr = 'PrimInterrupt'        then Result := FX_PRIM_INTERRUPT          
    else if AStr = 'PrimRestart'          then Result := FX_PRIM_RESTART            
    else                                       Result := -1;
end;

function GetPrimFunctionFromCode(AIdCode: Integer): TFxString;
begin
    case AIdCode of
        FX_PRIM_ADD              : Result := 'PrimAdd'              ;
        FX_PRIM_SUB              : Result := 'PrimSub'              ;
        FX_PRIM_MUL              : Result := 'PrimMul'              ;
        FX_PRIM_DIV              : Result := 'PrimDiv'              ;
        FX_PRIM_POW              : Result := 'PrimPow'              ;
        FX_PRIM_EQUAL            : Result := 'PrimEqual'            ;
        FX_PRIM_LESS             : Result := 'PrimLess'             ;
        FX_PRIM_GREATER          : Result := 'PrimGreater'          ;
        FX_PRIM_ISNAN            : Result := 'PrimIsNaN'            ;
        FX_PRIM_TRUNC            : Result := 'PrimTrunc'            ;
        FX_PRIM_FRAC             : Result := 'PrimFrac'             ;
        FX_PRIM_SIN              : Result := 'PrimSin'              ;
        FX_PRIM_COS              : Result := 'PrimCos'              ;
        FX_PRIM_TAN              : Result := 'PrimTan'              ;
        FX_PRIM_ASIN             : Result := 'PrimASin'             ;
        FX_PRIM_ACOS             : Result := 'PrimACos'             ;
        FX_PRIM_ATAN             : Result := 'PrimATan'             ;
        FX_PRIM_LN               : Result := 'PrimLn'               ;
        FX_PRIM_EXP              : Result := 'PrimExp'              ;
        FX_PRIM_REM              : Result := 'PrimRem'              ;
        FX_PRIM_QUOT             : Result := 'PrimQuot'             ;
        FX_PRIM_BITNOT           : Result := 'PrimBitNot'           ;
        FX_PRIM_BITAND           : Result := 'PrimBitAnd'           ;
        FX_PRIM_BITOR            : Result := 'PrimBitOr'            ;
        FX_PRIM_BITSHL           : Result := 'PrimBitShl'           ;
        FX_PRIM_BITSHR           : Result := 'PrimBitShr'           ;
        FX_PRIM_RANDOM           : Result := 'PrimRandom'           ;
        FX_PRIM_ENCODECHAR       : Result := 'PrimEncodeChar'       ;
        FX_PRIM_DECODECHAR       : Result := 'PrimDecodeChar'       ;
        FX_PRIM_LENGTH           : Result := 'PrimLength'           ;
        FX_PRIM_GET              : Result := 'PrimGet'              ;
        FX_PRIM_SET              : Result := 'PrimSet'              ;
        FX_PRIM_ARITY            : Result := 'PrimArity'            ;
        FX_PRIM_SELECT           : Result := 'PrimSelect'           ;
        FX_PRIM_PUT              : Result := 'PrimPut'              ;
        FX_PRIM_INPUT            : Result := 'PrimInput'            ;
        FX_PRIM_OUTPUT           : Result := 'PrimOutput'           ;
        FX_PRIM_CLEARSCREEN      : Result := 'PrimClearScreen'      ;
        FX_PRIM_GETDATETIME      : Result := 'PrimGetDateTime'      ;
        FX_PRIM_SETDATETIME      : Result := 'PrimSetDateTime'      ;
        FX_PRIM_ANSWER           : Result := 'PrimAnswer'           ;
        FX_PRIM_ERROR            : Result := 'PrimError'            ;
        FX_PRIM_TRYSTRTONUM      : Result := 'PrimTryStrToNum'      ;
        FX_PRIM_VALUETOSTR       : Result := 'PrimValueToStr'       ;
        FX_PRIM_TYPETOSTR        : Result := 'PrimTypeToStr'        ;
        FX_PRIM_VALUETOSTRFULL   : Result := 'PrimValueToStrFull'   ;
        FX_PRIM_ISANONYMOUS      : Result := 'PrimIsAnonymous'      ;
        FX_PRIM_ISFREEIDENTIFIER : Result := 'PrimIsFreeIdentifier'      ;
        FX_PRIM_ISTUPLE          : Result := 'PrimIsTuple'          ;
        FX_PRIM_ISLAMBDA         : Result := 'PrimIsLambda'         ;
        FX_PRIM_LANGUAGE         : Result := 'PrimLanguage'             ;
        FX_PRIM_QUIT             : Result := 'PrimQuit'             ;
        FX_PRIM_INTERRUPT        : Result := 'PrimInterrupt'        ;
        FX_PRIM_RESTART          : Result := 'PrimRestart'          ;
        else                       Result := '';
    end;
end;

procedure GetPrimitiveFunctionType(AIdCode: Integer; var AType: TTypeExpr);

label LBL_L1, LBL_L2;

var 
    FunctionBranch: TTypeExpr;

begin
    MakeHeadTypeBranch(FX_TN_FUNCTION, AType);
    AddTypeBranchChilds(AType, 2);
    case AIdCode of
        FX_PRIM_NONE           : begin
            MakeHeadTypeBranch(FX_TN_ANONYMOUS, AType^.Childs[0]);
            MakeHeadTypeBranch(FX_TN_ANONYMOUS, AType^.Childs[1]);
        end;
        FX_PRIM_ADD,
        FX_PRIM_SUB,
        FX_PRIM_MUL,
        FX_PRIM_DIV,
        FX_PRIM_POW            : begin
            MakeHeadTypeBranch(FX_TN_TUPLE, AType^.Childs[0]);
            AddTypeBranchChilds(AType^.Childs[0], 2);
            MakeHeadTypeBranch(FX_TN_REAL, AType^.Childs[0]^.Childs[0]);
            MakeHeadTypeBranch(FX_TN_REAL, AType^.Childs[0]^.Childs[1]);
            MakeHeadTypeBranch(FX_TN_REAL, AType^.Childs[1]);
        end;
        FX_PRIM_EQUAL,
        FX_PRIM_LESS,
        FX_PRIM_GREATER        : begin
            MakeHeadTypeBranch(FX_TN_TUPLE, AType^.Childs[0]);
            AddTypeBranchChilds(AType^.Childs[0], 2);
            MakeHeadTypeBranch(FX_TN_REAL, AType^.Childs[0]^.Childs[0]);
            MakeHeadTypeBranch(FX_TN_REAL, AType^.Childs[0]^.Childs[1]);
            MakeHeadTypeBranch(FX_TN_BOOLEAN, AType^.Childs[1]);
        end;
        FX_PRIM_ISNAN : begin
            MakeHeadTypeBranch(FX_TN_REAL, AType^.Childs[0]);
            MakeHeadTypeBranch(FX_TN_BOOLEAN, AType^.Childs[1]);
        end;
        FX_PRIM_TRUNC          : begin
            MakeHeadTypeBranch(FX_TN_REAL, AType^.Childs[0]);
            MakeHeadTypeBranch(FX_TN_INTEGER, AType^.Childs[1]);
        end;
        FX_PRIM_FRAC,
        FX_PRIM_SIN,
        FX_PRIM_COS,
        FX_PRIM_TAN,
        FX_PRIM_ASIN,
        FX_PRIM_ACOS,
        FX_PRIM_ATAN,
        FX_PRIM_LN,
        FX_PRIM_EXP            : begin
            MakeHeadTypeBranch(FX_TN_REAL, AType^.Childs[0]);
            MakeHeadTypeBranch(FX_TN_REAL, AType^.Childs[1]);
        end;
        FX_PRIM_REM,
        FX_PRIM_QUOT           : begin
            LBL_L1:
            MakeHeadTypeBranch(FX_TN_TUPLE, AType^.Childs[0]);
            AddTypeBranchChilds(AType^.Childs[0], 2);
            MakeHeadTypeBranch(FX_TN_INTEGER, AType^.Childs[0]^.Childs[0]);
            MakeHeadTypeBranch(FX_TN_INTEGER, AType^.Childs[0]^.Childs[1]);
            MakeHeadTypeBranch(FX_TN_INTEGER, AType^.Childs[1]);
        end;
        FX_PRIM_BITNOT         : begin
            MakeHeadTypeBranch(FX_TN_INTEGER, AType^.Childs[0]);
            MakeHeadTypeBranch(FX_TN_INTEGER, AType^.Childs[1]);
        end;
        FX_PRIM_BITAND,
        FX_PRIM_BITOR,
        FX_PRIM_BITSHL,
        FX_PRIM_BITSHR         : begin
            goto LBL_L1;
        end;
        FX_PRIM_ENCODECHAR     : begin
            MakeHeadTypeBranch(FX_TN_NATURAL, AType^.Childs[0]);
            MakeHeadTypeBranch(FX_TN_CHARACTER, AType^.Childs[1]);
        end;
        FX_PRIM_RANDOM         : begin
            MakeHeadTypeBranch(FX_TN_INTEGER, AType^.Childs[0]);
            MakeHeadTypeBranch(FX_TN_INTEGER, AType^.Childs[1]);
        end;
        FX_PRIM_DECODECHAR     : begin
            MakeHeadTypeBranch(FX_TN_CHARACTER, AType^.Childs[0]);
            MakeHeadTypeBranch(FX_TN_NATURAL, AType^.Childs[1]);
        end;
        FX_PRIM_LENGTH         : begin
            MakeHeadTypeBranch(FX_TN_LIST, AType^.Childs[0]);
            AddTypeBranchChilds(AType^.Childs[0], 1);
            MakeHeadTypeBranch(FX_TN_ANONYMOUS, AType^.Childs[0]^.Childs[0]);
            MakeHeadTypeBranch(FX_TN_ANONYMOUS, AType^.Childs[1]);
        end;
        FX_PRIM_GET         : begin
            MakeHeadTypeBranch(FX_TN_TUPLE, AType^.Childs[0]);
            AddTypeBranchChilds(AType^.Childs[0], 2);
            MakeHeadTypeBranch(FX_TN_LIST, AType^.Childs[0]^.Childs[0]);
            AddTypeBranchChilds(AType^.Childs[0]^.Childs[0], 1);
            MakeHeadTypeBranch(FX_TN_ANONYMOUS, AType^.Childs[0]^.Childs[0]^.Childs[0]);
            MakeHeadTypeBranch(FX_TN_NATURAL, AType^.Childs[0]^.Childs[1]);
            MakeHeadTypeBranch(FX_TN_ANONYMOUS, AType^.Childs[1]);
        end;
        FX_PRIM_SET         : begin
            MakeHeadTypeBranch(FX_TN_TUPLE, AType^.Childs[0]);
            AddTypeBranchChilds(AType^.Childs[0], 3);
            MakeHeadTypeBranch(FX_TN_ANONYMOUS, AType^.Childs[0]^.Childs[0]);
            MakeHeadTypeBranch(FX_TN_LIST, AType^.Childs[0]^.Childs[1]);
            AddTypeBranchChilds(AType^.Childs[0]^.Childs[1], 1);
            MakeHeadTypeBranch(FX_TN_ANONYMOUS, AType^.Childs[0]^.Childs[1]^.Childs[0]);
            MakeHeadTypeBranch(FX_TN_NATURAL, AType^.Childs[0]^.Childs[2]);
            MakeHeadTypeBranch(FX_TN_LIST, AType^.Childs[1]);
            AddTypeBranchChilds(AType^.Childs[1], 1);
            MakeHeadTypeBranch(FX_TN_ANONYMOUS, AType^.Childs[1]^.Childs[0]);
        end;
        FX_PRIM_ARITY          : begin
            MakeHeadTypeBranch(FX_TN_ANONYMOUS, AType^.Childs[0]);
            MakeHeadTypeBranch(FX_TN_NATURAL, AType^.Childs[1]);
        end;
        FX_PRIM_SELECT         : begin
            MakeHeadTypeBranch(FX_TN_TUPLE, AType^.Childs[0]);
            AddTypeBranchChilds(AType^.Childs[0], 2);
            MakeHeadTypeBranch(FX_TN_ANONYMOUS, AType^.Childs[0]^.Childs[0]);
            MakeHeadTypeBranch(FX_TN_NATURAL, AType^.Childs[0]^.Childs[1]);
            MakeHeadTypeBranch(FX_TN_ANONYMOUS, AType^.Childs[1]);
        end;
        FX_PRIM_PUT            : begin
            MakeHeadTypeBranch(FX_TN_TUPLE, AType^.Childs[0]);
            AddTypeBranchChilds(AType^.Childs[0], 3);
            MakeHeadTypeBranch(FX_TN_ANONYMOUS, AType^.Childs[0]^.Childs[0]);
            MakeHeadTypeBranch(FX_TN_ANONYMOUS, AType^.Childs[0]^.Childs[1]);
            MakeHeadTypeBranch(FX_TN_NATURAL, AType^.Childs[0]^.Childs[2]);
            MakeHeadTypeBranch(FX_TN_ANONYMOUS, AType^.Childs[1]);
        end;
        FX_PRIM_INPUT          : begin
            MakeTrivialTypeBranch(AType^.Childs[0]);
            MakeHeadTypeBranch(FX_TN_LIST, AType^.Childs[1]);
            AddTypeBranchChilds(AType^.Childs[1], 1);
            MakeHeadTypeBranch(FX_TN_CHARACTER, AType^.Childs[1]^.Childs[0]);
        end;
        FX_PRIM_OUTPUT         : begin
            MakeHeadTypeBranch(FX_TN_LIST, AType^.Childs[0]);
            AddTypeBranchChilds(AType^.Childs[0], 1);
            MakeHeadTypeBranch(FX_TN_CHARACTER, AType^.Childs[0]^.Childs[0]);
            MakeTrivialTypeBranch(AType^.Childs[1]);
        end;
        FX_PRIM_CLEARSCREEN    : begin
            MakeTrivialTypeBranch(AType^.Childs[0]);
            MakeTrivialTypeBranch(AType^.Childs[1]);
        end;
        FX_PRIM_GETDATETIME    : begin
            MakeTrivialTypeBranch(AType^.Childs[0]);
            MakeHeadTypeBranch(FX_TN_TUPLE, AType^.Childs[1]);
            AddTypeBranchChilds(AType^.Childs[1], 8);
            MakeHeadTypeBranch(FX_TN_NATURAL, AType^.Childs[1]^.Childs[0]);
            MakeHeadTypeBranch(FX_TN_NATURAL, AType^.Childs[1]^.Childs[1]);
            MakeHeadTypeBranch(FX_TN_NATURAL, AType^.Childs[1]^.Childs[2]);
            MakeHeadTypeBranch(FX_TN_NATURAL, AType^.Childs[1]^.Childs[3]);
            MakeHeadTypeBranch(FX_TN_NATURAL, AType^.Childs[1]^.Childs[4]);
            MakeHeadTypeBranch(FX_TN_NATURAL, AType^.Childs[1]^.Childs[5]);
            MakeHeadTypeBranch(FX_TN_NATURAL, AType^.Childs[1]^.Childs[6]);
            MakeHeadTypeBranch(FX_TN_NATURAL, AType^.Childs[1]^.Childs[7]);
        end;
        FX_PRIM_SETDATETIME    : begin
            MakeHeadTypeBranch(FX_TN_TUPLE, AType^.Childs[0]);
            AddTypeBranchChilds(AType^.Childs[0], 8);
            MakeHeadTypeBranch(FX_TN_NATURAL, AType^.Childs[0]^.Childs[0]);
            MakeHeadTypeBranch(FX_TN_NATURAL, AType^.Childs[0]^.Childs[1]);
            MakeHeadTypeBranch(FX_TN_NATURAL, AType^.Childs[0]^.Childs[2]);
            MakeHeadTypeBranch(FX_TN_NATURAL, AType^.Childs[0]^.Childs[3]);
            MakeHeadTypeBranch(FX_TN_NATURAL, AType^.Childs[0]^.Childs[4]);
            MakeHeadTypeBranch(FX_TN_NATURAL, AType^.Childs[0]^.Childs[5]);
            MakeHeadTypeBranch(FX_TN_NATURAL, AType^.Childs[0]^.Childs[6]);
            MakeHeadTypeBranch(FX_TN_NATURAL, AType^.Childs[0]^.Childs[7]);
            MakeTrivialTypeBranch(AType^.Childs[1]);
        end;
        FX_PRIM_ANSWER         : begin
            MakeTrivialTypeBranch(AType^.Childs[0]);
            MakeHeadTypeBranch(FX_TN_ANONYMOUS, AType^.Childs[1]);
        end;
        FX_PRIM_ERROR          : begin
            MakeHeadTypeBranch(FX_TN_LIST, AType^.Childs[0]);
            AddTypeBranchChilds(AType^.Childs[0], 1);
            MakeHeadTypeBranch(FX_TN_CHARACTER, AType^.Childs[0]^.Childs[0]);
            MakeHeadTypeBranch(FX_TN_ANONYMOUS, AType^.Childs[1]);
        end;
        FX_PRIM_TRYSTRTONUM    : begin
            MakeHeadTypeBranch(FX_TN_LIST, AType^.Childs[0]);
            AddTypeBranchChilds(AType^.Childs[0], 1);
            MakeHeadTypeBranch(FX_TN_CHARACTER, AType^.Childs[0]^.Childs[0]);
            MakeHeadTypeBranch(FX_TN_TUPLE, AType^.Childs[1]);
            AddTypeBranchChilds(AType^.Childs[1], 2);
            MakeHeadTypeBranch(FX_TN_REAL, AType^.Childs[1]^.Childs[0]);
            MakeHeadTypeBranch(FX_TN_BOOLEAN, AType^.Childs[1]^.Childs[1]);
        end;
        FX_PRIM_VALUETOSTR,
        FX_PRIM_TYPETOSTR,
        FX_PRIM_VALUETOSTRFULL : begin
            MakeHeadTypeBranch(FX_TN_ANONYMOUS, AType^.Childs[0]);
            MakeHeadTypeBranch(FX_TN_LIST, AType^.Childs[1]);
            AddTypeBranchChilds(AType^.Childs[1], 1);
            MakeHeadTypeBranch(FX_TN_CHARACTER, AType^.Childs[1]^.Childs[0]);
        end;
        FX_PRIM_ISANONYMOUS,
        FX_PRIM_ISFREEIDENTIFIER,
        FX_PRIM_ISTUPLE,
        FX_PRIM_ISLAMBDA : begin
            MakeHeadTypeBranch(FX_TN_ANONYMOUS, AType^.Childs[0]);
            MakeHeadTypeBranch(FX_TN_BOOLEAN, AType^.Childs[1]);
        end;
        FX_PRIM_LANGUAGE: begin
            MakeTrivialTypeBranch(AType^.Childs[0]);
            MakeHeadTypeBranch(FX_TN_NATURAL, AType^.Childs[1]);
        end;
        FX_PRIM_QUIT,
        FX_PRIM_INTERRUPT,
        FX_PRIM_RESTART  : begin
            MakeTrivialTypeBranch(AType^.Childs[0]);
            MakeTrivialTypeBranch(AType^.Childs[1]);
        end;
        else
            EraseTypeBranch(AType); // retornar una rama vacia
    end;
end;

end.
