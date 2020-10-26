FILE1 = basicmath_small.c   rad2deg.c  cubic.c   isqrt.c
FILE2 = basicmath_large.c   rad2deg.c  cubic.c   isqrt.c
CFLAGS = -Os -g -static -mabi=ilp32 -march=rv32imc -Wall -pedantic -v

all: basicmath_small basicmath_large

basicmath_small: ${FILE1} Makefile
	$(CC) $(CFLAGS) ${FILE1} -o basicmath_small -nostartfiles ${LD} -lm
basicmath_large: ${FILE2} Makefile
	$(CC) $(CFLAGS) ${FILE2} -o basicmath_large -nostartfiles ${LD} -lm

clean:
	rm -rf basicmath_small basicmath_large output*
