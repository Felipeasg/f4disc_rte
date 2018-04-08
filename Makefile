# extracted from https://github.com/torvalds/linux/blob/master/scripts/Lindent
LINDENT=indent -npro -kr -i8 -ts8 -sob -l80 -ss -ncs -cp1 -il0


LIBOPENCM3_DIR ?= /home/felipe/projects_study/automation/beremiz/related-projects/ioton_plc/libopencm3
MATIEC_C_INCLUDE_DIR ?=/home/felipe/projects_study/automation/beremiz/related-projects/ioton_plc/matiec/lib/C
ARM_GCC_TOOLCHAIN_DIR ?=/home/felipe/projects_study/automation/beremiz/related-projects/ioton_plc/gcc-arm-none-eabi-4_9-2015q3
STM32FLASH_DIR ?=/home/felipe/projects_study/automation/beremiz/related-projects/ioton_plc/stm32flash

# BUILD CONFIG 
LDSCRIPT = stm32f4disco-rte.ld

PREFIX	?= arm-none-eabi

CC		=  ${ARM_GCC_TOOLCHAIN_DIR}/bin/$(PREFIX)-gcc
LD		=  ${ARM_GCC_TOOLCHAIN_DIR}/bin/$(PREFIX)-g++
OBJCOPY	=  ${ARM_GCC_TOOLCHAIN_DIR}/bin/$(PREFIX)-objcopy
OBJDUMP =  ${ARM_GCC_TOOLCHAIN_DIR}/bin/$(PREFIX)-objdump
GDB		=  ${ARM_GCC_TOOLCHAIN_DIR}/bin/$(PREFIX)-gdb
SIZE	=  ${ARM_GCC_TOOLCHAIN_DIR}/bin/$(PREFIX)-size

EXECUTABLE = f4disc_rte
BINARY = $(EXECUTABLE).elf
HEX	   = $(EXECUTABLE).hex
BIN    = $(EXECUTABLE).bin
LIST   = $(EXECUTABLE).lst
SREC   = $(EXECUTABLE).srec


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
		
SOURCES		= main.c xprintf.c plc_libc.c plc_clock.c plc_wait_tmr.c plc_iom.c plc_backup.c plc_rtc.c plc_glue_rte.c plc_diag.c   plc_isr_stubs.c frac_div.c plc_tick.c plc_serial.c plc_app_default.c  plc_dbg.c  plc_gpio.c dbnc_flt.c  plc_hw.c  
		   
OBJS		= $(SOURCES:.c=.o)

#OBJS		+= $(BINARY).o 




all: $(BINARY) $(SOURCES) $(HEX) $(BIN) $(SREC) $(LIST)
	@echo "finished"
	$(SIZE) $(BINARY)		

$(BINARY): $(OBJS) $(LDSCRIPT)
	$(LD) $(OBJS) -lopencm3_stm32f4 $(LDFLAGS)  -o $@
	

%.o: %.c Makefile
	$(CC) $(CFLAGS) -c $< -o $@

$(HEX): $(BINARY) $(SOURCES)
	$(OBJCOPY) -Oihex $(BINARY) $@

$(BIN): $(BINARY) $(SOURCES)
	$(OBJCOPY) -Obinary $(BINARY) $@

$(SREC): $(BINARY) $(SOURCES)
	$(OBJCOPY) -Osrec $(BINARY) $@

$(LIST): $(BINARY) $(SOURCES)
	$(OBJDUMP) -S $(BINARY) > $@

clean:
	rm -f *.o *.d *.elf *.bin *.hex *.srec *.list
	#$(MAKE) -C $(LIBOPENCM3_DIR) clean

flash_hex: $(HEX)
	stm32flash -w $< -v -g 0x0 -S 0x08000000 /dev/ttyUSB0
