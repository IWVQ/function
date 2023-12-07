unit fxScanner;

interface

uses
    fxUtils, fxError, fxStorage, fxStrUtils, fxInterpreterUtils, fxPrimFuncUtils,
    fxTokenUtils;

type

    TScanner = class
    private
        
        FrontEnd: IFrontEndListener;
        Interpreter: IInterpreterListener;
        Storage: TStorage;
        Error: TErrorRegister;
        
        LxKind: Byte;
        LxStr: TFxString;
        LxPos: Integer;
        Stream: IStream;

        function ErrorAtLexeme(AMsg: string): Word; overload;
        function ErrorAtLexeme(AMsg: TFxString; const AArgs: array of const): Word; overload;
        procedure AddRestrictedVariables(var ARIV: TRestrictedVariables; ACode: Integer);
        function __FindNextLineStart(APosFrom: Integer): Integer;
        function __StringFromSequence(ASeq: TFxString; var Str: TFxString): Word;
        function __CharFromSequence(ASeq: TFxString; var Ch: TFxChar): Word;
        function __TokenFromLexeme(var Token: TToken; var ARIV: TRestrictedVariables): Word;
        function __ScanCommandTokens(var K: Integer; var ATokenList: TTokenList; var ARIV: TRestrictedVariables): Word;
    protected
        STOP: BOOLEAN;
    public
        constructor Create(AFrontEnd: IFrontEndListener; AInterpreter: IInterpreterListener;
            AStorage: TStorage; AError: TErrorRegister);
        destructor Destroy; override;
        
        function __ScanCommand(var AScanPos: Integer; var AStream: IStream; var ATokenList: TTokenList;
            var ARestrictedInternalVars: TRestrictedVariables): Word;
        procedure Interrupt;
    end;

{
SEQUENCES FOR SYNTAX HIGHLIGHTING:
- literal
- symbol
- hexadecimal
- decimal
- character
- string
- primitives
- keywords
- command keywords(run, ...)
- keysymbols
- command keysymbols(:=, ...)
- braces and commas
- eol
- spaces
- comment
- comment directive
}

implementation

{ TScanner }

constructor TScanner.Create(AFrontEnd: IFrontEndListener; AInterpreter: IInterpreterListener;
    AStorage: TStorage; AError: TErrorRegister);
begin
    inherited Create;
    FrontEnd := AFrontEnd;
    Interpreter := AInterpreter;
    Storage := AStorage;
    Error := AError;
    
    STOP := FALSE;
end;

destructor TScanner.Destroy;
begin
    inherited;
end;

function TScanner.ErrorAtLexeme(AMsg: string): Word;
begin
    Result := ErrorAtLexeme(AMsg, []);
end;

function TScanner.ErrorAtLexeme(AMsg: TFxString; const AArgs: array of const): Word;
begin
    Result := FX_RES_ERR_SINGLE;
    Error.Code := Result;
    Error.Line := Stream.LineFromPos(LxPos);
    Error.Msg := FormatMessage(AMsg, AArgs);
end;

procedure TScanner.AddRestrictedVariables(var ARIV: TRestrictedVariables; ACode: Integer);
var
    K, L: Integer;
    ARIVNew: TRestrictedVariables;
begin
    // este tipo de variables son generados internamente
    // por lo que si se encuentra alguno en la entrada
    // entonces su uso estara restringido
    L := Length(ARIV);
    for K := 0 to L - 1 do
        if ARIV[K] = ACode then Exit;
    SetLength(ARIVNew, L + 1);
    K := 0;
    while (K < L) and (ARIV[K] < ACode) do begin
        ARIVNew[K] := ARIV[K];
        Inc(K);
    end;
    ARIVNew[K] := ACode;
    while (K < L) do begin
        ARIVNew[K + 1] := ARIV[K];
        Inc(K);
    end;
    ARIV := ARIVNew;
end;

function TScanner.__FindNextLineStart(APosFrom: Integer): Integer;

LABEL LBL_END;

var
    CR_Readed: Boolean;
    
begin
    
    Result := APosFrom;
    while Result < Stream.Length do begin
        IF STOP THEN GOTO LBL_END;
        if Stream[Result] = FX_EOL_LF then begin
            Inc(Result);
            Break;
        end
        else if Stream[Result] = FX_EOL_CR then begin
            Inc(Result);
            if Stream[Result] = FX_EOL_LF then
                Inc(Result);
            Break;
        end
        else
            Inc(Result);
    end;
    
LBL_END:
    
end;

function TScanner.__StringFromSequence(ASeq: TFxString; var Str: TFxString): Word;

LABEL LBL_END;

var
    L, K: Integer;
    Ch: TFxChar;
begin
    
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END;
    
    ASeq := System.Copy(ASeq, 2, Length(ASeq) - 2);
    L := Length(ASeq);
    K := 1;
    Str := '';
    while (Result = FX_RES_SUCCESS) and (K <= L) do begin
        IF STOP THEN GOTO LBL_END;
        if ASeq[K] = '\' then begin
            Inc(K);
            if ReadEscapeSequenceAtPos(ASeq, K, L, Ch) then
                Str := Str + Ch
            else
                Result := ErrorAtLexeme(InvalidEscapeSequenceStr, ['\' + ASeq[K]]);
        end
        else begin
            Str := Str + ASeq[K];
            Inc(K)
        end;
    end;

LBL_END:

end;

function TScanner.__CharFromSequence(ASeq: TFxString; var Ch: TFxChar): Word;

LABEL LBL_END;

var
    L, K: Integer;
    
begin
    
    Result := FX_RES_SUCCESS;
    
    IF STOP THEN GOTO LBL_END;
    
    ASeq := System.Copy(ASeq, 2, Length(ASeq) - 2);
    L := Length(ASeq);
    K := 1;
    if L = 0 then
        Result := ErrorAtLexeme(InvalidEmptyCharacterStr)
    else if ASeq[K] = '\' then begin
        Inc(K);
        if not ReadEscapeSequenceAtPos(ASeq, K, L, Ch) then
            Result := ErrorAtLexeme(InvalidEscapeSequenceStr, ['\' + ASeq[K]]);
    end
    else begin
        Ch := ASeq[K];
        Inc(K);
    end;
    if (Result = FX_RES_SUCCESS) and (K <= L) then
        Result := ErrorAtLexeme(TooLongCharacterSequenceStr);
    
LBL_END:

end;

function TScanner.__TokenFromLexeme(var Token: TToken; var ARIV: TRestrictedVariables): Word;

LABEL LBL_END;

var
    P, I: Integer;
    Ch: TFxChar;
    Str: TFxString;
begin

    Result := FX_RES_SUCCESS;

    IF STOP THEN GOTO LBL_END;

    Token.Next := nil;
    Token.Col := Stream.ColFromPos(LxPos);
    Token.Line := Stream.LineFromPos(LxPos);
    case LxKind of
        FX_LEXEME_DECIMAL     : begin
            Token.Kind := FX_TK_NUMBER;
            Token.nValue := NumberFromDecLexeme(LxStr);
        end;
        FX_LEXEME_HEXADECIMAL : begin
            Token.Kind := FX_TK_NUMBER;
            Token.nValue := NumberFromHexLexeme(LxStr);
        end;
        FX_LEXEME_CHAR        : begin
            Token.Kind := FX_TK_CHARACTER;
            Result := __CharFromSequence(LxStr, Ch);
            IF STOP THEN GOTO LBL_END;
            if Result = FX_RES_SUCCESS then
                Token.cValue := Ch;
        end;
        FX_LEXEME_STRING      : begin
            Token.Kind := FX_TK_STRING;
            System.New(Token.sValue);
            Result := __StringFromSequence(LxStr, Str);
            IF STOP THEN GOTO LBL_END;
            if Result = FX_RES_SUCCESS then
                Token.sValue^ := Str;
        end;
        FX_LEXEME_LITERAL     : begin
            Token.IdCode := GetPrimFunctionCode(LxStr);
            if (Token.IdCode < 0) or (Token.IdCode = FX_PRIM_NONE) then begin
                Token.Kind := GetKeyWordTokenKind(LxStr);
                if (Token.Kind = FX_TK_NONE) then begin
                    Token.Kind := FX_TK_IDENTIFIER;
                    P := Storage.FindIdentifier(LxStr);
                    if P < 0 then
                        P := Storage.AddIdentifier(LxStr);
                    Token.IdCode := P;
                    if IsInternalVariable(LxStr, I) then
                        AddRestrictedVariables(ARIV, I);
                end;
            end
            else
                Token.Kind := FX_TK_PRIMITIVE;
        end;
        FX_LEXEME_SYMBOL      : begin
            Token.Kind := GetKeySymbolTokenKind(LxStr);
            if Token.Kind = FX_TK_NONE then begin
                Token.Kind := FX_TK_IDENTIFIER;
                P := Storage.FindIdentifier(LxStr);
                if P < 0 then
                    P := Storage.AddIdentifier(LxStr);
                Token.IdCode := P;
            end;
        end;
        FX_LEXEME_MONO        : begin
            Token.Kind := GetMonoTokenKind(LxStr);
        end;
    end;
    
LBL_END:
    
end;

function TScanner.__ScanCommandTokens(var K: Integer; var ATokenList: TTokenList; var ARIV: TRestrictedVariables): Word;

LABEL LBL_END;

label LBL_GETNEWTOKEN;

var
    L, S: Integer;
    LastTkn: PToken;
    LineStart: Integer;

    function CheckIsPartOfCommand: Boolean;
    begin
        if ATokenList = nil then
            Result := True
        else
            Result := Stream.ColFromPos(LxPos) > ATokenList^.Col;
        if not Result then
            K := LineStart;
    end;
    
begin
    
    Result := FX_RES_SUCCESS;
    IF STOP THEN GOTO LBL_END;
    
    LineStart := K;
    L := Stream.Length;
    LastTkn := nil;
    LxKind := FX_LEXEME_NONE;
    LxStr := '';
    LxPos := 0;
    
    LBL_GETNEWTOKEN:
    IF STOP THEN GOTO LBL_END;
    if K >= L then
        goto LBL_END;
    
    // posible comentario o fin de linea
    if Stream[K] = '.' then begin
        if (K + 1 < L) and (Stream[K + 1] = '.') then begin
            if (K + 2 < L) and (Stream[K + 2] = '.') then begin
                S := K + 3;
                K := __FindNextLineStart(S);
                IF STOP THEN GOTO LBL_END;
                LineStart := K;
                goto LBL_GETNEWTOKEN;
            end;
        end;
    end
    else if Stream[K] = FX_EOL_LF then begin
        Inc(K);
        LineStart := K;
        goto LBL_GETNEWTOKEN;
    end
    else if Stream[K] = FX_EOL_CR then begin
        Inc(K);
        if Stream[K] = FX_EOL_LF then
            Inc(K);
        LineStart := K;
        goto LBL_GETNEWTOKEN;
    end;
    
    // leer un lexema
    if IsNumberStartChar(Stream[K]) then begin
        LxKind := FX_LEXEME_DECIMAL;
        LxPos := K;
        if not CheckIsPartOfCommand then
            goto LBL_END;

        LxStr := Stream[K];
        Inc(K);
        if K >= L then begin 
        end
        else if (LxStr = '0') and (Stream[K] in ['x', 'X']) then begin
            LxKind := FX_LEXEME_HEXADECIMAL;
            LxStr := LxStr + Stream[K];
            Inc(K);
            while (K < L) and IsHexadecimalChar(Stream[K]) do begin
                IF STOP THEN GOTO LBL_END;
                LxStr := LxStr + Stream[K];
                Inc(K);
            end;
        end
        else begin
            while (K < L) and IsNumeralChar(Stream[K]) do begin
                IF STOP THEN GOTO LBL_END;
                LxStr := LxStr + Stream[K];
                Inc(K);
            end;
            if (K < L) and (Stream[K] = '.') then begin
                LxStr := LxStr + Stream[K];
                Inc(K);
                while (K < L) and IsNumeralChar(Stream[K]) do begin
                    IF STOP THEN GOTO LBL_END;
                    LxStr := LxStr + Stream[K];
                    Inc(K);
                end;
            end;
            if (K < L) and (Stream[K] in ['e', 'E']) then begin
                LxStr := LxStr + Stream[K];
                Inc(K);
                if (K < L) and (Stream[K] in ['+', '-']) then begin
                    LxStr := LxStr + Stream[K];
                    Inc(K);
                end;
                while (K < L) and IsNumeralChar(Stream[K]) do begin
                    IF STOP THEN GOTO LBL_END;
                    LxStr := LxStr + Stream[K];
                    Inc(K);
                end;
            end;
        end;
    end
    else if Stream[K] = '''' { character start } then begin
        LxKind := FX_LEXEME_CHAR;
        LxPos := K;
        if not CheckIsPartOfCommand then
            goto LBL_END;
        
        LxStr := Stream[K];
        Inc(K);
        while (K < L) and (Stream[K] <> '''') and (not IsEOLChar(Stream[K])) do begin
            IF STOP THEN GOTO LBL_END;
            LxStr := LxStr + Stream[K];
            if Stream[K] = '\' then begin
                Inc(K);
                if (K < L) and (not IsEOLChar(Stream[K])) then
                    LxStr := LxStr + Stream[K];
            end;
            Inc(K);
        end;
        if (K >= L) or IsEOLChar(Stream[K]) then begin
            Result := ErrorAtLexeme(MissingCharacterDelimiterStr);
            goto LBL_END;
        end
        else begin
            LxStr := LxStr + Stream[K];
            Inc(K);
        end;
    end
    else if Stream[K] = '"' { string start } then begin
        LxKind := FX_LEXEME_STRING;
        LxPos := K;
        if not CheckIsPartOfCommand then
            goto LBL_END;
        
        LxStr := Stream[K];
        Inc(K);
        while (K < L) and (Stream[K] <> '"') and (not IsEOLChar(Stream[K])) do begin
            IF STOP THEN GOTO LBL_END;
            LxStr := LxStr + Stream[K];
            if Stream[K] = '\' then begin
                Inc(K);
                if (K < L) and (not IsEOLChar(Stream[K])) then
                    LxStr := LxStr + Stream[K];
            end;
            Inc(K);
        end;
        if (K >= L) or IsEOLChar(Stream[K]) then begin
            Result := ErrorAtLexeme(MissingStringDelimiterStr);
            goto LBL_END;
        end
        else begin
            LxStr := LxStr + Stream[K];
            Inc(K);
        end;
    end
    else if IsLiteralStartChar(Stream[K]) then begin
        LxKind := FX_LEXEME_LITERAL;
        LxPos := K;
        if not CheckIsPartOfCommand then
            goto LBL_END;
        
        LxStr := Stream[K];
        Inc(K);
        while (K < L) and IsLiteralTailChar(Stream[K]) do begin
            IF STOP THEN GOTO LBL_END;
            LxStr := LxStr + Stream[K];
            Inc(K);
        end;
    end
    else if IsSymbolStartChar(Stream[K]) then begin
        LxKind := FX_LEXEME_SYMBOL;
        LxPos := K;
        if not CheckIsPartOfCommand then
            goto LBL_END;
        
        LxStr := Stream[K];
        Inc(K);
        while (K < L) and IsSymbolTailChar(Stream[K]) do begin
            IF STOP THEN GOTO LBL_END;
            LxStr := LxStr + Stream[K];
            Inc(K);
        end;
    end
    else if IsMonoChar(Stream[K]) then begin
        LxKind := FX_LEXEME_MONO;
        LxPos := K;
        if not CheckIsPartOfCommand then
            goto LBL_END;
        
        LxStr := Stream[K];
        Inc(K);
    end
    else if IsWhiteSpaceChar(Stream[K]) then begin
        LxKind := FX_LEXEME_NONE;
        Inc(K);
        while (K < L) and IsWhiteSpaceChar(Stream[K]) do begin
            IF STOP THEN GOTO LBL_END;
            Inc(K);
        end;
    end
    else { invalid lexeme start } begin
        LxPos := K;
        if not CheckIsPartOfCommand then
            goto LBL_END;
        Result := ErrorAtLexeme(UnexpectedInputStr, [Stream[K]]);
        goto LBL_END;
    end;
    
    // agregar lexema
    if (Result = FX_RES_SUCCESS) and (LxKind <> FX_LEXEME_NONE) then begin
        IF STOP THEN GOTO LBL_END;
        
        // agregar token
        
        if ATokenList = nil then begin
            System.New(ATokenList);
            Result := __TokenFromLexeme(ATokenList^, ARIV);
            IF STOP THEN GOTO LBL_END;
            LastTkn := ATokenList;
        end
        else begin
            System.New(LastTkn^.Next);
            LastTkn := LastTkn^.Next;
            Result := __TokenFromLexeme(LastTkn^, ARIV);
            IF STOP THEN GOTO LBL_END;
        end;
        
    end;
    if Result = FX_RES_SUCCESS then goto LBL_GETNEWTOKEN;
    
LBL_END:

end;

function TScanner.__ScanCommand(var AScanPos: Integer; var AStream: IStream; var ATokenList: TTokenList;
    var ARestrictedInternalVars: TRestrictedVariables): Word;
begin
    Result := FX_RES_SUCCESS;
    Stream := AStream;
    ATokenList := nil;
    ARestrictedInternalVars := nil;
    Result := __ScanCommandTokens(AScanPos, ATokenList, ARestrictedInternalVars);
end;

procedure TScanner.Interrupt;
begin
    STOP := TRUE;
end;

end.
