#ifndef CONSOLE_H
#define CONSOLE_H

#include <QtWidgets>
#include "codeeditor.h"
#include "consolehilite.h"
#include "shell.h"

class Console;

class CmdHistory
{
public:
    CmdHistory();
    ~CmdHistory();

    void clear();
    void append(const QString &s);
    QString prev(const QString &cmdhint);
    QString next(const QString &cmdhint);
    bool canGoPrev(const QString &cmdhint);
    bool canGoNext(const QString &cmdhint);
    void save(const QString &cmd);
    bool onTop(){return current == count;}

    bool wrap = false;
    bool savewrittencmd = true;
protected:
    bool matchcmdhint = false; // experimental
    friend class Console;
private:
    int findPrevCmd(const QString &cmdhint);
    int findNextCmd(const QString &cmdhint);

    QString savedcmd = "";
    int current = 0;
    int count = 0;
    QString *body;
};

class Console: public CodeEditor
{
    Q_OBJECT

public:
    explicit Console(QWidget *parent = nullptr);
    ~Console();

    bool loadFromFile(const QString &filename) override;
    bool saveToFile(const QString &filename) override;

    void initialize();
    void pause();
    void resume();
    void interrupt();

    void userClrScr();
    void newCell(int cell, bool newline = true);
    void beginRead(const QString &prompter = "");
    void endRead(const QString &input);
    void write(const QString &s);
    void clrscr(int from = 0);
    void response(int m, qint64 l, qint64 r);

    CmdHistory *cmdHistory(){return commandhistory;}
    Shell *theShell(){ return shell; }
    void prevCmd();
    void nextCmd();
    bool canGoPrevCmd();
    bool canGoNextCmd();

    bool isEvaluating();
    bool isPaused();

signals:
    void evaluating(bool b);
    void exiting();
    void started();
protected slots:
    void onMessage(int m, qint64 l, qint64 r);
public:

    bool embeddedPrompter();
    void setEmbeddedPrompter(bool b);
    void selectReadingStr();
    void replaceReadingStr(const QString &s);
    QString readingStr();
    int readingPos();
    int protectedTo();
    void setProtectedTo(int t);
    ConsoleHighlighter *consoleHighlighter();
    void lineOperation(int i, LineOperation o) override;

    int gutterWidth() override; // fixed width,
    QString gutterLineString(int i) override;
    bool selectionInProtectedArea();
    int currentCellLine(){ return currentcellline; }
    int currentCellType(){ return currentcelltype; }
protected slots:
    void onCursorPositionChanged() override; // implements: clear saved dragsel
    void onSelectionChanged() override; // implements: dragsel,

protected:
    void protectDragSelection();
    bool canCursorGoPrevCmd();
    bool canCursorGoNextCmd();
    void protectAll();
    QString commandHint();
    void replaceByHistory(const QString &s);

protected:
    void keyPressEvent(QKeyEvent *event) override;
    void dragEnterEvent(QDragEnterEvent *event) override;
    void dragLeaveEvent(QDragLeaveEvent *event) override;
    void dragMoveEvent(QDragMoveEvent *event) override;
    void dropEvent(QDropEvent *event) override;

    bool canTab(int newpos, bool back) override;
    bool keyStrokeTab(bool back, QKeyEvent *event) override;
    bool keyStrokeReturn(QKeyEvent *event) override;
    bool keyStrokeUp(QKeyEvent *event) override;
    bool keyStrokeDown(QKeyEvent *event) override;
protected:
    bool checkProtectedTo(QKeyEvent *event);

    ConsoleHighlighter *consolehighlighter;
    CmdHistory *commandhistory;
    Shell *shell = nullptr;
    int protectedto = 0;
    int dragselanchor = -1;
    int dragselcaret = -1;
    bool dragoriginisme = false;
    bool reading = false;

    int currentcellline = -1;
    int currentcelltype = CELL_CONSOLE;
};

#endif // CONSOLE_H
