unit fxEvaluator;

interface

uses
    fxMath, fxUtils, fxStrUtils, fxStorage, fxError, fxBasicStructure, fxInterpreterUtils, fxPrimFuncUtils,
    fxPrimFunctions, fxTypeChecker, fxStrConverter;

type
    
    TEvaluator = class
    private
        FrontEnd: IFrontEndListener;
        Interpreter: IInterpreterListener;
        Storage: TStorage;
        Error: TErrorRegister;
        
        FTypeChecker: TTypeChecker;
        FPrimitiveFunctionList: TPrimitiveFunctionList;
        FStrConverter: TStrConverter;
        
        function EvaluationError(AMsg: TFxString): Word; overload;
        function EvaluationError(AMsg: TFxString; const AArgs: array of const): Word; overload;
        function FindIdentifierInPatternBranch(AIdCode: Integer; APatternBranch: TPatternExpr): Boolean;

        function __MatchWithIdentifier(APattern, AArgument: TValueExpr; var AMatches: Boolean): Word;
        function __Match(APattern, AArgument: TValueExpr; var AReturn: TValueExpr): Word;
        function __PrimitiveMap(var ABranch: TValueExpr): Word;
        function __Map(var ABranch: TValueExpr): Word;
    protected
        STOP: BOOLEAN;
    public
        constructor Create(AFrontEnd: IFrontEndListener; AInterpreter: IInterpreterListener;
            AStorage: TStorage; AError: TErrorRegister);
        destructor Destroy; override;
        
        function __Reduce(var ABranch: TValueExpr): Word;
        function __ReplaceIdentifier(AIdCode: Integer; AArgument: TValueExpr; var AReturn: TValueExpr): Word;
        function __Evaluate(var AValue: TValueExpr): Word;
        procedure Interrupt;
    end;
    
implementation

{ TEvaluator }

constructor TEvaluator.Create(AFrontEnd: IFrontEndListener; AInterpreter: IInterpreterListener;
    AStorage: TStorage; AError: TErrorRegister);
begin
    inherited Create;
    FrontEnd := AFrontEnd;
    Interpreter := AInterpreter;
    Storage := AStorage;
    Error := AError;
    
    FTypeChecker := TTypeChecker.Create(FrontEnd, Interpreter, Storage, Error);
    FPrimitiveFunctionList := TPrimitiveFunctionList.Create(FrontEnd, Interpreter, Storage, Error);
    FStrConverter := TStrConverter.Create(FrontEnd, Interpreter, Storage, Error);
    
    STOP := FALSE;
end;

destructor TEvaluator.Destroy;
begin
    FTypeChecker.Free;
    FPrimitiveFunctionList.Free;
    FStrConverter.Free;
    inherited;
end;

function TEvaluator.EvaluationError(AMsg: TFxString): Word;
begin
    Result := EvaluationError(AMsg, []);
end;

function TEvaluator.EvaluationError(AMsg: TFxString; const AArgs: array of const): Word;
begin
    Result := FX_RES_ERR_SINGLE;
    Error.Code := Result;
    Error.Msg := FormatMessage(AMsg, AArgs);
end;

function TEvaluator.FindIdentifierInPatternBranch(AIdCode: Integer; APatternBranch: TPatternExpr): Boolean;
var
    K: Integer;
begin
    Result := False;
    case APatternBranch^.vKind of
        FX_PN_NONE      :;
        FX_PN_NUMBER    :;
        FX_PN_BOOLEAN   :;
        FX_PN_CHARACTER :;
        FX_PN_NULL      :;
        FX_PN_FAIL      :;
        FX_PN_IDENTIFIER: begin
            Result := APatternBranch^.D.vIdCode = AIdCode;
        end;
        FX_PN_ANONYMOUS :;
        FX_PN_TUPLE     : begin
            for K := 0 to Length(APatternBranch^.Childs) - 1 do begin
                Result := FindIdentifierInPatternBranch(AIdCode, APatternBranch^.Childs[K]);
                if Result then Break;
            end;
        end;
        FX_PN_LIST_CONS : begin
            Result := FindIdentifierInPatternBranch(AIdCode, APatternBranch^.Childs[0]);
            if not Result then
                Result := FindIdentifierInPatternBranch(AIdCode, APatternBranch^.Childs[1]);
        end;
    end;
end;

//---

function TEvaluator.__MatchWithIdentifier(APattern, AArgument: TValueExpr; var AMatches: Boolean): Word;

LABEL LBL_END;

begin
    
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END;
    
    Result := FTypeChecker.__ValueMatchsValueType(APattern, AArgument, AMatches);
    IF STOP THEN GOTO LBL_END;
    
LBL_END:
    
end;

function TEvaluator.__ReplaceIdentifier(AIdCode: Integer; AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

    procedure DoReplacement(AReturnBranch: TValueExpr);
    var
        K: Integer;
    begin
        case AReturnBranch^.vKind of
            FX_VN_NONE       :;
            FX_VN_NUMBER     :;
            FX_VN_BOOLEAN    :;
            FX_VN_CHARACTER  :;
            FX_VN_NULL       :;
            FX_VN_FAIL       :;
            FX_VN_IDENTIFIER : begin
                if AIdCode = AReturnBranch^.D.vIdCode then begin
                    EraseValueBranchChilds(AReturnBranch);
                    CopyValueBranchTo(AArgument, AReturnBranch);
                end;
            end;
            FX_VN_PRIMITIVE  :;
            FX_VN_ANONYMOUS  :;
            FX_VN_TRY        : begin
                DoReplacement(AReturnBranch^.Childs[0]);
                DoReplacement(AReturnBranch^.Childs[1]);
            end;
            FX_VN_TUPLE      : begin
                for K := 0 to Length(AReturnBranch^.Childs) - 1 do
                    DoReplacement(AReturnBranch^.Childs[K]);
            end;
            FX_VN_LIST_CONS       : begin
                DoReplacement(AReturnBranch^.Childs[0]);
                DoReplacement(AReturnBranch^.Childs[1]);
            end;
            FX_VN_LAMBDA     : begin
                if not FindIdentifierInPatternBranch(AIdCode, AReturnBranch^.Childs[0]) then begin
                    // es identificador libre
                    DoReplacement(AReturnBranch^.Childs[1]);
                end;
            end;
            FX_VN_APPLICATION: begin
                DoReplacement(AReturnBranch^.Childs[0]);
                DoReplacement(AReturnBranch^.Childs[1]);
            end;
        end;
    end;

begin
    
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END;
    
    DoReplacement(AReturn);
    
LBL_END:
    
end;

function TEvaluator.__Match(APattern, AArgument: TValueExpr; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    K: Integer;
    IdMatches: Boolean;
    
begin

    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END;
    
    case APattern^.vKind of
        FX_PN_NONE      :;
        FX_PN_NUMBER    : begin
            if (AArgument^.vKind = FX_VN_NUMBER) and fxMath.nEqual(APattern^.D.nValue, AArgument^.D.nValue) then begin
                // Encaja , continuar
            end
            else begin
                // reemplazar con fail
                EraseValueBranchChilds(AReturn);
                AReturn^.vKind := FX_VN_FAIL;
            end;
        end;
        FX_PN_BOOLEAN   : begin
            if (AArgument^.vKind = FX_VN_BOOLEAN) and (APattern^.D.bValue = AArgument^.D.bValue) then begin
                // Encaja , continuar
            end
            else begin
                // reemplazar con fail
                EraseValueBranchChilds(AReturn);
                AReturn^.vKind := FX_VN_FAIL;
            end;
        end;
        FX_PN_CHARACTER : begin
            if (AArgument^.vKind = FX_VN_CHARACTER) and (APattern^.D.cValue = AArgument^.D.cValue) then begin
                // Encaja , continuar
            end
            else begin
                // reemplazar con fail
                EraseValueBranchChilds(AReturn);
                AReturn^.vKind := FX_VN_FAIL;
            end;
        end;
        FX_PN_NULL      : begin
            if (AArgument^.vKind = FX_VN_NULL) then begin
                // Encaja , continuar
            end
            else begin
                // reemplazar con fail
                EraseValueBranchChilds(AReturn);
                AReturn^.vKind := FX_VN_FAIL;
            end;
        end;
        FX_PN_FAIL      : begin
            // nada encaja con esto
            EraseValueBranchChilds(AReturn);
            AReturn^.vKind := FX_VN_FAIL;
        end;
        FX_PN_IDENTIFIER: begin
            Result := __MatchWithIdentifier(APattern, AArgument, IdMatches);
            IF STOP THEN GOTO LBL_END;
            if Result = FX_RES_SUCCESS then begin
                if IdMatches then begin
                    if  (AArgument^.vKind = FX_VN_IDENTIFIER) and
                        (AArgument^.D.vIdCode = APattern^.D.vIdCode) and
                        (APattern^.D.tKind = FX_TN_NONE) and
                        (AArgument^.D.tKind = FX_TN_NONE) then begin end
                    else begin
                        Result := __ReplaceIdentifier(APattern^.D.vIdCode, AArgument, AReturn);
                        IF STOP THEN GOTO LBL_END;
                    end;
                end
                else begin
                    EraseValueBranchChilds(AReturn);
                    AReturn^.vKind := FX_VN_FAIL;
                end;
            end;
        end;
        FX_PN_ANONYMOUS : begin
            // siempre encaja, continuar
        end;
        FX_PN_TUPLE     : begin
            if (AArgument^.vKind = FX_VN_TUPLE) and (Length(APattern^.Childs) = Length(AArgument^.Childs)) then begin
                // incluye automaticamente tupla vacia
                for K := 0 to Length(APattern^.Childs) - 1 do begin
                    IF STOP THEN GOTO LBL_END;
                    Result := __Match(APattern^.Childs[K], AArgument^.Childs[K], AReturn);
                    IF STOP THEN GOTO LBL_END;
                    if Result = FX_RES_SUCCESS then begin
                        if AReturn^.vKind = FX_VN_FAIL then
                            Break // ya no es necesario seguir encajando
                        else
                            //K-esimo patron encaja, continuar bucle
                            ;
                    end
                    else
                        Break;
                end;
            end
            else begin
                EraseValueBranchChilds(AReturn);
                AReturn^.vKind := FX_VN_FAIL;
            end;
        end;
        FX_PN_LIST_CONS : begin
            if AArgument^.vKind = FX_VN_LIST_CONS then begin
                Result := __Match(APattern^.Childs[0], AArgument^.Childs[0], AReturn);
                IF STOP THEN GOTO LBL_END;
                if Result = FX_RES_SUCCESS then begin
                    if AReturn^.vKind <> FX_VN_FAIL then begin
                        Result := __Match(APattern^.Childs[1], AArgument^.Childs[1], AReturn);
                        IF STOP THEN GOTO LBL_END;
                    end
                    else
                        // ya no es necesario seguir encajando
                        ;
                end;
            end
            else begin
                EraseValueBranchChilds(AReturn);
                AReturn^.vKind := FX_VN_FAIL;
            end;
        end;
    end;
    
LBL_END:
    
end;

function TEvaluator.__PrimitiveMap(var ABranch: TValueExpr): Word;

LABEL LBL_END;

var
    Argument, Return: TValueExpr;
    
begin
    
    Result := FX_RES_SUCCESS;
    
    Argument := nil;
    Return := nil;
    
    IF STOP THEN GOTO LBL_END;
    
    Argument := ABranch^.Childs[1];
    ABranch^.Childs[1] := nil;
    Return := nil;
    Result := FPrimitiveFunctionList[ABranch^.Childs[0]^.D.vIdCode](Argument, Return);
    IF STOP THEN GOTO LBL_END;
    if Result = FX_RES_SUCCESS then begin
        EraseValueBranch(ABranch);
        ABranch := Return;
        Return := nil;
    end;
    
LBL_END:
    
    EraseValueBranch(Argument);
    EraseValueBranch(Return);
    
end;

function TEvaluator.__Map(var ABranch: TValueExpr): Word;

LABEL LBL_END;

var
    Pattern, Argument, Return: TValueExpr;
    
begin
    
    Result := FX_RES_SUCCESS;
    
    Pattern := nil;
    Argument := nil;
    Return := nil;
    
    IF STOP THEN GOTO LBL_END;
    
    if ABranch^.Childs[0]^.vKind = FX_VN_PRIMITIVE then begin
        Result := __PrimitiveMap(ABranch);
        IF STOP THEN GOTO LBL_END;
    end
    else if ABranch^.Childs[0]^.vKind = FX_VN_LAMBDA then begin
        Pattern := ABranch^.Childs[0]^.Childs[0];
        ABranch^.Childs[0]^.Childs[0] := nil;
        Argument := ABranch^.Childs[1];
        ABranch^.Childs[1] := nil;
        Return := ABranch^.Childs[0]^.Childs[1];
        ABranch^.Childs[0]^.Childs[1] := nil;
        EraseValueBranch(ABranch);
        Result := __Match(Pattern, Argument, Return);
        IF STOP THEN GOTO LBL_END;
        if Result = FX_RES_SUCCESS then begin
            ABranch := Return;
            Return := nil;
        end;
    end;
    
LBL_END:
    
    EraseValueBranch(Pattern);
    EraseValueBranch(Argument);
    EraseValueBranch(Return);
    
end;

function TEvaluator.__Reduce(var ABranch: TValueExpr): Word;

LABEL LBL_END, LBL_AGAIN;

var
    K: Integer;
    AuxBranch: TValueExpr;
    Str: TFxString;

begin
LBL_AGAIN:
    
    Result := FX_RES_SUCCESS;

    IF STOP THEN GOTO LBL_END;

        case ABranch^.vKind of
            FX_VN_NONE       : ;
            FX_VN_NUMBER     : ;
            FX_VN_BOOLEAN    : ;
            FX_VN_CHARACTER  : ;
            FX_VN_NULL       : ;
            FX_VN_FAIL       : ;
            FX_VN_IDENTIFIER : begin
                if (ABranch^.D.vIdCode >= 0) and Storage[ABranch^.D.vIdCode].HasValue then begin
                    EraseValueBranchChilds(ABranch);
                    CopyValueBranchTo(Storage[ABranch^.D.vIdCode].Value, ABranch);
                    goto LBL_AGAIN; // para poder programar recursiones y bucles infinitas
                end;
            end;
            FX_VN_PRIMITIVE  : ; // no reduce
            FX_VN_ANONYMOUS  : ; // no reduce
            FX_VN_TRY        : begin
                Result := __Reduce(ABranch^.Childs[0]); // intentar que no falle
                IF STOP THEN GOTO LBL_END;
                if Result = FX_RES_SUCCESS then begin
                    if ABranch^.Childs[0]^.vKind = FX_VN_FAIL then begin
                        // primero reemplazar con su expresion derecha y luego reducir(para recursividad eterna)
                        AuxBranch := ABranch^.Childs[1];
                        ABranch^.Childs[1] := nil;
                        EraseValueBranch(ABranch);
                        ABranch := AuxBranch;
                        AuxBranch := nil;
                        goto LBL_AGAIN;
                    end
                    else begin
                        // reemplazar con su expresion izquierda
                        AuxBranch := ABranch^.Childs[0];
                        ABranch^.Childs[0] := nil;
                        EraseValueBranch(ABranch);
                        ABranch := AuxBranch;
                        AuxBranch := nil;
                    end;
                end;
            end;
            FX_VN_TUPLE      : begin
                for K := 0 to Length(ABranch^.Childs) - 1 do begin // en caso de tupla vacia ya estara reducido
                    IF STOP THEN GOTO LBL_END;
                    Result := __Reduce(ABranch^.Childs[K]);
                    IF STOP THEN GOTO LBL_END;
                    if Result = FX_RES_SUCCESS then begin
                        if ABranch^.Childs[K]^.vKind = FX_VN_FAIL then begin
                            EraseValueBranchChilds(ABranch);
                            ABranch^.vKind := FX_VN_FAIL;
                            Break;
                        end
                        else begin
                            // rama reducida, continuar con otras
                        end;
                    end
                    else
                        Break;
                end;
            end;
            FX_VN_LIST_CONS       : begin
                // no es necesario revisar tipo(ejm, se permite: ['a', 1, \x -> x])
                Result := __Reduce(ABranch^.Childs[0]);
                IF STOP THEN GOTO LBL_END;
                if Result = FX_RES_SUCCESS then begin
                    if ABranch^.Childs[0]^.vKind = FX_VN_FAIL then begin
                        EraseValueBranchChilds(ABranch);
                        ABranch^.vKind := FX_VN_FAIL;
                    end
                    else begin
                        Result := __Reduce(ABranch^.Childs[1]);
                        IF STOP THEN GOTO LBL_END;
                        if Result = FX_RES_SUCCESS then begin
                            if ABranch^.Childs[1]^.vKind = FX_VN_FAIL then begin
                                EraseValueBranchChilds(ABranch);
                                ABranch^.vKind := FX_VN_FAIL;
                            end
                            else if (ABranch^.Childs[1]^.vKind = FX_VN_LIST_CONS) or
                                (ABranch^.Childs[1]^.vKind = FX_VN_NULL) then begin
                                // correctamente reducido, continuar
                            end
                            else begin
                                EraseValueBranchChilds(ABranch);
                                ABranch^.vKind := FX_VN_FAIL;
                            end;
                        end;
                    end;
                end;
            end;
            FX_VN_LAMBDA     : ; // no reduce
            FX_VN_APPLICATION: begin
                Result := __Reduce(ABranch^.Childs[0]);
                IF STOP THEN GOTO LBL_END;
                if Result = FX_RES_SUCCESS then begin
                    if ABranch^.Childs[0]^.vKind = FX_VN_FAIL then begin
                        EraseValueBranchChilds(ABranch);
                        ABranch^.vKind := FX_VN_FAIL;
                    end
                    else if (ABranch^.Childs[0]^.vKind <> FX_VN_PRIMITIVE) and (ABranch^.Childs[0]^.vKind <> FX_VN_LAMBDA) then begin
                        // la parte izquierda de la aplicacion no es una funcion(detectar aqui para ya no evaluar el lado derecho)
                        Str := FStrConverter.__ValueToStr(ABranch^.Childs[0]);
                        IF STOP THEN GOTO LBL_END;
                        Result := EvaluationError(ExpectedFunctionLeftSideStr, [Str]);
                    end
                    else begin
                        Result := __Reduce(ABranch^.Childs[1]);
                        IF STOP THEN GOTO LBL_END;
                        if Result = FX_RES_SUCCESS then begin
                            if ABranch^.Childs[1]^.vKind = FX_VN_FAIL then begin
                                EraseValueBranchChilds(ABranch);
                                ABranch^.vKind := FX_VN_FAIL;
                            end
                            else begin
                                Result := __Map(ABranch);
                                IF STOP THEN GOTO LBL_END;
                                if Result = FX_RES_SUCCESS then begin
                                    goto LBL_AGAIN; // para poder programar recursiones y bucles infinitas
                                end;
                            end;
                        end;
                    end;
                end;
            end;
        end;
    
LBL_END:

end;

function TEvaluator.__Evaluate(var AValue: TValueExpr): Word;

LABEL LBL_END;

begin
    
    Result := FX_RES_SUCCESS;

    IF STOP THEN GOTO LBL_END;
    fxMath.iRandomize;
    
    Result := __Reduce(AValue);
    IF STOP THEN GOTO LBL_END;
    
LBL_END:
    
end;

//---
procedure TEvaluator.Interrupt;
begin
    STOP := TRUE;
    FTypeChecker.Interrupt;
    FPrimitiveFunctionList.Interrupt;
    FStrConverter.Interrupt;
end;

end.
