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
hex_msg						db	"Hexadecimal number = 0x"
hex_msg_len				equ	$-hex_msg

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
	call parse_decimal
	call check_error
	; rax contains binary number
	mov rsi, text_buffer
	; rsi = string buffer
	call print_decimal

	call print_hexadecimal

	jmp read_args

; ------------------------------
parse_decimal
	push r8
	mov r8, 10
	call parse_radix
	pop r8
	ret

; ------------------------------
print_hexadecimal:
	call write_hexadecimal
	call check_error
	call write_hex_msg
	call reverse_print
	call check_error
	call write_newline
	ret

; ------------------------------
print_decimal:
	call write_decimal_msg
	call write_decimal
	call check_error
	call reverse_print
	call check_error
	call write_newline
	ret

; ------------------------------
parse_radix:
	; rcx : digit count
	; rsi : digit string
	; r8 : base
	push rcx
	push rdx
	push rsi
	push rdi
	push rbx
	; rdi : result
	; rbx : char buffer
	; rax : digit factor accumulator
	; rdi : result
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
	mul r8		; rax = rax * base
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
write_hexadecimal:
	; rcx = output length
	; rax = decimal buffer
	; rsi = text buffer
	; rdx = div remainder
	; rbx = divisor
	push rax
	push rdx
	push rbx
	xor rcx, rcx ; clear for counting
loop_write_hexadecimal:
	cmp rcx, 8
	je end_write_hexadecimal

	mov dl, al
	shr rax, 4 ; rax / 16
	and dl, 15	; set all bits 5-8 to 0
	; rax = result
	; rdx = remainder
	cmp rdx, 9
	jle skip_ascii_skip
	add rdx, 7 ; skip to characters
skip_ascii_skip:
	add rdx, ascii_0 ; to ascii
	mov [rsi + rcx], rdx
	inc rcx

	jmp loop_write_hexadecimal
end_write_hexadecimal:
	cmp rax, 0			; finished?
	jne overflow_error
	jmp finished_write
overflow_error:
	call write_overflow_error
	mov [error_flag], byte 2
finished_write:
	pop rbx
	pop rdx
	pop rax
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
reverse_print:
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
exit:
	;; exit program via syscall exit (necessary!)
	mov	rax, SYS_EXIT
	mov	rdi, 0
	; rax = syscommand
	; rdi = exit code
	syscall
