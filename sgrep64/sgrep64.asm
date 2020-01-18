;;; system calls
%define SYS_WRITE	1
%define SYS_OPEN	2
%define SYS_CLOSE	3
%define SYS_EXIT	60
;;; file ids
%define STDOUT		1

;;; start of data section
section .data
;;; a newline character
newline		db	0x0a
end_of_file		db	-1

;;; start of code section
section	.text
	;; this symbol has to be defined as entry point of the program
	global _start


;;; main function
_start:
	pop rbx		; pop argument count into rbx (>= 1 guaranteed)
	pop rdi   ; drop first argument (command name)

read_args:
	;; read next argument
	dec rbx   
	jz exit   ; when argument count 0 
	pop rdi   ; pop address to next argument into rsi
	call count_string_length
	jmp read_args

write_newline:
	push rsi
	mov rsi, newline
	call write_char
	pop rsi
	ret

write_char:
	push rdx
	mov rdx, 1
	; rdx = write length
	call write
	pop rdx
	ret

write:
	push rax
	push rdi
	push rcx
	mov	rax, SYS_WRITE	; set syscall to SYS_WRITE
	mov	rdi, STDOUT			; write to STDOUT
	; rdx = write length
	; rax = syscommand
	; rdi = file descriptor
	; rcx = ?
	syscall
	pop rcx
	pop rdi
	pop rax
	ret

exit:
	;; exit program via syscall exit (necessary!)
	mov	rax, SYS_EXIT
	mov	rdi, 0
	; rax = syscommand
	; rdi = exit code
	syscall

count_file_length:
	push rax ; rbx, rax
	mov al, end_of_file
	; al = end byte
	call count_length
	; rcx = length
	pop rax ; rbx,
	ret

count_line_length:
	push rax ; rbx, rax
	mov al, newline
	; al = end byte
	call count_length
	; rcx = length
	pop rax ; rbx,
	ret

count_string_length:
	push rax ; rbx, rax
	mov al, byte 0
	; al = end byte
	call count_length
	; rcx = length
	pop rax ; rbx,
	ret

count_length:
	push rax ; rbx
	push rbx ; rbx,
	push rdi ; rbx, rdi
	mov rcx, 0
	; al = end byte
count_iter:
	cmp [rdi], al
	je count_end
	inc rcx
	inc rdi
	jmp count_iter
count_end:	
	; rcx = length
	pop rdi ; rbx
	pop rbx ;
	pop rax ; rbx,
	ret

open_file: 
	push rdi			; rdi
	mov rax, SYS_OPEN
	; rax = sys_function
	; rdi = file name
	syscall
	; rax = file handle
	pop rdi				;
	ret

close_file:
	push rax			; rax,
	mov rax, SYS_CLOSE
	; rax = sys_function
	; rdi = file handle
	syscall
	pop rax				;
	ret
