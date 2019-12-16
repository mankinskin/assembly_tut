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
space		db	' '

;;; start of code section
section	.text
	;; this symbol has to be defined as entry point of the program
	global _start


;;; main function
_start:
	pop rbx		; pop argument count into rbx (>= 1 guaranteed)
	pop rsi   ; drop first argument (command name)

	mov	rax, SYS_WRITE	; set syscall to SYS_WRITE
	mov	rdi, STDOUT			; write to STDOUT
	mov rdx, 1					; set length to 1

read_args:
	;; read next argument
	dec rbx   
	jz exit   ; when argument count 0 
	pop rsi   ; pop address to next argument into rsi
	call write_arg
	jmp read_args

exit:
	;; exit program via syscall exit (necessary!)
	mov	rax, SYS_EXIT	; set syscall to SYS_EXIT
	mov	rdi, 0				; set exit code 0
	syscall

write_char:
	push rcx
	; syscall is configured at _start
	syscall
	pop rcx
	ret

write_newline:
	push rsi ; argument string address pointer
	mov rsi, newline
	call write_char
	pop rsi ; restore starting address of string
	ret

;;; write string schraeg function
;; writes string in rsi slanted to stdout
write_arg:
	push rsi ; remember string address
	mov rcx, 0	; set char count to 0
	; rsi points to current char
walk_string:				; loop
	cmp [rsi], byte 0 ; zero byte (eos) reached?
	je reached_end		; yes, finish >>>

write_spaces:				
	push rcx					; char count -> white spaces remaining
  push rsi					; remember current char
	mov rsi, space		; current char -> space

loop_spaces:        ; loop
	cmp rcx, byte 0		; 0 reached?
	je finish_spaces	; yes, finish >>>
write_space:
	call write_char		; write 1 space to stdout
	dec rcx						; decrement whitespace counter
	jmp loop_spaces		; loop ^^^

finish_spaces:
	pop rsi ; space -> current char
	pop rcx ; 0 -> char count

finish_char:
	call write_char ; write 1 char to stdout
	call write_newline
	inc rsi ; next char
	inc rcx ; increment char count
	jmp walk_string ; loop ^^^

reached_end:
	pop rsi ; eos -> string
	ret
