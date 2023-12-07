unit fxStorage;

interface

uses
    fxUtils, fxBasicStructure;
    
type
    
    TValueDefinition = record
        Patterns: TPatternExprArray;
        Return: TValueExpr;
    end;
    
    TIdentifier = class
    public
        Name: TFxString;
        TypeSynonymous: TTypeExpr;
        Notation: TNotation;
        InheritableType: TTypeExpr;
        RestrictedInternalVariables: TRestrictedVariables;
        Definitions: array of TValueDefinition;
        Value: TValueExpr;
        constructor Create(AName: TFxString);
        destructor Destroy; override;
        procedure Clear;
        
        procedure AddRestrictedVariables(ACode: Integer);
        procedure NewTypeSynonymous(var AType: TTypeExpr); // mueve la informacion
        procedure NewNotation(ANotation: TNotation); overload;
        procedure NewNotation(APriority: TNotationPriority; APosition: TNotationPosition); overload;
        procedure NewInheritableType(var AType: TTypeExpr); // mueve la informacion
        procedure NewDefinition(var ADefinition: TValueDefinition; var ARestrictedInternalVars: TRestrictedVariables); overload; // mueve la informacion
        procedure NewDefinition(var APatterns: TPatternExprArray; var AReturn: TValueExpr; var ARestrictedInternalVars: TRestrictedVariables); overload; // mueve la informacion
        procedure NewValue(var AValue: TValueExpr); // mueve la informacion
        
        function HasTypeSynonymous: Boolean;
        function HasInheritableType: Boolean;
        function HasAnyDefinition: Boolean;
        function HasValue: Boolean;
        
        function DefinitionArity: Integer;
        function CopyValue(var ABranch: TValueExpr): Boolean;
        function CopySynonymous(var ABranch: TTypeExpr): Boolean;
        function CopySynonymousAsValue(var ABranch: TValueExpr): Boolean;
        function CopySynonymousToValue(var ABranch: TValueExpr): Boolean;
    end;
    
    TStorage = class
    private
        FIdentifiers: array of TIdentifier;
        FCount: Integer;
        function GetIdentifier(IdCode: Integer): TIdentifier;
        procedure SetIdentifier(IdCode: Integer; AValue: TIdentifier);
        procedure EnsureRoom;
    public
        Answer: TValueExpr;
        constructor Create;
        destructor Destroy; override;
        procedure Clear;
        
        function HasAnswer: Boolean;
        procedure StoreAnswer(var AValue: TValueExpr); // mueve la informacion
        
        function FindIdentifier(AName: TFxString): Integer;
        function AddIdentifier(AName: TFxString): Integer;
        property Identifiers[IdCode: Integer]: TIdentifier read GetIdentifier; default;
        property Count: Integer read FCount;
    end;
    
procedure ReleaseValueDefinition(var V: TValueDefinition);
procedure EmptyValueDefinition(var V: TValueDefinition);
procedure CopyValueDefinition(VSource: TValueDefinition; var VDest: TValueDefinition);

implementation

procedure ReleaseValueDefinition(var V: TValueDefinition);
var
    K: Integer;
begin
    for K := 0 to Length(V.Patterns) - 1 do
        EraseValueBranch(V.Patterns[K]);
    EraseValueBranch(V.Return);
end;

procedure EmptyValueDefinition(var V: TValueDefinition);  
begin
    V.Patterns := nil;
    V.Return := nil;
end;

procedure CopyValueDefinition(VSource: TValueDefinition; var VDest: TValueDefinition);
var
    K: Integer;
begin
    SetLength(VDest.Patterns, Length(VSource.Patterns));
    for K := 0 to Length(VSource.Patterns) - 1 do
        CopyValueBranch(VSource.Patterns[K], VDest.Patterns[K]);
    CopyValueBranch(VSource.Return, VDest.Return);
end;

{ TIdentifier }

constructor TIdentifier.Create(AName: TFxString);
begin
    inherited Create;
    Name := AName;
    TypeSynonymous := nil;
    Notation.Position := npPrefix;
    Notation.Priority := High(TNotationPriority);
    InheritableType := nil;
    Definitions := nil;
    Value := nil;
end;

destructor TIdentifier.Destroy;
begin
    Clear;
    inherited;
end;

procedure TIdentifier.Clear;
var
    K: Integer;
begin
    EraseTypeBranch(TypeSynonymous);
    EraseTypeBranch(InheritableType);
    for K := 0 to Length(Definitions) - 1 do
        ReleaseValueDefinition(Definitions[K]);
    EraseValueBranch(Value);
    
    TypeSynonymous := nil;
    Notation.Position := npPrefix;
    Notation.Priority := High(TNotationPriority);
    InheritableType := nil;
    Definitions := nil;
    Value := nil;
end;

procedure TIdentifier.NewTypeSynonymous(var AType: TTypeExpr);                                             
begin
    EraseTypeBranch(TypeSynonymous);
    TypeSynonymous := AType;
    AType := nil;
end;

procedure TIdentifier.NewNotation(ANotation: TNotation);                                                   
begin
    Notation := ANotation;
end;

procedure TIdentifier.NewNotation(APriority: TNotationPriority; APosition: TNotationPosition);
begin
    Notation.Position := APosition;
    Notation.Priority := APriority;
end;

procedure TIdentifier.NewInheritableType(var AType: TTypeExpr);                                            
begin
    EraseTypeBranch(InheritableType);
    InheritableType := AType;
    AType := nil;
end;

procedure TIdentifier.AddRestrictedVariables(ACode: Integer);
var
    K, L: Integer;
    RIVNew: TRestrictedVariables;
begin
    L := Length(RestrictedInternalVariables);
    for K := 0 to L - 1 do
        if RestrictedInternalVariables[K] = ACode then Exit;
    SetLength(RIVNew, L + 1);
    K := 0;
    while (K < L) and (RestrictedInternalVariables[K] < ACode) do begin
        RIVNew[K] := RestrictedInternalVariables[K];
        Inc(K);
    end;
    RIVNew[K] := ACode;
    while (K < L) do begin
        RIVNew[K + 1] := RestrictedInternalVariables[K];
        Inc(K);
    end;
    RestrictedInternalVariables := RIVNew;
end;

procedure TIdentifier.NewDefinition(var ADefinition: TValueDefinition; var ARestrictedInternalVars: TRestrictedVariables);
var
    K, J: Integer;
begin
    K := Length(Definitions);
    SetLength(Definitions, K + 1);
    Definitions[K] := ADefinition;
    for J := 0 to Length(ARestrictedInternalVars) - 1 do
        AddRestrictedVariables(ARestrictedInternalVars[J]);
    ADefinition.Patterns := nil;
    ADefinition.Return := nil;
    ARestrictedInternalVars := nil;
end;

procedure TIdentifier.NewDefinition(var APatterns: TPatternExprArray; var AReturn: TValueExpr; var ARestrictedInternalVars: TRestrictedVariables);
var
    D: TValueDefinition;
begin
    D.Patterns := APatterns;
    D.Return := AReturn;
    APatterns := nil;
    AReturn := nil;
    NewDefinition(D, ARestrictedInternalVars);
end;

procedure TIdentifier.NewValue(var AValue: TValueExpr);
begin
    EraseValueBranch(Value);
    Value := AValue;
    AValue := nil;
end;

function TIdentifier.HasTypeSynonymous: Boolean; 
begin
    Result := TypeSynonymous <> nil;
end;

function TIdentifier.HasInheritableType: Boolean;
begin
    Result := InheritableType <> nil;
end;

function TIdentifier.HasAnyDefinition: Boolean;  
begin
    Result := Definitions <> nil;
end;

function TIdentifier.HasValue: Boolean;          
begin
    Result := Value <> nil;
end;

function TIdentifier.DefinitionArity: Integer;                                
begin
    if HasAnyDefinition then
        Result := Length(Definitions[0].Patterns)
    else
        Result := -1;
end;

function TIdentifier.CopyValue(var ABranch: TValueExpr): Boolean;             
begin
    Result := HasValue;
    if Result then
        CopyValueBranch(Value, ABranch)
end;

function TIdentifier.CopySynonymous(var ABranch: TTypeExpr): Boolean;         
begin
    Result := HasTypeSynonymous;
    if Result then
        CopyTypeBranch(TypeSynonymous, ABranch);
end;

function TIdentifier.CopySynonymousAsValue(var ABranch: TValueExpr): Boolean; 
begin
    Result := HasTypeSynonymous;
    if Result then
        fxBasicStructure.CopyTypeBranchAsValueBranch(TypeSynonymous, ABranch);
end;

function TIdentifier.CopySynonymousToValue(var ABranch: TValueExpr): Boolean; 
begin
    Result := HasTypeSynonymous;
    if Result then
        CopyTypeBranchToValueBranch(TypeSynonymous, ABranch);
end;

{ TStorage }

constructor TStorage.Create;
begin
    inherited Create;
    FIdentifiers := nil;
    FCount := 0;
end;

destructor TStorage.Destroy;
begin
    Clear;
    inherited;
end;

function TStorage.GetIdentifier(IdCode: Integer): TIdentifier;
begin
    if (IdCode >= 0) and (IdCode < FCount) then
        Result := FIdentifiers[IdCode]
    else
        Result := nil;
end;

procedure TStorage.SetIdentifier(IdCode: Integer; AValue: TIdentifier);
begin
    if (IdCode >= 0) and (IdCode < FCount) then
        FIdentifiers[IdCode] := AValue;
end;

procedure TStorage.EnsureRoom;
begin
    if FCount >= Length(FIdentifiers) then begin
        SetLength(FIdentifiers, FCount + 32);
    end;
end;

procedure TStorage.Clear;
var
    K: Integer;
begin
    for K := 0 to FCount - 1 do
        FIdentifiers[K].Free;
    FIdentifiers := nil;
    EraseValueBranch(Answer);
    Answer := nil;
    FCount := 0;
end;

function TStorage.HasAnswer: Boolean;
begin
    Result := Answer <> nil;
end;

procedure TStorage.StoreAnswer(var AValue: TValueExpr);
begin
    EraseValueBranch(Answer);
    Answer := AValue;
    AValue := nil;
end;

function TStorage.FindIdentifier(AName: TFxString): Integer;
var
    FirstPos, LastPos: Integer;
begin
    // busqueda binaria(los identificadores mas usados se encuentran al inicio o al final)
    Result := -1;
    FirstPos := 0;
    LastPos := FCount - 1;
    while FirstPos <= LastPos do begin
        if FIdentifiers[FirstPos].Name = AName then begin
            Result := FirstPos;
            Break;
        end
        else if FIdentifiers[LastPos].Name = AName then begin
            Result := LastPos;
            Break;
        end;
        Inc(FirstPos);
        Dec(LastPos);
    end;
end;

function TStorage.AddIdentifier(AName: TFxString): Integer;
begin
    EnsureRoom;
    Result := FCount;
    FIdentifiers[Result] := TIdentifier.Create(AName);
    Inc(FCount);
end;

end.
