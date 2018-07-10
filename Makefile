CC=cc\bin\i686-elf-gcc
CPP=cc\bin\i686-elf-g++
CFLAGS=-nostartfiles -nostdlib -fno-exceptions -fno-rtti -masm=intel -O2 -Wall -Wextra -std=c++11
LDFLAGS=-nostartfiles -nostdlib -fno-exceptions -fno-rtti -nostdlib -nodefaultlibs -lgcc

ASS=Tools\NASM\nasm.exe
ASS_FLAGS=-g -f elf

BUILD_DIR=build
SRC_DIR=src
ISO_DIR=ISO

ASM_FILES=$(shell find $(SRC_DIR) -name *.asm)
CPP_FILES=$(shell find $(SRC_DIR) -name *.cpp)
H_FILES=$(shell find $(SRC_DIR) -name *.h)
OBJECT_FILES=$(ASM_FILES:%.asm=$(BUILD_DIR)/asm/%.o) $(CPP_FILES:%.cpp=$(BUILD_DIR)/cpp/%.o)

# Commands
RM=rm
RMR=rm -rf
CP=cp
MV=mv
MKDIR=mkdir -p
WD=$(shell pwd)

$(BUILD_DIR)/kernel.iso: $(BUILD_DIR)/kernel.bin
	$(CP) $(BUILD_DIR)/kernel.bin $(ISO_DIR)/Kernel.bin
	Tools/ISO9660Generator.exe 4 ".\build\kernel.iso" ".\ISO\isolinux-debug.bin" true ".\ISO"
	$(MV) $(ISO_DIR)/kernel.bin $(BUILD_DIR)/kernel.bin

$(BUILD_DIR)/kernel.bin: $(OBJECT_FILES) linker.ld
	$(CC) $(OBJECT_FILES) -T linker.ld -o $@ $(LDFLAGS) $(CFLAGS)

$(BUILD_DIR)/cpp/%.o: %.cpp
	$(MKDIR) $(dir $@)
	$(CPP) -c $< -o $@ $(CFLAGS)

$(BUILD_DIR)/asm/%.o: %.asm
	$(MKDIR) $(dir $@)
	$(ASS) $(ASS_FLAGS) -o $@ $<

clean:
	$(RMR) $(BUILD_DIR)
