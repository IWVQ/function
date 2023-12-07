#include "kernel.h"
#include "shell.h"
#include <stdio.h>
#include <string.h>

#include <QtCore>

/* kernel */

KernelParam fx_callback(KernelParam kernel, KernelParam code, KernelParam data)
{
    qDebug("fx_callback");
    Shell *shell = reinterpret_cast<Shell *>(fx_call_shell(kernel));
    if (shell){
        qDebug("fx_callback shell->callback");
        return shell->callback(code, reinterpret_cast<KernelData *>(data));
        qDebug("fx_callback shell->callback --- after");
    }
    else return 0;
}

/*/
KernelParam fx_call_shell(KernelParam kernel);
KernelParam fx_call_create(KernelParam shell, KernelParam file, KernelParam callback);
KernelParam fx_call_destroy(KernelParam kernel);
KernelParam fx_call_input(KernelParam kernel, KernelParam data);
KernelParam fx_call_run(KernelParam kernel);
KernelParam fx_call_pause(KernelParam kernel);
KernelParam fx_call_resume(KernelParam kernel);
KernelParam fx_call_interrupt(KernelParam kernel);
KernelParam fx_call_save(KernelParam kernel, KernelParam data);
KernelParam fx_call_test(KernelParam data, KernelParam callback);
/*/

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

KernelParam fx_call_shell(KernelParam kernel)
{
    FakeKernel *k = reinterpret_cast<FakeKernel *>(kernel);
    return k->shell;
}

KernelParam fx_call_create(KernelParam shell, KernelParam file, KernelParam callback)
{
    FakeKernel *k = new FakeKernel(shell, reinterpret_cast<KernelData *>(file), reinterpret_cast<KernelCallback>(callback));
    return reinterpret_cast<KernelParam>(k);
}

KernelParam fx_call_destroy(KernelParam kernel)
{
    FakeKernel *k = reinterpret_cast<FakeKernel *>(kernel);
    delete k;
    return 0;
}

KernelParam fx_call_input(KernelParam kernel, KernelParam data)
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

KernelParam fx_call_run(KernelParam kernel)
{
    FakeKernel *k = reinterpret_cast<FakeKernel *>(kernel);
    k->stop = false;
    k->pause = false;
    qDebug("fx_run %s", k->input);
    return k->run();
}

KernelParam fx_call_pause(KernelParam kernel)
{
    FakeKernel *k = reinterpret_cast<FakeKernel *>(kernel);
    k->pause = true;
    qDebug("kernel paused");
    return 0;
}

KernelParam fx_call_resume(KernelParam kernel)
{
    FakeKernel *k = reinterpret_cast<FakeKernel *>(kernel);
    k->pause = false;
    qDebug("kernel resumed");
    return 0;
}

KernelParam fx_call_interrupt(KernelParam kernel)
{
    FakeKernel *k = reinterpret_cast<FakeKernel *>(kernel);
    k->stop = true;
    return 0;
}

KernelParam fx_call_save(KernelParam kernel, KernelParam data)
{
    FakeKernel *k = reinterpret_cast<FakeKernel *>(kernel);
    k->save();
    return 0;
}

KernelParam fx_call_test(KernelParam, KernelParam)
{
    return 0; // used in fxkernel library
}

//*/
