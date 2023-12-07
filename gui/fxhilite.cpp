#include "fxhilite.h"

FXHighlighter::FXHighlighter(QTextDocument *parent):
    Highlighter(parent)
{
    QTextCharFormat f = defaultformat;

    f.setForeground(Qt::black);
    formats[FX_DEFAULT          ] = f;

    f.setFontItalic(true);
    f.setForeground(QColor("#808080"));
    formats[FX_COMMENT          ] = f;

    f.setFontItalic(false);
    f.setForeground(QColor("#ff8000"));
    formats[FX_NUMBER           ] = f;

    f.setFontItalic(false);
    f.setForeground(Qt::darkGreen);
    formats[FX_CHARACTER        ] = f;
    formats[FX_STRING           ] = f;

    f.setFontItalic(false);
    f.setForeground(Qt::blue);
    formats[FX_RESERVED         ] = f;

    f.setFontItalic(true);
    f.setForeground(Qt::black);
    formats[FX_PRIMITIVE        ] = f;

    f.setFontItalic(false);
    f.setForeground(Qt::black);
    formats[FX_IDENTIFIER       ] = f;

    f.setFontItalic(false);
    f.setForeground(Qt::darkCyan);
    formats[FX_LOWERCASEWORD    ] = f;

    f.setFontItalic(false);
    f.setForeground(Qt::darkBlue);
    formats[FX_OPERATOR         ] = f;
    formats[FX_DELIMITER        ] = f;

    f.setForeground(QColor("#404040"));
    formats[FX_SPACES           ] = f;
    formats[FX_EOL              ] = f;

    f.setFontUnderline(true);
    f.setForeground(QColor("#808080"));
    formats[FX_URL              ] = f;

    f.setFontUnderline(false);
    f.setForeground(Qt::darkMagenta);
    formats[FX_TYPE             ] = f;

    f.setForeground(Qt::darkYellow);
    formats[FX_BOOLEAN          ] = f;

    f.setForeground(QColor("#ff0080"));
    formats[FX_FAIL             ] = f;

    f.setForeground(Qt::black);
    formats[FX_UNKNOWN          ] = f;

    f.setForeground(Qt::darkRed);
    formats[FX_PROMPTER         ] = f;

    f.setForeground(QColor("#383838"));
    formats[FX_OUTPUT           ] = f;

    f.setForeground(Qt::black);
    formats[FX_CONSOLE          ] = f;
}

void FXHighlighter::copy(Highlighter *other)
{
    if (!other) return;

    FXHighlighter *fxother = qobject_cast<FXHighlighter*>(other);
    if (fxother){
        for(int i = FX_DEFAULT; i < FX_ELM_COUNT; i++)
            formats[i] = fxother->formats[i];
        distinguishlowercase = fxother->distinguishlowercase;
    }

    Highlighter::copy(other);
}

void FXHighlighter::setDistinguishLowercase(bool d)
{
    if (distinguishlowercase != d){
        distinguishlowercase = d;
        refresh();
    }
}

QTextCharFormat FXHighlighter::tokenFormat(char tk)
{
    return formats[static_cast<int>(tk)];
}

bool isFxUppercaseWordChar(const QChar &c)
{
    return (c >= 'A') && (c <= 'Z');
}

bool isOperatorChar(const QChar &c)
{
    return  (c == '|') || (c == '!') || (c == '#') || (c == '$') ||
            (c == '%') || (c == '&') || (c == '/') || (c == '=') ||
            (c == '\\') || (c == '?') || (c == '+') || (c == '*') ||
            (c == '~') || (c == '^') || (c == '`') || (c == '-') ||
            (c == '.') || (c == ':') || (c == ',') || (c == ';') ||
            (c == '@') || (c == '<') || (c == '>');
}

bool isBraceChar(const QChar &c)
{
    return  (c == '(') || (c == ')') || (c == '[') || (c == ']') ||
            (c == '{') || (c == '}');
}

bool isBooleanWord(const QString &s)
{
    if ((s == "true") ||
        (s == "false"))
        return true;
    return false;
}

bool isFailWord(const QString &s)
{
    return (s == "fail");
}

bool isNumberWord(const QString &s)
{
    if ((s == "inf") || (s == "nan"))
        return true;
    else
        return false;
}

bool isPrimitiveWord(const QString &s)
{
    if ((s == "PrimAdd"             ) ||
        (s == "PrimSub"             ) ||
        (s == "PrimMul"             ) ||
        (s == "PrimDiv"             ) ||
        (s == "PrimPow"             ) ||
        (s == "PrimEqual"           ) ||
        (s == "PrimLess"            ) ||
        (s == "PrimGreater"         ) ||
        (s == "PrimIsNaN"           ) ||
        (s == "PrimTrunc"           ) ||
        (s == "PrimFrac"            ) ||
        (s == "PrimSin"             ) ||
        (s == "PrimCos"             ) ||
        (s == "PrimTan"             ) ||
        (s == "PrimASin"            ) ||
        (s == "PrimACos"            ) ||
        (s == "PrimATan"            ) ||
        (s == "PrimLn"              ) ||
        (s == "PrimExp"             ) ||
        (s == "PrimRem"             ) ||
        (s == "PrimQuot"            ) ||
        (s == "PrimBitNot"          ) ||
        (s == "PrimBitAnd"          ) ||
        (s == "PrimBitOr"           ) ||
        (s == "PrimBitShl"          ) ||
        (s == "PrimBitShr"          ) ||
        (s == "PrimRandom"          ) ||
        (s == "PrimEncodeChar"      ) ||
        (s == "PrimDecodeChar"      ) ||
        (s == "PrimLength"          ) ||
        (s == "PrimGet"             ) ||
        (s == "PrimSet"             ) ||
        (s == "PrimArity"           ) ||
        (s == "PrimSelect"          ) ||
        (s == "PrimPut"             ) ||
        (s == "PrimInput"           ) ||
        (s == "PrimOutput"          ) ||
        (s == "PrimClearScreen"     ) ||
        (s == "PrimGetDateTime"     ) ||
        (s == "PrimSetDateTime"     ) ||
        (s == "PrimAnswer"          ) ||
        (s == "PrimError"           ) ||
        (s == "PrimTryStrToNum"     ) ||
        (s == "PrimValueToStr"      ) ||
        (s == "PrimTypeToStr"       ) ||
        (s == "PrimValueToStrFull"  ) ||
        (s == "PrimIsAnonymous"     ) ||
        (s == "PrimIsFreeIdentifier") ||
        (s == "PrimIsTuple"         ) ||
        (s == "PrimIsLambda"        ) ||
        (s == "PrimLanguage"        ) ||
        (s == "PrimQuit"            ) ||
        (s == "PrimInterrupt"       ) ||
        (s == "PrimRestart"         ))
        return true;
    else
        return false;
}

bool isReservedWord(const QString &s)
{
    if ((s == "_"     ) ||
        (s == "let"   ) ||
        (s == "in"    ) ||
        (s == "where" ) ||
        (s == "run"   ) ||
        (s == "clear" ) ||
        (s == "infix" ) ||
        (s == "infixl") ||
        (s == "infixr") ||
        (s == "posfix") ||
        (s == "prefix") ||
        (s == "begin" ) ||
        (s == "if"    ) ||
        (s == "elif"  ) ||
        (s == "then"  ) ||
        (s == "else"  ) ||
        (s == "while" ) ||
        (s == "do"    ) ||
        (s == "for"   ) ||
        (s == "return") ||
        (s == "end"   ) ||
        (s == "real"  ) ||
        (s == "int"   ) ||
        (s == "nat"   ) ||
        (s == "bool"  ) ||
        (s == "char"  ))
        return true;
    else
        return false;
}

bool isTypeWord(const QString &s)
{
    if ((s == "Real"    ) ||
        (s == "Nat"     ) ||
        (s == "Int"     ) ||
        (s == "Bool"    ) ||
        (s == "Char"    ) ||
        (s == "String"  ) ||
        (s == "Function") ||
        (s == "Pair"    ) ||
        (s == "List"    ) ||
        (s == "Degree"  ) ||
        (s == "Radian"  ) ||
        (s == "Complex" ) ||
        (s == "Vector"  ) ||
        (s == "Matrix"  ) ||
        (s == "Point"   ))
        return true;
    else
        return false;
}

bool isLowercaseWord(const QString &s)
{
    int l = s.length();
    for (int i = 0; i < l; i++)
        if (isFxUppercaseWordChar(s[i]))
            return false;
    return true;
}

bool consumeEoL(const QString &text, int &i, int l)
{
    if ((i < l) && (text[i] == CR)){
        i++;
        if ((i < l) && (text[i] == LF))
            i++;
        return true;
    }
    else if ((i < l) && (text[i] == LF)){
        i++;
        return true;
    }
    return false;
}

void FXHighlighter::highlightPrompter(const QString &, TextBlockData *, int &)
{
    // do nothing
}

void FXHighlighter::highlightLine(const QString &text, TextBlockData *data)
{
    int l = text.length();
    int i = 0;
    int token = FX_DEFAULT;
    int f = 0;

    highlightPrompter(text, data, i);

    if (previousBlockState() == FX_STRING){
        f = i;
        goto LBL_CONTINUE_STRING;
    }

    setCurrentBlockState(-1);

LBL_AGAIN:

    if (i >= l) goto LBL_END;

    // posible comment
    if (text[i] == '.'){
        if (i + 1 < l){
            if (text[i + 1] == '.'){
                if (i + 2 < l){
                    if (text[i + 2] == '.'){
                        // comment
                        f = i;
                        i += 3;
                        token = FX_COMMENT;
                        while ((i < l) && (!isEoLChar(text[i]))){
                            // int _from, _to;
                            // if (scanAutoUrl(i, _from, _to)){
                            //     token = FX_URL;
                            //     i = _t;
                            // }
                            // else
                            i++;
                        }
                        colourise(f, i, token, data);
                    }
                }
            }
        }
    }

    if (i >= l) goto LBL_END;

    // numbers
    if (isDecimalChar(text[i])){
        // decimal, hex, octal and binary
        f = i;
        token = FX_NUMBER;
        QChar x = text[i];
        i++;
        if (i < l){
            if ((x == '0') && ((text[i] == 'x') || (text[i] == 'X'))){
                // hexadecimal
                i++;
                while ((i < l) && isHexadecimalChar(text[i])) i++;
                //token = FX_HEX_NUMBER;
            }
            else {
                // decimal
                while ((i < l) && isDecimalChar(text[i])) i++;
                if ((i < l) && (text[i] == '.')){
                    i++;
                    while ((i < l) && isDecimalChar(text[i])) i++;
                }
                if ((i < l) && ((text[i] == 'e') || (text[i] == 'E'))){
                    i++;
                    if ((i < l) && ((text[i] == '+') || (text[i] == '-')))
                        i++;
                    while ((i < l) && isDecimalChar(text[i])) i++;
                }
                //token = FX_DEC_NUMBER;
            }
        }
        colourise(f, i, token, data);
    }
    // words
    else if (isWordChar(text[i])){
        // identifiers and reserveds
        f = i;
        while ((i < l) && isWordChar(text[i])) i++;
        QString s = text.mid(f, i - f);
        if (isFailWord(s))
            token = FX_FAIL;
        else if (isBooleanWord(s))
            token = FX_BOOLEAN;
        else if (isNumberWord(s))
            token = FX_NUMBER;
        else if (isReservedWord(s))
            token = FX_RESERVED;
        else if (isTypeWord(s))
            token = FX_TYPE;
        else if (isPrimitiveWord(s))
            token = FX_PRIMITIVE;
        else if (distinguishLowercase() && isLowercaseWord(s))
             token = FX_LOWERCASEWORD;
        else
            token = FX_IDENTIFIER;
        colourise(f, i, token, data);
    }
    // strings
    else if (text[i] == '"'){
        // string
        f = i;
        i++;
LBL_CONTINUE_STRING:
        token = FX_STRING;
        while ((i < l) && (text[i] != '"') && !isEoLChar(text[i])){
            if (text[i] == '\\'){
                if ((i + 1 < l) && !isEoLChar(text[i + 1]))
                    i++;
                // i++;
                // consumeEoL(text, i, l);
                // if (i == l) setCurrentBlockState(token);
            }
            i++;
        }
        if ((i < l) && (text[i] == '"')) i++;
        colourise(f, i, token, data);
    }
    else if (text[i] == '\''){
        // char
        f = i;
        i++;
        token = FX_CHARACTER;
        while ((i < l) && (text[i] != '\'') && !isEoLChar(text[i])){
            if (text[i] == '\\'){
                if ((i + 1 < l) && !isEoLChar(text[i + 1]))
                    i++;
            }
            i++;
        }
        if ((i < l) && (text[i] == '\'')) i++;
        colourise(f, i, token, data);
    }
    // operators
    else if (isOperatorChar(text[i])){
        f = i;
        token = FX_OPERATOR;
        while ((i < l) && isOperatorChar(text[i])) i++;
        colourise(f, i, token, data);
    }
    else if (isBraceChar(text[i])){
        f = i;
        token = FX_DELIMITER;
        data->append(text[i], i);
        i++;
        colourise(f, i, token, data);
    }
    // newline
    else if (isEoLChar(text[i])){
        f = i;
        token = FX_EOL;
        consumeEoL(text, i, l);
        colourise(f, i, token, data);
    }
    // spaces
    else if (isSpaceChar(text[i])){
        f = i;
        while ((i < l) && isSpaceChar(text[i])) i++;
        colourise(f, i, FX_SPACES, data); // don't store in token
    }
    // unknown
    else{
        token = FX_UNKNOWN;
        colourise(i, i + 1, token, data);
        i++;
    }

    goto LBL_AGAIN;

LBL_END:
    return;
}

