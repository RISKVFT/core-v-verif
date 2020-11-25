BASEDIR=${CURDIR}

all: elf-to-hex

.ONESHELL:
elf-to-hex: $(BASEDIR)/*
        for file in $^; do \
        if [[ $$file =~ .elf ]] ; then \
	$(CC)objcopy -O verilog $$file.elf $$file.hex \
	--change-section-address  .debugger=0x3FC000 \
	--change-section-address  .debugger_exception=0x3FC800 \
	fi \
	done
