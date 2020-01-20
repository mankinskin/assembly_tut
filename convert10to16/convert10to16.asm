bits 64
;;; system calls
%define SYS_WRITE	1
%define SYS_EXIT	60
;;; file ids
%define STDOUT		1
;;; constants
%define ascii_0		48
%define ascii_9		57

section .data
newline									db	0x0a
invalid_char_msg				db	"Invalid decimal number"
invalid_char_msg_len		equ	$-invalid_char_msg
overflow_msg						db	"Value overflow"
overflow_msg_len				equ	$-overflow_msg
decimal_msg						db	"Decimal number = "
decimal_msg_len				equ	$-decimal_msg
hex_msg						db	"Hexadecimal number = "
hex_msg_len				equ	$-hex_msg
number_buffer		dd			0

section .bss
	text_buffer		resb 32
	error_flag			resb 1


section	.text
	;; this symbol has to be defined as entry point of the program
	global _start

; ------------------------------
check_error:
	cmp [error_flag], byte 0
	jne exit
	ret

; ------------------------------
_start:
	pop rbx		; pop argument count into rbx (>= 1 guaranteed)
	pop rdi   ; drop first argument (command name)
	mov [error_flag], byte 0
	mov [number_buffer], byte 0
read_args:
	dec rbx   ; --argument_count
	jz exit   ; when argument count 0 

	pop rdi
	; rdi = next argument

	mov rsi, rdi
	; rsi = string
	call count_digits
	call check_error
	; rcx = digit count
	; rsi = input string
	call read_decimal
	call check_error
	; number_buffer contains decimal
	mov rsi, text_buffer
	;mov rax, 1002
	call print_decimal

	call print_hexadecimal

	jmp read_args

; ------------------------------
read_decimal:
	; rcx : digit count
	; rsi : digit string
	push rcx
	push rdx
	push rsi
	push rdi
	push rbx
	; r8 : base
	; rdi : result
	; rbx : char buffer
	; rax : digit factor accumulator
	; rdi : result
	mov r8, 10 ; base 10
	mov rax, 1
	mov rdi, 0
	mov rbx, 0
next_digit:
	cmp rcx, 0		; end of string?
	je end_decimal
	dec rcx
	mov bl, byte [rsi + rcx]
	; rdi = char
	sub rbx, ascii_0 ; convert char to decimal value
	push rax
	mul rbx		; rax = rax * rdx
	add rdi, rax
	pop rax
	mul r8		; rax = rax * 10
	jmp next_digit
end_decimal:
	mov rax, rdi
	; rax : result
	pop rbx
	pop rdi
	pop rsi
	pop rdx
	pop rcx
	ret
; ------------------------------
print_hexadecimal:
	call write_hexadecimal
	call check_error
	call write_hex_msg
	call reverse_print_decimal
	call check_error
	call write_newline
	ret

; ------------------------------
write_hexadecimal:
	; rcx = output length
	; rax = decimal buffer
	; rdx = div remainder
	; rsi = text buffer
	; rbx = divisor
	push rax
	push rdx
	push rbx
	xor rcx, rcx ; clear for counting
loop_write_hexadecimal:
	cmp rcx, 8
	je overflow_error
	mov rdx, 0 ; clear for div
	mov rbx, 16
	div rbx ; rdx:rax / 16
	; rax = result
	; rdx = remainder
	cmp rdx, 9
	jle skip_ascii_skip
	add rdx, 7 ; skip to characters
skip_ascii_skip:
	add rdx, ascii_0 ; to ascii
	mov [rsi + rcx], rdx
	inc rcx

	cmp rax, 0			; stop?
	je end_write_hexadecimal

	jmp loop_write_hexadecimal
overflow_error:
	call write_overflow_error
	mov [error_flag], byte 2
end_write_hexadecimal:
	pop rbx
	pop rdx
	pop rax
	ret

; ------------------------------
reverse_print_hexadecimal:
	; rcx = input length
	; rsi = text buffer
	push rcx
	push rsi
	add rsi, rcx
loop_reverse_print_hex:
	cmp rcx, 0
	je end_reverse_print_hex
	dec rcx
	dec rsi
	call write_char
	jmp loop_reverse_print_hex
end_reverse_print_hex:
	pop rsi
	pop rcx
	ret
; ------------------------------
print_decimal:
	call write_decimal_msg
	call write_decimal
	call check_error
	call reverse_print_decimal
	call check_error
	call write_newline
	ret
; ------------------------------
write_decimal:
	; rcx = output length
	; rax = decimal buffer
	; rdx = div remainder
	; rsi = text buffer
	; rbx = divisor
	push rax
	push rdx
	push rbx
	xor rcx, rcx ; clear for counting
loop_write_decimal:
	mov rdx, 0 ; clear for div
	mov rbx, 10
	div rbx ; rdx:rax / 10
	; rax = result
	; rdx = remainder
	add rdx, ascii_0 ; to ascii
	mov [rsi + rcx], rdx
	inc rcx

	cmp rax, 0			; stop?
	je end_write_decimal

	jmp loop_write_decimal
end_write_decimal:
	pop rbx
	pop rdx
	pop rax
	ret

; ------------------------------
reverse_print_decimal:
	; rcx = input length
	; rsi = text buffer
	push rcx
	push rsi
	add rsi, rcx
loop_reverse_print:
	cmp rcx, 0
	je end_reverse_print
	dec rcx
	dec rsi
	call write_char
	jmp loop_reverse_print
end_reverse_print:
	pop rsi
	pop rcx
	ret

; ------------------------------
count_digits:
	; rsi : text
	; rcx : output length
	xor rcx, rcx ; clear rcx
count_next_digit:
	cmp [rsi + rcx], byte 0		; end of string?
	jz end_digits
	cmp [rsi + rcx], byte ascii_0
	jl invalid_char		; less than ascii_0
	cmp [rsi + rcx], byte ascii_9
	jg invalid_char		; greater than ascii_9
	inc rcx
	jmp count_next_digit	
invalid_char:
	call write_invalid_char_error
	mov [error_flag], byte 1
end_digits:
	ret

; ------------------------------
write_decimal_msg:
	push rsi
	push rcx
	mov rsi, decimal_msg
	mov rcx, decimal_msg_len
	call write
	pop rcx
	pop rsi
	ret

; ------------------------------
write_hex_msg:
	push rsi
	push rcx
	mov rsi, hex_msg
	mov rcx, hex_msg_len
	call write
	pop rcx
	pop rsi
	ret

; ------------------------------
write_overflow_error:
	push rsi
	push rcx
	mov rsi, overflow_msg
	mov rcx, overflow_msg_len
	call write
	call write_newline
	pop rcx
	pop rsi
	ret
; ------------------------------
write_invalid_char_error:
	push rsi
	push rcx
	mov rsi, invalid_char_msg
	mov rcx, invalid_char_msg_len
	call write
	call write_newline
	pop rcx
	pop rsi
	ret
; ------------------------------
write_newline:
	; rsi = text
	push rsi
	mov rsi, newline
	call write_char
	pop rsi
	ret
; ------------------------------
write_char:
	; rsi = text
	push rcx
	mov rcx, 1
	; rcx = write length
	call write
	pop rcx
	ret
; ------------------------------
write:
	; rsi = text
	; rcx = write length
	; rax = syscommand
	; rdi = file descriptor
	push rax
	push rdi
	push rcx
	push rdx
	mov	rax, SYS_WRITE	; set syscall to SYS_WRITE
	mov	rdi, STDOUT			; write to STDOUT
	mov rdx, rcx
	; rdx = write length
	syscall
	; rcx = ?
	pop rdx
	pop rcx
	pop rdi
	pop rax
	ret
; ------------------------------
count_line_length:
	push rax ; rax
	mov al, [newline]
	; al = end byte
	; rsi = data
	call count_length
	; rcx = length
	pop rax ;
	ret
; ------------------------------
count_string_length:
	push rax ; rax
	mov al, byte 0
	; al = end byte
	; rsi = data
	call count_length
	; rcx = length
	pop rax ;
	ret
; ------------------------------
count_length:
	push rbx ; rbx,
	push rsi ; rbx, rsi
	mov rcx, 0
	; al = end byte
	; rsi = data
count_iter:
	cmp [rsi], al
	je count_end
	inc rcx
	inc rsi
	jmp count_iter
count_end:	
	; rcx = length
	pop rsi ; rbx,
	pop rbx ; 
	ret
; ------------------------------
exit:
	;; exit program via syscall exit (necessary!)
	mov	rax, SYS_EXIT
	mov	rdi, 0
	; rax = syscommand
	; rdi = exit code
	syscall
