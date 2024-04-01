#include "searchengine.h"

void SearchEngine::init(CodeEditor *e)
{
    editor = e;
    anchorpos = -1;
    str = "";
    strrep = "";
}

QTextCursor SearchEngine::findText(const QTextCursor &from, bool backward)
{
    // options
    QTextDocument::FindFlags flags;
    if (backward) flags |= QTextDocument::FindBackward;
    if (casesensitive) flags |= QTextDocument::FindCaseSensitively;
    if (wholeword) flags |= QTextDocument::FindWholeWords;

    bool selonly = selectiononly && editor->textCursor().hasSelection();
    // range
    int minpos = 0;
    int maxpos = editor->documentLength();
    if (selonly){
        minpos = editor->textCursor().selectionStart();
        maxpos = editor->textCursor().selectionEnd();
    }
    int startpos = minpos;
    int endpos = maxpos;
    if (backward)
        std::swap(startpos, endpos);

    // cursor from
    QTextCursor cur = from;
    if(cur.isNull()){
        cur = editor->textCursor();
        if (fromcursor) ;
        else cur.setPosition(startpos);
    }
    if (cur.position() < minpos || cur.position() > maxpos)
        return QTextCursor(); // cursor out of range

    // find
    QTextCursor foundcur;
    if (regex){
        QRegularExpression re(str);
        foundcur = editor->document()->find(re, cur, flags);
        if (foundcur.isNull()){ // check for wrap
            if (wrap && fromcursor && cur.position() != startpos){
                cur.setPosition(startpos);
                foundcur = editor->document()->find(re, cur, flags);
            }
        }
    }
    else {
        foundcur = editor->document()->find(str, cur, flags);
        if (foundcur.isNull()){ // check for wrap
            if (wrap && fromcursor && cur.position() != startpos){
                cur.setPosition(startpos);
                foundcur = editor->document()->find(str, cur, flags);
            }
        }
    }

    // check range bounds
    if (selonly && !foundcur.isNull()){
        if (foundcur.selectionStart() < minpos ||
            foundcur.selectionEnd() > maxpos)
            return QTextCursor();
    }

    return foundcur;
}

void SearchEngine::collectFind(QList<QTextCursor> &list)
{
    // determine range
    int startpos = 0;
    int endpos = editor->documentLength();
    if (selectiononly && editor->textCursor().hasSelection()){
        startpos = editor->textCursor().selectionStart();
        endpos = editor->textCursor().selectionEnd();
    }

    // find all
    QTextCursor c = editor->textCursor();
    c.setPosition(startpos);
    forever{
        c = findText(c, false);
        if (!c.isNull()) list.append(c);
        if (c.isNull() || c.position() >= endpos) break;
    }
}

bool SearchEngine::canReplace(const QTextCursor &c)
{
    bool autoreplace = false;
    bool cancel = false;
    return canReplace(c, false, autoreplace, cancel);
}

bool SearchEngine::canReplace(const QTextCursor &c, bool all, bool &autoreplace,
                              bool &cancel)
{
    Console *console = qobject_cast<Console *>(editor);
    if (console){
        bool matchprotected = false;
        if (c.isNull())
            matchprotected = console->selectionInProtectedArea();
        else
            matchprotected = (c.selectionStart() < console->protectedTo()) ||
                             (c.selectionEnd() < console->protectedTo());
        if (matchprotected) return false; // skip
    }

    if (makequestion && !autoreplace){
        QMessageBox::StandardButtons btns;
        QMessageBox::StandardButton btn;
        QString msg;

        msg = "Would you like to replace it?";
        btns = QMessageBox::Yes
             | QMessageBox::No
             | QMessageBox::Cancel;
        if (all) btns |= QMessageBox::YesToAll;

        btn = QMessageBox::question(w, "Question", msg, btns, QMessageBox::Yes);
        if ((btn != QMessageBox::Yes)
            && (btn != QMessageBox::No)
            && (btn != QMessageBox::YesToAll)){
            cancel = true;
            return false;
        }

        if (btn == QMessageBox::YesToAll)
            autoreplace = true;
        if (btn == QMessageBox::No)
            return false;
    }

    return true;
}

void SearchEngine::replaceOccurrence(const QTextCursor &c)
{
    editor->setTextCursor(c);
    editor->textCursor().insertText(strrep);
    if (anchorpos != -1){
        int delta = strrep.length() - str.length();
        if (anchorpos > c.selectionStart())
            anchorpos += delta; // correct anchor
    }
}

void SearchEngine::showResults(const QTextCursor &c, int count)
{
    bool selonly = selectiononly && editor->textCursor().hasSelection();
    QPalette p = label->palette();
    QString msg = "";
    bool show = true;
    if (result & FIND_RESULT_NOT_FOUND){
        if (selonly)
            msg = "Can't find the text \"" + str + "\" in current selection";
        else
            msg = "Can't find the text \"" + str + "\" in this file";
        p.setColor(QPalette::Text, Qt::darkRed);
    }
    else if (result & FIND_RESULT_COUNT){
        if (selonly)
            msg = QString::number(count) + " matches in selected text";
        else
            msg = QString::number(count) + " matches in entire file";
        if (count == 0) p.setColor(QPalette::Text, Qt::darkRed);
        else p.setColor(QPalette::Text, Qt::darkBlue);
    }
    else{
        editor->setTextCursor(c);
        if (result & FIND_RESULT_REPLACED){
            if (count == -1){
                if (canReplace(c))
                    replaceOccurrence(c);
                show = false;
            }
            else if (selonly)
                msg = QString::number(count) + " occurrences were replaced in selected text";
            else
                msg = QString::number(count) + " occurrences were replaced in entire file";

        }
        else if (result & FIND_RESULT_AGAIN)
            msg = "Going back to the first result";
        else
            show = false;
        if (count == 0) p.setColor(QPalette::Text, Qt::darkRed);
        else p.setColor(QPalette::Text, Qt::darkBlue);
    }
    label->setPalette(p);
    label->setText(msg);
    label->setVisible(show);
}

void SearchEngine::find(const QString &s, bool backward)
{
    if (!editor) return;

    result = FIND_RESULT_SUCCESS;
    str = s;
    QTextCursor c; //! is really null?
    c = findText(c, backward);
    if (!c.isNull()){
        if (anchorpos == -1)
            anchorpos = c.position();
        else if (anchorpos == c.position())
            result |= FIND_RESULT_AGAIN;
    }
    else
        result |= FIND_RESULT_NOT_FOUND;
    showResults(c);
}

void SearchEngine::replace(const QString &s, const QString &rep, bool backward)
{
    if (!editor) return;

    result = FIND_RESULT_REPLACED;
    str = s;
    strrep = rep;
    QTextCursor c; //! is really null?
    c = findText(c, backward);
    if (!c.isNull()){
        if (anchorpos == -1)
            if (backward) anchorpos = c.selectionEnd();
            else anchorpos = c.selectionStart();
        else if (backward && anchorpos >= c.selectionEnd())
            result |= FIND_RESULT_AGAIN;
        else if (!backward && anchorpos <= c.selectionStart())
            result |= FIND_RESULT_AGAIN;
    }
    else
        result |= FIND_RESULT_NOT_FOUND;
    showResults(c);
}

void SearchEngine::count(const QString &s)
{
    if (!editor) return;

    str = s;
    QList<QTextCursor> list;
    collectFind(list);
    result = FIND_RESULT_COUNT;
    showResults(QTextCursor(), list.count());
}

void SearchEngine::replaceAll(const QString &s, const QString &rep)
{
    if (!editor) return;

    str = s;
    strrep = rep;
    result = FIND_RESULT_REPLACED;

    QList<QTextCursor> list;
    collectFind(list);
    int count = 0;
    bool autoreplace = false;
    bool cancel = false;
    anchorpos = -1; // invalidate
    for (int i = list.count() - 1; i >= 0; i--){
        QTextCursor c = list.at(i);
        editor->setTextCursor(c);
        if (canReplace(c, true, autoreplace, cancel)){
            replaceOccurrence(c);
            count++;
        }
    }
    showResults(QTextCursor(), count);
    editor->update();
}
