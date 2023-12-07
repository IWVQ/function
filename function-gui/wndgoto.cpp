#include "wndgoto.h"
#include "ui_wndgoto.h"

WndGoto::WndGoto(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::WndGoto)
{
    ui->setupUi(this);
    setWindowFlags(Qt::Window | Qt::FramelessWindowHint | Qt::Popup);
}

WndGoto::~WndGoto()
{
    delete ui;
}

void WndGoto::showGoto(const QTextCursor &c)
{
    show();
    raise();

    ui->editLineY->setText(QString::number(c.blockNumber()));
    ui->editColX->setText(QString::number(c.columnNumber()));
    ui->editLineY->setFocus();
}

void WndGoto::paintEvent(QPaintEvent *event)
{
    QDialog::paintEvent(event);
    QPainter painter(this);
    painter.setBrush(Qt::NoBrush);
    painter.setPen(Qt::gray);
    QRect r(0, 0, width() - 1, height() - 1);
    painter.drawRect(r);
}

void WndGoto::on_editColX_returnPressed()
{
    on_toolButton_clicked();
}


void WndGoto::on_editLineY_returnPressed()
{
    on_toolButton_clicked();
}


void WndGoto::on_toolButton_clicked()
{
    bool ok;
    int l = ui->editLineY->text().toInt(&ok);
    if (!ok) return;
    int c = ui->editColX->text().toInt(&ok);
    if (!ok) return;
    close();
    emit gotoPressed(l, c);
}

