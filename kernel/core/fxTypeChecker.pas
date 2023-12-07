unit fxTypeChecker;

interface

uses
    fxUtils, fxStrUtils, fxStorage, fxError, fxBasicStructure, fxInterpreterUtils, fxPrimFuncUtils;

type
    
    TTypeChecker = class
    private
        FrontEnd: IFrontEndListener;
        Interpreter: IInterpreterListener;
        Storage: TStorage;
        Error: TErrorRegister;
        
        function CheckingError(AMsg: TFxString; const AArgs: array of const): Word;
    protected
        STOP: BOOLEAN;
    public
        constructor Create(AFrontEnd: IFrontEndListener; AInterpreter: IInterpreterListener;
            AStorage: TStorage; AError: TErrorRegister);
        destructor Destroy; override;

        function __CheckForRecursivity(AIdCode: Integer; ATypeBranch: TTypeExpr): Word;
        function __ValueMatchsType(ATypeBranch: TTypeExpr; AValueBranch: TValueExpr; var AMatches: Boolean): Word;
        function __ValueMatchsValueType(AValueTypeBranch, AValueBranch: TValueExpr; var AMatches: Boolean): Word;
        function __TypeIsSubTypeOf(ATypeBranchSub, ATypeBranchSup: TTypeExpr; var Res: Boolean): Word;
        function __ValueTypeIsSubTypeOf(AValueTypeBranchSub: TValueExpr; ATypeBranchSup: TTypeExpr; var Res: Boolean): Word;
        procedure Interrupt;
    end;

implementation

{ TTypeChecker }

constructor TTypeChecker.Create(AFrontEnd: IFrontEndListener; AInterpreter: IInterpreterListener;
    AStorage: TStorage; AError: TErrorRegister);
begin
    inherited Create;
    FrontEnd := AFrontEnd;
    Interpreter := AInterpreter;
    Storage := AStorage;
    Error := AError;
    
    STOP := FALSE;
end;

destructor TTypeChecker.Destroy;
begin
    inherited;
end;

function TTypeChecker.CheckingError(AMsg: TFxString; const AArgs: array of const): Word;
begin
    Result := FX_RES_ERR_SINGLE;
    Error.Code := Result;
    Error.Msg := FormatMessage(AMsg, AArgs);
end;

//--

function TTypeChecker.__CheckForRecursivity(AIdCode: Integer; ATypeBranch: TTypeExpr): Word;

LABEL LBL_END;

var
    K: Integer;

begin
    // revisar en la definicion de sinonimos es suficiente
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END;
    
    if ATypeBranch^.tKind = FX_TN_IDENTIFIER then begin
        if AIdCode = ATypeBranch^.tIdCode then
            Result := CheckingError(RecursiveTypeStr, [Storage[AIdCode].Name])
        else if Storage[ATypeBranch^.tIdCode].HasTypeSynonymous then begin
            ATypeBranch := Storage[ATypeBranch^.tIdCode].TypeSynonymous;
            Result := __CheckForRecursivity(AIdCode, ATypeBranch);
            IF STOP THEN GOTO LBL_END;
        end
        else
            Result := CheckingError(UndefinedTypeSynonymousStr, [Storage[ATypeBranch^.tIdCode].Name]);
    end
    else begin
        for K := 0 to Length(ATypeBranch^.Childs) - 1 do begin
            IF STOP THEN GOTO LBL_END;
            Result := __CheckForRecursivity(AIdCode, ATypeBranch^.Childs[K]);
            IF STOP THEN GOTO LBL_END;
            if Result <> FX_RES_SUCCESS then
                Break;
        end;
    end;
    
LBL_END:
    
end;

function TTypeChecker.__ValueMatchsType(ATypeBranch: TTypeExpr; AValueBranch: TValueExpr; var AMatches: Boolean): Word;

LABEL LBL_END;

var
    K: Integer;
    R: TFxReal;
    I: TFxInteger;
    
begin
    
    Result := FX_RES_SUCCESS;
    AMatches := False;
    
    IF STOP THEN GOTO LBL_END;
    
    case ATypeBranch^.tKind of
        FX_TN_NONE      : begin
            AMatches := True; // siempre encaja
        end;
        FX_TN_REAL      : begin
            if ValueIsRealNumber(AValueBranch, R) then
                AMatches := True;
        end;
        FX_TN_INTEGER   : begin
            if ValueIsIntegerNumber(AValueBranch, I) then
                AMatches := True;
        end;
        FX_TN_NATURAL   : begin
            if ValueIsNaturalNumber(AValueBranch, I) then
                AMatches := True;
        end;
        FX_TN_BOOLEAN   : begin
            if AValueBranch^.vKind = FX_VN_BOOLEAN then
                AMatches := True;
        end;
        FX_TN_CHARACTER : begin
            if AValueBranch^.vKind = FX_VN_CHARACTER then
                AMatches := True;
        end;
        FX_TN_IDENTIFIER: begin
            if Storage[ATypeBranch^.tIdCode].HasTypeSynonymous then begin
                ATypeBranch := Storage[ATypeBranch^.tIdCode].TypeSynonymous;
                Result := __ValueMatchsType(ATypeBranch, AValueBranch, AMatches);
                IF STOP THEN GOTO LBL_END;
            end
            else
                Result := CheckingError(UndefinedTypeSynonymousStr, [Storage[ATypeBranch^.tIdCode].Name]);
        end;
        FX_TN_ANONYMOUS : begin
            AMatches := True; // siempre encaja
        end;
        FX_TN_TUPLE     : begin
            if (AValueBranch^.vKind = FX_VN_TUPLE) and (Length(AValueBranch^.Childs) = Length(ATypeBranch^.Childs)) then begin
                AMatches := True;
                for K := 0 to Length(AValueBranch^.Childs) - 1 do begin
                    IF STOP THEN GOTO LBL_END;
                    Result := __ValueMatchsType(ATypeBranch^.Childs[K], AValueBranch^.Childs[K], AMatches);
                    IF STOP THEN GOTO LBL_END;
                    if (Result <> FX_RES_SUCCESS) or (not AMatches) then
                        Break;
                end;
            end;
        end;
        FX_TN_LIST      : begin
            if AValueBranch^.vKind = FX_VN_NULL then
                AMatches := True // siempre encaja
            else if AValueBranch^.vKind = FX_VN_LIST_CONS then begin
                AMatches := True;
                Result := __ValueMatchsType(ATypeBranch^.Childs[0], AValueBranch^.Childs[0], AMatches);
                IF STOP THEN GOTO LBL_END;
                if Result = FX_RES_SUCCESS then begin
                    if AMatches then begin
                        // averiguar si la cola sigue encajando
                        Result := __ValueMatchsType(ATypeBranch, AValueBranch^.Childs[1], AMatches);
                        IF STOP THEN GOTO LBL_END;
                    end;
                end;
            end;
        end;
        FX_TN_FUNCTION  : begin
            // Encaja siempre con build-in y lambda por razones:
            //      (\ (s :: (Nat, Nat) -> Nat) -> s (3,4))(+); + :: _ -> _
            //      (Sin + Cos)(2 + 3*I) 
            // Para futuras versiones hacer esto mas robusto y seguro
            if (AValueBranch^.vKind = FX_VN_PRIMITIVE) or (AValueBranch^.vKind = FX_VN_LAMBDA) then begin
                AMatches := True; // encaja
            end;
        end;
    end;
    
LBL_END:
    
end;

function TTypeChecker.__ValueMatchsValueType(AValueTypeBranch, AValueBranch: TValueExpr; var AMatches: Boolean): Word;

LABEL LBL_END;

var
    K: Integer;
    R: TFxReal;
    I: TFxInteger;
    AuxTypeBranch: TTypeExpr;
    
begin
    
    Result := FX_RES_SUCCESS;
    AMatches := False;
    AuxTypeBranch := nil;
    
    IF STOP THEN GOTO LBL_END;
    
    case AValueTypeBranch^.D.tKind of
        FX_TN_NONE      : begin
            AMatches := True; // siempre encaja
        end;
        FX_TN_REAL      : begin
            if ValueIsRealNumber(AValueBranch, R) then
                AMatches := True;
        end;
        FX_TN_INTEGER   : begin
            if ValueIsIntegerNumber(AValueBranch, I) then
                AMatches := True;
        end;
        FX_TN_NATURAL   : begin
            if ValueIsNaturalNumber(AValueBranch, I) then
                AMatches := True;
        end;
        FX_TN_BOOLEAN   : begin
            if AValueBranch^.vKind = FX_VN_BOOLEAN then
                AMatches := True;
        end;
        FX_TN_CHARACTER : begin
            if AValueBranch^.vKind = FX_VN_CHARACTER then
                AMatches := True;
        end;
        FX_TN_IDENTIFIER: begin
            if Storage[AValueTypeBranch^.D.tIdCode].HasTypeSynonymous then begin
                AuxTypeBranch := Storage[AValueTypeBranch^.D.tIdCode].TypeSynonymous;
                Result := __ValueMatchsType(AuxTypeBranch, AValueBranch, AMatches);
                IF STOP THEN GOTO LBL_END;
            end
            else
                Result := CheckingError(UndefinedTypeSynonymousStr, [Storage[AValueTypeBranch^.D.tIdCode].Name]);
        end;
        FX_TN_ANONYMOUS : begin
            AMatches := True; // siempre encaja
        end;
        FX_TN_TUPLE     : begin
            if (AValueBranch^.vKind = FX_VN_TUPLE) and (Length(AValueBranch^.Childs) = Length(AValueTypeBranch^.Childs)) then begin
                AMatches := True;
                for K := 0 to Length(AValueBranch^.Childs) - 1 do begin
                    IF STOP THEN GOTO LBL_END;
                    Result := __ValueMatchsValueType(AValueTypeBranch^.Childs[K], AValueBranch^.Childs[K], AMatches);
                    IF STOP THEN GOTO LBL_END;
                    if (Result <> FX_RES_SUCCESS) or (not AMatches) then
                        Break;
                end;
            end;
        end;
        FX_TN_LIST      : begin
            if AValueBranch^.vKind = FX_VN_NULL then
                AMatches := True // siempre encaja
            else if AValueBranch^.vKind = FX_VN_LIST_CONS then begin
                AMatches := True;
                Result := __ValueMatchsValueType(AValueTypeBranch^.Childs[0], AValueBranch^.Childs[0], AMatches);
                IF STOP THEN GOTO LBL_END;
                if Result = FX_RES_SUCCESS then begin
                    if AMatches then begin
                        // averiguar si la cola sigue encajando
                        Result := __ValueMatchsValueType(AValueTypeBranch, AValueBranch^.Childs[1], AMatches);
                        IF STOP THEN GOTO LBL_END;
                    end;
                end;
            end;
        end;
        FX_TN_FUNCTION  : begin
            // Encaja siempre con build-in y lambda por razones:
            //      (\ (s :: (Nat, Nat) -> Nat) -> s (3,4))(+); + :: _ -> _
            //      (Sin + Cos)(2 + 3*I) 
            // Para futuras versiones hacer esto mas robusto y seguro
            if (AValueBranch^.vKind = FX_VN_PRIMITIVE) or (AValueBranch^.vKind = FX_VN_LAMBDA) then begin
                AMatches := True; // encaja
            end;
        end;
    end;
    
LBL_END:
    
    AuxTypeBranch := nil; // para evitar borrar ramas guardadas en "Storage"
    
end;

function TTypeChecker.__TypeIsSubTypeOf(ATypeBranchSub, ATypeBranchSup: TTypeExpr; var Res: Boolean): Word;

LABEL LBL_END;

var
    K: Integer;
    
begin
    
    Result := FX_RES_SUCCESS;
    Res := True;
    
    IF STOP THEN GOTO LBL_END;
    
    if ATypeBranchSub^.tKind = FX_TN_IDENTIFIER then begin
        if Storage[ATypeBranchSub^.tIdCode].HasTypeSynonymous then begin
            ATypeBranchSub := Storage[ATypeBranchSub^.tIdCode].TypeSynonymous;
            Result := __TypeIsSubTypeOf(ATypeBranchSub, ATypeBranchSup, Res);
            IF STOP THEN GOTO LBL_END;
        end
        else
            Result := CheckingError(UndefinedTypeSynonymousStr, [Storage[ATypeBranchSub^.tIdCode].Name]);
    end
    else begin
        case ATypeBranchSup^.tKind of
            FX_TN_NONE:;
            FX_TN_REAL: begin
                if  (ATypeBranchSub^.tKind = FX_TN_REAL) or
                    (ATypeBranchSub^.tKind = FX_TN_INTEGER) or
                    (ATypeBranchSub^.tKind = FX_TN_NATURAL) then begin
                end
                else
                    Res := False;
            end;
            FX_TN_INTEGER   : begin
                if  (ATypeBranchSub^.tKind = FX_TN_INTEGER) or
                    (ATypeBranchSub^.tKind = FX_TN_NATURAL) then begin
                end
                else
                    Res := False;
            end;
            FX_TN_NATURAL   : begin
                if  (ATypeBranchSub^.tKind = FX_TN_NATURAL) then begin
                end
                else
                    Res := False;
            end;
            FX_TN_BOOLEAN   : begin
                if  (ATypeBranchSub^.tKind = FX_TN_BOOLEAN) then begin
                end
                else
                    Res := False;
            end;
            FX_TN_CHARACTER : begin
                if  (ATypeBranchSub^.tKind = FX_TN_CHARACTER) then begin
                end
                else
                    Res := False;
            end;
            FX_TN_IDENTIFIER: begin
                if Storage[ATypeBranchSup^.tIdCode].HasTypeSynonymous then begin
                    ATypeBranchSup := Storage[ATypeBranchSup^.tIdCode].TypeSynonymous;
                    Result := __TypeIsSubTypeOf(ATypeBranchSub, ATypeBranchSup, Res);
                    IF STOP THEN GOTO LBL_END;
                end
                else
                    Result := CheckingError(UndefinedTypeSynonymousStr, [Storage[ATypeBranchSup^.tIdCode].Name]);
            end;
            FX_TN_ANONYMOUS : begin
                if  (ATypeBranchSub^.tKind <> FX_TN_NONE) then begin
                end
                else
                    Res := False;
            end;
            FX_TN_TUPLE     : begin
                if (ATypeBranchSub^.tKind = FX_TN_TUPLE) and (Length(ATypeBranchSup^.Childs) = Length(ATypeBranchSub^.Childs)) then begin
                    for K := 0 to Length(ATypeBranchSub^.Childs) - 1 do begin
                        Result := __TypeIsSubTypeOf(ATypeBranchSub^.Childs[K], ATypeBranchSup^.Childs[K], Res);
                        IF STOP THEN GOTO LBL_END;
                        if (Result <> FX_RES_SUCCESS) or (not Res) then
                            Break;
                    end;
                end
                else
                    Res := False;
            end;
            FX_TN_LIST      : begin
                if (ATypeBranchSub^.tKind = FX_TN_LIST) then begin
                    Result := __TypeIsSubTypeOf(ATypeBranchSub^.Childs[0], ATypeBranchSup^.Childs[0], Res);
                    IF STOP THEN GOTO LBL_END;
                end
                else
                    Res := False;
            end;
            FX_TN_FUNCTION  : begin
                if (ATypeBranchSub^.tKind = FX_TN_FUNCTION) then begin
                    Result := __TypeIsSubTypeOf(ATypeBranchSub^.Childs[0], ATypeBranchSup^.Childs[0], Res);
                    IF STOP THEN GOTO LBL_END;
                    if (Result = FX_RES_SUCCESS) and Res then begin
                        Result := __TypeIsSubTypeOf(ATypeBranchSub^.Childs[1], ATypeBranchSup^.Childs[1], Res);
                        IF STOP THEN GOTO LBL_END;
                    end;
                end
                else
                    Res := False;
            end;
        end;
    end;
    
LBL_END:
    
end;

function TTypeChecker.__ValueTypeIsSubTypeOf(AValueTypeBranchSub: TValueExpr; ATypeBranchSup: TTypeExpr; var Res: Boolean): Word;

LABEL LBL_END;

var
    K: Integer;
    
    AuxTypeBranchSub: TTypeExpr;

begin
    
    Result := FX_RES_SUCCESS;
    Res := True;
    AuxTypeBranchSub := nil;
    
    IF STOP THEN GOTO LBL_END;
    
    if AValueTypeBranchSub^.D.tKind = FX_TN_IDENTIFIER then begin
        if Storage[AValueTypeBranchSub^.D.tIdCode].HasTypeSynonymous then begin
            AuxTypeBranchSub := Storage[AValueTypeBranchSub^.D.tIdCode].TypeSynonymous;
            Result := __TypeIsSubTypeOf(AuxTypeBranchSub, ATypeBranchSup, Res);
            IF STOP THEN GOTO LBL_END;
            AuxTypeBranchSub := nil;
        end
        else
            Result := CheckingError(UndefinedTypeSynonymousStr, [Storage[AValueTypeBranchSub^.D.tIdCode].Name]);
    end
    else begin
        case ATypeBranchSup^.tKind of
            FX_TN_NONE:;
            FX_TN_REAL: begin
                if  (AValueTypeBranchSub^.D.tKind = FX_TN_REAL) or
                    (AValueTypeBranchSub^.D.tKind = FX_TN_INTEGER) or
                    (AValueTypeBranchSub^.D.tKind = FX_TN_NATURAL) then begin
                end
                else
                    Res := False;
            end;
            FX_TN_INTEGER   : begin
                if  (AValueTypeBranchSub^.D.tKind = FX_TN_INTEGER) or
                    (AValueTypeBranchSub^.D.tKind = FX_TN_NATURAL) then begin
                end
                else
                    Res := False;
            end;
            FX_TN_NATURAL   : begin
                if  (AValueTypeBranchSub^.D.tKind = FX_TN_NATURAL) then begin
                end
                else
                    Res := False;
            end;
            FX_TN_BOOLEAN   : begin
                if  (AValueTypeBranchSub^.D.tKind = FX_TN_BOOLEAN) then begin
                end
                else
                    Res := False;
            end;
            FX_TN_CHARACTER : begin
                if  (AValueTypeBranchSub^.D.tKind = FX_TN_CHARACTER) then begin
                end
                else
                    Res := False;
            end;
            FX_TN_IDENTIFIER: begin
                if Storage[ATypeBranchSup^.tIdCode].HasTypeSynonymous then begin
                    ATypeBranchSup := Storage[ATypeBranchSup^.tIdCode].TypeSynonymous;
                    Result := __ValueTypeIsSubTypeOf(AValueTypeBranchSub, ATypeBranchSup, Res);
                    IF STOP THEN GOTO LBL_END;
                end
                else
                    Result := CheckingError(UndefinedTypeSynonymousStr, [Storage[ATypeBranchSup^.tIdCode].Name]);
            end;
            FX_TN_ANONYMOUS : begin
                if  (AValueTypeBranchSub^.D.tKind <> FX_TN_NONE) then begin
                end
                else
                    Res := False;
            end;
            FX_TN_TUPLE     : begin
                if (AValueTypeBranchSub^.D.tKind = FX_TN_TUPLE) and (Length(ATypeBranchSup^.Childs) = Length(AValueTypeBranchSub^.Childs)) then begin
                    for K := 0 to Length(AValueTypeBranchSub^.Childs) - 1 do begin
                        Result := __ValueTypeIsSubTypeOf(AValueTypeBranchSub^.Childs[K], ATypeBranchSup^.Childs[K], Res);
                        IF STOP THEN GOTO LBL_END;
                        if (Result <> FX_RES_SUCCESS) or (not Res) then
                            Break;
                    end;
                end
                else
                    Res := False;
            end;
            FX_TN_LIST      : begin
                if (AValueTypeBranchSub^.D.tKind = FX_TN_LIST) then begin
                    Result := __ValueTypeIsSubTypeOf(AValueTypeBranchSub^.Childs[0], ATypeBranchSup^.Childs[0], Res);
                    IF STOP THEN GOTO LBL_END;
                end
                else
                    Res := False;
            end;
            FX_TN_FUNCTION  : begin
                if (AValueTypeBranchSub^.D.tKind = FX_TN_FUNCTION) then begin
                    Result := __ValueTypeIsSubTypeOf(AValueTypeBranchSub^.Childs[0], ATypeBranchSup^.Childs[0], Res);
                    IF STOP THEN GOTO LBL_END;
                    if (Result = FX_RES_SUCCESS) and Res then begin
                        Result := __ValueTypeIsSubTypeOf(AValueTypeBranchSub^.Childs[1], ATypeBranchSup^.Childs[1], Res);
                        IF STOP THEN GOTO LBL_END;
                    end;
                end
                else
                    Res := False;
            end;
        end;
    end;
    
LBL_END:
    
    AuxTypeBranchSub := nil; // para evitar borrar ramas guardadas en "Storage"
    
end;

//--

procedure TTypeChecker.Interrupt;
begin
    STOP := TRUE;
end;

end.
