#ifndef WNDGOTO_H
#define WNDGOTO_H

#include <QtWidgets>
#include <QDialog>

namespace Ui {
class WndGoto;
}

class WndGoto : public QDialog
{
    Q_OBJECT

public:
    explicit WndGoto(QWidget *parent = nullptr);
    ~WndGoto();

    void showGoto(const QTextCursor &c);
signals:
    void gotoPressed(int line, int col);
protected:
    void paintEvent(QPaintEvent *event) override;
private slots:
    void on_editColX_returnPressed();

    void on_editLineY_returnPressed();

    void on_toolButton_clicked();

private:
    Ui::WndGoto *ui;
};

#endif // WNDGOTO_H
