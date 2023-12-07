unit fxStdStreams;

interface

uses
    SysUtils, fxUtils, fxStrUtils;

type
    
    TScriptStream = class(TFxObject, IStream)
    private
        FrontEnd: IFrontEndListener;

        FCaption: string;
        FText: TFxString;
        FLines: TIntArray; // line per char: length(FLines) = length(FText) + 1
        FCols: TIntArray; // col per char: length(FCols) = length(FText) + 1
        procedure CalculateLineCols;
    public
        constructor Create(AFrontEnd: IFrontEndListener);
        destructor Destroy; override;
        procedure Init;
        function LoadFromFile(FileName: TFileName): Boolean;
        { listener }
        function GetItem(AIndex: Integer): Char;
        function ColFromPos(APos: Integer): Integer;
        function LineFromPos(APos: Integer): Integer;
        function GetCaption: string;
        function GetRange(AFrom, ATo: Integer): TFxString;
        function Length: Integer;
        function TabSize: Integer;
        procedure MarkLine(ALine: Integer);
        property Item[AIndex: Integer]: Char read GetItem; default;
    end;
    
    TInputStream = class(TFxObject, IStream)
    private
        FrontEnd: IFrontEndListener;
        
        FPrompterSize: Integer;
        FCaption: string;
        FText: TFxString;
        FCols: TIntArray; // col per char
        FLines: TIntArray; // line per char
        
        FNeedsEoL: Boolean; // internal variable for adding multiple lines
    protected
        procedure CalculateLineCols; virtual;
        property Cols: TIntArray read FCols;
        property Lines: TIntArray read FLines;
    public
        constructor Create(AFrontEnd: IFrontEndListener);
        destructor Destroy; override;
        procedure Init; virtual;
        function Load(S: string): Boolean;
        
        procedure BeginReadLine;
        function AddLine(S: string): Boolean;
        procedure EndReadLine;
        { listener }
        function GetItem(Index: Integer): Char;
        function ColFromPos(P: Integer): Integer;
        function LineFromPos(P: Integer): Integer;
        function GetCaption: string;
        function GetRange(AFrom, ATo: Integer): TFxString;
        function Length: Integer;
        function TabSize: Integer;
        procedure MarkLine(ALine: Integer); virtual;
        property PrompterSize: Integer read FPrompterSize write FPrompterSize;
        property Item[Index: Integer]: Char read GetItem; default;
    end;
    
implementation

{ TScriptStream }

constructor TScriptStream.Create(AFrontEnd: IFrontEndListener);
begin
    inherited Create;
    FrontEnd := AFrontEnd;
    Init;
end;

destructor TScriptStream.Destroy;                              
begin
    Init;
    inherited;
end;

procedure TScriptStream.Init;
begin
    FCaption := '';
    FText := '';
    SetLength(FCols, 1);
    SetLength(FLines, 1);
    FCols[0] := 0;
    FLines[0] := 0;
end;

procedure TScriptStream.CalculateLineCols;
var
    K, T, C, R, W: Integer;
begin
    T := TabSize;
    SetLength(FCols, Length + 1);
    SetLength(FLines, Length + 1);
    C := 0;
    R := 0;
    K := 0;
    while K < Length do begin
        FLines[K] := R;
        FCols[K] := C;
        if Item[K] = FX_EOL_LF then begin
            C := 0;
            Inc(R);
            Inc(K);
        end
        else if Item[K] = FX_EOL_CR then begin
            C := 0;
            Inc(K);
            if (K < Length) and (Item[K] = FX_EOL_LF) then
                Inc(K);
            Inc(R);
        end
        else if Item[K] = #9 then begin
            C := C + T - (C mod T);
            Inc(K);
        end
        else begin
            Inc(C);
            Inc(K);
        end;
    end;
    FCols[Length] := C;
    FLines[Length] := R;
end;

function TScriptStream.LoadFromFile(FileName: TFileName): Boolean;    
var
    F: ANSIFILE;
    K: Integer;
    S: AnsiString;
    Ch: AnsiChar;
begin
    AssignFile(F, FileName);
    {$I-}
    Reset(F);
    {$I+}
    Result := IOResult = 0;
    if Result then begin
        Init;
        FCaption := FileName;
        K := 1;
        SetLength(S, FileSize(F));
        while not EoF(F) do begin
            Read(F, Ch);
            S[K] := Ch;
            Inc(K);
        end;
        CloseFile(F);
        FText := Utf8ToString(S);
        CalculateLineCols;
    end;
end;

function TScriptStream.GetItem(AIndex: Integer): Char;                  
begin
    if (AIndex >= 0) and (AIndex < Length) then
        Result := FText[AIndex + 1]
    else
        Result := #0;
end;

function TScriptStream.GetRange(AFrom, ATo: Integer): TFxString;
begin
    Result := System.Copy(FText, AFrom, ATo - AFrom);
end;

function TScriptStream.ColFromPos(APos: Integer): Integer;
begin
    if APos < 0 then Result := -1
    else if (APos <= Length) then
        Result := FCols[APos]
    else
        Result := -1;
end;

function TScriptStream.LineFromPos(APos: Integer): Integer;
begin
    if APos < 0 then Result := -1
    else if (APos <= Length) then
        Result := FLines[APos]
    else
        Result := -1;
end;

function TScriptStream.GetCaption: string;
begin
    Result := FCaption;
end;

function TScriptStream.Length: Integer;
begin
    Result := System.Length(FText);
end;

function TScriptStream.TabSize: Integer;
begin
    Result := ScriptTabSize;
end;

procedure TScriptStream.MarkLine(ALine: Integer);
begin
end;

{ TInputStream }

constructor TInputStream.Create(AFrontEnd: IFrontEndListener);
begin
    inherited Create;
    FrontEnd := AFrontEnd;
    Init;
end;

destructor TInputStream.Destroy;
begin
    Init;
    inherited;
end;

procedure TInputStream.Init;
begin
    FCaption := '';
    FText := '';
    FCols := nil;
    FLines := nil;
    SetLength(FCols, 1);
    FCols[0] := FPrompterSize;
    SetLength(FLines, 1);
    FLines[0] := 0;
    FNeedsEoL := False;
end;

procedure TInputStream.CalculateLineCols;
var
    K, T, C, R: Integer;
begin
    T := TabSize;
    SetLength(FCols, Self.Length + 1);
    SetLength(FLines, Self.Length + 1);
    C := FPrompterSize;
    R := 0;
    K := 1;
    while K <= Self.Length do begin
        FCols[K - 1] := C;
        FLines[K - 1] := R;
        if FText[K] = FX_EOL_LF then begin
            C := FPrompterSize;
            Inc(K);
            Inc(R);
        end
        else if FText[K] = FX_EOL_CR then begin
            C := FPrompterSize;
            Inc(K);
            if (K <= Self.Length) and (FText[K] = FX_EOL_LF) then
                Inc(K);
            Inc(R);
        end
        else if FText[K] = #9 then begin
            C := C + T - (C mod T);
            Inc(K);
        end
        else begin
            Inc(C);
            Inc(K);
        end;
    end;
    FCols[Self.Length] := C;
    FLines[Self.Length] := R;
end;

function TInputStream.Load(S: string): Boolean;
begin
    Init;
    FText := S;
    CalculateLineCols;
    FNeedsEoL := True;
    Result := True;
end;

procedure TInputStream.BeginReadLine;
begin
    Init;
end;

function TInputStream.AddLine(S: string): Boolean;
begin
    if FNeedsEoL then 
        FText := FText + GetStdEoL + S
    else
        FText := FText + S;
    FNeedsEoL := True;
    Result := S <> '';
end;

procedure TInputStream.EndReadLine;
begin
    CalculateLineCols;
    FNeedsEoL := True;
end;

function TInputStream.GetItem(Index: Integer): Char;
begin
    if (Index >= 0) and (Index < Self.Length) then
        Result := FText[Index + 1]
    else
        Result := #0;
end;

function TInputStream.ColFromPos(P: Integer): Integer;
begin
    if P < 0 then
        Result := -1
    else if P <= Self.Length then
        Result := FCols[P]
    else
        Result := -1;
end;

function TInputStream.LineFromPos(P: Integer): Integer;
begin
    if P < 0 then
        Result := -1
    else if P <= Self.Length then
        Result := FLines[P]
    else
        Result := -1;
end;

function TInputStream.GetCaption: string;
begin
    Result := FCaption;
end;

function TInputStream.GetRange(AFrom, ATo: Integer): TFxString;
begin
    Result := System.Copy(FText, AFrom, ATo - AFrom);
end;

function TInputStream.Length: Integer;
begin
    Result := System.Length(FText);
end;

function TInputStream.TabSize: Integer;
begin
    Result := InputTabSize;
end;

procedure TInputStream.MarkLine(ALine: Integer);
begin
end;

end.
