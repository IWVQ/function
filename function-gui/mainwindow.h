#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include "codeeditor.h"
#include "settingsdialog.h"
#include "aboutdialog.h"
#include "pagetabs.h"
#include "searchengine.h"
#include "wndgoto.h"

#define FX_WINDOW_NAME "Function"

QT_BEGIN_NAMESPACE
namespace Ui { class MainWindow; }
QT_END_NAMESPACE

class FindComboFilter;
class ReplaceComboFilter;

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(QWidget *parent = nullptr);
    ~MainWindow();

public slots:
    void on_btnFindNext_clicked();

    void on_btnReplaceNext_clicked();

private slots:
    void on_pushButton_closesearch_clicked();

    void on_actionSettings_triggered();

    void on_actionAbout_triggered();

    void on_actionNewScript_triggered();

    void on_actionNewShell_triggered();

    void on_actionOpen_triggered();

    void on_actionSave_triggered();

    void on_actionSaveAs_triggered();

    void on_actionSaveAll_triggered();

    void on_actionClose_triggered();

    void on_actionCloseAll_triggered();

    void on_actionPrint_triggered();

    void on_actionExit_triggered();

    void on_pageTabs_currentChanged(int index);

    void on_pageTabs_tabCloseRequested(int index);

    void on_pageTabs_tabSheetModifiedChanged(TabSheet *sheet, bool m);
    void on_pageTabs_tabUndoAvailable(TabSheet *sheet, bool b);
    void on_pageTabs_tabRedoAvailable(TabSheet *sheet, bool b);
    void on_pageTabs_tabSelectionChanged(TabSheet *sheet);
    void on_pageTabs_tabCoordinatesChanged(TabSheet *sheet);
    void on_pageTabs_tabEvaluating(TabSheet *sheet, bool b);
    void on_pageTabs_tabExiting(TabSheet *sheet);
    void on_pageTabs_tabStarted(TabSheet *sheet);
    void on_pageTabs_tabSheetCaptionChanged(TabSheet *sheet);

    void on_actionUndo_triggered();

    void on_actionRedo_triggered();

    void on_actionCut_triggered();

    void on_actionCopy_triggered();

    void on_actionPaste_triggered();

    void on_actionSelectAll_triggered();

    void on_actionUppercase_triggered();

    void on_actionLowercase_triggered();

    void on_actionPropercase_triggered();

    void on_actionMoveUpLine_triggered();

    void on_actionMoveDownLine_triggered();

    void on_actionDuplicateLine_triggered();

    void on_actionJoinLines_triggered();


    void on_btnFindPrev_clicked();

    void on_btnFindCount_clicked();

    void on_btnReplacePrev_clicked();

    void on_btnReplaceAll_clicked();

    void on_actionLineWrap_triggered();

    void on_actionFullScreen_triggered();

    void on_btn_CaseSensitive_toggled(bool checked);

    void on_btn_WholeWord_toggled(bool checked);

    void on_btn_Regex_toggled(bool checked);

    void on_btn_FromCursor_toggled(bool checked);

    void on_btn_SelOnly_toggled(bool checked);

    void on_btn_Question_toggled(bool checked);

    void on_combo_Find_currentTextChanged(const QString &arg1);

    void on_combo_Replace_currentTextChanged(const QString &arg1);

    void on_actionFind_triggered();

    void on_actionReplace_triggered();

    void on_actionGoto_triggered();

    void onWndGotoPressed(int line, int col);

    void on_actionPause_triggered();

    void on_actionResume_triggered();

    void on_actionInterrupt_triggered();

    void on_actionClearConsole_triggered();

    void on_actionManual_triggered();

    void on_actionReferences_triggered();

protected:
    void closeEvent(QCloseEvent *event) override;
private:
    bool canSaveSheet(TabSheet *sheet);
    void updateSaveAllAction();
    void updateFileActions();
    void updateEditActions();
    void updateShellActions();

    void updateWindowTitle(TabSheet *sheet);
    void updateActionEnabling();
    void saveTabSheetFile(TabSheet *sheet, bool saveas = false);
    bool closeTabSheet(int index);
    bool closeAllTabs();
    CodeEditor *currentEditor();
    Console *currentConsole();
    TabSheet *currentTabSheet();
    ShellTabSheet *currentShellTabSheet();
    Shell *currentShell();

    void updateCoordinatesStatus();
    void updateShellStatus();

    Ui::MainWindow *ui;

    // CodeEditor *editor;
    SettingsDialog *settings;
    AboutDialog *about;
    FindComboFilter *findfilter;
    ReplaceComboFilter *replacefilter;

    SearchEngine search;
    WndGoto *wndgoto;

    QLabel *coordStatusLbl;
    QLabel *coordStatusImg;
    QWidget *coordStatusWdg;
    QHBoxLayout *coordStatusLayout;

    QLabel *runStatusLbl;
    QLabel *runStatusImg;
    QWidget *runStatusWdg;
    QHBoxLayout *runStatusLayout;
};

class FindComboFilter: public QObject
{
    Q_OBJECT
public:
    FindComboFilter(QObject *parent = nullptr);
    bool eventFilter(QObject *watched, QEvent *event) override;
    MainWindow *w;
};

class ReplaceComboFilter: public QObject
{
    Q_OBJECT
public:
    ReplaceComboFilter(QObject *parent = nullptr);
    bool eventFilter(QObject *watched, QEvent *event) override;
    MainWindow *w;
};

#endif // MAINWINDOW_H
