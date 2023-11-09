#include "mainwindow.h"
#include "ui_mainwindow.h"

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
    , ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    editor = new CodeEditor(ui->tab);
    editor->setObjectName(QString::fromUtf8("editor"));
    editor->setGeometry(QRect(0, 0, 700, 400));
    editor->setVisible(true);
    editor->document()->setDocumentMargin(2);
    QTextOption option = editor->document()->defaultTextOption();
    option.setFlags(QTextOption::ShowTabsAndSpaces
                    //| QTextOption::ShowLineAndParagraphSeparators
                    //| QTextOption::AddSpaceForLineAndParagraphSeparators
                    //| QTextOption::ShowDocumentTerminator
                    //| QTextOption::IncludeTrailingSpaces
                    //| QTextOption::SuppressColors
                    );
    editor->document()->setDefaultTextOption(option);
}

MainWindow::~MainWindow()
{
    delete editor;
    delete ui;
}


void MainWindow::on_pushButton_12_clicked()
{
    editor->zoomIn(2);
}


void MainWindow::on_pushButton_13_clicked()
{
    //editor->test_status_saved();
}


void MainWindow::on_pushButton_14_clicked()
{
    //editor->test_status_virgin();
}


void MainWindow::on_pushButton_15_clicked()
{
    editor->setLineWrapMode(QPlainTextEdit::WidgetWidth);
}


void MainWindow::on_pushButton_16_clicked()
{
    editor->setReadOnly(not editor->isReadOnly());
}


void MainWindow::on_spinBox_valueChanged(int arg1)
{
    //editor->readonlylineto = arg1;
    editor->document()->clearUndoRedoStacks();
}


void MainWindow::on_pushButton_17_clicked()
{
    // insert red span

    QTextCharFormat format = editor->currentCharFormat();
    format.setFontFamily("Courier New");
    format.setFontFixedPitch(true);
    format.setForeground(Qt::red);
    editor->setCurrentCharFormat(format);

    editor->insertPlainText("insert red");
}


void MainWindow::on_pushButton_18_clicked()
{
    // insert green span

    QTextCharFormat format = editor->currentCharFormat();
    format.setFontFamily("Courier New");
    format.setFontFixedPitch(true);
    format.setForeground(Qt::darkGreen);
    editor->setCurrentCharFormat(format);

    editor->insertPlainText("green and more \ngreen");
}

void MainWindow::on_pushButton_19_clicked()
{
    QTextCharFormat format = editor->currentCharFormat();
    format.setFontFamily("Courier New");
    format.setFontFixedPitch(true);
    format.setForeground(Qt::blue);
    editor->setCurrentCharFormat(format);

    editor->appendPlainText("append blue");
}

