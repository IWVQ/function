program functioncli;

{$mode objfpc}{$H+}

{$DEFINE FX_CLI}
{$DEFINE FX_ENGLISH}

uses
    {$IFDEF UNIX}{$IFDEF UseCThreads}
    cthreads,
    {$ENDIF}{$ENDIF}
    SysUtils,
    Classes,
    Crt,
    fxCLIShell,
    fxStrUtils
    ;

function CtrlBreakHandler(CtrlBreak: Boolean): Boolean;
begin      
    Result := True;
    if CtrlBreak then begin
        if Interpreter <> nil then
           Interpreter.Interrupt;
    end;
end;

begin
   try
       TextColor(HEADER_FOREGROUND);
       Writeln(Format(FX_CONSOLE_HEADER, [FxVersion]));
       TextColor(CONSOLE_FOREGROUND);
                           
       //Writeln(ShellLoadingStr);
       CLIShell := TCLIShell.Create;
       CLIShell.LoadPrelude;
       CLIShell.LoadHelper;
       Writeln(ShellTypeHelpStr);     
       Writeln;
       SysSetCtrlBreakHandler(@CtrlBreakHandler);
       CLIShell.Run;
                                       {
       TextColor(Crt.Brown);
       Write('>>> ');
       TextColor(Crt.LightGray);
       Writeln('2 + 3 + 4 ...');     
       TextColor(Crt.Brown);
       Write('... ');
       TextColor(Crt.LightGray);
       Writeln('    + 7');
       TextColor(Crt.LightRed);
       Writeln('Error: at line 1 from prompter');
                                      }

   except
       on E: Exception do begin
           Writeln(E.ClassName, ':', E.Message);
           Readln;
       end;
   end;
end.

