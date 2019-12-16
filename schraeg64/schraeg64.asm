;;; system calls
%define SYS_WRITE	1
%define SYS_EXIT	60
;;; file ids
%define STDOUT		1

;;; start of data section
section .data
;;; a newline character
newline		db	0x0a
;;; a space character
space		db	0x20

;;; start of code section
section	.text
	;; this symbol has to be defined as entry point of the program
	global _start


;;; main function
_start:
	pop rbx		; pop argument count into rbx (>= 1 guaranteed)
	pop rsi   ; drop first argument (command name)

read_args:
	;; read next argument
	dec rbx   
	jz exit   ; when argument count 0 
	pop rsi   ; pop address to next argument into rsi
	call write_arg
	jmp read_args

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
	call write_char
	pop rsi ; restore starting address of string
	ret
write_char:
	push rax
	mov	rax, SYS_WRITE	; set syscall to SYS_WRITE
	push rdi
	mov	rdi, STDOUT			; write to STDOUT
	push rdx
	mov rdx, 1					; set length to 1
	syscall
	pop rdx
	pop rdi
	pop rax
	ret

;;; write string schraeg function
;; writes string slanted in rsi to stdout
write_arg:
	push rcx
	mov rcx, 0	; set char count to 0

	push rsi ; remember string address
	; rsi points to current char
walk_string:				; loop
	cmp [rsi], byte 0 ; zero byte (eos) reached?
	je reached_end		; yes, finish >>>

write_spaces:				; loop
  push rsi					; remember current char
	mov rsi, space		; current char -> space
	push rcx					; char count -> white spaces remaining
write_space:
	cmp rcx, byte 0		; 0 reached?
	je finish_spaces	; yes, finish >>>
	dec rcx						; dec whitespace counter
	call write_char						; write 1 space to stdout
	jmp write_space		; loop ^^^
finish_spaces:
	pop rcx ; 0 -> char count
	pop rsi ; space -> current char

finish_char:
	push rcx
	call write_char ; write 1 char to stdout
	call write_newline
	pop rcx
	inc rcx ; increment char count
	inc rsi ; next char
	jmp walk_string ; loop ^^^

reached_end:
	pop rsi ; eos -> string
	pop rcx ; char count -> _
	; pop remembered values back into registers
	; opposite order because of stack
	ret
