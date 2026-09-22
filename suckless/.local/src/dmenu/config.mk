# dmenu version
VERSION = 5.0

# paths
PREFIX = /usr/local
MANPREFIX = $(PREFIX)/share/man

X11INC = /usr/X11R6/include
X11LIB = /usr/X11R6/lib

# Xinerama, comment if you don't want it
XINERAMALIBS  = -lXinerama
XINERAMAFLAGS = -DXINERAMA

# freetype
FREETYPELIBS = -lfontconfig -lXft
FREETYPEINC = /usr/include/freetype2
# OpenBSD (uncomment)
#FREETYPEINC = $(X11INC)/freetype2

# includes and libs
INCS = -I$(X11INC) -I$(FREETYPEINC)
LIBS = -L$(X11LIB) -lX11 $(XINERAMALIBS) $(FREETYPELIBS) -lXrender

# flags
CPPFLAGS = -D_DEFAULT_SOURCE -D_BSD_SOURCE -D_XOPEN_SOURCE=700 -D_POSIX_C_SOURCE=200809L -DVERSION=\"$(VERSION)\" $(XINERAMAFLAGS)
ifeq ($(LOCAL_BUILD),1)
OPTFLAGS = -O3 -march=native -pipe -flto
LDFLTO   = -flto
else
OPTFLAGS = -O2 -march=x86-64-v2 -pipe
LDFLTO   =
endif

CFLAGS   = -std=c99 -pedantic -Wall $(OPTFLAGS) $(INCS) $(CPPFLAGS)
LDFLAGS  = $(LDFLTO) $(LIBS)

# compiler and linker
CC = cc
