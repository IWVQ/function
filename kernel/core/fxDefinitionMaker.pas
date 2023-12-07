unit fxDefinitionMaker;

interface

uses
    fxUtils, fxStrUtils, fxStorage, fxError, fxBasicStructure, fxInterpreterUtils, fxPrimFuncUtils,
    fxTypeChecker, fxStrConverter;

type

    TDefinitionMaker = class
    private
        FrontEnd: IFrontEndListener;
        Interpreter: IInterpreterListener;
        Storage: TStorage;
        Error: TErrorRegister;

        FTypeChecker: TTypeChecker;
        FStrConverter: TStrConverter;

        AvailableInternalVariableCode: Integer;
        RIVIndex: Integer;
        function DefMakingError(AMsg: TFxString; const AArgs: array of const): Word;
        function UseNewInternalVariable(AIdCode: Integer): Integer;
        function __CheckForSynonymous(var ATypeBranch: TTypeExpr): Word;
        function __InheritTypeBranch(ATypeBranch: TTypeExpr; var AValueBranch: TValueExpr): Word;
    protected
        STOP: BOOLEAN;
    public
        constructor Create(AFrontEnd: IFrontEndListener; AInterpreter: IInterpreterListener;
            AStorage: TStorage; AError: TErrorRegister);
        destructor Destroy; override;
        
        function __InheritType(AIdCode: Integer; var APatterns: TPatternExprArray; var AReturn: TValueExpr): Word;
        function __MakeValue(AIdCode: Integer; var AValue: TValueExpr): Word;
        procedure Interrupt;
    end;
    
implementation

{ TDefinitionMaker }

constructor TDefinitionMaker.Create(AFrontEnd: IFrontEndListener; AInterpreter: IInterpreterListener;
    AStorage: TStorage; AError: TErrorRegister);
begin
    inherited Create;
    FrontEnd := AFrontEnd;
    Interpreter := AInterpreter;
    Storage := AStorage;
    Error := AError;
    
    FTypeChecker := TTypeChecker.Create(FrontEnd, Interpreter, Storage, Error);
    FStrConverter := TStrConverter.Create(FrontEnd, Interpreter, Storage, Error);
    
    STOP := FALSE;
end;

destructor TDefinitionMaker.Destroy;
begin
    FTypeChecker.Free;
    FStrConverter.Free;
    inherited;
end;

function TDefinitionMaker.DefMakingError(AMsg: TFxString; const AArgs: array of const): Word;
begin
    Result := FX_RES_ERR_SINGLE;
    Error.Code := Result;
    Error.Msg := FormatMessage(AMsg, AArgs);
end;

function TDefinitionMaker.UseNewInternalVariable(AIdCode: Integer): Integer;
var
    InternalName: TFxString;
    InternalIdentifier, L: Integer;
begin
    L := Length(Storage[AIdCode].RestrictedInternalVariables);
    Inc(AvailableInternalVariableCode);
    if (RIVIndex < L) and (AvailableInternalVariableCode < Storage[AIdCode].RestrictedInternalVariables[RIVIndex]) then
        begin end
    else begin
        while (RIVIndex < L) and (AvailableInternalVariableCode >= Storage[AIdCode].RestrictedInternalVariables[RIVIndex]) do begin
            Inc(RIVIndex);
            Inc(AvailableInternalVariableCode);
        end;
    end;
    
    InternalName := InternalVariableName(AvailableInternalVariableCode);
    InternalIdentifier := Storage.FindIdentifier(InternalName);
    if InternalIdentifier < 0 then
        InternalIdentifier := Storage.AddIdentifier(InternalName);
    Result := InternalIdentifier;
    
end;

//---

function TDefinitionMaker.__CheckForSynonymous(var ATypeBranch: TTypeExpr): Word;

LABEL LBL_END;

begin

    Result := FX_RES_SUCCESS;

    IF STOP THEN GOTO LBL_END;

    if ATypeBranch^.tKind = FX_TN_IDENTIFIER then begin
        if Storage[ATypeBranch^.tIdCode].HasTypeSynonymous then begin
            ATypeBranch := Storage[ATypeBranch^.tIdCode].TypeSynonymous;
            Result := __CheckForSynonymous(ATypeBranch);
            IF STOP THEN GOTO LBL_END;
        end
        else
            Result := DefMakingError(UndefinedTypeSynonymousStr, [Storage[ATypeBranch^.tIdCode].Name]);
    end;

LBL_END:

end;

function TDefinitionMaker.__InheritTypeBranch(ATypeBranch: TTypeExpr; var AValueBranch: TValueExpr): Word;

LABEL LBL_END;

var
    K: Integer;
    N: TFxInteger;
    B: Boolean;
    S1, S2: TFxString;
begin

    Result := FX_RES_SUCCESS;

    IF STOP THEN GOTO LBL_END;

    if ATypeBranch^.tKind = FX_TN_IDENTIFIER then begin
        if Storage[ATypeBranch^.tIdCode].HasTypeSynonymous then begin
            ATypeBranch := Storage[ATypeBranch^.tIdCode].TypeSynonymous;
            Result := __InheritTypeBranch(ATypeBranch, AValueBranch);
            IF STOP THEN GOTO LBL_END;
        end
        else
            Result := DefMakingError(UndefinedTypeSynonymousStr, [Storage[ATypeBranch^.tIdCode].Name]);
    end
    else begin
        case AValueBranch^.vKind of
            FX_VN_NONE       :;
            FX_VN_NUMBER     : begin
                if  ((ATypeBranch^.tKind = FX_TN_REAL)) or
                    ((ATypeBranch^.tKind = FX_TN_INTEGER) and ValueIsIntegerNumber(AValueBranch, N)) or
                    ((ATypeBranch^.tKind = FX_TN_NATURAL) and ValueIsNaturalNumber(AValueBranch, N)) or
                    ((ATypeBranch^.tKind = FX_TN_ANONYMOUS)) then begin
                end
                else begin
                    S1 := FStrConverter.__TypeToStr(ATypeBranch);
                    IF STOP THEN GOTO LBL_END;
                    S2 := FStrConverter.__ValueToStr(AValueBranch);
                    IF STOP THEN GOTO LBL_END;
                    Result := DefMakingError(CouldNotInheritTypeOnExpressionStr, [S1, S2]);
                end;
            end;
            FX_VN_BOOLEAN    : begin
                if  (ATypeBranch^.tKind = FX_TN_BOOLEAN) or
                    (ATypeBranch^.tKind = FX_TN_ANONYMOUS)  then begin
                end
                else begin
                    S1 := FStrConverter.__TypeToStr(ATypeBranch);
                    IF STOP THEN GOTO LBL_END;
                    S2 := FStrConverter.__ValueToStr(AValueBranch);
                    IF STOP THEN GOTO LBL_END;
                    Result := DefMakingError(CouldNotInheritTypeOnExpressionStr, [S1, S2]);
                end;
            end;
            FX_VN_CHARACTER  : begin
                if  (ATypeBranch^.tKind = FX_TN_CHARACTER) or
                    (ATypeBranch^.tKind = FX_TN_ANONYMOUS) then begin
                end
                else begin
                    S1 := FStrConverter.__TypeToStr(ATypeBranch);
                    IF STOP THEN GOTO LBL_END;
                    S2 := FStrConverter.__ValueToStr(AValueBranch);
                    IF STOP THEN GOTO LBL_END;
                    Result := DefMakingError(CouldNotInheritTypeOnExpressionStr, [S1, S2]);
                end;
            end;
            FX_VN_NULL       : begin
                if  (ATypeBranch^.tKind = FX_TN_LIST) or
                    (ATypeBranch^.tKind = FX_TN_ANONYMOUS) then begin
                end
                else begin
                    S1 := FStrConverter.__TypeToStr(ATypeBranch);
                    IF STOP THEN GOTO LBL_END;
                    S2 := FStrConverter.__ValueToStr(AValueBranch);
                    IF STOP THEN GOTO LBL_END;
                    Result := DefMakingError(CouldNotInheritTypeOnExpressionStr, [S1, S2]);
                end;
            end;
            FX_VN_FAIL       :;
            FX_VN_IDENTIFIER : begin
                if AValueBranch^.D.tKind = FX_TN_NONE then begin
                    CopyTypeBranchToValueBranch(ATypeBranch, AValueBranch);
                end
                else begin
                    Result := FTypeChecker.__ValueTypeIsSubTypeOf(AValueBranch, ATypeBranch, B);
                    IF STOP THEN GOTO LBL_END;
                    if Result = FX_RES_SUCCESS then begin
                        if B then begin
                        end
                        else begin
                            S1 := FStrConverter.__TypeToStr(ATypeBranch);
                            IF STOP THEN GOTO LBL_END;
                            S2 := FStrConverter.__ValueToStr(AValueBranch);
                            IF STOP THEN GOTO LBL_END;
                            Result := DefMakingError(CouldNotInheritTypeOnExpressionStr, [S1, S2]);
                        end;
                    end;
                end;
            end;
            FX_VN_PRIMITIVE  :;
            FX_VN_ANONYMOUS  :;
            FX_VN_TRY        :;
            FX_VN_TUPLE      : begin
                if (ATypeBranch^.tKind = FX_TN_ANONYMOUS) then begin
                end
                else if (ATypeBranch^.tKind = FX_TN_TUPLE) and (Length(AValueBranch^.Childs) = Length(ATypeBranch^.Childs)) then begin
                    for K := 0 to Length(ATypeBranch^.Childs) - 1 do begin
                        IF STOP THEN GOTO LBL_END;
                        Result := __InheritTypeBranch(ATypeBranch^.Childs[K], AValueBranch^.Childs[K]);
                        IF STOP THEN GOTO LBL_END;
                        if Result <> FX_RES_SUCCESS then
                            Break;
                    end;
                end
                else begin
                    S1 := FStrConverter.__TypeToStr(ATypeBranch);
                    IF STOP THEN GOTO LBL_END;
                    S2 := FStrConverter.__ValueToStr(AValueBranch);
                    IF STOP THEN GOTO LBL_END;
                    Result := DefMakingError(CouldNotInheritTypeOnExpressionStr, [S1, S2]);
                end;
            end;
            FX_VN_LIST_CONS       : begin
                if (ATypeBranch^.tKind = FX_TN_ANONYMOUS) then begin
                end
                else if (ATypeBranch^.tKind = FX_TN_LIST) then begin
                    Result := __InheritTypeBranch(ATypeBranch^.Childs[0], AValueBranch^.Childs[0]);
                    IF STOP THEN GOTO LBL_END;
                    if Result = FX_RES_SUCCESS then begin
                        Result := __InheritTypeBranch(ATypeBranch, AValueBranch^.Childs[1]);
                        IF STOP THEN GOTO LBL_END;
                    end;
                end
                else begin
                    S1 := FStrConverter.__TypeToStr(ATypeBranch);
                    IF STOP THEN GOTO LBL_END;
                    S2 := FStrConverter.__ValueToStr(AValueBranch);
                    IF STOP THEN GOTO LBL_END;
                    Result := DefMakingError(CouldNotInheritTypeOnExpressionStr, [S1, S2]);
                end;
            end;
            FX_VN_LAMBDA     : begin
                if (ATypeBranch^.tKind = FX_TN_ANONYMOUS) then begin
                end
                else if ATypeBranch^.tKind = FX_TN_FUNCTION then begin
                    Result := __InheritTypeBranch(ATypeBranch^.Childs[0], AValueBranch^.Childs[0]);
                    IF STOP THEN GOTO LBL_END;
                    if Result = FX_RES_SUCCESS then begin
                        Result := __InheritTypeBranch(ATypeBranch^.Childs[1], AValueBranch^.Childs[1]);
                        IF STOP THEN GOTO LBL_END;
                    end;
                end
                else begin
                    S1 := FStrConverter.__TypeToStr(ATypeBranch);
                    IF STOP THEN GOTO LBL_END;
                    S2 := FStrConverter.__ValueToStr(AValueBranch);
                    IF STOP THEN GOTO LBL_END;
                    Result := DefMakingError(CouldNotInheritTypeOnExpressionStr, [S1, S2]);
                end;
            end;
            FX_VN_APPLICATION:;
        end;
    end;
    
LBL_END:
    
end;

//---

function TDefinitionMaker.__InheritType(AIdCode: Integer; var APatterns: TPatternExprArray; var AReturn: TValueExpr): Word;

LABEL LBL_END;

var
    M, N, Arity: Integer;
    TailBranch: TTypeExpr;
    S1, S2: TFxString;
    
begin
    
    Result := FX_RES_SUCCESS;
    TailBranch := nil;
    
    IF STOP THEN GOTO LBL_END;
    
    Arity := Storage[AIdCode].DefinitionArity;
    if Arity < 0 then
        Arity := Length(APatterns);
    
    if Arity = Length(APatterns) then begin
        if Storage[AIdCode].HasInheritableType then begin
            TailBranch := Storage[AIdCode].InheritableType;
            for M := 0 to Arity - 1 do begin
                IF STOP THEN GOTO LBL_END;
                Result := __CheckForSynonymous(TailBranch);
                IF STOP THEN GOTO LBL_END;
                if Result = FX_RES_SUCCESS then begin
                    if TailBranch^.tKind = FX_TN_FUNCTION then begin
                        Result := __InheritTypeBranch(TailBranch^.Childs[0], APatterns[M]);
                        IF STOP THEN GOTO LBL_END;
                        if Result = FX_RES_SUCCESS then
                            TailBranch := TailBranch^.Childs[1];
                    end
                    else begin
                        S1 := FStrConverter.__TypeToStr(TailBranch);
                        IF STOP THEN GOTO LBL_END;
                        Result := DefMakingError(CouldNotInheritTypeOnPatternStr, [S1]);
                    end;
                end;
                if Result <> FX_RES_SUCCESS then Break;
            end;
            if Result = FX_RES_SUCCESS then begin
                Result := __InheritTypeBranch(TailBranch, AReturn);
                IF STOP THEN GOTO LBL_END;
            end;
        end;
    end
    else
        Result := DefMakingError(DifferentAritiesForStr, [Storage[AIdCode].Name]);
    
LBL_END:
    
    TailBranch := nil;

end;

function TDefinitionMaker.__MakeValue(AIdCode: Integer; var AValue: TValueExpr): Word;

LABEL LBL_END;

var
    M, N, Arity: Integer;
    AuxBranch, TailBranch, TailPatternBranch, PrevTailPatternBranch: TValueExpr;
    NewIds: TIntArray;

begin

    AvailableInternalVariableCode := 0;
    RIVIndex := 0;

    Result := FX_RES_SUCCESS;
    AuxBranch := nil;
    TailBranch := nil;
    TailPatternBranch := nil;

    AValue := nil;

    IF STOP THEN GOTO LBL_END;

    Arity := Storage[AIdCode].DefinitionArity;

    if (Arity >= 0) and Storage[AIdCode].HasAnyDefinition then begin
        if (Arity = 0) and (Length(Storage[AIdCode].Definitions) = 1) then begin
            // copia fiel solo en este caso
            CopyValueBranch(Storage[AIdCode].Definitions[0].Return, AValue);
        end
        else begin
            // se agregan variables internas
            System.New(AValue);
            TailBranch := AValue;

            SetLength(NewIds, Arity);
            for M := 0 to Arity - 1 do
                NewIds[M] := UseNewInternalVariable(AIdCode);

            for M := 0 to Arity - 1 do begin
                IF STOP THEN GOTO LBL_END;
                TailBranch^.vKind := FX_VN_LAMBDA;
                AddValueBranchChilds(TailBranch, 2);

                MakeIdentifierValueBranch(NewIds[M], TailBranch^.Childs[0]);
                MakeNoneValueBranch(TailBranch^.Childs[1]); // para inicializar
                TailBranch := TailBranch^.Childs[1];
            end;
            
            for N := 0 to Length(Storage[AIdCode].Definitions) - 1 do begin
                IF STOP THEN GOTO LBL_END;
                TailBranch^.vKind := FX_VN_TRY;
                AddValueBranchChilds(TailBranch, 2);
                
                System.New(TailBranch^.Childs[0]);
                TailPatternBranch := TailBranch^.Childs[0];
                for M := Arity - 1 downto 0 do begin
                    IF STOP THEN GOTO LBL_END;
                    TailPatternBranch^.vKind := FX_VN_APPLICATION;
                    AddValueBranchChilds(TailPatternBranch, 2);

                    MakeIdentifierValueBranch(NewIds[M], TailPatternBranch^.Childs[1]);
                    MakeNoneValueBranch(TailPatternBranch^.Childs[0]);
                    TailPatternBranch := TailPatternBranch^.Childs[0];
                end;
                
                for M := 0 to Arity - 1 do begin
                    IF STOP THEN GOTO LBL_END;
                    TailPatternBranch^.vKind := FX_VN_LAMBDA;
                    AddValueBranchChilds(TailPatternBranch, 2);
                    
                    CopyValueBranch(Storage[AIdCode].Definitions[N].Patterns[M], TailPatternBranch^.Childs[0]);
                    MakeNoneValueBranch(TailPatternBranch^.Childs[1]);
                    TailPatternBranch := TailPatternBranch^.Childs[1];
                end;
                
                CopyValueBranchTo(Storage[AIdCode].Definitions[N].Return, TailPatternBranch);
                TailPatternBranch := nil;
                MakeNoneValueBranch(TailBranch^.Childs[1]);
                TailBranch := TailBranch^.Childs[1];
                
            end;
            
            TailBranch^.vKind := FX_VN_FAIL;
            TailBranch^.Childs := nil;
            // si ningun patron encaja debe devolver fail, pues si 
            //lanzara un error seria imposible programar una 
            //funcion que devuelva explicitamente fail,
            //por lo que tampoco seria programable las guardas ni //el Case
            //ejm:
            //  F 0 := 1
            //  F y := fail
            //
            //  Evaluado en 2
            //
            
            TailBranch := nil;
            
        end;
    end
    else
        Result := DefMakingError(ValueUndefinedStr, [Storage[AIdCode].Name]);
    
LBL_END:
    
    EraseValueBranch(AuxBranch);
    EraseValueBranch(TailBranch);
    EraseValueBranch(TailPatternBranch);
    
end;

procedure TDefinitionMaker.Interrupt;
begin
    STOP := TRUE;
    FTypeChecker.Interrupt;
    FStrConverter.Interrupt;
end;

end.
