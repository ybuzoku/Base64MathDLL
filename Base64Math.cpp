// Define the exported functions for the DLL.
#include "pch.h"
#include "Base64Math.h"
#include "AssemblyWrapper.h"

int add64(char* input1, char* input2 , char* returnBuffer, int lengthOfReturnBuffer) {
	return add64A(input1, input2, returnBuffer, lengthOfReturnBuffer);
}

int sub64(char* input1, char* input2, char* returnBuffer, int lengthOfReturnBuffer) {
	return sub64A(input1, input2, returnBuffer, lengthOfReturnBuffer);
}