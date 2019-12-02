; ===========================================================================
; 
; print_args64.asm --
; prints command line arguments to stdout
; (simplified version of use_args.asm for script)
;
; Ralf Moeller
; 
;    Copyright (C) 2007
;    Computer Engineering Group
;    Faculty of Technology
;    University of Bielefeld
;    www.ti.uni-bielefeld.de
; 
; 1.0 / 22. Mar 07 (rm)
; - from use_args.asm
; 1.1 / 11. Jun 08 (rm)
; - output of 0x00 char not required
; - label finish removed
; 1.2 / 24. Sep 13 (rm)
; - from print_args.asm, now for 64 bit
; 1.3 /  6. Oct 14 (rm)
; - corrected bug, see date-tag
; 
; ===========================================================================

;;; system calls
%define SYS_WRITE	1
%define SYS_EXIT	60
;;; file ids
%define STDOUT		1
	
;;; start of data section
section .data
;;; a newline character
newline:
 	db 0x0a

;;; start of code section
section	.text
	;; this symbol has to be defined as entry point of the program
	global _start

;;;--------------------------------------------------------------------------
;;; subroutine write_newline
;;;--------------------------------------------------------------------------
;;; writes a newline character to stdout
	
write_newline:
	;; save registers that are used in the code
	push	rax
	push	rdi
	push	rsi
	push	rdx
	;; prepare arguments for write syscall
	mov	rax, SYS_WRITE	; write syscall
	mov	rdi, STDOUT	; fd = 1 (stdout)
	mov	rsi, newline	; string
	mov	rdx, 1		; length
	syscall			; system call
	;; restore registers (in opposite order)
	pop	rdx
	pop	rsi
	pop	rdi
	pop	rax
	ret
	
;;;--------------------------------------------------------------------------
;;; subroutine write_string
;;;--------------------------------------------------------------------------
;;; address of 0-terminated string passed in rsi
;;; operation: determines length of string and writes it in ONE write
;;; (plus a second write that appends a new-line character)

write_string:
	;; save registers that are used in the code
	push	rax
	push	rdi
	push	rdx
	;; prepare arguments for write syscall
	mov	rax, SYS_WRITE	; write syscall
	mov	rdi, STDOUT	; fd = 1 (stdout)
	mov	rdx, 0		; count bytes
	push	rsi		; keep starting address of string
search_eos:
	;; here we have to specify the string size (byte) 
	cmp	[rsi], byte 0	; end of string (0) reached?
	je	eos_found	; yes, end of loop
	inc	rdx		; count
	inc	rsi		; next position in string
	jmp	search_eos	; loop
eos_found:
	pop	rsi		; restore starting address of string
	;; here rdx contains the string length
	syscall			; system call
	;; restore registers (in opposite order)
	;;  6. Oct 14 (rm): corrected bug: was pop rsi:
	pop	rdx
	pop	rdi
	pop	rax
	ret
	
;;;--------------------------------------------------------------------------
;;; main entry
;;;--------------------------------------------------------------------------

_start:
	pop	rbx		; argc (>= 1 guaranteed)
read_args:
	;; print command line arguments
	pop	rsi		; argv[j]
	call	write_string	; string in rsi is written to stdout
	call	write_newline	; a newline character is written to stdout
	dec	rbx		; dec arg-index
	jnz	read_args	; continue until last argument was printed

	;; exit program via syscall exit (necessary!)
	mov	rax, SYS_EXIT	; exit syscall
	mov	rdi, 0		; exit code 0 (= "ok")
	syscall 		; kernel interrupt: system call
