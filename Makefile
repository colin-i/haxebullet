# Builds bullet.hdll (a shared library HashLink can load) from haxebullet.
#
# On an x86-64 machine it builds natively.
# On an ARM64 machine (Raspberry Pi) it cross-compiles an x86-64 bullet.hdll,
# the kind you run with box64, using x86_64-linux-gnu-g++.
#
#   make -j$(nproc) [HB=...] [HL_SRC=...] [HL_LIB=...]
#   make check      # confirm the result really is an x86-64 library
#
# On Ubuntu ARM64, install the cross tools with:
#   sudo apt install g++-x86-64-linux-gnu binutils-x86-64-linux-gnu libc6-dev-amd64-cross
#
# HL_LIB must hold the x86-64 libhl.so (Lime's Linux64 one is fine).

HB     ?= $(CURDIR)
HL_SRC ?= $(HOME)/haxelib/lime/8,3,2/templates/bin/hl/include
HL_LIB ?= $(HOME)/haxelib/lime/8,3,2/templates/bin/hl/Linux64

# Pick the compiler by host architecture (a CXX=... on the command line still wins).
ifeq ($(shell uname -m),aarch64)
CXX := x86_64-linux-gnu-g++
endif

BUILD := ../build-x86_64

SRCS := $(shell find $(HB)/bullet -name '*.cpp') $(HB)/hl/bullet.cpp $(HB)/hl/DebugDrawer.cpp
OBJS := $(patsubst $(HB)/%.cpp,$(BUILD)/%.o,$(SRCS))

CXXFLAGS := -O2 -fPIC -std=c++11 -pthread -I$(HL_SRC) -I$(HB)/bullet -I$(HB)/hl

../bullet.hdll: $(OBJS)
	$(CXX) -shared -o $@ $(OBJS) -L$(HL_LIB) -lhl -pthread

$(BUILD)/%.o: $(HB)/%.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

check: bullet.hdll
	@file bullet.hdll
	@file bullet.hdll | grep -q "x86-64" && echo "OK: x86-64 library" || (echo "NOT x86-64 - check CXX"; exit 1)

clean:
	rm -rf $(BUILD) bullet.hdll

.PHONY: check clean
