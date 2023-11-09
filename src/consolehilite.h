#ifndef CONSOLEHILITE_H
#define CONSOLEHILITE_H

#include <QtWidgets>
#include "fxhilite.h"

#define LINE_STYLE_DEFAULT  0
#define LINE_STYLE_INPUT    1
#define LINE_STYLE_PROMPTER 2
#define LINE_STYLE_OUTPUT   3
#define LINE_STYLE_ERROR    4

class ConsoleHighlighter: public FXHighlighter
{
    Q_OBJECT

public:
    ConsoleHighlighter(QTextDocument *parent = nullptr);

    void copy(Highlighter *other) override;
protected:
    void highlightLine(const QString &text, TextBlockData *data) override;
public:
    bool colouredoutput = false;

    QTextCharFormat reportformat;
    QTextCharFormat outputformat;
    QTextCharFormat errorformat;
};


#endif // CONSOLEHILITE_H
