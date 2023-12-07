QT       += core gui widgets qml

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

CONFIG += c++11

# You can make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

SOURCES += \
    aboutdialog.cpp \
    codeeditor.cpp \
    console.cpp \
    consolehilite.cpp \
    fxhilite.cpp \
    hilite.cpp \
    jsonhilite.cpp \
    kernel.cpp \
    main.cpp \
    mainwindow.cpp \
    pagetabs.cpp \
    searchengine.cpp \
    settingsdialog.cpp \
    shell.cpp \
    wndgoto.cpp

HEADERS += \
    aboutdialog.h \
    builddatetime.h \
    codeeditor.h \
    console.h \
    consolehilite.h \
    fxhilite.h \
    hilite.h \
    jsonhilite.h \
    kernel.h \
    mainwindow.h \
    pagetabs.h \
    searchengine.h \
    settingsdialog.h \
    shell.h \
    wndgoto.h

FORMS += \
    aboutdialog.ui \
    mainwindow.ui \
    settingsdialog.ui \
    wndgoto.ui

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

RESOURCES += \
    function.qrc
