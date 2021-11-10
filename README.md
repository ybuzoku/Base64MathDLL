# Base64MathDLL
The source code for the Win64 Base64Math Library written in x86-64 Assembly. 

Current Hardware/Software Requirements: 
- 64-bit Windows
- x86-64 CPU

Note, the Alphabet used to represent numbers in base 64 is non-standard, and is intended to be similar to hexadecimal.

The alphabet is: 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz@$, with the offset of the symbol in this list giving its place value.

 - Currently, this DLL provides two functions: an addition and subtraction function, though the subtraction ALWAYS computes the larger number minus the smaller.
 - Each input number must be a string of EXACTLY 8 ASCII encoded characters.
 - The caller MUST pass a pointer to the location in memory for where to save the result, known as the returnBuffer. The caller must ensure that the returnBuffer is 
 	large enough to safely store the sum or difference of two numbers. I recommend a 9 char buffer for addition and subtraction.
 - All numbers are little endian and must be read and written as such.

C prototypes for the functions in the DLL:

	 int add64A(char* firstNumberPtrASCIIEncoded, char* secondNumberPtrASCIIEncoded, char* returnBufferPtr, int lengthOfReturnBuffer);
	 
	 int sub64A(char*, char*, char*, int);
   
For examples of interfacing this DLL with MSVC/C++ and C#, please see my repositories B64DllTestClient (MSVC/C++) and Base64PInvokeTest (C#).
