bits 64
;;; system calls
%define SYS_WRITE	1
%define SYS_OPEN	2
%define SYS_CLOSE	3
%define SYS_EXIT	60
%define O_RDONLY	0
%define SYS_READ	0x0
;;; file ids
%define STDIN			0
%define STDOUT		1

;;; start of data section
section .data
;;; a newline character
newline		db	0x0a

section .bss
	file_buffer resb 2040
	file_buffer_size equ $-file_buffer
	match_found resb 1

;;; start of code section
section	.text
	;; this symbol has to be defined as entry point of the program
	global _start


;;; main function
_start:
	pop rbx		; pop argument count into rbx (>= 1 guaranteed)
	pop rdi   ; drop first argument (command name)

read_args:
	dec rbx   
	jz exit   ; when argument count 0 
	call get_stdin
	; file buffer contains stdin
	; rcx contains stdin length

	;; read next argument
	pop rdi   ; pop address to next argument into rdi
	; rdi = word
	;; print argument (debug)
	;mov rsi, rdi
	; rsi = text buffer
	;mov rdx, rcx
	; rdx = write length
	;call write
	mov rsi, file_buffer
	call search_lines
	jmp read_args

search_lines:
	push rcx ; rcx,
	push rdx ; rcx, rdx
	push rsi ; rcx, rdx, rsi
	; rsi = string
	call count_string_length
	; rcx = length
	mov rdx, rcx
	; rdx : total length
next_line:
	mov rcx, 0
	; rcx : length read
	cmp [rsi], byte 0
	je end_lines

	; rsi = string
	call count_line_length
	; rcx = line length
	
	; rcx = max length
	; rsi = text
	call search_string
	; match_found : 1 or 0
	cmp [match_found], byte 1
	je print_line
	jmp end_line
print_line:
	push rdx
	mov rdx, rcx
	call write
	pop rdx
	call write_newline
end_line:
	add rsi, rcx
	inc rsi
	jmp next_line

end_lines:
	pop rsi		; rcx, rdx,
	pop rdx		; rcx,
	pop rcx		;
	ret

search_string:
	; rdi = word (searched for)
	; rsi = text (searched in)
	; rcx = max search length
	push rdx ; rdx,
	push rax ; rdx, rax
	push r8 ; rdx, rax, r8
	mov rdx, 0
	; rdx : index in word
	mov r8, 0
	; r8 : index in text
	; rax : buffer for calculations
	mov [match_found], byte 0
next_char:
	mov rax, r8
	add rax, rdx ; rax = r8 + rdx
	cmp rax, rcx ; max length?
	je end_search
	mov rax, rdi
	add rax, rdx ; rax = rdi + rdx
	cmp [rax], byte 0 ; end of word?
	je end_search
match_chars:
	mov rax, [rax]	; char in word
	push rsi
	add rsi, r8		; rsi = pointer to current index
	cmp [rsi + rdx], al
	pop rsi
	je char_match
	jmp char_miss
char_match:
	inc rdx
	mov [match_found], byte 1
	jmp next_char
char_miss:
	mov rdx, 0	; match from beginning again
	inc r8			; inc chars checked
	mov [match_found], byte 0
	jmp next_char
end_search:	
	pop r8	; rdx, rax
	pop rax ; rdx,
	pop rdx ;
	ret


get_stdin:
	; file_buffer : data from stdin
	; rcx : length of data
	push rsi	; rsi,
	push rdx	; rsi, rdx
	mov rsi, file_buffer
	; rsi = text buffer
	mov rdx, file_buffer_size
	; rdx = read length
	call read_stdin
	; rsi = stdin buffer

	; rsi = text buffer
	call count_string_length
	; rcx = string length

	;; print buffer (debug)
	; rsi = text buffer
	mov rdx, rcx
	; rdx = write length
	;call write

	pop rdx		; rsi,
	pop rsi		;
	ret


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
	; rsi = text
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

count_line_length:
	push rax ; rax
	mov al, [newline]
	; al = end byte
	; rsi = data
	call count_length
	; rcx = length
	pop rax ;
	ret

count_string_length:
	push rax ; rax
	mov al, byte 0
	; al = end byte
	; rsi = data
	call count_length
	; rcx = length
	pop rax ;
	ret

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

read_stdin: 
	push rdi			; rdi
	; rsi = buffer handle
	mov rdi, STDIN
	call read_file
	pop rdi				;
	ret

read_file: 
	push rax			; rax,
	; rdi = file descriptor
	; rsi = buffer handle
	; rdx = read size
	mov rax, SYS_READ
	syscall
	pop rax				;
	ret

open_file: 
	push rdi			; rdi
	push rsi			; rdi, rsi
	mov rax, SYS_OPEN
	mov rsi, O_RDONLY
	; rax = sys_function
	; rdi = file name
	; rsi = flags
	syscall
	; rax = file handle
	pop rsi				; rdi,
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
