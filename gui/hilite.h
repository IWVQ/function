#ifndef HILITE_H
#define HILITE_H

#include <QtWidgets>

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
    ~TextBlockData()
    {
        if (cache) delete []cache;
    }

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

    void createFormatCache()
    {
        if (cache) delete[]cache;
        cache = new char[oldstr.length()];
    }

public:
    char *cache = nullptr; // used for refresh
    QString oldstr = "";
    int status = 0;
    int cell = 0;
    QList<BraceInfo> braces;
};

class Highlighter: public QSyntaxHighlighter
{
    Q_OBJECT

public:
    Highlighter(QTextDocument *parent = nullptr);

    virtual void copy(Highlighter *other);
    void refresh();

protected:
    void highlightBlock(const QString &text) override;
    virtual void highlightLine(const QString &text, TextBlockData *data);
    virtual QTextCharFormat tokenFormat(char tk);
    virtual void colourise(int i, int t, char tk, TextBlockData *data);
public:
    TextBlockData *createBlockData(const QString &str, int cell, int status = LINE_STATUS_MODIFIED);

    QTextCharFormat markers[MARKER_COUNT];
    QTextCharFormat defaultformat;
    QTextCharFormat bracesformat;
    QColor rightedgecolor;

    QColor savedstatuscolor = Qt::darkGreen;
    QColor modifiedstatuscolor = Qt::red;
private:
    bool refreshonly = false;
};

bool isEoLChar(const QChar &c);
bool isSpaceChar(const QChar &c);
bool isDecimalChar(const QChar &c);
bool isHexadecimalChar(const QChar &c);
bool isWordChar(const QChar &c);

#endif // HILITE_H
