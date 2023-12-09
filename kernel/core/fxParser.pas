unit fxParser;

interface

uses
    fxUtils, fxMath, fxStorage, fxError, fxStrUtils, fxBasicStructure, fxInterpreterUtils, fxTokenUtils,
    fxPrimFuncUtils, fxASTUtils;

type
    
    TParser = class
    private
        FrontEnd: IFrontEndListener;
        Interpreter: IInterpreterListener;
        Storage: TStorage;
        Error: TErrorRegister;
        
        PrevLine: Integer;
        Tkn: PToken;
        IsLayoutToken: Boolean;
        LayoutStack: TLayoutStack;
        
        function ErrorAtToken(AMsg: TFxString): Word; overload;
        function TokenToStr: TFxString;
        function ThereIsToken: Boolean;
        function ReadNextToken: Boolean;
        function TokenInLayout: Boolean;
        function TokenOnLayout: Boolean;
        function LayoutAtToken: Boolean;
        function RemoveLayout: Boolean;
        function IsMinusPlusIdent(AIdCode: Integer): Boolean;
        function IsMinusIdent(AIdCode: Integer): Boolean;
        function IsPlusIdent(AIdCode: Integer): Boolean;
        function IdentString(AIdCode: Integer): TFxString;
        
        function __AppTermForestToApplication(var AForest: TAbstractSyntaxTreeList; var ABranch: TAbstractSyntaxTree; var AEKind: Byte): Word;
        function __ParsePatternTerm(var ABranch: TAbstractSyntaxTree; var AParsed: Boolean): Word;
        function __ParseListConsPatternPosibility(var ABranch: TAbstractSyntaxTree; var AParsed: Boolean): Word;
        function __ParsePatternExpression(var ABranch: TAbstractSyntaxTree; var AParsed: Boolean): Word;
        function __ParseStatement(var ABranch: TAbstractSyntaxTree; var AParsed: Boolean): Word;
        function __ParseQualifier(var ABranch: TAbstractSyntaxTree; var AQKind: Byte): Word;
        function __ParseAssignment(var ABranch: TAbstractSyntaxTree; var AParsed: Boolean): Word;
        
        function __ParseAppTermPreIndex(var ABranch: TAbstractSyntaxTree; var AEKind: Byte): Word;
        function __ParseIndexPartPosibilityTail(var ABranch: TAbstractSyntaxTree; var AEKind: Byte): Word;
        function __ParseAppTerm(var ABranch: TAbstractSyntaxTree; var AEKind: Byte): Word;
        function __ParseApplication(var ABranch: TAbstractSyntaxTree; var AEKind: Byte): Word;
        function __ParseListConsExprPosibility(var ABranch: TAbstractSyntaxTree; var AEKind: Byte): Word;
        function __ParseGuardExprPosibility(var ABranch: TAbstractSyntaxTree; var AEKind: Byte): Word;
        function __ParseTryExprPosibility(var ABranch: TAbstractSyntaxTree; var AEKind: Byte): Word;
        function __ParseWhereExprPosibilityTail(var ABranch: TAbstractSyntaxTree; var AEKind: Byte): Word;
        function __ParseWhereExprPosibility(var ABranch: TAbstractSyntaxTree; var AEKind: Byte): Word;
        function __ParseValueExpression(var ABranch: TAbstractSyntaxTree; var AEKind: Byte): Word;
        function __ParseTypeExpression(var ABranch: TAbstractSyntaxTree; var AParsed: Boolean): Word;
        function __ParseTentativeDefEvl(var ABranch: TAbstractSyntaxTree): Word;
        function __ParseTentativeSynInhDefAsgEvl(var ABranch: TAbstractSyntaxTree): Word;
        function __ParseCommand(var ABranch: TAbstractSyntaxTree): Word;
    protected
        STOP: BOOLEAN;
        SLEEP: BOOLEAN;
    public
        constructor Create(AFrontEnd: IFrontEndListener; AInterpreter: IInterpreterListener;
            AStorage: TStorage; AError: TErrorRegister);
        destructor Destroy; override;
        
        function __Parse(var ATokenList: TTokenList; var AAST: TAbstractSyntaxTree): Word;
        procedure Interrupt;  
        procedure Pause;
        procedure Resume;
    end;

implementation

const
    {Value Expression Kind}
    FX_VEK_EMPTY      = 0;
    FX_VEK_IDENTIFIER = 1;
    FX_VEK_PATTERN    = 2;
    FX_VEK_APPPATTERN = 3;
    FX_VEK_COMPLETE   = 4;
    
    FX_VQK_EMPTY      = 0;
    FX_VQK_FILTER     = 1;
    FX_VQK_GENERATOR  = 2;
    
    AK_NONE           = 0;
    AK_PREFIX         = 1;
    AK_POSFIX         = 2;
    AK_INFIX          = 3;
    AK_INFIXL         = 4;
    AK_INFIXR         = 5;

function IsPriorityNumber(N: TFxNumber): Boolean;
begin
    Result := nGreaterOrEqual(N, Low(TNotationPriority)) and
        nLessOrEqual(N, High(TNotationPriority)) and
        nIsZero(nFrac(N));
end;

{ TParser }

constructor TParser.Create(AFrontEnd: IFrontEndListener; AInterpreter: IInterpreterListener;
    AStorage: TStorage; AError: TErrorRegister);
begin
    inherited Create;
    FrontEnd := AFrontEnd;
    Interpreter := AInterpreter;
    Storage := AStorage;
    Error := AError;
    
    STOP := FALSE;
    LayoutStack := TLayoutStack.Create;
end;

destructor TParser.Destroy;
begin
    LayoutStack.Free;
    inherited;
end;

function TParser.ErrorAtToken(AMsg: TFxString): Word;
begin
    Result := FX_RES_ERR_SINGLE;
    Error.Code := Result;
    if ThereIsToken then begin
        if TokenInLayout then begin
            Error.Line := Tkn^.Line;
            Error.Msg := FormatMessage(AMsg, [TokenToStr]);
        end
        else begin
            Error.Line := Tkn^.Line;
            Error.Msg := FormatMessage(AMsg, [EndOfLayoutStr]);
        end;
    end
    else begin
        Error.Line := PrevLine;
        Error.Msg := FormatMessage(AMsg, [EndOfCommandStr]);
    end;
end;

function TParser.TokenToStr: TFxString;
begin
    if ThereIsToken then begin
        Result := TokenToLexeme(Tkn^, Storage);
        if Tkn^.Kind = FX_TK_STRING then Result := 'string ' + Result
        else Result := '"' + Result + '"';
    end
    else
        Result := '';
end;

function TParser.ThereIsToken: Boolean;
begin
    Result := Tkn <> nil;
end;

function TParser.ReadNextToken: Boolean;
begin
    if ThereIsToken then begin
        PrevLine := Tkn^.Line;
        Tkn := Tkn^.Next;
        Result := Tkn <> nil;
        IsLayoutToken := False;
    end
    else
        Result := False;
end;

function TParser.TokenInLayout: Boolean;
begin
    if ThereIsToken then
        Result := IsLayoutToken or (Tkn^.Col > LayoutStack.Top)
    else
        Result := False;
end;

function TParser.TokenOnLayout: Boolean;
begin
    if ThereIsToken then
        Result := IsLayoutToken or (Tkn^.Col = LayoutStack.Top)
    else
        Result := False;
end;

function TParser.LayoutAtToken: Boolean;
begin
    if ThereIsToken then begin
        IsLayoutToken := True;
        LayoutStack.Push(Tkn^.Col);
        Result := True;
    end
    else
        Result := False;
end;

function TParser.RemoveLayout: Boolean;
begin
    if not LayoutStack.IsEmpty then begin
        LayoutStack.Pop;
        IsLayoutToken := False; // segun al diseño de la sintaxis no hay dos trazados en un mismo token
        Result := True;
    end
    else
        Result := False;
end;

function TParser.IsMinusPlusIdent(AIdCode: Integer): Boolean;
begin
    Result := IsMinusIdent(AIdCode) or IsPlusIdent(AIdCode);
end;

function TParser.IsMinusIdent(AIdCode: Integer): Boolean;
begin
    Result := (AIdCode >= 0) and (Storage[AIdCode].Name = '-');
end;

function TParser.IsPlusIdent(AIdCode: Integer): Boolean;
begin
    Result := (AIdCode >= 0) and (Storage[AIdCode].Name = '+');
end;

function TParser.IdentString(AIdCode: Integer): TFxString;
begin
    Result := '"' + Storage[AIdCode].Name + '"';
end;

//-- rutinas principales

function TParser.__AppTermForestToApplication(var AForest: TAbstractSyntaxTreeList; var ABranch: TAbstractSyntaxTree; var AEKind: Byte): Word;

LABEL LBL_END;

var
    SEP: Boolean;
    AuxBranch: TAbstractSyntaxTree;
    OutASTStack: TAbstractSyntaxTreeStack;
    OprStack: TAbstractSyntaxTreeStack;
    PrevAppKind, CurrentAppKind: Byte;
    CanPopOpr: Boolean;
    K: Integer;
    
    function ErrorAtAppIdent(AMsg: TFxString): Word;
    begin
        Result := FX_RES_ERR_SINGLE;
        Error.Code := Result;
        Error.Line := AForest.List[K]^.D.IdLine;
        Error.Msg := FormatMessage(AMsg, [IdentString(AForest.List[K]^.D.IdCode)]);
    end;
    
    function ErrorAtAppIdentStack(AMsg: TFxString): Word;
    begin
        Result := FX_RES_ERR_SINGLE;
        Error.Code := Result;
        Error.Line := OprStack.Top^.D.IdLine;
        Error.Msg := FormatMessage(AMsg, [IdentString(OprStack.Top^.D.IdCode)]);
    end;
    
    function AssociativityCheckingError(AMsg: TFxString): Word;
    begin
        Result := FX_RES_ERR_SINGLE;
        Error.Code := Result;
        Error.Line := AForest.List[K]^.D.IdLine;
        Error.Msg := FormatMessage(AMsg, [IdentString(OprStack.Top^.D.IdCode), IdentString(AForest.List[K]^.D.IdCode)]);
    end;
    
    function InvalidInfixIdentifierError(AMsg: TFxString; AInfixBranch: TAbstractSyntaxTree): Word;
    begin
        Result := FX_RES_ERR_SINGLE;
        Error.Code := Result;
        Error.Line := AInfixBranch^.D.IdLine;
        Error.Msg := FormatMessage(AMsg, [AInfixBranch^.D.IdCode]);
    end;
    
    function GetAppKind: Byte;
    var
        NPr: TNotationPriority;
        NPs: TNotationPosition;
    begin

        if AForest.List[K]^.Kind = FX_ASTN_IDENTIFIER then begin
            if AForest.List[K]^.D.IdCode < 0 then 
                NPs := npPrefix
            else
                NPs := Storage[AForest.List[K]^.D.IdCode].Notation.Position;
            case NPs of
                npPrefix: Result := AK_PREFIX;
                npPosfix: Result := AK_POSFIX;
                npInfix : Result := AK_INFIX ;
                npInfixl: Result := AK_INFIXL;
                npInfixr: Result := AK_INFIXR;
            end;
        end
        else if AForest.List[K]^.Kind = FX_ASTN_PRIMITIVE then
            Result := AK_PREFIX
        else
            Result := AK_PREFIX;
    end;
    
    function AppTermIsMinusPlus: Boolean;
    begin
        Result := IsMinusPlusIdent(AForest.List[K]^.D.IdCode);
    end;
    
    procedure MakePrefixApplication;
    var
        SEK: Byte;
    begin
        MakeHeadASTBranch(FX_ASTN_APPLICATION, AuxBranch);
        AddASTBranchChilds(AuxBranch, 2);
        OutASTStack.Pop(AuxBranch^.Childs[0], SEK);
        AuxBranch^.Childs[1] := AForest.List[K];
        AForest.List[K] := nil;
        if ((SEK = FX_VEK_IDENTIFIER) or (SEK = FX_VEK_APPPATTERN)) and
            (AForest.Seks[K] <= FX_VEK_PATTERN) then SEK := FX_VEK_APPPATTERN
        else
            SEK := FX_VEK_COMPLETE;
        OutASTStack.Push(AuxBranch, SEK);
    end;
    
    procedure MakePosfixApplication;
    var
        SEK: Byte;
    begin
        MakeHeadASTBranch(FX_ASTN_APPLICATION, AuxBranch);
        AddASTBranchChilds(AuxBranch, 2);
        OutASTStack.Pop(AuxBranch^.Childs[1], SEK);
        AuxBranch^.Childs[0] := AForest.List[K];
        AForest.List[K] := nil;
        if  ((AForest.Seks[K] = FX_VEK_IDENTIFIER) or (AForest.Seks[K] = FX_VEK_APPPATTERN)) and
            (SEK <= FX_VEK_PATTERN) then SEK := FX_VEK_APPPATTERN
        else
            SEK := FX_VEK_COMPLETE;
        OutASTStack.Push(AuxBranch, SEK);
    end;
    
    procedure MakeInfixApplication;
    var
        SEK, SEK_A, SEK_B: Byte;
    begin
        MakeHeadASTBranch(FX_ASTN_APPLICATION, AuxBranch);
        AddASTBranchChilds(AuxBranch, 2);
        OprStack.Pop(AuxBranch^.Childs[0], SEK);
        
        MakeHeadASTBranch(FX_ASTN_TUPLE, AuxBranch^.Childs[1]);
        AddASTBranchChilds(AuxBranch^.Childs[1], 2);
        OutASTStack.Pop(AuxBranch^.Childs[1]^.Childs[1], SEK_B);
        OutASTStack.Pop(AuxBranch^.Childs[1]^.Childs[0], SEK_A);
        
        if (SEK_A <= FX_VEK_PATTERN) and (SEK_B <= FX_VEK_PATTERN) then
            SEK_A := FX_VEK_PATTERN
        else
            SEK_A := FX_VEK_COMPLETE;
        
        if ((SEK = FX_VEK_IDENTIFIER) or (SEK = FX_VEK_APPPATTERN)) and
            (SEK_A <= FX_VEK_PATTERN) then SEK := FX_VEK_APPPATTERN
        else
            SEK := FX_VEK_COMPLETE;
        
        OutASTStack.Push(AuxBranch, SEK);
    end;
    
    function CheckInfixAssociativity: Word;
    var
        SNPs: TNotationPosition;
        FNPr, SNPr: TNotationPriority;
    begin
        CanPopOpr := False;
        if AForest.List[K]^.D.IdCode < 0 then
            Result := InvalidInfixIdentifierError(NegativeInfixIdentifierDetectedStr, AForest.List[K])
        else if OprStack.Top^.D.IdCode < 0 then
            Result := InvalidInfixIdentifierError(NegativeInfixIdentifierDetectedStr, OprStack.Top)
        else begin
            FNPr := Storage[AForest.List[K]^.D.IdCode].Notation.Priority;
            SNPr := Storage[OprStack.Top^.D.IdCode].Notation.Priority;
            SNPs := Storage[OprStack.Top^.D.IdCode].Notation.Position;
            Result := FX_RES_SUCCESS;
            case CurrentAppKind of
                AK_INFIX:
                    if (SNPs = npInfix) and (FNPr = SNPr) then begin
                        Result := AssociativityCheckingError(AmbiguousAssociativityBetweenStr);
                    end
                    else
                        CanPopOpr := FNPr < SNPr;
                AK_INFIXL:
                    CanPopOpr := FNPr <= SNPr;
                AK_INFIXR:
                    CanPopOpr := FNPr < SNPr;
            end;
        end;
    end;
    
begin // Por la forma en que esta escrito el parser, cada arbol del bosque esta debidamente convertido
    
    ABranch := nil;
    AuxBranch := nil;
    OutASTStack := TAbstractSyntaxTreeStack.Create;
    OprStack := TAbstractSyntaxTreeStack.Create;
    Result := FX_RES_SUCCESS;
    
    AEKind := FX_VEK_EMPTY;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;

    PrevAppKind := AK_NONE;

    K := 0;
    
    while K < AForest.Count do begin
        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
        CurrentAppKind := GetAppKind;
        case PrevAppKind of
            AK_NONE  :
                case CurrentAppKind of
                    AK_PREFIX:
                        OutASTStack.Push(AForest.List[K], AForest.Seks[K]); // mueve la informacion
                    AK_POSFIX:
                        if AForest.Count = 1 then
                            OutASTStack.Push(AForest.List[K], AForest.Seks[K])
                        else
                            Result := ErrorAtAppIdent(MissingArgumentForStr);
                    AK_INFIX ,
                    AK_INFIXL,
                    AK_INFIXR:
                        if AForest.Count = 1 then
                            OutASTStack.Push(AForest.List[K], AForest.Seks[K])
                        else if AppTermIsMinusPlus then begin
                            MakeNumberASTBranch(0, AuxBranch);
                            OutASTStack.Push(AuxBranch, FX_VEK_PATTERN);
                            OprStack.Push(AForest.List[K], AForest.Seks[K]); // este operador tiene maxima prioridad que los anteriores encontrados
                        end
                        else
                                Result := ErrorAtAppIdent(MissingLeftArgumentForStr);
                end;
            AK_PREFIX:
                case CurrentAppKind of
                    AK_PREFIX:
                        MakePrefixApplication;
                    AK_POSFIX:
                        MakePosfixApplication;
                    AK_INFIX ,
                    AK_INFIXL,
                    AK_INFIXR: begin
                        while not OprStack.IsEmpty do begin
                            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                            Result := CheckInfixAssociativity;
                            if (Result = FX_RES_SUCCESS) and CanPopOpr then
                                MakeInfixApplication
                            else
                                Break;
                        end;
                        OprStack.Push(AForest.List[K], AForest.Seks[K]);
                    end;
                end;
            AK_POSFIX:
                case CurrentAppKind of
                    AK_PREFIX:
                        MakePrefixApplication;
                    AK_POSFIX:
                        MakePosfixApplication;
                    AK_INFIX ,
                    AK_INFIXL,
                    AK_INFIXR: begin
                        while not OprStack.IsEmpty do begin
                            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                            Result := CheckInfixAssociativity;
                            if (Result = FX_RES_SUCCESS) and CanPopOpr then
                                MakeInfixApplication
                            else
                                Break;
                        end;
                        OprStack.Push(AForest.List[K], AForest.Seks[K]);
                    end;
                end;
            AK_INFIX ,
            AK_INFIXL,
            AK_INFIXR:
                case CurrentAppKind of
                    AK_PREFIX:
                        OutASTStack.Push(AForest.List[K], AForest.Seks[K]);
                    AK_POSFIX:
                        Result := ErrorAtAppIdent(MissingArgumentForStr);
                    AK_INFIX ,
                    AK_INFIXL,
                    AK_INFIXR:
                        if AppTermIsMinusPlus then begin
                            MakeNumberASTBranch(0, AuxBranch);
                            OutASTStack.Push(AuxBranch, FX_VEK_PATTERN);
                            OprStack.Push(AForest.List[K], AForest.Seks[K]); // este operador tiene maxima prioridad que los anteriores encontrados
                        end
                        else
                            Result := ErrorAtAppIdent(MissingLeftArgumentForStr);
                end;
        end;
        if Result <> FX_RES_SUCCESS then Break;
        PrevAppKind := CurrentAppKind;
        Inc(K);
    end;
    if Result = FX_RES_SUCCESS then begin
        case PrevAppKind of
            AK_INFIX,
            AK_INFIXL,
            AK_INFIXR:
                if AForest.Count > 1 then
                    Result := ErrorAtAppIdentStack(MissingRightArgumentForStr);
            else
                while not OprStack.IsEmpty do begin
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    MakeInfixApplication;
                end;
        end;
        if Result = FX_RES_SUCCESS then
            OutASTStack.Pop(ABranch, AEKind);
    end;

LBL_END:
    
    EraseASTBranch(AuxBranch);

    OutASTStack.Free;   //&&

    OprStack.Free;
end;

function TParser.__ParsePatternTerm(var ABranch: TAbstractSyntaxTree; var AParsed: Boolean): Word;

LABEL LBL_END;

var
    K, I: Integer;
    SEP: Boolean;
    AuxBranch: TAbstractSyntaxTree;
    
begin
    
    ABranch := nil;
    AuxBranch := nil;
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if TokenInLayout then begin
        AParsed := True;
        case Tkn^.Kind of
            FX_TK_NUMBER : begin
                MakeNumberASTBranch(Tkn^.nValue, ABranch);
                ReadNextToken;
            end;
            FX_TK_CHARACTER         : begin
                MakeCharASTBranch(Tkn^.cValue, ABranch);
                ReadNextToken;
            end;
            FX_TK_KW_TRUE: begin
                MakeBoolASTBranch(True, ABranch);
                ReadNextToken;
            end;
            FX_TK_KW_FALSE: begin
                MakeBoolASTBranch(False, ABranch);
                ReadNextToken;
            end;
            FX_TK_KW_FAIL: begin
                MakeHeadASTBranch(FX_ASTN_FAIL, ABranch);
                ReadNextToken;
            end;
            FX_TK_STRING            : begin
                MakeStrASTBranch(Tkn^.sValue^, ABranch);
                ReadNextToken;
            end;
            FX_TK_KW_ANONYMOUS      : begin
                MakeHeadASTBranch(FX_ASTN_ANONYMOUS, ABranch);
                ReadNextToken;
            end;
            FX_TK_KW_NAN : begin
                MakeNumberASTBranch(NAN, ABranch);
                ReadNextToken;
            end;
            FX_TK_KW_INF : begin
                MakeNumberASTBranch(INF, ABranch);
                ReadNextToken;
            end;
            FX_TK_IDENTIFIER : begin
                MakeIdentifierASTBranch(Tkn^.IdCode, Tkn^.Line, ABranch);
                ReadNextToken;
                if TokenInLayout then begin
                    if (Tkn^.Kind = FX_TK_KS_COLON) then begin
                        MakeHeadASTBranch(FX_ASTN_TYPING, AuxBranch);
                        AddASTBranchChilds(AuxBranch, 2);
                        AuxBranch^.Childs[0] := ABranch;
                        ABranch := AuxBranch;
                        AuxBranch := nil;

                        ReadNextToken;
                        Result := __ParseTypeExpression(ABranch^.Childs[1], SEP);
                        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                        if Result = FX_RES_SUCCESS then begin
                            if not SEP then
                                Result := ErrorAtToken(TypeExpressionExpectedStr);
                        end;
                    end
                    else if IsMinusPlusIdent(ABranch^.D.IdCode) then begin
                        // patron con signo
                        if Tkn^.Kind = FX_TK_NUMBER then begin
                            // termino de patron de numero con signo
                            if IsMinusIdent(ABranch^.D.IdCode) then Tkn^.nValue := fxMath.nNeg(Tkn^.nValue);
                            // Reemplazar nodo actual por este nuevo patron
                            ABranch^.Kind := FX_ASTN_NUMBER;
                            ABranch^.D.nValue := Tkn^.nValue;
                            
                            ReadNextToken;
                        end
                        else if Tkn^.Kind = FX_TK_KW_INF then begin
                            // termino de patron de infinito con signo
                            if IsMinusIdent(ABranch^.D.IdCode) then Tkn^.nValue := NEGINF
                            else Tkn^.nValue := INF;
                            // Reemplazar nodo actual por este nuevo patron
                            ABranch^.Kind := FX_ASTN_NUMBER;
                            ABranch^.D.nValue := Tkn^.nValue;
                            
                            ReadNextToken;
                        end
                        else if Tkn^.Kind = FX_TK_KW_NAN then begin
                            // termino de patron de nan con signo
                            Tkn^.nValue := NAN;
                            // Reemplazar nodo actual por este nuevo patron
                            ABranch^.Kind := FX_ASTN_NUMBER;
                            ABranch^.D.nValue := Tkn^.nValue;
                            
                            ReadNextToken;
                        end;
                    end;
                end;
            end;
            FX_TK_LEFT_PARENTHESIS: begin
                MakeHeadASTBranch(FX_ASTN_TUPLE, ABranch);
                ReadNextToken;
                if TokenInLayout then begin
                    K := 0;
                    AddASTBranchChilds(ABranch);
                    Result := __ParsePatternExpression(ABranch^.Childs[K], SEP);
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    if Result = FX_RES_SUCCESS then begin
                        if SEP then begin
                            while (Result = FX_RES_SUCCESS) and TokenInLayout and (Tkn^.Kind = FX_TK_COMMA) do begin
                                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                ReadNextToken;
                                Inc(K);
                                AddASTBranchChilds(ABranch);
                                Result := __ParsePatternExpression(ABranch^.Childs[K], SEP);
                                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                if (Result = FX_RES_SUCCESS) and (not SEP) then
                                    Result := ErrorAtToken(PatternExpectedStr);
                            end;
                        end
                        else
                            ABranch^.Childs := nil;
                        if Result = FX_RES_SUCCESS then begin
                            if TokenInLayout and (Tkn^.Kind = FX_TK_RIGHT_PARENTHESIS) then
                                ReadNextToken
                            else
                                Result := ErrorAtToken(RightParenthesisExpectedStr);
                        end;
                    end;
                end
                else
                    Result := ErrorAtToken(RightParenthesisExpectedStr);
            end;
            FX_TK_LEFT_SQUAREBRACKET: begin
                MakeHeadASTBranch(FX_ASTN_LIST, ABranch);
                ReadNextToken;
                if TokenInLayout then begin
                    K := 0;
                    AddASTBranchChilds(ABranch);
                    Result := __ParsePatternExpression(ABranch^.Childs[K], SEP);
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    if Result = FX_RES_SUCCESS then begin
                        if SEP then begin
                            while (Result = FX_RES_SUCCESS) and TokenInLayout and (Tkn^.Kind = FX_TK_COMMA) do begin
                                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                ReadNextToken;
                                Inc(K);
                                AddASTBranchChilds(ABranch);
                                Result := __ParsePatternExpression(ABranch^.Childs[K], SEP);
                                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                if (Result = FX_RES_SUCCESS) and (not SEP) then
                                    Result := ErrorAtToken(PatternExpectedStr);
                            end;
                        end
                        else
                            ABranch^.Childs := nil;
                        if Result = FX_RES_SUCCESS then begin
                            if TokenInLayout and (Tkn^.Kind = FX_TK_RIGHT_SQUAREBRACKET) then
                                ReadNextToken
                            else
                                Result := ErrorAtToken(RightSquareBracketExpectedStr);
                        end;
                    end;
                end
                else
                    Result := ErrorAtToken(RightSquareBracketExpectedStr);
            end;
            else
                AParsed := False;
        end; { case }
    end
    else
        AParsed := False;
    
LBL_END:
    
    EraseASTBranch(AuxBranch);
    
end;

function TParser.__ParseListConsPatternPosibility(var ABranch: TAbstractSyntaxTree; var AParsed: Boolean): Word;

LABEL LBL_END;

var
    SEP: Boolean;
    AuxBranch: TAbstractSyntaxTree;
    
begin
    
    ABranch := nil;
    AuxBranch := nil;
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if TokenInLayout then begin
        Result := __ParsePatternTerm(ABranch, AParsed);
        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
        if (Result = FX_RES_SUCCESS) and AParsed then begin
            if TokenInLayout and (Tkn^.Kind = FX_TK_KS_PUSH_LIST) then begin
                MakeHeadASTBranch(FX_ASTN_LIST_CONSTRUCTOR, AuxBranch);
                AddASTBranchChilds(AuxBranch, 2);
                AuxBranch^.Childs[0] := ABranch;
                ABranch := AuxBranch;
                AuxBranch := nil;
                ReadNextToken;
                if TokenInLayout then begin
                    Result := __ParseListConsPatternPosibility(ABranch^.Childs[1], SEP);
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    if Result = FX_RES_SUCCESS then begin
                        if not SEP then
                            Result := ErrorAtToken(PatternExpectedStr);
                    end;
                end
                else
                    Result := ErrorAtToken(PatternExpectedStr);
            end;
        end;
    end
    else
        AParsed := False;
    
LBL_END:
    
    EraseASTBranch(AuxBranch);
    
end;

function TParser.__ParsePatternExpression(var ABranch: TAbstractSyntaxTree; var AParsed: Boolean): Word;
begin
    ABranch := nil;
    Result := FX_RES_SUCCESS;
    Result := __ParseListConsPatternPosibility(ABranch, AParsed);
end;

function TParser.__ParseStatement(var ABranch: TAbstractSyntaxTree; var AParsed: Boolean): Word;
    
LABEL LBL_END;
    
var
    K, L: Integer;
    SEK: Byte;
    SEP: Boolean;
    AuxBranch: TAbstractSyntaxTree;
    
begin
    
    ABranch := nil;
    AuxBranch := nil;
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if TokenInLayout then begin
        AParsed := True;
        case Tkn^.Kind of
            FX_TK_KW_IF: begin
                MakeHeadASTBranch(FX_ASTN_IF, ABranch);
                LayoutAtToken;
                ReadNextToken;
                AddASTBranchChilds(ABranch, 2);
                L := 0;
                Result := __ParseValueExpression(ABranch^.Childs[L], SEK);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                Inc(L);
                if Result = FX_RES_SUCCESS then begin
                    if SEK <> FX_VEK_EMPTY then begin
                        if TokenInLayout and (Tkn^.Kind = FX_TK_KW_THEN) then begin
                            ReadNextToken;
                            
                            MakeHeadASTBranch(FX_ASTN_UNTITLED, ABranch^.Childs[L]);
                            K := 0;
                            while (Result = FX_RES_SUCCESS) and TokenInLayout do begin
                                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                AddASTBranchChilds(ABranch^.Childs[L]);
                                Result := __ParseStatement(ABranch^.Childs[L]^.Childs[K], SEP);
                                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                if (Result = FX_RES_SUCCESS) and (not SEP) then begin
                                    SetLength(ABranch^.Childs[L]^.Childs, K);
                                    Break;
                                end;
                                Inc(K);
                            end;
                            Inc(L);
                            
                            while (Result = FX_RES_SUCCESS) and (TokenInLayout or TokenOnLayout) and (Tkn^.Kind = FX_TK_KW_ELIF) do begin
                                ReadNextToken;
                                
                                AddASTBranchChilds(ABranch, 2);
                                Result := __ParseValueExpression(ABranch^.Childs[L], SEK);
                                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                Inc(L);
                                if Result = FX_RES_SUCCESS then begin
                                    if SEK <> FX_VEK_EMPTY then begin
                                        if TokenInLayout and (Tkn^.Kind = FX_TK_KW_THEN) then begin
                                            ReadNextToken;
                                            
                                            MakeHeadASTBranch(FX_ASTN_UNTITLED, ABranch^.Childs[L]);
                                            K := 0;
                                            while (Result = FX_RES_SUCCESS) and TokenInLayout do begin
                                                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                                AddASTBranchChilds(ABranch^.Childs[L]);
                                                Result := __ParseStatement(ABranch^.Childs[L]^.Childs[K], SEP);
                                                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                                if (Result = FX_RES_SUCCESS) and (not SEP) then begin
                                                    SetLength(ABranch^.Childs[L]^.Childs, K);
                                                    Break;
                                                end;
                                                Inc(K);
                                            end;
                                            Inc(L);
                                        end
                                        else
                                            Result := ErrorAtToken(KeywordTHENExpectedStr);
                                    end
                                    else
                                        Result := ErrorAtToken(ValueExpressionExpectedStr);
                                end;
                            end;
                            
                            if (Result = FX_RES_SUCCESS) and (TokenInLayout or TokenOnLayout) and (Tkn^.Kind = FX_TK_KW_ELSE) then begin
                                AddASTBranchChilds(ABranch);
                                MakeHeadASTBranch(FX_ASTN_UNTITLED, ABranch^.Childs[L]);
                                ReadNextToken;
                                K := 0;
                                while (Result = FX_RES_SUCCESS) and TokenInLayout do begin
                                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                    AddASTBranchChilds(ABranch^.Childs[L]);
                                    Result := __ParseStatement(ABranch^.Childs[L]^.Childs[K], SEP);
                                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                    if (Result = FX_RES_SUCCESS) and (not SEP) then begin
                                        SetLength(ABranch^.Childs[L]^.Childs, K);
                                        Break;
                                    end;
                                    Inc(K);
                                end;
                                Inc(L);
                            end;
                            
                        end
                        else
                            Result := ErrorAtToken(KeywordTHENExpectedStr);
                    end
                    else
                        Result := ErrorAtToken(ValueExpressionExpectedStr);
                end;
                RemoveLayout;
            end;
            FX_TK_KW_WHILE: begin
                MakeHeadASTBranch(FX_ASTN_WHILE, ABranch);
                LayoutAtToken;
                ReadNextToken;
                AddASTBranchChilds(ABranch, 2);
                Result := __ParseValueExpression(ABranch^.Childs[0], SEK);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                if Result = FX_RES_SUCCESS then begin
                    if SEK <> FX_VEK_EMPTY then begin
                        if TokenInLayout and (Tkn^.Kind = FX_TK_KW_DO) then begin
                            ReadNextToken;
                            
                            MakeHeadASTBranch(FX_ASTN_UNTITLED, ABranch^.Childs[1]);
                            K := 0;
                            while (Result = FX_RES_SUCCESS) and TokenInLayout do begin
                                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                AddASTBranchChilds(ABranch^.Childs[1]);
                                Result := __ParseStatement(ABranch^.Childs[1]^.Childs[K], SEP);
                                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                if (Result = FX_RES_SUCCESS) and (not SEP) then begin
                                    SetLength(ABranch^.Childs[1]^.Childs, K);
                                    Break;
                                end;
                                Inc(K);
                            end;
                            
                        end
                        else
                            Result := ErrorAtToken(KeywordDOExpectedStr);
                    end
                    else
                        Result := ErrorAtToken(ValueExpressionExpectedStr);
                end;
                RemoveLayout;
            end;
            FX_TK_KW_FOR: begin
                MakeHeadASTBranch(FX_ASTN_FOR, ABranch);
                LayoutAtToken;
                ReadNextToken;
                AddASTBranchChilds(ABranch, 3);
                Result := __ParsePatternExpression(ABranch^.Childs[0], SEP);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                if Result = FX_RES_SUCCESS then begin
                    if SEP then begin
                        if TokenInLayout and (Tkn^.Kind = FX_TK_KW_IN) then begin
                            ReadNextToken;
                            if TokenInLayout then begin
                                Result := __ParseValueExpression(ABranch^.Childs[1], SEK);
                                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                if Result = FX_RES_SUCCESS then begin
                                    if SEK <> FX_VEK_EMPTY then begin
                                        if TokenInLayout and (Tkn^.Kind = FX_TK_KW_DO) then begin
                                            ReadNextToken;
                                            
                                            MakeHeadASTBranch(FX_ASTN_UNTITLED, ABranch^.Childs[2]);
                                            K := 0;
                                            while (Result = FX_RES_SUCCESS) and TokenInLayout do begin
                                                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                                AddASTBranchChilds(ABranch^.Childs[2]);
                                                Result := __ParseStatement(ABranch^.Childs[2]^.Childs[K], SEP);
                                                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                                if (Result = FX_RES_SUCCESS) and (not SEP) then begin
                                                    SetLength(ABranch^.Childs[2]^.Childs, K);
                                                    Break;
                                                end;
                                                Inc(K);
                                            end;
                                            
                                        end
                                        else
                                            Result := ErrorAtToken(KeywordDOExpectedStr);
                                    end
                                    else
                                        Result := ErrorAtToken(ValueExpressionExpectedStr);
                                end;
                            end
                            else
                                Result := ErrorAtToken(ValueExpressionExpectedStr);
                        end
                        else
                            Result := ErrorAtToken(KeywordINExpectedStr);
                    end
                    else
                        Result := ErrorAtToken(PatternExpectedStr);
                end;
                RemoveLayout;
            end;
            FX_TK_KW_RETURN: begin
                MakeHeadASTBranch(FX_ASTN_RETURN, ABranch);
                LayoutAtToken;
                ReadNextToken;
                AddASTBranchChilds(ABranch, 1);
                Result := __ParseValueExpression(ABranch^.Childs[0], SEK);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                if Result = FX_RES_SUCCESS then begin
                    if SEK = FX_VEK_EMPTY then
                        Result := ErrorAtToken(ValueExpressionExpectedStr);
                end;
                RemoveLayout;
            end;
            else { call eval or assignment } begin
                if TokenInLayout then begin
                    LayoutAtToken;
                    
                    Result := __ParseValueExpression(ABranch, SEK);
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    if Result = FX_RES_SUCCESS then begin
                        if SEK = FX_VEK_EMPTY then
                            AParsed := False
                        else if SEK <= FX_VEK_PATTERN then begin
                            if TokenInLayout and (Tkn^.Kind = FX_TK_KS_LEFT_ARROW) then begin
                                { assignment }
                                ReadNextToken;
                                
                                MakeHeadASTBranch(FX_ASTN_ASSIGNMENT, AuxBranch);
                                AddASTBranchChilds(AuxBranch, 2);
                                AuxBranch^.Childs[0] := ABranch;
                                ABranch := AuxBranch;
                                AuxBranch := nil;
                                Result :=  __ParseValueExpression(ABranch^.Childs[1], SEK);
                                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                if Result = FX_RES_SUCCESS then begin
                                    if SEK = FX_VEK_EMPTY then
                                        Result := ErrorAtToken(ValueExpressionExpectedStr);
                                end;
                                
                            end;
                            { else call eval }
                        end
                        else begin
                            { call eval }
                        end;
                    end;
                    RemoveLayout;
                end
                else
                    AParsed := False;
            end;
        end;
    end
    else
        AParsed := False;
    
LBL_END:
    
    EraseASTBranch(AuxBranch);
    
end;

function TParser.__ParseQualifier(var ABranch: TAbstractSyntaxTree; var AQKind: Byte): Word;

LABEL LBL_END;
    
var
    SEK: Byte;
    SEP: Boolean;
    AuxBranch: TAbstractSyntaxTree;
    
begin
    
    ABranch := nil;
    AuxBranch := nil;
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if TokenInLayout then begin
        AQKind := FX_VQK_FILTER;
        Result := __ParseValueExpression(ABranch, SEK);
        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
        if Result = FX_RES_SUCCESS then begin
            if SEK = FX_VEK_EMPTY then begin
                AQKind := FX_VQK_EMPTY;
            end
            else if SEK <= FX_VEK_PATTERN then begin
                if TokenInLayout and (Tkn^.Kind = FX_TK_KS_POP_LIST) then begin
                    ReadNextToken;
                    AQKind := FX_VQK_GENERATOR;
                    MakeHeadASTBranch(FX_ASTN_LIST_GENERATOR, AuxBranch);
                    AddASTBranchChilds(AuxBranch, 2);
                    AuxBranch^.Childs[0] := ABranch;
                    ABranch := AuxBranch;
                    AuxBranch := nil;
                    Result :=  __ParseValueExpression(ABranch^.Childs[1], SEK);
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    if Result = FX_RES_SUCCESS then begin
                        if SEK = FX_VEK_EMPTY then
                            Result := ErrorAtToken(ValueExpressionExpectedStr);
                    end;
                end;
            end
            else begin
                { filter }
                AQKind := FX_VQK_FILTER;
            end;
        end;
    end
    else
        AQKind := FX_VQK_EMPTY;
    
LBL_END:
    
    EraseASTBranch(AuxBranch);
    
end;

function TParser.__ParseAssignment(var ABranch: TAbstractSyntaxTree; var AParsed: Boolean): Word;
    
LABEL LBL_END;
    
var
    SEK: Byte;
    SEP: Boolean;
    AuxBranch: TAbstractSyntaxTree;
    
begin
    
    ABranch := nil;
    AuxBranch := nil;
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if TokenInLayout then begin
        AParsed := True;
        LayoutAtToken;
        MakeHeadASTBranch(FX_ASTN_ASSIGNMENT, ABranch);
        AddASTBranchChilds(ABranch, 2);   //&&
        Result := __ParsePatternExpression(ABranch^.Childs[0], AParsed);
        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
        if Result = FX_RES_SUCCESS then begin
            if AParsed then begin
                if TokenInLayout and (Tkn^.Kind = FX_TK_KS_LEFT_ARROW) then begin
                    ReadNextToken;
                    if TokenInLayout then begin
                        Result := __ParseValueExpression(ABranch^.Childs[1], SEK);
                        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                        if Result = FX_RES_SUCCESS then begin
                            if SEK = FX_VEK_EMPTY then
                                Result := ErrorAtToken(ValueExpressionExpectedStr);
                        end;
                    end
                    else
                        Result := ErrorAtToken(ValueExpressionExpectedStr);
                end
                else
                    Result := ErrorAtToken(LeftArrowExpectedStr);
            end;
        end;
        RemoveLayout;
    end
    else
        AParsed := False;
    
LBL_END:
    
    EraseASTBranch(AuxBranch);
    
end;

function TParser.__ParseAppTermPreIndex(var ABranch: TAbstractSyntaxTree; var AEKind: Byte): Word;
    
LABEL LBL_END;
    
var
    K, I: Integer;
    SEK: Byte;
    SEP: Boolean;
    AuxBranch: TAbstractSyntaxTree;
    
begin

    ABranch := nil;
    AuxBranch := nil;
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if TokenInLayout then begin
        AEKind := FX_VEK_EMPTY;
        case Tkn^.Kind of
            FX_TK_NUMBER : begin
                MakeNumberASTBranch(Tkn^.nValue, ABranch);
                ReadNextToken;
                AEKind := FX_VEK_PATTERN;
            end;
            FX_TK_CHARACTER         : begin
                MakeCharASTBranch(Tkn^.cValue, ABranch);
                ReadNextToken;
                AEKind := FX_VEK_PATTERN;
            end;
            FX_TK_KW_TRUE: begin
                MakeBoolASTBranch(True, ABranch);
                ReadNextToken;
                AEKind := FX_VEK_PATTERN;
            end;
            FX_TK_KW_FALSE: begin
                MakeBoolASTBranch(False, ABranch);
                ReadNextToken;
                AEKind := FX_VEK_PATTERN;
            end;
            FX_TK_KW_FAIL: begin
                MakeHeadASTBranch(FX_ASTN_FAIL, ABranch);
                ReadNextToken;
                AEKind := FX_VEK_PATTERN;
            end;
            FX_TK_STRING            : begin
                MakeStrASTBranch(Tkn^.sValue^, ABranch);
                ReadNextToken;
                AEKind := FX_VEK_PATTERN;
            end;
            FX_TK_KW_ANONYMOUS      : begin
                MakeHeadASTBranch(FX_ASTN_ANONYMOUS, ABranch);
                ReadNextToken;
                AEKind := FX_VEK_PATTERN;
            end;
            FX_TK_KW_NAN : begin
                MakeNumberASTBranch(NaN, ABranch);
                ReadNextToken;
                AEKind := FX_VEK_PATTERN;
            end;
            FX_TK_KW_INF : begin
                MakeNumberASTBranch(INF, ABranch);
                ReadNextToken;
                AEKind := FX_VEK_PATTERN;
            end;
            FX_TK_IDENTIFIER : begin
                MakeIdentifierASTBranch(Tkn^.IdCode, Tkn^.Line, ABranch);
                ReadNextToken;
                AEKind := FX_VEK_IDENTIFIER;
                if TokenInLayout and (Tkn^.Kind = FX_TK_KS_COLON) then begin
                    AEKind := FX_VEK_PATTERN;
                    MakeHeadASTBranch(FX_ASTN_TYPING, AuxBranch);
                    AddASTBranchChilds(AuxBranch, 2);
                    AuxBranch^.Childs[0] := ABranch;
                    ABranch := AuxBranch;
                    AuxBranch := nil;
                    
                    ReadNextToken;
                    Result := __ParseTypeExpression(ABranch^.Childs[1], SEP);
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    if Result = FX_RES_SUCCESS then begin
                        if not SEP then
                            Result := ErrorAtToken(TypeExpressionExpectedStr);
                    end;
                end;
            end;
            FX_TK_PRIMITIVE: begin
                MakePrimASTBranch(Tkn^.IdCode, Tkn^.Line, ABranch);
                ReadNextToken;
                AEKind := FX_VEK_COMPLETE;
            end;
            FX_TK_KS_LAMBDA: begin
                MakeHeadASTBranch(FX_ASTN_LAMBDA, ABranch);
                ReadNextToken;
                AEKind := FX_VEK_COMPLETE;
                if TokenInLayout then begin
                    AddASTBranchChilds(ABranch);
                    K := 0;
                    Result := __ParsePatternExpression(ABranch^.Childs[K], SEP);
                    Inc(K);
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    if Result = FX_RES_SUCCESS then begin
                        if SEP then begin
                            while (Result = FX_RES_SUCCESS) and TokenInLayout and (Tkn^.Kind <> FX_TK_KS_RIGHT_ARROW) do begin
                                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                AddASTBranchChilds(ABranch);
                                Result := __ParsePatternExpression(ABranch^.Childs[K], SEP);
                                Inc(K);
                                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                if (Result = FX_RES_SUCCESS) and (not SEP) then
                                    Result := ErrorAtToken(RightArrowExpectedStr);
                            end;
                            if Result = FX_RES_SUCCESS then begin
                                if TokenInLayout and (Tkn^.Kind = FX_TK_KS_RIGHT_ARROW) then begin
                                    ReadNextToken;
                                    if TokenInLayout then begin
                                        AddASTBranchChilds(ABranch);
                                        Result := __ParseValueExpression(ABranch^.Childs[K], SEK);
                                        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                        if Result = FX_RES_SUCCESS then begin
                                            if (SEK = FX_VEK_EMPTY) then
                                                Result := ErrorAtToken(ValueExpressionExpectedStr);
                                        end;
                                    end
                                    else
                                        Result := ErrorAtToken(ValueExpressionExpectedStr);
                                end
                                else
                                    Result := ErrorAtToken(RightArrowExpectedStr);
                            end;
                        end
                        else
                            Result := ErrorAtToken(PatternExpectedStr);
                    end;
                end
                else
                    Result := ErrorAtToken(PatternExpectedStr);
            end;
            FX_TK_LEFT_PARENTHESIS: begin
                MakeHeadASTBranch(FX_ASTN_TUPLE, ABranch);
                ReadNextToken;
                AEKind := FX_VEK_PATTERN;
                if TokenInLayout then begin
                    K := 0;
                    AddASTBranchChilds(ABranch);
                    Result := __ParseValueExpression(ABranch^.Childs[K], SEK);
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    if SEK = FX_VEK_APPPATTERN then
                        AEKind := FX_VEK_APPPATTERN
                    else if SEK > FX_VEK_APPPATTERN then
                        AEKind := FX_VEK_COMPLETE;
                    if Result = FX_RES_SUCCESS then begin
                        if SEK <> FX_VEK_EMPTY then begin
                            while (Result = FX_RES_SUCCESS) and TokenInLayout and (Tkn^.Kind = FX_TK_COMMA) do begin
                                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                ReadNextToken;
                                Inc(K);
                                AddASTBranchChilds(ABranch);
                                Result := __ParseValueExpression(ABranch^.Childs[K], SEK);
                                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                if AEKind > FX_VEK_PATTERN then
                                    AEKind := FX_VEK_COMPLETE
                                else if SEK > FX_VEK_PATTERN then
                                    AEKind := FX_VEK_COMPLETE;
                                if (Result = FX_RES_SUCCESS) and (SEK = FX_VEK_EMPTY) then
                                    Result := ErrorAtToken(ValueExpressionExpectedStr);
                            end;
                        end
                        else
                            ABranch^.Childs := nil;
                        if Result = FX_RES_SUCCESS then begin
                            if TokenInLayout and (Tkn^.Kind = FX_TK_RIGHT_PARENTHESIS) then
                                ReadNextToken
                            else
                                Result := ErrorAtToken(RightParenthesisExpectedStr);
                        end;
                    end;
                end
                else
                    Result := ErrorAtToken(RightParenthesisExpectedStr);
            end;
            FX_TK_LEFT_SQUAREBRACKET: begin
                MakeHeadASTBranch(FX_ASTN_LIST, ABranch);
                ReadNextToken;
                AEKind := FX_VEK_PATTERN;
                if TokenInLayout then begin
                    K := 0;
                    AddASTBranchChilds(ABranch);
                    Result := __ParseValueExpression(ABranch^.Childs[K], SEK);
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    if SEK > AEKind then AEKind := FX_VEK_COMPLETE;
                    if Result = FX_RES_SUCCESS then begin
                        
                        if SEK <> FX_VEK_EMPTY then begin
                            if TokenInLayout then begin
                                if Tkn^.Kind = FX_TK_COMMA then begin
                                    ReadNextToken;
                                    Inc(K);
                                    AddASTBranchChilds(ABranch);
                                    Result := __ParseValueExpression(ABranch^.Childs[K], SEK);
                                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                    if SEK > AEKind then AEKind := FX_VEK_COMPLETE;
                                    if Result = FX_RES_SUCCESS then begin
                                        if SEK <> FX_VEK_EMPTY then begin
                                            if TokenInLayout then begin
                                                if Tkn^.Kind = FX_TK_COMMA then begin
                                                    { Single list }
                                                    while (Result = FX_RES_SUCCESS) and TokenInLayout and (Tkn^.Kind = FX_TK_COMMA) do begin
                                                        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                                        ReadNextToken;
                                                        Inc(K);
                                                        AddASTBranchChilds(ABranch);
                                                        Result := __ParseValueExpression(ABranch^.Childs[K], SEK);
                                                        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                                        if SEK > AEKind then AEKind := FX_VEK_COMPLETE;
                                                        if (Result = FX_RES_SUCCESS) and (SEK = FX_VEK_EMPTY) then
                                                            Result := ErrorAtToken(ValueExpressionExpectedStr);
                                                    end;
                                                end
                                                else if Tkn^.Kind = FX_TK_KS_DOTDOT then begin
                                                    { List secuence with step }
                                                    ABranch^.Kind := FX_ASTN_LIST_SECUENCE;
                                                    AEKind := FX_VEK_COMPLETE;
                                                    ReadNextToken;
                                                    Inc(K);
                                                    AddASTBranchChilds(ABranch);
                                                    Result := __ParseValueExpression(ABranch^.Childs[K], SEK);
                                                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                                    if Result = FX_RES_SUCCESS then begin
                                                        if SEK = FX_VEK_EMPTY then
                                                            Result := ErrorAtToken(ValueExpressionExpectedStr);
                                                    end;
                                                end;
                                            end;
                                        end
                                        else
                                            Result := ErrorAtToken(ValueExpressionExpectedStr);
                                    end;
                                end
                                else if Tkn^.Kind = FX_TK_KS_BAR then begin
                                    { List comprehension }
                                    ABranch^.Kind := FX_ASTN_LIST_COMPREHENSION;
                                    AEKind := FX_VEK_COMPLETE;
                                    ReadNextToken;
                                    Inc(K);
                                    AddASTBranchChilds(ABranch);
                                    Result := __ParseQualifier(ABranch^.Childs[K], SEK);
                                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                    if Result = FX_RES_SUCCESS then begin
                                        if SEK <> FX_VQK_EMPTY then begin
                                            while (Result = FX_RES_SUCCESS) and TokenInLayout and (Tkn^.Kind = FX_TK_COMMA) do begin
                                                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                                ReadNextToken;
                                                Inc(K);
                                                AddASTBranchChilds(ABranch);
                                                Result := __ParseQualifier(ABranch^.Childs[K], SEK);
                                                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                                if (Result = FX_RES_SUCCESS) and (SEK = FX_VQK_EMPTY) then
                                                    Result := ErrorAtToken(QualifierExpectedStr);
                                            end;
                                        end
                                        else
                                            SetLength(ABranch^.Childs, 1);
                                    end;
                                end
                                else if Tkn^.Kind = FX_TK_KS_DOTDOT then begin
                                    { List secuence }
                                    ABranch^.Kind := FX_ASTN_LIST_SECUENCE;
                                    AEKind := FX_VEK_COMPLETE;
                                    ReadNextToken;
                                    Inc(K);
                                    AddASTBranchChilds(ABranch);
                                    Result := __ParseValueExpression(ABranch^.Childs[K], SEK);
                                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                    if Result = FX_RES_SUCCESS then begin
                                        if SEK = FX_VEK_EMPTY then
                                            Result := ErrorAtToken(ValueExpressionExpectedStr);
                                    end;
                                end;
                            end;
                        end
                        else
                            ABranch^.Childs := nil;
                        
                        if Result = FX_RES_SUCCESS then begin
                            if TokenInLayout and (Tkn^.Kind = FX_TK_RIGHT_SQUAREBRACKET) then
                                ReadNextToken
                            else
                                Result := ErrorAtToken(RightSquareBracketExpectedStr);
                        end;
                    end;
                end
                else
                    Result := ErrorAtToken(RightSquareBracketExpectedStr);
            end;
            FX_TK_KW_LET: begin
                MakeHeadASTBranch(FX_ASTN_LET, ABranch);
                ReadNextToken;
                AEKind := FX_VEK_COMPLETE;
                if TokenInLayout then begin
                    AddASTBranchChilds(ABranch, 2);
                    Result := __ParseAssignment(ABranch^.Childs[0], SEP);
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    if Result = FX_RES_SUCCESS then begin
                        if SEP then begin
                            if TokenInLayout and (Tkn^.Kind = FX_TK_KW_IN) then begin
                                ReadNextToken;
                                if TokenInLayout then begin
                                    Result := __ParseValueExpression(ABranch^.Childs[1], SEK);
                                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                    if Result = FX_RES_SUCCESS then begin
                                        if SEK = FX_VEK_EMPTY then
                                            Result := ErrorAtToken(ValueExpressionExpectedStr);
                                    end;
                                end
                                else
                                    Result := ErrorAtToken(ValueExpressionExpectedStr);
                            end
                            else
                                Result := ErrorAtToken(KeywordINExpectedStr);
                        end
                        else
                            Result := ErrorAtToken(AssignmentExpectedStr);
                    end;
                end
                else
                    Result := ErrorAtToken(AssignmentExpectedStr);
            end;
            FX_TK_KW_BEGIN: begin
                // TODO:
                // no detecta bien una entrada de tipo
                //
                // begin
                // end
                //
                // aunque en realidad es una caracteristica del lenguaje
                //
                MakeHeadASTBranch(FX_ASTN_IMPERATIVE, ABranch);
                // LayoutAtToken; // no usar esto por que al quitar el trazado puede eliminarse
                //                // tambien el trazado anterior
                ReadNextToken;
                AEKind := FX_VEK_COMPLETE;
                K := 0;
                while (Result = FX_RES_SUCCESS) and TokenInLayout do begin
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    AddASTBranchChilds(ABranch);
                    Result := __ParseStatement(ABranch^.Childs[K], SEP);
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    if (Result = FX_RES_SUCCESS) and (not SEP) then begin
                        SetLength(ABranch^.Childs, K);
                        Break;
                    end;
                    Inc(K);
                end;
                if Result = FX_RES_SUCCESS then begin
                    if (TokenInLayout {or TokenOnLayout}) and (Tkn^.Kind = FX_TK_KW_END) then
                        ReadNextToken
                    else
                        Result := ErrorAtToken(KeywordENDExpectedStr);
                end;
                // RemoveLayout; // no usar esto(la explicacion arriba)
            end;
            else
                AEKind := FX_VEK_EMPTY;
        end; { case }
    end
    else
        AEKind := FX_VEK_EMPTY;
    
LBL_END:
    
    EraseASTBranch(AuxBranch);
    
end;

function TParser.__ParseIndexPartPosibilityTail(var ABranch: TAbstractSyntaxTree; var AEKind: Byte): Word;
    
LABEL LBL_END;
    
var
    K: Integer;
    SEK: Byte;
    AuxBranch: TAbstractSyntaxTree;
    
begin

    AuxBranch := nil;
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;

    if TokenInLayout and (Tkn^.Kind = FX_TK_LEFT_CURLYBRACKET) then begin
        AEKind := FX_VEK_COMPLETE;
        MakeHeadASTBranch(FX_ASTN_INDEX, AuxBranch);
        AddASTBranchChilds(AuxBranch, 2);
        AuxBranch^.Childs[0] := ABranch;
        ABranch := AuxBranch;
        AuxBranch := nil;
        ReadNextToken;
        
        MakeHeadASTBranch(FX_ASTN_UNTITLED, ABranch^.Childs[1]);
        if TokenInLayout then begin
            K := 0;
            AddASTBranchChilds(ABranch^.Childs[1]);
            Result := __ParseValueExpression(ABranch^.Childs[1]^.Childs[K], SEK);
            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            if Result = FX_RES_SUCCESS then begin
                if SEK <> FX_VEK_EMPTY then begin
                    while (Result = FX_RES_SUCCESS) and TokenInLayout and (Tkn^.Kind = FX_TK_COMMA) do begin
                        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                        ReadNextToken;
                        Inc(K);
                        AddASTBranchChilds(ABranch^.Childs[1]);
                        Result := __ParseValueExpression(ABranch^.Childs[1]^.Childs[K], SEK);
                        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                        if (Result = FX_RES_SUCCESS) and (SEK = FX_VEK_EMPTY) then
                            Result := ErrorAtToken(ValueExpressionExpectedStr);
                    end;
                end
                else
                    ABranch^.Childs[1]^.Childs := nil;
                if Result = FX_RES_SUCCESS then begin
                    if TokenInLayout and (Tkn^.Kind = FX_TK_RIGHT_CURLYBRACKET) then
                        ReadNextToken
                    else
                        Result := ErrorAtToken(RightCurlyBracketExpectedStr);
                end;
            end;
        end
        else
            Result := ErrorAtToken(RightCurlyBracketExpectedStr);
        if Result = FX_RES_SUCCESS then begin
            Result := __ParseIndexPartPosibilityTail(ABranch, SEK);
            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
        end;
    end
    else
        AEKind := FX_VEK_EMPTY;
    
LBL_END:

    EraseASTBranch(AuxBranch);

end;

function TParser.__ParseAppTerm(var ABranch: TAbstractSyntaxTree; var AEKind: Byte): Word;

LABEL LBL_END;

var
    SEK: Byte;
    AuxBranch: TAbstractSyntaxTree;
    
begin
    
    ABranch := nil;
    AuxBranch := nil;
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if TokenInLayout then begin
        Result := __ParseAppTermPreIndex(ABranch, AEKind);
        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
        if (Result = FX_RES_SUCCESS) and (AEKind <> FX_VEK_EMPTY) then begin
            Result := Self.__ParseIndexPartPosibilityTail(ABranch, SEK);
            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
        end;
    end
    else
        AEKind := FX_VEK_EMPTY;
    
LBL_END:
    
    EraseASTBranch(AuxBranch);
    
end;

function TParser.__ParseApplication(var ABranch: TAbstractSyntaxTree; var AEKind: Byte): Word;

LABEL LBL_END;

var
    SEK: Byte;
    AuxBranch: TAbstractSyntaxTree;
    AppTermForest: TAbstractSyntaxTreeList;
    
begin
    
    ABranch := nil;
    AuxBranch := nil;
    Result := FX_RES_SUCCESS;
    AppTermForest := TAbstractSyntaxTreeList.Create;
    
    AEKind := FX_VEK_EMPTY;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    while TokenInLayout do begin
        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
        Result := __ParseAppTerm(AuxBranch, SEK);
        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
        if (Result = FX_RES_SUCCESS) and (SEK <> FX_VEK_EMPTY) then begin

            AppTermForest.Add(AuxBranch, SEK);
            AuxBranch := nil;
        end
        else
            Break;
    end;
    if (Result = FX_RES_SUCCESS) and (AppTermForest.Count > 0) then begin
        // verificar si es un numero con signo(para evitar aplicaciones innecesarias y detectar patrones con signo)
        if  (AppTermForest.Count = 2) and
            (AppTermForest.List[0]^.Kind = FX_ASTN_IDENTIFIER) and
            (IsMinusPlusIdent(AppTermForest.List[0]^.D.IdCode)) and
            (AppTermForest.List[1]^.Kind = FX_ASTN_NUMBER) then begin
            ABranch := AppTermForest.List[1];
            AppTermForest.List[1] := nil;
            if IsMinusIdent(AppTermForest.List[0]^.D.IdCode) then ABranch^.D.nValue := fxMath.nNeg(ABranch^.D.nValue);
            AEKind := FX_VEK_PATTERN;
        end
        else begin
            Result := __AppTermForestToApplication(AppTermForest, ABranch, AEKind);
            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
        end;
    end;
    
LBL_END:

    EraseASTBranch(AuxBranch);
    AppTermForest.Free;
    
end;

function TParser.__ParseListConsExprPosibility(var ABranch: TAbstractSyntaxTree; var AEKind: Byte): Word;

LABEL LBL_END;

var
    SEK: Byte;
    AuxBranch: TAbstractSyntaxTree;
    
begin
    
    ABranch := nil;
    AuxBranch := nil;
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if TokenInLayout then begin
        Result := __ParseApplication(ABranch, AEKind);
        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
        if (Result = FX_RES_SUCCESS) and (AEKind <> FX_VEK_EMPTY) then begin
            if TokenInLayout and (Tkn^.Kind = FX_TK_KS_PUSH_LIST) then begin
                MakeHeadASTBranch(FX_ASTN_LIST_CONSTRUCTOR, AuxBranch);
                AddASTBranchChilds(AuxBranch, 2);
                AuxBranch^.Childs[0] := ABranch;
                ABranch := AuxBranch;
                AuxBranch := nil;
                ReadNextToken;
                if TokenInLayout then begin
                    Result := __ParseListConsExprPosibility(ABranch^.Childs[1], SEK);
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    if Result = FX_RES_SUCCESS then begin
                        if SEK = FX_VEK_EMPTY then
                            Result := ErrorAtToken(ValueExpressionExpectedStr)
                        else begin
                            case AEKind of
                                FX_VEK_IDENTIFIER:
                                    if SEK > FX_VEK_PATTERN then AEKind := FX_VEK_COMPLETE
                                    else AEKind := FX_VEK_PATTERN;
                                FX_VEK_PATTERN:
                                    if SEK > FX_VEK_PATTERN then AEKind := FX_VEK_COMPLETE;
                                FX_VEK_APPPATTERN: AEKind := FX_VEK_COMPLETE;
                                FX_VEK_COMPLETE:;
                            end;
                        end;
                    end;
                end
                else
                    Result := ErrorAtToken(ValueExpressionExpectedStr);
            end;
        end;
    end
    else
        AEKind := FX_VEK_EMPTY;
    
LBL_END:
    
    EraseASTBranch(AuxBranch);
    
end;

function TParser.__ParseGuardExprPosibility(var ABranch: TAbstractSyntaxTree; var AEKind: Byte): Word;

LABEL LBL_END;

var
    SEK: Byte;
    AuxBranch: TAbstractSyntaxTree;

begin
    
    ABranch := nil;
    AuxBranch := nil;
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if TokenInLayout then begin
        Result := __ParseListConsExprPosibility(ABranch, AEKind);
        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
        if (Result = FX_RES_SUCCESS) and (AEKind <> FX_VEK_EMPTY) then begin
            if TokenInLayout and (Tkn^.Kind = FX_TK_KS_GUARD) then begin
                AEKind := FX_VEK_COMPLETE;
                MakeHeadASTBranch(FX_ASTN_GUARD, AuxBranch);
                AddASTBranchChilds(AuxBranch, 2);
                AuxBranch^.Childs[0] := ABranch;
                ABranch := AuxBranch;
                AuxBranch := nil;
                ReadNextToken;
                if TokenInLayout then begin
                    Result := __ParseGuardExprPosibility(ABranch^.Childs[1], SEK);
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    if Result = FX_RES_SUCCESS then begin
                        if SEK = FX_VEK_EMPTY then
                            Result := ErrorAtToken(ValueExpressionExpectedStr);
                    end;
                end
                else
                    Result := ErrorAtToken(ValueExpressionExpectedStr);
            end;
        end;
    end
    else
        AEKind := FX_VEK_EMPTY;
    
LBL_END:
    
    EraseASTBranch(AuxBranch);
    
end;

function TParser.__ParseTryExprPosibility(var ABranch: TAbstractSyntaxTree; var AEKind: Byte): Word;

LABEL LBL_END;

var
    SEK: Byte;
    AuxBranch: TAbstractSyntaxTree;

begin
    
    ABranch := nil;
    AuxBranch := nil;
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if TokenInLayout then begin
        Result := __ParseGuardExprPosibility(ABranch, AEKind);
        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
        if (Result = FX_RES_SUCCESS) and (AEKind <> FX_VEK_EMPTY) then begin
            if TokenInLayout and (Tkn^.Kind = FX_TK_KS_TRY) then begin
                AEKind := FX_VEK_COMPLETE;
                MakeHeadASTBranch(FX_ASTN_TRY, AuxBranch);
                AddASTBranchChilds(AuxBranch, 2);
                AuxBranch^.Childs[0] := ABranch;
                ABranch := AuxBranch;
                AuxBranch := nil;
                ReadNextToken;
                if TokenInLayout then begin
                    Result := __ParseTryExprPosibility(ABranch^.Childs[1], SEK);
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    if Result = FX_RES_SUCCESS then begin
                        if SEK = FX_VEK_EMPTY then
                            Result := ErrorAtToken(ValueExpressionExpectedStr);
                    end;
                end
                else
                    Result := ErrorAtToken(ValueExpressionExpectedStr);
            end;
        end;
    end
    else
        AEKind := FX_VEK_EMPTY;
        
LBL_END:
    
    EraseASTBranch(AuxBranch);
    
end;

function TParser.__ParseWhereExprPosibilityTail(var ABranch: TAbstractSyntaxTree; var AEKind: Byte): Word;

LABEL LBL_END;

var
    SEK: Byte;
    AuxBranch: TAbstractSyntaxTree;
    SEP: Boolean;

begin

    AuxBranch := nil;
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if TokenInLayout and (Tkn^.Kind = FX_TK_KW_WHERE) then begin
        AEKind := FX_VEK_COMPLETE;
        MakeHeadASTBranch(FX_ASTN_WHERE, AuxBranch);
        AddASTBranchChilds(AuxBranch, 2);
        AuxBranch^.Childs[0] := ABranch;
        ABranch := AuxBranch;
        AuxBranch := nil;
        ReadNextToken;
        if TokenInLayout then begin
            Result := __ParseAssignment(ABranch^.Childs[1], SEP);
            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            if Result = FX_RES_SUCCESS then begin
                if not SEP then
                    Result := ErrorAtToken(AssignmentExpectedStr);
            end;
        end
        else
            Result := ErrorAtToken(AssignmentExpectedStr);
        if Result = FX_RES_SUCCESS then begin
            Result := __ParseWhereExprPosibilityTail(ABranch, SEK);
            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
        end;
    end
    else
        AEKind := FX_VEK_EMPTY;
    
LBL_END:
    
    EraseASTBranch(AuxBranch);
    
end;

function TParser.__ParseWhereExprPosibility(var ABranch: TAbstractSyntaxTree; var AEKind: Byte): Word;

LABEL LBL_END;

var
    SEK: Byte;

begin
    
    ABranch := nil;
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if TokenInLayout then begin
        Result := __ParseTryExprPosibility(ABranch, AEKind);
        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
        if (Result = FX_RES_SUCCESS) and (AEKind <> FX_VEK_EMPTY) then begin
            Result := __ParseWhereExprPosibilityTail(ABranch, SEK);
            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            if (Result = FX_RES_SUCCESS) and (SEK <> FX_VEK_EMPTY) then
                AEKind := FX_VEK_COMPLETE;
        end;
    end
    else
        AEKind := FX_VEK_EMPTY;
    
LBL_END:

end;

function TParser.__ParseValueExpression(var ABranch: TAbstractSyntaxTree; var AEKind: Byte): Word;
begin
    ABranch := nil;
    Result := FX_RES_SUCCESS;
    Result := __ParseWhereExprPosibility(ABranch, AEKind);
end;

function TParser.__ParseTypeExpression(var ABranch: TAbstractSyntaxTree; var AParsed: Boolean): Word;

LABEL LBL_END;

var
    AuxBranch: TAbstractSyntaxTree;
    K: Integer;
    SEP: Boolean;
    
begin
    
    ABranch := nil;
    AuxBranch := nil;
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if TokenInLayout then begin
        AParsed := True;
        case Tkn^.Kind of
            FX_TK_KW_REAL: begin
                MakeHeadASTBranch(FX_ASTN_TYPE_REAL, ABranch);
                ReadNextToken;
            end;
            FX_TK_KW_INT: begin
                MakeHeadASTBranch(FX_ASTN_TYPE_INT, ABranch);
                ReadNextToken;
            end;
            FX_TK_KW_NAT: begin
                MakeHeadASTBranch(FX_ASTN_TYPE_NAT, ABranch);
                ReadNextToken;
            end;
            FX_TK_KW_BOOL: begin
                MakeHeadASTBranch(FX_ASTN_TYPE_BOOL, ABranch);
                ReadNextToken;
            end;
            FX_TK_KW_CHAR: begin
                MakeHeadASTBranch(FX_ASTN_TYPE_CHAR, ABranch);
                ReadNextToken;
            end;
            FX_TK_IDENTIFIER: begin
                MakeIdentifierASTBranch(Tkn^.IdCode, Tkn^.Line, ABranch);
                ReadNextToken;
            end;
            FX_TK_KW_ANONYMOUS: begin
                MakeHeadASTBranch(FX_ASTN_ANONYMOUS, ABranch);
                ReadNextToken;
            end;
            FX_TK_LEFT_PARENTHESIS: begin
                MakeHeadASTBranch(FX_ASTN_TUPLE, ABranch);
                ReadNextToken;
                if TokenInLayout then begin
                    K := 0;
                    AddASTBranchChilds(ABranch);
                    Result := __ParseTypeExpression(ABranch^.Childs[K], SEP);
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    if Result = FX_RES_SUCCESS then begin
                        if SEP then begin
                            while (Result = FX_RES_SUCCESS) and TokenInLayout and (Tkn^.Kind = FX_TK_COMMA) do begin
                                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                ReadNextToken;
                                Inc(K);
                                AddASTBranchChilds(ABranch);
                                Result := __ParseTypeExpression(ABranch^.Childs[K], SEP);
                                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                if (Result = FX_RES_SUCCESS) and (not SEP) then
                                    Result := ErrorAtToken(TypeExpressionExpectedStr);
                            end;
                        end
                        else
                            ABranch^.Childs := nil;
                        if Result = FX_RES_SUCCESS then begin
                            if TokenInLayout and (Tkn^.Kind = FX_TK_RIGHT_PARENTHESIS) then
                                ReadNextToken
                            else
                                Result := ErrorAtToken(RightParenthesisExpectedStr);
                        end;
                    end;
                end
                else
                    Result := ErrorAtToken(RightParenthesisExpectedStr);
            end;
            FX_TK_LEFT_SQUAREBRACKET: begin
                MakeHeadASTBranch(FX_ASTN_LIST, ABranch);
                ReadNextToken;
                if TokenInLayout then begin
                    AddASTBranchChilds(ABranch);
                    Result := __ParseTypeExpression(ABranch^.Childs[0], SEP);
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    if Result = FX_RES_SUCCESS then begin
                        if SEP then begin
                            if TokenInLayout and (Tkn^.Kind = FX_TK_RIGHT_SQUAREBRACKET) then
                                ReadNextToken
                            else
                                Result := ErrorAtToken(RightSquareBracketExpectedStr);
                        end
                        else
                            Result := ErrorAtToken(TypeExpressionExpectedStr);
                    end;
                end
                else
                    Result := ErrorAtToken(TypeExpressionExpectedStr);
            end;
            else
                AParsed := False;
        end;
        if (Result = FX_RES_SUCCESS) and AParsed then begin
            if TokenInLayout and (Tkn^.Kind = FX_TK_KS_RIGHT_ARROW) then begin
                MakeHeadASTBranch(FX_ASTN_FUNCTION, AuxBranch);
                AddASTBranchChilds(AuxBranch, 2);
                AuxBranch^.Childs[0] := ABranch;
                ABranch := AuxBranch;
                AuxBranch := nil;
                
                ReadNextToken;
                if TokenInLayout then begin
                    Result := __ParseTypeExpression(ABranch^.Childs[1], SEP);
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    if Result = FX_RES_SUCCESS then begin
                        if SEP then begin
                            ;
                        end
                        else
                            Result := ErrorAtToken(TypeExpressionExpectedStr);
                    end;
                end
                else
                    Result := ErrorAtToken(TypeExpressionExpectedStr);
            end;
        end;
    end
    else
        AParsed := False;
    
LBL_END:
    
    EraseASTBranch(AuxBranch);
    
end;

function TParser.__ParseTentativeDefEvl(var ABranch: TAbstractSyntaxTree): Word;

LABEL LBL_END;

var
    SEK: Byte;{Sub Expression Kind}
    AuxBranch: TAbstractSyntaxTree;
    
begin

    ABranch := nil;
    AuxBranch := nil;
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    Result := __ParseValueExpression(ABranch, SEK);
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if Result = FX_RES_SUCCESS then begin
        case SEK of
            FX_VEK_EMPTY     :
                if TokenInLayout then
                    Result := ErrorAtToken(UnexpectedTokenStr)
                else
                    Result := ErrorAtToken(ValueExpressionExpectedStr);
            FX_VEK_IDENTIFIER, FX_VEK_PATTERN, FX_VEK_APPPATTERN{, VEK_PATTERN_STRONG}   : begin
                if TokenInLayout then begin
                    if Tkn^.Kind = FX_TK_KS_DEFINITION then begin
                        MakeHeadASTBranch(FX_ASTN_DEFINITION, AuxBranch);
                        AddASTBranchChilds(AuxBranch, 2);
                        AuxBranch^.Childs[0] := ABranch;
                        ABranch := AuxBranch;
                        AuxBranch := nil;
                        ReadNextToken;
                        if TokenInLayout then begin
                            Result := __ParseValueExpression(ABranch^.Childs[1], SEK);
                            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                            if Result = FX_RES_SUCCESS then begin
                                if SEK = FX_VEK_EMPTY then begin
                                    if TokenInLayout then
                                        Result := ErrorAtToken(UnexpectedTokenStr)
                                    else
                                        Result := ErrorAtToken(ValueExpressionExpectedStr);
                                end
                                else
                                    if TokenInLayout then
                                        Result := ErrorAtToken(UnexpectedTokenStr);
                            end;
                        end
                        else
                            Result := ErrorAtToken(ValueExpressionExpectedStr);
                    end
                    else
                        Result := ErrorAtToken(UnexpectedTokenStr);
                end
                else
                    ; // es una evaluacion de valor
            end;
            FX_VEK_COMPLETE  : begin
                if TokenInLayout then
                    Result := ErrorAtToken(UnexpectedTokenStr);
            end;
        end;
    end;
    
    
LBL_END:

    EraseASTBranch(AuxBranch);
    
end;

function TParser.__ParseTentativeSynInhDefAsgEvl(var ABranch: TAbstractSyntaxTree): Word;

LABEL LBL_END;

var
    SEP: Boolean;{Sub Expression Parsed}
    SEK: Byte;
    
begin
    ABranch := nil;
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if Tkn^.Kind = FX_TK_IDENTIFIER then begin
        if Tkn^.Next <> nil then begin
            if Tkn^.Next^.Kind = FX_TK_KS_SYNONYMOUS then begin
                MakeHeadASTBranch(FX_ASTN_SYNONYMOUS, ABranch);
                SetLength(ABranch^.Childs, 2);
                MakeIdentifierASTBranch(Tkn^.IdCode, Tkn^.Line, ABranch^.Childs[0]);
                ReadNextToken;
                ReadNextToken;
                Result := __ParseTypeExpression(ABranch^.Childs[1], SEP);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                if not SEP then
                    Result := ErrorAtToken(TypeExpressionExpectedStr);
            end
            else if Tkn^.Next^.Kind = FX_TK_KS_INHERITABLE then begin
                MakeHeadASTBranch(FX_ASTN_INHERITABLE, ABranch);
                SetLength(ABranch^.Childs, 2);
                MakeIdentifierASTBranch(Tkn^.IdCode, Tkn^.Line, ABranch^.Childs[0]);
                ReadNextToken;
                ReadNextToken;
                Result := __ParseTypeExpression(ABranch^.Childs[1], SEP);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                if not SEP then
                    Result := ErrorAtToken(TypeExpressionExpectedStr);
            end
            else if Tkn^.Next^.Kind = FX_TK_KS_LEFT_ARROW then begin
                MakeHeadASTBranch(FX_ASTN_GLOBAL_ASSIGNMENT, ABranch);
                SetLength(ABranch^.Childs, 2);
                MakeIdentifierASTBranch(Tkn^.IdCode, Tkn^.Line, ABranch^.Childs[0]);
                ReadNextToken;
                ReadNextToken;
                Result := __ParseValueExpression(ABranch^.Childs[1], SEK);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                if SEK = FX_VEK_EMPTY then
                    Result := ErrorAtToken(ValueExpressionExpectedStr);
            end
            else begin
                Result := __ParseTentativeDefEvl(ABranch);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            end;
        end
        else begin
            Result := __ParseTentativeDefEvl(ABranch);
            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
        end;
    end
    else begin
        Result := __ParseTentativeDefEvl(ABranch);
        IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    end;
    if (Result = FX_RES_SUCCESS) and ThereIsToken and TokenInLayout then
        Result := ErrorAtToken(UnexpectedTokenStr);
    
LBL_END:
    
end;

function TParser.__ParseCommand(var ABranch: TAbstractSyntaxTree): Word;

LABEL LBL_END;

label
    LBL_L1, LBL_L2; 

var
    AuxBranch: TAbstractSyntaxTree;
    K: Integer;

begin

    ABranch := nil;
    Result := FX_RES_SUCCESS;
    AuxBranch := nil;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    if ThereIsToken then begin
        LayoutAtToken;
        case Tkn^.Kind of
            FX_TK_KW_RUN: begin
                MakeHeadASTBranch(FX_ASTN_RUN, ABranch);
                AddASTBranchChilds(ABranch);
                ReadNextToken;
                if TokenInLayout then begin
                    if Tkn^.Kind = FX_TK_STRING then begin
                        MakeStrASTBranch(Tkn^.sValue^, ABranch^.Childs[0]);
                        ReadNextToken;
                        if TokenInLayout then
                            Result := ErrorAtToken(UnexpectedTokenStr);
                    end
                    else
                        Result := ErrorAtToken(ScriptPathExpectedStr);
                end
                else
                    Result := ErrorAtToken(ScriptPathExpectedStr);
            end;{ RUN }
            FX_TK_KW_CLEAR: begin
                MakeHeadASTBranch(FX_ASTN_CLEAR, ABranch);
                K := 0;
                ReadNextToken;
                while TokenInLayout do begin
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    if Tkn^.Kind = FX_TK_IDENTIFIER then begin
                        AddASTBranchChilds(ABranch);
                        MakeIdentifierASTBranch(Tkn^.IdCode, Tkn^.Line, ABranch^.Childs[K]);
                        Inc(K);
                        ReadNextToken;
                    end
                    else
                        Result := ErrorAtToken(IdentifierExpectedStr);
                end;
            end;{ CLEAR }
            FX_TK_KW_INFIX: begin
                MakeHeadASTBranch(FX_ASTN_INFIX, ABranch);
                K := 0;
                ReadNextToken;
                LBL_L1:
                if TokenInLayout then begin
                    if Tkn^.Kind = FX_TK_NUMBER then begin
                        if IsPriorityNumber(Tkn^.nValue) then begin
                            AddASTBranchChilds(ABranch);
                            MakeNumberASTBranch(Tkn^.nValue, ABranch^.Childs[K]);
                            Inc(K);
                            ReadNextToken;
                            LBL_L2:
                            while TokenInLayout do begin
                                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                if Tkn^.Kind = FX_TK_IDENTIFIER then begin
                                    AddASTBranchChilds(ABranch);
                                    MakeIdentifierASTBranch(Tkn^.IdCode, Tkn^.Line, ABranch^.Childs[K]);
                                    Inc(K);
                                    ReadNextToken;
                                end
                                else
                                    Result := ErrorAtToken(IdentifierExpectedStr);
                            end;
                        end
                        else
                            ErrorAtToken(InvalidPriorityNumber);
                    end
                    else
                        Result := ErrorAtToken(PriorityNumberExpectedStr);
                end
                else
                    Result := ErrorAtToken(PriorityNumberExpectedStr);
            end; { INFIX; INFIXL, INFIXR, PREFIX, POSFIX }
            FX_TK_KW_INFIXL: begin
                MakeHeadASTBranch(FX_ASTN_INFIXL, ABranch);
                K := 0;
                ReadNextToken;
                goto LBL_L1;
            end; { INFIXL }
            FX_TK_KW_INFIXR: begin
                MakeHeadASTBranch(FX_ASTN_INFIXR, ABranch);
                K := 0;
                ReadNextToken;
                goto LBL_L1;
            end; { INFIXR }
            FX_TK_KW_PREFIX: begin
                MakeHeadASTBranch(FX_ASTN_PREFIX, ABranch);
                K := 0;
                ReadNextToken;
                goto LBL_L2;
            end; { PREFIX }
            FX_TK_KW_POSFIX: begin
                MakeHeadASTBranch(FX_ASTN_POSFIX, ABranch);
                K := 0;
                ReadNextToken;
                goto LBL_L2;
            end; { POSFIX }
            else { Syn, Inh, Def or Evl } begin
                Result := __ParseTentativeSynInhDefAsgEvl(ABranch);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            end; { Syn, Inh, Def, Asg or Evl }
        end;
    end; 
    
LBL_END:
    
    EraseASTBranch(AuxBranch);

end;

//--

function TParser.__Parse(var ATokenList: TTokenList; var AAST: TAbstractSyntaxTree): Word;
var
    SEP: Boolean;
    SEK: Byte;
begin
    Result := FX_RES_SUCCESS;
    AAST := nil;
    Tkn := ATokenList;
    if ThereIsToken then
        PrevLine := Tkn^.Line
    else
        PrevLine := 0;
    LayoutStack.Clear;
    
    Result := __ParseCommand(AAST);
end;

procedure TParser.Interrupt;
begin
    STOP := TRUE;
end;

procedure TParser.Pause;
begin
    SLEEP := TRUE;
end;

procedure TParser.Resume;
begin
    SLEEP := FALSE;
end;

end.





