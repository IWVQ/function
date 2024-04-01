#include "codeeditor.h"

char braceOpposite(char c)
{
    if (c == '(') return ')';
    if (c == '[') return ']';
    if (c == '{') return '}';

    if (c == ')') return '(';
    if (c == ']') return '[';
    if (c == '}') return '{';

    return c;
}

const int SAVED_GUTTER_WIDTH = 2;

/* Gutter */

GutterArea::GutterArea(QWidget *parent)
    : QWidget(parent)
{
    setMouseTracking(true);
    //setFocusPolicy(Qt::WheelFocus);
}

GutterArea::~GutterArea()
{

}

QSize GutterArea::sizeHint() const
{
    if (editor)
        return QSize(editor->gutterWidth(), 0);
    else
        return QSize(0, 0);
}

void GutterArea::setMargins(int aleft, int aright)
{
    if (aleft != leftmargin || aright != rightmargin){
        leftmargin = aleft;
        rightmargin = aright;
        if (editor) editor->updateGeometry();
    }
}

void GutterArea::paintEvent(QPaintEvent *event)
{
    if (editor)
        editor->gutterPaintEvent(event);
}

void GutterArea::mousePressEvent(QMouseEvent *event)
{
    QPoint p = event->pos();
    selanchorline = -1;
    if ((Qt::LeftButton & event->buttons()) == Qt::LeftButton){
        int xright = width();
        if (editor->showsavestatusgutter) xright -= SAVED_GUTTER_WIDTH;
        if (p.x() < xright){
            selanchorline = editor->lineFromPoint(p);
            editor->selectLines(selanchorline, selanchorline);
        }
    }
    QWidget::mousePressEvent(event);
}

void GutterArea::mouseMoveEvent(QMouseEvent *event)
{
    QPoint p = event->pos();
    if ((Qt::LeftButton & event->buttons()) == Qt::LeftButton && (selanchorline =! -1)){
        int selcaretline = editor->lineFromPoint(p, selanchorline);
        editor->selectLines(selanchorline, selcaretline);
    }
    QWidget::mouseMoveEvent(event);
}

void GutterArea::mouseReleaseEvent(QMouseEvent *event)
{
    selanchorline = -1;
    QWidget::mouseReleaseEvent(event);
}

void GutterArea::wheelEvent(QWheelEvent *event)
{
    if (editor)
        editor->doWheelEvent(event);
    else
        QWidget::wheelEvent(event);
}

/* CodeEditor */

CodeEditor::CodeEditor(QWidget *parent)
    : QPlainTextEdit(parent)
{
    setMouseTracking(true);
    gutter = new GutterArea(this);
    gutter->editor = this;

    highlighter = new FXHighlighter(this->document());

    connect(this, SIGNAL(cursorPositionChanged()), this, SLOT(onCursorPositionChanged()));
    connect(this, SIGNAL(updateRequest(QRect, int)), this, SLOT(onUpdateRequest(QRect, int)));
    connect(this, SIGNAL(blockCountChanged(int)), this, SLOT(onBlockCountChanged(int)));
    connect(this, SIGNAL(selectionChanged()), this, SLOT(onSelectionChanged()));
    connect(this, SIGNAL(undoAvailable(bool)), this, SLOT(onUndoAvailable(bool)));
    connect(this, SIGNAL(redoAvailable(bool)), this, SLOT(onRedoAvailable(bool)));

    updateGutterGeometry();
    updateExtraSelections(); // colourises current line


    // font initialization

    QFont font;
    font.setFamily("Courier New");
    font.setBold(false);
    font.setItalic(false);
    font.setUnderline(false);
    font.setStrikeOut(false);
    font.setPointSize(9);
    setFont(font);

    QTextCharFormat format = currentCharFormat();
    format.setFontFamily("Courier New"); // ! deprecated in qt
    format.setFontFixedPitch(true);
    setCurrentCharFormat(format);
    setLineWrapMode(QPlainTextEdit::NoWrap);

    // set inital tab size
    int spacewidth = QFontMetrics(currentCharFormat().font()).horizontalAdvance(' ');
#if QT_VERSION_MAJOR <= 5
    setTabStopWidth(tabsize*spacewidth);
#elif QT_VERSION_MAJOR == 6
    this->setTabStopDistance(tabsize*spacewidth);
#endif
    //



}

CodeEditor::~CodeEditor()
{
    //delete gutter;
    //delete highlighter;
}

int CodeEditor::gutterWidth()
{
    if (numbering == NUMBERING_NONE){
        if (showsavestatusgutter) return SAVED_GUTTER_WIDTH;
        else return 0;
    }

    int linescount = qMax(1, blockCount());
    int digits = floor(log10(linescount) + 1);
    int delta = 0;
    if (gutter) delta = gutter->leftMargin() + gutter->rightMargin();
    int width = QFontMetrics(currentCharFormat().font()).horizontalAdvance('9')*digits +
                delta;
    if (showsavestatusgutter && width < SAVED_GUTTER_WIDTH) width = SAVED_GUTTER_WIDTH;
    return width;
}

QString CodeEditor::gutterLineString(int i)
{
    int curr = textCursor().block().blockNumber() + 1;
    QString str = "";
    if ((numbering == NUMBERING_FULL) || (i == curr))
        str = QString::number(i);
    else if (numbering == NUMBERING_PARTIAL){
        if ((i == 1) || (i % 10 == 0))
            str = QString::number(i);
        else if (i % 10 == 5)
            str = "-";
        else
            str = "·"; // interpunct
    }
    return str;
}

void CodeEditor::gutterPaintEvent(QPaintEvent *event)
{
    if (!gutter || !highlighter) return;

    QPainter painter(gutter);
    QTextCharFormat format = highlighter->markers[MARKER_GUTTER];
    QTextCharFormat currformat = highlighter->markers[MARKER_CURRENT_GUTTER];
    painter.fillRect(event->rect(), format.background());

    if (numbering == NUMBERING_NONE) return;

    QTextBlock block = firstVisibleBlock();
    int top = qRound(blockBoundingGeometry(block).translated(contentOffset()).top());
    int bottom = top + qRound(blockBoundingRect(block).height());
    int i = block.blockNumber() + 1;
    int curr = textCursor().block().blockNumber() + 1;

    while (block.isValid() && top <= event->rect().bottom()){ //! rect().bottom()
        if (block.isVisible() && bottom >= event->rect().top()) {
            QString str = gutterLineString(i);

            if (i == curr){
                QRect currrect(0, top, gutter->width(), bottom);
                painter.fillRect(currrect, currformat.background());
                painter.setFont(currformat.font());
                painter.setPen(currformat.foreground().color());
            }
            else{
                painter.setFont(format.font());
                painter.setPen(format.foreground().color());
            }
            painter.drawText(0, top, gutter->width() - gutter->rightMargin(), fontMetrics().height(),
                             Qt::AlignRight, str);

            TextBlockData *data = static_cast<TextBlockData *>(block.userData());
            if (data != nullptr && data->status != LINE_STATUS_PURE){
                if (showsavestatusgutter){
                    QRect markrect = QRect(gutter->width() - SAVED_GUTTER_WIDTH, top, gutter->width(), bottom - top);
                    if (data->status == LINE_STATUS_MODIFIED)
                        painter.fillRect(markrect, highlighter->modifiedstatuscolor);
                    else if (data->status == LINE_STATUS_SAVED)
                        painter.fillRect(markrect, highlighter->savedstatuscolor);
                }
            }
        }

        block = block.next();
        top = bottom;
        bottom = top + qRound(blockBoundingRect(block).height());
        i++;
    }
}

void CodeEditor::colouriseBraces(QList<QTextEdit::ExtraSelection> *selections)
{
    if (!highlighter) return;
    if (braces[0] == -1) return;
    if (braces[1] == -1) return;

    if (braces[0] > braces[1]){ // sort
        int aux = braces[0];
        braces[0] = braces[1];
        braces[1] = aux;
    }

    QTextEdit::ExtraSelection selection;
    QTextCursor cursor = textCursor();

    selection.format = highlighter->bracesformat;

    cursor.setPosition(braces[0]);
    cursor.movePosition(QTextCursor::NextCharacter, QTextCursor::KeepAnchor);
    selection.cursor = cursor;
    selections->append(selection);

    cursor.setPosition(braces[1]);
    cursor.movePosition(QTextCursor::NextCharacter, QTextCursor::KeepAnchor);
    selection.cursor = cursor;
    selections->append(selection);
}

void CodeEditor::matchBraces()
{
    braces[0] = -1;
    braces[1] = -1;
    if (!bracematching) return;

    QTextBlock block = textCursor().block();
    if (!block.isValid()) return;
    TextBlockData *data = static_cast<TextBlockData *>(block.userData());
    if (data == nullptr) return;
    int i = data->find(textCursor().position() - block.position());



    if (i != -1){ // at brace char
        int braceposition = data->braces.at(i).pos + block.position();
        char brace = data->braces.at(i).ch;
        char opposite = braceOpposite(brace);
        bool foreward = isOpenBrace(brace);
        int depth = 1;
        if (foreward) i++;
        else i--;

        while (block.isValid()){

            // search the opposite in block
            if (foreward){
                while (i < data->braces.size()){
                    if (data->braces[i].ch == opposite){
                        depth--;
                        if (depth == 0){
                            braces[0] = braceposition;
                            braces[1] = data->braces[i].pos + block.position();
                            return;
                        }
                    }
                    else if (data->braces[i].ch == brace)
                        depth++;
                    i++;
                }

                block = block.next();
                if (!block.isValid()) return;
                data = static_cast<TextBlockData *>(block.userData());
                if (data == nullptr) return;
                i = 0;
            } // foreward
            else{
                while (i >= 0){
                    if (data->braces[i].ch == opposite){
                        depth--;
                        if (depth == 0){
                            braces[0] = braceposition;
                            braces[1] = data->braces[i].pos + block.position();
                            return;
                        }
                    }
                    else if (data->braces[i].ch == brace)
                        depth++;
                    i--;
                }

                block = block.previous();
                if (!block.isValid()) return;
                data = static_cast<TextBlockData *>(block.userData());
                if (data == nullptr) return;
                i = data->braces.size() - 1;
            } // backward
        } // while
    } // if
}

void CodeEditor::updateGutterGeometry()
{
    setViewportMargins(gutterWidth(), 0, 0, 0);
}

void CodeEditor::updateGutterLine(int line)
{
    QTextBlock block = document()->findBlockByNumber(line);
    int top = qRound(blockBoundingGeometry(block).translated(contentOffset()).top());
    int height = qRound(blockBoundingRect(block).height());
    gutter->update(0, top, gutter->width(), height);
}

void CodeEditor::colouriseCurrentLine(QList<QTextEdit::ExtraSelection> *selections)
{
    if (!highlighter) return;

    QTextEdit::ExtraSelection selection;

    selection.format.setBackground(highlighter->markers[MARKER_CURRENT_LINE].background());
    selection.format.setProperty(QTextFormat::FullWidthSelection, true);
    selection.cursor = textCursor();
    selection.cursor.clearSelection();

    // update gutter rects when current line changed
    if (currentline != textCursor().blockNumber()){
        updateGutterLine(currentline);
        currentline = textCursor().blockNumber();
        updateGutterLine(currentline);
    }

    selections->append(selection);
}

void CodeEditor::drawRightEdge(QPaintEvent *event)
{
    if (!highlighter) return;
    if (edge == EDGE_NONE) return;

    QRect rect = event->rect();
    QFont font = highlighter->defaultformat.font();
    int xedge = qRound(QFontMetricsF(font).averageCharWidth()*rightedge) +
                contentOffset().x() +
                document()->documentMargin();
    QPainter painter(viewport());

    painter.setPen(highlighter->rightedgecolor);

    if (rect.left() <= xedge && xedge <= rect.right()){
        if (edge == EDGE_FULL)
            painter.drawLine(xedge, rect.top(), xedge, rect.bottom()); //? rect.bottom
        else if (edge == EDGE_PARTIAL){
            int bottom = qRound(blockBoundingRect(document()->lastBlock()).bottom());
            if (bottom > rect.bottom()) bottom = rect.bottom(); //? rect.bottom
            if (bottom >= rect.top())
                painter.drawLine(xedge, rect.top(), xedge, bottom);
        }
    }
}

void CodeEditor::updateExtraSelections()
{
    //
    QList<QTextEdit::ExtraSelection> selections;
    // current line
    colouriseCurrentLine(&selections);
    // match braces
    matchBraces();
    colouriseBraces(&selections);
    // extra selections
    setExtraSelections(selections);
    // coords

    // delimiter autocompletion
    if (braces[0] == delimiterautocompletionpos && braces[1] == textCursor().position()){
        // do nothing
    }
    else
        delimiterautocompletionpos = -1;
}

void CodeEditor::onCursorPositionChanged()
{
    updateExtraSelections();
}

void CodeEditor::onUndoAvailable(bool b)
{
    canundo = b;
}

void CodeEditor::onRedoAvailable(bool b)
{
    canredo = b;
}

void CodeEditor::onUpdateRequest(const QRect &rect, int dy)
{
    if (!gutter) return;

    if (dy)
        gutter->scroll(0, dy);
    else
        gutter->update(0, rect.y(), gutter->width(), rect.height());

    if (rect.contains(viewport()->rect()))
        updateGutterGeometry();
}

void CodeEditor::onBlockCountChanged(int)
{
    updateGutterGeometry();
}

void CodeEditor::onSelectionChanged()
{}

QTextBlock CodeEditor::blockFromPosition(int pos)
{
    return document()->findBlock(pos);
}

bool CodeEditor::canTab(int, bool)
{
    return true;
}

void CodeEditor::lineOperation(int i, LineOperation o)
{
    int l = blockCount();
    if (i < 0 || i >= l) return;
    int caretcol = textCursor().position() - textCursor().block().position();
    QTextCursor cursor = textCursor();
    int eollen = 1; //#

    if (o == MOVE_UP_LINE){
        if (i == 0) return ;

        QTextBlock blocku = document()->findBlockByNumber(i - 1);
        QTextBlock blockc = document()->findBlockByNumber(i);

        int firstpos = blocku.position();
        int lastpos = blockc.position() + blockc.length();

        cursor.setPosition(firstpos);
        cursor.setPosition(lastpos - eollen, QTextCursor::KeepAnchor);
        setTextCursor(cursor);
        QString str = blockc.text() + "\n" + blocku.text();
        textCursor().insertText(str);

        cursor.setPosition(caretcol + firstpos);
        setTextCursor(cursor);
    }
    else if (o == MOVE_DOWN_LINE){
        if (i == l - 1) return ;

        QTextBlock blockc = document()->findBlockByNumber(i);
        QTextBlock blockd = document()->findBlockByNumber(i + 1);

        int firstpos = blockc.position();
        int secondpos = blockd.position();
        int secondlen = blockd.length();
        int lastpos = secondpos + blockd.length();

        cursor.setPosition(firstpos);
        cursor.setPosition(lastpos - eollen, QTextCursor::KeepAnchor);
        setTextCursor(cursor);
        QString str = blockd.text() + "\n" + blockc.text();
        textCursor().insertText(str);

        cursor.setPosition(caretcol + firstpos + secondlen);
        setTextCursor(cursor);
    }
    else if (o == DUPLICATE_LINE){
        QTextBlock blockc = document()->findBlockByNumber(i);

        int firstpos = blockc.position();
        int lastpos = firstpos + blockc.length();

        cursor.setPosition(firstpos);
        cursor.setPosition(lastpos - eollen, QTextCursor::KeepAnchor);
        setTextCursor(cursor);
        QString str = blockc.text() + "\n" + blockc.text();
        textCursor().insertText(str);

        cursor.setPosition(caretcol + firstpos);
        setTextCursor(cursor);
    }
    else if (o == JOIN_LINES){
        if (!textCursor().hasSelection()) return;

        int caret = textCursor().position();
        int caretcol = caret - textCursor().block().position();
        int start = textCursor().selectionStart();
        int end = textCursor().selectionEnd();

        QTextBlock block = blockFromPosition(start);
        int firstpos = block.position();
        int lastpos = firstpos;

        QString str = "";
        while (block.isValid() && block.position() < end){
            str.append(block.text());
            lastpos += block.length();
            block = block.next();
        }

        QTextCursor cursor = textCursor();
        cursor.setPosition(firstpos);
        cursor.setPosition(lastpos - eollen, QTextCursor::KeepAnchor);
        setTextCursor(cursor);
        textCursor().insertText(str);

        if (caret == start){}
        else caret = firstpos + textCursor().block().length() -
                     (lastpos - caret);
        cursor.setPosition(caret);
        setTextCursor(cursor);
    }
}

bool CodeEditor::keyStrokeTab(bool back, QKeyEvent *event)
{
    if (textCursor().hasSelection()){
        QString tabstr = "\t";
        if (tabtospaces) tabstr = QString(" ").repeated(tabsize);
        // increase indent
        int anchor = textCursor().anchor();
        int caret = textCursor().position();
        int start = textCursor().selectionStart();
        int end = textCursor().selectionEnd();

        QTextBlock block = blockFromPosition(start);
        int firstpos = block.position();
        int lastpos = firstpos;

        QString str = "";
        while (block.isValid() && block.position() < end){
            if (back){
                QString txt = block.text();
                int col = 0;
                for (int i = 0; i < txt.length(); i++){
                    if (txt[i] == ' ')
                        col++;
                    else if (txt[i] == '\t')
                        col += tabsize - (col % tabsize);
                    else
                        break;
                    if (col >= tabsize) break;
                }
                str.append(txt.remove(0, col));
            }
            else{
                str.append(tabstr);
                str.append(block.text());
            }
            str.append("\n");

            lastpos += block.length();
            block = block.next();
        }

        QTextCursor cursor = textCursor();
        cursor.setPosition(firstpos);
        cursor.setPosition(lastpos, QTextCursor::KeepAnchor);
        setTextCursor(cursor);

        QKeyEvent tabevent(QKeyEvent::KeyPress, Qt::Key_Tab,
                           Qt::KeyboardModifiers(event->nativeModifiers()), str);
        QPlainTextEdit::keyPressEvent(&tabevent);

        lastpos = textCursor().position();
        if (caret < anchor){
            cursor.setPosition(lastpos);
            cursor.setPosition(firstpos, QTextCursor::KeepAnchor);
            setTextCursor(cursor);
        }
        else{
            cursor.setPosition(firstpos);
            cursor.setPosition(lastpos, QTextCursor::KeepAnchor);
            setTextCursor(cursor);
        }

        return true;
    }
    else if (back){
        QString linestr = textCursor().block().text();
        int caret = textCursor().position() - textCursor().block().position();

        int col = 0;
        int i = 0;
        while (i < linestr.length() && isSpaceChar(linestr[i])){
            if (linestr[i] == '\t')
                col += (tabsize - col % tabsize);
            else
                col++;
            i++;
        }
        if (caret <= i){
            QTextCursor cursor = textCursor();
            cursor.setPosition(i + textCursor().block().position());
            while (i > 0){
                i--;
                if (linestr[i] == '\t')
                    col -= (tabsize - col % tabsize);
                else
                    col--;
                if (col % tabsize == 0) break;
            }
            int newcaretpos = i + textCursor().block().position();
            if (canTab(newcaretpos, true)){
                cursor.setPosition(newcaretpos, QTextCursor::KeepAnchor);
                setTextCursor(cursor);
                textCursor().removeSelectedText();
            }
        }
        return true;
    }
    else if (tabtospaces){
        QString linestr = textCursor().block().text();
        QString str = "";
        int firstpos = textCursor().block().position();
        int caret = textCursor().position() - firstpos;

        int col = 0;
        for (int i = 0; i < linestr.length(); i++){
            if (i == caret)
                break;
            else if (linestr[i] == '\t')
                col += (tabsize - col % tabsize);
            else
                col++;
        }
        str = QString(" ").repeated(tabsize - col % tabsize);
        int newcaretpos = caret + str.length() + firstpos;
        if (canTab(newcaretpos)){
            QKeyEvent tabevent(QKeyEvent::KeyPress, Qt::Key_Tab,
                               Qt::KeyboardModifiers(event->nativeModifiers()), str);
            QPlainTextEdit::keyPressEvent(&tabevent);
        }
        return true;
    }
    else{
        int firstpos = textCursor().block().position();
        int caret = textCursor().position() - firstpos;
        int newcaretpos = caret + firstpos + 1;
        if (!canTab(newcaretpos)) return true;
    }
    return false;
}

bool CodeEditor::keyStrokeReturn(QKeyEvent *event)
{
    if (autoindent){
        QString linestr = textCursor().block().text();
        QString str = "";
        if (tabtospaces){
            int spaces = 0;
            spaces = 0;
            for (int i = 0; i < linestr.length(); i++){
                if (linestr[i] == ' ')
                    spaces++;
                else if (linestr[i] == '\t')
                    spaces += (tabsize - spaces % tabsize);
                else
                    break;
            }
            str = QString(" ").repeated(spaces);
        }
        else
            for (int i = 0; i < linestr.length(); i++)
                if (!isSpaceChar(linestr[i])){
                    str = linestr.mid(0, i);
                    break;
                }
        QPlainTextEdit::keyPressEvent(event);
        insertPlainText(str);
        return true;
    }
    return false;
}

bool CodeEditor::keyStrokeUp(QKeyEvent *)
{
    return false;
}

bool CodeEditor::keyStrokeDown(QKeyEvent *)
{
    return false;
}

bool CodeEditor::autoCompleteDelimiter(QKeyEvent *event, char c)
{
    delimiterautocompletionpos = -1;
    if (autocompletedelimiter){
        QString linestr = textCursor().block().text();
        int i = textCursor().position() - textCursor().block().position();
        if ((i == linestr.length()) ||
            isSpaceChar(linestr[i]) ||
            isCloseBrace(linestr[i].toLatin1()) ||
            isEoLChar(linestr[i])){
            int thepos = textCursor().position();

            QString str;
            str.append(c);
            str.append(braceOpposite(c));
            QKeyEvent kevent(QKeyEvent::KeyPress, event->key(),
                             Qt::KeyboardModifiers(event->nativeModifiers()),
                             str);
            QPlainTextEdit::keyPressEvent(&kevent);

            QTextCursor cursor = textCursor();
            cursor.setPosition(textCursor().position() - 1);
            setTextCursor(cursor);

            delimiterautocompletionpos = thepos;
            return true;
        }
    }
    return false;
}

bool CodeEditor::autoCompleteDelimiterDone(QKeyEvent *)
{
    if (autocompletedelimiter){
        if (delimiterautocompletionpos != -1 &&
            braces[0] == delimiterautocompletionpos &&
            braces[1] == textCursor().position()){
            delimiterautocompletionpos = -1;

            QTextCursor cursor = textCursor();
            cursor.setPosition(textCursor().position() + 1);
            setTextCursor(cursor);

            return true;
        }
    }
    delimiterautocompletionpos = -1;
    return false;
}

void CodeEditor::keyPressEvent(QKeyEvent *event)
{
    switch(event->key()){
    case Qt::Key_Backtab:
        if (keyStrokeTab(true, event))
            return;
        break;
    case Qt::Key_Tab:
        if (keyStrokeTab(false, event))
            return;
        break;
    case Qt::Key_Return:
        if (keyStrokeReturn(event))
            return;
        break;
    case Qt::Key_Up:
        if (keyStrokeUp(event))
            return;
        break;
    case Qt::Key_Down:
        if (keyStrokeDown(event))
            return;
        break;
    case Qt::Key_ParenLeft:
        if (autoCompleteDelimiter(event, '('))
            return;
        break;
    case Qt::Key_BraceLeft:
        if (autoCompleteDelimiter(event, '{'))
            return;
        break;
    case Qt::Key_BracketLeft:
        if (autoCompleteDelimiter(event, '['))
            return;
        break;
    case Qt::Key_ParenRight:
    case Qt::Key_BraceRight:
    case Qt::Key_BracketRight:
        if (autoCompleteDelimiterDone(event))
            return;
        break;
    case Qt::Key_Insert:
        setOverwriteMode(not overwriteMode());
        break;
    }
    QPlainTextEdit::keyPressEvent(event);
}

void CodeEditor::resizeEvent(QResizeEvent *event)
{
    QPlainTextEdit::resizeEvent(event);

    if (!gutter) return;

    QRect contentrect = contentsRect();
    gutter->setGeometry(QRect(contentrect.left(), contentrect.top(),
                              gutterWidth(), contentrect.height()));
}

void CodeEditor::paintEvent(QPaintEvent *event)
{
    QPlainTextEdit::paintEvent(event);
    if (highlighter)
        drawRightEdge(event);
}

void CodeEditor::doWheelEvent(QWheelEvent *event)
{
    QPlainTextEdit::wheelEvent(event);
}

int CodeEditor::lineFromPoint(QPoint p, int from)
{
    QTextBlock block;
    if (from == -1) block = firstVisibleBlock();
    else block = document()->findBlockByNumber(from);

    if (!block.isValid()) return -1;

    int top = qRound(blockBoundingGeometry(block).translated(contentOffset()).top());

    if (p.y() < top){
        // search backward
        while(p.y() < top){
            block = block.previous();
            if (block.isValid())
                top = qRound(blockBoundingGeometry(block).translated(contentOffset()).top());
            else
                break;
        }
        if (block.isValid())
            return block.blockNumber();
    }
    else {
        // search foreward
        int bottom = top + qRound(blockBoundingRect(block).height());
        while (p.y() >= bottom){
            block = block.next();
            if (block.isValid())
                top = qRound(blockBoundingGeometry(block).translated(contentOffset()).top());
            else
                break;
            bottom = top + qRound(blockBoundingRect(block).height());
        }
        if (block.isValid())
            return block.blockNumber();
    }
    return -1;
}

void CodeEditor::selectLines(int anchorline, int caretline)
{
    if (!(caretline >= 0 && caretline < document()->blockCount() &&
          anchorline >= 0 && anchorline < document()->blockCount()))
        return;

    int anchorpos, caretpos;
    if (caretline < anchorline){
        QTextBlock block = document()->findBlockByNumber(anchorline);
        anchorpos = block.position() + block.length();
        block = document()->findBlockByNumber(caretline);
        caretpos = block.position();
    }
    else{
        QTextBlock block = document()->findBlockByNumber(anchorline);
        anchorpos = block.position();
        block = document()->findBlockByNumber(caretline);
        caretpos = block.position() + block.length();
    }

    QTextCursor cursor = textCursor();
    cursor.setPosition(anchorpos);
    cursor.setPosition(caretpos, QTextCursor::KeepAnchor);
    setTextCursor(cursor);
}

void CodeEditor::gotoPosition(int p)
{
    QTextCursor cursor = textCursor();
    // if (p < 0) p = 0;
    // if (p > documentLength()) p = documentLength();
    cursor.setPosition(p);
    setTextCursor(cursor);
}

void CodeEditor::gotoXY(int x, int y)
{
    QTextBlock block = document()->findBlockByNumber(y);
    if (block.isValid()){
        int eollen = 1;
        int p = x + block.position();
        int l = block.position() + block.length() - eollen;
        if (p > l) p = l;
        QTextCursor cursor = textCursor();
        cursor.setPosition(p);
        setTextCursor(cursor);
    }
}

QPoint CodeEditor::whereXY()
{
    int y = textCursor().blockNumber();
    int x = textCursor().position() - textCursor().block().position();
    return QPoint{x, y};
}

QPoint CodeEditor::endXY()
{
    int y = document()->lastBlock().blockNumber();
    int x = documentLength() - document()->lastBlock().position();
    return QPoint{x, y};
}

int CodeEditor::documentLength()
{
    QTextBlock block = document()->lastBlock();
    int eollen = 1;
    return block.position() + block.length() - eollen;
}

void CodeEditor::modified(bool m)
{
    document()->setModified(m);
}

void CodeEditor::makeSaved()
{
    QTextBlock block = document()->firstBlock();
    while(block.isValid()){
        TextBlockData *data = static_cast<TextBlockData *>(block.userData());
        if (data != nullptr)
            if (data->status == LINE_STATUS_MODIFIED)
                data->status = LINE_STATUS_SAVED;
        block = block.next();
    }
    document()->setModified(false);
    update();
}

void CodeEditor::makePure()
{
    QTextBlock block = document()->firstBlock();
    while(block.isValid()){
        TextBlockData *data = static_cast<TextBlockData *>(block.userData());
        if (data != nullptr)
            data->status = LINE_STATUS_PURE;
        block = block.next();
    }
    document()->clearUndoRedoStacks();
    update();
}

void CodeEditor::setHighlighter(Highlighter *h)
{
    if (h){
        highlighter->setDocument(nullptr);
        delete highlighter;
        highlighter = h;
        highlighter->setDocument(this->document());
        update();
    }
}

void CodeEditor::setTabSize(int s)
{
    if (tabsize != s){
        tabsize = s;
        int spacewidth = QFontMetrics(currentCharFormat().font()).horizontalAdvance(' ');
#if QT_VERSION_MAJOR <= 5
        setTabStopWidth(tabsize*spacewidth);
#elif QT_VERSION_MAJOR == 6
        setTabStopDistance(tabsize*spacewidth);
#endif
    }
}

void CodeEditor::setAutoIndent(bool b)
{
    if (autoindent != b){
        autoindent = b;
    }
}

void CodeEditor::setBraceMatching(bool b)
{
    if (bracematching != b){
        bracematching = b;
        updateExtraSelections();
    }
}

void CodeEditor::setTabToSpaces(bool b)
{
    if (tabtospaces != b){
        tabtospaces = b;
    }
}

void CodeEditor::setRightEdgePos(int e)
{
    if (rightedge != e){
        rightedge = e;
        update();
    }
}

void CodeEditor::setRightEdgeStyle(RightEdge e)
{
    if (edge != e){
        edge = e;
        update();
    }
}

void CodeEditor::setLineNumbering(LineNumbering n)
{
    if (numbering != n){
        numbering = n;
        updateGeometry();
    }
}

void CodeEditor::setSaveStatusVisible(bool b)
{
    if (showsavestatusgutter != b){
        showsavestatusgutter = b;
        updateGeometry();
    }
}

GutterArea *CodeEditor::gutterWidget()
{
    return gutter;
}


bool CodeEditor::loadFromFile(const QString &filename)
{
    QFile loadfile(filename);
    if (!loadfile.open(QIODevice::ReadOnly)) {
        qWarning("Couldn't open file.");
        return false;
    }
    //QTextStream in(&loadfile);
    QString data = loadfile.readAll();
    setPlainText(data);
    makePure();
    return true;
}

bool CodeEditor::saveToFile(const QString &filename)
{

    QFile savefile(filename);
    if (!savefile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        qWarning("Couldn't open file.");
        return false;
    }
    QTextStream out(&savefile);
    out << toPlainText();
    makeSaved();
    return true;
}
