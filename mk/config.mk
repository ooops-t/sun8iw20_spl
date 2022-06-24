

# Load generated board configuration
sinclude $(TOPDIR)/include/autoconf.mk
ifneq ($(SKIP_AUTO_CONF),yes)
sinclude $(TOPDIR)/autoconf.mk
endif

AS		= $(CROSS_COMPILE)as
LD		= $(CROSS_COMPILE)ld
CC		= $(CROSS_COMPILE)gcc
CPP		= $(CC) -E
AR		= $(CROSS_COMPILE)ar
NM		= $(CROSS_COMPILE)nm
LDR		= $(CROSS_COMPILE)ldr
STRIP		= $(CROSS_COMPILE)strip
OBJCOPY		= $(CROSS_COMPILE)objcopy
OBJDUMP		= $(CROSS_COMPILE)objdump

##########################################################
ifeq (x$(CPU), xriscv64)
MARCH := rv64gc
MABI := lp64

SPLINCLUDE    := \
		-I$(SRCTREE)/include \
		-I$(SRCTREE)/include/arch/riscv/ \
		-I$(SRCTREE)/include/configs/ \
		-I$(SRCTREE)/include/arch/$(PLATFORM)/ \
		-I$(SRCTREE)/include/openssl/

 COMM_FLAGS := \
	-g  -Os   -fno-common \
	-ffunction-sections \
	-fno-builtin -ffreestanding \
	-D__KERNEL__  \
	-march=$(MARCH)\
	-mabi=$(MABI)\
	-fno-stack-protector \
	-Wall \
	-Werror \
	-Wstrict-prototypes \
	-Wno-format-security \
	-Wno-format-nonliteral \
	-fno-delete-null-pointer-checks \
	-pipe

else

ifeq ($(CFG_SUNXI_USE_NEON),y)
FLOAT_FLAGS := -mfloat-abi=softfp
else
FLOAT_FLAGS := -msoft-float
endif

SPLINCLUDE    := \
		-I$(SRCTREE)/include \
		-I$(SRCTREE)/include/arch/arm/ \
		-I$(SRCTREE)/include/configs/ \
		-I$(SRCTREE)/include/arch/$(PLATFORM)/ \
		-I$(SRCTREE)/include/openssl/

 COMM_FLAGS := \
	-g  -Os   -fno-common -mfpu=neon  $(FLOAT_FLAGS) \
	-ffunction-sections \
	-fno-builtin -ffreestanding \
	-D__KERNEL__  \
	-DCONFIG_ARM -D__ARM__ \
	-D__NEON_SIMD__  \
        -march=armv7-a -mtune=cortex-a7 \
	-mabi=aapcs-linux \
	-mthumb-interwork \
	-fno-stack-protector \
	-Wall \
	-Wstrict-prototypes \
	-Wno-format-security \
	-Wno-format-nonliteral \
	-fno-delete-null-pointer-checks \
	-pipe
#	-Werror \

 COMM_FLAGS += -mno-unaligned-access
endif

SPLINCLUDE += -I$(SRCTREE)/libfdt

C_FLAGS += $(SPLINCLUDE)   $(COMM_FLAGS)
S_FLAGS += $(SPLINCLUDE)   -D__ASSEMBLY__  $(COMM_FLAGS)
LDFLAGS_GC += --gc-sections
#LDFLAGS += --gap-fill=0xff
export LDFLAGS_GC
###########################################################

###########################################################
PLATFORM_LIBGCC = -L $(shell dirname `$(CC) $(CFLAGS) -print-libgcc-file-name`) -l:$(shell basename `$(CC) $(CFLAGS) -print-libgcc-file-name`)
export PLATFORM_LIBGCC
###########################################################

# Allow boards to use custom optimize flags on a per dir/file basis
ALL_AFLAGS = $(AFLAGS)  $(PLATFORM_RELFLAGS) $(S_FLAGS)
ALL_CFLAGS = $(CFLAGS)  $(PLATFORM_RELFLAGS) $(C_FLAGS)
export ALL_CFLAGS ALL_AFLAGS


$(obj)%.o:	%.S
	$(Q)$(CC)  $(ALL_AFLAGS) -o $@ $< -c
	@echo " CC      "$< ...
$(obj)%.o:	%.c
	$(Q)$(CC)  $(ALL_CFLAGS) -o $@ $< -c
	@echo " CC      "$< ...

#########################################################################

# If the list of objects to link is empty, just create an empty built-in.o
cmd_link_o_target = $(if $(strip $1),\
			  $(LD) $(LDFLAGS) -r -o $@ $1,\
		      rm -f $@; $(AR) rcs $@ )

#########################################################################

