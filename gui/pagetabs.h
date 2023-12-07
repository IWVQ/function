#ifndef PAGETABS_H
#define PAGETABS_H

#include <QtWidgets>
#include "shell.h"
#include "codeeditor.h"
#include "console.h"

class PageTabs;
class TabSheet;

class TabListToolButton: public QToolButton
{
    Q_OBJECT
public:
    explicit TabListToolButton(QWidget *parent = nullptr);
    ~TabListToolButton();

    void initialize(PageTabs *t);

    PageTabs *pageTabs(){ return pagetabs; }
    void tabSheetAction(TabSheet *sheet, bool added);
protected:
    void mousePressEvent(QMouseEvent *event) override;
    void prepareTheMenu();
private:
    QActionGroup *thegroup = nullptr;
    QMenu *themenu = nullptr;
    PageTabs *pagetabs = nullptr;
};

class TabSheet: public QWidget
{
    Q_OBJECT
public:
    explicit TabSheet(QWidget *parent = nullptr);
    ~TabSheet();

    virtual void initialize(PageTabs *pagetabs, const QString &filename);
    virtual void finalize(PageTabs *pagetabs);

    virtual bool isShellTabSheet() const {return false;}
    virtual bool loadFromFile(const QString &filename);
    virtual bool saveToFile(const QString &filename);

    virtual void applySettings(QJsonDocument *settings);
    virtual void checkSettings(QJsonDocument *settings);

    QString language(){return thelanguage;}
    void setLanguage(const QString &l);

    PageTabs *pageTabs(){ return thepagetabs; }
    virtual bool isModified();
    int index(){return theindex;}
signals:
    void captionChanged(TabSheet *me);
protected slots:
    virtual void onModifiedChanged(bool m = true);
    void onUndoAvailable(bool b);
    void onRedoAvailable(bool b);
    void onSelectionChanged();
    void onCoordinatesChanged();

    virtual void onActionTriggered(bool checked = false);
public:
    CodeEditor *theeditor = nullptr;
    QAction *theaction = nullptr; // menu list action
    QString thelanguage = "";
    QVBoxLayout *thelayout = nullptr;
    PageTabs *thepagetabs = nullptr;
    QString filename = "";
    QString title = "";
    QIcon icon;
protected:
    bool needssettings = false;
    int theindex;
    friend class PageTabs;
};

class ShellTabSheet: public TabSheet
{
    Q_OBJECT
public:
    explicit ShellTabSheet(QWidget *parent = nullptr);
    ~ShellTabSheet();

    bool isShellTabSheet() const override {return true;}
    void initialize(PageTabs *pagetabs, const QString &filename) override;
    void finalize(PageTabs *pagetabs) override;

    bool loadFromFile(const QString &filename) override;
    bool saveToFile(const QString &filename) override;
    void checkSettings(QJsonDocument *settings) override;
    bool isModified() override;
protected slots:
    void onEvaluating(bool b);
    void onExiting();
    void onStarted();
public:
    Console *theconsole = nullptr;
};

class PageTabs: public QTabWidget
{
    Q_OBJECT
public:
    explicit PageTabs(QWidget *parent = nullptr);
    ~PageTabs();

    TabSheet *appendTabSheet(const QString &filename);
    ShellTabSheet *appendShellTabSheet(const QString &filename);
    TabSheet *removeTabSheet(int index);
    void deleteTabSheet(int index);
    void applySettings(QJsonDocument *settings);

    QAction *tabAction(int index);
    TabSheet *tabSheet(int index);
    TabSheet *currentTabSheet();
    void doTabSheetModifiedChanged(TabSheet *sheet, bool m);
    void doTabUndoAvailable(TabSheet *sheet, bool b);
    void doTabRedoAvailable(TabSheet *sheet, bool b);
    void doTabSelectionChanged(TabSheet *sheet);
    void doTabCoordinatesChanged(TabSheet *sheet);
    void doTabEvaluating(TabSheet *sheet, bool b);
    void doTabExiting(TabSheet *sheet);
    void doTabStarted(TabSheet *sheet);
signals:
    void tabSheetAdded(TabSheet *sheet);
    void tabSheetRemoved(TabSheet *sheet);

    void tabSheetCaptionChanged(TabSheet *sheet);
    void tabSheetModifiedChanged(TabSheet *sheet, bool m);
    void tabUndoAvailable(TabSheet *sheet, bool b);
    void tabRedoAvailable(TabSheet *sheet, bool b);
    void tabSelectionChanged(TabSheet *sheet);
    void tabCoordinatesChanged(TabSheet *sheet);
    void tabEvaluating(TabSheet *sheet, bool b);
    void tabExiting(TabSheet *sheet);
    void tabStarted(TabSheet *sheet);
protected slots:
    void onCurrentChanged(int index);
    void onTabCaptionChanged(TabSheet *me);
protected:
    void tabInserted(int index) override;
    void tabRemoved(int index) override;
private:
    void fillIndexes(int from = 0);
    QJsonDocument *thesettings = nullptr; // pointer to the settings
    TabListToolButton *listbutton;
    QWidget *cornerwidget;
    QHBoxLayout *cornerlayout;
};

QString newTabTitle(QTabWidget *pagetabs, bool shelltab = false);

#endif // PAGETABS_H
