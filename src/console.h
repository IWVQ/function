#ifndef CONSOLE_H
#define CONSOLE_H

#include <QtWidgets>
#include "codeeditor.h"
#include "consolehilite.h"

class Console: public CodeEditor
{
    Q_OBJECT

public:
    explicit Console(QWidget *parent = nullptr);
    ~Console();

    int gutterWidth() override; // fixed width,
    QString gutterLineString(int i) override;

    bool selectionInProtectedArea();
    void protectDragSelection();

protected slots:
    void onCursorPositionChanged() override; // implements: clear saved dragsel
    void onSelectionChanged() override; // implements: dragsel,
protected:
    void keyPressEvent(QKeyEvent *event) override;
    void dragEnterEvent(QDragEnterEvent *event) override;
    void dragLeaveEvent(QDragLeaveEvent *event) override;
    void dragMoveEvent(QDragMoveEvent *event) override;
    void dropEvent(QDropEvent *event) override;

    bool keyStrokeTab(bool back, QKeyEvent *event) override;
    bool keyStrokeReturn(QKeyEvent *event) override;
    bool keyStrokeUp(QKeyEvent *event) override;
    bool keyStrokeDown(QKeyEvent *event) override;
protected:
    bool checkReadOnlyEnd(QKeyEvent *event);

    int readonlyto = 0;
    int dragselanchor = -1;
    int dragselcaret = -1;
    bool dragoriginisme = false;
};

#endif // CONSOLE_H
