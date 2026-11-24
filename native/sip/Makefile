# PJSIP must be built as PIC (CFLAGS/CXXFLAGS=-fPIC), version 2.17.
# Override PJ_PKG_PATH when PJSIP was installed into a custom prefix.
PJ_PKG_PATH ?=
CC ?= cc
PKG_CONFIG ?= pkg-config
PJ_CFLAGS := $(shell PKG_CONFIG_PATH="$(PJ_PKG_PATH):$(PKG_CONFIG_PATH)" $(PKG_CONFIG) --cflags libpjproject)
PJ_LIBS := $(shell PKG_CONFIG_PATH="$(PJ_PKG_PATH):$(PKG_CONFIG_PATH)" $(PKG_CONFIG) --libs --static libpjproject)
TARGET ?= build/libchatgpt_sip_bridge.so
CFLAGS ?= -O2 -g

all: $(TARGET)

$(TARGET): chatgpt_sip_bridge.c chatgpt_sip_bridge.h
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -std=gnu11 -fPIC -fvisibility=hidden -Wall -Wextra -Werror $(PJ_CFLAGS) -shared -o $@ chatgpt_sip_bridge.c $(PJ_LIBS)

clean:
	rm -rf build
.PHONY: all clean
