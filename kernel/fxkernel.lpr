library fxkernel;

{$mode objfpc}{$H+}

uses
    Classes, SysUtils,
    fxUtils, fxError, fxStdStreams, fxStrUtils,
    fxStorage, fxInterpreter;

const
    FX_EOL = FX_EOL_CR+FX_EOL_LF;
    FX_INIT_SCRIPT = 'run "scripts\\prelude.fx"' + FX_EOL +
                     'run "scripts\\helper.fx"';

const
    FX_SUCCESS          = 0;
    FX_EXIT             = 1;
    FX_RESTARTED        = 2;
    FX_INTERRUPTED      = 3;
    FX_ERROR            = 4;

    FX_KER_NOTHING      = 0;
    FX_KER_PAUSED       = 1;
    FX_KER_READ         = 2;
    FX_KER_WRITE        = 3;
    FX_KER_OUTPUT       = 4;
    FX_KER_ERROR        = 5;
    FX_KER_CLRSCR       = 6;

{ types }

type KernelParam = QWord;
type KernelCallback = function(kernel: KernelParam; code: KernelParam; data: KernelParam): KernelParam; cdecl;

type
    KernelData =  packed record
        case Byte of
        0: (len: Int64; str: PAnsiChar);
    end;
    PKernelData = ^KernelData;

{ kernel }

type
    TKernel = class(TFxObject, IFrontEndListener)
    public
        Shell: KernelParam; // stored
        InputText: TFxString;
        FileName: TFxString;

        CallBack: KernelCallBack;
        Storage: TStorage;
        ErrorRegister: TErrorRegister;
        Interpreter: TInterpreter;
        Stream: TInputStream;
        QuitFlag: Boolean;
        RestartFlag: Boolean;

        constructor Create(AShell: KernelParam; ACallback: KernelCallback);
        destructor Destroy; override;
        procedure Initialize(); overload;
        function Initialize(F: PKernelData): Word; overload;
        function Input(D: PKernelData): Word;
        function Run: Word;
        function Pause: Word;
        function Resume: Word;
        function Interrupt: Word;
        function Save(D: PKernelData): Word;
        function DataToString(D: PKernelData; var Str: TFxString): Boolean;
        { front end }
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
    end;

{ TKernel }

constructor TKernel.Create(AShell: KernelParam; ACallback: KernelCallback);
begin
    Storage := TStorage.Create;
    ErrorRegister := TErrorRegister.Create(Self);
    Stream := TInputStream.Create(Self);
    Interpreter := nil;
    QuitFlag := False;
    RestartFlag := False;

    Shell := AShell;
    Callback := ACallback;
end;

destructor TKernel.Destroy;
begin
    Storage.Free;
    ErrorRegister.Free;
    Stream.Free;
    if (Interpreter <> nil) then Interpreter.Free;
    inherited;
end;

procedure TKernel.Initialize();
begin
    // don't use file
    ErrorRegister.Clear;
    Interpreter := TInterpreter.Create(Self, Storage, ErrorRegister);
    Stream.PrompterSize := 0;
    Stream.Load(FX_INIT_SCRIPT);
    if Interpreter.__Run(Stream) <> FX_RES_SUCCESS then begin
        if ErrorRegister.ThereIsError then begin
            PrintError(ErrorRegister.GetFullMsg);
            ErrorRegister.Clear;
        end;
    end;
    FreeAndNil(Interpreter);
end;

function TKernel.Initialize(F: PKernelData): Word;
begin
    // don't use file
    Result := FX_SUCCESS;
    ErrorRegister.Clear;
    Interpreter := TInterpreter.Create(Self, Storage, ErrorRegister);
    Stream.PrompterSize := 0;
    Stream.Load(FX_INIT_SCRIPT);
    if Interpreter.__Run(Stream) <> FX_RES_SUCCESS then begin
        if ErrorRegister.ThereIsError then begin
            PrintError(ErrorRegister.GetFullMsg);
            ErrorRegister.Clear;
            Result := FX_ERROR;
        end;
    end;
    FreeAndNil(Interpreter);
end;

function TKernel.Input(D: PKernelData): Word;
begin
    if DataToString(D, InputText) then Result := 0
    else Result := 1;
end;

function TKernel.Run: Word;
begin
    ErrorRegister.Clear;
    Interpreter := TInterpreter.Create(Self, Storage, ErrorRegister);
    Stream.PrompterSize := 4;
    Stream.Load(InputText);

    Result := FX_SUCCESS;
    if Interpreter.__Run(Stream) <> FX_RES_SUCCESS then begin
        if ErrorRegister.ThereIsError then begin
            ErrorRegister.MarkErrorPosition;
            PrintError(ErrorRegister.GetFullMsg);
            ErrorRegister.Clear;
            Result := FX_ERROR;
        end;
    end;

    if (not QuitFlag) and (not RestartFlag) and Interpreter.Stopped then begin
        OutputStr(ShellInterruptedStr + FX_EOL);
        Result := FX_INTERRUPTED;
    end;

    FreeAndNil(Interpreter);

    if RestartFlag then begin
        Storage.Clear;
        Initialize();
        OutputStr(ShellRestartedStr + FX_EOL);
        RestartFlag := False;
        Result := FX_RESTARTED;
    end;

    if QuitFlag then Result := FX_EXIT

end;

function TKernel.Pause: Word;
begin
    if Interpreter <> nil then
        Interpreter.Pause;
    Result := 0;
end;

function TKernel.Resume: Word;
begin
    if Interpreter <> nil then
        Interpreter.Resume;  
    Result := 0;
end;

function TKernel.Interrupt: Word;
begin
    if Interpreter <> nil then
        Interpreter.Interrupt; 
    Result := 0;
end;

function TKernel.Save(D: PKernelData): Word;
var
    S: string;
begin
    if DataToString(D, S) then begin
        // don't save anything
    end;                            
    Result := 0;
end;

function TKernel.DataToString(D: PKernelData; var Str: string): Boolean;
var
    L, I: Integer;
    S: PAnsiChar;
begin
    Result := False;
    if D <> nil then begin
        try
            L := D^.len;
            S := D^.str;
            SetLength(Str, L);
            I := 0;
            while I < L do begin
                Str[I + 1] := S^;
                Inc(S);
                Inc(I);
            end;
            Result := True;
        except
            on E: Exception do begin
                Writeln(E.ClassName + ': ' + E.Message);
            end;
        end;
    end;
end;

{ frontend }

function TKernel.InputStr: TFxString;    
var
    K: KernelParam;
    C: KernelParam;
begin
    K := KernelParam(PtrUInt(Self));
    C := FX_KER_READ;
    Callback(K, C, 0);
    // after the callback executes fx_call_input so the result is:
    Result := InputText;
end;

procedure TKernel.OutputStr(S: TFxString);  
var
    K: KernelParam;
    C: KernelParam;
    D: KernelParam;
    data: KernelData;
begin
    K := KernelParam(PtrUInt(Self));
    C := FX_KER_WRITE;
    data.len := Length(S);
    data.str := PAnsiChar(S);
    D := KernelParam(PtrUInt(@data));
    Callback(K, C, D);
end;

procedure TKernel.ClearScreen;
var
    K: KernelParam;
    C: KernelParam;
begin
    K := KernelParam(PtrUInt(Self));
    C := FX_KER_CLRSCR;
    Callback(K, C, 0);
end;

procedure TKernel.PrintOutput(S: TFxString);
var
    K: KernelParam;
    C: KernelParam;
    D: KernelParam;
    data: KernelData;
begin
    K := KernelParam(PtrUInt(Self));
    C := FX_KER_OUTPUT;
    data.len := Length(S);
    data.str := PAnsiChar(S);
    D := KernelParam(PtrUInt(@data));
    Callback(K, C, D);
end;

procedure TKernel.PrintError(S: TFxString);
var
    K: KernelParam;
    C: KernelParam;
    D: KernelParam;
    data: KernelData;
begin
    K := KernelParam(PtrUInt(Self));
    C := FX_KER_ERROR;
    data.len := Length(S);
    data.str := PAnsiChar(S);
    D := KernelParam(PtrUInt(@data));
    Callback(K, C, D);
end;

procedure TKernel.PrintAnswer(S: TFxString);
begin
    PrintOutput(S);
end;

procedure TKernel.DoOnStartRun;       
begin
end;

procedure TKernel.DoOnEndRun;  
begin
end;

procedure TKernel.DoQuit;   
begin
    DoInterrupt;
    QuitFlag := True;
end;

procedure TKernel.DoInterrupt;
begin
    if Interpreter <> nil then
        Interpreter.Interrupt;
end;

procedure TKernel.DoRestart;
begin
    DoInterrupt;
    RestartFlag := True;
end;

procedure TKernel.DoPause;
var
    K: KernelParam;
    C: KernelParam;
begin
    K := KernelParam(PtrUInt(Self));
    C := FX_KER_PAUSED;
    Callback(K, C, 0);
end;

{ implementation }

function fx_call_shell    (k: KernelParam; l: KernelParam; r: KernelParam): KernelParam; cdecl;
var
    Kernel: TKernel;
begin
    Writeln('FXKERNEL: fx_call_shell');
    Kernel := TKernel(PtrUInt(k));
    Result := Kernel.Shell;
end;

function fx_call_create   (s: KernelParam; f: KernelParam; c: KernelParam): KernelParam; cdecl;
var
    Kernel: TKernel;
begin
    Writeln('FXKERNEL: fx_call_create');
    Kernel := TKernel.Create(s, KernelCallback(PtrUInt(c)));
    Kernel.Initialize(PKernelData(PtrUInt(f)));
    Result := KernelParam(Kernel);
end;

function fx_call_destroy  (k: KernelParam; l: KernelParam; r: KernelParam): KernelParam; cdecl;
var
    Kernel: TKernel;
begin
    Writeln('FXKERNEL: fx_call_destroy');
    Kernel := TKernel(PtrUInt(k));
    Kernel.Free;
    Result := 0;
end;

function fx_call_input    (k: KernelParam; d: KernelParam; r: KernelParam): KernelParam; cdecl;
var
    Kernel: TKernel;
begin
    Writeln('FXKERNEL: fx_call_input');
    Kernel := TKernel(PtrUInt(k));
    Result := KernelParam(Kernel.Input(PKernelData(PtrUInt(d))));
end;

function fx_call_run      (k: KernelParam; l: KernelParam; r: KernelParam): KernelParam; cdecl;
var
    Kernel: TKernel;
begin
    Writeln('FXKERNEL: fx_call_run');
    Kernel := TKernel(PtrUInt(k));
    Result := KernelParam(Kernel.Run());
end;

function fx_call_pause    (k: KernelParam; l: KernelParam; r: KernelParam): KernelParam; cdecl;
var
    Kernel: TKernel;
begin
    Writeln('FXKERNEL: fx_call_pause');
    Kernel := TKernel(PtrUInt(k));
    Result := KernelParam(Kernel.Pause());
end;

function fx_call_resume   (k: KernelParam; l: KernelParam; r: KernelParam): KernelParam; cdecl;
var
    Kernel: TKernel;
begin
    Writeln('FXKERNEL: fx_call_resume');
    Kernel := TKernel(PtrUInt(k));
    Result := KernelParam(Kernel.Resume());
end;

function fx_call_interrupt(k: KernelParam; l: KernelParam; r: KernelParam): KernelParam; cdecl;
var
    Kernel: TKernel;
begin
    Writeln('FXKERNEL: fx_call_interrupt');
    Kernel := TKernel(PtrUInt(k));
    Result := KernelParam(Kernel.Interrupt());
end;

function fx_call_save     (k: KernelParam; d: KernelParam; r: KernelParam): KernelParam; cdecl;
var
    Kernel: TKernel;
begin
    Writeln('FXKERNEL: fx_call_save');
    Kernel := TKernel(PtrUInt(k));
    Result := KernelParam(Kernel.Save(PKernelData(PtrUInt(d))));
end;

exports
    fx_call_shell    ,
    fx_call_create   ,
    fx_call_destroy  ,
    fx_call_input    ,
    fx_call_run      ,
    fx_call_pause    ,
    fx_call_resume   ,
    fx_call_interrupt,
    fx_call_save     ;
end.

