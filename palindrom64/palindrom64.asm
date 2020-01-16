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
is_pal				db	" is a palindrome!"
is_not_pal		db	" is not a palindrome!"

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
	call check_palindrome
	jmp read_args

write_char:
	push rdx
	mov rdx, 1
	call write
	pop rdx
	ret

write_newline:
	push rsi
	mov rsi, newline
	call write_char
	pop rsi
	ret

write:
	push rax
	mov	rax, SYS_WRITE	; set syscall to SYS_WRITE
	push rdi
	mov	rdi, STDOUT			; write to STDOUT
	push rcx
	syscall
	pop rcx
	pop rdi
	pop rax
	ret

count_length: ; writes length into rcx
	mov rcx, 0
	push rsi
count_iter:
	cmp [rsi], byte 0		; end of argument reached?
	je end_counting
	inc rcx
	inc rsi
	jmp count_iter
end_counting:
	pop rsi
	ret

echo_arg:
	push rdx						; rcx,rdx,
	mov rdx, rcx
	call write					; write arg
	pop rdx							; rcx,
	ret

check_palindrome:
	; rsi contains current argument
	push rcx						; rcx,
	call count_length   ; rcx = length(arg)
	call echo_arg

divide_length: ; rdx = rax/rbx
	push rdx						; rcx,rdx,
	push rax						; rcx,rdx,rax
	push rbx						; rcx,rdx,rax,rbx
	mov rdx, 0					; quotient
	mov rax, rcx				; dividend
	mov rbx, 2					; divisor

	div rbx							; rax = rax / rbx
	mov rdx, rax        ; rdx = rax

	pop rbx							; rcx,rdx,rax
	pop rax							; rcx,rdx
	; rdx contains result

compare:
	push rsi						; rcx,rdx,rsi
	push rax						; rcx,rdx,rsi,rax
	push rbx						; rcx,rdx,rsi,rax,rbx

	mov rax, rsi				; beginning of word
	mov rbx, rsi				; end of word

	add rbx, rcx        ; rbx points after word
	dec rbx             ; rbx points at last character

	push rdi						; rcx,rdx,rsi,rax,rbx,rdi
compare_next:
	cmp rcx, 0				; finished comparing?
	je print_answer
	mov dl, byte [rbx]			; buffer value at rbx
	cmp dl, byte [rax] 			; characters are equal?
	jne print_answer
	inc rax
	dec rbx
	dec rcx
	jmp compare_next

print_answer:
	pop rdi							; rcx,rdx,rsi,rax,rbx
	pop rbx 						; rcx,rdx,rsi,rax
	pop rax 						; rcx,rdx,rsi
	pop rsi 						; rcx,rdx
	pop rdx 						; rcx,
	push rdx						; rcx, rdx
	cmp rcx, 0					; finished comparing?
	je is_palindrome
	jmp is_not_palindrome
is_palindrome:	
	mov rsi, is_pal
	mov rdx, 17
	jmp end_line
is_not_palindrome:	
	mov rsi, is_not_pal
	mov rdx, 21
end_line:
	call write
	call write_newline
	pop rdx ; rcx
	pop rcx ;
	ret

exit:
	;; exit program via syscall exit (necessary!)
	mov	rax, SYS_EXIT	; set syscall to SYS_EXIT
	mov	rdi, 0				; set exit code 0
	syscall
