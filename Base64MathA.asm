;------------------------------------------------------------------------------
; Base 64 arithmetic library, that impliments arithmetic operations on numbers 
;  in base 64.
; A bit long winded but fast as it converts first down to base 16 and 
;	then uses the CPU's ALU to carry out the calculations.
;
; Written by: Yll Buzoku
; Date:		  08/11/2021
;------------------------------------------------------------------------------
;
;rax, rcx, rdx, r8, r9, r10, r11 can be trashed
;rbx, rbp, rdi, rsi, rsp, r12, r13, r14, r15 MUST BE SAVED before returning to caller
;
;----------------Equates----------------:
numBase		equ		40h
;---------------------------------------:

STACK   SEGMENT PARA 'STACK'
	dq 64 dup(?)	;Allocate a 512 byte/64 qword stack
stk		label	qword
STACK	ENDS

DATA   SEGMENT		'DATA'
digits		db '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz@$'	
			;Place value digits for base 64
DATA	ENDS

MAIN   SEGMENT		'CODE'
;-----------------------------------------------------------
; C prototypes for these functions				
;		 int add64A(char*, char*, char*, int);
;		 int sub64A(char*, char*, char*, int);
;														   
; Input: rcx = Ptr to first 8 character number string      
;		 rdx = Ptr to second 8 character number string     
;		 r8  = Ptr to alloc'd space for return result      
;		 r9  = Length of buffer pointed to by r8 in bytes  
;														   
; Ensure that all number strings are padded with 0's	   
; For addition allocate for return a 9 char buffer		   							   
; For multiplication, please allocate a 16 char buffer     
;														   
; Output: rax = Return code, 0 = Success				   
;							 1 = Invalid Argument		   
;----------------------------------------------------------

add64A	PROC	PUBLIC
	push rbp		;Save bp on caller stack
	mov rbp, rsp	;Move the current stack pointer to BP
	mov rsp, OFFSET stk	;Repoint to our internal stack

	mov rax, rcx	;Get first buffer ptr into rsi
	call convStrHex
	jc exitbad		;If a bad char was detected, exit fail
	mov rcx, rax	;Save the first number in rcx

	mov rax, rdx	;Get second buffer ptr into rsi
	call convStrHex
	jc exitbad		;If a bad char was detected, exit fail

	add rax, rcx	;Add the first number to the second, save in rax
	call convHexStr	;Store the result of the sum in r8
	xor eax, eax	;Return success
	jmp short exitcommon
add64A	ENDP

sub64A	PROC	PUBLIC
;ALWAYS subtracts the bigger number from the smaller
	push rbp		;Save bp on caller stack
	mov rbp, rsp	;Move the current stack pointer to BP
	mov rsp, OFFSET stk	;Repoint to our internal stack

	mov rax, rcx	;Move pointer into rsi
	call convStrHex
	jc exitbad
	mov rcx, rax	;Save number in rcx
	
	mov rax, rdx
	call convStrHex
	jc exitbad

	cmp rcx, rax	;If carry set, subtract them the other way
	jc sub0		
	sub rcx, rax	;Subtract the two
	mov rax, rcx	;Move the result into rax
	jmp short sub1
sub0:
	sub rax, rcx
sub1:
	call convHexStr	;rax has difference in hex, r8 has ptr to buffer
	xor eax, eax	;Return success
	jmp short exitcommon
sub64A	ENDP

exitCommon:
	mov rsp, rbp
	pop rbp
	ret
exitbad:
	mov rax, 1
	jmp short exitCommon

;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;   Functions below here are NOT to be exposed as they do NOT abide by the	  
;						Win 64 bit calling convention						  
;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
convStrHex	PROC
;------------------------------------------------------------------------------
; Converts a base 64 character string (of length 8) into a 48 bit hex number. 
; Input:  rax = Ptr to character string                                       
; Output: rax = 48 bit hex number                                             
; If CF=CY, invalid string character detected                                 
;------------------------------------------------------------------------------
	push rbx
	push rcx
	push rdx
	push rsi
	push rdi
	push rbp
	pushfq			

	lea rsi, qword ptr [rax + 7]	;Move pointer to the end of the string in rsi
	mov rdx, 8		;Use rdx as loop counter
	xor ebx, ebx	;Use rbx as the number store
	xor ecx, ecx	;Use rcx as a shift factor
	mov rbp, OFFSET digits	;Use rbp as table base
csh0:
	std				;Read number string backwards
	lodsb			;Get one base 64 symbol into al
	cld				;Read digit string forwards
	mov rdi, rbp	;Return rdi to the head of the list of digits
	push rcx
	mov rcx, numBase
	repne scasb		;Scan string byte whilst ecx is not zero and byte [rdi] != al
	pop rcx
	jne cshbad		;If char not found, return error
	dec rdi			;rdi gets incremented past the necessary byte
	sub rdi, rbp	;Get the offset into the data table into rdi
	shl rdi, cl		;Shift the offset by cl
	add rbx, rdi	;Add the shifted offset into the final count
	add rcx, 6		;Add the shift factor to rcx
	dec edx			;Decrement edx
	jnz csh0
	mov rax, rbx	;Return the number in rax
	and qword ptr [rsp], NOT 1	;Clear carry flag
cshexit:
	popfq
	pop rbp
	pop rdi
	pop rsi
	pop rdx
	pop rcx
	pop rbx
	ret
cshbad:
	or qword ptr [rsp], 1	;Set Carry Flag
	jmp short cshexit
convStrHex	ENDP

convHexStr	PROC
;------------------------------------------------------------------------------
; Converts a 48 bit hex number into a 8 character base 64 string              
; Input:  rax = 48 bit number                                                 
;		  r8  = Ptr to return buffer                                          
;		  r9  = Length of buffer                                              
; Output: r8 = Ptr to 8 char buffer with number stored in                     
;                                                                             
;This will work by taking 6 bits at a time and using that 6 bit value         
;	as an offset into the digits table                                        
;------------------------------------------------------------------------------
	pushfq
	push rax
	push rbx
	push rcx
	push rdx
	push rdi

	mov rdi, r8		;Get the buffer into rdi
	mov rdx, 0FFFFh
	ror rdx, 16		;Move this word to upper 16 bits of rdx
	not rdx			;Bitwise negate rdx
	and rax, rdx	;FORCE the upper bits of rax to be zero
;The above is since we cannot have constants bigger than 32 bits
	mov rbx, OFFSET digits	;Point to digits table with rbx
	mov rdx, rax	;Move a copy of our number into rdx
	movzx rax, byte ptr [digits]	;Get the zero symbol into al
	mov rcx, r9
	cld				;Write forwards
	rep stosb		;Repeatedly store '0' symbols into the char buffer 
	dec rdi
	std				;Now do reverse string writes
chs0:
	mov al, dl		;Get the lower byte into al
	shr rdx, 6		;Shift down by 6 bits
	and al, 03Fh	;Isolate bits [5:0]
	xlatb			;Get the symbol in al
	stosb			;Write the symbol and decrement rdi
	test rdx, rdx	;rdx is zero => no more digits left to write, exit
	jnz chs0

	pop rdi
	pop rdx
	pop rcx
	pop rbx
	pop rax
	popfq
	ret
convHexStr	ENDP

MAIN	ENDS
	END