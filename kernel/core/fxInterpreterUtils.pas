unit fxInterpreterUtils;

interface

uses
    fxUtils, fxBasicStructure;

type
    
    IInterpreterListener = interface
        function __RunScript(S: TFxString): Word;
        function __Reduce(V: TValueExpr): Word;
        function __ReplaceIdentifier(I: Integer; A, R: TValueExpr): Word;
    end;
    
implementation

end.
