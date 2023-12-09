unit fxTranslator;

interface

uses
    fxUtils, fxMath, fxStorage, fxError, fxStrUtils, fxBasicStructure, fxInterpreterUtils, fxASTUtils,
    fxPrimFuncUtils, fxCommandUtils;

type
    
    TTranslator = class
    private
        FrontEnd: IFrontEndListener;
        Interpreter: IInterpreterListener;
        Storage: TStorage;
        Error: TErrorRegister;
        
        RestrictedInternalVariables: TRestrictedVariables;
        AvailableInternalVariableCode: Integer;
        RIVIndex: Integer;
        function TranslationError(AMsg: TFxString; const AArgs: array of const): Word;
        function UseNewInternalVariable: Integer;
        function GetRequiredDefinitionIdCode(AName: TFxString): Integer;
        
        function __BranchIdentifiers(var ABranch, ATuple: TAbstractSyntaxTree): Word;
        function __PatternsFromAppPatternAST(var ABranch: TAbstractSyntaxTree; var AIdCode: Integer; var APatterns: TPatternExprArray): Word;
        function __ValueTypeExprFromValueAST(var ABranch: TAbstractSyntaxTree; var AValueBranch: TValueExpr): Word;
        function __ValueExprFromValueAST(var ABranch: TAbstractSyntaxTree; var AValueBranch: TValueExpr): Word;
        function __TypeExprFromTypeAST(var ABranch: TAbstractSyntaxTree; var ATypeBranch: TTypeExpr): Word;
        function __BasicValueASTBranch(var ABranch: TAbstractSyntaxTree): Word;
        function __BasicTypeASTBranch(var ABranch: TAbstractSyntaxTree): Word;
        
        function __TranslateDefinitionPatterns(var ABranch: TAbstractSyntaxTree; var AIdCode: Integer; var APatterns: TPatternExprArray): Word;
        function __TranslateToValueExpr(var ABranch: TAbstractSyntaxTree; var AValue: TValueExpr): Word;
        function __TranslateToTypeExpr(var ABranch: TAbstractSyntaxTree; var AType: TTypeExpr): Word;
        
        function __TranslateCommand(var ABranch: TAbstractSyntaxTree; var ACommand: TCommand): Word;
    protected
        STOP: BOOLEAN;
        SLEEP: BOOLEAN;
    public
        constructor Create(AFrontEnd: IFrontEndListener; AInterpreter: IInterpreterListener;
            AStorage: TStorage; AError: TErrorRegister);
        destructor Destroy; override;
        
        function __Translate(var ATree: TAbstractSyntaxTree; var ARestrictedInternalVars: TRestrictedVariables; var ACommand: TCommand): Word;
        procedure Interrupt;  
        procedure Pause;
        procedure Resume;
    end;
    
implementation

{ TTranslator }

constructor TTranslator.Create(AFrontEnd: IFrontEndListener; AInterpreter: IInterpreterListener;
    AStorage: TStorage; AError: TErrorRegister);
begin
    inherited Create;
    FrontEnd := AFrontEnd;
    Interpreter := AInterpreter;
    Storage := AStorage;
    Error := AError;
    
    STOP := FALSE;
end;

destructor TTranslator.Destroy;
begin
    inherited;
end;

function TTranslator.TranslationError(AMsg: TFxString; const AArgs: array of const): Word;
begin
    Result := FX_RES_ERR_SINGLE;
    Error.Code := Result;
    Error.Msg := FormatMessage(AMsg, AArgs);
end;

function TTranslator.UseNewInternalVariable: Integer;
var
    InternalName: TFxString;
    InternalIdentifier, L: Integer;
begin
    L := Length(RestrictedInternalVariables);
    Inc(AvailableInternalVariableCode);
    if (RIVIndex < L) and (AvailableInternalVariableCode < RestrictedInternalVariables[RIVIndex]) then
        begin end
    else begin
        while (RIVIndex < L) and (AvailableInternalVariableCode >= RestrictedInternalVariables[RIVIndex]) do begin
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

function TTranslator.GetRequiredDefinitionIdCode(AName: TFxString): Integer;
begin
    Result := Storage.FindIdentifier(AName);
end;

//----

function TTranslator.__BranchIdentifiers(var ABranch, ATuple: TAbstractSyntaxTree): Word;

LABEL LBL_END;

var
    PosIds: TBoolArray;


    procedure __CheckBranchIdentifiers_(ACurrentBranch: TAbstractSyntaxTree);

    LABEL LBL_END_;

    var
        K_: Integer;

    begin

        IF STOP THEN GOTO LBL_END_;

        if ACurrentBranch <> nil then begin
            if ACurrentBranch^.Kind = FX_ASTN_IDENTIFIER then begin
                PosIds[ACurrentBranch^.D.IdCode] := True;
            end
            else if ACurrentBranch^.Kind = FX_ASTN_TYPING then
                __CheckBranchIdentifiers_(ACurrentBranch^.Childs[0])
            else
                for K_ := 0 to Length(ACurrentBranch^.Childs) - 1 do begin
                    IF STOP THEN GOTO LBL_END_;
                    __CheckBranchIdentifiers_(ACurrentBranch^.Childs[K_]);
                    IF STOP THEN GOTO LBL_END_;
                end;
        end;

    LBL_END_:

    end;

var
    I, K: Integer;

begin

    ATuple := nil;
    Result := FX_RES_SUCCESS;

    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;

    SetLength(PosIds, Storage.Count);
    FillChar(PosIds[0], Storage.Count*SizeOf(Boolean), 0); // rellenar con valor falso

    __CheckBranchIdentifiers_(ABranch);
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    K := 0;
    MakeHeadASTBranch(FX_ASTN_TUPLE, ATuple);
    
    for I := 0 to Storage.Count - 1 do begin
        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
        if PosIds[I] then begin
            AddASTBranchChilds(ATuple);
            MakeIdentifierASTBranch(I, -1, ATuple^.Childs[K]);
            Inc(K);
        end;
    end;
    
LBL_END:
    
end;

function TTranslator.__PatternsFromAppPatternAST(var ABranch: TAbstractSyntaxTree; var AIdCode: Integer; var APatterns: TPatternExprArray): Word;
    
LABEL LBL_END;
    
var
    L, K: Integer;
    Sek: Byte;
    AuxBranch, TailBranch: TAbstractSyntaxTree;
    Stack: TAbstractSyntaxTreeStack;
    
begin
    
    AIdCode := 0;
    APatterns := nil;
    AuxBranch := nil;
    TailBranch := nil;
    Stack := TAbstractSyntaxTreeStack.Create;
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    TailBranch := ABranch;
    L := 0;
    while TailBranch^.Kind = FX_ASTN_APPLICATION do begin
        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
        Stack.Push(TailBranch^.Childs[1], 0);
        TailBranch := TailBranch^.Childs[0];
        Inc(L);
    end;
    
    if TailBranch^.Kind = FX_ASTN_IDENTIFIER then begin
        if TailBranch^.D.IdCode >= 0 then begin
            AIdCode := TailBranch^.D.IdCode;
            SetLength(APatterns, L);
            for K := 0 to L - 1 do
                APatterns[K] := nil;
            for K := 0 to L - 1 do begin
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                Stack.Pop(AuxBranch, Sek);
                Result := __ValueExprFromValueAST(AuxBranch, APatterns[K]);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                if Result <> FX_RES_SUCCESS then Break;
            end;
        end
        else
            Result := TranslationError(CanNotDefineNegativeIdentifiersStr, []);
    end
    else if TailBranch^.Kind = FX_ASTN_PRIMITIVE then
        Result := TranslationError(CanNotDefinePrimitiveFunctionsStr, [])
    else
        Result := TranslationError(ExpectedIdentifierForDefinitionStr, []);
    
    TailBranch := nil;
    
LBL_END:
    
    EraseASTBranch(AuxBranch);
    EraseASTBranch(TailBranch);
    Stack.Free;
    
    //--
    EraseASTBranch(ABranch);
    //--
    
end;

function TTranslator.__ValueTypeExprFromValueAST(var ABranch: TAbstractSyntaxTree; var AValueBranch: TValueExpr): Word;
    
LABEL LBL_END;
    
var
    K: Integer;
begin
    
    AValueBranch := nil;
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    case ABranch^.Kind of
        FX_ASTN_NONE     : begin
            MakeHeadValueTypeBranch(FX_TN_NONE, AValueBranch);
        end;
        FX_ASTN_TYPE_REAL     : begin
            MakeHeadValueTypeBranch(FX_TN_REAL, AValueBranch);
        end;
        FX_ASTN_TYPE_INT  : begin
            MakeHeadValueTypeBranch(FX_TN_INTEGER, AValueBranch);
        end;
        FX_ASTN_TYPE_NAT  : begin
            MakeHeadValueTypeBranch(FX_TN_NATURAL, AValueBranch);
        end;
        FX_ASTN_TYPE_CHAR: begin
            MakeHeadValueTypeBranch(FX_TN_CHARACTER, AValueBranch);
        end;
        FX_ASTN_TYPE_BOOL  : begin
            MakeHeadValueTypeBranch(FX_TN_BOOLEAN, AValueBranch);
        end;
        FX_ASTN_IDENTIFIER : begin
            MakeIdentifierValueTypeBranch(ABranch^.D.IdCode, AValueBranch);
        end;
        FX_ASTN_ANONYMOUS: begin
            MakeHeadValueTypeBranch(FX_TN_ANONYMOUS, AValueBranch);
        end;
        FX_ASTN_FUNCTION : begin
            MakeHeadValueTypeBranch(FX_TN_FUNCTION, AValueBranch);
            AddValueBranchChilds(AValueBranch, 2);
            Result := __ValueTypeExprFromValueAST(ABranch^.Childs[0], AValueBranch^.Childs[0]);
            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            if Result = FX_RES_SUCCESS then begin
                Result := __ValueTypeExprFromValueAST(ABranch^.Childs[1], AValueBranch^.Childs[1]);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            end;
        end;
        FX_ASTN_TUPLE    : begin
            MakeHeadValueTypeBranch(FX_TN_TUPLE, AValueBranch);
            AddValueBranchChilds(AValueBranch, Length(ABranch^.Childs));
            for K := 0 to Length(ABranch^.Childs) - 1 do begin
                Result := __ValueTypeExprFromValueAST(ABranch^.Childs[K], AValueBranch^.Childs[K]);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                if Result <> FX_RES_SUCCESS then Break;
            end;
        end;
        FX_ASTN_LIST     : begin
            MakeHeadValueTypeBranch(FX_TN_LIST, AValueBranch);
            AddValueBranchChilds(AValueBranch, 1);
            Result := __ValueTypeExprFromValueAST(ABranch^.Childs[0], AValueBranch^.Childs[0]);
            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
        end;
    end;
    
LBL_END:
    
end;

function TTranslator.__ValueExprFromValueAST(var ABranch: TAbstractSyntaxTree; var AValueBranch: TValueExpr): Word;
    
LABEL LBL_END;
    
var
    K: Integer;
begin
    
    AValueBranch := nil;
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    case ABranch^.Kind of
        FX_ASTN_NONE       : begin  
            MakeNoneValueBranch(AValueBranch);
        end;
        FX_ASTN_NUMBER       : begin
            MakeNumberValueBranch(ABranch^.D.nValue, AValueBranch);
        end;
        FX_ASTN_CHARACTER  : begin
            MakeCharValueBranch(ABranch^.D.cValue, AValueBranch);
        end;
        FX_ASTN_BOOLEAN    : begin
            MakeBoolValueBranch(ABranch^.D.bValue, AValueBranch);
        end;
        FX_ASTN_FAIL       : begin
            MakeFailValueBranch(AValueBranch);
        end;
        FX_ASTN_STRING   : begin // mucho mejor
            MakeStrValueBranch(ABranch^.D.sValue^, AValueBranch);
        end;
        FX_ASTN_IDENTIFIER   : begin
            MakeIdentifierValueBranch(ABranch^.D.IdCode, AValueBranch);
        end;
        FX_ASTN_ANONYMOUS  : begin
            MakeHeadValueBranch(FX_VN_ANONYMOUS, AValueBranch);
        end;
        FX_ASTN_TUPLE      : begin
            MakeHeadValueBranch(FX_VN_TUPLE, AValueBranch);
            AddValueBranchChilds(AValueBranch, Length(ABranch^.Childs));
            for K := 0 to Length(ABranch^.Childs) - 1 do begin
                Result := __ValueExprFromValueAST(ABranch^.Childs[K], AValueBranch^.Childs[K]);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                if Result <> FX_RES_SUCCESS then Break;
            end;
        end;
        FX_ASTN_NULL_LIST  : begin
            MakeHeadValueBranch(FX_VN_NULL, AValueBranch);
        end;
        FX_ASTN_LIST_CONSTRUCTOR: begin
            MakeHeadValueBranch(FX_VN_LIST_CONS, AValueBranch);
            AddValueBranchChilds(AValueBranch, 2);
            Result := __ValueExprFromValueAST(ABranch^.Childs[0], AValueBranch^.Childs[0]);
            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            if Result = FX_RES_SUCCESS then begin
                __ValueExprFromValueAST(ABranch^.Childs[1], AValueBranch^.Childs[1]);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            end;
        end;
        FX_ASTN_LAMBDA     : begin
            MakeHeadValueBranch(FX_VN_LAMBDA, AValueBranch);
            AddValueBranchChilds(AValueBranch, 2);
            __ValueExprFromValueAST(ABranch^.Childs[0], AValueBranch^.Childs[0]);
            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            if Result = FX_RES_SUCCESS then begin
                __ValueExprFromValueAST(ABranch^.Childs[1], AValueBranch^.Childs[1]);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            end;
        end;
        FX_ASTN_TRY        : begin
            MakeHeadValueBranch(FX_VN_TRY, AValueBranch);
            AddValueBranchChilds(AValueBranch, 2);
            __ValueExprFromValueAST(ABranch^.Childs[0], AValueBranch^.Childs[0]);
            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            if Result = FX_RES_SUCCESS then begin
                __ValueExprFromValueAST(ABranch^.Childs[1], AValueBranch^.Childs[1]);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            end;
        end;
        FX_ASTN_APPLICATION: begin
            MakeHeadValueBranch(FX_VN_APPLICATION, AValueBranch);
            AddValueBranchChilds(AValueBranch, 2);
            __ValueExprFromValueAST(ABranch^.Childs[0], AValueBranch^.Childs[0]);
            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            if Result = FX_RES_SUCCESS then begin
                __ValueExprFromValueAST(ABranch^.Childs[1], AValueBranch^.Childs[1]);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            end;
        end;
        FX_ASTN_PRIMITIVE   : begin
            MakePrimValueBranch(ABranch^.D.IdCode, AValueBranch);
        end;
        FX_ASTN_TYPING     : begin
            __ValueTypeExprFromValueAST(ABranch^.Childs[1], AValueBranch);
            if AValueBranch = nil then
                MakeIdentifierValueBranch(ABranch^.Childs[0]^.D.IdCode, AValueBranch)
            else begin
                AValueBranch^.vKind := FX_VN_IDENTIFIER;
                AValueBranch^.D.vIdCode := ABranch^.Childs[0]^.D.IdCode;
            end;
        end;
    end;
    
LBL_END:
    
end;

function TTranslator.__TypeExprFromTypeAST(var ABranch: TAbstractSyntaxTree; var ATypeBranch: TTypeExpr): Word;
    
LABEL LBL_END;
    
var
    K: Integer;
begin
    
    ATypeBranch := nil;
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    case ABranch^.Kind of
        FX_ASTN_NONE     : begin
            MakeHeadTypeBranch(FX_TN_NONE, ATypeBranch);
        end;
        FX_ASTN_TYPE_REAL     : begin
            MakeHeadTypeBranch(FX_TN_REAL, ATypeBranch);
        end;
        FX_ASTN_TYPE_INT  : begin
            MakeHeadTypeBranch(FX_TN_INTEGER, ATypeBranch);
        end;
        FX_ASTN_TYPE_NAT  : begin
            MakeHeadTypeBranch(FX_TN_NATURAL, ATypeBranch);
        end;
        FX_ASTN_TYPE_CHAR: begin
            MakeHeadTypeBranch(FX_TN_CHARACTER, ATypeBranch);
        end;
        FX_ASTN_TYPE_BOOL  : begin
            MakeHeadTypeBranch(FX_TN_BOOLEAN, ATypeBranch);
        end;
        FX_ASTN_IDENTIFIER : begin
            MakeIdentifierTypeBranch(ABranch^.D.IdCode, ATypeBranch);
        end;
        FX_ASTN_ANONYMOUS: begin
            MakeHeadTypeBranch(FX_TN_ANONYMOUS, ATypeBranch);
        end;
        FX_ASTN_FUNCTION : begin
            MakeHeadTypeBranch(FX_TN_FUNCTION, ATypeBranch);
            AddTypeBranchChilds(ATypeBranch, 2);
            Result := __TypeExprFromTypeAST(ABranch^.Childs[0], ATypeBranch^.Childs[0]);
            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            if Result = FX_RES_SUCCESS then begin
                Result := __TypeExprFromTypeAST(ABranch^.Childs[1], ATypeBranch^.Childs[1]);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            end;
        end;
        FX_ASTN_TUPLE    : begin
            MakeHeadTypeBranch(FX_TN_TUPLE, ATypeBranch);
            AddTypeBranchChilds(ATypeBranch, Length(ABranch^.Childs));
            for K := 0 to Length(ABranch^.Childs) - 1 do begin
                Result := __TypeExprFromTypeAST(ABranch^.Childs[K], ATypeBranch^.Childs[K]);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                if Result <> FX_RES_SUCCESS then Break;
            end;
        end;
        FX_ASTN_LIST     : begin
            MakeHeadTypeBranch(FX_TN_LIST, ATypeBranch);
            AddTypeBranchChilds(ATypeBranch, 1);
            Result := __TypeExprFromTypeAST(ABranch^.Childs[0], ATypeBranch^.Childs[0]);
            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
        end;
    end;
    
LBL_END:
    
end;

function TTranslator.__BasicValueASTBranch(var ABranch: TAbstractSyntaxTree): Word;
    
LABEL LBL_END;
    
var
    K, RDIdCode, L, LL, NI: Integer;
    AuxBranch, TailBranch: TAbstractSyntaxTree;
    AuxBranchList: TAbstractSyntaxTreeArray;
    NewListBranch, NewLambdaBranch: TAbstractSyntaxTree;
    NewImpBranch, NewStatementBranch, NewAssignmentBranch: TAbstractSyntaxTree;
    NewBranchCond, NewBranchThen, NewBranchElse,
    NewBranchNext, NewBranchLoop, NewBranchIdTuple: TAbstractSyntaxTree;
    
begin
    
    AuxBranch := nil;
    TailBranch := nil;
    AuxBranchList := nil;
    
    NewListBranch := nil;
    NewLambdaBranch := nil;
    
    NewImpBranch := nil;
    NewStatementBranch := nil;
    NewAssignmentBranch := nil;
    NewBranchCond := nil;
    NewBranchThen := nil;
    NewBranchElse := nil;
    NewBranchNext := nil;
    NewBranchLoop := nil;
    NewBranchIdTuple := nil;
    
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    case ABranch^.Kind of
        FX_ASTN_NONE:;
        FX_ASTN_NUMBER:;
        FX_ASTN_BOOLEAN:;
        FX_ASTN_CHARACTER:;
        FX_ASTN_STRING:; // se transforma en el copiado
        FX_ASTN_ANONYMOUS:;
        FX_ASTN_NULL_LIST:;
        FX_ASTN_FAIL:;
        FX_ASTN_IDENTIFIER:;
        FX_ASTN_PRIMITIVE:;
        FX_ASTN_LET: begin
            MakeHeadASTBranch(FX_ASTN_APPLICATION, AuxBranch);
            AddASTBranchChilds(AuxBranch, 2);
            MakeHeadASTBranch(FX_ASTN_LAMBDA, AuxBranch^.Childs[0]);
            AddASTBranchChilds(AuxBranch^.Childs[0], 2);
            AuxBranch^.Childs[0]^.Childs[0] := ABranch^.Childs[0]^.Childs[0];
            ABranch^.Childs[0]^.Childs[0] := nil;
            AuxBranch^.Childs[0]^.Childs[1] := ABranch^.Childs[1];
            ABranch^.Childs[1] := nil;
            AuxBranch^.Childs[1] := ABranch^.Childs[0]^.Childs[1];
            ABranch^.Childs[0]^.Childs[1] := nil;
            EraseASTBranch(ABranch);
            ABranch := AuxBranch;
            AuxBranch := nil;
            Result := __BasicValueASTBranch(ABranch);
            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
        end;
        FX_ASTN_WHERE: begin
            MakeHeadASTBranch(FX_ASTN_LET, AuxBranch);
            AddASTBranchChilds(AuxBranch, 2);
            AuxBranch^.Childs[0] := ABranch^.Childs[1];
            ABranch^.Childs[1] := nil;
            AuxBranch^.Childs[1] := ABranch^.Childs[0];
            ABranch^.Childs[0] := nil;
            EraseASTBranch(ABranch);
            ABranch := AuxBranch;
            AuxBranch := nil;
            Result := __BasicValueASTBranch(ABranch);
            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
        end;
        FX_ASTN_TUPLE: begin
            for K := 0 to Length(ABranch^.Childs) - 1 do begin
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                Result := __BasicValueASTBranch(ABranch^.Childs[K]);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                if Result <> FX_RES_SUCCESS then
                    Break;
            end;
            // MAKE
            // quitar tuplas unarias
            if (Result = FX_RES_SUCCESS) and (Length(ABranch^.Childs) = 1) then begin
                AuxBranch := ABranch^.Childs[0];
                ABranch^.Childs[0] := nil;
                EraseASTBranch(ABranch);
                ABranch := AuxBranch;
                AuxBranch := nil;
            end;
        end;
        FX_ASTN_LIST: begin
            for K := 0 to Length(ABranch^.Childs) - 1 do begin
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                Result := __BasicValueASTBranch(ABranch^.Childs[K]);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                if Result <> FX_RES_SUCCESS then
                    Break;
            end;
            // MAKE
            AuxBranchList := ABranch^.Childs;
            ABranch^.Childs := nil;
            TailBranch := ABranch;
            for K := 0 to Length(AuxBranchList) - 1 do begin
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                TailBranch^.Kind := FX_ASTN_LIST_CONSTRUCTOR;
                SetLength(TailBranch^.Childs, 2);
                TailBranch^.Childs[0] := AuxBranchList[K];
                System.New(TailBranch^.Childs[1]);
                TailBranch := TailBranch^.Childs[1];
            end;
            TailBranch^.Kind := FX_ASTN_NULL_LIST;
            TailBranch^.Childs := nil;
            AuxBranchList := nil;
            TailBranch := nil;
        end;
        FX_ASTN_APPLICATION: begin
            Result := __BasicValueASTBranch(ABranch^.Childs[0]);
            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            if Result = FX_RES_SUCCESS then begin
                Result := __BasicValueASTBranch(ABranch^.Childs[1]);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            end;
        end;
        FX_ASTN_INDEX: begin
            RDIdCode := GetRequiredDefinitionIdCode(FX_RD_GETELM_STR);
            if RDIdCode >= 0 then begin
                MakeHeadASTBranch(FX_ASTN_APPLICATION, AuxBranch);
                AddASTBranchChilds(AuxBranch, 2);
                MakeHeadASTBranch(FX_ASTN_APPLICATION, AuxBranch^.Childs[0]);
                AddASTBranchChilds(AuxBranch^.Childs[0], 2);

                MakeIdentifierASTBranch(RDIdCode, -1, AuxBranch^.Childs[0]^.Childs[0]);

                AuxBranch^.Childs[0]^.Childs[1] := ABranch^.Childs[1];
                ABranch^.Childs[1] := nil;
                AuxBranch^.Childs[0]^.Childs[1]^.Kind := FX_ASTN_LIST;

                AuxBranch^.Childs[1] := ABranch^.Childs[0];
                ABranch^.Childs[0] := nil;

                EraseASTBranch(ABranch);
                ABranch := AuxBranch;
                AuxBranch := nil;
                Result := __BasicValueASTBranch(ABranch);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            end
            else
                Result := TranslationError(RequiredDefinitionForStr, [FX_RD_GETELM_STR, IndexStructureStr]);
        end;
        FX_ASTN_LAMBDA: begin
            // convertir las subramas en basicas
            for K := 0 to Length(ABranch^.Childs) - 1 do begin
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                Result := __BasicValueASTBranch(ABranch^.Childs[K]);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                if Result <> FX_RES_SUCCESS then
                    Break;
            end;
            // MAKE
            if Result = FX_RES_SUCCESS then begin // expresion lambda de multiples patrones
                L := Length(ABranch^.Childs);
                K := 0;
                MakeHeadASTBranch(FX_ASTN_LAMBDA, AuxBranch);
                TailBranch := AuxBranch;
                while K < L - 1 do begin
                    AddASTBranchChilds(TailBranch, 2);
                    TailBranch^.Childs[0] := ABranch^.Childs[K];
                    ABranch^.Childs[K] := nil;
                    Inc(K);
                    if K = L - 1 then Break;
                    MakeHeadASTBranch(FX_ASTN_LAMBDA, TailBranch^.Childs[1]);
                    TailBranch := TailBranch^.Childs[1];
                end;
                TailBranch^.Childs[1] := ABranch^.Childs[K];
                ABranch^.Childs[K] := nil;
                EraseASTBranch(ABranch);
                ABranch := AuxBranch;
                AuxBranch := nil;
                TailBranch := nil;
            end;
        end;
        FX_ASTN_TRY: begin
            Result := __BasicValueASTBranch(ABranch^.Childs[0]);
            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            if Result = FX_RES_SUCCESS then begin
                Result := __BasicValueASTBranch(ABranch^.Childs[1]);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            end;
        end;
        FX_ASTN_GUARD: begin
            Result := __BasicValueASTBranch(ABranch^.Childs[0]);
            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            if Result = FX_RES_SUCCESS then begin
                Result := __BasicValueASTBranch(ABranch^.Childs[1]);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                if Result = FX_RES_SUCCESS then begin
                    RDIdCode := GetRequiredDefinitionIdCode(FX_RD_IFTHENELSE_STR);
                    if RDIdCode >= 0 then begin
                        MakeHeadASTBranch(FX_ASTN_APPLICATION, AuxBranch);
                        AddASTBranchChilds(AuxBranch, 2);
                        MakeHeadASTBranch(FX_ASTN_APPLICATION, AuxBranch^.Childs[0]);
                        AddASTBranchChilds(AuxBranch^.Childs[0], 2);
                        
                        MakeIdentifierASTBranch(RDIdCode, -1, AuxBranch^.Childs[0]^.Childs[0]);
                        
                        MakeHeadASTBranch(FX_ASTN_TUPLE, AuxBranch^.Childs[0]^.Childs[1]);
                        AddASTBranchChilds(AuxBranch^.Childs[0]^.Childs[1], 3);
                        
                        AuxBranch^.Childs[0]^.Childs[1]^.Childs[0] := ABranch^.Childs[0];
                        ABranch^.Childs[0] := nil;
                        
                        MakeHeadASTBranch(FX_ASTN_LAMBDA, NewLambdaBranch);
                        AddASTBranchChilds(NewLambdaBranch, 2);
                        MakeHeadASTBranch(FX_ASTN_ANONYMOUS, NewLambdaBranch^.Childs[0]);
                        NewLambdaBranch^.Childs[1] := ABranch^.Childs[1];
                        ABranch^.Childs[1] := nil;
                        AuxBranch^.Childs[0]^.Childs[1]^.Childs[1] := NewLambdaBranch;
                        NewLambdaBranch := nil;
                        
                        MakeHeadASTBranch(FX_ASTN_LAMBDA, NewLambdaBranch);
                        AddASTBranchChilds(NewLambdaBranch, 2);
                        MakeHeadASTBranch(FX_ASTN_ANONYMOUS, NewLambdaBranch^.Childs[0]);
                        MakeFailASTBranch(NewLambdaBranch^.Childs[1]);
                        AuxBranch^.Childs[0]^.Childs[1]^.Childs[2] := NewLambdaBranch;
                        NewLambdaBranch := nil;
                        
                        MakeTrivialASTBranch(AuxBranch^.Childs[1]);
                        
                        EraseASTBranch(ABranch);
                        ABranch := AuxBranch;
                        AuxBranch := nil;
                        
                    end
                    else
                        Result := TranslationError(RequiredDefinitionForStr, [FX_RD_IFTHENELSE_STR, GuardExpressionStr]);
                end;
            end;
        end;
        FX_ASTN_LIST_COMPREHENSION: begin
            if Length(ABranch^.Childs) = 1 then begin
                { without qualifiers }
                MakeHeadASTBranch(FX_ASTN_LIST_CONSTRUCTOR, AuxBranch);
                AddASTBranchChilds(AuxBranch, 2);
                AuxBranch^.Childs[0] := ABranch^.Childs[0];
                ABranch^.Childs[0] := nil;
                MakeHeadASTBranch(FX_ASTN_NULL_LIST, AuxBranch^.Childs[1]);
                
                EraseASTBranch(ABranch);
                ABranch := AuxBranch;
                AuxBranch := nil;
                Result := __BasicValueASTBranch(ABranch);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            end
            else if ABranch^.Childs[1]^.Kind = FX_ASTN_LIST_GENERATOR then begin
                { first qualifier is generator }
                RDIdCode := GetRequiredDefinitionIdCode(FX_RD_FLATMAP_STR);
                if RDIdCode >= 0 then begin
                    MakeHeadASTBranch(FX_ASTN_LIST_COMPREHENSION, NewListBranch);
                    AddASTBranchChilds(NewListBranch, Length(ABranch^.Childs) - 1);
                    NewListBranch^.Childs[0] := ABranch^.Childs[0];
                    ABranch^.Childs[0] := nil;
                    for K := 2 to Length(ABranch^.Childs) - 1 do begin
                        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                        NewListBranch^.Childs[K - 1] := ABranch^.Childs[K];
                        ABranch^.Childs[K] := nil;
                    end;
                    
                    MakeHeadASTBranch(FX_ASTN_LAMBDA, NewLambdaBranch);
                    AddASTBranchChilds(NewLambdaBranch, 2);
                    NewLambdaBranch^.Childs[0] := ABranch^.Childs[1]^.Childs[0];
                    ABranch^.Childs[1]^.Childs[0] := nil;
                    NewLambdaBranch^.Childs[1] := NewListBranch;
                    NewListBranch := nil;
                    
                    
                    MakeHeadASTBranch(FX_ASTN_APPLICATION, AuxBranch);
                    AddASTBranchChilds(AuxBranch, 2);
                    MakeHeadASTBranch(FX_ASTN_APPLICATION, AuxBranch^.Childs[0]);
                    AddASTBranchChilds(AuxBranch^.Childs[0], 2);
                    
                    MakeIdentifierASTBranch(RDIdCode, -1, AuxBranch^.Childs[0]^.Childs[0]);
                    AuxBranch^.Childs[0]^.Childs[1] := NewLambdaBranch;
                    NewLambdaBranch := nil;
                    AuxBranch^.Childs[1] := ABranch^.Childs[1]^.Childs[1];
                    ABranch^.Childs[1]^.Childs[1] := nil;
                    
                    
                    EraseASTBranch(ABranch);
                    ABranch := AuxBranch;
                    AuxBranch := nil;
                    Result := __BasicValueASTBranch(ABranch);
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                end
                else
                    Result := TranslationError(RequiredDefinitionForStr, [FX_RD_FLATMAP_STR, ListComprehensionGeneratorStr]);
            end
            else begin
                {first qualifier is filter }
                RDIdCode := GetRequiredDefinitionIdCode(FX_RD_IFFALSE_STR);
                if RDIdCode >= 0 then begin
                    MakeHeadASTBranch(FX_ASTN_LIST_COMPREHENSION, NewListBranch);
                    AddASTBranchChilds(NewListBranch, Length(ABranch^.Childs) - 1);
                    NewListBranch^.Childs[0] := ABranch^.Childs[0];
                    ABranch^.Childs[0] := nil;
                    for K := 2 to Length(ABranch^.Childs) - 1 do begin
                        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                        NewListBranch^.Childs[K - 1] := ABranch^.Childs[K];
                        ABranch^.Childs[K] := nil;
                    end;
                    
                    MakeHeadASTBranch(FX_ASTN_TRY, AuxBranch);
                    AddASTBranchChilds(AuxBranch, 2);
                    MakeHeadASTBranch(FX_ASTN_APPLICATION, AuxBranch^.Childs[0]);
                    AddASTBranchChilds(AuxBranch^.Childs[0], 2);
                    MakeHeadASTBranch(FX_ASTN_APPLICATION, AuxBranch^.Childs[0]^.Childs[0]);
                    AddASTBranchChilds(AuxBranch^.Childs[0]^.Childs[0], 2);
                    
                    MakeIdentifierASTBranch(RDIdCode, -1, AuxBranch^.Childs[0]^.Childs[0]^.Childs[0]);
                    AuxBranch^.Childs[0]^.Childs[0]^.Childs[1] := ABranch^.Childs[1];
                    ABranch^.Childs[1] := nil;
                    MakeHeadASTBranch(FX_ASTN_NULL_LIST, AuxBranch^.Childs[0]^.Childs[1]);
                    AuxBranch^.Childs[1] := NewListBranch;
                    NewListBranch := nil;
                    
                    EraseASTBranch(ABranch);
                    ABranch := AuxBranch;
                    AuxBranch := nil;
                    Result := __BasicValueASTBranch(ABranch);
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                end
                else
                    Result := TranslationError(RequiredDefinitionForStr, [FX_RD_IFFALSE_STR, ListComprehensionFilterStr]);
            end;
        end;
        FX_ASTN_LIST_CONSTRUCTOR: begin
            Result := __BasicValueASTBranch(ABranch^.Childs[0]);
            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            if Result = FX_RES_SUCCESS then begin
                Result := __BasicValueASTBranch(ABranch^.Childs[1]);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            end;
        end;
        FX_ASTN_LIST_SECUENCE: begin
            if Length(ABranch^.Childs) = 2 then begin
                { secuence 1-1 }
                RDIdCode := GetRequiredDefinitionIdCode(FX_RD_LISTFROMTO_STR);
                if RDIdCode >= 0 then begin
                    MakeHeadASTBranch(FX_ASTN_APPLICATION, AuxBranch);
                    AddASTBranchChilds(AuxBranch, 2);
                    MakeHeadASTBranch(FX_ASTN_APPLICATION, AuxBranch^.Childs[0]);
                    AddASTBranchChilds(AuxBranch^.Childs[0], 2);
                    
                    MakeIdentifierASTBranch(RDIdCode, -1, AuxBranch^.Childs[0]^.Childs[0]);
                    AuxBranch^.Childs[0]^.Childs[1] := ABranch^.Childs[0];
                    ABranch^.Childs[0] := nil;
                    AuxBranch^.Childs[1] := ABranch^.Childs[1];
                    ABranch^.Childs[1] := nil;
                    
                    EraseASTBranch(ABranch);
                    ABranch := AuxBranch;
                    AuxBranch := nil;
                    Result := __BasicValueASTBranch(ABranch);
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                end
                else
                    Result := TranslationError(RequiredDefinitionForStr, [FX_RD_LISTFROMTO_STR, SequenceListStr]);
            end
            else begin
                { secuence step }
                RDIdCode := GetRequiredDefinitionIdCode(FX_RD_LISTFROMTHENTO_STR);
                if RDIdCode >= 0 then begin
                    MakeHeadASTBranch(FX_ASTN_APPLICATION, AuxBranch);
                    AddASTBranchChilds(AuxBranch, 2);
                    MakeHeadASTBranch(FX_ASTN_APPLICATION, AuxBranch^.Childs[0]);
                    AddASTBranchChilds(AuxBranch^.Childs[0], 2);
                    MakeHeadASTBranch(FX_ASTN_APPLICATION, AuxBranch^.Childs[0]^.Childs[0]);
                    AddASTBranchChilds(AuxBranch^.Childs[0]^.Childs[0], 2);
                    
                    MakeIdentifierASTBranch(RDIdCode, -1, AuxBranch^.Childs[0]^.Childs[0]^.Childs[0]);
                    AuxBranch^.Childs[0]^.Childs[0]^.Childs[1] := ABranch^.Childs[0];
                    ABranch^.Childs[0] := nil;
                    AuxBranch^.Childs[0]^.Childs[1] := ABranch^.Childs[1];
                    ABranch^.Childs[1] := nil;
                    AuxBranch^.Childs[1] := ABranch^.Childs[2];
                    ABranch^.Childs[2] := nil;
                    
                    EraseASTBranch(ABranch);
                    ABranch := AuxBranch;
                    AuxBranch := nil;
                    Result := __BasicValueASTBranch(ABranch);
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                end
                else
                    Result := TranslationError(RequiredDefinitionForStr, [FX_RD_LISTFROMTHENTO_STR, SequenceStepListStr]);
            end;
        end;
        FX_ASTN_TYPING: begin
            Result := __BasicValueASTBranch(ABranch^.Childs[0]);
            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            if Result = FX_RES_SUCCESS then begin
                Result := __BasicTypeASTBranch(ABranch^.Childs[1]);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            end;
            // MAKE: se fusiona en el copiado
        end;
        FX_ASTN_IMPERATIVE: begin
            if ABranch^.Childs = nil then begin
                ABranch^.Kind := FX_ASTN_TUPLE; // hacer una tupla trivial
            end
            else begin
                LL := Length(ABranch^.Childs) - 1;
                case ABranch^.Childs[0]^.Kind of
                    FX_ASTN_RETURN: begin
                        AuxBranch := ABranch^.Childs[0]^.Childs[0];
                        ABranch^.Childs[0]^.Childs[0] := nil;
                        
                        EraseASTBranch(ABranch);
                        ABranch := AuxBranch;
                        AuxBranch := nil;
                        Result := __BasicValueASTBranch(ABranch);
                        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    end;
                    FX_ASTN_ASSIGNMENT: begin
                        MakeHeadASTBranch(FX_ASTN_IMPERATIVE, NewImpBranch);
                        AddASTBranchChilds(NewImpBranch, Length(ABranch^.Childs) - 1);
                        for K := 1 to Length(ABranch^.Childs) - 1 do begin
                            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                            NewImpBranch^.Childs[K - 1] := ABranch^.Childs[K];
                            ABranch^.Childs[K] := nil;
                        end;
                        
                        MakeHeadASTBranch(FX_ASTN_LET, AuxBranch);
                        AddASTBranchChilds(AuxBranch, 2);
                        AuxBranch^.Childs[0] := ABranch^.Childs[0];
                        ABranch^.Childs[0] := nil;
                        AuxBranch ^.Childs[1] := NewImpBranch;
                        NewImpBranch := nil;
                        
                        EraseASTBranch(ABranch);
                        ABranch := AuxBranch;
                        AuxBranch := nil;
                        Result := __BasicValueASTBranch(ABranch);
                        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    end;
                    FX_ASTN_IF: begin
                        RDIdCode := GetRequiredDefinitionIdCode(FX_RD_IFTHENELSE_STR);
                        if RDIdCode >= 0 then begin
                            
                            if Length(ABranch^.Childs[0]^.Childs) > 3 then begin
                                AuxBranch := nil;
                                MakeHeadASTBranch(FX_ASTN_UNTITLED, AuxBranch);
                                AddASTBranchChilds(AuxBranch, 1);
                                MakeHeadASTBranch(FX_ASTN_IF, AuxBranch^.Childs[0]);
                                L := Length(ABranch^.Childs[0]^.Childs) - 2;
                                AddASTBranchChilds(AuxBranch^.Childs[0], L);
                                for K := 0 to L -  1 do begin
                                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                    AuxBranch^.Childs[0]^.Childs[K] := ABranch^.Childs[0]^.Childs[2 + K];
                                    ABranch^.Childs[0]^.Childs[2 + K] := nil;
                                end;
                                SetLength(ABranch^.Childs[0]^.Childs, 3);
                                ABranch^.Childs[0]^.Childs[2] := AuxBranch;
                                AuxBranch := nil;
                                Result := __BasicValueASTBranch(ABranch);
                                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                            end
                            else begin
                                
                                NewBranchCond := ABranch^.Childs[0]^.Childs[0];
                                ABranch^.Childs[0]^.Childs[0] := nil;
                                
                                L := Length(ABranch^.Childs[0]^.Childs[1]^.Childs);
                                MakeHeadASTBranch(FX_ASTN_IMPERATIVE, NewImpBranch);
                                AddASTBranchChilds(NewImpBranch, L + LL);
                                for K := 0 to L - 1 do begin
                                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                    NewImpBranch^.Childs[K] := ABranch^.Childs[0]^.Childs[1]^.Childs[K];
                                    ABranch^.Childs[0]^.Childs[1]^.Childs[K] := nil;
                                end;
                                for K := 1 to LL do begin
                                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                    CopyASTBranch(ABranch^.Childs[K], NewImpBranch^.Childs[K - 1 + L]);
                                end;
                                
                                MakeHeadASTBranch(FX_ASTN_LAMBDA, NewBranchThen);
                                AddASTBranchChilds(NewBranchThen, 2);
                                MakeHeadASTBranch(FX_ASTN_ANONYMOUS, NewBranchThen^.Childs[0]);
                                NewBranchThen^.Childs[1] := NewImpBranch;
                                NewImpBranch := nil;
                                
                                
                                if Length(ABranch^.Childs[0]^.Childs) = 3 { has else } then
                                    L := Length(ABranch^.Childs[0]^.Childs[2]^.Childs)
                                else
                                    L := 0; // por defecto
                                MakeHeadASTBranch(FX_ASTN_IMPERATIVE, NewImpBranch);
                                AddASTBranchChilds(NewImpBranch, L + LL);
                                for K := 0 to L - 1 do begin
                                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                    NewImpBranch^.Childs[K] := ABranch^.Childs[0]^.Childs[2]^.Childs[K];
                                    ABranch^.Childs[0]^.Childs[2]^.Childs[K] := nil;
                                end;
                                for K := 1 to LL do begin
                                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                    NewImpBranch^.Childs[K - 1 + L] := ABranch^.Childs[K];
                                    ABranch^.Childs[K] := nil;
                                end;
                                
                                MakeHeadASTBranch(FX_ASTN_LAMBDA, NewBranchElse);
                                AddASTBranchChilds(NewBranchElse, 2);
                                MakeHeadASTBranch(FX_ASTN_ANONYMOUS, NewBranchElse^.Childs[0]);
                                NewBranchElse^.Childs[1] := NewImpBranch;
                                NewImpBranch := nil;
                                
                                
                                MakeHeadASTBranch(FX_ASTN_APPLICATION, AuxBranch);
                                AddASTBranchChilds(AuxBranch, 2);
                                
                                MakeHeadASTBranch(FX_ASTN_APPLICATION, AuxBranch^.Childs[0]);
                                AddASTBranchChilds(AuxBranch^.Childs[0], 2);
                                MakeIdentifierASTBranch(RDIdCode, -1, AuxBranch^.Childs[0]^.Childs[0]);
                                
                                MakeHeadASTBranch(FX_ASTN_TUPLE, AuxBranch^.Childs[0]^.Childs[1]);
                                AddASTBranchChilds(AuxBranch^.Childs[0]^.Childs[1], 3);
                                AuxBranch^.Childs[0]^.Childs[1]^.Childs[0] := NewBranchCond;
                                NewBranchCond := nil;
                                AuxBranch^.Childs[0]^.Childs[1]^.Childs[1] := NewBranchThen;
                                NewBranchThen := nil;
                                AuxBranch^.Childs[0]^.Childs[1]^.Childs[2] := NewBranchElse;
                                NewBranchElse := nil;
                                
                                MakeTrivialASTBranch(AuxBranch^.Childs[1]);
                                
                                
                                EraseASTBranch(ABranch);
                                ABranch := AuxBranch;
                                AuxBranch := nil;
                                Result := __BasicValueASTBranch(ABranch);
                                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                            end;
                        end
                        else
                            Result := TranslationError(RequiredDefinitionForStr, [FX_RD_IFTHENELSE_STR, ConditionalStatementStr]);
                        
                    end;
                    FX_ASTN_WHILE: begin
                        RDIdCode := GetRequiredDefinitionIdCode(FX_RD_WHILESKELETON_STR);
                        if RDIdCode >= 0 then begin
                            NI := UseNewInternalVariable;

                            
                            Result := __BranchIdentifiers(ABranch, NewBranchIdTuple);
                            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                            if Result = FX_RES_SUCCESS then begin
                                NewBranchCond := ABranch^.Childs[0]^.Childs[0];
                                ABranch^.Childs[0]^.Childs[0] := nil;
                                
                                
                                L := Length(ABranch^.Childs[0]^.Childs[1]^.Childs);
                                MakeHeadASTBranch(FX_ASTN_IMPERATIVE, NewImpBranch);
                                AddASTBranchChilds(NewImpBranch, L + 1);
                                for K := 0 to L - 1 do begin
                                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                    NewImpBranch^.Childs[K] := ABranch^.Childs[0]^.Childs[1]^.Childs[K];
                                    ABranch^.Childs[0]^.Childs[1]^.Childs[K] := nil;
                                end;
                                MakeHeadASTBranch(FX_ASTN_RETURN, NewImpBranch^.Childs[L]);
                                AddASTBranchChilds(NewImpBranch^.Childs[L], 1);
                                MakeHeadASTBranch(FX_ASTN_APPLICATION, NewImpBranch^.Childs[L]^.Childs[0]);
                                AddASTBranchChilds(NewImpBranch^.Childs[L]^.Childs[0], 2);
                                MakeIdentifierASTBranch(NI, -1, NewImpBranch^.Childs[L]^.Childs[0]^.Childs[0]);
                                CopyASTBranch(NewBranchIdTuple, NewImpBranch^.Childs[L]^.Childs[0]^.Childs[1]);
                                
                                
                                MakeHeadASTBranch(FX_ASTN_LAMBDA, NewBranchLoop);
                                AddASTBranchChilds(NewBranchLoop, 2);
                                MakeIdentifierASTBranch(NI, -1, NewBranchLoop^.Childs[0]);
                                NewBranchLoop^.Childs[1] := NewImpBranch;
                                NewImpBranch := nil;
                                
                                
                                MakeHeadASTBranch(FX_ASTN_IMPERATIVE, NewImpBranch);
                                AddASTBranchChilds(NewImpBranch, LL);
                                for K := 1 to LL do begin
                                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                    NewImpBranch^.Childs[K - 1] := ABranch^.Childs[K];
                                    ABranch^.Childs[K] := nil;
                                end;
                                
                                MakeHeadASTBranch(FX_ASTN_LAMBDA, NewBranchNext);
                                AddASTBranchChilds(NewBranchNext, 2);
                                MakeHeadASTBranch(FX_ASTN_ANONYMOUS, NewBranchNext^.Childs[0]);
                                NewBranchNext^.Childs[1] := NewImpBranch;
                                NewImpBranch := nil;
                                
                                
                                MakeHeadASTBranch(FX_ASTN_LAMBDA, AuxBranch);
                                AddASTBranchChilds(AuxBranch, 2);
                                CopyASTBranch(NewBranchIdTuple, AuxBranch^.Childs[0]);
                                MakeHeadASTBranch(FX_ASTN_TUPLE, AuxBranch^.Childs[1]);
                                AddASTBranchChilds(AuxBranch^.Childs[1], 3);
                                AuxBranch^.Childs[1]^.Childs[0] := NewBranchCond;
                                NewBranchCond := nil;
                                AuxBranch^.Childs[1]^.Childs[1] := NewBranchLoop;
                                NewBranchLoop := nil;
                                AuxBranch^.Childs[1]^.Childs[2] := NewBranchNext;
                                NewBranchNext := nil;
                                
                                
                                EraseASTBranch(ABranch);
                                ABranch := AuxBranch;
                                AuxBranch := nil;
                                
                                
                                MakeHeadASTBranch(FX_ASTN_APPLICATION, AuxBranch);
                                AddASTBranchChilds(AuxBranch, 2);
                                MakeHeadASTBranch(FX_ASTN_APPLICATION, AuxBranch^.Childs[0]);
                                AddASTBranchChilds(AuxBranch^.Childs[0], 2);
                                MakeIdentifierASTBranch(RDIdCode, -1, AuxBranch^.Childs[0]^.Childs[0]);
                                AuxBranch^.Childs[0]^.Childs[1] := ABranch;
                                ABranch := nil;
                                AuxBranch^.Childs[1] := NewBranchIdTuple;
                                NewBranchIdTuple := nil;
                                
                                ABranch := AuxBranch;
                                AuxBranch := nil;
                                Result := __BasicValueASTBranch(ABranch);
                                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                            end;
                        end
                        else
                            Result := TranslationError(RequiredDefinitionForStr, [FX_RD_WHILESKELETON_STR, LoopWhileStatementStr]);
                    end;
                    FX_ASTN_FOR: begin
                        RDIdCode := GetRequiredDefinitionIdCode(FX_RD_NOTEMPTY_STR);
                        if RDIdCode >= 0 then begin
                            NI := UseNewInternalVariable;
                            
                            MakeHeadASTBranch(FX_ASTN_IMPERATIVE, NewImpBranch);
                            AddASTBranchChilds(NewImpBranch, Length(ABranch^.Childs) + 1);
                            
                            MakeHeadASTBranch(FX_ASTN_ASSIGNMENT, NewAssignmentBranch);
                            AddASTBranchChilds(NewAssignmentBranch, 2);
                            MakeIdentifierASTBranch(NI, -1, NewAssignmentBranch^.Childs[0]);
                            NewAssignmentBranch^.Childs[1] := ABranch^.Childs[0]^.Childs[1];
                            ABranch^.Childs[0]^.Childs[1] := nil;
                            
                            NewImpBranch^.Childs[0] := NewAssignmentBranch;
                            NewAssignmentBranch := nil;
                            
                            L := Length(ABranch^.Childs[0]^.Childs[2]^.Childs);
                            MakeHeadASTBranch(FX_ASTN_WHILE, AuxBranch);
                            AddASTBranchChilds(AuxBranch, 2);
                            MakeHeadASTBranch(FX_ASTN_APPLICATION, AuxBranch^.Childs[0]);
                            AddASTBranchChilds(AuxBranch^.Childs[0], 2);
                            MakeIdentifierASTBranch(RDIdCode, -1, AuxBranch^.Childs[0]^.Childs[0]);
                            MakeIdentifierASTBranch(NI, -1, AuxBranch^.Childs[0]^.Childs[1]);
                            MakeHeadASTBranch(FX_ASTN_UNTITLED, AuxBranch^.Childs[1]);
                            AddASTBranchChilds(AuxBranch^.Childs[1], L + 1);
                            
                            MakeHeadASTBranch(FX_ASTN_ASSIGNMENT, NewAssignmentBranch);
                            AddASTBranchChilds(NewAssignmentBranch, 2);
                            MakeHeadASTBranch(FX_ASTN_LIST_CONSTRUCTOR, NewAssignmentBranch^.Childs[0]);
                            AddASTBranchChilds(NewAssignmentBranch^.Childs[0], 2);
                            NewAssignmentBranch^.Childs[0]^.Childs[0] := ABranch^.Childs[0]^.Childs[0];
                            ABranch^.Childs[0]^.Childs[0] := nil;
                            MakeIdentifierASTBranch(NI, -1, NewAssignmentBranch^.Childs[0]^.Childs[1]);
                            MakeIdentifierASTBranch(NI, -1, NewAssignmentBranch^.Childs[1]);
                            
                            AuxBranch^.Childs[1]^.Childs[0] := NewAssignmentBranch;
                            NewAssignmentBranch := nil;
                            
                            for K := 0 to L - 1 do begin
                                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                AuxBranch^.Childs[1]^.Childs[K + 1] := ABranch^.Childs[0]^.Childs[2]^.Childs[K];
                                ABranch^.Childs[0]^.Childs[2]^.Childs[K] := nil;
                            end;
                            
                            NewImpBranch^.Childs[1] := AuxBranch;
                            AuxBranch := nil;
                            
                            for K := 1 to Length(ABranch^.Childs) - 1 do begin
                                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                NewImpBranch^.Childs[K + 1] := ABranch^.Childs[K];
                                ABranch^.Childs[K] := nil;
                            end;
                            
                            AuxBranch := NewImpBranch;
                            NewImpBranch := nil;
                            
                            EraseASTBranch(ABranch);
                            ABranch := AuxBranch;
                            AuxBranch := nil;
                            Result := __BasicValueASTBranch(ABranch);
                            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                        end
                        else
                            Result := TranslationError(RequiredDefinitionForStr, [FX_RD_NOTEMPTY_STR, LoopForStatementStr]);
                    end;
                    else { call eval } begin
                        MakeHeadASTBranch(FX_ASTN_IMPERATIVE, NewImpBranch);
                        AddASTBranchChilds(NewImpBranch, Length(ABranch^.Childs) - 1);
                        for K := 1 to Length(ABranch^.Childs) - 1 do begin
                            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                            NewImpBranch^.Childs[K - 1] := ABranch^.Childs[K];
                            ABranch^.Childs[K] := nil;
                        end;
                        
                        MakeHeadASTBranch(FX_ASTN_ASSIGNMENT, NewAssignmentBranch);
                        AddASTBranchChilds(NewAssignmentBranch, 2);
                        MakeHeadASTBranch(FX_ASTN_ANONYMOUS, NewAssignmentBranch^.Childs[0]);
                        NewAssignmentBranch^.Childs[1] := ABranch^.Childs[0];
                        ABranch^.Childs[0] := nil;
                        
                        MakeHeadASTBranch(FX_ASTN_LET, AuxBranch);
                        AddASTBranchChilds(AuxBranch, 2);
                        AuxBranch^.Childs[0] := NewAssignmentBranch;
                        NewAssignmentBranch := nil;
                        AuxBranch ^.Childs[1] := NewImpBranch;
                        NewImpBranch := nil;
                        
                        EraseASTBranch(ABranch);
                        ABranch := AuxBranch;
                        AuxBranch := nil;
                        Result := __BasicValueASTBranch(ABranch);
                        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    end;
                end;
            end;
        end;
    end;
    
LBL_END:
    
    EraseASTBranch(AuxBranch);
    EraseASTBranch(TailBranch);
    for K := 0 to Length(AuxBranchList) - 1 do
        EraseASTBranch(AuxBranchList[K]);
    AuxBranchList := nil;
    
    EraseASTBranch(NewListBranch);
    EraseASTBranch(NewLambdaBranch);
    
    EraseASTBranch(NewImpBranch);
    EraseASTBranch(NewStatementBranch);
    EraseASTBranch(NewAssignmentBranch);
    EraseASTBranch(NewBranchCond);
    EraseASTBranch(NewBranchThen);
    EraseASTBranch(NewBranchElse);
    EraseASTBranch(NewBranchNext);
    EraseASTBranch(NewBranchLoop);
    EraseASTBranch(NewBranchIdTuple);
    
end;

function TTranslator.__BasicTypeASTBranch(var ABranch: TAbstractSyntaxTree): Word;
    
LABEL LBL_END;
    
var
    K: Integer;
    AuxBranch: TAbstractSyntaxTree;
begin
    
    AuxBranch := nil;
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    case ABranch^.Kind of
        FX_ASTN_NONE:;
        FX_ASTN_TYPE_REAL:;
        FX_ASTN_TYPE_INT:;
        FX_ASTN_TYPE_NAT:;
        FX_ASTN_TYPE_CHAR:;
        FX_ASTN_TYPE_BOOL:;
        FX_ASTN_IDENTIFIER:;
        FX_ASTN_ANONYMOUS:;
        FX_ASTN_FUNCTION: begin
            Result := __BasicTypeASTBranch(ABranch^.Childs[0]);
            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            if Result = FX_RES_SUCCESS then begin
                Result := __BasicTypeASTBranch(ABranch^.Childs[1]);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            end;
        end;
        FX_ASTN_TUPLE: begin
            for K := 0 to Length(ABranch^.Childs) - 1 do begin
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                Result := __BasicTypeASTBranch(ABranch^.Childs[K]);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                if Result <> FX_RES_SUCCESS then
                    Break;
            end;
            // quitar tuplas unarias
            if (Result = FX_RES_SUCCESS) and (Length(ABranch^.Childs) = 1) then begin
                AuxBranch := ABranch^.Childs[0];
                ABranch^.Childs[0] := nil;
                EraseASTBranch(ABranch);
                ABranch := AuxBranch;
                AuxBranch := nil;
            end;
        end;
        FX_ASTN_LIST: begin
            Result := __BasicTypeASTBranch(ABranch^.Childs[0]);
            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
        end;
    end;
    
LBL_END:
    
    EraseASTBranch(AuxBranch);
    
end;

function TTranslator.__TranslateDefinitionPatterns(var ABranch: TAbstractSyntaxTree; var AIdCode: Integer; var APatterns: TPatternExprArray): Word;
    
LABEL LBL_END;
    
begin
    
    AIdCode := 0;
    APatterns := nil;
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    Result := __BasicValueASTBranch(ABranch);
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    if Result = FX_RES_SUCCESS then begin
        Result := __PatternsFromAppPatternAST(ABranch, AIdCode, APatterns);
        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    end;
    
LBL_END:
    
end;

function TTranslator.__TranslateToValueExpr(var ABranch: TAbstractSyntaxTree; var AValue: TValueExpr): Word;
    
LABEL LBL_END;
    
begin
    
    AValue := nil;
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    Result := __BasicValueASTBranch(ABranch);
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    if Result = FX_RES_SUCCESS then begin
        Result := __ValueExprFromValueAST(ABranch, AValue);
        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    end;
    
LBL_END:
    
end;

function TTranslator.__TranslateToTypeExpr(var ABranch: TAbstractSyntaxTree; var AType: TTypeExpr): Word;
    
LABEL LBL_END;
    
begin
    
    AType := nil;
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    Result := __BasicTypeASTBranch(ABranch);
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    if Result = FX_RES_SUCCESS then begin
        Result := __TypeExprFromTypeAST(ABranch, AType);
        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    end;
    
LBL_END:
    
end;

function TTranslator.__TranslateCommand(var ABranch: TAbstractSyntaxTree; var ACommand: TCommand): Word;
    
LABEL LBL_END;
    
var
    K: Integer;
begin
    
    EmptyCommand(ACommand);
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if ABranch = nil then begin
        // comando vacio(no hay nada que ejecutar)
    end
    else begin
        case ABranch^.Kind of
            FX_ASTN_RUN     : begin
                ACommand.Kind := FX_CMD_RUN;
                System.New(ACommand.Run);
                System.New(ACommand.Run^.ScriptFile);
                ACommand.Run^.ScriptFile^ := ABranch^.Childs[0]^.D.sValue^;
            end;
            FX_ASTN_CLEAR      : begin
                ACommand.Kind := FX_CMD_CLEAR;
                System.New(ACommand.Clear);
                SetLength(ACommand.Clear^.IdCodes, Length(ABranch^.Childs));
                for K := 0 to Length(ABranch^.Childs) - 1 do begin
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    ACommand.Clear^.IdCodes[K] := ABranch^.Childs[K]^.D.IdCode;
                end;
            end;
            FX_ASTN_INFIX      : begin
                ACommand.Kind := FX_CMD_NOTATION;
                System.New(ACommand.Notation);
                ACommand.Notation^.Position := npInfix;
                ACommand.Notation^.Priority := nITrunc(ABranch^.Childs[0]^.D.nValue);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                SetLength(ACommand.Notation^.IdCodes, Length(ABranch^.Childs) - 1);
                for K := 1 to Length(ABranch^.Childs) - 1 do begin
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    ACommand.Notation^.IdCodes[K - 1] := ABranch^.Childs[K]^.D.IdCode;
                end;
            end;
            FX_ASTN_INFIXL     : begin
                ACommand.Kind := FX_CMD_NOTATION;
                System.New(ACommand.Notation);
                ACommand.Notation^.Position := npInfixl;
                ACommand.Notation^.Priority := nITrunc(ABranch^.Childs[0]^.D.nValue);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                SetLength(ACommand.Notation^.IdCodes, Length(ABranch^.Childs) - 1);
                for K := 1 to Length(ABranch^.Childs) - 1 do begin
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    ACommand.Notation^.IdCodes[K - 1] := ABranch^.Childs[K]^.D.IdCode;
                end;
            end;
            FX_ASTN_INFIXR     : begin
                ACommand.Kind := FX_CMD_NOTATION;
                System.New(ACommand.Notation);
                ACommand.Notation^.Position := npInfixr;
                ACommand.Notation^.Priority := nITrunc(ABranch^.Childs[0]^.D.nValue);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                SetLength(ACommand.Notation^.IdCodes, Length(ABranch^.Childs) - 1);
                for K := 1 to Length(ABranch^.Childs) - 1 do begin
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    ACommand.Notation^.IdCodes[K - 1] := ABranch^.Childs[K]^.D.IdCode;
                end;
            end;
            FX_ASTN_POSFIX     : begin
                ACommand.Kind := FX_CMD_NOTATION;
                System.New(ACommand.Notation);
                ACommand.Notation^.Position := npPosfix;
                ACommand.Notation^.Priority := High(TNotationPriority);
                SetLength(ACommand.Notation^.IdCodes, Length(ABranch^.Childs));
                for K := 0 to Length(ABranch^.Childs) - 1 do begin
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    ACommand.Notation^.IdCodes[K] := ABranch^.Childs[K]^.D.IdCode;
                end;
            end;
            FX_ASTN_PREFIX     : begin
                ACommand.Kind := FX_CMD_NOTATION;
                System.New(ACommand.Notation);
                ACommand.Notation^.Position := npPrefix;
                ACommand.Notation^.Priority := High(TNotationPriority);
                SetLength(ACommand.Notation^.IdCodes, Length(ABranch^.Childs));
                for K := 0 to Length(ABranch^.Childs) - 1 do begin
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    ACommand.Notation^.IdCodes[K] := ABranch^.Childs[K]^.D.IdCode;
                end;
            end;
            FX_ASTN_SYNONYMOUS : begin
                ACommand.Kind := FX_CMD_SYNONYMOUS;
                System.New(ACommand.Synonymous);
                ACommand.Synonymous^.IdCode := ABranch^.Childs[0]^.D.IdCode;
                Result := __TranslateToTypeExpr(ABranch^.Childs[1], ACommand.Synonymous^.Expr);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            end;
            FX_ASTN_INHERITABLE: begin
                ACommand.Kind := FX_CMD_INHERITABLE;
                System.New(ACommand.Inheritable);
                ACommand.Inheritable^.IdCode := ABranch^.Childs[0]^.D.IdCode;
                Result := __TranslateToTypeExpr(ABranch^.Childs[1], ACommand.Inheritable^.Expr);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            end;
            FX_ASTN_DEFINITION : begin
                ACommand.Kind := FX_CMD_DEFINITION;
                System.New(ACommand.Definition);
                Result := __TranslateDefinitionPatterns(ABranch^.Childs[0], ACommand.Definition^.IdCode, ACommand.Definition^.Patterns);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                if Result = FX_RES_SUCCESS then begin
                    Result := __TranslateToValueExpr(ABranch^.Childs[1], ACommand.Definition^.Return);
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                end;
            end;
            FX_ASTN_GLOBAL_ASSIGNMENT: begin
                ACommand.Kind := FX_CMD_ASSIGNMENT;
                System.New(ACommand.Assignment);
                ACommand.Assignment^.IdCode := ABranch^.Childs[0]^.D.IdCode;
                Result := __TranslateToValueExpr(ABranch^.Childs[1], ACommand.Assignment^.Expr);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            end;
            else { Evaluation }  begin
                ACommand.Kind := FX_CMD_EVALUATION;
                System.New(ACommand.Evaluation);
                ACommand.Evaluation^.Show := True;
                ACommand.Evaluation^.Store := True;
                Result := __TranslateToValueExpr(ABranch, ACommand.Evaluation^.Expr);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            end;
        end;
    end;
    
LBL_END:
    
end;

function TTranslator.__Translate(var ATree: TAbstractSyntaxTree; var ARestrictedInternalVars: TRestrictedVariables; var ACommand: TCommand): Word;

begin
    AvailableInternalVariableCode := 0;
    RIVIndex := 0;
    RestrictedInternalVariables := ARestrictedInternalVars;
    Result := __TranslateCommand(ATree, ACommand);
end;

procedure TTranslator.Interrupt;
begin
    STOP := TRUE;
end;
            
procedure TTranslator.Pause;
begin
    SLEEP := TRUE;
end;

procedure TTranslator.Resume;
begin
    SLEEP := FALSE;
end;

end.
