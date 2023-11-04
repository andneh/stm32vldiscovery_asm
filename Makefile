# Project name
TARGET = firmware

# Directories
SRC_DIR = src
BUILD_DIR = build
LD_DIR = ld
SCRIPT_DIR = scripts
CNF_DIR = config

# Source files
SRC = $(wildcard $(SRC_DIR)/*.S)
OBJ = $(patsubst $(SRC_DIR)/%.S, $(BUILD_DIR)/%.o, $(ASM_SRC))

# Linker script
LD_SCRIPT = $(LD_DIR)/STM32F100RBTx_FLASH.ld

# Output file
ELF = $(BUILD_DIR)/$(TARGET).elf
BIN = $(BUILD_DIR)/$(TARGET).bin

# Define the toolchain and compiler
AS = arm-none-eabi-as
LD = arm-none-eabi-ld
OBJCOPY = arm-none-eabi-objcopy
OBJDUMP = arm-none-eabi-objdump
CC = arm-none-eabi-gcc
STL = st-flash
GDB = arm-none-eabi-gdb
OPENOCD = openocd
QEMU = qemu-system-arm

# Define the target microcontroller
BOARD = stm32vldiscovery
MCU = cortex-m3
ARCH = armv7-m

# Define compilation flags
AS_FLAGS = -mcpu=$(MCU) -march=$(ARCH) -mthumb -g # -marm
C_FLAGS = -mcpu=$(MCU) -march=$(ARCH) #-mthumb #-g -O0
LD_FLAGS = -T $(LD_SCRIPT)
OBJCP_FLAGS = -O binary
GDB_FLAGS = #-x $(CNF_DIR)/.gdbinit #-tui
OPENOCD_FLAGS = -f interface/stlink-v2-1.cfg -f target/stm32f1x.cfg
QEMU_FLAGS = -M $(BOARD) -cpu $(MCU) -nographic -S -s -monitor null

# Define source files and output file
SRC = $(wildcard $(SRC_DIR)/*)
C_SRC = $(wildcard $(SRC_DIR)/*.c)
S_SRC = $(wildcard $(SRC_DIR)/*.S)
OBJ += $(patsubst $(SRC_DIR)/%, $(BUILD_DIR)/%.o, $(SRC))

all: $(BUILD_DIR) $(BIN)

# Create the build directory
$(BUILD_DIR): $(clean)
	mkdir -p $(BUILD_DIR)

build_clean:
	rm -rf $(BUILD_DIR)

# Compile the source files into object files
$(BUILD_DIR)/%.S.o: $(SRC_DIR)/%.S
	$(AS) $(AS_FLAGS) -o $@ $<

# Compile the source files into object files
$(BUILD_DIR)/%.c.o: $(SRC_DIR)/%.c
	$@(chmod +x ./scripts/*.sh)

	$(CC) $(C_FLAGS) -c -o $@ $<

# Link the object files into an ELF file
$(ELF): $(OBJ)
	$(LD) $(LD_FLAGS) -o $@ $^

# Make objectdump of the ELF file
elf_dump: $(ELF)
	#$(OBJDUMP) -d $< > $(BUILD_DIR)/$(TARGET).dump
	$(OBJDUMP) -d $(ELF)

# Convert the ELF file into a BIN file
$(BIN): $(ELF)
	$(OBJCOPY) $(OBJCP_FLAGS) $< $@

reset:
	$(STL) reset

# Flash the BIN file to the STM32 board
flash: $(BIN) erase
	$(STL) write $(BIN) 0x8000000

# Erase the flash memory of the STM32 board
erase: reset
	$(STL) erase

# Flash the BIN file to the STM32 board using OpenOCD
ocd_flash: $(BIN)
	$(OPENOCD) $(OPENOCD_FLAGS) -c "init" -c "reset halt" -c "flash write_image erase $< 0x08000000" -c "reset run" -c "exit"


# Erase the flash memory of the STM32 board using OpenOCD
ocd_erase:
	$(OPENOCD) $(OPENOCD_FLAGS) -c "init" -c "reset halt" -c "flash erase_sector 0 0 last" -c "reset run" -c "exit"

# Start OpenOCD server
ocd_start: ocd_kill
	$(OPENOCD) $(OPENOCD_FLAGS) &
	sleep 2

# Kill OpenOCD server
ocd_kill:
	$(SCRIPT_DIR)/kill_port_6666.sh
	#killall $(OPENOCD)

# Debug the program using GDB and OpenOCD
ocd_debug: $(ELF) ocd_start
	# Give OpenOCD time to start and initialize
	#$(GDB) -ex "target remote :3333" -ex "file $(ELF)"
	$(GDB) $(GDB_FLAGS) -q -ex "target remote :3333" $(ELF)

# start qemu
qemu_start: $(BIN) qemu_kill
	$(QEMU) $(QEMU_FLAGS) -kernel $(BIN) &
	sleep 2

# Debug the program using GDB and QEMU
qemu_debug: $(ELF) qemu_start
	$(GDB) $(GDB_FLAGS) -q -ex "target remote :1234" $(ELF)

qemu_kill:
	#killall $(QEMU)
	$(SCRIPT_DIR)/kill_port_1234.sh

# Remove the build directory
clean: build_clean ocd_kill qemu_kill erase



# Define phony targets
.PHONY: all dump flash erase ocd_flash ocd_erase ocd_debug ocd_kill qemu_debug qemu_kill clean
