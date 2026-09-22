.POSIX:

BIN := ka-clipd
PREFIX := /usr/local
CC := cc
ifeq ($(LOCAL_BUILD),1)
OPTFLAGS := -O3 -march=native -pipe -flto
LDFLTO   := -flto
else
OPTFLAGS := -O2 -march=x86-64-v2 -pipe
LDFLTO   :=
endif

CFLAGS := $(OPTFLAGS) -std=c99 -Wall -Wextra -Wpedantic
LIBS := x11 xfixes

CFLAGS += $(shell pkg-config --cflags $(LIBS))
LDLIBS := $(shell pkg-config --libs $(LIBS)) $(LDFLTO)

all: $(BIN)

$(BIN): ka-clipd.c
	$(CC) $(CFLAGS) -o $@ $< $(LDLIBS)

clean:
	rm -f $(BIN) *.o

install: $(BIN)
	install -D -m 755 $(BIN) $(DESTDIR)$(PREFIX)/bin/$(BIN)

uninstall:
	rm -f $(DESTDIR)$(PREFIX)/bin/$(BIN)

.PHONY: all clean install uninstall
