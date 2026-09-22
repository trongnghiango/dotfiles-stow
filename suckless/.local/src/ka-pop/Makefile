.POSIX:

BIN := ka-pop
PREFIX ?= /usr/local
CC ?= gcc

BUILD_DIR := build
SRC_DIR := src
INC_DIR := include

ifeq ($(LOCAL_BUILD),1)
OPTFLAGS := -O3 -march=native -pipe -flto
LDFLTO   := -flto
else
OPTFLAGS := -O2 -march=x86-64-v2 -pipe
LDFLTO   :=
endif

CFLAGS ?= $(OPTFLAGS) -Wall -Wextra -Wpedantic
CFLAGS += -I$(INC_DIR) $(shell pkg-config --cflags gtk+-3.0)
LDLIBS += $(LDFLTO) $(shell pkg-config --libs gtk+-3.0) -lm

SRCS := $(SRC_DIR)/main.c $(SRC_DIR)/theme.c $(SRC_DIR)/ui.c $(SRC_DIR)/util.c \
        $(SRC_DIR)/modules/volume.c $(SRC_DIR)/modules/battery.c $(SRC_DIR)/modules/clock.c \
        $(SRC_DIR)/modules/cpu.c $(SRC_DIR)/modules/memory.c $(SRC_DIR)/modules/network.c \
        $(SRC_DIR)/modules/notify.c $(SRC_DIR)/modules/forecast.c $(SRC_DIR)/modules/clip.c

OBJS := $(patsubst $(SRC_DIR)/%.c,$(BUILD_DIR)/%.o,$(SRCS))

INSTALL_DIR := $(DESTDIR)$(PREFIX)/bin

all: $(BUILD_DIR)/$(BIN)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.c
	@mkdir -p $(@D)
	$(CC) $(CFLAGS) -c -o $@ $<

$(BUILD_DIR)/$(BIN): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDLIBS)

debug: CFLAGS := -g -O1 -fsanitize=address,undefined -Wall -Wextra -I$(INC_DIR) $(shell pkg-config --cflags gtk+-3.0)
debug: LDLIBS := -fsanitize=address,undefined $(shell pkg-config --libs gtk+-3.0) -lm
debug: clean $(BUILD_DIR)/$(BIN)

install: $(BUILD_DIR)/$(BIN)
	install -d $(INSTALL_DIR)
	install -m 755 $< $(INSTALL_DIR)/$(BIN)

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all debug clean install
