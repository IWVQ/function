unit fxBasicStructure;

interface

uses
    fxMath, fxUtils;

const
    
    { Type expression node information }
    
    FX_TN_NONE       = 0;
    
    FX_TN_REAL       = 1;
    FX_TN_INTEGER    = 2;
    FX_TN_NATURAL    = 3;
    FX_TN_BOOLEAN    = 4;
    FX_TN_CHARACTER  = 5;
    FX_TN_IDENTIFIER = 6;
    FX_TN_ANONYMOUS  = 7;
    
    FX_TN_TUPLE      = 8;
    FX_TN_LIST       = 9;
    FX_TN_FUNCTION   = 10;
    
    { Value expression node information }
    
    FX_VN_NONE        = 0; // usado en inicializacion y ramificacion de informacion de tipo
    
    FX_VN_NUMBER      = 1;
    FX_VN_BOOLEAN     = 4;
    FX_VN_CHARACTER   = 5;
    FX_VN_NULL        = 6; // la cadena vacia no es mas que una lista vacia
    FX_VN_FAIL        = 7;
    FX_VN_IDENTIFIER  = 8; // necesario hacer explicito informacion de tipo
    FX_VN_PRIMITIVE   = 9; // funciones primitivas
    FX_VN_ANONYMOUS   = 10;
    
    FX_VN_TRY         = 11; // atrapa los fallos y aisla la llamada a error
    FX_VN_TUPLE       = 12; // incluye tupla trivial
    FX_VN_LIST_CONS   = 13;
    FX_VN_LAMBDA      = 14;
    FX_VN_APPLICATION = 15;
    
    FX_PN_NONE        = FX_VN_NONE;
    
    FX_PN_NUMBER      = FX_VN_NUMBER;
    FX_PN_BOOLEAN     = FX_VN_BOOLEAN;
    FX_PN_CHARACTER   = FX_VN_CHARACTER;
    FX_PN_NULL        = FX_VN_NULL;
    FX_PN_FAIL        = FX_VN_FAIL;
    FX_PN_IDENTIFIER  = FX_VN_IDENTIFIER;
    FX_PN_ANONYMOUS   = FX_VN_ANONYMOUS;
    
    FX_PN_TUPLE       = FX_VN_TUPLE;
    FX_PN_LIST_CONS   = FX_VN_LIST_CONS;
    
type
    
    { Type expression tree }
    
    PTypeExprNode = ^TTypeExprNode;
    TTypeExprNodeChilds = array of PTypeExprNode;
    TTypeExprNode = record
        tKind: Byte;
        Childs: TTypeExprNodeChilds;
        tIdCode: Integer;
    end;
    TTypeExpr = PTypeExprNode;
    TTypeExprArray = array of TTypeExpr;
    
    { Value expression tree }
    
    TValueExprData = packed record
        case Byte of
            0: (bValue: TFxBool);
            1: (cValue: TFxChar);
            4: (nValue: TFxNumber);
            5: (vIdCode, tIdCode: Integer; tKind: Byte);
    end;
    
    PValueExprNode = ^TValueExprNode;
    TValueExprNodeChilds = array of PValueExprNode;
    TValueExprNode = record
        vKind: Byte;
        Childs: TValueExprNodeChilds;
        D: TValueExprData;
    end;
    TValueExpr = PValueExprNode;
    TPatternExpr = PValueExprNode;
    TValueExprArray = array of TValueExpr;
    TPatternExprArray = array of TPatternExpr;
    
    TNotationPriority = Byte;
    TNotationPosition = (npPrefix, npPosfix, npInfix, npInfixl, npInfixr);
    TNotation = record
        Priority: TNotationPriority;
        Position: TNotationPosition;
    end;

    { Type expression tree routines }
    
procedure MakeNoneTypeBranch(var ABranch: TTypeExpr);
procedure MakeHeadTypeBranch(K: Byte; var ABranch: TTypeExpr);
procedure MakeTrivialTypeBranch(var ABranch: TTypeExpr);
procedure MakeIdentifierTypeBranch(AIdCode: Integer; var ABranch: TTypeExpr);

procedure EraseTypeBranch(var ABranch: TTypeExpr);
procedure EraseTypeBranchChilds(var ABranch: TTypeExpr);
procedure CopyTypeBranch(var ASourceBranch, ADestBranch: TTypeExpr);
procedure CopyTypeBranchAsValueBranch(var ATypeSourceBranch: TTypeExpr; var AValueDestBranch: TValueExpr);
procedure CopyTypeBranchToValueBranch(var ATypeSourceBranch: TTypeExpr; var AValueDestBranch: TValueExpr);
procedure AddTypeBranchChilds(var ABranch: TTypeExpr; C: Integer = 1);

    { Value expression tree routines }

procedure MakeNoneValueBranch(var ABranch: TValueExpr);
procedure MakeNumberValueBranch(N: TFxNumber; var ABranch: TValueExpr);
procedure MakeBoolValueBranch(B: TFxBool; var ABranch: TValueExpr);
procedure MakeCharValueBranch(C: TFxChar; var ABranch: TValueExpr);
procedure MakeHeadValueBranch(K: Byte; var ABranch: TValueExpr);
procedure MakeFailValueBranch(var ABranch: TValueExpr);
procedure MakeTrivialValueBranch(var ABranch: TValueExpr);
procedure MakeStrValueBranch(AStr: TFxString; var ABranch: TValueExpr);
procedure MakeIdentifierValueBranch(AIdCode: Integer; var ABranch: TValueExpr);
procedure MakePrimValueBranch(AIdCode: Integer; var ABranch: TValueExpr);

procedure MakeNoneValueTypeBranch(var ABranch: TValueExpr);
procedure MakeHeadValueTypeBranch(K: Byte; var ABranch: TValueExpr);
procedure MakeTrivialValueTypeBranch(var ABranch: TValueExpr);
procedure MakeIdentifierValueTypeBranch(AIdCode: Integer; var ABranch: TValueExpr);

function ValueIsRealNumber(var ANode: TValueExpr; out N: TFxReal): Boolean;
function ValueIsIntegerNumber(var ANode: TValueExpr; out N: TFxInteger): Boolean;
function ValueIsNaturalNumber(var ANode: TValueExpr; out N: TFxInteger): Boolean;

procedure EraseValueBranch(var ABranch: TValueExpr);
procedure EraseValueBranchChilds(var ABranch: TValueExpr);
procedure CopyValueBranch(var ASourceBranch, ADestBranch: TValueExpr);
procedure CopyValueBranchTo(var ASourceBranch, ADestBranch: TValueExpr);
procedure CopyTypeFromValueBranch(var ASourceValueBranch: TValueExpr; var ADestTypeBranch: TTypeExpr);
procedure AddValueBranchChilds(var ABranch: TValueExpr; C: Integer = 1);

implementation

    { Type expression tree }

procedure MakeNoneTypeBranch(var ABranch: TTypeExpr);
begin
    System.New(ABranch);
    with ABranch^ do begin
        tKind := FX_TN_NONE;
        Childs := nil;
        tIdCode := 0;
    end;
end;

procedure MakeHeadTypeBranch(K: Byte; var ABranch: TTypeExpr);
begin
    System.New(ABranch);
    with ABranch^ do begin
        tKind := K;
        Childs := nil;
        tIdCode := 0;
    end;
end;

procedure MakeTrivialTypeBranch(var ABranch: TTypeExpr);
begin
    System.New(ABranch);
    with ABranch^ do begin
        tKind := FX_TN_TUPLE;
        Childs := nil;
        tIdCode := 0;
    end;
end;

procedure MakeIdentifierTypeBranch(AIdCode: Integer; var ABranch: TTypeExpr);
begin
    System.New(ABranch);
    with ABranch^ do begin
        tKind := FX_TN_IDENTIFIER;
        Childs := nil;
        tIdCode := AIdCode;
    end;
end;

procedure EraseTypeBranch(var ABranch: TTypeExpr);
var
    K: Integer;
begin
    if ABranch <> nil then begin
        for K := 0 to Length(ABranch^.Childs) - 1 do
            EraseTypeBranch(ABranch^.Childs[K]);
        ABranch^.Childs := nil;
        Dispose(ABranch);
        ABranch := nil;
    end;
end;

procedure EraseTypeBranchChilds(var ABranch: TTypeExpr);
var
    K: Integer;
begin
    if ABranch <> nil then begin
        for K := 0 to Length(ABranch^.Childs) - 1 do
            EraseTypeBranch(ABranch^.Childs[K]);
        ABranch^.Childs := nil;
    end;
end;

procedure CopyTypeBranch(var ASourceBranch, ADestBranch: TTypeExpr);
var
    K: Integer;
begin
    if ASourceBranch = nil then Exit;
    System.New(ADestBranch);
    ADestBranch^ := ASourceBranch^;
    ADestBranch^.Childs := nil;
    SetLength(ADestBranch^.Childs, Length(ASourceBranch^.Childs));
    for K := 0 to Length(ADestBranch^.Childs) - 1 do begin
        ADestBranch^.Childs[K] := nil;
        CopyTypeBranch(ASourceBranch^.Childs[K], ADestBranch^.Childs[K]);
    end;
end;

procedure CopyTypeBranchAsValueBranch(var ATypeSourceBranch: TTypeExpr; var AValueDestBranch: TValueExpr);
var
    K: Integer;
begin
    if ATypeSourceBranch = nil then Exit;
    System.New(AValueDestBranch);
    with AValueDestBranch^ do begin
        vKind := FX_VN_NONE;
        D.vIdCode := 0;
        D.tIdCode := ATypeSourceBranch^.tIdCode;
        D.tKind := ATypeSourceBranch^.tKind;
        SetLength(Childs, Length(ATypeSourceBranch^.Childs));
        for K := 0 to Length(Childs) - 1 do begin
            Childs[K] := nil;
            CopyTypeBranchAsValueBranch(ATypeSourceBranch^.Childs[K], Childs[K]);
        end;
    end;
end;

procedure CopyTypeBranchToValueBranch(var ATypeSourceBranch: TTypeExpr; var AValueDestBranch: TValueExpr);
var
    K: Integer;
begin
    if AValueDestBranch = nil then Exit;
    if ATypeSourceBranch = nil then Exit;
    with AValueDestBranch^ do begin
        // para el primer nodo solo copia el tipo
        D.tIdCode := ATypeSourceBranch^.tIdCode;
        D.tKind := ATypeSourceBranch^.tKind;
        SetLength(Childs, Length(ATypeSourceBranch^.Childs));
        for K := 0 to Length(Childs) - 1 do begin
            Childs[K] := nil;
            CopyTypeBranchAsValueBranch(ATypeSourceBranch^.Childs[K], Childs[K]);
        end;
    end;
end;

procedure AddTypeBranchChilds(var ABranch: TTypeExpr; C: Integer = 1);
var
    I, K, L: Integer;
begin
    K := Length(ABranch^.Childs);
    L := K + C;
    SetLength(ABranch^.Childs, L);
    for I := K to L - 1 do
        ABranch^.Childs[I] := nil;
end;

    { Value expression tree }

procedure MakeNoneValueBranch(var ABranch: TValueExpr);
begin
    System.New(ABranch);
    FillChar(ABranch^, SizeOf(TValueExprNode), 0);
    with ABranch^ do begin
        vKind := FX_VN_NONE;
        Childs := nil;
    end;
end;

procedure MakeNumberValueBranch(N: TFxNumber; var ABranch: TValueExpr);
begin
    System.New(ABranch);
    FillChar(ABranch^, SizeOf(TValueExprNode), 0);
    with ABranch^ do begin
        vKind := FX_VN_NUMBER;
        D.nValue := N;
        Childs := nil;
    end;
end;

procedure MakeBoolValueBranch(B: TFxBool; var ABranch: TValueExpr);
begin
    System.New(ABranch);
    FillChar(ABranch^, SizeOf(TValueExprNode), 0);
    with ABranch^ do begin
        vKind := FX_VN_BOOLEAN;
        D.bValue := B;
        Childs := nil;
    end;
end;

procedure MakeCharValueBranch(C: TFxChar; var ABranch: TValueExpr);
begin
    System.New(ABranch);
    FillChar(ABranch^, SizeOf(TValueExprNode), 0);
    with ABranch^ do begin
        vKind := FX_VN_CHARACTER;
        D.cValue := C;
        Childs := nil;
    end;
end;

procedure MakeHeadValueBranch(K: Byte; var ABranch: TValueExpr);
begin
    System.New(ABranch);
    FillChar(ABranch^, SizeOf(TValueExprNode), 0);
    with ABranch^ do begin
        vKind := K;
        Childs := nil;
    end;
end;

procedure MakeFailValueBranch(var ABranch: TValueExpr);
begin
    System.New(ABranch);
    FillChar(ABranch^, SizeOf(TValueExprNode), 0);
    with ABranch^ do begin
        vKind := FX_VN_FAIL;
        Childs := nil;
    end;
end;

procedure MakeTrivialValueBranch(var ABranch: TValueExpr);
begin
    System.New(ABranch);
    FillChar(ABranch^, SizeOf(TValueExprNode), 0);
    with ABranch^ do begin
        vKind := FX_VN_TUPLE;
        Childs := nil;
    end;
end;

procedure MakeStrValueBranch(AStr: TFxString; var ABranch: TValueExpr);
var
    TailBranch: TValueExpr;
    K: Integer;
begin
    System.New(ABranch);
    TailBranch := ABranch;
    for K := 1 to Length(AStr) do begin
        FillChar(TailBranch^, SizeOf(TValueExprNode), 0);
        TailBranch^.vKind := FX_VN_LIST_CONS;
        SetLength(TailBranch^.Childs, 2);
        System.New(TailBranch^.Childs[0]);
        TailBranch^.Childs[0]^.vKind := FX_VN_CHARACTER;
        TailBranch^.Childs[0]^.Childs := nil;
        TailBranch^.Childs[0]^.D.cValue := AStr[K];
        System.New(TailBranch^.Childs[1]);
        TailBranch := TailBranch^.Childs[1];
    end;
    FillChar(TailBranch^, SizeOf(TValueExprNode), 0);
    TailBranch^.vKind := FX_VN_NULL;
    TailBranch^.Childs := nil;
end;

procedure MakeIdentifierValueBranch(AIdCode: Integer; var ABranch: TValueExpr);
begin
    System.New(ABranch);
    FillChar(ABranch^, SizeOf(TValueExprNode), 0);
    with ABranch^ do begin
        vKind := FX_VN_IDENTIFIER;
        D.tKind := FX_TN_NONE;
        D.vIdCode := AIdCode;
        Childs := nil;
    end;
end;

procedure MakePrimValueBranch(AIdCode: Integer; var ABranch: TValueExpr);
begin
    System.New(ABranch);
    FillChar(ABranch^, SizeOf(TValueExprNode), 0);
    with ABranch^ do begin
        vKind := FX_VN_PRIMITIVE;
        D.tKind := FX_TN_NONE;
        D.vIdCode := AIdCode;
        Childs := nil;
    end;
end;

//--

procedure MakeNoneValueTypeBranch(var ABranch: TValueExpr);
begin
    System.New(ABranch);
    FillChar(ABranch^, SizeOf(TValueExprNode), 0);
    with ABranch^ do begin
        vKind := FX_VN_NONE;
        D.vIdCode := 0;
        D.tIdCode := 0;
        D.tKind := FX_TN_NONE;
        Childs := nil;
    end;
end;

procedure MakeHeadValueTypeBranch(K: Byte; var ABranch: TValueExpr);
begin
    System.New(ABranch);
    FillChar(ABranch^, SizeOf(TValueExprNode), 0);
    with ABranch^ do begin
        vKind := FX_VN_NONE;
        D.vIdCode := 0;
        D.tIdCode := 0;
        D.tKind := K;
        Childs := nil;
    end;
end;

procedure MakeTrivialValueTypeBranch(var ABranch: TValueExpr);
begin
    System.New(ABranch);
    FillChar(ABranch^, SizeOf(TValueExprNode), 0);
    with ABranch^ do begin
        vKind := FX_VN_NONE;
        D.vIdCode := 0;
        D.tIdCode := 0;
        D.tKind := FX_TN_TUPLE;
        Childs := nil;
    end;
end;

procedure MakeIdentifierValueTypeBranch(AIdCode: Integer; var ABranch: TValueExpr);
begin
    System.New(ABranch);
    FillChar(ABranch^, SizeOf(TValueExprNode), 0);
    with ABranch^ do begin
        vKind := FX_VN_NONE;
        D.vIdCode := 0;
        D.tIdCode := AIdCode;
        D.tKind := FX_TN_IDENTIFIER;
        Childs := nil;
    end;
end;

//--

function ValueIsRealNumber(var ANode: TValueExpr; out N: Extended): Boolean;
begin
    if ANode^.vKind = FX_VN_NUMBER then begin
        N := ANode^.D.nValue;
        Result := True;
    end
    else
        Result := False;
end;

function ValueIsIntegerNumber(var ANode: TValueExpr; out N: TFxInteger): Boolean;
var
    R: TFxNumber;
begin
    if ANode^.vKind = FX_VN_NUMBER then begin
        R := ANode^.D.nValue;
        Result := nIsInt(R);
        if Result then
            N := nITrunc(R);
    end
    else
        Result := False;
end;

function ValueIsNaturalNumber(var ANode: TValueExpr; out N: TFxInteger): Boolean;
var
    R: TFxNumber;
begin
    if ANode^.vKind = FX_VN_NUMBER then begin
        R := ANode^.D.nValue;
        Result := nIsNat(R);
        if Result then
            N := nITrunc(R);
    end
    else
        Result := False;
end;

procedure EraseValueBranch(var ABranch: TValueExpr);
var
    K: Integer;
begin
    if ABranch <> nil then begin
        for K := 0 to Length(ABranch^.Childs) - 1 do
            EraseValueBranch(ABranch^.Childs[K]);
        ABranch^.Childs := nil;
        Dispose(ABranch);
        ABranch := nil;
    end;
end;

procedure EraseValueBranchChilds(var ABranch: TValueExpr);
var
    K: Integer;
begin
    if ABranch <> nil then begin
        for K := 0 to Length(ABranch^.Childs) - 1 do
            EraseValueBranch(ABranch^.Childs[K]);
        ABranch^.Childs := nil;
    end;
end;

procedure CopyValueBranch(var ASourceBranch, ADestBranch: TValueExpr);
var
    K: Integer;
    L: Integer;
begin
    if ASourceBranch = nil then Exit;
    System.New(ADestBranch);
    ADestBranch^ := ASourceBranch^;
    ADestBranch^.Childs := nil;
    SetLength(ADestBranch^.Childs, Length(ASourceBranch^.Childs));
    for K := 0 to Length(ADestBranch^.Childs) - 1 do begin
        ADestBranch^.Childs[K] := nil;
        CopyValueBranch(ASourceBranch^.Childs[K], ADestBranch^.Childs[K]);
    end;
end;

procedure CopyValueBranchTo(var ASourceBranch, ADestBranch: TValueExpr);
var
    K: Integer;
begin
    if ASourceBranch = nil then Exit;
    ADestBranch^ :=  ASourceBranch^;
    ADestBranch^.Childs := nil;
    SetLength(ADestBranch^.Childs, Length(ASourceBranch^.Childs));
    for K := 0 to Length(ADestBranch^.Childs) - 1 do begin
        ADestBranch^.Childs[K] := nil;
        CopyValueBranch(ASourceBranch^.Childs[K], ADestBranch^.Childs[K]);
    end;
end;

procedure CopyTypeFromValueBranch(var ASourceValueBranch: TValueExpr; var ADestTypeBranch: TTypeExpr);
var
    K: Integer;
begin
    if ASourceValueBranch = nil then Exit;
    System.New(ADestTypeBranch);
    
    ADestTypeBranch^.tKind := ASourceValueBranch^.D.tKind;
    ADestTypeBranch^.tIdCode := ASourceValueBranch^.D.tIdCode;
    ADestTypeBranch^.Childs := nil;
    
    SetLength(ADestTypeBranch^.Childs, Length(ASourceValueBranch^.Childs));
    for K := 0 to Length(ADestTypeBranch^.Childs) - 1 do begin
        ADestTypeBranch^.Childs[K] := nil;
        CopyTypeFromValueBranch(ASourceValueBranch^.Childs[K], ADestTypeBranch^.Childs[K]);
    end;
end;

procedure AddValueBranchChilds(var ABranch: TValueExpr; C: Integer = 1);
var
    I, K, L: Integer;
begin
    K := Length(ABranch^.Childs);
    L := K + C;
    SetLength(ABranch^.Childs, L);
    for I := K to L - 1 do
        ABranch^.Childs[I] := nil;
end;

end.
