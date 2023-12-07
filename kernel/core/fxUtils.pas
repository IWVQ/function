unit fxUtils;

interface

uses
    SysUtils, Classes, DateUtils;

const
    
    FX_RES_SUCCESS      = 0;
    FX_RES_ERR_SINGLE   = 1;
    FX_RES_ERR_INTERNAL = 2;
    
    FX_EOL_LF           = #10;
    FX_EOL_CR           = #13;
    
    FX_INVALID_LINE     = -1;
    
    FX_LANGUAGE_NONE    = 0;
    FX_LANGUAGE_ENGLISH = 1;
    
var
    ScriptTabSize: Integer = 8;
    InputTabSize: Integer = 8;
    
type
    
    (* BASIC TYPES *)
    
    //Complex = packed record
    //    R: Extended;
    //    C: Extended;
    //end;
    
    { Language types }
    
    TFxBool   = Boolean;
    TFxChar   = Char;
    //TFxNumber = Complex;
    TFxNumber = Extended;
    
    { Internal types }
    
    //TFxComplex = Complex;
    TFxReal = Extended;
    TFxInteger = Int64;
    TFxString = string;
    PFxString = PString;
    
    { Other types }
    
    ANSIFILE = file of AnsiChar;
    TIntArray  = array of Integer;
    TBoolArray = array of Boolean;
    TRestrictedVariables = TIntArray;
    
    (* INTERFACES *)
    
    { Object }
    
    EFxError = Exception;
    
    TFxObject = class(TPersistent, IInterface)
    protected
        { IInterface }    
        function QueryInterface({$IFDEF FPC_HAS_CONSTREF} constref {$ELSE} const {$ENDIF}
            IID: TGUID; out Obj): Longint; {$IFNDEF WINDOWS} cdecl {$ELSE} stdcall {$ENDIF};
        function _AddRef: Longint; {$IFNDEF WINDOWS} cdecl {$ELSE} stdcall {$ENDIF};
        function _Release: Longint; {$IFNDEF WINDOWS} cdecl {$ELSE} stdcall {$ENDIF};
    end;
    
    { CharStream }
    
    IStream = interface
        function GetItem(AIndex: Integer): Char;
        function ColFromPos(APos: Integer): Integer;
        function LineFromPos(APos: Integer): Integer;
        function GetCaption: string; // script file name or console name
        function GetRange(AFrom, ATo: Integer): string;
        function Length: Integer;
        function TabSize: Integer;
        procedure MarkLine(ALine: Integer);
        property Item[AIndex: Integer]: Char read GetItem; default;
    end;
    
    { FrontEnd }
    
    IFrontEndListener = interface
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
    end;

procedure UndefinedRoutine(S: string);
procedure ShowDebugMsg(S: string);
function GetLanguage: Byte;
function GetStdEoL: string;
procedure GetNowDateTime(var AYear, AMonth, ADayOfWeek, ADay, AHour, AMinute, ASecond, AMilliseconds: TFxInteger);
procedure SetNowDateTime(AYear, AMonth, ADayOfWeek, ADay, AHour, AMinute, ASecond, AMilliseconds: TFxInteger);

implementation

procedure ShowDebugMsg(S: string);
begin
{$IFDEF FX_CLI}
    System.Writeln(Format('{debug message: %s}', [S]));
{$ENDIF}
{$IFDEF FX_GUI}
    ShowMessage(Format('{debug message: %s}', [S]));
{$ENDIF}
end;

function GetLanguage: Byte;
begin
{$IFDEF FX_ENGLISH}
    ShowDebugMsg('1');
    Result := FX_LANGUAGE_ENGLISH;
{$ELSE}
    ShowDebugMsg('2');
    Result := FX_LANGUAGE_ENGLISH;
{$ENDIF}
end;

function GetStdEoL: string;
begin
{$IF DEFINED(MSWINDOWS)}
    Result := FX_EOL_CR + FX_EOL_LF;
{$ELSEIF DEFINED(LINUX)}
    Result := FX_EOL_LF;
{$ELSEIF DEFINED(MACOS)}
    Result := FX_EOL_CR;
{$ELSE}
    Result := FX_EOL_LF;
{$IFEND}
end;

procedure UndefinedRoutine(S: string);
begin
    raise EFxError.Create(Format('undefined routine: "%s"', [S]));
end;

procedure GetNowDateTime(var AYear, AMonth, ADayOfWeek, ADay, AHour, AMinute, ASecond, AMilliseconds: TFxInteger);
var
    ANow: TSystemTime;
begin
    GetLocalTime(ANow);
    with ANow do begin
        AYear := wYear;
        AMonth := wMonth;
        ADay := wDay;
        ADayOfWeek := wDayOfWeek;
        AHour := wHour;
        AMinute := wMinute;
        ASecond := wSecond;
        AMilliseconds := wMilliseconds;
    end;
end;

procedure SetNowDateTime(AYear, AMonth, ADayOfWeek, ADay, AHour, AMinute, ASecond, AMilliseconds: TFxInteger);
var
    ANow: TSystemTime;
begin
    with ANow do begin
        wYear := Word(AYear);
        wMonth := Word(AMonth);
        wDay := Word(ADay);
        wDayOfWeek := Word(ADayOfWeek);
        wHour := Word(AHour);
        wMinute := Word(AMinute);
        wSecond := Word(ASecond);
        wMilliseconds := Word(AMilliseconds);
    end;
    //# SetLocalTime(ANow);
end;

{ TFxObject }
                   
function TFxObject.QueryInterface({$IFDEF FPC_HAS_CONSTREF} constref {$ELSE} const {$ENDIF}
    IID: TGUID; out Obj): Longint; {$IFNDEF WINDOWS} cdecl {$ELSE} stdcall {$ENDIF};
begin
	if GetInterface(IID, Obj) then Result := S_OK
	else Result := E_NOINTERFACE;
end;

function TFxObject._AddRef: Longint; {$IFNDEF WINDOWS} cdecl {$ELSE} stdcall {$ENDIF};
begin
    Result := -1;
end;

function TFxObject._Release: Longint; {$IFNDEF WINDOWS} cdecl {$ELSE} stdcall {$ENDIF};
begin
    Result := -1;
end;

end.
