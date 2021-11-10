# Base64MathDLL
The source code for the Win64 Base64Math Library written in x86-64 Assembly. 

Note, the Alphabet used to represent numbers in base 64 is non-standard, and is intended to be similar to hexadecimal.

The alphabet is: 0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz@$, with the offset of the symbol in this list giving its place value.

Currently, this DLL provides two functions: an addition and subtraction function.
Numbers which get passed to these functions MUST BE EXACTLY 8 characters in length. 
Any less gives undefined results and any more and the DLL ignores the additional digits. Ensure the calling application pads out all data buffers to 8 chars before
calling the functions within.
