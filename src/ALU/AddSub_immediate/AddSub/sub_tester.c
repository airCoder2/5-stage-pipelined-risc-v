#include <stdio.h>
#include <stdbool.h>
#include <stdlib.h>

signed int sub(signed int a, signed int b, bool* is_overflow){

	signed int result = a - b;

	if ((a > 0 && b < 0 && result < 0) || (a < 0 && b > 0 && result > 0)) 
		*is_overflow = true;

	else *is_overflow = false;
	return result;
}


int main(int argc, char *argv[]) {
    if (argc != 3) {
        printf("Usage: %s <A_hex> <B_hex>\n", argv[0]);
        return 1;
    }

    // Parse input hex numbers
    signed int A = (signed int)strtol(argv[1], NULL, 16);
    signed int B = (signed int)strtol(argv[2], NULL, 16);

	bool is_overflow;

	signed int result = sub(A, B, &is_overflow);

	printf("\n--- SUB ---\n");
	printf("A: %X\nB: %X\n", A, B);
	printf("A - B is: 0x%X\nOverflow: %s\n\n",result, is_overflow? "yes":"no");

	return 0;
}
