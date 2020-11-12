#include <stdio.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <fcntl.h>

int main(){

	int i=3;
	int x;
	i=i+5;
	int f;


	printf("%d", i);
	f=open("test.txt", O_CREAT);
	//fscanf(f,"%d", &x);
	//printf("%d", x);
	close(f);
	
}
