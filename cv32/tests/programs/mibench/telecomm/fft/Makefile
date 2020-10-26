OBJ = main.o fftmisc.o  fourierf.o
FILE = main.c fftmisc.c  fourierf.c
CFLAGS = -Os -g -static -mabi=ilp32 -march=rv32imc -Wall -pedantic -v

fft: ${OBJ} Makefile
	${CC} ${CFLAGS} ${OBJ} -o fft -nostartfiles ${LD} -lm
fftmisc.o: fftmisc.c
	${CC} ${CFLAGS} -c fftmisc.c
fourierf.o: fourierf.c
	${CC} ${CFLAGS} -c fourierf.c
main.o: main.c
	${CC} ${CFLAGS} -c main.c

clean:
	rm -rf *.o fft output*
