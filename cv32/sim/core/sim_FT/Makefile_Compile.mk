CORE_V_VERIF=/home/thesis/marcello.neri/Desktop/core-v-verif
DIRNAME=$(shell basename ${CURDIR})
ASM="$(CORE_V_VERIF)/cv32/sim/core/asm"
$(info $(DIRNAME))
$(info $(ASM))

SRCS=$(wildcard *.S)
SRCH=$(wildcard *.h)

is_c_file=$(shell if [ -e $(wildcard ${DIRNAME}.c) ]; then echo "1"; else echo "0"; fi)
is_sc_file=$(shell if [ -z "$(SRCS)" ]; then echo "1"; else echo "0"; fi)
is_s_file=$(shell if [ -e $(wildcard ${DIRNAME}.S) ]; then echo "1"; else echo "0"; fi)


ifeq ("$(is_c_file)", "1")
ifeq ("$(is_sc_file)", "1")
OBJ=$(DIRNAME)_C
else
OBJ=$(DIRNAME)_CS
endif
else ifeq ("$(is_s_file)", "1")
OBJ=$(DIRNAME)_S
endif

all: verify clean ${OBJ} elf-to-hex

BSP=$(CORE_V_VERIF)/cv32/bsp
OPT=-Os -g -static -mabi=ilp32 -march=rv32imc -Wall -pedantic
CC=/software/pulp/riscv/bin/riscv32-unknown-elf-
LD=-nostartfiles --specs=nosys.specs -nostdlib -L ${BSP} -lcv-verif -Wl,--start-group -lc -lgcc -lc -lm -Wl,--end-group -L ${BSP} -lcv-verif -T ${BSP}/link.ld


verify:
	@echo -e "\e[0;91mTARGET: $(OBJ)\e[0m"
	@echo -e "\e[0;91mS files: $(SRCS)\e[0m"
	@echo -e "\e[0;91m $(a) $(b) $(c)\e[0m"


$(DIRNAME)_C: $(DIRNAME).c $(SRCH)
	make -C ${BSP}
	test_asm_src=$(basename )
	${CC}gcc ${OPT} $^ -o $(DIRNAME).elf ${LD}

$(DIRNAME)_CS: $(DIRNAME).c $(SRCS) $(SRCH)
	make -C ${BSP}
	test_asm_src=$(basename )
	${CC}gcc ${OPT} $^ -o $(DIRNAME).elf ${LD}

$(DIRNAME)_S: $(SRCS) $(SRCH)
	make -C ${BSP}
	#echo -e "\e[0;91m ${CC} ${OPT} -v -o ./../../out/$@.elf -I $(ASM) $^ ${LD} \e[0m"
	${CC}gcc ${OPT} $^ -v -o $(DIRNAME).elf -I $(ASM) ${LD}

elf-to-hex:
	$(CC)objcopy -O verilog $(DIRNAME).elf $(DIRNAME).hex \
        	--change-section-address  .debugger=0x3FC000 \
        	--change-section-address  .debugger_exception=0x3FC800
	# Save elf properties
	$(CC)readelf -a $(DIRNAME).elf > $(DIRNAME).readelf
	$(CC)objdump -D -S $(DIRNAME).elf > $(DIRNAME).objdump
	

.PHONY: clean
clean:
	rm -rf *.elf *.o




























	



	


