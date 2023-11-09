#include "console.h"

const int GUTTER_MARGIN = 3;
QString PROMPTER = ">>";

Console::Console(QWidget *parent)
    : CodeEditor(parent)
{

}

Console::~Console()
{

}

int Console::gutterWidth()
{
    int width = 2*GUTTER_MARGIN +
                QFontMetrics(currentCharFormat().font()).horizontalAdvance(PROMPTER);
    return width;
}

QString Console::gutterLineString(int i)
{
    QTextBlock block = document()->findBlockByNumber(i);
    TextBlockData *data = static_cast<TextBlockData *>(block.userData());
    if (data){
        if (data->style == LINE_STYLE_PROMPTER)
            return PROMPTER;
    }
    return "";
}

void Console::onCursorPositionChanged()
{
    dragselanchor = -1;
    dragselcaret = -1;
    CodeEditor::onCursorPositionChanged();
}

void Console::onSelectionChanged()
{
    dragselanchor = -1;
    dragselcaret = -1;
}

/*      no problem
QKeySequence::SelectAll
QKeySequence::Copy
Qt::Key_Direction_L
Qt::Key_Direction_R
QKeySequence::Undo
QKeySequence::Redo

        special skip
Qt::Key_Backspace
QKeySequence::Backspace

        skip if in protected area
QKeySequence::InsertParagraphSeparator
QKeySequence::InsertLineSeparator
QKeySequence::Cut
QKeySequence::Paste
QKeySequence::Delete
QKeySequence::DeleteEndOfWord
QKeySequence::DeleteStartOfWord
isAcceptableInput(e)

        skip always
QKeySequence::DeleteEndOfLine
QKeySequence::DeleteCompleteLine
Key_Back
Key_No

        check dragging
*/

void Console::protectDragSelection()
{
    // store anchor caret
    int anchor = textCursor().anchor();
    int caret = textCursor().position();
    QTextEdit::ExtraSelection dragselection;
    dragselection.cursor = textCursor();
    dragselection.format.setBackground(this->palette().highlight());
    dragselection.format.setForeground(this->palette().highlightedText());

    // colapse selection
    QTextCursor cursor = textCursor();
    cursor.setPosition(cursor.position());
    setTextCursor(cursor);

    // create extra selection
    QList<QTextEdit::ExtraSelection> selections;
    // brace and current
    colouriseCurrentLine(&selections);
    colouriseBraces(&selections);
    // the protected
    selections.append(dragselection);
    // extra selections
    setExtraSelections(selections);

    // store for the future
    dragselanchor = anchor;
    dragselcaret = caret;
}

bool Console::selectionInProtectedArea()
{
    int selstart = textCursor().selectionStart();
    int selend =  textCursor().selectionEnd();
    return (selstart < readonlyto || selend < readonlyto);
}

bool Console::checkReadOnlyEnd(QKeyEvent *event)
{
    int selstart = textCursor().selectionStart();
    int selend =  textCursor().selectionEnd();
    bool inprotectedarea = (selstart < readonlyto || selend < readonlyto);

    if  ( (event == QKeySequence::Backspace)
             ||(event->key() == Qt::Key_Backspace)
             ){
        if (inprotectedarea) return true;
        else if (selstart - 1 < readonlyto || selend - 1 < readonlyto)
            if (!textCursor().hasSelection())
                return true; // avoid delete back if caret at readonlyend
    }
    else if  ( (event == QKeySequence::Cut)
             ||(event == QKeySequence::Paste)
             ||(event == QKeySequence::Delete)
             ||(event == QKeySequence::DeleteEndOfWord)
             ||(event == QKeySequence::DeleteStartOfWord)
             ||(event == QKeySequence::InsertLineSeparator)
             ||(event == QKeySequence::InsertParagraphSeparator)
             ||(event->key() == Qt::Key_Backtab)
             ||(event->key() == Qt::Key_Tab)
             ||(event->key() == Qt::Key_Return)
             ||(!(event->text().isEmpty()))
             ){
        if (inprotectedarea) return true;
    }
    else if  ( (event == QKeySequence::DeleteEndOfLine)
             ||(event == QKeySequence::DeleteCompleteLine)
             ||(event->key() == Qt::Key_Back)
             ||(event->key() == Qt::Key_No)
             ){
        return true; // skip always
    }
    return false;
}

void Console::keyPressEvent(QKeyEvent *event)
{
    if (checkReadOnlyEnd(event))
        return; // skip

    CodeEditor::keyPressEvent(event);
}

void Console::dragEnterEvent(QDragEnterEvent *event)
{
    QPlainTextEdit::dragEnterEvent(event);
}

void Console::dragLeaveEvent(QDragLeaveEvent *event)
{
    if (dragoriginisme && selectionInProtectedArea())
        protectDragSelection();
    QPlainTextEdit::dragLeaveEvent(event);
}

void Console::dragMoveEvent(QDragMoveEvent *event)
{
    dragoriginisme = false;
    QWidget *source = dynamic_cast<QWidget *>(event->source());

    if (source)
        if (source->parent()){
            if (source->parent() == this){
                dragoriginisme = true;
            }
        }

    QPlainTextEdit::dragMoveEvent(event);

    // planning
    QPoint p = event->pos();
    int caret = document()->documentLayout()->hitTest(p, Qt::FuzzyHit);
    QTextCursor cursor = textCursor();
    if (caret < readonlyto) // caret == -1 too
        event->ignore(cursorRect(cursor)); // skip if target in protected
    else
        event->accept(cursorRect(cursor));
}

void Console::dropEvent(QDropEvent *event)
{
    if (dragoriginisme){
        if (selectionInProtectedArea()){
            QTextCursor cursor = textCursor();
            cursor.setPosition(cursor.position());
            setTextCursor(cursor);
        }
    }

    QPlainTextEdit::dropEvent(event);
}

bool Console::keyStrokeTab(bool back, QKeyEvent *event)
{
    return CodeEditor::keyStrokeTab(back, event);
}

bool Console::keyStrokeReturn(QKeyEvent *event)
{ //# needs implementation
    if (event->modifiers() & Qt::ShiftModifier)
        if (!selectionInProtectedArea())
            //if (textCursor().block().blockNumber() >= readonlylineto){
                //# run
                return true;
            //}

    return CodeEditor::keyStrokeReturn(event);
}

bool Console::keyStrokeUp(QKeyEvent *event)
{ //# needs implementation
    //if (!textCursor().hasSelection() && (textCursor().blockNumber() == readonlylineto)){
        //# command up
        return true;
    //}
    return CodeEditor::keyStrokeUp(event);
}

bool Console::keyStrokeDown(QKeyEvent *event)
{ //# needs implementation
    if (!textCursor().hasSelection() && (textCursor().blockNumber() == blockCount() - 1)){
        //# command up
        return true;
    }
    return CodeEditor::keyStrokeDown(event);
}

