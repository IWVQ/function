unit fxTypeInferencer;

interface

uses
    fxUtils, fxStorage, fxError, fxBasicStructure, fxInterpreterUtils, fxPrimFuncUtils, fxTypeChecker;

type    
    
    TTypeInferencer = class
    private
        FrontEnd: IFrontEndListener;
        Interpreter: IInterpreterListener;
        Storage: TStorage;
        Error: TErrorRegister;
        
        FTypeChecker: TTypeChecker;
        
        function InferenceError(AMsg: TFxString): Word;
        function __InferType(AValueBranch: TValueExpr; var ATypeBranch: TTypeExpr): Word;
    protected
        STOP: BOOLEAN;   
        SLEEP: BOOLEAN;
    public
        constructor Create(AFrontEnd: IFrontEndListener; AInterpreter: IInterpreterListener;
            AStorage: TStorage; AError: TErrorRegister);
        destructor Destroy; override;
        
        function __Infer(AValue: TValueExpr; var AType: TTypeExpr): Word;
        procedure Interrupt;
        procedure Pause;
        procedure Resume;
    end;
    
implementation

{ TTypeInferencer }

constructor TTypeInferencer.Create(AFrontEnd: IFrontEndListener; AInterpreter: IInterpreterListener;
    AStorage: TStorage; AError: TErrorRegister);
begin
    inherited Create;
    FrontEnd := AFrontEnd;
    Interpreter := AInterpreter;
    Storage := AStorage;
    Error := AError;
    
    FTypeChecker := TTypeChecker.Create(FrontEnd, Interpreter, Storage, Error);
    
    STOP := FALSE;
end;

destructor TTypeInferencer.Destroy;
begin
    FTypeChecker.Free;
    inherited;
end;

function TTypeInferencer.InferenceError(AMsg: TFxString): Word;
begin
    Result := FX_RES_ERR_SINGLE;
    Error.Code := Result;
    Error.Msg := AMsg;
end;    

//--

function TTypeInferencer.__InferType(AValueBranch: TValueExpr; var ATypeBranch: TTypeExpr): Word;

LABEL LBL_END;

var
    I: TFxInteger;
    K: Integer;
    AuxTypeBranchHead, AuxTypeBranchTail: TTypeExpr;
    B: Boolean;
    
begin
    
    Result := FX_RES_SUCCESS;
    ATypeBranch := nil;
    AuxTypeBranchHead := nil;
    AuxTypeBranchTail := nil;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    case AValueBranch^.vKind of
        FX_VN_NONE       : begin
            MakeNoneTypeBranch(ATypeBranch);
        end;
        FX_VN_NUMBER     : begin
            if ValueIsNaturalNumber(AValueBranch, I) then
                MakeHeadTypeBranch(FX_TN_NATURAL, ATypeBranch)
            else if ValueIsIntegerNumber(AValueBranch, I) then
                MakeHeadTypeBranch(FX_TN_INTEGER, ATypeBranch)
            else
                MakeHeadTypeBranch(FX_TN_REAL, ATypeBranch);
        end;
        FX_VN_BOOLEAN    : begin
            MakeHeadTypeBranch(FX_TN_BOOLEAN, ATypeBranch);
        end;
        FX_VN_CHARACTER  : begin
            MakeHeadTypeBranch(FX_TN_CHARACTER, ATypeBranch);
        end;
        FX_VN_NULL       : begin
            MakeHeadTypeBranch(FX_TN_LIST, ATypeBranch);
            AddTypeBranchChilds(ATypeBranch, 1);
            MakeHeadTypeBranch(FX_TN_ANONYMOUS, ATypeBranch^.Childs[0]);
        end;
        FX_VN_FAIL       : begin
            MakeHeadTypeBranch(FX_TN_ANONYMOUS, ATypeBranch);
        end;
        FX_VN_IDENTIFIER : begin
            if AValueBranch^.D.tKind = FX_TN_NONE then
                MakeHeadTypeBranch(FX_TN_ANONYMOUS, ATypeBranch)
            else
                CopyTypeFromValueBranch(AValueBranch, ATypeBranch);
        end;
        FX_VN_PRIMITIVE  : begin
            GetPrimitiveFunctionType(AValueBranch^.D.vIdCode, ATypeBranch);
        end;
        FX_VN_ANONYMOUS  : begin
            MakeHeadTypeBranch(FX_TN_ANONYMOUS, ATypeBranch);
        end;
        FX_VN_TRY        : begin
            MakeHeadTypeBranch(FX_TN_ANONYMOUS, ATypeBranch); // siempre sera anonimo
        end;
        FX_VN_TUPLE      : begin
            MakeHeadTypeBranch(FX_TN_TUPLE, ATypeBranch);
            AddTypeBranchChilds(ATypeBranch, Length(AValueBranch^.Childs));
            for K := 0 to Length(AValueBranch^.Childs) - 1 do begin
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                Result := __InferType(AValueBranch^.Childs[K], ATypeBranch^.Childs[K]);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                if Result <> FX_RES_SUCCESS then
                    Break;
            end;
        end;
        FX_VN_LIST_CONS       : begin
            MakeHeadTypeBranch(FX_TN_LIST, ATypeBranch);
            AddTypeBranchChilds(ATypeBranch, 1);
            Result := __InferType(AValueBranch^.Childs[0], AuxTypeBranchHead);
            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            if Result = FX_RES_SUCCESS then begin
                if AValueBranch^.Childs[1]^.vKind = FX_VN_NULL then begin
                    ATypeBranch^.Childs[0] := AuxTypeBranchHead;
                    AuxTypeBranchHead := nil;
                end
                else begin
                    Result := __InferType(AValueBranch^.Childs[1], AuxTypeBranchTail);
                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                    if Result = FX_RES_SUCCESS then begin
                        if AuxTypeBranchTail^.tKind = FX_TN_LIST then begin
                            Result := FTypeChecker.__TypeIsSubTypeOf(AuxTypeBranchHead, AuxTypeBranchTail^.Childs[0], B);
                            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                            if Result = FX_RES_SUCCESS then begin
                                if B then begin
                                    ATypeBranch^.Childs[0] := AuxTypeBranchTail^.Childs[0];
                                    AuxTypeBranchTail^.Childs[0] := nil;
                                end
                                else begin
                                    Result := FTypeChecker.__TypeIsSubTypeOf(AuxTypeBranchTail^.Childs[0], AuxTypeBranchHead, B);
                                    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
                                    if Result = FX_RES_SUCCESS then begin
                                        if B then begin
                                            ATypeBranch^.Childs[0] := AuxTypeBranchHead;
                                            AuxTypeBranchHead := nil;
                                        end
                                        else begin
                                            { different lists }
                                            MakeHeadTypeBranch(FX_TN_ANONYMOUS, ATypeBranch^.Childs[0]);
                                        end;
                                    end;
                                end;
                            end;
                        end
                        else
                            MakeHeadTypeBranch(FX_TN_ANONYMOUS, ATypeBranch^.Childs[0]);
                    end;
                end;
            end;
        end;
        FX_VN_LAMBDA     : begin
            MakeHeadTypeBranch(FX_TN_FUNCTION, ATypeBranch);
            AddTypeBranchChilds(ATypeBranch, 2);
            Result := __InferType(AValueBranch^.Childs[0], ATypeBranch^.Childs[0]);
            IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            if Result = FX_RES_SUCCESS then begin
                Result := __InferType(AValueBranch^.Childs[1], ATypeBranch^.Childs[1]);
                IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
            end;
        end;
        FX_VN_APPLICATION: begin
            MakeHeadTypeBranch(FX_TN_ANONYMOUS, ATypeBranch); // siempre sera anonimo
        end;
    end;
    
LBL_END:

    EraseTypeBranch(AuxTypeBranchHead);
    EraseTypeBranch(AuxTypeBranchTail);
    
end;

function TTypeInferencer.__Infer(AValue: TValueExpr; var AType: TTypeExpr): Word;

LABEL LBL_END;

begin
    
    Result := FX_RES_SUCCESS;
    AType := nil;
    
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
    Result := __InferType(AValue, AType);
    IF STOP THEN GOTO LBL_END; IF SLEEP THEN FRONTEND.DOPAUSE;
    
LBL_END:
    
end;

//--

procedure TTypeInferencer.Interrupt;
begin
    STOP := TRUE;
    FTypeChecker.Interrupt;
end;
            
procedure TTypeInferencer.Pause;
begin
    SLEEP := TRUE;
    FTypeChecker.Pause;
end;

procedure TTypeInferencer.Resume;
begin
    SLEEP := FALSE;
    FTypeChecker.Resume;
end;

end.
