unit fxStrConverter;

interface

uses
    fxUtils, fxStorage, fxBasicStructure, fxError, fxStrUtils, fxPrimFuncUtils,
    fxInterpreterUtils;

type

    TStrConverter = class
    private
        FrontEnd: IFrontEndListener;
        Storage: TStorage;
        function __ListToStr(AValue: TValueExpr; var AHasDelimiter: Boolean): TFxString;
        function __AppToStr(AValue: TValueExpr; var AAppKind: Byte): TFxString;
        function __LambdaToStr(AValue: TValueExpr): TFxString;
    protected
        STOP: BOOLEAN;
    public
        constructor Create(AFrontEnd: IFrontEndListener; AInterpreter: IInterpreterListener;
            AStorage: TStorage; AError: TErrorRegister);
        destructor Destroy; override;
        
        function __ValueToStr(AValue: TValueExpr): TFxString;
        function __ValueToStrPrettyForm(AValue: TValueExpr): TFxString;
        function __ValueToStrFullForm(AValue: TValueExpr): TFxString;
        function __ValueTypeToStr(AValueType: TValueExpr): TFxString;
        function __TypeToStr(AType: TTypeExpr): TFxString;
        
        procedure Interrupt;
    end;
    
implementation

const
    AK_PREFIX = 0;
    AK_POSFIX = 1;
    AK_INFIX  = 2;

constructor TStrConverter.Create(AFrontEnd: IFrontEndListener; AInterpreter: IInterpreterListener;
    AStorage: TStorage; AError: TErrorRegister);                             
begin
    inherited Create;
    FrontEnd := AFrontEnd;
    Storage := AStorage;
    STOP := FALSE;
end;

destructor TStrConverter.Destroy;                                            
begin
    inherited;
end;

function TStrConverter.__ListToStr(AValue: TValueExpr; var AHasDelimiter: Boolean): TFxString;

LABEL LBL_END;

const
    LK_STRING   = 0;
    LK_COMPACT  = 1;
    LK_EXTENDED = 2;
var
    ListKind: Byte;
    Str: TFxString;
    B: Boolean;
    HeadBranch, TailBranch: TValueExpr;
    
begin

    Result := '';

    IF STOP THEN GOTO LBL_END;
    
    // revisar el tipo de lista
    
    ListKind := LK_STRING;
    TailBranch := AValue;
    while TailBranch <> nil do begin
        IF STOP THEN GOTO LBL_END;
        HeadBranch := TailBranch^.Childs[0];
        TailBranch := TailBranch^.Childs[1];
        if HeadBranch^.vKind <> FX_VN_CHARACTER then
            ListKind := LK_COMPACT;
        if TailBranch^.vKind = FX_VN_LIST_CONS then
            Continue
        else if TailBranch^.vKind = FX_VN_NULL then
            Break
        else begin
            ListKind := LK_EXTENDED;
            Break;
        end;
    end;
    
    // convertir a cadena
    case ListKind of
        LK_STRING: begin
            AHasDelimiter := True;
            Result := '';
            TailBranch := AValue;
            while TailBranch <> nil do begin
                IF STOP THEN GOTO LBL_END;
                HeadBranch := TailBranch^.Childs[0];
                TailBranch := TailBranch^.Childs[1];
                Result := Result + HeadBranch^.D.cValue;
                if TailBranch^.vKind = FX_VN_LIST_CONS then
                    Continue
                else if TailBranch^.vKind = FX_VN_NULL then
                    Break;
            end;
            Result := '"' + fxStrUtils.StrToSequence(Result) + '"';
        end;
        LK_COMPACT: begin
            AHasDelimiter := True;
            Result := '[';
            TailBranch := AValue;
            while TailBranch <> nil do begin
                IF STOP THEN GOTO LBL_END;
                HeadBranch := TailBranch^.Childs[0];
                TailBranch := TailBranch^.Childs[1];
                Result := Result + __ValueToStrPrettyForm(HeadBranch);
                IF STOP THEN GOTO LBL_END;
                if TailBranch^.vKind = FX_VN_LIST_CONS then begin
                    Result := Result + ', ';
                    Continue;
                end
                else if TailBranch^.vKind = FX_VN_NULL then begin
                    Result := Result + ']';
                    Break;
                end;
            end;
        end;
        LK_EXTENDED: begin
            // a >| b >| ss == a >| (b >| ss)
            // a ; b >| c ; d == a ; (b >| c) ; d
            // a b >| c d == (a b) >| (c d)
            // a ! >| c ! == (a !) >| (c !)
            // a . b >| c . d == (a . b) >| (c . d)
            AHasDelimiter := False;
            Result := '';
            TailBranch := AValue;
            while TailBranch <> nil do begin
                IF STOP THEN GOTO LBL_END;
                HeadBranch := TailBranch^.Childs[0];
                TailBranch := TailBranch^.Childs[1];
                if HeadBranch^.vKind = FX_VN_LIST_CONS then begin
                    Str := __ListToStr(HeadBranch, B);
                    IF STOP THEN GOTO LBL_END;
                    if not B then
                        Str := '(' + Str + ')';
                end
                else begin
                    Str := __ValueToStrPrettyForm(HeadBranch);
                    IF STOP THEN GOTO LBL_END;
                    if HeadBranch^.vKind = FX_VN_TRY then
                        Str := '(' + Str + ')';
                end;
                Result := Result + Str + ' >| ';
                if TailBranch^.vKind = FX_VN_LIST_CONS then
                    Continue
                else begin
                    Str := __ValueToStrPrettyForm(TailBranch);
                    IF STOP THEN GOTO LBL_END;
                    if TailBranch^.vKind = FX_VN_TRY then
                        Str := '(' + Str + ')';
                    Result := Result + Str;
                    Break;
                end;
            end;
        end;
    end;
    
LBL_END:
    
end;

function TStrConverter.__AppToStr(AValue: TValueExpr; var AAppKind: Byte): TFxString;

LABEL LBL_END;

var
    Str: TFxString;
    AK: Byte;
    B: Boolean;
    IdCode, LeftAppId, RightAppId: Integer;
    LeftArg, RightArg: TValueExpr;
begin

    Result := '';
    
    IF STOP THEN GOTO LBL_END;
    
    // a b c == (a b)c
    // a >| as b > bs == a >| (as b) > bs
    // a ; b c ; d == a ; (b c) ; d
    // diversas notaciones
    // casos infijo, posfijo y prefijo
    Result := '';
    if  (AValue^.Childs[0]^.vKind = FX_VN_IDENTIFIER) and (AValue^.Childs[0]^.D.tKind = FX_TN_NONE) and
        (AValue^.Childs[0]^.D.vIdCode >= 0) then begin
        IdCode := AValue^.Childs[0]^.D.vIdCode;

        if Storage[IdCode].Notation.Position = npPrefix then begin
            AAppKind := AK_PREFIX;
            
            Result := Storage[IdCode].Name;
            
            case AValue^.Childs[1]^.vKind of
                FX_VN_LIST_CONS: begin
                    Str := __ListToStr(AValue^.Childs[1], B);
                    IF STOP THEN GOTO LBL_END;
                    if not B then
                        Str := '(' + Str + ')';
                end;
                FX_VN_APPLICATION: begin
                    Str := '(' + __AppToStr(AValue^.Childs[1], AK) + ')';
                    IF STOP THEN GOTO LBL_END;
                end;
                FX_VN_TRY: begin
                    Str := '(' + __ValueToStrPrettyForm(AValue^.Childs[1]) + ')';
                    IF STOP THEN GOTO LBL_END;
                end;
                else begin
                    Str := __ValueToStrPrettyForm(AValue^.Childs[1]);
                    IF STOP THEN GOTO LBL_END;
                end;
            end;
            Result := Result + ' ' + Str;
        end
        else if Storage[IdCode].Notation.Position = npPosfix then begin
            AAppKind := AK_POSFIX;
            // g f 1 ! ! ! == (((g f 1) !) !) ! ; la segunda esta mas xvr
            case AValue^.Childs[1]^.vKind of
                FX_VN_LIST_CONS: begin
                    Str := __ListToStr(AValue^.Childs[1], B);
                    IF STOP THEN GOTO LBL_END;
                    if not B then
                        Str := '(' + Str + ')';
                end;
                FX_VN_APPLICATION: begin
                    Str := '(' + __AppToStr(AValue^.Childs[1], AK) + ')';
                    IF STOP THEN GOTO LBL_END;
                end;
                FX_VN_TRY: begin
                    Str := '(' + __ValueToStrPrettyForm(AValue^.Childs[1]) + ')';
                    IF STOP THEN GOTO LBL_END;
                end;
                else begin
                    Str := __ValueToStrPrettyForm(AValue^.Childs[1]);
                    IF STOP THEN GOTO LBL_END;
                end;
            end;
            Result := Str + ' ' + Storage[IdCode].Name;
        end
        else begin
            AAppKind := AK_INFIX;
            
            if (AValue^.Childs[1]^.vKind = FX_VN_TUPLE) and (Length(AValue^.Childs[1]^.Childs) = 2) then begin
                
                LeftArg := AValue^.Childs[1]^.Childs[0];
                RightArg := AValue^.Childs[1]^.Childs[1];
                
                case LeftArg^.vKind of
                    FX_VN_LIST_CONS: begin
                        Str := __ListToStr(LeftArg, B);
                        IF STOP THEN GOTO LBL_END;
                        if not B then
                            Str := '(' + Str + ')';
                    end;
                    FX_VN_TRY: begin
                        Str := '(' + __ValueToStrPrettyForm(LeftArg) + ')';
                        IF STOP THEN GOTO LBL_END;
                    end;
                    FX_VN_APPLICATION: begin
                        Str := __AppToStr(LeftArg, AK);
                        IF STOP THEN GOTO LBL_END;
                        if AK = AK_INFIX then begin
                            LeftAppId := LeftArg^.Childs[0]^.D.vIdCode;
                            if Storage[LeftAppId].Notation.Priority <= Storage[IdCode].Notation.Priority then
                                Str := '(' + Str + ')'
                            else
                                ; // mayor prioridad, no hay problema
                        end;
                    end;
                    else begin
                        Str := __ValueToStrPrettyForm(LeftArg);
                        IF STOP THEN GOTO LBL_END;
                    end;
                end;
                
                Result := Str;
                
                case RightArg^.vKind of
                    FX_VN_LIST_CONS: begin
                        Str := __ListToStr(RightArg, B);
                        IF STOP THEN GOTO LBL_END;
                        if not B then
                            Str := '(' + Str + ')';
                    end;
                    FX_VN_TRY: begin
                        Str := '(' + __ValueToStrPrettyForm(RightArg) + ')';
                        IF STOP THEN GOTO LBL_END;
                    end;
                    FX_VN_APPLICATION: begin
                        Str := __AppToStr(RightArg, AK);
                        IF STOP THEN GOTO LBL_END;
                        if AK = AK_INFIX then begin
                            RightAppId := RightArg^.Childs[0]^.D.vIdCode;
                            if Storage[RightAppId].Notation.Priority <= Storage[IdCode].Notation.Priority then
                                Str := '(' + Str + ')'
                            else
                                ; // mayor prioridad, no hay problema
                        end;
                    end;
                    else begin
                        Str := __ValueToStrPrettyForm(RightArg);
                        IF STOP THEN GOTO LBL_END;
                    end;
                end;
                
                Result := Result + ' ' + Storage[IdCode].Name + ' ' + Str;
            end
            else begin
                
                Result := '(' + Storage[IdCode].Name + ')';
                
                case AValue^.Childs[1]^.vKind of
                    FX_VN_LIST_CONS: begin
                        Str := __ListToStr(AValue^.Childs[1], B);
                        IF STOP THEN GOTO LBL_END;
                        if not B then
                            Str := '(' + Str + ')';
                    end;
                    FX_VN_APPLICATION: begin
                        Str := '(' + __AppToStr(AValue^.Childs[1], AK) + ')';
                        IF STOP THEN GOTO LBL_END;
                    end;
                    FX_VN_TRY: begin
                        Str := '(' + __ValueToStrPrettyForm(AValue^.Childs[1]) + ')';
                        IF STOP THEN GOTO LBL_END;
                    end;
                    else begin
                        Str := __ValueToStrPrettyForm(AValue^.Childs[1]);
                        IF STOP THEN GOTO LBL_END;
                    end;
                end;
                Result := Result + ' ' + Str;
            end;
        end;
    end
    else begin
        
        AAppKind := AK_PREFIX;
        
        case AValue^.Childs[0]^.vKind of
            FX_VN_LIST_CONS: begin
                Str := __ListToStr(AValue^.Childs[0], B);
                IF STOP THEN GOTO LBL_END;
                if not B then
                    Str := '(' + Str + ')';
            end;
            FX_VN_APPLICATION: begin // f g ! 3 == ((f g) !) 3 ; la segunda forma esta xvr
                Str := __AppToStr(AValue^.Childs[0], AK);
                IF STOP THEN GOTO LBL_END;
                if AK <> AK_PREFIX then
                    Str := '(' + Str + ')';
            end;
            FX_VN_TRY: begin
                Str := '(' + __ValueToStrPrettyForm(AValue^.Childs[0]) + ')';
                IF STOP THEN GOTO LBL_END;
            end;
            else begin
                Str := __ValueToStrPrettyForm(AValue^.Childs[0]);
                IF STOP THEN GOTO LBL_END;
            end;
        end;
        
        Result := Str;
        
        case AValue^.Childs[1]^.vKind of
            FX_VN_LIST_CONS: begin
                Str := __ListToStr(AValue^.Childs[1], B);
                IF STOP THEN GOTO LBL_END;
                if not B then
                    Str := '(' + Str + ')';
            end;
            FX_VN_APPLICATION: begin
                Str := '(' + __AppToStr(AValue^.Childs[1], AK) + ')';
                IF STOP THEN GOTO LBL_END;
            end;
            FX_VN_TRY: begin
                Str := '(' + __ValueToStrPrettyForm(AValue^.Childs[1]) + ')';
                IF STOP THEN GOTO LBL_END;
            end;
            else begin
                Str := __ValueToStrPrettyForm(AValue^.Childs[1]);
                IF STOP THEN GOTO LBL_END;
            end;
        end;
        Result := Result + ' ' + Str;
    end;
    
LBL_END:
    
end;

function TStrConverter.__LambdaToStr(AValue: TValueExpr): TFxString;

LABEL LBL_END;

var
    Multipattern: Boolean;
    Str, LStr: TFxString;
    TailBranch: TValueExpr;
    HasDelimiter: Boolean;
    
begin
    
    Result := '';
    
    IF STOP THEN GOTO LBL_END;
    
    Multipattern := False;
    if AValue^.Childs[1]^.vKind = FX_VN_LAMBDA then Multipattern := True;
    TailBranch := AValue;
    Str := '';
    while TailBranch^.vKind = FX_VN_LAMBDA do begin
        IF STOP THEN GOTO LBL_END;
        if TailBranch^.Childs[0]^.vKind = FX_VN_LIST_CONS then begin
            LStr := __ListToStr(TailBranch^.Childs[0], HasDelimiter);
            IF STOP THEN GOTO LBL_END;
            if (not HasDelimiter) and Multipattern then
                LStr := '(' + LStr + ')';
            Str := Str + ' ' + LStr;
        end
        else begin
            Str := Str + ' ' + __ValueToStrPrettyForm(TailBranch^.Childs[0]);
            IF STOP THEN GOTO LBL_END;
        end;
        TailBranch := TailBranch^.Childs[1];
    end;
    Result := '(\' + Str + ' -> ' + __ValueToStrPrettyForm(TailBranch) + ')';
    TailBranch := nil;
    // parentesis para darle elegancia
    
LBL_END:
    
end;

function TStrConverter.__ValueToStr(AValue: TValueExpr): TFxString;           
begin
    Result := __ValueToStrPrettyForm(AValue);
end;

function TStrConverter.__ValueToStrPrettyForm(AValue: TValueExpr): TFxString;

LABEL LBL_END;
 
var
    K: Integer;
    Str: TFxString;
    B: Boolean;
    AK: Byte;
begin

    Result := '';
    
    IF STOP THEN GOTO LBL_END;

    case AValue^.vKind of
        FX_VN_NONE        :
            Result := '';
        FX_VN_NUMBER      :
            Result := fxStrUtils.NumberToStr(AValue^.D.nValue); // tambien es correcto para numeros negativos
        FX_VN_BOOLEAN     :
            Result := fxStrUtils.BoolToStr(AValue^.D.bValue);
        FX_VN_CHARACTER   :
            Result := '''' + fxStrUtils.CharToSequence(AValue^.D.cValue) + ''''; // este caracter no esta en ninguna cadena
        FX_VN_NULL        :
            Result := '[]'; // esta constante no es cola de ninguna lista
        FX_VN_FAIL        :
            Result := 'fail';
        FX_VN_IDENTIFIER  : begin // este identificador no es en ninguna aplicacion
            Result := Storage[AValue^.D.vIdCode].Name;
            if AValue^.D.tKind <> FX_TN_NONE then begin
                Result := '(' + Result + ' : ' + __ValueTypeToStr(AValue) + ')';
                IF STOP THEN GOTO LBL_END;
                // parentesis para darle elegancia(aunque en tuplas es innecesario)
            end
            else if (Storage[AValue^.D.vIdCode].Notation.Position <> npPrefix) then begin
                Result := '(' + Result + ')';
                // parentesis para darle elegancia(aunque en tuplas es innecesario)
            end;
        end;
        FX_VN_PRIMITIVE   :
            Result := fxPrimFuncUtils.GetPrimFunctionFromCode(AValue^.D.vIdCode);
        FX_VN_ANONYMOUS   :
            Result := '_';
        FX_VN_TRY         : begin
            // a ; b ; c == a ; (b ; c)
            // a >| as ; b >| bs == (a >| as) ; (b >| bs)
            // a b ; c d == (a b) ; (c d)
            // a ! ; c ! == (a !) ; (c !)
            // a . b ; c . d == (a . b) ; (c . d)
            Result := __ValueToStrPrettyForm(AValue^.Childs[0]);
            IF STOP THEN GOTO LBL_END;
            if AValue^.Childs[0]^.vKind = FX_VN_TRY then
                Result := '(' + Result + ')';
            Result := Result + ' ; ' + __ValueToStrPrettyForm(AValue^.Childs[1]);
            IF STOP THEN GOTO LBL_END;
        end;
        FX_VN_TUPLE       : begin
            Result := '(';
            for K := 0 to Length(AValue^.Childs) - 1 do begin
                IF STOP THEN GOTO LBL_END;
                if K <> 0 then
                    Result := Result + ', ';
                Result := Result + __ValueToStrPrettyForm(AValue^.Childs[K]); 
                IF STOP THEN GOTO LBL_END;
            end;
            Result := Result + ')';
        end;
        FX_VN_LIST_CONS        : begin
            Result := __ListToStr(AValue, B);
            IF STOP THEN GOTO LBL_END;
        end;
        FX_VN_LAMBDA      : begin
            Result := __LambdaToStr(AValue);
            IF STOP THEN GOTO LBL_END;
        end;
        FX_VN_APPLICATION : begin
            Result := __AppToStr(AValue, AK);
            IF STOP THEN GOTO LBL_END;
        end;
        else
            Result := '';
    end;

LBL_END:

end;

function TStrConverter.__ValueToStrFullForm(AValue: TValueExpr): TFxString;   

LABEL LBL_END;

var
    K: Integer;
    Str: TFxString;
begin
    
    Result := '';
    
    IF STOP THEN GOTO LBL_END;

    case AValue^.vKind of
        FX_VN_NONE        :
            Result := '';
        FX_VN_NUMBER      :
            Result := fxStrUtils.NumberToStr(AValue^.D.nValue); // tambien es correcto para numeros negativos
        FX_VN_BOOLEAN     :
            Result := fxStrUtils.BoolToStr(AValue^.D.bValue);
        FX_VN_CHARACTER   :
            Result := '''' + fxStrUtils.CharToSequence(AValue^.D.cValue) + '''';
        FX_VN_NULL        :
            Result := '[]';
        FX_VN_FAIL        :
            Result := 'fail';
        FX_VN_IDENTIFIER  : begin
            Result := Storage[AValue^.D.vIdCode].Name;
            if AValue^.D.tKind <> FX_TN_NONE then begin
                Result := '(' + Result + ' : ' + __ValueTypeToStr(AValue) + ')';
                IF STOP THEN GOTO LBL_END;
            end
            else if (Storage[AValue^.D.vIdCode].Notation.Position <> npPrefix) then
                Result := '(' + Result + ')';
        end;
        FX_VN_PRIMITIVE   :
            Result := fxPrimFuncUtils.GetPrimFunctionFromCode(AValue^.D.vIdCode);
        FX_VN_ANONYMOUS   :
            Result := '_';
        FX_VN_TRY         : begin
            // a ; b ; c == a ; (b ; c)
            // a >| as ; b >| bs == (a >| as) ; (b >| bs)
            // a b ; c d == (a b) ; (c d)
            Result := __ValueToStrFullForm(AValue^.Childs[0]);
            IF STOP THEN GOTO LBL_END;
            if AValue^.Childs[0]^.vKind = FX_VN_TRY then
                Result := '(' + Result + ')';
            Result := Result + ' ; ' + __ValueToStrFullForm(AValue^.Childs[1]);
            IF STOP THEN GOTO LBL_END;
        end;
        FX_VN_TUPLE       : begin
            Result := '(';
            for K := 0 to Length(AValue^.Childs) - 1 do begin
                IF STOP THEN GOTO LBL_END;
                if K <> 0 then
                    Result := Result + ',';
                Result := Result + __ValueToStrFullForm(AValue^.Childs[K]);  
                IF STOP THEN GOTO LBL_END;
            end;
            Result := Result + ')';
        end;
        FX_VN_LIST_CONS        : begin
            // a >| b >| ss == a >| (b >| ss)
            // a ; b >| c ; d == a ; (b >| c) ; d
            // a b >| c d == (a b) >| (c d)
            Result := __ValueToStrFullForm(AValue^.Childs[0]);
            IF STOP THEN GOTO LBL_END;
            if AValue^.Childs[0]^.vKind = FX_VN_LIST_CONS then
                Result := '(' + Result + ')'
            else if AValue^.Childs[0]^.vKind = FX_VN_TRY then
                Result := '(' + Result + ')';
            Str := __ValueToStrFullForm(AValue^.Childs[1]);
            IF STOP THEN GOTO LBL_END;
            if AValue^.Childs[1]^.vKind = FX_VN_TRY then
                Str := '(' + Str + ')';
            Result := Result + ' >| ' + Str;
        end;
        FX_VN_LAMBDA      : begin
            Result := '(\ ' + __ValueToStrFullForm(AValue^.Childs[0]) + ' -> ' + __ValueToStrFullForm(AValue^.Childs[1]) + ')';
            IF STOP THEN GOTO LBL_END;
            // parentesis para darle elegancia
        end;
        FX_VN_APPLICATION : begin
            // a b c == (a b)c
            // a >| as b > bs == a >| (as b) > bs
            // a ; b c ; d == a ; (b c) ; d
            Result := __ValueToStrFullForm(AValue^.Childs[0]);
            IF STOP THEN GOTO LBL_END;
            if AValue^.Childs[0]^.vKind = FX_VN_LIST_CONS then
                Result := '(' + Result + ')'
            else if AValue^.Childs[0]^.vKind = FX_VN_TRY then
                Result := '(' + Result + ')';
            Str := __ValueToStrFullForm(AValue^.Childs[1]);
            IF STOP THEN GOTO LBL_END;
            if AValue^.Childs[1]^.vKind = FX_VN_LIST_CONS then
                Str := '(' + Str + ')'
            else if AValue^.Childs[1]^.vKind = FX_VN_TRY then
                Str := '(' + Str + ')'
            else if AValue^.Childs[1]^.vKind = FX_VN_APPLICATION then
                Str := '(' + Str + ')';
            Result := Result + ' ' + Str;
        end;
        else
            Result := '';
    end;

LBL_END:

end;

function TStrConverter.__ValueTypeToStr(AValueType: TValueExpr): TFxString;

LABEL LBL_END;

var
    K: Integer;
begin
    
    Result := '';
    
    IF STOP THEN GOTO LBL_END;
    
    case AValueType^.D.tKind of
        FX_TN_NONE      :
            Result := '';
        FX_TN_REAL      :
            Result := 'real';
        FX_TN_INTEGER   :
            Result := 'int';
        FX_TN_NATURAL   :
            Result := 'nat';
        FX_TN_BOOLEAN   :
            Result := 'bool';
        FX_TN_CHARACTER :
            Result := 'char';
        FX_TN_IDENTIFIER:
            Result := Storage[AValueType^.D.tIdCode].Name;
        FX_TN_ANONYMOUS :
            Result := '_';
        FX_TN_TUPLE     : begin
            Result := '(';
            for K := 0 to Length(AValueType^.Childs) - 1 do begin
                IF STOP THEN GOTO LBL_END;
                if K <> 0 then
                    Result := Result + ', ';
                Result := Result + __ValueTypeToStr(AValueType^.Childs[K]);
                IF STOP THEN GOTO LBL_END;
            end;
            Result := Result + ')';
        end;
        FX_TN_LIST      : begin
            Result := '[' + __ValueTypeToStr(AValueType^.Childs[0]) + ']';
            IF STOP THEN GOTO LBL_END;
        end;
        FX_TN_FUNCTION  : begin
            // (a -> b) -> c =/= a -> b -> c; para otro caso hacer explicito
            Result := __ValueTypeToStr(AValueType^.Childs[0]);
            IF STOP THEN GOTO LBL_END;
            if AValueType^.Childs[0]^.D.tKind = FX_TN_FUNCTION then
                Result := '(' + Result + ')';
            Result := Result + ' -> ' + __ValueTypeToStr(AValueType^.Childs[1]);
            IF STOP THEN GOTO LBL_END;
        end;
        else
            Result := '';
    end;

LBL_END:

end;

function TStrConverter.__TypeToStr(AType: TTypeExpr): TFxString;      

LABEL LBL_END;
        
var
    K: Integer;
begin

    Result := '';
    
    IF STOP THEN GOTO LBL_END;

    case AType^.tKind of
        FX_TN_NONE      :
            Result := '';
        FX_TN_REAL      :
            Result := 'real';
        FX_TN_INTEGER   :
            Result := 'int';
        FX_TN_NATURAL   :
            Result := 'nat';
        FX_TN_BOOLEAN   :
            Result := 'bool';
        FX_TN_CHARACTER :
            Result := 'char';
        FX_TN_IDENTIFIER:
            Result := Storage[AType^.tIdCode].Name;
        FX_TN_ANONYMOUS :
            Result := '_';
        FX_TN_TUPLE     : begin
            Result := '(';
            for K := 0 to Length(AType^.Childs) - 1 do begin
                IF STOP THEN GOTO LBL_END;
                if K <> 0 then
                    Result := Result + ', ';
                Result := Result + __TypeToStr(AType^.Childs[K]);
                IF STOP THEN GOTO LBL_END;                
            end;
            Result := Result + ')';
        end;
        FX_TN_LIST      : begin
            Result := '[' + __TypeToStr(AType^.Childs[0]) + ']';
            IF STOP THEN GOTO LBL_END;
        end;
        FX_TN_FUNCTION  : begin
            // (a -> b) -> c =/= a -> b -> c; para otro caso hacer explicito
            Result := __TypeToStr(AType^.Childs[0]);
            IF STOP THEN GOTO LBL_END;
            if AType^.Childs[0]^.tKind = FX_TN_FUNCTION then
                Result := '(' + Result + ')';
            Result := Result + ' -> ' + __TypeToStr(AType^.Childs[1]);
            IF STOP THEN GOTO LBL_END;
        end;
        else
            Result := '';
    end;

LBL_END:

end;

procedure TStrConverter.Interrupt;
begin
    STOP := TRUE;
end;

end.
