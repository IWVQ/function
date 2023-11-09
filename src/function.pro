QT       += core gui widgets qml

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

CONFIG += c++11

# You can make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

SOURCES += \
    codeeditor.cpp \
    console.cpp \
    consolehilite.cpp \
    fxhilite.cpp \
    hilite.cpp \
    jsonhilite.cpp \
    main.cpp \
    mainwindow.cpp

HEADERS += \
    codeeditor.h \
    console.h \
    consolehilite.h \
    fxhilite.h \
    hilite.h \
    jsonhilite.h \
    mainwindow.h

FORMS += \
    mainwindow.ui

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target