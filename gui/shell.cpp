#include "shell.h"
#include <stdio.h>
#include <string.h>

/* SHELL */

Shell::Shell(QObject *parent): QThread(parent)
{
    QTextCharFormat f;
    f.setFontFamily("Courier New");
    f.setFontPointSize(9);
    f.setFontFixedPitch(true);

    f.setForeground(Qt::red);
    errorformat = f;
    f.setForeground(Qt::darkBlue);
    bannerformat = f;
    f.setForeground(Qt::darkMagenta);
    consoleformat = f;
}

Shell::~Shell()
{
    qDebug("deleting shell");
    mutex.lock();
    qDebug("mutex.lock()");
    exit = true;
    qDebug("exit = true");
    if (evaluating)
        fx_call_interrupt(kernel);
    qDebug("fx_interrupt(kernel);");
    sleepcondition.wakeAll();
    qDebug("sleepcondition.wakeAll();");
    mutex.unlock();
    qDebug("mutex.unlock();");
    wait();
    qDebug("wait();");
}

void Shell::run()
{

    // header
    qDebug("writing header");
    writeBanner();
    // create kernel
    qDebug("creating kernel");
    QByteArray b = filetoopen.toUtf8();
    KernelData d;
    d.str = b.data();
    d.len = b.length();
    KernelParam callback = reinterpret_cast<KernelParam>(&fx_callback); //#
    kernel = fx_call_create(reinterpret_cast<KernelParam>(this),
                       reinterpret_cast<KernelParam>(&d),
                       callback); //#

    do{
        qDebug("reading something");
        QString input = readInput();
        if (exit) break;
        QByteArray b = input.toUtf8();
        d.str = b.data(); // no problem, this doesn't needs to grab
        d.len = b.length();

        // evaluate
        evaluating = true;
        sendMessage(SHELL_EVALUATING);
        qDebug("evaluating something");
        fx_call_input(kernel, reinterpret_cast<KernelParam>(&d));
        qDebug("running");
        KernelParam res = fx_call_run(kernel);
        qDebug("runned");
        evaluating = false;
        sendMessage(SHELL_EVALUATED);

        if (res == FX_EXIT){
            qDebug("res == FX_EXIT");
            qDebug("sendMessage(SHELL_EXIT)");
            sendMessage(SHELL_EXIT);
            qDebug("before SHELL_EXIT");
            // if not closed then continue running
        }

    }while(!exit);
    qDebug("shell exited");

    fx_call_destroy(kernel);
    kernel = 0;
}


KernelParam Shell::callback(KernelParam code, KernelData *data)
{
    if (exit) return 0;

    if (code == FX_KER_NOTHING){}
    else if (code == FX_KER_PAUSED){
        const QMutexLocker locker(&mutex);
        qDebug("pause: thread sleep");
        sleepcondition.wait(&mutex);
        qDebug("pause: thread wake up");
        fx_call_resume(kernel);
        paused = false;
    }
    else if (code == FX_KER_READ){
        QString s = read();
        QByteArray b = s.toUtf8();
        KernelData d;
        d.str = b.data();
        d.len = b.length();
        fx_call_input(kernel, reinterpret_cast<KernelParam>(&d));
    }
    else if (code == FX_KER_WRITE){
        format(consoleformat);
        QString s = QString::fromUtf8(data->str, data->len);
        write(s);
    }
    else if (code == FX_KER_OUTPUT){
        QString s = QString::fromUtf8(data->str, data->len);
        writeOutput(s);
    }
    else if (code == FX_KER_ERROR){
        QString s = QString::fromUtf8(data->str, data->len);
        writeError(s);
    }
    else if (code == FX_KER_CLRSCR){
        clrscr();
    }
    return 0;
}

void Shell::pause()
{
    const QMutexLocker locker(&mutex);
    if (isRunning() && evaluating && !paused){
        paused = true;
        fx_call_pause(kernel);
    }
}

void Shell::resume()
{
    const QMutexLocker locker(&mutex);
    if (isRunning() && evaluating && paused){
        if (reading) // don't wake up
            fx_call_resume(kernel);
        else
            sleepcondition.wakeAll();
    }
}

void Shell::interrupt()
{
    const QMutexLocker locker(&mutex);
    if (isRunning() && evaluating){
        fx_call_interrupt(kernel);
        if (paused || reading)
            sleepcondition.wakeAll();
    }
}

bool Shell::loadFromFile(const QString &filename)
{
    const QMutexLocker locker(&mutex); // for main thread
    if (isRunning())
        return false; // cann't open if already running
    else{
        filetoopen = filename;
        return true;
    }
    return false;
}

bool Shell::saveToFile(const QString &filename)
{
    const QMutexLocker locker(&mutex);
    if (isRunning() && !evaluating){
        QByteArray b = filename.toUtf8();
        KernelData d;
        d.str = b.data();
        d.len = b.length();
        fx_call_save(kernel, reinterpret_cast<KernelParam>(&d));
    }
    return false;
}

bool Shell::canRead(QKeyEvent *returnkeyevent)
{
    if (isRunning()){
        if (evaluating) return true;
        else if (embeddedprompter){
            if (returnkeyevent->modifiers() & Qt::ShiftModifier) return true;
            else return false;
        }
        else
            return true;
    }
    return true;
}

QString Shell::arrowPrompter()
{
    return ">>> ";
}

QString Shell::spacePrompter()
{
    return "... ";
}

QString Shell::readInput()
{
    cell(CELL_INPUT);
    QString str = "";
    if (embeddedprompter){
        str = read();
    }
    else{
        bool multiline = false;
        bool canreadnewline = true;
        while (canreadnewline) {
            if (exit) return ""; // avoids infinite loop
            qDebug("writing prompter");
            writePrompter(multiline);
            if (!started){
                // first prompter
                sendMessage(SHELL_STARTED);
                started = true;
            }
            qDebug("starting to read");
            QString s = read();
            qDebug("exit after read 1");
            //if (exit) return ""; // check why
            if (s == "")
                canreadnewline = false;
            else{
                if (multiline) str.append("\n" + s);
                else str.append(s);
                canreadnewline = true;
            }
            if (canreadnewline) multiline = true;
            qDebug("exit after read 2");
        }
        if (multiline){
            // remove last prompter
            QPoint p = whereXY();
            clrscr(p.y() - 1);
        }
        qDebug("exit after read 3");
    }
    qDebug("exit after read 4");
    cell(CELL_CONSOLE, false);
    qDebug("exit after read 5");
    return str;
}

void Shell::writeOutput(const QString &s)
{
    cell(CELL_OUTPUT);
    write(s);
    cell(CELL_CONSOLE);
}

void Shell::writeError(const QString &s)
{
    format(errorformat);
    write(s + "\n");
}

void Shell::writePrompter(bool multiline)
{
    qDebug("writing a prompter to ");
    if (multiline)
        write(spacePrompter());
    else
        write(arrowPrompter());
}

void Shell::writeBanner()
{
    cell(CELL_CONSOLE, false);
    format(bannerformat);
    write(FUNCTION_BANNER_STR);
}

// console

void Shell::response(int m, qint64 l, qint64 r)
{
    if (isRunning() && m == currmsg){
        resl = l;
        resr = r;
        if (m == SHELL_READ){
            QString *s = reinterpret_cast<QString *>(resl);
            readedstr = *s;
            readedstr.detach(); // creates detached copy
        }
        sleepcondition.wakeAll();
    }
}

void Shell::sendMessage(int m, qint64 l, qint64 r)
{
    const QMutexLocker locker(&mutex);
    if (exit) return; // avoids to sleep again
    currmsg = m;
    if (m == SHELL_READ) reading = true;
    emit message(m, l, r);
    sleepcondition.wait(&mutex);
    if (m == SHELL_READ) reading = false;
}

void Shell::cell(int cell, bool newline)
{
    sendMessage(SHELL_CELL, cell, static_cast<int>(newline));
}

void Shell::format(const QTextCharFormat &f)
{
    sendMessage(SHELL_FORMAT, reinterpret_cast<qint64>(&f), 0);
}

QString Shell::read()
{
    sendMessage(SHELL_READ, 0, 0);
    return readedstr;
}

void Shell::write(const QString &s)
{
    // writtenstr = s;
    sendMessage(SHELL_WRITE, reinterpret_cast<qint64>(&s), 0);
}

void Shell::clrscr(int from)
{
    sendMessage(SHELL_CLRSCR, from, 0);
}

QPoint Shell::whereXY(bool end)
{
    //*/
    sendMessage(SHELL_WHEREXY, static_cast<int>(end), 0);
    return QPoint{static_cast<int>(resl), static_cast<int>(resr)};
    /*/
    const QMutexLocker locker(&mutex);
    if (end)
        return console->endXY();
    else
        return console->whereXY();
    //*/
}
