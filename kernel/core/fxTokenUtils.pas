unit fxTokenUtils;

interface

uses
    fxUtils, fxStrUtils, fxStorage, fxPrimFuncUtils;

const
    
    FX_LEXEME_NONE             = 0;
	FX_LEXEME_DECIMAL          = 1;
	FX_LEXEME_HEXADECIMAL      = 2;
	FX_LEXEME_CHAR             = 3;
	FX_LEXEME_STRING           = 4;
	FX_LEXEME_LITERAL          = 5;
	FX_LEXEME_SYMBOL           = 6;
	FX_LEXEME_MONO             = 7;
    
    FX_TK_NONE                 = 00;
    FX_TK_NUMBER               = 01;
    FX_TK_CHARACTER            = 02;
    FX_TK_STRING               = 03;
    FX_TK_IDENTIFIER           = 04;
    FX_TK_PRIMITIVE            = 05;
    FX_TK_COMMA                = 06;
    FX_TK_SEMICOLON            = 07;
    FX_TK_LEFT_PARENTHESIS     = 08;
    FX_TK_RIGHT_PARENTHESIS    = 09;
    FX_TK_LEFT_SQUAREBRACKET   = 10;
    FX_TK_RIGHT_SQUAREBRACKET  = 11;
    FX_TK_LEFT_CURLYBRACKET    = 12;
    FX_TK_RIGHT_CURLYBRACKET   = 13;
    FX_TK_KW_TRUE              = 14;
    FX_TK_KW_FALSE             = 15;
    FX_TK_KW_FAIL              = 16;
    FX_TK_KW_ANONYMOUS         = 17;
    FX_TK_KW_LET               = 18;
    FX_TK_KW_IN                = 19;
    FX_TK_KW_WHERE             = 20;
    FX_TK_KW_RUN            = 21;
    FX_TK_KW_CLEAR             = 22;
    FX_TK_KW_INFIX             = 23;
    FX_TK_KW_INFIXL            = 24;
    FX_TK_KW_INFIXR            = 25;
    FX_TK_KW_POSFIX            = 26;
    FX_TK_KW_PREFIX            = 27;
    FX_TK_KW_BEGIN             = 28;
    FX_TK_KW_IF                = 29;
    FX_TK_KW_ELIF              = 30;
    FX_TK_KW_THEN              = 31;
    FX_TK_KW_ELSE              = 32;
    FX_TK_KW_WHILE             = 33;
    FX_TK_KW_DO                = 34;
    FX_TK_KW_FOR               = 35;
    FX_TK_KW_RETURN            = 36;
    FX_TK_KW_END               = 37;
    FX_TK_KW_NAN               = 38;
    FX_TK_KW_INF               = 39;
    FX_TK_KW_REAL              = 40;
    FX_TK_KW_INT               = 41;
    FX_TK_KW_NAT               = 42;
    FX_TK_KW_BOOL              = 43;
    FX_TK_KW_CHAR              = 44;
    FX_TK_KS_SYNONYMOUS        = 45;
    FX_TK_KS_INHERITABLE       = 46;
    FX_TK_KS_DEFINITION        = 47;
    FX_TK_KS_LAMBDA            = 48;
    FX_TK_KS_LEFT_ARROW        = 49;
    FX_TK_KS_RIGHT_ARROW       = 50;
    FX_TK_KS_POP_LIST          = 51;
    FX_TK_KS_PUSH_LIST         = 52;
    FX_TK_KS_DOTDOT            = 53;
    FX_TK_KS_BAR               = 54;
    FX_TK_KS_TRY               = FX_TK_SEMICOLON;
    FX_TK_KS_COLON             = 56;
    FX_TK_KS_GUARD             = 57;
    
type

    PToken = ^TToken;
    TToken = packed record
        Kind: Byte;
        Line: Integer;
        Col: Integer;
        Next: PToken;
        case Byte of
            1: (cValue: TFxChar);
            4: (nValue: TFxNumber);
            5: (sValue: PFxString);
            7: (IdCode: Integer);
    end;
    TTokenList = PToken;

function NumberFromDecLexeme(ALxStr: TFxString): TFxNumber;
function NumberFromHexLexeme(ALxStr: TFxString): TFxNumber;
function GetKeyWordTokenKind(ALxStr: TFxString): Byte;
function GetKeySymbolTokenKind(ALxStr: TFxString): Byte;
function GetMonoTokenKind(ALxStr: TFxString): Byte;

function NumberToLexeme(N: TFxNumber): TFxString;
function CharacterToCharLexeme(Ch: TFxChar): TFxString;
function StringToStrLexeme(Str: TFxString): TFxString;
function TokenKindToLexeme(AKind: Byte): TFxString;
function TokenToLexeme(ATkn: TToken; AStorage: TStorage): TFxString;

procedure EraseTokenListTail(var ATokenList: TTokenList);
procedure EraseTokenList(var ATokenList: TTokenList);

implementation

function NumberFromDecLexeme(ALxStr: TFxString): TFxNumber;  
begin
    Result := StrToNumber(ALxStr);
end;

function NumberFromHexLexeme(ALxStr: TFxString): TFxNumber;    
begin
    Result := HexToNumber(ALxStr);
end;

function GetKeyWordTokenKind(ALxStr: TFxString): Byte;          
begin
         if ALxStr = 'true'   then Result := FX_TK_KW_TRUE     
    else if ALxStr = 'false'  then Result := FX_TK_KW_FALSE    
    else if ALxStr = 'fail'   then Result := FX_TK_KW_FAIL     
    else if ALxStr = '_'      then Result := FX_TK_KW_ANONYMOUS
    else if ALxStr = 'let'    then Result := FX_TK_KW_LET      
    else if ALxStr = 'in'     then Result := FX_TK_KW_IN       
    else if ALxStr = 'where'  then Result := FX_TK_KW_WHERE    
    else if ALxStr = 'run'    then Result := FX_TK_KW_RUN
    else if ALxStr = 'clear'  then Result := FX_TK_KW_CLEAR    
    else if ALxStr = 'infix'  then Result := FX_TK_KW_INFIX    
    else if ALxStr = 'infixl' then Result := FX_TK_KW_INFIXL   
    else if ALxStr = 'infixr' then Result := FX_TK_KW_INFIXR   
    else if ALxStr = 'posfix' then Result := FX_TK_KW_POSFIX   
    else if ALxStr = 'prefix' then Result := FX_TK_KW_PREFIX   
    else if ALxStr = 'begin'  then Result := FX_TK_KW_BEGIN    
    else if ALxStr = 'if'     then Result := FX_TK_KW_IF       
    else if ALxStr = 'elif'   then Result := FX_TK_KW_ELIF     
    else if ALxStr = 'then'   then Result := FX_TK_KW_THEN     
    else if ALxStr = 'else'   then Result := FX_TK_KW_ELSE     
    else if ALxStr = 'while'  then Result := FX_TK_KW_WHILE    
    else if ALxStr = 'do'     then Result := FX_TK_KW_DO       
    else if ALxStr = 'for'    then Result := FX_TK_KW_FOR      
    else if ALxStr = 'return' then Result := FX_TK_KW_RETURN   
    else if ALxStr = 'end'    then Result := FX_TK_KW_END  
    else if ALxStr = 'nan'    then Result := FX_TK_KW_NAN  
    else if ALxStr = 'inf'    then Result := FX_TK_KW_INF  
    else if ALxStr = 'real'   then Result := FX_TK_KW_REAL
    else if ALxStr = 'int'    then Result := FX_TK_KW_INT 
    else if ALxStr = 'nat'    then Result := FX_TK_KW_NAT 
    else if ALxStr = 'bool'   then Result := FX_TK_KW_BOOL
    else if ALxStr = 'char'   then Result := FX_TK_KW_CHAR
    else                           Result := FX_TK_NONE;
end;

function GetKeySymbolTokenKind(ALxStr: TFxString): Byte;        
begin
         if ALxStr = '::=' then Result := FX_TK_KS_SYNONYMOUS
    else if ALxStr = '::'  then Result := FX_TK_KS_INHERITABLE
    else if ALxStr = ':='  then Result := FX_TK_KS_DEFINITION
    else if ALxStr = '\'   then Result := FX_TK_KS_LAMBDA
    else if ALxStr = '<-'  then Result := FX_TK_KS_LEFT_ARROW
    else if ALxStr = '->'  then Result := FX_TK_KS_RIGHT_ARROW
    else if ALxStr = '|<'  then Result := FX_TK_KS_POP_LIST
    else if ALxStr = '>|'  then Result := FX_TK_KS_PUSH_LIST
    else if ALxStr = '..'  then Result := FX_TK_KS_DOTDOT
    else if ALxStr = '|'   then Result := FX_TK_KS_BAR
    else if ALxStr = ';'   then Result := FX_TK_KS_TRY
    else if ALxStr = ':'   then Result := FX_TK_KS_COLON
    else if ALxStr = '?'   then Result := FX_TK_KS_GUARD
    else                      Result := FX_TK_NONE;
end;

function GetMonoTokenKind(ALxStr: TFxString): Byte;             
begin
    case ALxStr[1] of
        ',': Result := FX_TK_COMMA;
        ';': Result := FX_TK_SEMICOLON;
        '(': Result := FX_TK_LEFT_PARENTHESIS;
        ')': Result := FX_TK_RIGHT_PARENTHESIS;
        '[': Result := FX_TK_LEFT_SQUAREBRACKET;
        ']': Result := FX_TK_RIGHT_SQUAREBRACKET;
        '{': Result := FX_TK_LEFT_CURLYBRACKET;
        '}': Result := FX_TK_RIGHT_CURLYBRACKET;
        else Result := FX_TK_NONE;
    end;
end;

function NumberToLexeme(N: TFxNumber): TFxString;      
begin
    Result := NumberToStr(N);
end;

function CharacterToCharLexeme(Ch: TFxChar): TFxString;
begin
    Result := '''' + CharToSequence(Ch) + '''';
end;

function StringToStrLexeme(Str: TFxString): TFxString;
begin
    Result := '"' + StrToSequence(Str) + '"';
end;

function TokenKindToLexeme(AKind: Byte): TFxString;             
begin
    case AKind of
        FX_TK_NONE                 : Result := '';
        FX_TK_NUMBER               : Result := '';
        FX_TK_CHARACTER            : Result := '';
        FX_TK_STRING               : Result := '';
        FX_TK_IDENTIFIER           : Result := '';
        FX_TK_PRIMITIVE            : Result := '';
        FX_TK_COMMA                : Result := ',';
        FX_TK_SEMICOLON            : Result := ';';
        FX_TK_LEFT_PARENTHESIS     : Result := '(';
        FX_TK_RIGHT_PARENTHESIS    : Result := ')';
        FX_TK_LEFT_SQUAREBRACKET   : Result := '[';
        FX_TK_RIGHT_SQUAREBRACKET  : Result := ']';
        FX_TK_LEFT_CURLYBRACKET    : Result := '{';
        FX_TK_RIGHT_CURLYBRACKET   : Result := '}';
        FX_TK_KW_TRUE              : Result := 'true';
        FX_TK_KW_FALSE             : Result := 'false';
        FX_TK_KW_FAIL              : Result := 'fail';
        FX_TK_KW_ANONYMOUS         : Result := '_';
        FX_TK_KW_LET               : Result := 'let';
        FX_TK_KW_IN                : Result := 'in';
        FX_TK_KW_WHERE             : Result := 'where';
        FX_TK_KW_RUN               : Result := 'run';
        FX_TK_KW_CLEAR             : Result := 'clear';
        FX_TK_KW_INFIX             : Result := 'infix';
        FX_TK_KW_INFIXL            : Result := 'infixl';
        FX_TK_KW_INFIXR            : Result := 'infixr';
        FX_TK_KW_POSFIX            : Result := 'posfix';
        FX_TK_KW_PREFIX            : Result := 'prefix';
        FX_TK_KW_BEGIN             : Result := 'begin';
        FX_TK_KW_IF                : Result := 'if';
        FX_TK_KW_ELIF              : Result := 'elif';
        FX_TK_KW_THEN              : Result := 'then';
        FX_TK_KW_ELSE              : Result := 'else';
        FX_TK_KW_WHILE             : Result := 'while';
        FX_TK_KW_DO                : Result := 'do';
        FX_TK_KW_FOR               : Result := 'for';
        FX_TK_KW_RETURN            : Result := 'return';
        FX_TK_KW_END               : Result := 'end';
        FX_TK_KW_NAN               : Result := 'nan';
        FX_TK_KW_INF               : Result := 'inf';
        FX_TK_KW_REAL              : Result := 'real';
        FX_TK_KW_INT               : Result := 'int';
        FX_TK_KW_NAT               : Result := 'nat';
        FX_TK_KW_BOOL              : Result := 'bool';
        FX_TK_KW_CHAR              : Result := 'char';
        FX_TK_KS_SYNONYMOUS        : Result := '::=';
        FX_TK_KS_INHERITABLE       : Result := '::';
        FX_TK_KS_DEFINITION        : Result := ':=';
        FX_TK_KS_LAMBDA            : Result := '\';
        FX_TK_KS_LEFT_ARROW        : Result := '<-';
        FX_TK_KS_RIGHT_ARROW       : Result := '->';
        FX_TK_KS_POP_LIST          : Result := '|<';
        FX_TK_KS_PUSH_LIST         : Result := '>|';
        FX_TK_KS_DOTDOT            : Result := '..';
        FX_TK_KS_BAR               : Result := '|';
        //FX_TK_KS_TRY               : Result := ';';
        FX_TK_KS_COLON             : Result := ':';
        FX_TK_KS_GUARD             : Result := '?';
        else Result := '';
    end;
end;

function TokenToLexeme(ATkn: TToken; AStorage: TStorage): TFxString;                
begin
    case ATkn.Kind of
        FX_TK_NONE                 : Result := '';
        FX_TK_NUMBER               : Result := NumberToLexeme(ATkn.nValue);
        FX_TK_CHARACTER            : Result := CharacterToCharLexeme(ATkn.cValue);
        FX_TK_STRING               : Result := StringToStrLexeme(ATkn.sValue^);
        FX_TK_IDENTIFIER           : Result := AStorage[ATkn.IdCode].Name;
        FX_TK_PRIMITIVE            : Result := GetPrimFunctionFromCode(ATkn.IdCode);
        else Result := TokenKindToLexeme(ATkn.Kind);
    end;
end;

procedure EraseTokenListTail(var ATokenList: TTokenList);
begin
    if ATokenList <> nil then begin
        EraseTokenList(ATokenList^.Next);
        ATokenList^.Next := nil;
    end;
end;

procedure EraseTokenList(var ATokenList: TTokenList);
begin
    if ATokenList <> nil then begin
        EraseTokenList(ATokenList^.Next);
        if ATokenList^.Kind = FX_TK_STRING then begin
            ATokenList^.sValue^ := '';
            Dispose(ATokenList^.sValue);
        end;
        Dispose(ATokenList);
        ATokenList := nil;
    end;
end;

end.
