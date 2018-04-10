# extracted from https://github.com/torvalds/linux/blob/master/scripts/Lindent
LINDENT=indent -npro -kr -i8 -ts8 -sob -l80 -ss -ncs -cp1 -il0


LIBOPENCM3_DIR ?= /home/felipe/projects_study/automation/beremiz/related-projects/ioton_plc/libopencm3
MATIEC_C_INCLUDE_DIR ?=/home/felipe/projects_study/automation/beremiz/related-projects/ioton_plc/matiec/lib/C
ARM_GCC_TOOLCHAIN_DIR ?=/home/felipe/projects_study/automation/beremiz/related-projects/ioton_plc/gcc-arm-none-eabi-4_9-2015q3
STM32FLASH_DIR ?=/home/felipe/projects_study/automation/beremiz/related-projects/ioton_plc/stm32flash

# BUILD CONFIG 
LDSCRIPT = src/bsp/stm32f4/stm32f4disco-rte.ld

PREFIX	?= arm-none-eabi

CC		=  ${ARM_GCC_TOOLCHAIN_DIR}/bin/$(PREFIX)-gcc
LD		=  ${ARM_GCC_TOOLCHAIN_DIR}/bin/$(PREFIX)-g++
OBJCOPY	=  ${ARM_GCC_TOOLCHAIN_DIR}/bin/$(PREFIX)-objcopy
OBJDUMP =  ${ARM_GCC_TOOLCHAIN_DIR}/bin/$(PREFIX)-objdump
GDB		=  ${ARM_GCC_TOOLCHAIN_DIR}/bin/$(PREFIX)-gdb
SIZE	=  ${ARM_GCC_TOOLCHAIN_DIR}/bin/$(PREFIX)-size

EXECUTABLE = tonfit_rte
BINARY = $(EXECUTABLE).elf
HEX	   = $(EXECUTABLE).hex
BIN    = $(EXECUTABLE).bin
LIST   = $(EXECUTABLE).list
SREC   = $(EXECUTABLE).srec

SRC_DIR=./src

# -g flag indicated in issue  #2 RTE (https://github.com/nucleron/RTE/issues/2) (maybe something related with ABI?)
CFLAGS += -g -mthumb \
		-std=gnu90 \
		-mcpu=cortex-m4 \
		-mfloat-abi=hard \
		-mfpu=fpv4-sp-d16 \
		-fmessage-length=0 \
		-fno-builtin \
		-fno-strict-aliasing \
		-ffunction-sections \
		-fdata-sections \
		-DSTM32F4 \
		-I$(LIBOPENCM3_DIR)/include \
		-I$(MATIEC_C_INCLUDE_DIR) \
		-I./src \
		-I./src/bsp/common \
		-I./src/bsp/common/stm32/ \
		-I./src/bsp/common/stm32/f4/ \
		-I./src/bsp/stm32f4 \
		-I.

LDFLAGS 	+= -mthumb \
			   -mcpu=cortex-m4 \
			   -mfloat-abi=hard \
               -nostdlib \
               -Xlinker \
               -Map=$(EXECUTABLE).map \
               -T$(LDSCRIPT) -Wl,--gc-sections,-lgcc \
			   -L$(LIBOPENCM3_DIR)/lib \
			   -L$(LIBOPENCM3_DIR)/lib/stm32/f4 \
			   -L$(ARM_GCC_TOOLCHAIN_DIR)/lib/gcc/arm-none-eabi/4.9.3/armv7e-m/fpu \
			   -s # issue #2 (https://github.com/nucleron/RTE/issues/2)
		
SOURCES		= 	main.c \
				xprintf.c \
				plc_libc.c \
				plc_iom.c \
				plc_glue_rte.c \
				frac_div.c \
				plc_app_default.c  \
				plc_dbg.c  \
				dbnc_flt.c  \
				bsp/stm32f4/plc_hw.c  \
				bsp/common/stm32/plc_wait_tmr.c \
				bsp/common/stm32/f4/plc_backup.c \
				bsp/common/stm32/f4/plc_rtc.c \
				bsp/common/stm32/plc_diag.c   \
				bsp/common/stm32/f4/plc_serial.c \
				bsp/common/stm32/f4/plc_gpio.c \
				bsp/common/stm32/f4/plc_isr_stubs.c \
				bsp/common/stm32/f4/plc_clock.c \
				bsp/common/plc_tick.c 
		   
OBJS		= $(SOURCES:.c=.o)

#OBJS		+= $(BINARY).o 

CSOURCES = $(addprefix $(SRC_DIR)/,$(SOURCES))
COBJECTS = $(addprefix $(SRC_DIR)/,$(OBJS))


all: $(BINARY) $(CSOURCES) $(HEX) $(BIN) $(SREC) $(LIST)
	@echo "finished"
	$(SIZE) $(BINARY)		

$(BINARY): $(COBJECTS) $(LDSCRIPT)
	$(LD) $(COBJECTS) -lopencm3_stm32f4 $(LDFLAGS)  -o $@
	

$(SRC_DIR)/%.o: $(SRC_DIR)/%.c
	$(CC) $(CFLAGS) -c $< -o $@

$(HEX): $(BINARY) $(CSOURCES)
	$(OBJCOPY) -Oihex $(BINARY) $@

$(BIN): $(BINARY) $(CSOURCES)
	$(OBJCOPY) -Obinary $(BINARY) $@

$(SREC): $(BINARY) $(CSOURCES)
	$(OBJCOPY) -Osrec $(BINARY) $@

$(LIST): $(BINARY) $(CSOURCES)
	$(OBJDUMP) -S $(BINARY) > $@

clean:
	rm -f $(SRC_DIR)/*.o *.d *.elf *.bin *.hex *.srec *.list *.map *.log
	rm -f src/bsp/common/*.o
	rm -f src/bsp/common/stm32/*.o
	rm -f src/bsp/common/stm32/f4/*.o
	rm -f src/bsp/stm32f4/*.o
	#$(MAKE) -C $(LIBOPENCM3_DIR) clean

flash_hex: $(HEX)
	stm32flash -w $< -v -g 0x0 -S 0x08000000 /dev/ttyUSB0
