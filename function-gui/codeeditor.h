#ifndef CODEEDITOR_H
#define CODEEDITOR_H

#include <QtWidgets>
#include "fxhilite.h"
#include "jsonhilite.h"

/* TODO:
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

    int leftMargin(){ return leftmargin;}
    int rightMargin(){ return rightmargin;}
    void setMargins(int aleft, int aright);
    QSize sizeHint() const override;
protected:
    void paintEvent(QPaintEvent *event) override;

    void mousePressEvent(QMouseEvent *event) override;
    void mouseReleaseEvent(QMouseEvent *event) override;
    void mouseMoveEvent(QMouseEvent *event) override;
    void wheelEvent(QWheelEvent *event) override;
protected:
    CodeEditor *editor;
    int selanchorline = -1;
    int leftmargin = 3;
    int rightmargin = 3;
    friend class CodeEditor;
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

    enum LineOperation{
        MOVE_UP_LINE,
        MOVE_DOWN_LINE,
        DUPLICATE_LINE,
        JOIN_LINES
    };

    explicit CodeEditor(QWidget *parent = nullptr);
    ~CodeEditor();

    virtual bool loadFromFile(const QString &filename);
    virtual bool saveToFile(const QString &filename);

    virtual int gutterWidth();
    virtual QString gutterLineString(int i);
    virtual void gutterPaintEvent(QPaintEvent *event);

    virtual void lineOperation(int i, LineOperation o);
    void doWheelEvent(QWheelEvent *event);
    int lineFromPoint(QPoint p, int from = -1);
    void selectLines(int anchorline, int caretline);
    void gotoPosition(int p);
    void gotoXY(int x, int y);
    QPoint whereXY();
    QPoint endXY();
    int documentLength();
    QTextBlock blockFromPosition(int pos);

    void modified(bool m = true);
    void makeSaved();
    void makePure(); // clear edition and history
    Highlighter *theHighlighter(){return highlighter;}
    int tabSize(){return tabsize;}
    bool autoIndent(){return autoindent;}
    bool braceMatching(){return bracematching;}
    bool tabToSpaces(){return tabtospaces;}
    int rightEdgePos(){return rightedge;}
    bool saveStatusVisible(){return showsavestatusgutter;};
    RightEdge rightEdgeStyle(){return edge;}
    LineNumbering lineNumbering(){return numbering;}

    void setHighlighter(Highlighter *h);
    void setTabSize(int s);
    void setAutoIndent(bool b);
    void setBraceMatching(bool b);
    void setTabToSpaces(bool b);
    void setRightEdgePos(int e);
    void setRightEdgeStyle(RightEdge e);
    void setLineNumbering(LineNumbering n);
    void setSaveStatusVisible(bool b);

    GutterArea *gutterWidget();
    bool canUndo(){ return canundo; }
    bool canRedo(){ return canredo; }
protected:
    void resizeEvent(QResizeEvent *event) override;
    void paintEvent(QPaintEvent *event) override;
    void keyPressEvent(QKeyEvent *event) override;

protected slots:
    void onUndoAvailable(bool b);
    void onRedoAvailable(bool b);
    void onUpdateRequest(const QRect &rect, int dy);
    void onBlockCountChanged(int newBlockCount);
    virtual void onCursorPositionChanged();
    virtual void onSelectionChanged();
protected:
    virtual bool canTab(int newpos, bool back = false);
    virtual bool keyStrokeTab(bool back, QKeyEvent *event);
    virtual bool keyStrokeReturn(QKeyEvent *event);
    virtual bool keyStrokeUp(QKeyEvent *event);
    virtual bool keyStrokeDown(QKeyEvent *event);

    bool autoCompleteDelimiter(QKeyEvent *event, char c);
    bool autoCompleteDelimiterDone(QKeyEvent *event);
    void updateGutterLine(int line);

protected:
    void matchBraces();
    void colouriseBraces(QList<QTextEdit::ExtraSelection> *selections);
    void colouriseCurrentLine(QList<QTextEdit::ExtraSelection> *selections);
    void updateGutterGeometry();
    void updateExtraSelections();
    void drawRightEdge(QPaintEvent *event);

    int currentline = -1;
    int delimiterautocompletionpos = -1;
    bool autocompletedelimiter = true;
    bool autoindent = true;
    bool tabtospaces = true;
    bool bracematching = true;
    bool showsavestatusgutter = true;
    int tabsize = 4;
    int rightedge = 80;
    RightEdge edge = EDGE_FULL;
    LineNumbering numbering = NUMBERING_PARTIAL;
    int braces[2] = {-1, -1};
    Highlighter *highlighter;
    GutterArea *gutter;

    friend class GutterArea;
private:
    bool canundo = false;
    bool canredo = false;
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
