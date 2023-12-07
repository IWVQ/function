unit fxPerformer;

interface

uses
    fxUtils, fxStorage, fxError, fxStrUtils, fxInterpreterUtils, fxBasicStructure, fxCommandUtils,
    fxPrimFuncUtils, fxEvaluator, fxDefinitionMaker, fxStrConverter, fxTypeChecker;

type

    TPerformer = class
    private
        FrontEnd: IFrontEndListener;
        Interpreter: IInterpreterListener;
        Storage: TStorage;
        Error: TErrorRegister;
        
        FEvaluator: TEvaluator;
        FDefinitionMaker: TDefinitionMaker;
        FStrConverter: TStrConverter;
        FTypeChecker: TTypeChecker;
        
        function __PerformCommand(var ACommand: TCommand; var ARIV: TRestrictedVariables): Word;
        function PerformingError(AMsg: TFxString): Word;
    protected
        STOP: BOOLEAN;
    public
        property Evaluator: TEvaluator read FEvaluator;
        constructor Create(AFrontEnd: IFrontEndListener; AInterpreter: IInterpreterListener;
            AStorage: TStorage; AError: TErrorRegister);
        destructor Destroy; override;
        
        function __Perform(var ACommand: TCommand; var ARestrictedInternalVars: TRestrictedVariables): Word;
        procedure Interrupt;
    end;
    
implementation

{ TPerformer }

constructor TPerformer.Create(AFrontEnd: IFrontEndListener; AInterpreter: IInterpreterListener;
    AStorage: TStorage; AError: TErrorRegister);
begin
    inherited Create;
    FrontEnd := AFrontEnd;
    Interpreter := AInterpreter;
    Storage := AStorage;
    Error := AError;
    
    FEvaluator := TEvaluator.Create(FrontEnd, Interpreter, Storage, Error);
    FDefinitionMaker := TDefinitionMaker.Create(FrontEnd, Interpreter, Storage, Error);
    FStrConverter := TStrConverter.Create(FrontEnd, Interpreter, Storage, Error);
    FTypeChecker := TTypeChecker.Create(FrontEnd, Interpreter, Storage, Error);
    
    STOP := FALSE;
end;

destructor TPerformer.Destroy;
begin
    FEvaluator.Free;
    FDefinitionMaker.Free;
    FStrConverter.Free;
    FTypeChecker.Free;
    inherited;
end;

function TPerformer.PerformingError(AMsg: TFxString): Word;
begin
    Result := FX_RES_ERR_SINGLE;
    Error.Code := Result;
    Error.Msg := AMsg;
end;

//---

function TPerformer.__PerformCommand(var ACommand: TCommand; var ARIV: TRestrictedVariables): Word;

LABEL LBL_END;

var
    K: Integer;
    AuxBranch: TValueExpr;
    AnsStr: TFxString;

begin
    
    Result := FX_RES_SUCCESS;
    AuxBranch := nil;
    
    IF STOP THEN GOTO LBL_END;
    
    case ACommand.Kind of
        FX_CMD_NONE        :;
        FX_CMD_RUN      : begin
            Result := Interpreter.__RunScript(ACommand.Run^.ScriptFile^);
        end;
        FX_CMD_CLEAR       : begin
            for K := 0 to Length(ACommand.Clear^.IdCodes) - 1 do begin
                IF STOP THEN GOTO LBL_END;
                Storage[ACommand.Clear^.IdCodes[K]].Clear;
            end;
        end;
        FX_CMD_NOTATION    : begin
            for K := 0 to Length(ACommand.Notation^.IdCodes) - 1 do begin
                IF STOP THEN GOTO LBL_END;
                Storage[ACommand.Notation^.IdCodes[K]].NewNotation(ACommand.Notation^.Priority, ACommand.Notation^.Position);
            end;
        end;
        FX_CMD_SYNONYMOUS  : begin
            Result := FTypeChecker.__CheckForRecursivity(ACommand.Synonymous^.IdCode, ACommand.Synonymous^.Expr);
            IF STOP THEN GOTO LBL_END;
            if Result = FX_RES_SUCCESS then
                Storage[ACommand.Synonymous^.IdCode].NewTypeSynonymous(ACommand.Synonymous^.Expr);
        end;
        FX_CMD_INHERITABLE : begin
            Storage[ACommand.Inheritable^.IdCode].NewInheritableType(ACommand.Inheritable^.Expr);
        end;
        FX_CMD_DEFINITION  : begin

            Result := FDefinitionMaker.__InheritType(ACommand.Definition^.IdCode, ACommand.Definition^.Patterns, ACommand.Definition^.Return);
            IF STOP THEN GOTO LBL_END;
            if Result = FX_RES_SUCCESS then begin
                Storage[ACommand.Definition^.IdCode].NewDefinition(ACommand.Definition^.Patterns, ACommand.Definition^.Return, ARIV);
                Result := FDefinitionMaker.__MakeValue(ACommand.Definition^.IdCode, AuxBranch);
                IF STOP THEN GOTO LBL_END;
                if Result = FX_RES_SUCCESS then begin
                    Storage[ACommand.Definition^.IdCode].NewValue(AuxBranch);
                    AuxBranch := nil;
                end;
            end;
        end;
        FX_CMD_ASSIGNMENT  : begin
            Result := FEvaluator.__Evaluate(ACommand.Evaluation^.Expr);
            IF STOP THEN GOTO LBL_END;
            if Result = FX_RES_SUCCESS then
                Storage[ACommand.Assignment^.IdCode].NewValue(ACommand.Assignment^.Expr);
        end;
        FX_CMD_EVALUATION  : begin

            Result := FEvaluator.__Evaluate(ACommand.Evaluation^.Expr);
            IF STOP THEN GOTO LBL_END;
            if Result = FX_RES_SUCCESS then begin
                if ACommand.Evaluation^.Show then begin
                    AnsStr := FStrConverter.__ValueToStr(ACommand.Evaluation^.Expr);
                    IF STOP THEN GOTO LBL_END;
                    FrontEnd.PrintAnswer(AnsStr);
                end;
                if ACommand.Evaluation^.Store then
                    Storage.StoreAnswer(ACommand.Evaluation^.Expr);
            end;
        end;
    end;
    
LBL_END:
    
    EraseValueBranch(AuxBranch);
    
end;

//---

function TPerformer.__Perform(var ACommand: TCommand; var ARestrictedInternalVars: TRestrictedVariables): Word;
begin
    Result := __PerformCommand(ACommand, ARestrictedInternalVars);
end;

procedure TPerformer.Interrupt;
begin
    STOP := TRUE;
    FEvaluator.Interrupt;
    FDefinitionMaker.Interrupt;
    FStrConverter.Interrupt;
    FTypeChecker.Interrupt;
end;

end.
