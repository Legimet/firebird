load(configure)

lessThan(QT_MAJOR_VERSION, 5): error("You need at least Qt 5.6 to build firebird!")
lessThan(QT_MINOR_VERSION, 6): error("You need at least Qt 5.6 to build firebird!")

# Version
DEFINES += FB_VERSION=1.3-dev

# JIT
TRANSLATION_ENABLED = true
# More accurate, but slower
SUPPORT_LINUX = true
ios|android: SUPPORT_LINUX = false

# Localization
TRANSLATIONS += i18n/de_DE.ts i18n/fr_FR.ts

QT += core gui widgets quickwidgets
CONFIG += c++11

TEMPLATE = app
TARGET = firebird

# Warn if git submodules not downloaded
!exists("core/gif-h/gif.h"): error("You have to run 'git submodule init' and 'git submodule update' first.")

linux: !android {
    # For make install support
    target.path = /usr/bin
    desktop.path = /usr/share/applications
    desktop.files += resources/firebird.desktop
    icon.path = /usr/share/icons
    icon.files += resources/firebird.png
    sendtool.path = /usr/bin
    sendtool.files = core/firebird-send
    INSTALLS += target desktop icon sendtool
}

QMAKE_CFLAGS = -g -std=gnu11 -Wall -Wextra
QMAKE_CXXFLAGS = -g -std=c++11 -Wall -Wextra -D QT_NO_CAST_FROM_ASCII
LIBS += -lz

# Override bad default options to enable better optimizations
QMAKE_CFLAGS_RELEASE = -O3 -flto -DNDEBUG
QMAKE_CXXFLAGS_RELEASE = -O3 -flto -DNDEBUG
QMAKE_LFLAGS_RELEASE = -Wl,-O3 -flto
QMAKE_LFLAGS += -fno-pie

*-g++*: qtCompileTest(-no-pie): QMAKE_LFLAGS += -no-pie

# Apple's clang doesn't know about this one
macx: QMAKE_LFLAGS_RELEASE -= -Wl,-O3

# This became needed, somehow.
macx|ios: QMAKE_CXXFLAGS += -stdlib=libc++

# ios: The linker can't deal with LLVM bitcode directly (missing plugin?)
ios {
    QMAKE_CFLAGS_RELEASE -= -flto
    QMAKE_CXXFLAGS_RELEASE -= -flto
    QMAKE_LFLAGS_RELEASE -= -Wl,-O3 -flto
}

# noexecstack is not supported by MinGW's as
!win32 {
    QMAKE_CFLAGS += -Wa,--noexecstack
}

# The linker needs this somehow
android: QMAKE_LFLAGS += -fPIC

macx: ICON = resources/logo.icns

# This does also apply to android
linux|macx|ios: SOURCES += core/os/os-linux.c

# To make it appear in Qt Creator
emscripten: SOURCES += core/os/os-emscripten.c

equals(QT_MAJOR_VERSION, 5): lessThan(QT_MINOR_VERSION, 6) {
    # This should not be required. But somehow, it is...
    android: DEFINES += Q_OS_ANDROID
}

ios|android: DEFINES += MOBILE_UI

ios {
    DEFINES += IS_IOS_BUILD __arm__
    QMAKE_INFO_PLIST = Info.plist
    QMAKE_CFLAGS += -mno-thumb
    QMAKE_CXXFLAGS += -mno-thumb
    QMAKE_LFLAGS += -mno-thumb
    QMAKE_IOS_DEVICE_ARCHS = armv7
    ios_icon.files = $$files(resources/ios/Icon*.png)
    QMAKE_BUNDLE_DATA += ios_icon
}

# QMAKE_HOST can be e.g. armv7hl, but QT_ARCH would be arm in such cases
QMAKE_TARGET.arch = $$QT_ARCH

equals(QMAKE_TARGET.arch, "arm64") {
    QMAKE_TARGET.arch = aarch64
}

win32 {
    SOURCES += core/os/os-win32.c
    LIBS += -lwinmm -lws2_32
    # Somehow it's set to x86_64...
    QMAKE_TARGET.arch = x86
}

linux-g++-32 {
    QMAKE_CFLAGS += -m32
    QMAKE_CXXFLAGS += -m32
    QMAKE_TARGET.arch = x86
}

# A platform-independant implementation of lowlevel access as default
ASMCODE_IMPL = core/asmcode.c

equals(TRANSLATION_ENABLED, true) {
    TRANSLATE = $$join(QMAKE_TARGET.arch, "", "core/translate_", ".c")
    exists($$TRANSLATE) {
        SOURCES += $$TRANSLATE
    }

    TRANSLATE2 = $$join(QMAKE_TARGET.arch, "", "core/translate_", ".cpp")
    exists($$TRANSLATE2) {
        SOURCES += $$TRANSLATE2
    }

    ASMCODE = $$join(QMAKE_TARGET.arch, "", "core/asmcode_", ".S")
    exists($$ASMCODE): ASMCODE_IMPL = $$ASMCODE
}
else: DEFINES += NO_TRANSLATION

# The x86_64 and ARM JIT use asmcode.c for mem access
equals(QMAKE_TARGET.arch, "x86_64") || equals(QMAKE_TARGET.arch, "arm") || equals(QMAKE_TARGET.arch, "aarch64") {
    !contains(ASMCODE_IMPL, "core/asmcode.c") {
        SOURCES += core/asmcode.c
    }
}

equals(SUPPORT_LINUX, true) {
    DEFINES += SUPPORT_LINUX
}

# Default to armv7 on ARM for movw/movt. If your CPU doesn't support it, comment this out.
contains(QMAKE_TARGET.arch, "arm") {
    QMAKE_CFLAGS += -march=armv7-a -marm
    QMAKE_CXXFLAGS += -march=armv7-a -marm
    QMAKE_LFLAGS += -march=armv7-a -marm # We're using LTO, so the linker has to get the same flags
}

QML_IMPORT_PATH += qml

SOURCES += $$ASMCODE_IMPL \
    lcdwidget.cpp \
    mainwindow.cpp \
    main.cpp \
    flashdialog.cpp \
    emuthread.cpp \
    qmlbridge.cpp \
    qtkeypadbridge.cpp \
    core/arm_interpreter.cpp \
    core/coproc.cpp \
    core/cpu.cpp \
    core/thumb_interpreter.cpp \
    core/usblink_queue.cpp \
    core/armsnippets_loader.c \
    core/casplus.c \
    core/des.c \
    core/disasm.c \
    core/gdbstub.c \
    core/gif.cpp \
    core/interrupt.c \
    core/keypad.cpp \
    core/lcd.c \
    core/link.c \
    core/mem.c \
    core/misc.c \
    core/mmu.c \
    core/schedule.c \
    core/serial.c \
    core/sha256.c \
    core/usb.c \
    core/usblink.c \
    qtframebuffer.cpp \
    core/debug.cpp \
    core/flash.cpp \
    core/emu.cpp \
    usblinktreewidget.cpp \
    kitmodel.cpp \
    fbaboutdialog.cpp \
    dockwidget.cpp

FORMS += \
    mainwindow.ui \
    flashdialog.ui

HEADERS += \
    emuthread.h \
    lcdwidget.h \
    flashdialog.h \
    mainwindow.h \
    keymap.h \
    qmlbridge.h \
    qtkeypadbridge.h \
    core/os/os.h \
    core/armcode_bin.h \
    core/armsnippets.h \
    core/asmcode.h \
    core/bitfield.h \
    core/casplus.h \
    core/cpu.h \
    core/cpudefs.h \
    core/debug.h \
    core/des.h \
    core/disasm.h \
    core/emu.h \
    core/flash.h \
    core/gdbstub.h \
    core/gif.h \
    core/interrupt.h \
    core/keypad.h \
    core/lcd.h \
    core/link.h \
    core/mem.h \
    core/misc.h \
    core/mmu.h \
    core/schedule.h \
    core/sha256.h \
    core/translate.h \
    core/usb.h \
    core/usblink.h \
    core/usblink_queue.h \
    qtframebuffer.h \
    usblinktreewidget.h \
    kitmodel.h \
    fbaboutdialog.h \
    dockwidget.h

# For localization
lupdate_only {
SOURCES += qml/Keypad.qml \
    qml/MobileUI.qml \
    qml/ConfigPagesModel.qml \
    qml/NNumButton.qml \
    qml/MobileControl2.qml \
    qml/SidebarButton.qml \
    qml/ConfigPageDebug.qml \
    qml/ConfigPageEmulation.qml \
    qml/ConfigPageFileTransfer.qml \
    qml/ConfigPageKits.qml \
    qml/NBigButton.qml \
    qml/NButton.qml \
    qml/NAlphaButton.qml \
    qml/NDualButton.qml \
    qml/FBConfigDialog.qml \
    qml/Touchpad.qml \
    qml/Firebird/Emu/Emu.qml \
    qml/Firebird/Emu/EmuScreen.qml \
    qml/Firebird/UIComponents/FBLabel.qml \
    qml/Firebird/UIComponents/FileSelect.qml \
    qml/Firebird/UIComponents/PageDelegate.qml \
    qml/Firebird/UIComponents/PageList.qml \
    qml/Firebird/UIComponents/ConfigPages.qml \
    qml/Firebird/UIComponents/LabeledCheckBox.qml
}

# Generate the binary arm code into armcode_bin.h
armsnippets.commands = arm-none-eabi-gcc -fno-leading-underscore -c $$PWD/core/armsnippets.S -o armsnippets.o -mcpu=arm926ej-s \
                        && arm-none-eabi-objcopy -O binary armsnippets.o snippets.bin \
                        && xxd -i snippets.bin > $$PWD/core/armcode_bin.h \
                        && rm armsnippets.o

# In case you change armsnippets.S, run "make armsnippets" and update armcode_bin.h
QMAKE_EXTRA_TARGETS = armsnippets

OTHER_FILES += \
    TODO \
    emscripten/main.cpp \
    emscripten/Makefile

RESOURCES += \
    resources.qrc

DISTFILES += \
    core/firebird-send \
    android/AndroidManifest.xml \
    android/res/values/libs.xml \
    android/build.gradle

ANDROID_PACKAGE_SOURCE_DIR = $$PWD/android
