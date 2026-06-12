# Makefile for compiling the MediaPipe Pose Bridge on Linux / POSIX systems
# Targets include both the Free Pascal (FPC) stub compilation and the C++ GCC compilation.

FPC := $(shell which fpc 2>/dev/null)
GXX := $(shell which g++ 2>/dev/null)

VERSION_TAG := v1_0_0_mp0_10_35
SO_NAME_32 := libai_mediapipe_pose_bridge_$(VERSION_TAG)_linux32.so
SO_NAME_64 := libai_mediapipe_pose_bridge_$(VERSION_TAG)_linux64.so

# Detect system architecture
ARCH := $(shell uname -m)
ifeq ($(ARCH),x86_64)
    BITS := 64
    SO_NAME := $(SO_NAME_64)
    ARCH_DIR := x64
else
    BITS := 32
    SO_NAME := $(SO_NAME_32)
    ARCH_DIR := x86
endif

# Output directories
DEST_ROOT := ../linux
DEST_ARCH := $(DEST_ROOT)/$(ARCH_DIR)

.PHONY: all pascal cpp clean install

all: pascal

pascal:
	@if [ -z "$(FPC)" ]; then \
		echo "Error: fpc compiler not found in PATH."; \
		exit 1; \
	fi
	$(FPC) -MObjFPC -Scghi -O3 -gl -o"$(SO_NAME)" bridge.lpr
	@mkdir -p "$(DEST_ROOT)" "$(DEST_ARCH)"
	cp -f "$(SO_NAME)" "$(DEST_ROOT)/"
	cp -f "$(SO_NAME)" "$(DEST_ARCH)/"
	@echo "Built Pascal stub: $(SO_NAME) and copied to $(DEST_ROOT) and $(DEST_ARCH)"

cpp:
	@if [ -z "$(GXX)" ]; then \
		echo "Error: g++ compiler not found in PATH."; \
		exit 1; \
	fi
	$(GXX) -shared -fPIC -O3 -Wall -o "$(SO_NAME)" bridge.cpp
	@mkdir -p "$(DEST_ROOT)" "$(DEST_ARCH)"
	cp -f "$(SO_NAME)" "$(DEST_ROOT)/"
	cp -f "$(SO_NAME)" "$(DEST_ARCH)/"
	@echo "Built C++ integration: $(SO_NAME) and copied to $(DEST_ROOT) and $(DEST_ARCH)"

clean:
	rm -f *.o *.or *.ppu *.so
