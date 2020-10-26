# By default, the code is compiled for a "big endian" machine.
# To compile on a "little endian" machine set the LITTLE_ENDIAN flag.
# To make smaller object code, but run a little slower, don't use UNROLL_LOOPS.
# To use NIST's modified SHA of 7/11/94, define USE_MODIFIED_SHA

CFLAGS = -Os -g -static -mabi=ilp32 -march=rv32imc -Wall -pedantic -v

sha:	sha_driver.o sha.o
	$(CC) $(CFLAGS) sha_driver.o sha.o -o $@ -nostartfiles ${LD}

clean:
	rm -rf *.o sha output*
