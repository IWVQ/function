#ifndef CODEEDITOR_H
#define CODEEDITOR_H

#include <QtWidgets>
#include "fxhilite.h"
#include "jsonhilite.h"

/* TODO:
- focus when click on gutter

- load from file
- save to file
- make pure
- sethighlighter

- show save gutter
- show number gutter
- set right edge show/position
- autocomplete option
- autoindent option
- tabtospaces
- tabsize
- match braces

- set highlighter by language

- load config from master
*/

class CodeEditor;

class GutterArea: public QWidget
{
    Q_OBJECT

public:
    explicit GutterArea(QWidget *parent = nullptr);
    ~GutterArea();

    QSize sizeHint() const override;
protected:
    void paintEvent(QPaintEvent *event) override;

    void mousePressEvent(QMouseEvent *event) override;
    void mouseReleaseEvent(QMouseEvent *event) override;
    void mouseMoveEvent(QMouseEvent *event) override;
    void wheelEvent(QWheelEvent *event) override;
public:
    CodeEditor *editor;
    int selanchorline = -1;
};

class CodeEditor: public QPlainTextEdit
{
    Q_OBJECT

public:
    enum LineNumbering{
        NUMBERING_NONE = 0,
        NUMBERING_PARTIAL = 1,
        NUMBERING_FULL = 2
    };

    enum RightEdge{
        EDGE_NONE = 0,
        EDGE_PARTIAL = 1,
        EDGE_FULL = 2
    };

    explicit CodeEditor(QWidget *parent = nullptr);
    ~CodeEditor();

    virtual int gutterWidth();
    virtual QString gutterLineString(int i);
    virtual void gutterPaintEvent(QPaintEvent *event);


    void test_status_saved(){
        QTextBlock block = document()->firstBlock();
        while(block.isValid()){
            TextBlockData *data = static_cast<TextBlockData *>(block.userData());
            if (data != nullptr)
                if (data->status == LINE_STATUS_MODIFIED)
                    data->status = LINE_STATUS_SAVED;
            block = block.next();

        }
        update();
    }

    void test_status_virgin(){
        QTextBlock block = document()->firstBlock();
        while(block.isValid()){
            TextBlockData *data = static_cast<TextBlockData *>(block.userData());
            if (data != nullptr)
                data->status = LINE_STATUS_PURE;
            block = block.next();
        }
        update();
    }

    void doWheelEvent(QWheelEvent *event);
    int lineFromPoint(QPoint p, int from = -1);
    void selectLines(int anchorline, int caretline);

//signals:
//    void coordChanged();
protected:
    void resizeEvent(QResizeEvent *event) override;
    void paintEvent(QPaintEvent *event) override;
    void keyPressEvent(QKeyEvent *event) override;

protected slots:
    void onUpdateRequest(const QRect &rect, int dy);
    void onBlockCountChanged(int newBlockCount);
    virtual void onCursorPositionChanged();
    virtual void onSelectionChanged();
protected:
    virtual bool keyStrokeTab(bool back, QKeyEvent *event);
    virtual bool keyStrokeReturn(QKeyEvent *event);
    virtual bool keyStrokeUp(QKeyEvent *event);
    virtual bool keyStrokeDown(QKeyEvent *event);

    bool autoCompleteDelimiter(QKeyEvent *event, char c);
    bool autoCompleteDelimiterDone(QKeyEvent *event);
    void updateGutterLine(int line);

protected:
    QTextBlock blockFromPosition(int pos);
    void matchBraces();
    void colouriseBraces(QList<QTextEdit::ExtraSelection> *selections);
    void colouriseCurrentLine(QList<QTextEdit::ExtraSelection> *selections);
    void updateGutterGeometry();
    void drawRightEdge(QPaintEvent *event);

    int currentline = -1;
    int delimiterautocompletionpos = -1;
    bool autocompletedelimiter = true;
    bool autoindent = true;
    bool tabtospaces = true;
    int tabsize = 4;
    int rightedge = 80;
    RightEdge edge = EDGE_FULL;
    LineNumbering numbering = NUMBERING_PARTIAL;
    int braces[2] = {-1, -1};
    FXHighlighter *highlighter;
    GutterArea *gutter;
};

inline bool isOpenBrace(char c)
{
    return (c == '(') || (c == '[') || (c == '{');
}

inline bool isCloseBrace(char c)
{
    return (c == ')') || (c == ']') || (c == '}');
}

#endif // CODEEDITOR_H
