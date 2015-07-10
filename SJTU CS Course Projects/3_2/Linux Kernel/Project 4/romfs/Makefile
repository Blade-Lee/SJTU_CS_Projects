#
# Makefile for the linux RomFS filesystem routines.
#



obj-m := romfs.o

romfs-y := super.o storage.o

KDIR := /lib/modules/$(shell uname -r)/build

EXTRA_FLAGS := -I(PWD)

PWD := $(shell pwd)

all:

	make -C $(KDIR) M=$(PWD) modules

clean:

	rm *.o *.ko *.mod.c Module.symvers modules.order -f
