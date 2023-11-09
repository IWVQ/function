#ifndef HILITE_H
#define HILITE_H

#include <QtWidgets>

/*
TODO:
    - load config from master
    - load config from json
*/

#define CR '\x0D'
#define LF '\x0A'

// markers

#define MARKER_EMPTY            0
#define MARKER_CURRENT_LINE     1
#define MARKER_CURRENT_GUTTER   2
#define MARKER_GUTTER           3

#define MARKER_COUNT            4

// block status

#define LINE_STATUS_PURE      0x00
#define LINE_STATUS_MODIFIED  0x01
#define LINE_STATUS_SAVED     0x02


struct BraceInfo
{
    char ch;
    int pos;
};

class TextBlockData: public QTextBlockUserData
{
public:
    TextBlockData():QTextBlockUserData(){}
    ~TextBlockData(){}

    void append(QChar c, int pos)
    {
        BraceInfo info;
        info.ch = c.toLatin1();
        info.pos = pos;
        braces.append(info);
    }

    int find(int pos)
    {
        for (int i = 0; i < braces.size(); i++)
            if ((pos - 1 == braces[i].pos) || (pos == braces[i].pos))
                return i;
        return -1;
    }

public:
    QString oldstr = "";
    int status = 0;
    int style = 0;
    QList<BraceInfo> braces;
};

class Highlighter: public QSyntaxHighlighter
{
    Q_OBJECT

public:
    Highlighter(QTextDocument *parent = nullptr);

    virtual void copy(Highlighter *other);
    void update();

protected:
    void highlightBlock(const QString &text) override;
    virtual void highlightLine(const QString &text, TextBlockData *data);
    virtual void colourise(int i, int t, int tk);
public:
    QTextCharFormat markers[MARKER_COUNT];
    QTextCharFormat defaultformat;
    QTextCharFormat bracesformat;
    QColor rightedgecolor;
    int newlinestyle = 0;

    QColor savedstatuscolor = Qt::darkGreen;
    QColor modifiedstatuscolor = Qt::red;
};

bool isEoLChar(const QChar &c);
bool isSpaceChar(const QChar &c);
bool isDecimalChar(const QChar &c);
bool isHexadecimalChar(const QChar &c);
bool isWordChar(const QChar &c);

#endif // HILITE_H
