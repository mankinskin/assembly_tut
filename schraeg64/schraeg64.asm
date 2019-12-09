;;; system calls
%define SYS_WRITE	1
%define SYS_EXIT	60
;;; file ids
%define STDOUT		1

;;; start of data section
section .data
newline		db	0x0a
space		db	0x20
;;; a newline character
;newline:
; 	db 0x0a

;;; start of code section
section	.text
	;; this symbol has to be defined as entry point of the program
	global _start


;;; main function
_start:
	pop rbx		; pop argument count into rbx (>= 1 guaranteed)
	dec rbx
	pop rsi   ; drop first argument (command name)

	push rax
	mov	rax, SYS_WRITE	; set syscall to SYS_WRITE
	push rdi
	mov	rdi, STDOUT		; write to STDOUT

	push rdx ; write call length
	mov rdx, 1 ; set length to 1
read_args:
	;; read next argument
	pop rsi   ; pop address to next argument into rsi
	call write_arg
	dec rbx
	jnz read_args

	pop rdx
	pop rdi
	pop rax

exit:
	;; exit program via syscall exit (necessary!)
	push rax
	mov	rax, SYS_EXIT	; set syscall to SYS_EXIT
	push rdi
	mov	rdi, 0				; set exit code 0
	syscall
	pop rdi
	pop rax

write_newline:
	push rsi ; argument string address pointer
	mov rsi, newline
	syscall
	pop rsi ; restore starting address of string
	ret

;;; write string schraeg function
;; writes string slanted in rsi to stdout
write_arg:
	push rcx		; char count
	mov rcx, 0	; set char count to 0

	push rsi ; remember string address
	; rsi points to current char

walk_string:				; loop
	cmp rsi, byte 0 ; zero byte (eos) reached?
	je reached_end		; yes, finish >>>

;;; first, write spaces
;	push rsi				; remember current char
;	mov rsi, space	; current char -> space
;	push rcx				; char count -> white spaces remaining
;write_spaces:				; loop
;	cmp [rcx], byte 0 ; zero byte (eos) reached?
;	je finish_spaces	; yes, finish >>>
;	syscall						; write 1 space to stdout
;	dec rcx						; dec whitespace counter
;	jmp write_spaces	; loop ^^^
;finish_spaces:
;	pop rcx ; 0 -> char count
;	pop rsi ; space -> current char
write_char:
	syscall ; write 1 char to stdout
	inc rcx ; increment char count
	inc rsi ; next char
finish_char:
	call write_newline
	jmp walk_string ; loop ^^^

reached_end:
	; pop remembered values back into registers
	; opposite order because of stack
	pop rsi ; eos -> string
	pop rcx ; char count -> _
	ret
