FILE1 = basicmath_small.c   rad2deg.c  cubic.c   isqrt.c
FILE2 = basicmath_large.c   rad2deg.c  cubic.c   isqrt.c


all: basicmath_small basicmath_large 

basicmath_small: ${FILE1} Makefile
	${CC} ${OPT} ${FILE1} -o ../../out/basicmath_small.${TGT} ${LD} -lm
basicmath_large: ${FILE2} Makefile
	${CC} ${OPT} ${FILE2} -o ../../out/basicmath_large.${TGT} ${LD} -lm  
objects:
	${CC} ${OPT} basicmath_small.c -c -o ../../out/basicmath_small.o.${TGT} ${LD} -lm
	${CC} ${OPT} basicmath_large.c -c -o ../../out/basicmath_large.o.${TGT} ${LD} -lm
	${CC} ${OPT} rad2deg.c -c -o ../../out/rad2deg.o.${TGT} ${LD} -lm
	${CC} ${OPT} cubic.c -c -o ../../out/cubic.o.${TGT} ${LD} -lm
	${CC} ${OPT} isqrt.c -c -o ../../out/isqrt.o.${TGT} ${LD} -lm

clean:
	rm -rf basicmath_small basicmath_large output*
