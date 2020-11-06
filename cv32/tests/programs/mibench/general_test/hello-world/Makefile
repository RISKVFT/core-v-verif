ASM=$(realpath $(pwd)/../../../../core/asm)

SRC=$(wildcard *.c)
SRCS=$(wildcard *.s)


check: 
	if [ -z "$(SRCS)" -a "$(SRC)" -ne "" ]; then 
		OBJC=$(SRC:.c=.elf);
		all: $(OBJC)
		echo "C"
	elif [ $(SRCS) -ne "" -a $(SRC) -ne ""  ]; then
		OBJSC=$(SRC:.c=.elf);
		all: $(OBJSC)
		echo "SC"
	else
		OBJS=$(SRC:.s=.elf);
		all: $(OBJS)
		echo "S"
	fi

# This target selected if both %.c and %.S exist
# Note that this target will pass both sources to gcc


$(OBJSC): $(SRC) $(SRCS)
	make -C ${BSP}
	test_asm_src=$(basename )
	${CC} ${OPT} -o ./../../out/$@ $^ ${LD}

# This target selected if only %.c
$(OBJC): $(SRC)
	make -C ${BSP}
	test_asm_src=$(basename )
	${CC} ${OPT} -o ./../../out/$@ $^ ${LD}

# This target selected if only %.S exists
$(OBJS): $(SRCS)
	make -C ${BSP}
	${CC} ${OPT} -v -o ./../../out/$@ -I $(ASM) $^ ${LD}

.PHONY: clean
clean:
	rm -rf *.elf *.o


