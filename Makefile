##
## This file was part of the libopencm3 project, and has been
## modified for inclusion in the rotate-chars project.
##
## Copyright (C) 2009 Uwe Hermann <uwe@hermann-uwe.de>
## Copyright (C) 2010 Piotr Esden-Tempski <piotr@esden.net>
## Copyright (C) 2011 Fergus Noble <fergusnoble@gmail.com>
## Copyright (C) 2012 Kendrick Shaw <kms15@case.edu>
## Copyright (C) 2012,2016 Eric Herman <eric@freesa.org>
##
## This library is free software: you can redistribute it and/or modify
## it under the terms of the GNU Lesser General Public License as published by
## the Free Software Foundation, either version 3 of the License, or
## (at your option) any later version.
##
## This library is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU Lesser General Public License for more details.
##
## You should have received a copy of the GNU Lesser General Public License
## along with this library.  If not, see <http://www.gnu.org/licenses/>.
##

# extracted from https://github.com/torvalds/linux/blob/master/scripts/Lindent
LINDENT=indent -npro -kr -i8 -ts8 -sob -l80 -ss -ncs -cp1 -il0

BINARY = main
# Uncomment this line if you want to use the installed (not local) library.
#TOOLCHAIN_DIR := $(shell dirname `which $(CC)`)/../$(PREFIX)
#LIBOPENCM3_DIR   = $(TOOLCHAIN_DIR)
#LIBOPENCM3_DIR   = ../libopencm3-git
LIBOPENCM3_DIR = ../libopencm3-nucleron
#LDSCRIPT = ../stm32f4-discovery.ld
#LDSCRIPT = $(LIBOPENCM3_EXAMPLES_DIR)/examples/stm32/f4/stm32f4-discovery/stm32f4-discovery.ld
LDSCRIPT = stm32f4disco-rte.ld

PREFIX	?= arm-none-eabi
#PREFIX ?= arm-none-eabi
# PREFIX		?= arm-elf
CC		= $(PREFIX)-gcc
LD		= $(PREFIX)-gcc
OBJCOPY		= $(PREFIX)-objcopy
OBJDUMP		= $(PREFIX)-objdump
GDB		= $(PREFIX)-gdb

CFLAGS		+= -Os -g -Wall -Wextra -I$(LIBOPENCM3_DIR)/include -I$(MATIEC_C_INCLUDE_PATH) -I./ \
		 -Wimplicit-function-declaration -Wundef -Wshadow \
		 -Wredundant-decls -Wmissing-prototypes -Wstrict-prototypes \
		 -fno-common -ffunction-sections -fdata-sections \
		 -mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16 \
		 -MD -DSTM32F4

#CFLAGS += -mthumb \
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
		-I$(LIBOPENCM3_DIR)/include -I$(MATIEC_C_INCLUDE_PATH) -I.

LDSCRIPT	?= $(BINARY).ld
LDFLAGS		+= -lc -lnosys -L$(LIBOPENCM3_DIR)/lib \
			 -L$(LIBOPENCM3_DIR)/lib/stm32/f4 \
		   -T$(LDSCRIPT) -nostartfiles -Wl,--gc-sections \
		   -mthumb -mcpu=cortex-m4 -mfloat-abi=hard -mfpu=fpv4-sp-d16

OBJS		+= $(BINARY).o plc_clock.o plc_wait_tmr.o plc_iom.o plc_backup.o plc_rtc.o plc_glue_rte.o plc_diag.o   plc_isr_stubs.o frac_div.o plc_tick.o plc_serial.o plc_app_default.o  plc_dbg.o  plc_gpio.o dbnc_flt.o  plc_hw.o  

#OBJS		+= $(BINARY).o 

OOCD		?= openocd
OOCD_INTERFACE	?= flossjtag
OOCD_BOARD	?= olimex_stm32_h103
# Black magic probe specific variables
# Set the BMP_PORT to a serial port and then BMP is used for flashing
BMP_PORT        ?=

.SUFFIXES: .elf .bin .hex .srec .list .images
.SECONDEXPANSION:
.SECONDARY:

all: images

images: $(BINARY).images

flash: $(BINARY).flash

#rotate-chars-stm32f.o: rotate-chars-stm32f4.c rotate-chars-usb-descriptors.h
#tick_blink.o: tick_blink.c


%.images: %.bin %.hex %.srec %.list
	@echo "Success."

%.bin: %.elf
	$(OBJCOPY) -Obinary $(*).elf $(*).bin

%.hex: %.elf
	$(OBJCOPY) -Oihex $(*).elf $(*).hex

%.srec: %.elf
	$(OBJCOPY) -Osrec $(*).elf $(*).srec

%.list: %.elf
	$(OBJDUMP) -S $(*).elf > $(*).list

%.elf: $(OBJS) $(LDSCRIPT) $(LIBOPENCM3_DIR)/lib/stm32/f4/libopencm3_stm32f4.a
	$(LD) -o $(*).elf $(OBJS) -lopencm3_stm32f4 $(LDFLAGS)

%.o: %.c Makefile
	$(CC) $(CFLAGS) -o $@ -c $<

$(LIBOPENCM3_DIR)/lib/stm32/f4/libopencm3_stm32f4.a : $(LIBOPENCM3_DIR)/Makefile
	$(MAKE) -C $(LIBOPENCM3_DIR) lib


clean:
	rm -f *.o *.d *.elf *.bin *.hex *.srec *.list
	#$(MAKE) -C $(LIBOPENCM3_DIR) clean

%.flash: %.bin
	st-flash write $< 0x8000000

.PHONY: images clean

-include $(OBJS:.o=.d)
