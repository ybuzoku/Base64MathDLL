// Base64Mat.h - Contains exposed declarations of math functions
#pragma once

#ifdef BASE64MATH_EXPORTS
#define BASE64MATH_API __declspec(dllexport)
#else
#define BASE64MATH_API __declspec(dllimport)
#endif

extern "C" BASE64MATH_API int add64(char*, char*, char*, int);
extern "C" BASE64MATH_API int sub64(char*, char*, char*, int);


