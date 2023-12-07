unit fxError;

interface

uses
    SysUtils, fxUtils, fxStrUtils;

const
    
    FX_ERR_NONE         = FX_RES_SUCCESS     ;
    FX_ERR_SINGLE       = FX_RES_ERR_SINGLE  ;
    FX_ERR_INTERNAL     = FX_RES_ERR_INTERNAL;
    
    FX_PHASE_NONE       = 0;
    FX_PHASE_SCANNER    = 1;
    FX_PHASE_PARSER     = 2;
    FX_PHASE_TRANSLATOR = 3;
    FX_PHASE_PERFORMER  = 4;
    
type

    TErrorRegister = class
    private
        FFrontEnd: IFrontEndListener;
        
        FStream: IStream;
        FPhase: Byte;
        FCommandStartLine: Integer;
        FLine: Integer;
        FCommandIndex: Integer;
        FCode: Word;
        FMsg: string;
    public
        constructor Create(AFrontEnd: IFrontEndListener);
        destructor Destroy; override;
        
        procedure Clear;
        function GetFullMsg: string;
        function GetErrorInformation: string;
        procedure MarkErrorPosition;
        function ThereIsError: Boolean;
        
        property Stream: IStream read FStream write FStream;
        property Phase: Byte read FPhase write FPhase;
        property CommandStartLine: Integer read FCommandStartLine write FCommandStartLine;
        property Line: Integer read FLine write FLine;
        property CommandIndex: Integer read FCommandIndex write FCommandIndex;
        property Code: Word read FCode write FCode;
        property Msg: string read FMsg write FMsg;
    end;

implementation

{ TErrorRegister }

constructor TErrorRegister.Create(AFrontEnd: IFrontEndListener);
begin
    FFrontEnd := AFrontEnd;
    Clear;
end;

destructor TErrorRegister.Destroy;
begin
    FMsg := '';
    inherited;
end;

procedure TErrorRegister.Clear;
begin
    FStream := nil;
    FPhase := FX_PHASE_NONE;
    FLine := FX_INVALID_LINE;
    FCommandIndex := FX_INVALID_LINE;
    FCommandStartLine := FX_INVALID_LINE;
    FCode := FX_ERR_NONE;
    FMsg := '';
end;

function TErrorRegister.GetFullMsg: string;
var
    LineError: Integer;
    ShowInformation: Boolean;
begin
    ShowInformation := True; // activar solo para depuracion
    if FLine = FX_INVALID_LINE then LineError := FCommandStartLine
    else LineError := FLine;
    if FCode = FX_ERR_SINGLE then begin
        if FStream.GetCaption <> '' then
            Result := FormatMessage(ErrorStr, [FormatMessage(ScriptErrorStr, [FStream.GetCaption, LineError]), FMsg])
        else
            Result := FormatMessage(ErrorStr, ['', FMsg]);
    end
    else if FCode = FX_ERR_INTERNAL then begin
        if FStream.GetCaption <> '' then
            Result := FormatMessage(InternalErrorStr, [FormatMessage(ScriptErrorStr, [FStream.GetCaption, LineError]), FMsg])
        else
            Result := FormatMessage(InternalErrorStr, ['', FMsg]);
    end
    else
        Result := '';
    if (FCode <> FX_ERR_NONE) and ShowInformation then
        Result := Result + GetStdEoL + GetErrorInformation;
end;

function TErrorRegister.GetErrorInformation: string;
begin
    Result := Result + 'ERROR INFORMATION:' + GetStdEoL;
    if FStream.GetCaption <> '' then
        Result := Result + '    Stream: "' + FStream.GetCaption + '"' + GetStdEoL
    else
        Result := Result + '    Stream: CONSOLE' + GetStdEoL;
    case FCode of
        FX_ERR_NONE     : Result := Result + '    Kind: none' + GetStdEoL;
        FX_ERR_SINGLE   : Result := Result + '    Kind: single' + GetStdEoL;
        FX_ERR_INTERNAL : Result := Result + '    Kind: internal' + GetStdEoL;
    end;
    case FPhase of
        FX_PHASE_NONE       : Result := Result + '    Phase: none' + GetStdEoL;
        FX_PHASE_SCANNER    : Result := Result + '    Phase: scanner' + GetStdEoL;
        FX_PHASE_PARSER     : Result := Result + '    Phase: parser' + GetStdEoL;
        FX_PHASE_TRANSLATOR : Result := Result + '    Phase: translator' + GetStdEoL;
        FX_PHASE_PERFORMER  : Result := Result + '    Phase: performer' + GetStdEoL;
    end;
    Result := Result + '    Command: ' + IntToStr(FCommandIndex) + GetStdEoL;
    Result := Result + '    Command start line: ' + IntToStr(FCommandStartLine) + GetStdEoL;
    Result := Result + '    Line: ' + IntToStr(FLine) + GetStdEoL;
end;

procedure TErrorRegister.MarkErrorPosition;
var
    LineError: Integer;
begin
    if FLine = FX_INVALID_LINE then LineError := FCommandStartLine
    else LineError := FLine;
    case FPhase of
        FX_PHASE_NONE:;
        FX_PHASE_SCANNER,
        FX_PHASE_PARSER: Stream.MarkLine(LineError);
        FX_PHASE_TRANSLATOR,
        FX_PHASE_PERFORMER:;
    end;
end;

function TErrorRegister.ThereIsError: Boolean;
begin
    Result := FCode <> FX_ERR_NONE;
end;

end.
