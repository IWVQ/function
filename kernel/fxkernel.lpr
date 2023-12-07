library fxkernel;

{$mode objfpc}{$H+}

uses
    Classes, SysUtils,
    fxUtils, fxError, fxStdStreams, fxStrUtils,
    fxStorage, fxInterpreter;

{ types }

type KernelParam = QWord;
type KernelCallback = function(kernel: KernelParam; code: KernelParam; data: KernelParam): KernelParam; cdecl;

type
    KernelData =  packed record
        len: Integer;
        str: PAnsiChar;
    end;
    PKernelData = ^KernelData;

{ kernel }
               {
type
    TKernel = class
    public
        Shell: KernelParam; // stored
        Input: array of AnsiChar;
        FileName: string;

        CallBack: KernelCallBack;
        FrontEnd: TFrontEnd;
        Storage: TStorage;
        ErrorRegister: TErrorRegister;
        Interpreter: TInterpreter;
        Stream: TConsoleStream;
        QuitFlag: Boolean;
        RestartFlag: Boolean;

        constructor Create(FileName: string);
        destructor Destroy;
        function StoreInput(S: PAnsiChar; L: Integer): Word;
        function Run: Word;
        function Pause: Word;
        function Resume: Word;
        function Interrupt: Word;
        function Save(S: PAnsiChar; L: Integer): Word;
    end;      }

{ implementation }

function fx_call_test(data: KernelParam; callback: KernelParam): KernelParam; cdecl;
var
    D: PKernelData;
    I: Integer;
    S: PAnsiChar;
    F: KernelCallback;

    r: KernelParam;
begin
    if data <> 0 then begin
        D := PKernelData(PtrUInt(data));
        S := D^.str;
        for I := 0 to D^.len do begin
            Write(S^);
            Inc(S);
        end;
        Writeln('function fx_call_test(data: KernelParam): KernelParam; cdecl; ');
        Result := 1;
    end
    else Result := 0;
    F := KernelCallback(PtrUInt(callback));
    r := F(0, 0, KernelParam(D));
    Writeln('r := F(0, 0, KernelParam(D));');
end;

// function fx_call_shell    (kernel: KernelParam): KernelParam;
// function fx_call_create   (shell: KernelParam; file: KernelParam; handler: KernelParam): KernelParam;
// function fx_call_destroy  (kernel: KernelParam): KernelParam;
// function fx_call_input    (kernel: KernelParam; data: KernelParam): KernelParam;
// function fx_call_run      (kernel: KernelParam): KernelParam;
// function fx_call_pause    (kernel: KernelParam): KernelParam;
// function fx_call_resume   (kernel: KernelParam): KernelParam;
// function fx_call_interrupt(kernel: KernelParam): KernelParam;
// function fx_call_save     (kernel: KernelParam; data: KernelParam): KernelParam;

exports
    fx_call_test;
    // fx_call_shell    ;
    // fx_call_create   ;
    // fx_call_destroy  ;
    // fx_call_input    ;
    // fx_call_run      ;
    // fx_call_pause    ;
    // fx_call_resume   ;
    // fx_call_interrupt;
    // fx_call_save     ;
end.

