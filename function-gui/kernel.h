#ifndef KERNEL_H
#define KERNEL_H

struct KernelData{
    int len;
    char *str;
};

typedef unsigned long long int KernelParam;

typedef KernelParam (*KernelCallback)(KernelParam, KernelParam, KernelParam);

KernelParam fx_callback(KernelParam kernel, KernelParam code, KernelParam data);

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

#endif // KERNEL_H
