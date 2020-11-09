FILE1 = qsort_small.c
FILE2 = qsort_large.c

all: qsort_small qsort_large objects

qsort_small: qsort_small.c Makefile
	${CC} -static qsort_small.c ${OPT} -o ../../out/qsort_small.${TGT} ${LD} -lm
qsort_large: qsort_large.c Makefile
	${CC} -static qsort_large.c ${OPT} -o ../../out/qsort_large.${TGT} ${LD} -lm
objects:
	${CC} ${OPT} qsort_small.c -c -o ../../out/qsort_small.o.${TGT} ${LD} -lm
	${CC} ${OPT} qsort_large.c -c -o ../../out/qsort_large.o.${TGT} ${LD} -lm
clean:
	rm -rf qsort_small qsort_large output*
