#include "aboutdialog.h"
#include "ui_aboutdialog.h"

AboutDialog::AboutDialog(QWidget *parent) :
    QDialog(parent),
    ui(new Ui::AboutDialog)
{
    ui->setupUi(this);

    setWindowFlags(Qt::Window | Qt::FramelessWindowHint | Qt::Popup);

    ui->textEdit->setVisible(false);
}

AboutDialog::~AboutDialog()
{
    delete ui;
}

void AboutDialog::showAbout()
{
    show();
    raise();
}

void AboutDialog::on_pushButtonCredits_clicked()
{
    ui->textEdit->setVisible(true);
}


void AboutDialog::on_pushButtonLicense_clicked()
{
    ui->textEdit->setVisible(true);
}

void AboutDialog::mousePressEvent(QMouseEvent *event)
{
    QDialog::mousePressEvent(event);
    if ((Qt::LeftButton & event->buttons()) == Qt::LeftButton){
        anchor = event->pos();
        ui->textEdit->setVisible(false);
    }
}

void AboutDialog::mouseReleaseEvent(QMouseEvent *event)
{
    QDialog::mouseReleaseEvent(event);
}

double counter = 0;

void AboutDialog::mouseMoveEvent(QMouseEvent *event)
{
    QDialog::mouseMoveEvent(event);
    if ((Qt::LeftButton & event->buttons()) == Qt::LeftButton)
        move(event->globalX() - anchor.x(), event->globalY() - anchor.y());

    qWarning() << counter;
    counter += 0.1;
}

