#ifndef SEARCHENGINE_H
#define SEARCHENGINE_H

#include <QtWidgets>
#include "codeeditor.h"
#include "console.h"

#define FIND_RESULT_SUCCESS     0
#define FIND_RESULT_REPLACED    1
#define FIND_RESULT_NOT_FOUND   2
#define FIND_RESULT_AGAIN       4
#define FIND_RESULT_COUNT       8

class SearchEngine
{
public:
    SearchEngine(){}
    void init(CodeEditor *e);
    void find(const QString &s, bool backward);
    void replace(const QString &s, const QString &rep, bool backward);
    void count(const QString &s);
    void replaceAll(const QString &s, const QString &rep);

    bool casesensitive = false;
    bool wholeword = false;
    bool regex = false;
    bool fromcursor = true;
    bool selectiononly = false;
    bool makequestion = false;
    bool wrap = true;
    CodeEditor *editor = nullptr;
    QLabel *label;
    QMainWindow *w;
private:
    void replaceOccurrence(const QTextCursor &c);
    bool canReplace(const QTextCursor &c);
    bool canReplace(const QTextCursor &c, bool all, bool &autoreplace, bool &cancel);
    void showResults(const QTextCursor &c, int count = -1);
    QTextCursor findText(const QTextCursor &from, bool backward);
    void collectFind(QList<QTextCursor> &list);

    char result = 0;
    int anchorpos = -1;
    QString str = "";
    QString strrep = "";
};

#endif // SEARCHENGINE_H
