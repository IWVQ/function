unit fxCommandUtils;

interface

uses
    fxUtils, fxBasicStructure, fxStrUtils;

const

    FX_CMD_NONE        = 0;
    FX_CMD_RUN         = 1;
    FX_CMD_CLEAR       = 2;
    FX_CMD_NOTATION    = 3;
    FX_CMD_SYNONYMOUS  = 4;
    FX_CMD_INHERITABLE = 5;
    FX_CMD_DEFINITION  = 6;
    FX_CMD_ASSIGNMENT  = 7;
    FX_CMD_EVALUATION  = 8;
    
    { Translator required definitions }
    
    FX_RD_GETELM_STR          = 'GetElm';
    FX_RD_LISTFROMTO_STR      = 'ListFromTo';
    FX_RD_LISTFROMTHENTO_STR  = 'ListFromThenTo';
    FX_RD_FLATMAP_STR         = 'FlatMap';
    FX_RD_IFFALSE_STR         = 'IfFalse';
    FX_RD_NOTEMPTY_STR        = 'NotEmpty';
    FX_RD_IFTHENELSE_STR      = 'IfThenElse';
    FX_RD_WHILESKELETON_STR   = 'WhileSkeleton';
    
type

    { TCommand }
    
    PRunCommand = ^TRunCommand;
    TRunCommand = record
        ScriptFile: PFxString;
    end;
    
    PClearCommand = ^TClearCommand;
    TClearCommand = record
        IdCodes: TIntArray;
    end;
    
    PNotationCommand = ^TNotationCommand;
    TNotationCommand = record
        Priority: TNotationPriority;
        Position: TNotationPosition;
        IdCodes: TIntArray;
    end;
    
    PTypeSynonymousCommand = ^TTypeSynonymousCommand;
    TTypeSynonymousCommand = record
        IdCode: Integer;
        Expr: TTypeExpr;
    end;
    
    PInheritableTypeCommand = ^TInheritableTypeCommand;
    TInheritableTypeCommand = record
        IdCode: Integer;
        Expr: TTypeExpr;
    end;
    
    PDefinitionCommand = ^TDefinitionCommand;
    TDefinitionCommand = record
        IdCode: Integer;
        Patterns: TPatternExprArray;
        Return: TValueExpr;
    end;
    
    PAssignmentCommand = ^TAsssignmentCommand;
    TAsssignmentCommand = record
        IdCode: Integer;
        Expr: TValueExpr;
    end;
    
    PEvaluationCommand = ^TEvaluationCommand;
    TEvaluationCommand = record
        Show: Boolean;
        Store: Boolean;
        Expr: TValueExpr;
    end;
    
    TCommand = packed record
        Kind: Byte;
        case Byte of
            FX_CMD_NONE       : (Tag: Integer);
            FX_CMD_RUN        : (Run: PRunCommand);
            FX_CMD_CLEAR      : (Clear: PClearCommand);
            FX_CMD_NOTATION   : (Notation: PNotationCommand);
            FX_CMD_SYNONYMOUS : (Synonymous: PTypeSynonymousCommand);
            FX_CMD_INHERITABLE: (Inheritable: PInheritableTypeCommand);
            FX_CMD_DEFINITION : (Definition: PDefinitionCommand);
            FX_CMD_ASSIGNMENT : (Assignment: PAssignmentCommand);
            FX_CMD_EVALUATION : (Evaluation: PEvaluationCommand);
    end;
    
procedure EmptyCommand(var ACmd: TCommand);
procedure ReleaseCommand(var ACmd: TCommand);
procedure CopyCommand(ASourceCmd: TCommand; var ADestCmd: TCommand);

implementation

procedure EmptyCommand(var ACmd: TCommand);
begin
    ACmd.Kind := FX_CMD_NONE;
    ACmd.Tag := 0;
end;

procedure ReleaseCommand(var ACmd: TCommand);
var
    K: Integer;
begin
    with ACmd do begin
        case Kind of
            FX_CMD_NONE       : begin
                Tag := 0;
            end;
            FX_CMD_RUN     : begin
                if Run^.ScriptFile <> nil then
                    Dispose(Run^.ScriptFile);
                Dispose(Run);
                Run := nil;
            end;
            FX_CMD_CLEAR : begin
                Clear^.IdCodes := nil;
                Dispose(Clear);
                Clear := nil;
            end;
            FX_CMD_NOTATION   : begin
                Notation^.IdCodes := nil;
                Dispose(Notation);
                Notation := nil;
            end;
            FX_CMD_SYNONYMOUS : begin
                EraseTypeBranch(Synonymous^.Expr);
                Dispose(Synonymous);
                Synonymous := nil;
            end;
            FX_CMD_INHERITABLE: begin
                EraseTypeBranch(Inheritable^.Expr);
                Dispose(Inheritable);
                Inheritable := nil;
            end;
            FX_CMD_DEFINITION : begin
                for K := 0 to Length(Definition^.Patterns) - 1 do
                    EraseValueBranch(Definition^.Patterns[K]);
                Definition^.Patterns := nil;
                EraseValueBranch(Definition^.Return);
                Dispose(Definition);
                Definition := nil;
            end;
            FX_CMD_ASSIGNMENT: begin
                EraseValueBranch(Assignment^.Expr);
                Dispose(Assignment);
                Assignment := nil;
            end;
            FX_CMD_EVALUATION : begin
                EraseValueBranch(Evaluation^.Expr);
                Dispose(Evaluation);
                Evaluation := nil;
            end;
        end;
        Kind := FX_CMD_NONE;
        Tag := 0;
    end;
end;

procedure CopyCommand(ASourceCmd: TCommand; var ADestCmd: TCommand);
var
    K: Integer;
begin
    ADestCmd.Kind := ASourceCmd.Kind;
    with ADestCmd do begin
        case Kind of
            FX_CMD_NONE       : begin
                Tag := ASourceCmd.Tag;
            end;
            FX_CMD_RUN     : begin
                System.New(Run);
                Run^.ScriptFile^ := ASourceCmd.Run^.ScriptFile^;
            end;
            FX_CMD_NOTATION   : begin
                System.New(Notation);
                Notation^.Priority := ASourceCmd.Notation^.Priority;
                Notation^.Position := ASourceCmd.Notation^.Position;
                SetLength(Notation^.IdCodes, Length(ASourceCmd.Notation^.IdCodes));
                for K := 0 to Length(Notation^.IdCodes) - 1 do
                    Notation^.IdCodes[K] := ASourceCmd.Notation^.IdCodes[K];
            end;
            FX_CMD_SYNONYMOUS : begin
                System.New(Synonymous);
                Synonymous^.IdCode := ASourceCmd.Synonymous^.IdCode;
                Synonymous^.Expr := nil;
                CopyTypeBranch(ASourceCmd.Synonymous^.Expr, Synonymous^.Expr);
            end;
            FX_CMD_INHERITABLE: begin
                System.New(Inheritable);
                Inheritable^.IdCode := ASourceCmd.Inheritable^.IdCode;
                Inheritable^.Expr := nil;
                CopyTypeBranch(ASourceCmd.Inheritable^.Expr, Inheritable^.Expr);
            end;
            FX_CMD_DEFINITION : begin
                System.New(Definition);
                Definition^.IdCode := ASourceCmd.Definition^.IdCode;
                SetLength(Definition^.Patterns, Length(ASourceCmd.Definition^.Patterns));
                for K := 0 to Length(Definition^.Patterns) - 1 do begin
                    Definition^.Patterns[K] := nil;
                    CopyValueBranch(ASourceCmd.Definition^.Patterns[K], Definition^.Patterns[K]);
                end;
                Definition^.Return := nil;
                CopyValueBranch(ASourceCmd.Definition^.Return, Definition^.Return);
            end;
            FX_CMD_ASSIGNMENT: begin
                System.New(Assignment);
                Assignment^.IdCode := ASourceCmd.Assignment^.IdCode;
                Assignment^.Expr := nil;
                CopyValueBranch(ASourceCmd.Assignment^.Expr, Assignment^.Expr);
            end;
            FX_CMD_CLEAR : begin
                System.New(Clear);
                SetLength(Clear^.IdCodes, Length(ASourceCmd.Clear^.IdCodes));
                for K := 0 to Length(Clear^.IdCodes) - 1 do
                    Clear^.IdCodes[K] := ASourceCmd.Clear^.IdCodes[K];
            end;
            FX_CMD_EVALUATION : begin
                System.New(Evaluation);
                Evaluation^.Show := Evaluation^.Show;
                Evaluation^.Store := Evaluation^.Store;
                Evaluation^.Expr := nil;
                CopyValueBranch(ASourceCmd.Evaluation^.Expr, Evaluation^.Expr);
            end;
        end;
    end;
end;

end.
