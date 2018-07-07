CC=cc\bin\i686-elf-g++
CFLAGS=-nostartfiles -nostdlib
LDFLAGS=-T linker.ld

ASS=Tools\NASM\nasm.exe
ASS_FLAGS=-g -f elf

BUILD_DIR=build
SRC_DIR=src
ISO_DIR=ISO

ASM_FILES=$(shell find $(SRC_DIR) -name *.asm)
CPP_FILES=$(shell find $(SRC_DIR) -name *.cpp)
H_FILES=$(shell find $(SRC_DIR) -name *.h)
OBJECT_FILES=$(CPP_FILES:%.cpp=$(BUILD_DIR)/cpp/%.o) $(ASM_FILES:%.asm=$(BUILD_DIR)/asm/%.o)

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

$(BUILD_DIR)/kernel.bin: $(OBJECT_FILES)
	$(CC) $(OBJECT_FILES) -o $@ $(LDFLAGS) $(CFLAGS)

$(BUILD_DIR)/cpp/%.o: %.cpp
	$(MKDIR) $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/asm/%.o: %.asm
	$(MKDIR) $(dir $@)
	$(ASS) $(ASS_FLAGS) -o $@ $<

clean:
	$(RMR) $(BUILD_DIR)
