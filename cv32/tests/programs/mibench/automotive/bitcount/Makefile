FILE = bitcnt_1.c bitcnt_2.c bitcnt_3.c bitcnt_4.c bitcnts.c bitfiles.c bitstrng.c bstr_i.c bitarray.c 
#FILE = prova.c

all: bitcnts

bitcnts: ${FILE} Makefile *.h
	make -C ${BSP}
	${CC} ${OPT} ${FILE} -o ./../../out/bitcnts.${TGT} ${LD} #-bind_at_load -lm  -static 
	#${CC} -v -Wl,--trace ${OPT} ${FILE} -o ../../out/bitcnts.${TGT} ${LD} #-bind_at_load -lm  -static 
objects:
	${CC} ${OPT} bitcnt_1.c -c -o bitcnt_1.o ${LD} -lm
	${CC} ${OPT} bitcnt_2.c -c -o bitcnt_2.o ${LD} -lm
	${CC} ${OPT} bitcnt_3.c -c -o bitcnt_3.o ${LD} -lm
	${CC} ${OPT} bitcnt_4.c -c -o bitcnt_4.o ${LD} -lm 
	${CC} ${OPT} bitcnts.c -c -o  bitcnts.o ${LD} -lm
	${CC} ${OPT} bitfiles.c -c -o bitfiles.o ${LD} -lm
	${CC} ${OPT} bitstrng.c -c -o bitstring.o ${LD} -lm
	${CC} ${OPT} bstr_i.c -c -o bstr_i.o ${LD} -lm

clean:
	rm -rf bitcnts output*
