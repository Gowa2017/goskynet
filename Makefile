OS=$(shell uname -s)
PLAT ?= none
SKYNET_LIBS := -lpthread -lm -dl
SHARED := -fPIC --shared
EXPORT := -Wl,-E

ifeq ($(OS), Darwin)
PLAT = macosx
SHARED := -fPIC -dynamiclib -Wl,-undefined,dynamic_lookup
EXPORT :=
endif

ifeq ($(OS), Linux)
PLAT = linux
SKYNET_LIBS += -lrt
endif

LUAINC?=
LUACLIB_DIR=luaclib
LUACLIBS=ltimer

CFLAGS = -g -O2 -Wall -I$(LUAINC) $(EXPORT)
LDFLAGS = $(SKYNET_LIBS)

all: mkdir libs

mkdir:
	install -d $(LUACLIB_DIR)

libs: $(patsubst %, $(LUACLIB_DIR)/%.so, $(LUACLIBS))

$(LUACLIB_DIR)/ltimer.so : 3rd/timingwheel/twheel.c 3rd/timingwheel/lua-twheel.c
	gcc $(CFLAGS) $(SHARED) $^ -o $@ $(LDFLAGS)

clean:
	rm -rf $(LUACLIB_DIR)

all:
	@echo finish