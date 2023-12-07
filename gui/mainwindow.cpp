#include "mainwindow.h"
#include "ui_mainwindow.h"

/* filters */

FindComboFilter::FindComboFilter(QObject *parent): QObject(parent)
{
    w = qobject_cast<MainWindow *>(parent);
}

bool FindComboFilter::eventFilter(QObject *watched, QEvent *event)
{
    if ((event->type() == QEvent::KeyPress)){
        QKeyEvent *keyevent = static_cast<QKeyEvent *>(event);
        if (keyevent->key() == Qt::Key_Return)
            if (w) {
                w->on_btnFindNext_clicked();
                return false; // do normaly
            }
    }
    return QObject::eventFilter(watched, event);
}

ReplaceComboFilter::ReplaceComboFilter(QObject *parent): QObject(parent)
{
    w = qobject_cast<MainWindow *>(parent);
}

bool ReplaceComboFilter::eventFilter(QObject *watched, QEvent *event)
{
    if ((event->type() == QEvent::KeyPress)){
        QKeyEvent *keyevent = static_cast<QKeyEvent *>(event);
        if (keyevent->key() == Qt::Key_Return)
            if (w) {
                w->on_btnReplaceNext_clicked();
                return false; // do normaly
            }
    }
    return QObject::eventFilter(watched, event);
}

/* MainWindow */

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{


    ui->setupUi(this);

    // QTextOption option = editor->document()->defaultTextOption();
    // option.setFlags(QTextOption::ShowTabsAndSpaces
    //                 //| QTextOption::ShowLineAndParagraphSeparators
    //                 //| QTextOption::AddSpaceForLineAndParagraphSeparators
    //                 //| QTextOption::ShowDocumentTerminator
    //                 //| QTextOption::IncludeTrailingSpaces
    //                 //| QTextOption::SuppressColors
    //                 );
    // editor->document()->setDefaultTextOption(option);

    // dialogs
    about = new AboutDialog(this);
    settings = new SettingsDialog(this);
    wndgoto = new WndGoto(this);

    connect(wndgoto, SIGNAL(gotoPressed(int,int)), this, SLOT(onWndGotoPressed(int,int)));

    // pageTabs

    connect(ui->pageTabs, SIGNAL(tabSheetModifiedChanged(TabSheet*,bool)),
            this, SLOT(on_pageTabs_tabSheetModifiedChanged(TabSheet*,bool)));
    connect(ui->pageTabs, SIGNAL(tabUndoAvailable(TabSheet*,bool)),
            this, SLOT(on_pageTabs_tabUndoAvailable(TabSheet*,bool)));
    connect(ui->pageTabs, SIGNAL(tabRedoAvailable(TabSheet*,bool)),
            this, SLOT(on_pageTabs_tabRedoAvailable(TabSheet*,bool)));
    connect(ui->pageTabs, SIGNAL(tabSelectionChanged(TabSheet*)),
            this, SLOT(on_pageTabs_tabSelectionChanged(TabSheet*)));
    connect(ui->pageTabs, SIGNAL(tabCoordinatesChanged(TabSheet*)),
            this, SLOT(on_pageTabs_tabCoordinatesChanged(TabSheet*)));
    connect(ui->pageTabs, SIGNAL(tabEvaluating(TabSheet*,bool)),
            this, SLOT(on_pageTabs_tabEvaluating(TabSheet*,bool)));
    connect(ui->pageTabs, SIGNAL(tabExiting(TabSheet*)),
            this, SLOT(on_pageTabs_tabExiting(TabSheet*)), Qt::UniqueConnection); // why?
    connect(ui->pageTabs, SIGNAL(tabStarted(TabSheet*)),
            this, SLOT(on_pageTabs_tabStarted(TabSheet*)));
    connect(ui->pageTabs, SIGNAL(tabSheetCaptionChanged(TabSheet*)),
            this, SLOT(on_pageTabs_tabSheetCaptionChanged(TabSheet*)));

    // find

    findfilter = new FindComboFilter(this);
    replacefilter = new ReplaceComboFilter(this);
    ui->combo_Find->installEventFilter(findfilter);
    ui->combo_Replace->installEventFilter(replacefilter);
    search.label = ui->findLabel;
    search.w = this;

    // coord status

    coordStatusWdg = new QWidget(ui->statusbar);
    coordStatusWdg->setObjectName(QString::fromUtf8("coordStatusWdg"));
    coordStatusWdg->setVisible(true);
    coordStatusWdg->setMinimumSize(QSize{230, 0});
    coordStatusWdg->setMaximumSize(QSize{230, 16777215});

    coordStatusLayout = new QHBoxLayout(coordStatusWdg);
    coordStatusLayout->setObjectName(QString::fromUtf8("coordStatusLayout"));
    coordStatusLayout->setContentsMargins(9, 0, 0, 0);

    coordStatusImg = new QLabel(coordStatusWdg);
    coordStatusImg->setObjectName(QString::fromUtf8("coordStatusWdg"));
    QSizePolicy coordStatusSizePolicy = coordStatusImg->sizePolicy();
    coordStatusSizePolicy.setHorizontalPolicy(QSizePolicy::Fixed);
    coordStatusImg->setSizePolicy(coordStatusSizePolicy);
    coordStatusImg->setVisible(true);
    coordStatusImg->setPixmap(QPixmap(QString::fromUtf8(":/thirdparty/lucide-icons/text-cursor-b.png")));
    coordStatusLayout->addWidget(coordStatusImg);

    coordStatusLbl = new QLabel(coordStatusWdg);
    coordStatusLbl->setObjectName(QString::fromUtf8("coordStatusLbl"));
    coordStatusLbl->setVisible(true);
    coordStatusLbl->setText("");
    coordStatusLayout->addWidget(coordStatusLbl);

    ui->statusbar->addWidget(coordStatusWdg);

    // run status

    runStatusWdg = new QWidget(ui->statusbar);
    runStatusWdg->setObjectName(QString::fromUtf8("runStatusWdg"));
    runStatusWdg->setVisible(true);
    runStatusWdg->setMinimumSize(QSize{130, 0});
    runStatusWdg->setMaximumSize(QSize{130, 16777215});

    runStatusLayout = new QHBoxLayout(runStatusWdg);
    runStatusLayout->setObjectName(QString::fromUtf8("runStatusLayout"));
    runStatusLayout->setContentsMargins(9, 0, 0, 0);

    runStatusImg = new QLabel(runStatusWdg);
    runStatusImg->setObjectName(QString::fromUtf8("runStatusWdg"));
    QSizePolicy runStatusSizePolicy = runStatusImg->sizePolicy();
    runStatusSizePolicy.setHorizontalPolicy(QSizePolicy::Fixed);
    runStatusImg->setSizePolicy(runStatusSizePolicy);
    runStatusImg->setVisible(false);
    runStatusImg->setPixmap(QPixmap(QString::fromUtf8(":/img/runstatus.png")));
    runStatusLayout->addWidget(runStatusImg);

    runStatusLbl = new QLabel(runStatusWdg);
    runStatusLbl->setObjectName(QString::fromUtf8("runStatusLbl"));
    runStatusLbl->setVisible(true);
    runStatusLbl->setText("");
    runStatusLayout->addWidget(runStatusLbl);

    ui->statusbar->addWidget(runStatusWdg);

    // actions
    ui->actionReferences->setShortcut(QApplication::translate("MainWindow", "F1", nullptr));

    // init
    on_pushButton_closesearch_clicked();
    ui->pageTabs->appendShellTabSheet("");
}

MainWindow::~MainWindow()
{
    delete ui;
}

//-- search

void MainWindow::on_pushButton_closesearch_clicked()
{
    ui->replaceWidget->setVisible(false);
    ui->searchWidget->setVisible(false);
    ui->findLabel->setVisible(false);
}


//-- settings

void MainWindow::on_actionSettings_triggered()
{
    settings->showSettings();
}

//-- about & help

void MainWindow::on_actionAbout_triggered()
{
    about->showAbout();
}

void MainWindow::on_actionManual_triggered()
{ //#
    QDesktopServices::openUrl(QUrl::fromLocalFile("manual.pdf"));
}


void MainWindow::on_actionReferences_triggered()
{
    //#
}

//--


void MainWindow::on_actionNewScript_triggered()
{
    ui->pageTabs->appendTabSheet("");
}


void MainWindow::on_actionNewShell_triggered()
{
    ui->pageTabs->appendShellTabSheet("");
}


void MainWindow::on_actionOpen_triggered()
{
    // select the file
    QString selfilter = tr("Function (*.fx *.fxsh)");
    QString filename = QFileDialog::getOpenFileName(this,
                        tr("Open file"),
                        "",
                        tr("All files (*.*);;Function (*.fx *.fxsh);;JSON (*.json)" ),
                        &selfilter);
    // check if file was opened
    for (int i = 0; i < ui->pageTabs->count(); i++){
        if (filename == ui->pageTabs->tabSheet(i)->filename){
            // previously opened
            ui->pageTabs->setCurrentIndex(i);
            return;
        }
    }
    // open the file
    QFileInfo info(filename);
    if (info.suffix() == SHELL_FILE){
        ui->pageTabs->appendShellTabSheet(filename);
    }
    else{
        ui->pageTabs->appendTabSheet(filename);
    }
}

void MainWindow::saveTabSheetFile(TabSheet *sheet, bool saveas)
{
    if (sheet && sheet->isModified()){
        QString filename;
        if (sheet->filename == "" || saveas){
            QString filter = "*.";
            if (sheet->isShellTabSheet())
                filter.append(SHELL_FILE);
            else
                filter.append("fx");
            filename = QFileDialog::getSaveFileName(this, tr("Save file"), "", filter);
        }
        else
            filename = sheet->filename;
        sheet->saveToFile(filename);
    }
}

void MainWindow::on_actionSave_triggered()
{
    saveTabSheetFile(ui->pageTabs->currentTabSheet());
}


void MainWindow::on_actionSaveAs_triggered()
{
    saveTabSheetFile(ui->pageTabs->currentTabSheet(), true);
}


void MainWindow::on_actionSaveAll_triggered()
{
    for (int i = 0; i < ui->pageTabs->count(); i++){
        saveTabSheetFile(ui->pageTabs->tabSheet(i));
    }
}

bool MainWindow::closeTabSheet(int index)
{
    TabSheet *sheet = ui->pageTabs->tabSheet(index);
    // check if modified
    if (sheet->isModified()){
        QMessageBox::StandardButton btn;
        QString msg = "\"" + sheet->title + "\" have unsaved changes.\nDo you want to save it?" ;
        btn = QMessageBox::question(this, "Question", msg,
                                    QMessageBox::Save
                                    | QMessageBox::Discard
                                    | QMessageBox::Cancel,
                                    QMessageBox::Save);
        if ((btn != QMessageBox::Save) && (btn != QMessageBox::Discard))
            return false; // canceled

        if (btn == QMessageBox::Save)
            saveTabSheetFile(sheet);
        else if (btn == QMessageBox::Discard)
            {}
    }
    //
    ui->pageTabs->deleteTabSheet(index);

    // if (ui->pageTabs->count() == 0) close(); //# only for exit if no more shells

    return true;
}

bool MainWindow::closeAllTabs()
{
    int l = ui->pageTabs->count();
    // do close
    while (l > 0){ // close from the last
        if (!closeTabSheet(l - 1)) return false;
        l--;
    }
    return true;
}

void MainWindow::on_actionClose_triggered()
{
    closeTabSheet(ui->pageTabs->currentIndex());
}


void MainWindow::on_actionCloseAll_triggered()
{
    closeAllTabs();
}


void MainWindow::on_actionPrint_triggered()
{
    //# print technology
}


void MainWindow::closeEvent(QCloseEvent *event)
{
    //# if we are using backup then don't save the tabs, destroy it directly
    if (closeAllTabs())
        event->accept();
    else
        event->ignore();
}


void MainWindow::on_actionExit_triggered()
{
    close();
}


void MainWindow::on_pageTabs_currentChanged(int index)
{
    updateActionEnabling();
    if (index != -1){
        updateWindowTitle(ui->pageTabs->currentTabSheet());
        CodeEditor *editor = currentEditor();
        if (ui->actionLineWrap->isChecked())
            editor->setLineWrapMode(QPlainTextEdit::WidgetWidth);
        else
            editor->setLineWrapMode(QPlainTextEdit::NoWrap);
        search.init(editor);
    }
    else
        search.init(nullptr);
    updateCoordinatesStatus();
}


void MainWindow::on_pageTabs_tabCloseRequested(int index)
{
    closeTabSheet(index);
}

void MainWindow::on_pageTabs_tabSheetModifiedChanged(TabSheet *sheet, bool m)
{
    if (sheet == ui->pageTabs->currentTabSheet()){
        ui->actionSave->setEnabled(canSaveSheet(sheet));
        ui->actionSaveAs->setEnabled(m);
    }
    updateSaveAllAction();
}

void MainWindow::on_pageTabs_tabUndoAvailable(TabSheet *sheet, bool)
{
    if (sheet == ui->pageTabs->currentTabSheet()){
        ShellTabSheet *consolesheet = qobject_cast<ShellTabSheet*>(sheet);
        if (consolesheet){
            ui->actionUndo->setEnabled(consolesheet->theconsole->canUndo());
        }
        else {
            ui->actionUndo->setEnabled(sheet->theeditor->canUndo());
        }
    }
}

void MainWindow::on_pageTabs_tabRedoAvailable(TabSheet *sheet, bool)
{
    if (sheet == ui->pageTabs->currentTabSheet()){
        ShellTabSheet *consolesheet = qobject_cast<ShellTabSheet*>(sheet);
        if (consolesheet){
            ui->actionRedo->setEnabled(consolesheet->theconsole->canRedo());
        }
        else {
            ui->actionRedo->setEnabled(sheet->theeditor->canRedo());
        }
    }
}

void MainWindow::on_pageTabs_tabSelectionChanged(TabSheet *sheet)
{
    if (sheet == ui->pageTabs->currentTabSheet()){
        ShellTabSheet *consolesheet = qobject_cast<ShellTabSheet*>(sheet);
        if (consolesheet){
            bool s = !consolesheet->theconsole->selectionInProtectedArea();
            ui->actionCopy->setEnabled(consolesheet->theconsole->textCursor().hasSelection());
            ui->actionCut->setEnabled(s && consolesheet->theconsole->textCursor().hasSelection());
            ui->actionPaste->setEnabled(s);
            ui->actionUppercase->setEnabled(s && consolesheet->theconsole->textCursor().hasSelection());
            ui->actionLowercase->setEnabled(s && consolesheet->theconsole->textCursor().hasSelection());
            ui->actionPropercase->setEnabled(s && consolesheet->theconsole->textCursor().hasSelection());

            if (consolesheet->theconsole->hasFocus()) search.init(consolesheet->theconsole);
        }
        else {
            ui->actionCopy->setEnabled(sheet->theeditor->textCursor().hasSelection());
            ui->actionCut->setEnabled(sheet->theeditor->textCursor().hasSelection());
            ui->actionPaste->setEnabled(true);
            ui->actionUppercase->setEnabled(sheet->theeditor->textCursor().hasSelection());
            ui->actionLowercase->setEnabled(sheet->theeditor->textCursor().hasSelection());
            ui->actionPropercase->setEnabled(sheet->theeditor->textCursor().hasSelection());

            if (sheet->theeditor->hasFocus()) search.init(sheet->theeditor);
        }
        updateCoordinatesStatus();
    }
}

void MainWindow::on_pageTabs_tabCoordinatesChanged(TabSheet *)
{
    updateCoordinatesStatus();
}

void MainWindow::on_pageTabs_tabEvaluating(TabSheet *sheet, bool)
{
    if (sheet == ui->pageTabs->currentTabSheet()){
        updateShellStatus();
        updateShellActions();
        ui->actionSave->setEnabled(canSaveSheet(sheet));
    }
}

bool MainWindow::canSaveSheet(TabSheet *sheet)
{
    ShellTabSheet *shsheet = qobject_cast<ShellTabSheet *>(sheet);
    if (shsheet)
        return shsheet->isModified() && !shsheet->theconsole->isEvaluating();
    else
        return sheet->isModified();
}

void MainWindow::on_pageTabs_tabExiting(TabSheet *sheet)
{
    qDebug("on_pageTabs_tabExiting");
    if (sheet){
        qDebug("if (sheet)");
        closeTabSheet(sheet->index()); // if closed then sheet is deleted
    }
}

void MainWindow::on_pageTabs_tabStarted(TabSheet *sheet)
{
    ShellTabSheet *shsheet = qobject_cast<ShellTabSheet *>(sheet);
    if (shsheet){
        shsheet->theconsole->makePure();
        shsheet->theconsole->makeSaved();
    }
}

void MainWindow::on_pageTabs_tabSheetCaptionChanged(TabSheet *sheet)
{
    if (sheet == ui->pageTabs->currentTabSheet()){
        updateWindowTitle(sheet);
    }
}


void MainWindow::updateWindowTitle(TabSheet *sheet)
{
    QString strtitle = sheet->filename;
    if (strtitle == "") strtitle = sheet->title;
    if (sheet->isModified()) strtitle = "*" + strtitle;
    setWindowTitle(strtitle + " - " + FX_WINDOW_NAME);
}

void MainWindow::updateActionEnabling()
{
    // action enabled technology
    updateFileActions();
    updateEditActions();
    updateShellActions();
}

void MainWindow::updateSaveAllAction()
{
    TabSheet *sheet = ui->pageTabs->currentTabSheet();
    bool m = false;
    if (sheet) m = sheet->isModified();

    if (m)
        ui->actionSaveAll->setEnabled(true);
    else{ //# this must be fast
        bool somethingmodified = false;
        for (int i = 0; i < ui->pageTabs->count(); i++)
            if (ui->pageTabs->tabSheet(i)->isModified()){
                somethingmodified = true;
                break;
            }
        ui->actionSaveAll->setEnabled(somethingmodified);
    }
}

void MainWindow::updateFileActions()
{
    TabSheet *sheet = ui->pageTabs->currentTabSheet();
    bool m = false;
    if (sheet){
        m = sheet->isModified();
        ui->actionSave->setEnabled(canSaveSheet(sheet));
        ui->actionSaveAs->setEnabled(m);
    }
    updateSaveAllAction();
}

void MainWindow::updateEditActions()
{
    TabSheet *sheet = ui->pageTabs->currentTabSheet();
    if (sheet){
        ShellTabSheet *consolesheet = qobject_cast<ShellTabSheet*>(sheet);
        if (consolesheet){
            bool s = !consolesheet->theconsole->selectionInProtectedArea();
            ui->actionUndo->setEnabled(consolesheet->theconsole->canUndo());
            ui->actionRedo->setEnabled(consolesheet->theconsole->canRedo());
            ui->actionCopy->setEnabled(consolesheet->theconsole->textCursor().hasSelection());
            ui->actionCut->setEnabled(s && consolesheet->theconsole->textCursor().hasSelection());
            ui->actionPaste->setEnabled(s);
            ui->actionUppercase->setEnabled(s && consolesheet->theconsole->textCursor().hasSelection());
            ui->actionLowercase->setEnabled(s && consolesheet->theconsole->textCursor().hasSelection());
            ui->actionPropercase->setEnabled(s && consolesheet->theconsole->textCursor().hasSelection());
        }
        else {
            ui->actionUndo->setEnabled(sheet->theeditor->canUndo());
            ui->actionRedo->setEnabled(sheet->theeditor->canRedo());
            ui->actionCopy->setEnabled(sheet->theeditor->textCursor().hasSelection());
            ui->actionCut->setEnabled(sheet->theeditor->textCursor().hasSelection());
            ui->actionPaste->setEnabled(true);
            ui->actionUppercase->setEnabled(sheet->theeditor->textCursor().hasSelection());
            ui->actionLowercase->setEnabled(sheet->theeditor->textCursor().hasSelection());
            ui->actionPropercase->setEnabled(sheet->theeditor->textCursor().hasSelection());
        }
    }
}

void MainWindow::on_actionUndo_triggered()
{
    TabSheet *sheet = ui->pageTabs->currentTabSheet();
    ShellTabSheet *consolesheet = qobject_cast<ShellTabSheet *>(sheet);
    if (consolesheet){
        consolesheet->theconsole->undo();
    }
    else if (sheet){
        sheet->theeditor->undo();
    }
}


void MainWindow::on_actionRedo_triggered()
{
    TabSheet *sheet = ui->pageTabs->currentTabSheet();
    ShellTabSheet *consolesheet = qobject_cast<ShellTabSheet *>(sheet);
    if (consolesheet){
        consolesheet->theconsole->redo();
    }
    else if (sheet){
        sheet->theeditor->redo();
    }
}


void MainWindow::on_actionCut_triggered()
{
    TabSheet *sheet = ui->pageTabs->currentTabSheet();
    ShellTabSheet *consolesheet = qobject_cast<ShellTabSheet *>(sheet);
    if (consolesheet){
        if (!consolesheet->theconsole->selectionInProtectedArea())
            consolesheet->theconsole->cut();
    }
    else if (sheet){
        sheet->theeditor->cut();
    }
}


void MainWindow::on_actionCopy_triggered()
{
    TabSheet *sheet = ui->pageTabs->currentTabSheet();
    ShellTabSheet *consolesheet = qobject_cast<ShellTabSheet *>(sheet);
    if (consolesheet){
        consolesheet->theconsole->copy();
    }
    else if (sheet){
        sheet->theeditor->copy();
    }
}


void MainWindow::on_actionPaste_triggered()
{
    TabSheet *sheet = ui->pageTabs->currentTabSheet();
    ShellTabSheet *consolesheet = qobject_cast<ShellTabSheet *>(sheet);
    if (consolesheet){
        if (!consolesheet->theconsole->selectionInProtectedArea())
            consolesheet->theconsole->paste();
    }
    else if (sheet){
        sheet->theeditor->paste();
    }
}


void MainWindow::on_actionSelectAll_triggered()
{
    TabSheet *sheet = ui->pageTabs->currentTabSheet();
    ShellTabSheet *consolesheet = qobject_cast<ShellTabSheet *>(sheet);
    if (consolesheet){
        consolesheet->theconsole->selectAll();
    }
    else if (sheet){
        sheet->theeditor->selectAll();
    }
}


void MainWindow::on_actionUppercase_triggered()
{
    TabSheet *sheet = ui->pageTabs->currentTabSheet();
    ShellTabSheet *consolesheet = qobject_cast<ShellTabSheet *>(sheet);
    if (consolesheet){
        if (!consolesheet->theconsole->selectionInProtectedArea()){
            if (consolesheet->theconsole->textCursor().hasSelection()){
                QString str = consolesheet->theconsole->textCursor().selectedText();
                consolesheet->theconsole->textCursor().insertText(str.toUpper());
            }
        }
    }
    else if (sheet){
        if (sheet->theeditor->textCursor().hasSelection()){
            QString str = sheet->theeditor->textCursor().selectedText();
            sheet->theeditor->textCursor().insertText(str.toUpper());
        }
    }
}


void MainWindow::on_actionLowercase_triggered()
{
    TabSheet *sheet = ui->pageTabs->currentTabSheet();
    ShellTabSheet *consolesheet = qobject_cast<ShellTabSheet *>(sheet);
    if (consolesheet){
        if (!consolesheet->theconsole->selectionInProtectedArea()){
            if (consolesheet->theconsole->textCursor().hasSelection()){
                QString str = consolesheet->theconsole->textCursor().selectedText();
                consolesheet->theconsole->textCursor().insertText(str.toLower());
            }
        }
    }
    else if (sheet){
        if (sheet->theeditor->textCursor().hasSelection()){
            QString str = sheet->theeditor->textCursor().selectedText();
            sheet->theeditor->textCursor().insertText(str.toLower());
        }
    }
}

void strToProper(QString &str)
{
    int l = str.length();
    int i = 0;
LBL_PARSE:
    if (i == l) return;
    // consume spaces
    while (i < l && isSpaceChar(str[i])) i++;
    // upper case
    if (i < l){
        QChar c = str[i];
        str[i] = c.toUpper();
        i++;
    }
    // lower case
    while (i < l && !(isSpaceChar(str[i]))){
        QChar c = str[i];
        str[i] = c.toLower();
        i++;
    }
    goto LBL_PARSE;
}

void MainWindow::on_actionPropercase_triggered()
{
    TabSheet *sheet = ui->pageTabs->currentTabSheet();
    ShellTabSheet *consolesheet = qobject_cast<ShellTabSheet *>(sheet);
    if (consolesheet){
        if (!consolesheet->theconsole->selectionInProtectedArea()){
            if (consolesheet->theconsole->textCursor().hasSelection()){
                QString str = consolesheet->theconsole->textCursor().selectedText();
                strToProper(str);
                consolesheet->theconsole->textCursor().insertText(str);
            }
        }
    }
    else if (sheet){
        if (sheet->theeditor->textCursor().hasSelection()){
            QString str = sheet->theeditor->textCursor().selectedText();
            strToProper(str);
            sheet->theeditor->textCursor().insertText(str);
        }
    }
}


void MainWindow::on_actionMoveUpLine_triggered()
{
    TabSheet *sheet = ui->pageTabs->currentTabSheet();
    ShellTabSheet *consolesheet = qobject_cast<ShellTabSheet *>(sheet);
    if (consolesheet){
        int curr = consolesheet->theconsole->textCursor().blockNumber();
        consolesheet->theconsole->lineOperation(curr, CodeEditor::MOVE_UP_LINE);
    }
    else if (sheet){
        int curr = sheet->theeditor->textCursor().blockNumber();
        sheet->theeditor->lineOperation(curr, CodeEditor::MOVE_UP_LINE);
    }
}


void MainWindow::on_actionMoveDownLine_triggered()
{
    TabSheet *sheet = ui->pageTabs->currentTabSheet();
    ShellTabSheet *consolesheet = qobject_cast<ShellTabSheet *>(sheet);
    if (consolesheet){
        int curr = consolesheet->theconsole->textCursor().blockNumber();
        consolesheet->theconsole->lineOperation(curr, CodeEditor::MOVE_DOWN_LINE);
    }
    else if (sheet){
        int curr = sheet->theeditor->textCursor().blockNumber();
        sheet->theeditor->lineOperation(curr, CodeEditor::MOVE_DOWN_LINE);
    }
}


void MainWindow::on_actionDuplicateLine_triggered()
{
    TabSheet *sheet = ui->pageTabs->currentTabSheet();
    ShellTabSheet *consolesheet = qobject_cast<ShellTabSheet *>(sheet);
    if (consolesheet){
        int curr = consolesheet->theconsole->textCursor().blockNumber();
        consolesheet->theconsole->lineOperation(curr, CodeEditor::DUPLICATE_LINE);
    }
    else if (sheet){
        int curr = sheet->theeditor->textCursor().blockNumber();
        sheet->theeditor->lineOperation(curr, CodeEditor::DUPLICATE_LINE);
    }
}


void MainWindow::on_actionJoinLines_triggered()
{
    TabSheet *sheet = ui->pageTabs->currentTabSheet();
    ShellTabSheet *consolesheet = qobject_cast<ShellTabSheet *>(sheet);
    if (consolesheet){
        int curr = consolesheet->theconsole->textCursor().blockNumber();
        consolesheet->theconsole->lineOperation(curr, CodeEditor::JOIN_LINES);
    }
    else if (sheet){
        int curr = sheet->theeditor->textCursor().blockNumber();
        sheet->theeditor->lineOperation(curr, CodeEditor::JOIN_LINES);
    }
}

CodeEditor *MainWindow::currentEditor()
{
    TabSheet *sheet = ui->pageTabs->currentTabSheet();
    ShellTabSheet *consolesheet = qobject_cast<ShellTabSheet *>(sheet);
    if (consolesheet) return consolesheet->theconsole;
    else if (sheet) return sheet->theeditor;
    else return nullptr;
}

Console *MainWindow::currentConsole()
{
    TabSheet *sheet = ui->pageTabs->currentTabSheet();
    ShellTabSheet *consolesheet = qobject_cast<ShellTabSheet *>(sheet);
    if (consolesheet) return consolesheet->theconsole;
    else return nullptr;
}

TabSheet *MainWindow::currentTabSheet()
{
    return ui->pageTabs->currentTabSheet();
}

ShellTabSheet *MainWindow::currentShellTabSheet()
{
    TabSheet *sheet = ui->pageTabs->currentTabSheet();
    ShellTabSheet *consolesheet = qobject_cast<ShellTabSheet *>(sheet);
    return consolesheet;

}

// ---- text searching

void MainWindow::on_btnFindNext_clicked()
{
    search.find(ui->combo_Find->currentText(), false);
}


void MainWindow::on_btnFindPrev_clicked()
{
    search.find(ui->combo_Find->currentText(), true);
}


void MainWindow::on_btnFindCount_clicked()
{
    search.count(ui->combo_Find->currentText());
}

void MainWindow::on_btnReplaceNext_clicked()
{
    search.replace(ui->combo_Find->currentText(), ui->combo_Replace->currentText(), false);
}


void MainWindow::on_btnReplacePrev_clicked()
{
    search.replace(ui->combo_Find->currentText(), ui->combo_Replace->currentText(), true);
}


void MainWindow::on_btnReplaceAll_clicked()
{
    search.replaceAll(ui->combo_Find->currentText(), ui->combo_Replace->currentText());
}

void MainWindow::on_btn_CaseSensitive_toggled(bool checked)
{
    search.casesensitive = checked;
}


void MainWindow::on_btn_WholeWord_toggled(bool checked)
{
    search.wholeword = checked;
}


void MainWindow::on_btn_Regex_toggled(bool checked)
{
    search.regex = checked;
}


void MainWindow::on_btn_FromCursor_toggled(bool checked)
{
    search.fromcursor = checked;
}


void MainWindow::on_btn_SelOnly_toggled(bool checked)
{
    search.selectiononly = checked;
}


void MainWindow::on_btn_Question_toggled(bool checked)
{
    search.makequestion = checked;
}


void MainWindow::on_combo_Find_currentTextChanged(const QString &)
{
    search.init(currentEditor());
}


void MainWindow::on_combo_Replace_currentTextChanged(const QString &)
{
    //
}

void MainWindow::on_actionFind_triggered()
{
    CodeEditor *editor = currentEditor();
    if (editor){
        QString s = editor->textCursor().selectedText();
        ui->combo_Find->setCurrentText(s);
        ui->searchWidget->setVisible(true);
        ui->replaceWidget->setVisible(false);
        ui->findLabel->setVisible(false);
        ui->combo_Find->setFocus();
        search.init(currentEditor());
    }
}


void MainWindow::on_actionReplace_triggered()
{
    CodeEditor *editor = currentEditor();
    if (editor){
        QString s = editor->textCursor().selectedText();
        ui->combo_Find->setCurrentText(s);
        ui->searchWidget->setVisible(true);
        ui->replaceWidget->setVisible(true);
        ui->findLabel->setVisible(false);
        ui->combo_Find->setFocus();
        search.init(currentEditor());
    }
}


void MainWindow::on_actionGoto_triggered()
{
    CodeEditor *editor = currentEditor();
    if (editor)
        wndgoto->showGoto(editor->textCursor());
}

void MainWindow::onWndGotoPressed(int line, int col)
{
    CodeEditor *editor = currentEditor();
    if (editor){
        // line is 1-based
        line--;
        // col is 1-based
        col--;
        if (line >= editor->blockCount() - 1) line = editor->blockCount() - 1;
        if (line < 0) line = 0;
        QTextBlock block = editor->document()->findBlockByNumber(line);
        int strlen = block.text().length();
        if (col < 0) col = 0;
        if (col > strlen) col = strlen;
        int pos = block.position() + col;
        QTextCursor cursor = editor->textCursor();
        cursor.setPosition(pos);
        editor->setTextCursor(cursor);
        //# really goes
    }
}

//-----------------------

void MainWindow::on_actionLineWrap_triggered()
{
    CodeEditor *editor = currentEditor();
    if (!editor) return;

    if (ui->actionLineWrap->isChecked())
        editor->setLineWrapMode(QPlainTextEdit::WidgetWidth);
    else
        editor->setLineWrapMode(QPlainTextEdit::NoWrap);
}

void MainWindow::on_actionFullScreen_triggered()
{

}


//

void MainWindow::updateCoordinatesStatus()
{
    CodeEditor *editor = currentEditor();
    if (!editor) return;

    QString str = "";
    int line = editor->textCursor().blockNumber();
    int col = editor->textCursor().columnNumber();
    // int pos = editor->textCursor().position();
    str.append("line: ");
    str.append(QString::number(line + 1));
    str.append("   col: ");
    str.append(QString::number(col + 1));
    // str.append("   pos: ");
    // str.append(QString::number(pos));

    if(editor->textCursor().hasSelection()){
        int sel = editor->textCursor().selectionEnd() - editor->textCursor().selectionStart();
        int selln = editor->blockFromPosition(editor->textCursor().selectionEnd()).blockNumber() -
                     editor->blockFromPosition(editor->textCursor().selectionStart()).blockNumber() +
                     1;
        str.append("   sel: ");
        str.append(QString::number(sel));
        str.append(" - ");
        str.append(QString::number(selln));
    }

    coordStatusLbl->setText(str);
}

void MainWindow::updateShellStatus()
{
    Console *console = currentConsole();
    if (console && console->isEvaluating()){
        runStatusImg->setVisible(true);
        runStatusLbl->setText("evaluating..");
    }
    else{
        runStatusImg->setVisible(false);
        runStatusLbl->setText("");
    }
}

// shell & console

Shell *MainWindow::currentShell()
{ // be careful
    TabSheet *sheet = ui->pageTabs->currentTabSheet();
    ShellTabSheet *consolesheet = qobject_cast<ShellTabSheet *>(sheet);
    if (consolesheet) return consolesheet->theconsole->theShell();
    else return nullptr;
}

void MainWindow::on_actionPause_triggered()
{
    Console *console = currentConsole();
    if (console && console->isEvaluating() && !console->isPaused()){
        console->pause();
        ui->actionPause->setEnabled(false);
        ui->actionResume->setEnabled(true);
    }
}


void MainWindow::on_actionResume_triggered()
{
    Console *console = currentConsole();
    if (console && console->isEvaluating() && console->isPaused()){
        console->resume();
        ui->actionPause->setEnabled(true);
        ui->actionResume->setEnabled(false);
    }
}


void MainWindow::on_actionInterrupt_triggered()
{
    Console *console = currentConsole();
    if (console && console->isEvaluating()){
        console->interrupt();
        updateShellActions();
    }
}

void MainWindow::on_actionClearConsole_triggered()
{
    Console *console = currentConsole();
    if (console){
        console->userClrScr();
    }
}

void MainWindow::updateShellActions()
{
    Console *console = currentConsole();
    if (console){
        ui->actionPause->setEnabled(console->isEvaluating() && !console->isPaused());
        ui->actionResume->setEnabled(console->isEvaluating() && console->isPaused());
        ui->actionInterrupt->setEnabled(console->isEvaluating());
    }
    else{
        ui->actionPause->setEnabled(false);
        ui->actionResume->setEnabled(false);
        ui->actionInterrupt->setEnabled(false);
    }
}


