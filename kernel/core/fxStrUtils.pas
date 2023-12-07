unit fxStrUtils;

interface

uses
    SysUtils, Math, fxUtils, fxMath;
    
const
    FX_MAX_INTERNAL_VAR_LENGTH = 12;
    FX_MAX_INTERNAL_VAR_CODE = 999999999;
    
const
    ShellLoadingStr = 'Loading...';
    ShellTypeHelpStr = 'Type Help() for more information.';
    ShellRestartedStr = '--- SHELL RESTARTED ---';
    ShellInterruptedStr = '{Interrupted!}';
    
    InternalErrorStr = 'INTERNAL ERROR %s- %s';
    ErrorStr = 'ERROR %s- %s';
    ScriptErrorStr = '"%s" line %d';
    
    MissingCharacterDelimiterStr = 'missing character delimiter';
    MissingStringDelimiterStr = 'missing string delimiter';
    InvalidEscapeSequenceStr = 'invalid escape sequence "%s"';
    InvalidEmptyCharacterStr = 'invalid empty character';
    TooLongCharacterSequenceStr = 'too long character sequence';
    UnexpectedInputStr = 'unexpected input "%s"';
    UnknownDirectiveStr = 'unknown directive "%s"';
    
    EndOfLayoutStr = 'end of layout';
    EndOfCommandStr = 'end of command';
    TypeExpressionExpectedStr = 'type expression expected but %s found';
    InvalidNegativeIdentifierNumberStr = 'invalid negative identifier number %s';
    NegativeIdentifierNumberExpectedStr = 'negative identifier number expected but %s found';
    PatternExpectedStr = 'pattern expected but %s found';
    RightParenthesisExpectedStr = '")" expected but %s found';
    RightSquareBracketExpectedStr = '"]" expected but %s found';
    RightCurlyBracketExpectedStr = '"}" expected but %s found';
    KeywordTHENExpectedStr = '"then" expected but %s found';
    ValueExpressionExpectedStr = 'value expression expected but %s found';
    KeywordDOExpectedStr = '"do" expected but %s found';
    KeywordINExpectedStr = '"in" expected but %s found';
    LeftArrowExpectedStr = '"<-" expected but %s found';
    RightArrowExpectedStr = '"->" expected but %s found';
    QualifierExpectedStr = 'comprehension list qualifier expected but %s found';
    AssignmentExpectedStr = 'assignment expected but %s found';
    KeywordENDExpectedStr = '"end" expected but %s found';
    UnexpectedTokenStr = 'end of command expected but %s found';
    ScriptPathExpectedStr = 'script path expected but %s found';
    IdentifierExpectedStr = 'identifier expected but %s found';
    InvalidPriorityNumber = 'invalid priority number %s';
    PriorityNumberExpectedStr = 'priority number expected but %s found';
    
    MissingArgumentForStr = 'missing argument for %s';
    MissingLeftArgumentForStr = 'missing left argument for %s';
    MissingRightArgumentForStr = 'missing right argument for %s';
    NegativeInfixIdentifierDetectedStr = 'negative infix identifier detected "%d"';
    AmbiguousAssociativityBetweenStr = 'ambiguous associativity between %s and %s';
    
    CanNotDefinePrimitiveFunctionsStr = 'cann''t define primitive functions';
    ExpectedIdentifierForDefinitionStr = 'expected identifier for definition';
    CanNotDefineNegativeIdentifiersStr = 'cann''t define negative identifiers';
    RequiredDefinitionForStr = 'required "%s" definition for %s';
    IndexStructureStr = 'index structure';
    ListComprehensionGeneratorStr = 'list comprehension generator';
    ListComprehensionFilterStr = 'list comprehension filter';
    SequenceListStr = 'sequence list';
    SequenceStepListStr = 'sequence step list';
    ConditionalStatementStr = 'conditional statement';
    LoopWhileStatementStr = 'WHILE statement';
    LoopForStatementStr = 'FOR statement';
    GuardExpressionStr = 'guard';
    
    RecursiveTypeStr = 'type "%s" is recursive';
    UndefinedTypeSynonymousStr = 'undefined type synonymous "%s"';
    CouldNotInheritTypeOnExpressionStr = 'couldn''t inherit type %s on expression %s';
    CouldNotInheritTypeOnPatternStr = 'couldn''t inherit type %s too many patterns in definition';
    DifferentAritiesForStr = 'arity doesn''t match for "%s"';
    ValueUndefinedStr = 'no value has been defined for "%s"';
    ListIndexOutOfBoundsStr = 'list index out of bounds';
    TupleIndexOutOfBoundsStr = 'tuple index out of bounds';
    ThereIsNotPreviousAnswerStr = 'there isn''t previous answer value';
    PrimitiveErrorStr = 'primitive "%s": %s';
    ExpectedFunctionLeftSideStr = 'expected function for application left side but "%s" found';
    
    FileNotFoundStr = 'file not found "%s"';
    
function IsLetterChar(Ch: TFxChar): Boolean;
function IsSymbolChar(Ch: TFxChar): Boolean;
function IsHexadecimalChar(Ch: TFxChar): Boolean;
function IsMonoChar(Ch: TFxChar): Boolean;
function IsNumeralChar(Ch: TFxChar): Boolean;
function IsWhiteSpaceChar(Ch: TFxChar): Boolean;
function IsEOLChar(Ch: TFxChar): Boolean;
function IsNumberStartChar(Ch: TFxChar): Boolean;
function IsSymbolStartChar(Ch: TFxChar): Boolean;
function IsSymbolTailChar(Ch: TFxChar): Boolean;
function IsLiteralTailChar(Ch: TFxChar): Boolean;
function IsLiteralStartChar(Ch: TFxChar): Boolean;
function IsCommentStartChar(Ch: TFxChar): Boolean;
function IsBasicEscChar(ECh: TFxChar): Boolean;

function LineHasComment(S: TFxString): Boolean;
function ReadEscapeSequenceAtPos(Seq: TFxString; var K: Integer; L: Integer; out Ch: TFxChar): Boolean;
function CharToSequence(Ch: TFxChar): TFxString;
function SequenceToChar(Seq: TFxString): TFxChar;
function StrToSequence(Str: TFxString): TFxString;
function IsInternalVariable(Str: TFxString; var I: Integer): Boolean;
function InternalVariableName(I: Integer): TFxString;

function NumberToStr(N: TFxNumber): TFxString;
function TryStrToNumber(Str: TFxString; out N: TFxNumber): Boolean;
function StrToNumber(Str: TFxString): TFxNumber;
function TryHexToNumber(Str: TFxString; out N: TFxNumber): Boolean;
function HexToNumber(Str: TFxString): TFxNumber;
function BoolToStr(B: TFxBool): TFxString;
function IdCodeToStr(AIdCode: Integer): TFxString;

function FormatMessage(AMsg: string; const AArgs: array of const): string;

implementation

function IsLetterChar(Ch: TFxChar): Boolean;
begin
    Result := Ch in ['A' .. 'Z', 'a' .. 'z'];
end;

function IsSymbolChar(Ch: TFxChar): Boolean;
begin
    Result := Ch in ['|', '!', '$', '%', '&', '/', '=', '?', '\', '@', '*', '+', '^', '-', '.', ':', '<', '>', '#', '~', '`'];
end;

function IsHexadecimalChar(Ch: TFxChar): Boolean;
begin
    Result := Ch in ['0' .. '9', 'a' .. 'f', 'A' .. 'F'];
end;

function IsMonoChar(Ch: TFxChar): Boolean;
begin
    Result := Ch in ['(', ')', '[', ']', '{', '}', ',', ';'];
end;

function IsNumeralChar(Ch: TFxChar): Boolean;
begin
    Result := Ch in ['0' .. '9'];
end;

function IsWhiteSpaceChar(Ch: TFxChar): Boolean;
begin
    Result := Ch in [' ', #9];
end;

function IsEOLChar(Ch: TFxChar): Boolean;
begin
    Result := Ch in [FX_EOL_LF, FX_EOL_CR];
end;

function IsNumberStartChar(Ch: TFxChar): Boolean;
begin
    Result := IsNumeralChar(Ch);
end;

function IsSymbolStartChar(Ch: TFxChar): Boolean;
begin
    Result := IsSymbolChar(Ch);
end;

function IsSymbolTailChar(Ch: TFxChar): Boolean;
begin
    Result := IsSymbolChar(Ch);
end;

function IsLiteralTailChar(Ch: TFxChar): Boolean;
begin
    Result :=   (Ch = '_') or
                IsNumeralChar(Ch) or
                IsLetterChar(Ch);
end;

function IsLiteralStartChar(Ch: TFxChar): Boolean;
begin
    Result := (Ch = '_') or IsLetterChar(Ch);
end;

function IsCommentStartChar(Ch: TFxChar): Boolean;
begin
    Result := Ch = '.';
end;

function IsBasicEscChar(ECh: TFxChar): Boolean;
begin
    Result := ECh in ['"', '''', '\', 'a', 'b', 'f', 'n', 'r', 't', 'v'];
end;

function HexadecimalNibble(HCh: TFxChar): Byte;
begin
    case HCh of
        '0': Result := $00;
        '1': Result := $01;
        '2': Result := $02;
        '3': Result := $03;
        '4': Result := $04;
        '5': Result := $05;
        '6': Result := $06;
        '7': Result := $07;
        '8': Result := $08;
        '9': Result := $09;
        'a': Result := $0a;
        'b': Result := $0b;
        'c': Result := $0c;
        'd': Result := $0d;
        'e': Result := $0e;
        'f': Result := $0f;
        'A': Result := $0A;
        'B': Result := $0B;
        'C': Result := $0C;
        'D': Result := $0D;
        'E': Result := $0E;
        'F': Result := $0F;
        else raise EFxError.Create('HexadecimalNibble(' + HCh + ')');
    end;
end;

function DecimalDigit(DCh: TFxChar): Byte;
begin
    case DCh of
        '0': Result := 0;
        '1': Result := 1;
        '2': Result := 2;
        '3': Result := 3;
        '4': Result := 4;
        '5': Result := 5;
        '6': Result := 6;
        '7': Result := 7;
        '8': Result := 8;
        '9': Result := 9;
        else raise EFxError.Create('DecimalDigit(' + DCh + ')');
    end;
end;

function LineHasComment(S: TFxString): Boolean;
var
    K, L: Integer;
    ChQ, ChE: TFxChar;
    PrevIsNumeral: Boolean;
begin
    Result := False;
    K := 1;
    L := Length(S);
    PrevIsNumeral := False;
    while K <= L do begin
        if S[K] in ['''', '"'] then begin
            ChQ := S[K];
            Inc(K);
            while (K <= L) and (S[K] <> ChQ) do begin
                ChE := S[K];
                Inc(K);
                if (K <= L) and (ChE = '\') and (S[K] = ChQ) then
                    Inc(K);
            end;
            PrevIsNumeral := False;
            Inc(K);
        end
        else if S[K] = '.' then begin
            if PrevIsNumeral then begin
                PrevIsNumeral := False;
                Inc(K);
            end
            else if K <= L - 2 then begin
                if (S[K] = '.') and (S[K + 1] = '.') and (S[K + 2] = '.') then begin
                    Result := True;
                    Break;
                end;
                PrevIsNumeral := False;
                Inc(K);
            end
            else
                Break;
        end
        else if IsSymbolChar(S[K]) then begin
            while (K <= L) and IsSymbolChar(S[K]) do Inc(K);
            PrevIsNumeral := False;
        end
        else begin
            PrevIsNumeral := IsNumeralChar(S[K]);
            Inc(K);
        end;
    end;
end;

function ReadEscapeSequenceAtPos(Seq: TFxString; var K: Integer; L: Integer; out Ch: TFxChar): Boolean;
var
    H: Word;
    D, TD: Integer;
    
begin
    Result := False;
    if K <= L then begin
        if IsBasicEscChar(Seq[K]) then begin
            case Seq[K] of
                '"' : Ch := '"';
                '''': Ch := '''';
                '\' : Ch := '\';
                'a' : Ch := #7;  
                'b' : Ch := #8; 
                'f' : Ch := #12;
                'n' : Ch := #10; 
                'r' : Ch := #13; 
                't' : Ch := #9; 
                'v' : Ch := #11; 
            end;
            Inc(K);
            Result := True;
        end
        else if Seq[K] in ['x', 'X'] then { \xHHHH } begin
            Inc(K);
            H := 0;
            if (K <= L) and IsHexadecimalChar(Seq[K]) then begin
                H := HexadecimalNibble(Seq[K]);
                Inc(K);
                if (K <= L) and IsHexadecimalChar(Seq[K]) then begin
                    H := (H shl 4) or HexadecimalNibble(Seq[K]);
                    Inc(K);
                    if (K <= L) and IsHexadecimalChar(Seq[K]) then begin
                        H := (H shl 4) or HexadecimalNibble(Seq[K]);
                        Inc(K);
                        if (K <= L) and IsHexadecimalChar(Seq[K]) then begin
                            H := (H shl 4) or HexadecimalNibble(Seq[K]);
                            Inc(K);
                        end;
                    end;
                end;
            end;
            Ch := System.Chr(H);
            Result := True;
        end
        else if IsNumeralChar(Seq[K]) then { \DDDDD } begin
            D := DecimalDigit(Seq[K]);
            Inc(K);
            if (K <= L) and IsNumeralChar(Seq[K]) then begin
                D := (D*10) + DecimalDigit(Seq[K]);
                Inc(K);
                if (K <= L) and IsNumeralChar(Seq[K]) then begin
                    D := (D*10) + DecimalDigit(Seq[K]);
                    Inc(K);
                    if (K <= L) and IsNumeralChar(Seq[K]) then begin
                        D := (D*10) + DecimalDigit(Seq[K]);
                        Inc(K);
                        if (K <= L) and IsNumeralChar(Seq[K]) then begin
                            TD := (D*10) + DecimalDigit(Seq[K]);
                            if TD <= $FFFF then begin
                                D := TD;
                                Inc(K);
                            end;
                        end;
                    end;
                end;
            end;
            Ch := System.Chr(D);
            Result := True;
        end;
    end;
end;

function SequenceToChar(Seq: TFxString): TFxChar;
var
    K, L: Integer;
begin
    K := 1;
    L := Length(Seq);
    if L = 0 then
        raise EFxError.Create('SequenceToChar(' + Seq + ')')
    else if Seq[K] = '\' then begin
        if not ReadEscapeSequenceAtPos(Seq, K, L, Result) then
            raise EFxError.Create('SequenceToChar(' + Seq + ')');
    end
    else Result := Seq[K];
end;

function CharToSequence(Ch: TFxChar): TFxString;     
begin
    case Ch of
        '''': Result := '\''';
        '"' : Result := '\"';
        '\' : Result := '\\';
        #7  : Result := '\a';
        #8  : Result := '\b';
        #12 : Result := '\f';
        #10 : Result := '\n';
        #13 : Result := '\r';
        #9  : Result := '\t';
        #11 : Result := '\v';
        else if Ch in [' '..'~'] then Result := Ch
        else Result := '\' + IntToStr(Ord(Ch));//! en algunos caracteres no es necesario
    end;
end;

function StrToSequence(Str: TFxString): TFxString;  
var 
    K: Integer;
begin
    Result := '';
    for K := 1 to Length(Str) do
        Result := Result + CharToSequence(Str[K]);
end;

//<internal variable> ::= "var"("1"|"2"|...|"9"){"0"|"1"|"2"|...|"9"}}
// var1 ... var999999999

function IsInternalVariable(Str: TFxString; var I: Integer): Boolean;
var
    K, L: Integer;
begin
    Result := False;
    L := Length(Str);
    I := 0;
    if L > 3 then begin
        K := 1;
        if Str[K] = 'v' then begin
            Inc(K);
            if Str[K] = 'a' then begin
                Inc(K);
                if Str[K] = 'r' then begin
                    Inc(K);
                    if IsNumeralChar(Str[K]) and (Str[K] <> '0') then begin
                        I := DecimalDigit(Str[K]);
                        Inc(K);
                        while (K <= L) and IsNumeralChar(Str[K]) and (K <= FX_MAX_INTERNAL_VAR_LENGTH) do begin
                            I := I*10 + DecimalDigit(Str[K]);
                            Inc(K);
                        end;
                        if K > L then
                            Result := True;
                    end;
                end;
            end;
        end;
    end;
end;

function InternalVariableName(I: Integer): TFxString;
begin
    Result := 'var' + IntToStr(I);
end;

function NumberToStr(N: TFxNumber): TFxString;
begin
    if fxMath.nIsNan(N) then
        Result := 'nan'
    else if fxMath.nIsPosInfinity(N) then
        Result := 'inf'
    else if fxMath.nIsNegInfinity(N) then
        Result := '-inf'
    else if fxMath.nIsInt(N) then
        Result := IntToStr(fxMath.nITrunc(N))
    else
        Result := FloatToStr(N);
end;

function TryStrToNumber(Str: TFxString; out N: TFxNumber): Boolean;
var
    I: Int64;
begin
    Result := True;
    Str := Trim(Str);
    if Str = 'nan' then
        N := NAN
    else if Str = 'inf' then
        N := INF
    else if Str = '-inf' then
        N := NEGINF
    else if TryStrToInt64(Str, I) then
        N := I
    else
        Result := TryStrToFloat(Str, N);
end;

function StrToNumber(Str: TFxString): TFxNumber; 
var
    I: Int64;
begin
    Str := Trim(Str);
    if Str = 'nan' then
        Result := NAN
    else if Str = 'inf' then
        Result := INF
    else if Str = '-inf' then
        Result := NEGINF
    else if TryStrToInt64(Str, I) then begin
        Result := I
    end
    else
        Result := StrToFloat(Str);
end;

function HexToNumber(Str: TFxString): TFxNumber;     
begin
    Result := StrToInt64(Str);
end;

function TryHexToNumber(Str: TFxString; out N: TFxNumber): Boolean;
var
    I: Int64;
begin
    Result := TryStrToInt64(Str, I);
    if Result then N := I;
end;

function BoolToStr(B: TFxBool): TFxString;
begin
    if B then Result := 'true'
    else Result := 'false';
end;

function IdCodeToStr(AIdCode: Integer): TFxString;
begin
    Result := IntToStr(AIdCode);
end;

function FormatMessage(AMsg: string; const AArgs: array of const): string;
begin
    Result := Format(AMsg, AArgs);
end;

end.
