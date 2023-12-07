#ifndef FXHILITE_H
#define FXHILITE_H

#include <QtWidgets>
#include "hilite.h"

#define FX_DEFAULT              0
#define FX_COMMENT              1
#define FX_NUMBER               2
#define FX_CHARACTER            3
#define FX_STRING               4
#define FX_RESERVED             5
#define FX_PRIMITIVE            6
#define FX_IDENTIFIER           7
#define FX_LOWERCASEWORD        8
#define FX_OPERATOR             9
#define FX_DELIMITER            10
#define FX_SPACES               11
#define FX_EOL                  12
#define FX_URL                  13
#define FX_TYPE                 14
#define FX_BOOLEAN              15
#define FX_FAIL                 16
#define FX_UNKNOWN              17
#define FX_PROMPTER             18
#define FX_OUTPUT               19
#define FX_CONSOLE              20

#define FX_ELM_COUNT            21

class FXHighlighter: public Highlighter
{
    Q_OBJECT

public:
    FXHighlighter(QTextDocument *parent = nullptr);

    void copy(Highlighter *other) override;

    void setDistinguishLowercase(bool d);
    bool distinguishLowercase(){return distinguishlowercase;}
protected:
    void highlightLine(const QString &text, TextBlockData *data) override;
    virtual void highlightPrompter(const QString &text, TextBlockData *data, int &i);
    QTextCharFormat tokenFormat(char tk) override;
public:
    QTextCharFormat formats[FX_ELM_COUNT];
    bool distinguishlowercase = true;
};

#endif // FXHILITE_H
