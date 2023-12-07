#ifndef ABOUTDIALOG_H
#define ABOUTDIALOG_H

#include <QtWidgets>
#include <QDialog>
#include "builddatetime.h"

#define FUNCTION_BANNER_STR "Function v0.5 Copyright (c) Ivar Wiligran Vilca Quispe\n" \
                            "Type Help() for more information.\n"

namespace Ui {
class AboutDialog;
}

class AboutDialog : public QDialog
{
    Q_OBJECT

public:
    explicit AboutDialog(QWidget *parent = nullptr);
    ~AboutDialog();

    void showAbout();
private slots:
    void on_pushButtonCredits_clicked();

    void on_pushButtonLicense_clicked();
protected:
    void mousePressEvent(QMouseEvent *event) override;
    void mouseReleaseEvent(QMouseEvent *event) override;
    void mouseMoveEvent(QMouseEvent *event) override;
private:
    Ui::AboutDialog *ui;
    QPoint anchor;
};

#endif // ABOUTDIALOG_H
