#ifndef JSONHILITE_H
#define JSONHILITE_H

#include <QtWidgets>
#include "hilite.h"

#define JSON_DEFAULT              0
#define JSON_NUMBER               1
#define JSON_STRING               2
#define JSON_PROPERTY             3
#define JSON_RESERVED             4
#define JSON_DELIMITER            5
#define JSON_SPACES               6

#define JSON_ELM_COUNT            7

class JSONHighlighter: public Highlighter
{
    Q_OBJECT

public:
    JSONHighlighter(QTextDocument *parent = nullptr);

    void copy(Highlighter *other) override;
protected:
    void highlightLine(const QString &text, TextBlockData *data) override;
    QTextCharFormat tokenFormat(char tk) override;
public:
    QTextCharFormat formats[JSON_ELM_COUNT];
};

#endif // JSONHILITE_H
