#ifndef CONSOLEHILITE_H
#define CONSOLEHILITE_H

#include <QtWidgets>
#include "fxhilite.h"


#define CELL_CONSOLE    0
#define CELL_HEADER     1 // mask only
#define CELL_PROMPTER   CELL_HEADER
#define CELL_INPUT      2
#define CELL_OUTPUT     4

class ConsoleHighlighter: public FXHighlighter
{
    Q_OBJECT

public:
    ConsoleHighlighter(QTextDocument *parent = nullptr);

    void copy(Highlighter *other) override;
protected:
    void highlightPrompter(const QString &text, TextBlockData *data, int &i) override;
    void highlightLine(const QString &text, TextBlockData *data) override;
public:
    int currentcellline = -1;
    int currentcelltype = CELL_CONSOLE;
    bool colouredoutput = false;
    bool embeddedprompter = false;

    QTextCharFormat reportformat;
};


#endif // CONSOLEHILITE_H
