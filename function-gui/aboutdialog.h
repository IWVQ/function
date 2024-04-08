#ifndef ABOUTDIALOG_H
#define ABOUTDIALOG_H

#include <QtWidgets>
#include <QDialog>
#include "builddatetime.h"

#define FUNCTION_BANNER_STR "Function v0.5 Copyright (c) 2023-2024 Ivar Wiligran Vilca Quispe\n" \
                            "Type Help() for more information.\n"
#define FUNCTION_COPY_STR "Copyright (c) 2023-2024 Ivar Wiligran Vilca Quispe"
#define FUNCTION_LICENSE_NOTICE \
    "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\" \"http://www.w3.org/TR/REC-html40/strict.dtd\">\n" \
    "<html><head><meta name=\"qrichtext\" content=\"1\" /><meta charset=\"utf-8\" /><style type=\"text/css\">\n" \
    "p, li { white-space: pre-wrap; }\n" \
    "hr { height: 1px; border-width: 0; }\n" \
    "li.unchecked::marker { content: \"\\2610\"; }\n" \
    "li.checked::marker { content: \"\\2612\"; }\n" \
    "</style></head><body style=\" font-family:'Segoe UI'; font-size:9pt; font-weight:400; font-style:normal;\">\n" \
    "<p align=\"center\" style=\" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; " \
    "-qt-block-indent:0; text-indent:0px;\">This program is free software and is distributed under the " \
    " GNU General Public License, version 2.</p>\n" \
    "<p align=\"center\" style=\"-qt-paragraph-type:empty; margin-top:0px; margin-bottom:0px; " \
    " margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\"><br /></p>\n" \
    "<p align=\"center\" style=\" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-" \
    "block-indent:0; text-indent:0px;\">This program comes WITHOUT ANY WARRANTY. For more details about" \
    " the license, check <a href=\"https://www.gnu.org/licenses/old-licenses/gpl-2.0.html\"> " \
    "<span style=\" text-decoration: underline; color:#0078d7;\">this link</span></a> or read the file COPYING.</p>\n" \
    "<p align=\"center\" style=\"-qt-paragraph-type:empty; margin-top:0px; margin-bottom:0px; margin-left:0px;" \
    " margin-right:0px; -qt-block-indent:0; text-indent:0px;\"><br /></p></body></html>"
#define FUNCTION_CREDITS_TEXT \
    "<!DOCTYPE HTML PUBLIC \"-//W3C//DTD HTML 4.0//EN\" \"http://www.w3.org/TR/REC-html40/strict.dtd\">\n" \
    "<html><head><meta name=\"qrichtext\" content=\"1\" /><meta charset=\"utf-8\" /><style type=\"text/css\">\n" \
    "p, li { white-space: pre-wrap; }\n" \
    "hr { height: 1px; border-width: 0; }\n" \
    "li.unchecked::marker { content: \"\\2610\"; }\n" \
    "li.checked::marker { content: \"\\2612\"; }\n" \
    "</style></head><body style=\" font-family:'Segoe UI'; font-size:9pt; font-weight:400; font-style:normal;\">\n" \
    "<p style=\" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; " \
    "text-indent:0px;\"><span style=\" font-weight:700;\">Author</span><br />Ivar Wiligran Vilca Quispe<br />" \
    "<a href=\"iwilligramvilcaq@gmail.com\"><span style=\" text-decoration: underline; color:#0078d7;\">" \
    "iwilligramvilcaq@gmail.com </span></a></p>\n" \
    "<p style=\"-qt-paragraph-type:empty; margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px;" \
    " -qt-block-indent:0; text-indent:0px;\"><br /></p>\n" \
    "<p style=\" " \
    "margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; text-indent:0px;\">" \
    "<span style=\" font-weight:700;\">Qt 6</span></p>\n" \
    "<p style=\" margin-top:0px; margin-bottom:0px; margin-left:0px; margin-right:0px; -qt-block-indent:0; " \
    "text-indent:0px;\"><a href=\"https://www.qt.io/\"><span style=\" text-decoration: underline; color:#0078d7;\">" \
    "www.qt.io</span></a></p>\n" \
    "<p style=\" margin-top:12px; margin-bottom:12px; margin-left:0px; margin-right:0px; -qt-block-indent:0; " \
    "text-indent:0px;\"><span style=\" font-weight:700;\">Lucide icons</span><br /><a href=\"https://lucide.dev\">" \
    "<span style=\" text-decoration: underline; color:#0078d7;\">lucide.dev</span></a></p></body></html>"


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
