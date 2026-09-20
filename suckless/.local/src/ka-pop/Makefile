.POSIX:

BIN := ka-pop
PREFIX ?= $(HOME)/.local
CC ?= gcc

CFLAGS ?= -O3 -march=native -pipe -flto -Wall -Wextra
CFLAGS += $(shell pkg-config --cflags gtk+-3.0)
LDLIBS += -flto $(shell pkg-config --libs gtk+-3.0) -lm

all: $(BIN)

$(BIN): ka-pop.c
	$(CC) $(CFLAGS) -o $@ $< $(LDLIBS)

install: $(BIN)
	install -d $(DESTDIR)$(PREFIX)/bin
	install -m 755 $(BIN) $(DESTDIR)$(PREFIX)/bin/$(BIN)

clean:
	rm -f $(BIN)

.PHONY: all install clean
