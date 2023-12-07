#include "consolehilite.h"

ConsoleHighlighter::ConsoleHighlighter(QTextDocument *parent):
    FXHighlighter(parent)
{
    QTextCharFormat f = defaultformat;
    reportformat = f;
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

void ConsoleHighlighter::highlightPrompter(const QString &text, TextBlockData *data, int &i)
{
    if (embeddedprompter) return;

    int l = text.length();
    if (i + 3 < l){
        int f = i;
        if (text[i + 0] == '>' &&
            text[i + 1] == '>' &&
            text[i + 2] == '>' &&
            text[i + 3] == ' ') {
            // arrow prompter
            i += 4;
            colourise(f, i, FX_PROMPTER, data);
        }
        else if (text[i + 0] == '.' &&
                 text[i + 1] == '.' &&
                 text[i + 2] == '.' &&
                 text[i + 3] == ' '){
            // space prompter
            i += 4;
            colourise(f, i, FX_PROMPTER, data);
        }
    }
}

void ConsoleHighlighter::highlightLine(const QString &text, TextBlockData *data)
{
    if (currentBlock().blockNumber() > currentcellline)
        data->cell = currentcelltype; // correct it
    if (data->cell & CELL_INPUT)
        FXHighlighter::highlightLine(text, data); // inherited
    else if (data->cell & CELL_OUTPUT)
        colourise(0, text.length(), FX_OUTPUT, data);
    else if (data->cell & CELL_CONSOLE){
        // do nothing, maintaing written formats
    }
}
