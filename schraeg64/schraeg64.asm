;;; system calls
%define SYS_WRITE	1
%define SYS_EXIT	60
;;; file ids
%define STDOUT		1

;;; start of data section
section .data
msg		db	'Hello World!'
;;; a newline character
newline:
 	db 0x0a

;;; start of code section
section	.text
	;; this symbol has to be defined as entry point of the program
	global _start


;;; main function
_start:
	pop rbx		; pop argument count into rbx (>= 1 guaranteed)
read_args:
	;; read next argument
	pop rsi   ; pop address to next argument into rsi
	call write_string

exit:
	;; exit program via syscall exit (necessary!)
	mov	rax, SYS_EXIT	; set syscall to SYS_EXIT
	mov	rdi, 0		; exit code 0 (= "ok")
	syscall
write_newline:
	push rax
	mov rax, SYS_WRITE

	push rdi
	mov	rdi, STDOUT		; write to STDOUT

	push rdx ; write call length
	mov rdx, 1 ; set length to 0
	push rsi ; argument string address pointer
	mov rsi, newline
	syscall ; call SYS_WRITE to STDOUT with calculated length (in rdx)
	pop rsi ; restore starting address of string
	pop rdx
	pop rdi
	pop rax

;;; write string function
write_string:
	; remember values in registers we use
	; prepare write call
	push rax
	mov	rax, SYS_WRITE	; set syscall to SYS_WRITE

	push rdi
	mov	rdi, STDOUT		; write to STDOUT

	push rdx ; write call length
	mov rdx, 0 ; set length to 0

	push rsi ; argument string address pointer
search_eos:
	cmp [rsi], byte 0 ; zero byte (eos) reached?
	je found_eos ; yes, findish
	; else
	inc rdx ; count length
	inc rsi ; next byte
	jmp search_eos ; loop
found_eos:
	; pop remembered values back into registers
	; opposite order because of stack
	pop rsi ; restore starting address of string
	syscall ; call SYS_WRITE to STDOUT with calculated length (in rdx)
	pop rdx
	pop rdi
	pop rax
	ret
