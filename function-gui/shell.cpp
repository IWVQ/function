#include "shell.h"
#include <stdio.h>
#include <string.h>

#ifdef FUNCTION_KERNEL

KernelFunction fx_call_shell     = nullptr;
KernelFunction fx_call_create    = nullptr;
KernelFunction fx_call_destroy   = nullptr;
KernelFunction fx_call_input     = nullptr;
KernelFunction fx_call_run       = nullptr;
KernelFunction fx_call_pause     = nullptr;
KernelFunction fx_call_resume    = nullptr;
KernelFunction fx_call_interrupt = nullptr;
KernelFunction fx_call_save      = nullptr;

KernelLibrary kernellib("fxkernel");

#else

KernelParam fx_call_shell(KernelParam kernel, KernelParam, KernelParam);
KernelParam fx_call_create(KernelParam shell, KernelParam file, KernelParam callback);
KernelParam fx_call_destroy(KernelParam kernel, KernelParam, KernelParam);
KernelParam fx_call_input(KernelParam kernel, KernelParam data, KernelParam);
KernelParam fx_call_run(KernelParam kernel, KernelParam, KernelParam);
KernelParam fx_call_pause(KernelParam kernel, KernelParam, KernelParam);
KernelParam fx_call_resume(KernelParam kernel, KernelParam, KernelParam);
KernelParam fx_call_interrupt(KernelParam kernel, KernelParam, KernelParam);
KernelParam fx_call_save(KernelParam kernel, KernelParam data, KernelParam);

#endif

KernelParam fx_callback(KernelParam kernel, KernelParam code, KernelParam data)
{/*
    if (data){
        qDebug("calling the callback from kernel.pas");
        KernelData *d = reinterpret_cast<KernelData *>(data);
        qDebug(reinterpret_cast<char*>(d->str));
    }
    else
        qDebug("fx_callback");
*/
    Shell *shell = reinterpret_cast<Shell *>(fx_call_shell(kernel, 0, 0));
    if (shell){
        qDebug("fx_callback shell->callback");
        return shell->callback(code, reinterpret_cast<KernelData *>(data));
        qDebug("fx_callback shell->callback --- after");
    }
    else return 0;
}


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
        fx_call_interrupt(kernel, 0, 0);
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
    KernelData d(filetoopen);
    KernelParam callback = reinterpret_cast<KernelParam>(&fx_callback); //#
    kernel = fx_call_create(reinterpret_cast<KernelParam>(this),
                       reinterpret_cast<KernelParam>(&d),
                       callback); //#

    do{
        qDebug("reading something");
        QString input = readInput();
        if (exit) break;
        KernelData d(input);
        qDebug("---------------- d.str = %llu -----------------", KernelParam(d.str));
        qDebug("---------------- &d.str = %llu -----------------", KernelParam(&(d.str)));
        qDebug("---------------- &d.len = %llu -----------------", KernelParam(&(d.len)));
        qDebug("---------------- &d = %llu -----------------", KernelParam(&d));
        qDebug("---------------- *d.str = %d --------------", qint32(*(d.str)));

        // evaluate
        evaluating = true;
        sendMessage(SHELL_EVALUATING);
        qDebug("evaluating something");
        fx_call_input(kernel, reinterpret_cast<KernelParam>(&d), callback); //# remove callback
        qDebug("running");
        KernelParam res = fx_call_run(kernel, 0, 0);
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

    fx_call_destroy(kernel, 0, 0);
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
        fx_call_resume(kernel, 0, 0);
        paused = false;
    }
    else if (code == FX_KER_READ){
        QString s = read();
        KernelData d(s);
        fx_call_input(kernel, reinterpret_cast<KernelParam>(&d), 0);
    }
    else if (code == FX_KER_WRITE){
        format(consoleformat);
        QString s = QString::fromUtf8(reinterpret_cast<char*>(data->str), data->len);
        write(s);
    }
    else if (code == FX_KER_OUTPUT){
        QString s = QString::fromUtf8(reinterpret_cast<char*>(data->str), data->len);
        writeOutput(s);
    }
    else if (code == FX_KER_ERROR){
        QString s = QString::fromUtf8(reinterpret_cast<char*>(data->str), data->len);
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
        fx_call_pause(kernel, 0, 0);
    }
}

void Shell::resume()
{
    const QMutexLocker locker(&mutex);
    if (isRunning() && evaluating && paused){
        if (reading) // don't wake up
            fx_call_resume(kernel, 0, 0);
        else
            sleepcondition.wakeAll();
    }
}

void Shell::interrupt()
{
    const QMutexLocker locker(&mutex);
    if (isRunning() && evaluating){
        fx_call_interrupt(kernel, 0, 0);
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
        KernelData d(filename);
        fx_call_save(kernel, reinterpret_cast<KernelParam>(&d), 0);
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



/* KERNEL */

#ifdef FUNCTION_KERNEL

/* library */

KernelLibrary::KernelLibrary(const QString& fileName, QObject *parent):
    QLibrary(fileName, parent)
{
    fx_call_shell     = (KernelFunction)resolve("fx_call_shell");
    fx_call_create    = (KernelFunction)resolve("fx_call_create");
    fx_call_destroy   = (KernelFunction)resolve("fx_call_destroy");
    fx_call_input     = (KernelFunction)resolve("fx_call_input");
    fx_call_run       = (KernelFunction)resolve("fx_call_run");
    fx_call_pause     = (KernelFunction)resolve("fx_call_pause");
    fx_call_resume    = (KernelFunction)resolve("fx_call_resume");
    fx_call_interrupt = (KernelFunction)resolve("fx_call_interrupt");
    fx_call_save      = (KernelFunction)resolve("fx_call_save");

    if (!fx_call_shell    ) qDebug("Kernel: error loading fx_call_shell    ");
    if (!fx_call_create   ) qDebug("Kernel: error loading fx_call_create   ");
    if (!fx_call_destroy  ) qDebug("Kernel: error loading fx_call_destroy  ");
    if (!fx_call_input    ) qDebug("Kernel: error loading fx_call_input    ");
    if (!fx_call_run      ) qDebug("Kernel: error loading fx_call_run      ");
    if (!fx_call_pause    ) qDebug("Kernel: error loading fx_call_pause    ");
    if (!fx_call_resume   ) qDebug("Kernel: error loading fx_call_resume   ");
    if (!fx_call_interrupt) qDebug("Kernel: error loading fx_call_interrupt");
    if (!fx_call_save     ) qDebug("Kernel: error loading fx_call_save     ");

    QString s = "Kernel: " + errorString() + "------";
    qDebug(s.toUtf8());
}

KernelLibrary::~KernelLibrary() = default;

#else

class FakeKernel
{
public:
    FakeKernel(KernelParam shell, KernelData *file, KernelCallback callback)
    {
        this->shell = shell;
        this->callback = callback;
        if (file->len == 0) // use len instead str==null
            qDebug("no file loaded on creating kernel");
        else
            qDebug("file loaded on creating kernel");
    }

    ~FakeKernel()
    {

    }

    void doSomethingInLoop()
    {
        // do nothing
        if (pause){
            callback(reinterpret_cast<KernelParam>(this), FX_KER_PAUSED, 0);

        }
    }

    void save()
    {
        qDebug("kernel saved");
    }

    void load()
    {
        qDebug("kernel loaded");
    }

    KernelParam shell;
    char *input = nullptr;
    int inputlen = 0;
    bool pause = false;
    bool stop = false;
    KernelCallback callback;
    long long unsigned int run()
    {
        stop = false;

        QString s = QString::fromUtf8(input, inputlen);
        KernelData d;
        d.str = nullptr;
        d.len = 0;

        qDebug("FakeKernel.run() %s", d.str);

        KernelParam code = 0;

        long long unsigned int res = 0;

        if (s == "clrscr") {
            code = FX_KER_CLRSCR;
            res = callback(reinterpret_cast<KernelParam>(this),
                                                 code,
                                                 reinterpret_cast<KernelParam>(&d));
        }
        else if (s == "read") {
            // write a prompter
            code = FX_KER_WRITE;
            QString output = "--> ";
            QByteArray b = output.toUtf8();
            d.str = b.data();
            d.len = output.length();

            res = callback(reinterpret_cast<KernelParam>(this),
                                                 code,
                                                 reinterpret_cast<KernelParam>(&d));
            // read some string
            code = FX_KER_READ;
            d.str = nullptr;
            d.len = 0;

            res = callback(reinterpret_cast<KernelParam>(this),
                                                 code,
                                                 reinterpret_cast<KernelParam>(&d));
            if (stop) goto LBL_STOPPED;

            // print readed string
            code = FX_KER_WRITE;
            output = QString::fromUtf8(input, inputlen);
            output = "readed: " + output + "\n";
            b = output.toUtf8();
            d.str = b.data();
            d.len = output.length();

            res = callback(reinterpret_cast<KernelParam>(this),
                                                 code,
                                                 reinterpret_cast<KernelParam>(&d));

        }
        else if (s == "write") {
            code = FX_KER_WRITE;
            QString output = "write: blablablabla\n";
            QByteArray b = output.toUtf8();
            d.str = b.data();
            d.len = output.length();

            res = callback(reinterpret_cast<KernelParam>(this),
                                                 code,
                                                 reinterpret_cast<KernelParam>(&d));
        }
        else if (s == "error") {
            code = FX_KER_ERROR;
            QString output = "error: \"error\" entered";
            QByteArray b = output.toUtf8();
            d.str = b.data();
            d.len = output.length();

            res = callback(reinterpret_cast<KernelParam>(this),
                                                 code,
                                                 reinterpret_cast<KernelParam>(&d));
        }
        else if (s == "loop") {
            while(!stop){
                doSomethingInLoop();
                // qDebug("looping");
            }
        }
        else if (s == "exit"){
            qDebug("exiting");
            return FX_EXIT;
        }
        else{
            code = FX_KER_OUTPUT;
            QString output = "ans = " + s;
            QByteArray b = output.toUtf8();
            d.str = b.data();
            d.len = output.length();

            res = callback(reinterpret_cast<KernelParam>(this),
                                                 code,
                                                 reinterpret_cast<KernelParam>(&d));
        }

        LBL_STOPPED:

        if (stop){
            code = FX_KER_WRITE;
            QString output = "--- INTERRUPTED ---";
            QByteArray b = output.toUtf8();
            d.str = b.data();
            d.len = output.length();

            res = callback(reinterpret_cast<KernelParam>(this),
                                                 code,
                                                 reinterpret_cast<KernelParam>(&d));

            res = FX_INTERRUPTED;
        }

        qDebug("FakeKernel.run() -- after callback");

        return res;
    }

};

KernelParam fx_call_shell(KernelParam kernel, KernelParam, KernelParam)
{
    FakeKernel *k = reinterpret_cast<FakeKernel *>(kernel);
    return k->shell;
}

KernelParam fx_call_create(KernelParam shell, KernelParam file, KernelParam callback)
{
    FakeKernel *k = new FakeKernel(shell, reinterpret_cast<KernelData *>(file), reinterpret_cast<KernelCallback>(callback));
    return reinterpret_cast<KernelParam>(k);
}

KernelParam fx_call_destroy(KernelParam kernel, KernelParam, KernelParam)
{
    FakeKernel *k = reinterpret_cast<FakeKernel *>(kernel);
    delete k;
    return 0;
}

KernelParam fx_call_input(KernelParam kernel, KernelParam data, KernelParam)
{
    FakeKernel *k = reinterpret_cast<FakeKernel *>(kernel);
    KernelData *d = reinterpret_cast<KernelData *>(data);
    // copying data
    k->inputlen = d->len;
    if (k->input) delete [] k->input;
    k->input = new char[d->len];
    memcpy(k->input, d->str, (d->len) * sizeof(char));
    qDebug("fx_input %s", k->input);
    return 0;
}

KernelParam fx_call_run(KernelParam kernel, KernelParam, KernelParam)
{
    FakeKernel *k = reinterpret_cast<FakeKernel *>(kernel);
    k->stop = false;
    k->pause = false;
    qDebug("fx_run %s", k->input);
    return k->run();
}

KernelParam fx_call_pause(KernelParam kernel, KernelParam, KernelParam)
{
    FakeKernel *k = reinterpret_cast<FakeKernel *>(kernel);
    k->pause = true;
    qDebug("kernel paused");
    return 0;
}

KernelParam fx_call_resume(KernelParam kernel, KernelParam, KernelParam)
{
    FakeKernel *k = reinterpret_cast<FakeKernel *>(kernel);
    k->pause = false;
    qDebug("kernel resumed");
    return 0;
}

KernelParam fx_call_interrupt(KernelParam kernel, KernelParam, KernelParam)
{
    FakeKernel *k = reinterpret_cast<FakeKernel *>(kernel);
    k->stop = true;
    return 0;
}

KernelParam fx_call_save(KernelParam kernel, KernelParam data, KernelParam)
{
    FakeKernel *k = reinterpret_cast<FakeKernel *>(kernel);
    k->save();
    return 0;
}

#endif

