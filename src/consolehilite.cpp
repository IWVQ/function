#include "consolehilite.h"

ConsoleHighlighter::ConsoleHighlighter(QTextDocument *parent):
    FXHighlighter(parent)
{
    QTextCharFormat f = defaultformat;

    reportformat = defaultformat;

    f.setForeground(QColor("#404040"));
    outputformat = f;

    f.setForeground(Qt::darkRed);

    f.setForeground(QColor("#f14b54"));
    errorformat = f;
}

void ConsoleHighlighter::copy(Highlighter *other)
{
    if (!other) return;

    ConsoleHighlighter *cother = qobject_cast<ConsoleHighlighter*>(other);
    if (cother){
        colouredoutput = cother->colouredoutput;
    }

    FXHighlighter::copy(other);
}

void ConsoleHighlighter::highlightLine(const QString &text, TextBlockData *data)
{
    if (data->style == LINE_STYLE_INPUT || data->style == LINE_STYLE_PROMPTER)
        FXHighlighter::highlightLine(text, data); // inherited
    else if (data->style == LINE_STYLE_OUTPUT)
        setFormat(0, text.length(), outputformat);
    else if (data->style == LINE_STYLE_ERROR)
        setFormat(0, text.length(), errorformat);
    else
        setFormat(0, text.length(), reportformat);
}
