.POSIX:

BIN := ka-clipd
PREFIX := /usr/local
CC := cc
CFLAGS := -O3 -march=native -pipe -flto -std=c99 -Wall -Wextra -Wpedantic
LIBS := x11 xfixes

CFLAGS += $(shell pkg-config --cflags $(LIBS))
LDLIBS := $(shell pkg-config --libs $(LIBS)) -flto

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
