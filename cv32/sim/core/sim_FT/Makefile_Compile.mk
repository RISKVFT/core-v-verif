DIRNAME=$(shell basename $(CURDIR))
ASM="./../../../../core/asm"
$(info $(DIRNAME))
$(info $(ASM))

SRCS=$(wildcard *.S)
SRCH=$(wildcard *.h)

ifeq ($(shell [[ -f $(DIRNAME).c && -z "$(SRCS)" ]] && echo true), true)
OBJ=$(DIRNAME)_C
else ifeq ($(shell [[ -f $(DIRNAME).c ]] && echo true), true)
OBJ=$(DIRNAME)_CS
else
OBJ=$(DIRNAME)_S 
endif

all: verify clean ${OBJ}


verify:
	@echo -e "\e[0;91mTARGET: $(OBJ)\e[0m"
	@echo -e "\e[0;91mS files: $(SRCS)\e[0m"


$(DIRNAME)_C: $(DIRNAME).c $(SRCH)
	make -C ${BSP}
	test_asm_src=$(basename )
	${CC} ${OPT} -o ./../../out/$(DIRNAME).elf $^ ${LD}

$(DIRNAME)_CS: $(DIRNAME).c $(SRCS) $(SRCH)
	make -C ${BSP}
	test_asm_src=$(basename )
	${CC} ${OPT} -o ./../../out/$(DIRNAME).elf $^ ${LD}

$(DIRNAME)_S: $(SRCS) $(SRCH)
	make -C ${BSP}
	#echo -e "\e[0;91m ${CC} ${OPT} -v -o ./../../out/$@.elf -I $(ASM) $^ ${LD} \e[0m"
	${CC} ${OPT} -v -o ./../../out/$(DIRNAME).elf -I $(ASM) $^ ${LD}


.PHONY: clean
clean:
	rm -rf *.elf *.o




























	



	


