unit fxASTUtils;

interface

uses
    fxUtils, fxStrUtils;

const
    
    { Parser predefined priorities }
    {
    FX_LAMBDA_PRIORITY         = -7; 
    FX_LET_PRIORITY            = -7;
    FX_WHERE_PRIORITY          = -6; 
    FX_TRY_PRIORITY            = -5; right
    FX_GUARD_PRIORITY          = -4; right
    FX_LIST_CONS_PRIORITY      = -3;
    FX_INDEX_PRIORITY          = -2;
    FX_TYPING_PRIORITY         = -1;
    FX_INFIX_MIN_PRIORITY      = 0;
    FX_INFIX_MAX_PRIORITY      = 255;
    FX_POSFIX_PRIORITY         = 256;
    FX_PREFIX_PRIORITY         = 257;
    FX_VALUE_PRIORITY          = 258;
    }
    { Abstract syntax tree node information }
    FX_ASTN_NONE               = 00;
    FX_ASTN_NUMBER             = 01;
    FX_ASTN_BOOLEAN            = 02;
    FX_ASTN_CHARACTER          = 03;
    FX_ASTN_STRING             = 04;
    FX_ASTN_ANONYMOUS          = 05;
    FX_ASTN_NULL_LIST          = 06;
    FX_ASTN_FAIL               = 07;
    FX_ASTN_IDENTIFIER         = 08;
    FX_ASTN_PRIMITIVE          = 09;
    FX_ASTN_RUN                = 10;
    FX_ASTN_CLEAR              = 11;
    FX_ASTN_INFIX              = 12;
    FX_ASTN_INFIXL             = 13;
    FX_ASTN_INFIXR             = 14;
    FX_ASTN_POSFIX             = 15;
    FX_ASTN_PREFIX             = 16;
    FX_ASTN_SYNONYMOUS         = 17;
    FX_ASTN_INHERITABLE        = 18;
    FX_ASTN_DEFINITION         = 19;
    FX_ASTN_GLOBAL_ASSIGNMENT  = 20;
    FX_ASTN_LET                = 21;
    FX_ASTN_WHERE              = 22;
    FX_ASTN_FUNCTION           = 23;
    FX_ASTN_TUPLE              = 24;
    FX_ASTN_LIST               = 25;
    FX_ASTN_APPLICATION        = 26;
    FX_ASTN_INDEX              = 27;
    FX_ASTN_LAMBDA             = 28;
    FX_ASTN_TRY                = 29;
    FX_ASTN_GUARD              = 30;
    FX_ASTN_LIST_COMPREHENSION = 31;
    FX_ASTN_LIST_CONSTRUCTOR   = 32;
    FX_ASTN_LIST_GENERATOR     = 33;
    FX_ASTN_LIST_SECUENCE      = 34;
    FX_ASTN_TYPING             = 35;
    FX_ASTN_ASSIGNMENT         = 36;
    FX_ASTN_IMPERATIVE         = 37;
    FX_ASTN_IF                 = 38;
    FX_ASTN_WHILE              = 39;
    FX_ASTN_FOR                = 40;
    FX_ASTN_RETURN             = 41;
    FX_ASTN_TYPE_BOOL          = 42;
    FX_ASTN_TYPE_CHAR          = 43;
    FX_ASTN_TYPE_INT           = 44;
    FX_ASTN_TYPE_NAT           = 45;
    FX_ASTN_TYPE_REAL          = 46;
    FX_ASTN_UNTITLED           = FX_ASTN_NONE;
    
type
    
    TAbstractSyntaxTreeData = packed record
        case Byte of
            0: (bValue: TFxBool);
            1: (cValue: TFxChar);
            4: (nValue: TFxNumber);
            5: (sValue: PFxString);
            7: (IdCode: Integer; IdLine: Integer);
    end;
    
    PAbstractSyntaxTreeNode = ^TAbstractSyntaxTreeNode;
    TAbstractSyntaxTreeNodeArray = array of PAbstractSyntaxTreeNode;
    TAbstractSyntaxTreeNode = record
        Kind: Byte;
        Childs: TAbstractSyntaxTreeNodeArray;
        D: TAbstractSyntaxTreeData;
    end;
    TAbstractSyntaxTree = PAbstractSyntaxTreeNode;
    TAbstractSyntaxTreeArray = TAbstractSyntaxTreeNodeArray;
    
    PASTListItem = ^TASTListItem;
    TASTListItem = record
        AST: TAbstractSyntaxTree;
        Sek: Byte;
        Next: PASTListItem;
    end;
    TAbstractSyntaxTreeStack = class(TObject)
    private
        FTop: PASTListItem;
        procedure DeleteFrom(var P: PASTListItem);
        function GetTopAST: TAbstractSyntaxTree;
        function GetTopSek: Byte;
    public
        constructor Create;
        destructor Destroy; override;
        
        procedure Push(var AST: TAbstractSyntaxTree; ASek: Byte);
        procedure Pop(var AST: TAbstractSyntaxTree; var ASek: Byte);
        procedure Clear;
        function IsEmpty: Boolean;
        property Top: TAbstractSyntaxTree read GetTopAST;
        property TopSek: Byte read GetTopSek;
    end;
    
    TAbstractSyntaxTreeList = class
    private
        FCount: Integer;
        function GetItem(Index: Integer): TAbstractSyntaxTree;
        procedure SetItem(Index: Integer; const Value: TAbstractSyntaxTree);
        procedure EnsureRoom;
    public
        List: array of TAbstractSyntaxTree;
        Seks: array of Byte;
        constructor Create;
        destructor Destroy; override;
        procedure Clear;
        procedure Add(var AST: TAbstractSyntaxTree; ASek: Byte);
        property Item[Index: Integer]: TAbstractSyntaxTree read GetItem write SetItem;
        property Count: Integer read FCount;
    end;
    
    PLayoutListItem = ^TLayoutListItem;
    TLayoutListItem = record
        Layout: Integer;
        Next: PLayoutListItem;
    end;
    TLayoutStack = class
    private
        FTop: PLayoutListItem;
        procedure DeleteFrom(var P: PLayoutListItem);
        function GetTopLayout: Integer;
    public
        constructor Create;
        destructor Destroy; override;
        
        procedure Push(var L: Integer);
        function Pop: Integer;
        procedure Clear;
        function IsEmpty: Boolean;
        property Top: Integer read GetTopLayout;
    end;

procedure MakeNoneASTBranch(var ABranch: TAbstractSyntaxTree);
procedure MakeFailASTBranch(var ABranch: TAbstractSyntaxTree);
procedure MakeTrivialASTBranch(var ABranch: TAbstractSyntaxTree);
procedure MakeHeadASTBranch(AKind: Byte; var ABranch: TAbstractSyntaxTree);
procedure MakeNumberASTBranch(N: TFxNumber; var ABranch: TAbstractSyntaxTree);
procedure MakeBoolASTBranch(B: TFxBool; var ABranch: TAbstractSyntaxTree);
procedure MakeCharASTBranch(C: TFxChar; var ABranch: TAbstractSyntaxTree);
procedure MakeStrASTBranch(S: TFxString; var ABranch: TAbstractSyntaxTree);
procedure MakeIdentifierASTBranch(AIdCode, AIdLine: Integer; var ABranch: TAbstractSyntaxTree);
procedure MakePrimASTBranch(AIdCode, AIdLine: Integer; var ABranch: TAbstractSyntaxTree);

procedure AddASTBranchChilds(var ABranch: TAbstractSyntaxTree; C: Integer = 1);
procedure CopyASTBranch(var ASourceBranch, ADestBranch: TAbstractSyntaxTree);
procedure EraseASTBranch(var ABranch: TAbstractSyntaxTree);
procedure EraseASTBranchChilds(var ABranch: TAbstractSyntaxTree);

implementation

procedure MakeNoneASTBranch(var ABranch: TAbstractSyntaxTree);                        
begin
    System.New(ABranch);
    with ABranch^ do begin
        Kind := FX_ASTN_NONE;
        Childs := nil;
    end;
end;

procedure MakeFailASTBranch(var ABranch: TAbstractSyntaxTree);                        
begin
    System.New(ABranch);
    with ABranch^ do begin
        Kind := FX_ASTN_FAIL;
        Childs := nil;
    end;
end;

procedure MakeTrivialASTBranch(var ABranch: TAbstractSyntaxTree);                     
begin
    System.New(ABranch);
    with ABranch^ do begin
        Kind := FX_ASTN_TUPLE;
        Childs := nil;
    end;
end;

procedure MakeHeadASTBranch(AKind: Byte; var ABranch: TAbstractSyntaxTree);           
begin
    System.New(ABranch);
    with ABranch^ do begin
        Kind := AKind;
        Childs := nil;
    end;
end;

procedure MakeNumberASTBranch(N: TFxNumber; var ABranch: TAbstractSyntaxTree);       
begin
    System.New(ABranch);
    with ABranch^ do begin
        Kind := FX_ASTN_NUMBER;
        D.nValue := N;
        Childs := nil;
    end;
end;

procedure MakeBoolASTBranch(B: TFxBool; var ABranch: TAbstractSyntaxTree);           
begin
    System.New(ABranch);
    with ABranch^ do begin
        Kind := FX_ASTN_BOOLEAN;
        D.bValue := B;
        Childs := nil;
    end;
end;

procedure MakeCharASTBranch(C: TFxChar; var ABranch: TAbstractSyntaxTree);           
begin
    System.New(ABranch);
    with ABranch^ do begin
        Kind := FX_ASTN_CHARACTER;
        D.cValue := C;
        Childs := nil;
    end;
end;

procedure MakeStrASTBranch(S: TFxString; var ABranch: TAbstractSyntaxTree);          
begin
    System.New(ABranch);
    with ABranch^ do begin
        Kind := FX_ASTN_STRING;
        System.New(D.sValue);
        D.sValue^ := S;
        Childs := nil;
    end;
end;

procedure MakeIdentifierASTBranch(AIdCode, AIdLine: Integer; var ABranch: TAbstractSyntaxTree);
begin
    System.New(ABranch);
    with ABranch^ do begin
        Kind := FX_ASTN_IDENTIFIER;
        D.IdCode := AIdCode;
        D.IdLine := AIdLine;
        Childs := nil;
    end;
end;

procedure MakePrimASTBranch(AIdCode, AIdLine: Integer; var ABranch: TAbstractSyntaxTree);      
begin
    System.New(ABranch);
    with ABranch^ do begin
        Kind := FX_ASTN_PRIMITIVE;
        D.IdCode := AIdCode;
        D.IdLine := AIdLine;
        Childs := nil;
    end;
end;

procedure AddASTBranchChilds(var ABranch: TAbstractSyntaxTree; C: Integer = 1);
var
    K, L: Integer;
begin
    L := Length(ABranch^.Childs);
    SetLength(ABranch^.Childs, L + C);
    for K := L to L + C - 1 do
        ABranch^.Childs[K] := nil;
end;

procedure CopyASTBranch(var ASourceBranch, ADestBranch: TAbstractSyntaxTree);
var
    K: Integer;
begin
    if ASourceBranch = nil then Exit;
    System.New(ADestBranch);
    ADestBranch^ := ASourceBranch^;
    if ASourceBranch^.Kind = FX_ASTN_STRING then begin
        System.New(ADestBranch^.D.sValue);
        ADestBranch^.D.sValue^ := ASourceBranch^.D.sValue^;
    end;
    ADestBranch^.Childs := nil;
    SetLength(ADestBranch^.Childs, Length(ASourceBranch^.Childs));
    for K := 0 to Length(ADestBranch^.Childs) - 1 do begin
        ADestBranch^.Childs[K] := nil;
        CopyASTBranch(ASourceBranch^.Childs[K], ADestBranch^.Childs[K]);
    end;
end;

procedure EraseASTBranch(var ABranch: TAbstractSyntaxTree);
var
    K: Integer;
begin
    if ABranch <> nil then begin
        for K := 0 to Length(ABranch^.Childs) - 1 do
            EraseASTBranch(ABranch^.Childs[K]);
        if ABranch^.Kind = FX_ASTN_STRING then begin
            ABranch^.D.sValue^ := '';
            Dispose(ABranch^.D.sValue);
        end;
        ABranch^.Childs := nil;
        Dispose(ABranch);
        ABranch := nil;
    end;
end;

procedure EraseASTBranchChilds(var ABranch: TAbstractSyntaxTree);
var
    K: Integer;
begin
    if ABranch <> nil then begin
        for K := 0 to Length(ABranch^.Childs) - 1 do
            EraseASTBranch(ABranch^.Childs[K]);
        ABranch^.Childs := nil;
    end;
end;

//-------------------------------------------------------------

{ TAbstractSyntaxTreeStack }

constructor TAbstractSyntaxTreeStack.Create;
begin
    inherited Create;
    FTop := nil;
end;

destructor TAbstractSyntaxTreeStack.Destroy;
begin
    Clear;
    inherited;
end;

procedure TAbstractSyntaxTreeStack.DeleteFrom(var P: PASTListItem);
begin
    if P <> nil then begin
        DeleteFrom(P^.Next);
        EraseASTBranch(P^.AST);
        System.Dispose(P);
        P := nil;
    end;
end;

function TAbstractSyntaxTreeStack.GetTopAST: TAbstractSyntaxTree;
begin
    if FTop = nil then
        Result := nil
    else
        Result := FTop^.AST;
end;

function TAbstractSyntaxTreeStack.GetTopSek: Byte;
begin
    if FTop = nil then
        Result := 0
    else
        Result := FTop^.Sek;
end;

procedure TAbstractSyntaxTreeStack.Push(var AST: TAbstractSyntaxTree; ASek: Byte);
var
    N: PASTListItem;
begin
    System.New(N);
    N^.AST := AST;
    N^.Sek := ASek;
    AST := nil;
    N^.Next := FTop;
    FTop := N;
    N := nil;
end;

procedure TAbstractSyntaxTreeStack.Pop(var AST: TAbstractSyntaxTree; var ASek: Byte);
var
    N: PASTListItem;
begin
    if FTop <> nil then begin
        N := FTop;
        FTop := FTop^.Next;
        N^.Next := nil;
        AST := N^.AST;
        ASek := N^.Sek;
        N^.AST := nil;
        System.Dispose(N);
    end
    else
        AST := nil;
end;

procedure TAbstractSyntaxTreeStack.Clear;
begin
    DeleteFrom(FTop);
end;

function TAbstractSyntaxTreeStack.IsEmpty: Boolean;
begin
    Result := FTop = nil;
end;

{ TAbstractSyntaxTreeList }

constructor TAbstractSyntaxTreeList.Create;
begin
    inherited Create;
    List := nil;
    Seks := nil;
    FCount := 0;
end;

destructor TAbstractSyntaxTreeList.Destroy;
begin
    Clear;
    inherited;
end;

function TAbstractSyntaxTreeList.GetItem(Index: Integer): TAbstractSyntaxTree;
begin
    if (Index >= 0) and (Index < FCount) then
        Result := List[Index]
    else
        Result := nil;
end;

procedure TAbstractSyntaxTreeList.SetItem(Index: Integer; const Value: TAbstractSyntaxTree);
begin
    if (Index >= 0) and (Index < FCount) then
        List[Index] := Value;
end;

procedure TAbstractSyntaxTreeList.EnsureRoom;
begin
    if FCount >= System.Length(List) then begin
        SetLength(List, FCount + 32);
        SetLength(Seks, FCount + 32);
    end;
end;

procedure TAbstractSyntaxTreeList.Clear;
var
    K: Integer;
begin
    for K := 0 to FCount - 1 do
        EraseASTBranch(List[K]);
    List := nil;
    Seks := nil;
end;

procedure TAbstractSyntaxTreeList.Add(var AST: TAbstractSyntaxTree; ASek: Byte);
begin
    EnsureRoom;
    Seks[FCount] := ASek;
    List[FCount] := AST;
    AST := nil;
    Inc(FCount);
end;

{ TLayoutStack }

constructor TLayoutStack.Create;
begin
    inherited Create;
    FTop := nil;
end;

destructor TLayoutStack.Destroy;
begin
    Clear;
    inherited;
end;

procedure TLayoutStack.DeleteFrom(var P: PLayoutListItem);
begin
    if P <> nil then begin
        DeleteFrom(P^.Next);
        System.Dispose(P);
        P := nil;
    end;
end;

function TLayoutStack.GetTopLayout: Integer;
begin
    if FTop = nil then
        Result := 0
    else
        Result := FTop^.Layout;
end;

procedure TLayoutStack.Push(var L: Integer);
var
    N: PLayoutListItem;
begin
    System.New(N);
    N^.Layout := L;
    N^.Next := FTop;
    FTop := N;
    N := nil;
end;

function TLayoutStack.Pop: Integer;
var
    N: PLayoutListItem;
begin
    if FTop <> nil then begin
        N := FTop;
        FTop := FTop^.Next;
        N^.Next := nil;
        Result := N^.Layout;
        System.Dispose(N);
    end
    else
        Result := 0;
end;

procedure TLayoutStack.Clear;
begin
    DeleteFrom(FTop);
end;

function TLayoutStack.IsEmpty: Boolean;
begin
    Result := FTop = nil;
end;

end.
