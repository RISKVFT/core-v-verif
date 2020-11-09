all: susan objects

susan: susan.c Makefile
	${CC} -static ${OPT} -o ../../out/susan.${TGT} ${LD} susan.c -lm 
objects:
	${CC} ${OPT} susan.c -c -o ../../out/susan.o.${TGT} ${LD} -lm

clean:
	rm -rf susan output*
