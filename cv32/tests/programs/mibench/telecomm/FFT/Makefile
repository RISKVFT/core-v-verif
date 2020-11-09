OBJ = main.o fftmisc.o  fourierf.o
FILE = main.c fftmisc.c  fourierf.c

all: fft objects clean

fft:
	${CC} ${OPT} -static ${FILE} -o ../../out/fft.${TGT} ${LD} -lm

objects:
	${CC} ${OPT} main.c -c -o ../../out/fftmain.o ${LD} -lm
	${CC} ${OPT} fftmisc.c -c -o ../../out/fftmisc.o ${LD} -lm
	${CC} ${OPT} fourierf.c -c -o ../../out/fourierf.o ${LD} -lm

clean:
	rm -rf ../../out/*.o fft output*
