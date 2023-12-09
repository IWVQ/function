unit fxCLIShell;

interface

uses
    SysUtils, Crt, fxUtils, fxError, fxStdStreams, fxStrUtils,
    fxStorage, fxInterpreter;

const
    FxVersion = 'v0.5';    
    FX_CONSOLE_HEADER = 'Function %s Copyright (c) Ivar Wiligran Vilca Quispe';

const

    FX_ARROW_PROMPTER = '>>> ';
    FX_SPACE_PROMPTER = '... ';

    CONSOLE_FOREGROUND = Crt.White;
    HEADER_FOREGROUND = Crt.LightBlue;
    PROMPTER_FOREGROUND = Crt.Brown;
    OUTPUT_FOREGROUND = Crt.LightGray;
    INPUT_FOREGROUND = Crt.LightGray;
    ERROR_FOREGROUND = Crt.LightRed;

    FX_PRELUDE_SCRIPT = 'run "scripts\\prelude.fx"';
    FX_HELPER_SCRIPT = 'run "scripts\\helper.fx"';

type

    TConsoleStream = class(TInputStream)
    private
        FLineWidths: TIntArray;
        FFirstLineRow: Integer;
    protected
        procedure CalculateLineCols; override;
        property LineWidths: TIntArray read FLineWidths;
    public
        procedure Init; override;
        procedure MarkLine(ALine: Integer); override;
        property FirstLineRow: Integer read FFirstLineRow write FFirstLineRow;
    end;

    TFrontEnd = class(TFxObject, IFrontEndListener)
        function InputStr: TFxString;
        procedure OutputStr(S: TFxString);
        procedure ClearScreen;

        procedure PrintOutput(S: TFxString);
        procedure PrintError(S: TFxString);
        procedure PrintAnswer(S: TFxString);
        procedure DoOnStartRun;
        procedure DoOnEndRun;

        procedure DoQuit;
        procedure DoInterrupt;
        procedure DoRestart;
        procedure DoPause;
    public
        constructor Create;
        destructor Destroy; override;
    end;

    TCLIShell = class
    public
        constructor Create;
        destructor Destroy; override;
        procedure LoadPrelude;
        procedure LoadHelper;
        procedure Run;
    end;

var
    FrontEnd: TFrontEnd;
    Storage: TStorage;
    ErrorRegister: TErrorRegister;
    Interpreter: TInterpreter;
    Stream: TConsoleStream;
    S: string;
    QuitFlag: Boolean = False;
    RestartFlag: Boolean = False;
    CLIShell: TCLIShell;

implementation

{ TConsoleStream }

procedure TConsoleStream.CalculateLineCols;
var
    R, W, K, C, T: Integer;
begin
    inherited;
    T := TabSize;
    SetLength(FLineWidths, Lines[Length] + 1);
    W := 0;
    C := PrompterSize;
    K := 0;
    R := 0;
    while K < Length do begin
        if Item[K] = FX_EOL_LF then begin
            FLineWidths[R] := W;
            W := 0;
            C := PrompterSize;
            Inc(K);
            Inc(R);
        end
        else if Item[K] = FX_EOL_CR then begin
            FLineWidths[R] := W;
            W := 0;
            C := PrompterSize;
            Inc(K);
            if (K < Length) and (Item[K] = FX_EOL_LF) then
                Inc(K);
            Inc(R);
        end
        else if Item[K] = #9 then begin
            W := W + T - (C mod T);
            C := C + T - (C mod T);
            Inc(K);
        end
        else begin
            Inc(W);
            Inc(K);
            Inc(C);
        end;
    end;
    FLineWidths[R] := W;
end;

procedure TConsoleStream.Init;
begin
    inherited;
    SetLength(FLineWidths, 1);
    FLineWidths[0] := 0;
end;

procedure TConsoleStream.MarkLine(ALine: Integer);
begin
end;

{ TFrontEnd }

constructor TFrontEnd.Create;
begin
    inherited Create;
end;

destructor TFrontEnd.Destroy;
begin
    inherited;
end;

procedure TFrontEnd.ClearScreen;
begin
    ClrScr;
    TextColor(CONSOLE_FOREGROUND);
end;

procedure TFrontEnd.PrintError(S: TFxString);
begin
    TextColor(ERROR_FOREGROUND);
    Writeln(S);
end;

procedure TFrontEnd.PrintOutput(S: TFxString);
begin
    TextColor(OUTPUT_FOREGROUND);
    Writeln(S);
end;

procedure TFrontEnd.PrintAnswer(S: TFxString);
begin
    PrintOutput(S);
end;

function TFrontEnd.InputStr: TFxString;
begin
    TextColor(INPUT_FOREGROUND);
    Readln(Result);
end;

procedure TFrontEnd.OutputStr(S: TFxString);
begin
    TextColor(OUTPUT_FOREGROUND);
    Write(S);
end;

procedure TFrontEnd.DoOnEndRun;
begin
end;

procedure TFrontEnd.DoOnStartRun;
begin
end;

procedure TFrontEnd.DoQuit;
begin
    DoInterrupt;
    QuitFlag := True;
end;

procedure TFrontEnd.DoInterrupt;
begin
    if Interpreter <> nil then
        Interpreter.Interrupt;
end;

procedure TFrontEnd.DoRestart;
begin
    DoInterrupt;
    RestartFlag := True;
end;

procedure TFrontEnd.DoPause;
begin
    // do nothing
end;

{ TCLIShell }

constructor TCLIShell.Create;
begin
    inherited Create;
    FrontEnd := TFrontEnd.Create;
    Storage := TStorage.Create;
    ErrorRegister := TErrorRegister.Create(FrontEnd);
    Stream := TConsoleStream.Create(FrontEnd);
    Interpreter := nil;
    QuitFlag := False;
end;

destructor TCLIShell.Destroy;
begin
    inherited;
end;

procedure TCLIShell.LoadPrelude;
begin
    ErrorRegister.Clear;
    Interpreter := TInterpreter.Create(FrontEnd, Storage, ErrorRegister);
    Stream.FirstLineRow := 0;
    Stream.PrompterSize := 0;
    Stream.Load(FX_PRELUDE_SCRIPT);
    if Interpreter.__Run(Stream) <> FX_RES_SUCCESS then begin
        if ErrorRegister.ThereIsError then begin
            FrontEnd.PrintError(ErrorRegister.GetFullMsg);
            ErrorRegister.Clear;
        end;
    end;
    FreeAndNil(Interpreter);
end;

procedure TCLIShell.LoadHelper;
begin
    ErrorRegister.Clear;
    Interpreter := TInterpreter.Create(FrontEnd, Storage, ErrorRegister);
    Stream.FirstLineRow := 0;
    Stream.PrompterSize := 0;
    Stream.Load(FX_HELPER_SCRIPT);
    if Interpreter.__Run(Stream) <> FX_RES_SUCCESS then begin
        if ErrorRegister.ThereIsError then begin
            FrontEnd.PrintError(ErrorRegister.GetFullMsg);
            ErrorRegister.Clear;
        end;
    end;
    FreeAndNil(Interpreter);
end;

procedure WritePrompter(AArrow: Boolean);
begin
    TextColor(PROMPTER_FOREGROUND);
    if AArrow then
        Write(FX_ARROW_PROMPTER)
    else
        Write(FX_SPACE_PROMPTER);
    TextColor(INPUT_FOREGROUND);
end;

procedure ClearLastPrompter;
var
    Y: Integer;
begin
    Y := WhereY32;
    if Y > 0 then begin
        GotoXY32(0, Y - 1);
        ClrEoL;
    end;
end;

procedure TCLIShell.Run;
var
    ArrowPrompter, CanReadNewLine, Multiline: Boolean;
begin
    repeat
        if RestartFlag then begin
            Storage.Clear;
            LoadPrelude;
            LoadHelper;
            TextColor(CONSOLE_FOREGROUND);
            Writeln(ShellRestartedStr);
            RestartFlag := False;
        end;
        
        ErrorRegister.Clear;
        Interpreter := TInterpreter.Create(FrontEnd, Storage, ErrorRegister);
        
        Stream.FirstLineRow := WhereY32;
        Stream.PrompterSize := System.Length(FX_ARROW_PROMPTER);
        Stream.BeginReadLine;
        ArrowPrompter := True;
        CanReadNewLine := True;
        Multiline := False;
        while CanReadNewLine do begin
            WritePrompter(ArrowPrompter);
            if not ArrowPrompter then Multiline := True;
            Readln(S);
            CanReadNewLine := Stream.AddLine(S);
            ArrowPrompter := False;
        end;
        Stream.EndReadLine;
        if Multiline then ClearLastPrompter;
        
        if Interpreter.__Run(Stream) <> FX_RES_SUCCESS then begin
            if ErrorRegister.ThereIsError then begin
                ErrorRegister.MarkErrorPosition;
                FrontEnd.PrintError(ErrorRegister.GetFullMsg);
                ErrorRegister.Clear;
            end;
        end;
        if (not QuitFlag) and (not RestartFlag) and Interpreter.Stopped then begin
            TextColor(CONSOLE_FOREGROUND);
            Writeln(ShellInterruptedStr);
        end;

        FreeAndNil(Interpreter);
    until QuitFlag;
end;

end.

