#include "pagetabs.h"

QString newTabTitle(QTabWidget *pagetabs, bool shelltab)
{
    if (!pagetabs) return "";

    // initializing
    QString str;
    if (shelltab)
        str = "console";
    else
        str = "new";

    int spacepos = str.length();
    bool str0 = false;
    int tentative = 1;

    if (pagetabs->count() == 0) return str;

    // collect numbers
    int v[pagetabs->count()];
    int l = 0;
    for (int t = 0; t < pagetabs->count(); t++){
        QString tabstr = pagetabs->tabText(t);
        if (tabstr.startsWith(str)){ // l > 0
            int tabstrlen = tabstr.length();
            if (spacepos < tabstrlen){
                if (tabstr[spacepos] == ' '){
                    int ll = tabstrlen - spacepos - 1;
                    if (tabstr[tabstrlen - 1] == '*') // tab was modified
                        ll--;
                    if (ll < 1) continue;

                    QString numstr = tabstr.mid(spacepos + 1, ll);
                    bool ok;
                    int n = numstr.toInt(&ok);
                    if (ok && n > 0){
                        // required tab
                        v[l] = n;
                        l++;
                    }
                }
            }
            else str0 = true;
        }
    }

    if (!str0) return str;

    // bubble sort
    bool swapped;
    for (int i = 0; i < l - 1; i++) {
        swapped = false;
        for (int j = 0; j < l - i - 1; j++) {
            if (v[j] > v[j + 1]) {
                std::swap(v[j], v[j + 1]);
                swapped = true;
            }
        }
        if (swapped == false) break;
    }

    // find tentative

    int k = 0;
    while (k < l && v[k] <= tentative){ // if v[k] < tentative then it's duplicated
        if (v[k] < tentative) {/* duplicated values */}
        else if (v[k] == tentative) tentative++;
        else break; // found
        k++;
    }

    // return

    return str + " " + QString::number(tentative);
}

/* TabListToolButton */



TabListToolButton::TabListToolButton(QWidget *parent): QToolButton(parent)
{
    setMinimumWidth(17);
    setMaximumWidth(17);

    setText("");
    setIconSize(QSize(15, 15));
    setIcon(QIcon(":/img/arrdown.png"));
    setStyleSheet("QToolButton::menu-indicator { image: none; }");
}

TabListToolButton::~TabListToolButton() = default;

void TabListToolButton::initialize(PageTabs *t)
{
    if (t == nullptr) return;
    pagetabs = t;

    thegroup = new QActionGroup(this);

    thegroup->setExclusive(true);

    themenu = new QMenu(this);

    setPopupMode(QToolButton::DelayedPopup);
    setMenu(themenu);
}

void TabListToolButton::mousePressEvent(QMouseEvent *event)
{
    prepareTheMenu();
    QToolButton::mousePressEvent(event);
    showMenu();
}

void TabListToolButton::tabSheetAction(TabSheet *sheet, bool added)
{
    if (added)
        thegroup->addAction(sheet->theaction);
    else
        thegroup->removeAction(sheet->theaction);
}

void TabListToolButton::prepareTheMenu()
{
    themenu->clear();
    for (int i = 0; i < pagetabs->count(); i++)
        themenu->addAction(pagetabs->tabAction(i));
}

/* TabSheet */

TabSheet::TabSheet(QWidget *parent): QWidget(parent)
{

}

TabSheet::~TabSheet() = default;

void TabSheet::initialize(PageTabs *pagetabs, const QString &filename)
{
    thelayout = new QVBoxLayout(this);
    thelayout->setContentsMargins(0, 0, 0, 0);

    theaction = new QAction(this);
    theaction->setCheckable(true);
    theaction->setChecked(false);
    connect(theaction, SIGNAL(triggered(bool)), this, SLOT(onActionTriggered(bool)));

    if (!isShellTabSheet()){
        theeditor = new CodeEditor(this);
        QSizePolicy sp = theeditor->sizePolicy();
        sp.setVerticalPolicy(QSizePolicy::Expanding);
        sp.setHorizontalPolicy(QSizePolicy::Expanding);
        theeditor->setSizePolicy(sp);
        thelayout->addWidget(theeditor);
        theeditor->document()->setDocumentMargin(2);
        theeditor->setFrameShape(QFrame::NoFrame);

        if (filename != "")
            loadFromFile(filename);
        else{
            title = newTabTitle(pagetabs);
            icon = QIcon(":/img/fx-tab.png"); // default is fx script
            setLanguage("fx");
            theaction->setText(title);
            theaction->setToolTip(this->filename);
            theaction->setIcon(icon);
        }

        connect(theeditor, SIGNAL(modificationChanged(bool)), this, SLOT(onModifiedChanged(bool)));
        connect(theeditor, SIGNAL(undoAvailable(bool)), this, SLOT(onUndoAvailable(bool)));
        connect(theeditor, SIGNAL(redoAvailable(bool)), this, SLOT(onRedoAvailable(bool)));
        connect(theeditor, SIGNAL(selectionChanged()), this, SLOT(onSelectionChanged()));
        connect(theeditor, SIGNAL(cursorPositionChanged()), this, SLOT(onCoordinatesChanged()));

        theeditor->modified(false);
    }

    thepagetabs = pagetabs;
}

void TabSheet::finalize(PageTabs *pagetabs)
{
    if (pagetabs == thepagetabs)
        thepagetabs = nullptr;

}

bool TabSheet::loadFromFile(const QString &filename)
{
    if (theeditor){
        if (theeditor->loadFromFile(filename)){
            QFileInfo file(filename);
            title = file.fileName();
            this->filename = filename;
            emit captionChanged(this);
            setLanguage(file.suffix());
            theaction->setText(title);
            theaction->setToolTip(this->filename);
            theaction->setIcon(icon);
            return true;
        }
    }
    return false;
}

bool TabSheet::saveToFile(const QString &filename)
{
    if (theeditor){
        if (theeditor->saveToFile(filename)){
            QFileInfo file(filename);
            title = file.fileName();
            this->filename = filename;
            emit captionChanged(this);
            setLanguage(file.suffix());
            theaction->setText(title);
            theaction->setToolTip(this->filename);
            theaction->setIcon(icon);
            return true;
        }
    }

    return false;
}

void TabSheet::applySettings(QJsonDocument *settings)
{
    needssettings = true;
    checkSettings(settings);
}

void TabSheet::checkSettings(QJsonDocument *settings)
{
    if (!thepagetabs) return;
    if ((thepagetabs->currentWidget() == this) && needssettings){
        if (theeditor){
            //# read the settings from json
            theeditor->theHighlighter()->refresh();
        }
        needssettings = false;
    }
}

void TabSheet::setLanguage(const QString &l)
{
    if (theeditor && l != thelanguage){
        thelanguage = l;
        if ((l == "fx")){
            FXHighlighter *h = new FXHighlighter(nullptr);
            theeditor->setHighlighter(h);
            icon = QIcon(":/img/fx-tab.png");
        }
        else if (l == "json"){
            JSONHighlighter *h = new JSONHighlighter(nullptr);
            theeditor->setHighlighter(h);
            icon = QIcon(":/img/json-tab.png");
        }
        else {
            Highlighter *h = new Highlighter(nullptr);
            theeditor->setHighlighter(h);
            icon = QIcon(":/img/txt-tab.png");
        }
        emit captionChanged(this);
    }
}

bool TabSheet::isModified()
{
    if(theeditor) return theeditor->document()->isModified();
    return false;
}

void TabSheet::onModifiedChanged(bool m)
{
    emit captionChanged(this);
    if (thepagetabs) thepagetabs->doTabSheetModifiedChanged(this, m);
}

void TabSheet::onUndoAvailable(bool b)
{
    if (thepagetabs) thepagetabs->doTabUndoAvailable(this, b);
}

void TabSheet::onRedoAvailable(bool b)
{
    if (thepagetabs) thepagetabs->doTabRedoAvailable(this, b);
}

void TabSheet::onSelectionChanged()
{
    if (thepagetabs) thepagetabs->doTabSelectionChanged(this);
}

void TabSheet::onCoordinatesChanged()
{
    if (thepagetabs) thepagetabs->doTabCoordinatesChanged(this);
}

void TabSheet::onActionTriggered(bool)
{
    if (thepagetabs) thepagetabs->setCurrentWidget(this);
}

/* ShellTabSheet */

ShellTabSheet::ShellTabSheet(QWidget *parent): TabSheet(parent)
{

}

ShellTabSheet::~ShellTabSheet()
{

}

void ShellTabSheet::initialize(PageTabs *pagetabs, const QString &filename)
{
    TabSheet::initialize(pagetabs, filename);
    thepagetabs = nullptr;

    theconsole = new Console(this);
    QSizePolicy sp = theconsole->sizePolicy();
    sp.setVerticalPolicy(QSizePolicy::Expanding);
    sp.setHorizontalPolicy(QSizePolicy::Expanding);
    theconsole->setSizePolicy(sp);
    thelayout->addWidget(theconsole);
    theconsole->document()->setDocumentMargin(2);
    theconsole->setFrameShape(QFrame::NoFrame);


    thelanguage = "shell";
    icon = QIcon(":/img/shell-tab.png");
    if (filename != "")
        loadFromFile(filename);
    else{
        title = newTabTitle(pagetabs, true);
        theaction->setText(title);
        theaction->setToolTip(this->filename);
        theaction->setIcon(icon);
    }

    connect(theconsole, SIGNAL(modificationChanged(bool)), this, SLOT(onModifiedChanged(bool)));
    connect(theconsole, SIGNAL(undoAvailable(bool)), this, SLOT(onUndoAvailable(bool)));
    connect(theconsole, SIGNAL(redoAvailable(bool)), this, SLOT(onRedoAvailable(bool)));
    connect(theconsole, SIGNAL(selectionChanged()), this, SLOT(onSelectionChanged()));
    connect(theconsole, SIGNAL(cursorPositionChanged()), this, SLOT(onCoordinatesChanged()));
    connect(theconsole, SIGNAL(evaluating(bool)), this, SLOT(onEvaluating(bool)));
    connect(theconsole, SIGNAL(exiting()), this, SLOT(onExiting()));
    connect(theconsole, SIGNAL(started()), this, SLOT(onStarted()));

    theconsole->modified(false);

    thepagetabs = pagetabs;
}

void ShellTabSheet::finalize(PageTabs *pagetabs)
{
    TabSheet::finalize(pagetabs);
}

bool ShellTabSheet::loadFromFile(const QString &filename)
{
    if (theconsole->loadFromFile(filename)){
        QFileInfo file(filename);
        title = file.fileName();
        this->filename = filename;
        theaction->setText(title);
        theaction->setToolTip(this->filename);
        theaction->setIcon(icon);
        emit captionChanged(this);
        return true;
    }
    return false;
}

bool ShellTabSheet::saveToFile(const QString &filename)
{
    if (theconsole->saveToFile(filename)){
        QFileInfo file(filename);
        title = file.fileName();
        this->filename = filename;
        theaction->setText(title);
        theaction->setToolTip(this->filename);
        theaction->setIcon(icon);
        emit captionChanged(this);
        return true;
    }
    return false;
}

void ShellTabSheet::checkSettings(QJsonDocument *settings)
{
    if (!thepagetabs) return;
    if ((thepagetabs->currentWidget() == this) && needssettings){
        //# console: read the configuration from json
        theconsole->theHighlighter()->refresh();
        //# shell: read the configuration from json
    }
    TabSheet::checkSettings(settings);
}

bool ShellTabSheet::isModified()
{
    if(theconsole) return theconsole->document()->isModified();
    return false;
}

void ShellTabSheet::onEvaluating(bool b)
{
    if (thepagetabs) thepagetabs->doTabEvaluating(this, b);
}

void ShellTabSheet::onExiting()
{
    if (thepagetabs) thepagetabs->doTabExiting(this);
}

void ShellTabSheet::onStarted()
{
    if (thepagetabs) thepagetabs->doTabStarted(this);
}

/* PageTabs */

PageTabs::PageTabs(QWidget *parent): QTabWidget(parent)
{
    listbutton = new TabListToolButton(this);
    listbutton->initialize(this);

    connect(this, SIGNAL(currentChanged(int)), this, SLOT(onCurrentChanged(int)));

    QSizePolicy sp = listbutton->sizePolicy();
    sp.setVerticalPolicy(QSizePolicy::Expanding);
    sp.setHeightForWidth(listbutton->sizePolicy().hasHeightForWidth());
    listbutton->setSizePolicy(sp);

    cornerwidget = new QWidget(this);
    cornerlayout = new QHBoxLayout(cornerwidget);
    cornerlayout->addWidget(listbutton);
    cornerlayout->setContentsMargins(0, 0, 0, 0);


    // QSizePolicy cp = cornerwidget->sizePolicy();
    // cp.setVerticalPolicy(QSizePolicy::Expanding);
    // cp.setHeightForWidth(cornerwidget->sizePolicy().hasHeightForWidth());
    // cornerwidget->setSizePolicy(cp);

    setCornerWidget(cornerwidget);
    cornerwidget->setVisible(true);
    listbutton->setVisible(true);
}

PageTabs::~PageTabs() = default;

TabSheet *PageTabs::appendTabSheet(const QString &filename)
{
    TabSheet *sheet = new TabSheet(this);
    sheet->initialize(this, filename);
    addTab(sheet, sheet->icon, sheet->title);
    listbutton->tabSheetAction(sheet, true);
    connect(sheet, SIGNAL(captionChanged(TabSheet*)), this, SLOT(onTabCaptionChanged(TabSheet*)));
    setCurrentIndex(count() - 1);
    emit tabSheetAdded(sheet);
    return sheet;
}

ShellTabSheet *PageTabs::appendShellTabSheet(const QString &filename)
{
    ShellTabSheet *sheet = new ShellTabSheet(this);
    sheet->initialize(this, filename);
    addTab(sheet, sheet->icon, sheet->title);
    listbutton->tabSheetAction(sheet, true);
    connect(sheet, SIGNAL(captionChanged(TabSheet*)), this, SLOT(onTabCaptionChanged(TabSheet*)));
    setCurrentIndex(count() - 1);
    emit tabSheetAdded(sheet);
    sheet->theconsole->initialize();

    sheet->theconsole->makePure();
    return sheet;
}

TabSheet *PageTabs::removeTabSheet(int index)
{
    qDebug("removing tabsheet");
    TabSheet *sheet = tabSheet(index);
    disconnect(sheet, SIGNAL(captionChanged(TabSheet*)), this, SLOT(onTabCaptionChanged(TabSheet*)));
    qDebug("removing tabsheet 2");
    sheet->finalize(this);
    qDebug("sheet->finalize(this)");
    listbutton->tabSheetAction(sheet, false);
    qDebug("listbutton->tabSheetAction(sheet, false);");
    removeTab(index);
    qDebug("removeTab(index);");
    if (currentTabSheet())
        currentTabSheet()->theaction->setChecked(true); //!
    qDebug("if (currentTabSheet())");
    sheet->setParent(nullptr);
    qDebug("sheet->setParent(nullptr)");
    emit tabSheetRemoved(sheet);
    return sheet;
}

void PageTabs::deleteTabSheet(int index)
{
    TabSheet *sheet = removeTabSheet(index);
    qDebug("deleting tabsheet");
    if (sheet) delete(sheet);
    qDebug("deleted tabsheet");
}

void PageTabs::applySettings(QJsonDocument *settings)
{
    // apply theme

    // apply settings for console, shell and editor
    for (int i = 0; i < count(); i ++)
        tabSheet(i)->applySettings(settings);
    // store settings
    thesettings = settings;
}

QAction *PageTabs::tabAction(int index)
{
    TabSheet *sheet = tabSheet(index);
    if (sheet)
        return sheet->theaction;
    return nullptr;
}

TabSheet *PageTabs::tabSheet(int index)
{
    QWidget *w = widget(index);
    return qobject_cast<TabSheet *>(w);
}

TabSheet *PageTabs::currentTabSheet()
{
    return tabSheet(currentIndex());
}

void PageTabs::onCurrentChanged(int index)
{
    TabSheet *sheet = tabSheet(index);
    if (sheet){
        sheet->checkSettings(thesettings);
        sheet->theaction->setChecked(true);
    }
}

void PageTabs::onTabCaptionChanged(TabSheet *me)
{
    if (me->isModified())
        setTabText(me->index(), me->title + "*");
    else
        setTabText(me->index(), me->title);
    setTabIcon(me->index(), me->icon);
    emit tabSheetCaptionChanged(me);
}

void PageTabs::tabInserted(int index)
{
    QTabWidget::tabInserted(index);
    fillIndexes(index);
}

void PageTabs::tabRemoved(int index)
{
    QTabWidget::tabRemoved(index);
    fillIndexes(index);
}

void PageTabs::doTabSheetModifiedChanged(TabSheet *sheet, bool m)
{
    emit tabSheetModifiedChanged(sheet, m);
}

void PageTabs::doTabUndoAvailable(TabSheet *sheet, bool b)
{
    emit tabUndoAvailable(sheet, b);
}

void PageTabs::doTabRedoAvailable(TabSheet *sheet, bool b)
{
    emit tabRedoAvailable(sheet, b);
}

void PageTabs::doTabSelectionChanged(TabSheet *sheet)
{
    emit tabSelectionChanged(sheet);
}

void PageTabs::doTabCoordinatesChanged(TabSheet *sheet)
{
    emit tabCoordinatesChanged(sheet);
}

void PageTabs::doTabEvaluating(TabSheet *sheet, bool b)
{
    emit tabEvaluating(sheet, b);
}

void PageTabs::doTabExiting(TabSheet *sheet)
{
    qDebug("emit tabExiting(sheet)###########");
    emit tabExiting(sheet);
    qDebug("emited tabExiting(sheet)###########");
}

void PageTabs::doTabStarted(TabSheet *sheet)
{
    emit tabStarted(sheet);
}

void PageTabs::fillIndexes(int from)
{
    for (int i = from; i < count(); i++) tabSheet(i)->theindex = i;
}
