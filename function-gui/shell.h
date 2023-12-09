#ifndef SHELL_H
#define SHELL_H

#include <QtWidgets>
#include "codeeditor.h"
#include "consolehilite.h"
#include "aboutdialog.h"

#define SHELL_FILE "fxsh"

#define FUNCTION_KERNEL

#define FX_SUCCESS          0
#define FX_EXIT             1
#define FX_RESTARTED        2
#define FX_INTERRUPTED      3
#define FX_ERROR            4

#define FX_KER_NOTHING      0
#define FX_KER_PAUSED       1
#define FX_KER_READ         2
#define FX_KER_WRITE        3
#define FX_KER_OUTPUT       4
#define FX_KER_ERROR        5
#define FX_KER_CLRSCR       6

#define SHELL_READ          1
#define SHELL_WRITE         2
#define SHELL_FORMAT        3
#define SHELL_CELL          4
#define SHELL_CLRSCR        5
#define SHELL_WHEREXY       6
#define SHELL_EVALUATING    7
#define SHELL_EVALUATED     8
#define SHELL_EXIT          9
#define SHELL_STARTED       10

struct KernelData{
    long long int len;
    unsigned char *str = nullptr;
    KernelData(const QString &s)
    {
        QByteArray b = s.toUtf8();
        len = b.length();
        str = new unsigned char[len + 1];
        for (int i = 0; i < len; i++)
            str[i] = b[i];
        str[len] = 0;
    }

    ~KernelData()
    {
        delete [] str;
        str = nullptr;
    }
};

// union KernelDataU{KernelData d;};

typedef unsigned long long int KernelParam;

typedef KernelParam (*KernelFunction)(KernelParam, KernelParam, KernelParam);
typedef KernelFunction KernelCallback;

class KernelLibrary: public QLibrary
{
    Q_OBJECT
public:
    explicit KernelLibrary(const QString& fileName, QObject *parent = nullptr);
    ~KernelLibrary();
};

class Shell: public QThread
{
    Q_OBJECT
public:
    Shell(QObject *parent = 0);
    ~Shell();

    void run() override;
    KernelParam callback(KernelParam code, KernelData *data);

    void pause();
    void resume();
    void interrupt();

    bool loadFromFile(const QString &filename);
    bool saveToFile(const QString &filename);
    bool canRead(QKeyEvent *returnkeyevent);
    QString arrowPrompter();
    QString spacePrompter();

    bool isEvaluating(){ return evaluating; };
    bool isPaused(){ return paused; }
    bool isReading(){ return reading; }
    void response(int m, qint64 l, qint64 r);
    bool embeddedprompter = false;
    CodeEditor *console = nullptr; // the current console
signals:
    void message(int m, qint64 l, qint64 r);
protected:
    void sendMessage(int m, qint64 l = 0, qint64 r = 0);
    void cell(int cell, bool newline = true);
    void format(const QTextCharFormat &f);
    QString read();
    void write(const QString &s);
    void clrscr(int from = 0);
    QPoint whereXY(bool end = true);

    QString readInput();
    void removeLastPrompter();
    void writeOutput(const QString &s);
    void writeError(const QString &s);
    void writePrompter(bool multiline);
    void writeBanner();

    QMutex mutex;
    QWaitCondition sleepcondition;
    bool paused = false;
    bool evaluating = false;
    QString readedstr = "";
    // QString writtenstr = "";
    bool reading = false;

    QTextCharFormat errorformat;
    QTextCharFormat bannerformat;
    QTextCharFormat consoleformat;
private:
    KernelParam kernel = 0;
    bool exit = false;
    int currmsg = 0;
    qint64 resl = 0;
    qint64 resr = 0;
    bool started = false;
    QString filetoopen = "";
};



#endif // SHELL_H
