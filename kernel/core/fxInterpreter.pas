unit fxInterpreter;

interface

uses
    fxUtils, fxStrUtils, fxStorage, fxError, fxBasicStructure, fxInterpreterUtils,
    fxScanner, fxTokenUtils, fxParser, fxASTUtils, fxTranslator, fxCommandUtils, fxPerformer,
    fxStdStreams;

type

    TInterpreter = class(TFxObject, IInterpreterListener)
    private
        Error: TErrorRegister;
        FrontEnd: IFrontEndListener;
        Storage: TStorage;
        
        FScanner: TScanner;
        FParser: TParser;
        FTranslator: TTranslator;
        FPerformer: TPerformer;

        FScriptInterpreter: TInterpreter;
        FScriptStream: TScriptStream;
        
    protected
        STOP: BOOLEAN;
        { listener }
        function __RunScript(S: TFxString): Word;
        function __Reduce(V: TValueExpr): Word;
        function __ReplaceIdentifier(I: Integer; A, R: TValueExpr): Word;
        
    public
        constructor Create(AFrontEnd: IFrontEndListener; AStorage: TStorage; AError: TErrorRegister);
        destructor Destroy; override;
        
        function __Run(AStream: IStream): Word;
        function Stopped: Boolean;
        procedure Interrupt;
    end;

implementation

{ TInterpreter }

constructor TInterpreter.Create(AFrontEnd: IFrontEndListener; AStorage: TStorage; AError: TErrorRegister);
begin
    inherited Create;
    FrontEnd := AFrontEnd;
    Storage := AStorage;
    Error := AError;
    
    STOP := FALSE;
    
    FScanner := TScanner.Create(FrontEnd, Self, Storage, Error);
    FParser := TParser.Create(FrontEnd, Self, Storage, Error);
    FTranslator := TTranslator.Create(FrontEnd, Self, Storage, Error);
    FPerformer := TPerformer.Create(FrontEnd, Self, Storage, Error);

    FScriptInterpreter := nil;
    FScriptStream := nil;

end;


destructor TInterpreter.Destroy;
begin
    FScanner.Free;
    FParser.Free;
    FTranslator.Free;
    FPerformer.Free;

    if FScriptInterpreter <> nil then begin
        FScriptInterpreter.Free;
        FScriptInterpreter := nil;
    end;
    if FScriptStream <> nil then begin
        FScriptStream.Free;
        FScriptStream := nil;
    end;

    inherited;
end;

function TInterpreter.__Run(AStream: IStream): Word;

LABEL LBL_END;
    
var
    ScanPos: Integer;
    TknList: TTokenList;
    AST: TAbstractSyntaxTree;
    Command: TCommand;
    CommandIndex: Integer;
    ARIV: TRestrictedVariables;
begin

    try
        Error.Phase := FX_PHASE_NONE;
        Result := FX_RES_SUCCESS;
        CommandIndex := 0;
        ScanPos := 0;
        //-----
        TknList := nil;
        AST := nil;
        EmptyCommand(Command);
        //-----
        while ScanPos < AStream.Length do begin
            Error.Stream := AStream;
            Error.CommandIndex := CommandIndex;
            Error.CommandStartLine := AStream.LineFromPos(ScanPos);
            IF STOP THEN GOTO LBL_END;
            // escanear el siguiente comando
            Error.Phase := FX_PHASE_SCANNER;
            Result := FScanner.__ScanCommand(ScanPos, AStream, TknList, ARIV);
            IF STOP THEN GOTO LBL_END;
            if Result <> FX_RES_SUCCESS then
                Break;

            Error.Phase := FX_PHASE_PARSER;
            Result := FParser.__Parse(TknList, AST);
            IF STOP THEN GOTO LBL_END;
            if Result <> FX_RES_SUCCESS then
                Break;

            Error.Phase := FX_PHASE_TRANSLATOR;
            Result := FTranslator.__Translate(AST, ARIV, Command);
            IF STOP THEN GOTO LBL_END;
            if Result <> FX_RES_SUCCESS then
                Break;

            Error.Phase := FX_PHASE_PERFORMER;
            Result := FPerformer.__Perform(Command, ARIV);
            IF STOP THEN GOTO LBL_END;
            if Result <> FX_RES_SUCCESS then
                Break;
                
            Error.Phase := FX_PHASE_NONE;
            EraseTokenList(TknList);
            EraseASTBranch(AST);
            ReleaseCommand(Command);
            Inc(CommandIndex);
        end;
        
        LBL_END:
        //----
        EraseTokenList(TknList);
        EraseASTBranch(AST);
        ReleaseCommand(Command);
        //----
        
    except
        on E: EFxError do begin
            Result := FX_RES_ERR_INTERNAL;
            Error.Code := Result;
            Error.Msg := E.ClassName + ': ' + E.Message;
        end;
    end;
end;

procedure TInterpreter.Interrupt;
begin
    STOP := TRUE;
    FScanner.Interrupt;
    FParser.Interrupt;
    FTranslator.Interrupt;
    FPerformer.Interrupt;

    if FScriptInterpreter <> nil then
        FScriptInterpreter.Interrupt;
end;

function TInterpreter.Stopped: Boolean;
begin
    Result := STOP;
end;

{ listener }

function TInterpreter.__RunScript(S: TFxString): Word;
begin
    Result := FX_RES_SUCCESS;
    FScriptInterpreter := TInterpreter.Create(FrontEnd, Storage, Error);
    FScriptStream := TScriptStream.Create(FrontEnd);
    if FScriptStream.LoadFromFile(S) then
        Result := FScriptInterpreter.__Run(FScriptStream)
    else begin
        Result := FX_RES_ERR_SINGLE;
        Error.Code := Result;
        Error.Msg := FormatMessage(FileNotFoundStr, [S]);
    end;
    if Error.ThereIsError then begin
        Error.MarkErrorPosition;
        FrontEnd.PrintError(Error.GetFullMsg);
        Error.Clear;
    end;
    FScriptInterpreter.Free;
    FScriptInterpreter := nil;
    FScriptStream.Free;
    FScriptStream := nil;
end;

function TInterpreter.__Reduce(V: TValueExpr): Word;
begin
    Result := FPerformer.Evaluator.__Reduce(V);
end;

function TInterpreter.__ReplaceIdentifier(I: Integer; A, R: TValueExpr): Word;
begin
    Result := FPerformer.Evaluator.__ReplaceIdentifier(I, A, R);
end;

end.
