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

    update();
}

void Highlighter::update()
{
    rehighlight();
}

void Highlighter::colourise(int i, int t, int tk)
{}

void Highlighter::highlightLine(const QString &text, TextBlockData *data)
{
    setFormat(0, text.length(), defaultformat); // usefull for plain text
}

void Highlighter::highlightBlock(const QString &text)
{
    int style;
    int status;
    TextBlockData *olddata = static_cast<TextBlockData *>(currentBlockUserData());
    if (olddata != nullptr){
        style = olddata->style;
        status = olddata->status;
        if (olddata->oldstr != text)
            status = LINE_STATUS_MODIFIED;
    }
    else{ // new block
        style = newlinestyle;
        status = LINE_STATUS_MODIFIED;
    }

    TextBlockData *data = new TextBlockData;
    data->oldstr = text;
    data->status = status;
    data->style = style;

    highlightLine(text, data);

    setCurrentBlockUserData(data);
}

