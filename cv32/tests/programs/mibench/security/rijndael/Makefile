CFLAGS = -Os -g -static -mabi=ilp32 -march=rv32imc -Wall -pedantic -v


rijndael: aes.c aes.h aestab.h aesxam.c Makefile
	${CC} ${CFLAGS} aes.c aesxam.c -o rijndael -nostartfiles ${LD}

clean:z
	rm -rf rijndael output*
