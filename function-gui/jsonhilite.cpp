#include "jsonhilite.h"

JSONHighlighter::JSONHighlighter(QTextDocument *parent):
    Highlighter(parent)
{
    QTextCharFormat f = defaultformat;

    f.setForeground(QColor("#808080"));
    formats[JSON_DEFAULT          ] = f;

    f.setForeground(QColor("#ff8000"));
    formats[JSON_NUMBER           ] = f;

    f.setForeground(Qt::darkGreen);
    formats[JSON_STRING           ] = f;

    f.setForeground(Qt::blue);
    formats[JSON_PROPERTY         ] = f;

    f.setForeground(Qt::darkCyan);
    formats[JSON_RESERVED         ] = f;

    f.setForeground(Qt::darkBlue);
    formats[JSON_DELIMITER        ] = f;

    f.setForeground(QColor("#404040"));
    formats[JSON_SPACES           ] = f;
}

void JSONHighlighter::copy(Highlighter *other)
{
    if (!other) return;

    JSONHighlighter *fxother = qobject_cast<JSONHighlighter*>(other);
    if (fxother){
        for(int i = JSON_DEFAULT; i < JSON_ELM_COUNT; i++)
            formats[i] = fxother->formats[i];
    }

    Highlighter::copy(other);
}

QTextCharFormat JSONHighlighter::tokenFormat(char tk)
{
    return formats[static_cast<int>(tk)];
}

bool isJsonSpaceChar(const QChar &c)
{
    return isEoLChar(c) || (c == ' ') || (c == '\t');
}

bool isJsonWordChar(const QChar &c)
{
    return ((c >= 'a') && (c <= 'z')) || ((c >= 'A') && (c <= 'Z'));
}

bool isJsonReservedWord(const QString &s)
{
    return (s == "true") || (s == "false") || (s == "null");
}

bool isJsonDelimiterChar(const QChar &c)
{
    return  (c == '(') || (c == ')') || (c == '[') || (c == ']') ||
            (c == '{') || (c == '}') || (c == ',') || (c == ':');
}

void JSONHighlighter::highlightLine(const QString &text, TextBlockData *data)
{
    int l = text.length();
    int i = 0;
    int token = JSON_DEFAULT;
    int f = 0;

    setCurrentBlockState(-1);
LBL_AGAIN:

    if (i >= l) goto LBL_END;

    // numbers
    if ((text[i] == '+') || (text[i] == '-')){
        // posible signed number
        f = i;
        i++;
        if ((i < l) && isDecimalChar(text[i]))
            goto LBL_NUMBER;
        else
            colourise(f, i, JSON_DEFAULT, data);
    }
    else if (isDecimalChar(text[i])){
        // decimal
        f = i;
LBL_NUMBER:
        token = JSON_NUMBER;
        i++;
        if (i < l){
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
        }
        colourise(f, i, token, data);
    }
    // words
    else if (isJsonWordChar(text[i])){
        // reserveds
        f = i;
        while ((i < l) && isWordChar(text[i])) i++;
        QString s = text.mid(f, i - f);
        if (isJsonReservedWord(s))
            token = JSON_RESERVED;
        else
            token = JSON_DEFAULT;
        colourise(f, i, token, data);
    }
    // strings
    else if (text[i] == '"'){
        // string
        f = i;
        i++;
        token = JSON_STRING;
        while ((i < l) && (text[i] != '"') && !isEoLChar(text[i])){
            if (text[i] == '\\'){
                if ((i + 1 < l) && !isEoLChar(text[i + 1]))
                    i++;
            }
            i++;
        }
        if ((i < l) && (text[i] == '"')) i++;

        // consume spaces after string
        int k = i;
        while((k < l) && isJsonSpaceChar(text[k])) k++;
        colourise(i, k, JSON_SPACES, data);

        // test if is property
        if ((k < l) && (text[k] == ':'))
            token = JSON_PROPERTY;

        // colourise token
        colourise(f, i, token, data);

        i = k; // jump to k
    }
    else if (isJsonDelimiterChar(text[i])){
        f = i;
        token = JSON_DELIMITER;
        data->append(text[i], i);
        i++;
        colourise(f, i, token, data);
    }
    // spaces or eol
    else if (isJsonSpaceChar(text[i])){
        f = i;
        while ((i < l) && (isJsonSpaceChar(text[i]) )) i++;
        colourise(f, i, JSON_SPACES, data); // don't store in token
    }
    // unknown
    else{
        token = JSON_DEFAULT;
        colourise(i, i + 1, token, data);
        i++;
    }

    goto LBL_AGAIN;

LBL_END:
    return;
}
