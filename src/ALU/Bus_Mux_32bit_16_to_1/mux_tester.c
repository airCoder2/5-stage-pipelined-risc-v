#include <stdio.h>
#include <stdlib.h>


int main(int argc, char **argv){

    if (argc != 2) printf("You can use it as follows: 0xXXXX {number_from_0_to_15}\n\n"); return 0;
	

	unsigned int random; // max max 16 bit number
	unsigned int select; // max 31
	unsigned int one = 1;

	sscanf(argv[1], "0x%x", &random);
	sscanf(argv[2], "%d", &select);



	printf("\nthe %d bit of 0x%08X is:\n%d\n\n", (int)select, (int)random, (random >> select)&one);


	return 0;
}
