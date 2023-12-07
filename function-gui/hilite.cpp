#include "hilite.h"

bool isEoLChar(const QChar &c)
{
    return (c == 0x10) || (c == 0x13);
}

bool isSpaceChar(const QChar &c)
{
    return (c == ' ') || (c == '\t');
}

bool isDecimalChar(const QChar &c)
{
    return ((c >= '0') && (c <= '9'));
}

bool isHexadecimalChar(const QChar &c)
{
    return isDecimalChar(c) || ((c >= 'a') && (c <= 'f')) || ((c >= 'A') && (c <= 'F'));
}

bool isWordChar(const QChar &c)
{
    return ((c >= 'a') && (c <= 'z')) || ((c >= 'A') && (c <= 'Z'))
            || (c == '_');
}

Highlighter::Highlighter(QTextDocument *parent):
    QSyntaxHighlighter(parent)
{

    rightedgecolor = QColor("#ff89cb");

    QTextCharFormat f;
    QFont font;
    font.setFamily("Courier New");
    font.setBold(false);
    font.setItalic(false);
    font.setUnderline(false);
    font.setStrikeOut(false);
    font.setPointSize(9);

    f.setFont(font);
    f.setBackground(Qt::white);
    f.setForeground(Qt::black);
    defaultformat = f;

    f.setForeground(QColor(0xff0000));
    f.setBackground(QColor(0xffffff));
    f.setFontWeight(QFont::Bold);
    bracesformat = f;

    // markers

    f.setFont(font);

    f.setBackground(Qt::white);
    f.setForeground(Qt::black);
    markers[MARKER_EMPTY            ] = f;

    f.setBackground(QColor(0xf0f0f0));
    f.setForeground(QColor(0x9488bf));
    markers[MARKER_GUTTER           ] = f;

    f.setBackground(QColor(0xfbfbfb));
    f.setForeground(Qt::black);
    markers[MARKER_CURRENT_LINE     ] = f;

    f.setBackground(QColor(0xf0f0f0));
    f.setForeground(QColor("#9488bf"));
    markers[MARKER_CURRENT_GUTTER   ] = f;

}

void Highlighter::copy(Highlighter *other)
{
    if (!other) return;

    for(int i = MARKER_EMPTY; i < MARKER_COUNT; i++)
        markers[i] = other->markers[i];
    rightedgecolor = other->rightedgecolor;

    refresh();
}

void Highlighter::refresh()
{
    if (refreshonly) return;
    refreshonly = true;
    rehighlight();
    refreshonly = false;
}


QTextCharFormat Highlighter::tokenFormat(char)
{
    return defaultformat;
}

void Highlighter::colourise(int i, int t, char tk, TextBlockData *data)
{
    for (int k = i; k < t; k++) data->cache[k] = tk;
    setFormat(i, t - i, tokenFormat(tk)); // usefull for plain text
}

void Highlighter::highlightLine(const QString &text, TextBlockData *data)
{
    colourise(0, text.length(), 0, data);
}

void Highlighter::highlightBlock(const QString &text)
{
    if (refreshonly){
        TextBlockData *thedata = static_cast<TextBlockData *>(currentBlockUserData());
        if (thedata){
            int k = 0;
            int l = thedata->oldstr.length();
            while (k < l){
                char tk = thedata->cache[k];
                int t = k;
                while (t < l && tk == thedata->cache[t]){
                    setFormat(k, t - k, tokenFormat(tk));
                    t++;
                }
                k = t;
            }
        }
        return;
    }


    int cell;
    int status;
    TextBlockData *olddata = static_cast<TextBlockData *>(currentBlockUserData());
    if (olddata != nullptr){
        cell = olddata->cell;
        status = olddata->status;
        if (olddata->oldstr != text)
            status = LINE_STATUS_MODIFIED;
    }
    else{ // new block
        cell = 0;
        status = LINE_STATUS_MODIFIED;
    }

    TextBlockData *data = createBlockData(text, cell, status);

    highlightLine(text, data);

    setCurrentBlockUserData(data);
}

TextBlockData *Highlighter::createBlockData(const QString &str, int cell, int status)
{
    TextBlockData *data = new TextBlockData;
    data->oldstr = str;
    data->status = status;
    data->cell = cell;
    data->createFormatCache(); // usefull for refresh
    return data;
}

