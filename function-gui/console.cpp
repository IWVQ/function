#include "console.h"

const int SAVED_GUTTER_WIDTH = 2;

/* CmdHistory */

CmdHistory::CmdHistory()
{
    body = nullptr;
    savedcmd = "";
}

CmdHistory::~CmdHistory()
{
    clear();
}

void CmdHistory::clear()
{
    if (body) delete [] body;
    body = nullptr;
    current = 0;
    count = 0;
    savedcmd = "";
}

void CmdHistory::append(const QString &s)
{
    // new room
    QString *newbody = new QString[count + 1];
    for (int i = 0; i < count; i++)
        newbody[i] = body[i];
    if (body) delete[] body;
    body = newbody;
    // append
    body[count] = s;
    count++;
    current = count;
    savedcmd = "";
}

QString CmdHistory::prev(const QString &cmdhint)
{
    if (matchcmdhint){
        int curr = findPrevCmd(cmdhint);
        if (curr != -1) current = curr;
    } else {
        if (current == 0){
            if (wrap) current = count;
        }
        else current--;
    }

    if (current == count) return savedcmd;
    else return body[current];
}

QString CmdHistory::next(const QString &cmdhint)
{
    if (matchcmdhint){
        int curr = findNextCmd(cmdhint);
        if (curr != -1) current = curr;
    } else {
        if (current == count){
            if (wrap) current = 0;
        }
        else current ++;
    }

    if (current == count) return savedcmd;
    else return body[current];
}

bool CmdHistory::canGoPrev(const QString &cmdhint)
{
    if (count == 0) return false;

    if (matchcmdhint) return findPrevCmd(cmdhint) != -1;
    else if (wrap) return true;
    else return current > 0;
}

bool CmdHistory::canGoNext(const QString &cmdhint)
{
    if (count == 0) return false;

    if (matchcmdhint) return findNextCmd(cmdhint) != -1;
    else if (wrap) return true;
    else return current < count;
}

void CmdHistory::save(const QString &cmd)
{
    savedcmd = cmd;
}

int CmdHistory::findPrevCmd(const QString &cmdhint)
{
    if (count == 0) return -1;
    int curr = current;

    while (curr > 0){
        curr--;
        if (cmdhint == "") return curr;
        else if (body[curr].startsWith(cmdhint)) return curr;
    }
    if (wrap && current < count) return count;
    return -1;
}

int CmdHistory::findNextCmd(const QString &cmdhint)
{
    if (count == 0) return -1;
    int curr = current;

    if (curr == count) { if (wrap) curr = 0; }
    else curr++;
    while (curr < count){
        if (cmdhint == "") return curr;
        else if (body[curr].startsWith(cmdhint)) return curr;
        curr++;
    }
    if (current < count) return count;
    return -1;
}

/* Console */

Console::Console(QWidget *parent)
    : CodeEditor(parent)
{
    commandhistory = new CmdHistory();
    showsavestatusgutter = false;
    gutter->setMargins(3, 0);
    consolehighlighter = new ConsoleHighlighter();
    setHighlighter(consolehighlighter);

    shell = new Shell(this);
    shell->console = this;
    setRightEdgeStyle(CodeEditor::EDGE_NONE);
}

Console::~Console()
{
    shell = nullptr;
    delete commandhistory;
    delete consolehighlighter;
}


bool Console::loadFromFile(const QString &filename)
{
    if (shell){
        if (shell->loadFromFile(filename)){
            /*
            highlighter->newlinestyle = 0;
            setPlainText(text);
            for (int i = 0; i < document()->blockCount(); i++){
                QTextBlock block = document()->findBlockByNumber(i);
                TextBlockData *data = static_cast<TextBlockData *>(block.userData());
                if (data != nullptr) data->style = styles[i];
            }
            highlighter->rehighlight();
            */
            makePure();
            setProtectedTo(documentLength() + 1);
            return true;
        }
    }
    return CodeEditor::loadFromFile(filename);
}

bool Console::saveToFile(const QString &filename)
{
    if (shell){
        if (shell->saveToFile(filename)){
            makeSaved();
            return true;
        }
    }
    return CodeEditor::saveToFile(filename);
}

int Console::gutterWidth()
{
    if (numbering == NUMBERING_NONE || (!shell) || (!shell->embeddedprompter)){
        if (showsavestatusgutter) return SAVED_GUTTER_WIDTH;
        else return 0;
    }

    int delta = 0;
    if (gutter) delta = gutter->leftMargin() + gutter->rightMargin();
    int width = QFontMetrics(currentCharFormat().font()).horizontalAdvance(shell->arrowPrompter()) +
                delta; // prompter must be of the same length
    if (showsavestatusgutter && width < SAVED_GUTTER_WIDTH) width = SAVED_GUTTER_WIDTH;
    return width;
}

QString Console::gutterLineString(int i)
{
    QTextBlock block = document()->findBlockByNumber(i);
    TextBlockData *data = static_cast<TextBlockData *>(block.userData());
    if (data && shell && shell->embeddedprompter){
        if ((data->cell & CELL_INPUT) && (data->cell & CELL_PROMPTER))
            return shell->arrowPrompter();
        else if (data->cell & CELL_INPUT)
            return shell->spacePrompter();
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
    return (selstart < protectedto || selend < protectedto);
}

bool Console::checkProtectedTo(QKeyEvent *event)
{
    int selstart = textCursor().selectionStart();
    int selend =  textCursor().selectionEnd();
    bool inprotectedarea = (selstart < protectedto || selend < protectedto);

    if  ( (event == QKeySequence::Backspace)
             ||(event->key() == Qt::Key_Backspace)
             ){
        if (inprotectedarea) return true;
        else if (selstart - 1 < protectedto || selend - 1 < protectedto)
            if (!textCursor().hasSelection())
                return true; // avoid delete back if caret at protectedto
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
    if (checkProtectedTo(event))
        return; // skip

    if (event->key() == Qt::Key_Home){
        int readingline = blockFromPosition(protectedto).blockNumber();
        if (textCursor().blockNumber() == readingline){
            gotoPosition(readingPos());
            return;
        }
    }
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
    if (caret < protectedto) // caret == -1 too
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

bool Console::canTab(int newpos, bool back)
{
    if (back)
        return newpos >= protectedto;
    else
        return CodeEditor::canTab(newpos);
}

ConsoleHighlighter *Console::consoleHighlighter()
{
    Highlighter *h = CodeEditor::theHighlighter();
    return qobject_cast<ConsoleHighlighter *>(h);
}

void Console::lineOperation(int i, LineOperation o)
{
    if (i < 0 || i >= blockCount()) return;
    if (o == MOVE_UP_LINE){
        if (i == 0) return ;
        QTextBlock block = document()->findBlockByNumber(i - 1);
        if (block.position() < protectedto) return;
    }
    else if (o == MOVE_DOWN_LINE){
        QTextBlock block = document()->findBlockByNumber(i);
        if (block.position() < protectedto) return;
    }
    else if (o == DUPLICATE_LINE){
        QTextBlock block = document()->findBlockByNumber(i);
        if (block.position() < protectedto) return;
    }
    else if (o == JOIN_LINES){
        int start = textCursor().selectionStart();
        QTextBlock block = blockFromPosition(start);
        if (block.position() < protectedto) return;
    }
    else return;
    CodeEditor::lineOperation(i, o);
}

bool Console::keyStrokeTab(bool back, QKeyEvent *event)
{
    if (textCursor().hasSelection()){
        int start = textCursor().selectionStart();
        QTextBlock block = blockFromPosition(start);
        int firstpos = block.position();
        if (firstpos < protectedto)
            return true;
    }
    return CodeEditor::keyStrokeTab(back, event);
}

bool Console::keyStrokeReturn(QKeyEvent *event)
{
    if (!selectionInProtectedArea()){
        // in edition area
        if (shell)
            if (shell->canRead(event)){
                endRead(readingStr());
                return true;
            }
    }
    return CodeEditor::keyStrokeReturn(event);
}

bool Console::keyStrokeUp(QKeyEvent *event)
{
    if (canCursorGoPrevCmd()){
        if (commandhistory->savewrittencmd && commandhistory->onTop())
            commandhistory->save(readingStr());
        prevCmd();
        return true;
    }
    return CodeEditor::keyStrokeUp(event);
}

bool Console::keyStrokeDown(QKeyEvent *event)
{
    if (canCursorGoNextCmd()){
        if (commandhistory->savewrittencmd && commandhistory->onTop())
            commandhistory->save(readingStr());
        nextCmd();
        return true;
    }
    return CodeEditor::keyStrokeDown(event);
}


bool Console::embeddedPrompter()
{
    if (shell) return shell->embeddedprompter;
    else return false;
}

void Console::setEmbeddedPrompter(bool b)
{
    if (shell){
        if (shell->embeddedprompter != b){
            shell->embeddedprompter = b;
            updateGeometry();
            //# needs settings
        }
    }
}

void Console::selectReadingStr()
{
    QTextCursor cursor = textCursor();
    cursor.setPosition(documentLength());
    cursor.setPosition(readingPos(), QTextCursor::KeepAnchor);
    setTextCursor(cursor);
}

void Console::replaceReadingStr(const QString &s)
{
    QTextCursor cursor = textCursor();
    cursor.setPosition(readingPos());
    cursor.setPosition(documentLength(), QTextCursor::KeepAnchor);
    setTextCursor(cursor);
    textCursor().insertText(s);
}

QString Console::readingStr()
{
    QTextCursor cursor = textCursor();
    cursor.setPosition(readingPos());
    cursor.setPosition(documentLength(), QTextCursor::KeepAnchor);
    return cursor.selectedText();
}

int Console::readingPos()
{
    return protectedTo();
}

// shell connecting

void Console::initialize()
{
    repaint();
    connect(shell, SIGNAL(message(int,qint64,qint64)), this, SLOT(onMessage(int,qint64,qint64)));
    shell->start(QThread::NormalPriority);
}

void Console::pause()
{
    shell->pause();
}

void Console::resume()
{
    shell->resume();
}

void Console::interrupt()
{
    shell->interrupt();
}

void Console::userClrScr()
{
    // clears the console except for input cell
    if (shell){
        if (shell->isRunning() && !shell->isEvaluating() && shell->isReading()){
            // just reading input
            QTextBlock block = document()->findBlockByNumber(currentcellline);
            if (block.isValid()){
                int newprotectpos = protectedTo() - block.position();
                QTextCursor c = textCursor();
                c.setPosition(0);
                c.setPosition(block.position(), QTextCursor::KeepAnchor);
                c.removeSelectedText();
                c.setPosition(documentLength());
                setTextCursor(c);
                setProtectedTo(newprotectpos);
                currentcellline = 0;
                // cache
                consoleHighlighter()->currentcellline = 0;
            }
        }
    }
}

void Console::newCell(int cell, bool newline)
{
    QTextBlock block;
    TextBlockData *data;
    ConsoleHighlighter *h = consoleHighlighter();
    if (newline) write("\n");

    // fill old cell
    int line = currentcellline + 1; // if currentcellindex = -1 then line = 0
    int last = blockCount() - 1;
    while(line < last){
        block = document()->findBlockByNumber(line);
        data = static_cast<TextBlockData *>(block.userData());

        if (data)
            data->cell = currentcelltype;
        else
            block.setUserData(h->createBlockData(block.text(), currentcelltype));
        line++;
    }

    // new cell
    currentcelltype = cell;
    currentcellline = last;
    int headercelltype = currentcelltype | CELL_HEADER;
    block = document()->lastBlock();
    data = static_cast<TextBlockData *>(block.userData());
    if (data)
        data->cell = headercelltype;
    else
        block.setUserData(h->createBlockData(block.text(), headercelltype));
    protectAll();
    // cache
    h->currentcellline = last;
    h->currentcelltype = cell;
}

void Console::beginRead(const QString &s)
{
    write(s);
    setProtectedTo(documentLength());
    reading = true;
}

void Console::endRead(const QString &input)
{
    commandhistory->append(input);
    write("\n");
    protectAll();
    repaint(); //#
    reading = false;
    response(SHELL_READ, reinterpret_cast<qint64>(&input), 0);
}

void Console::write(const QString &s)
{
    QTextCursor cursor = textCursor();
    cursor.setPosition(documentLength());
    setTextCursor(cursor);
    if (s != "") insertPlainText(s);
    setProtectedTo(documentLength() + 1);
    // repaint(); //# not safe
}

void Console::clrscr(int from)
{
    if (from < 0 || from >= blockCount()) return;

    if (from == 0){
        clear();
        protectAll();
        // no problem with cell
    }
    else{
        QTextBlock block = document()->findBlockByNumber(from);
        QTextCursor c = textCursor();
        c.setPosition(block.position());
        c.setPosition(documentLength(), QTextCursor::KeepAnchor);
        setTextCursor(c);
        textCursor().removeSelectedText();
        protectAll();
        // no problem with cell
    }
}

void Console::response(int m, qint64 l, qint64 r)
{
    if (shell) shell->response(m, l, r);
}

void Console::onMessage(int m, qint64 l, qint64 r)
{
    if (m == SHELL_READ      ){
        beginRead();
    }
    else if (m == SHELL_WRITE     ){
        QString *s = reinterpret_cast<QString *>(l);
        write(*s);
        repaint(); //#
        response(m, 0, 0);
    }
    else if (m == SHELL_FORMAT    ){
        QTextCharFormat *f = reinterpret_cast<QTextCharFormat *>(l);
        setCurrentCharFormat(*f);
        response(m, 0, 0);
    }
    else if (m == SHELL_CELL      ){
        bool b = static_cast<bool>(r);
        newCell(l, b);
        response(m, 0, 0);
    }
    else if (m == SHELL_CLRSCR    ){
        clrscr(l);
        repaint();
        response(m, 0, 0);
    }
    else if (m == SHELL_WHEREXY   ){
        bool b = static_cast<bool>(r);
        QPoint p;
        if (b)
            p = endXY();
        else
            p = whereXY();
        response(m, p.x(), p.y());
    }
    else if (m == SHELL_EVALUATING){
        emit evaluating(true);
        response(m, 0, 0);
    }
    else if (m == SHELL_EVALUATED ){
        emit evaluating(false);
        response(m, 0, 0);
    }
    else if (m == SHELL_EXIT){
        qDebug("QPointer<Console> guard(this)#############");
        QPointer<Console> guard(this);
        qDebug("emit exiting();############");
        emit exiting();
        qDebug("if (guard)############");
        if (guard) // not closed so continue running
            response(m, 0, 0);
    }
    else if (m == SHELL_STARTED){
        emit started();
        response(m, 0, 0);
    }
}


bool Console::isEvaluating()
{
    return shell->isEvaluating();
}

bool Console::isPaused()
{
    return shell->isPaused();
}


//

int Console::protectedTo()
{
    return protectedto;
}

void Console::setProtectedTo(int t)
{
    if (t < 0) t = 0;

    if (t < protectedto){
        protectedto = t;
    }
    else if (t > protectedto){
        protectedto = t;
        document()->clearUndoRedoStacks();
    }
}

void Console::protectAll()
{
    setProtectedTo(documentLength() + 1);
    if (currentcellline >= blockCount()) currentcellline = blockCount();
}

QString Console::commandHint()
{
    if (!commandhistory->matchcmdhint) return "";

    QTextCursor cursor = textCursor();
    cursor.setPosition(readingPos());
    cursor.setPosition(textCursor().position(), QTextCursor::KeepAnchor);
    return cursor.selectedText();
}

void Console::replaceByHistory(const QString &s)
{
    int currentpos = textCursor().position();
    replaceReadingStr(s);
    QTextCursor cursor = textCursor();
    cursor.setPosition(qMin(currentpos, documentLength()));
    setTextCursor(cursor);
}

void Console::prevCmd()
{
    if (canGoPrevCmd()){
        replaceByHistory(commandhistory->prev(commandHint()));
    }
}

void Console::nextCmd()
{
    if (canGoNextCmd()){
        replaceByHistory(commandhistory->next(commandHint()));
    }
}

bool Console::canGoPrevCmd()
{
    return (reading && commandhistory->canGoPrev(commandHint()));
}

bool Console::canGoNextCmd()
{
    return (reading && commandhistory->canGoNext(commandHint()));
}

bool Console::canCursorGoPrevCmd()
{
    int readingline = blockFromPosition(protectedto).blockNumber();
    return !textCursor().hasSelection()
           && (textCursor().position() >= readingPos())
           && (textCursor().blockNumber() == readingline);
}

bool Console::canCursorGoNextCmd()
{
    int lastreadingline = document()->blockCount() - 1;
    return !textCursor().hasSelection()
           && (textCursor().position() >= readingPos())
           && (textCursor().blockNumber() == lastreadingline);
}

