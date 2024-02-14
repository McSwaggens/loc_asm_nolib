section .text

global _start
_start:

	; rsp+0: DIRECTORY FILE HANDLE

	sub rsp, 8192

	; Open current directory
	mov rax, 2 ; OPEN
	mov rdi, STR_DOT
	mov rsi, 0x10000 ; DIRECTORY
	syscall

	test rax, rax
	js error_opening_file

	sub rsp, 64
	mov QWORD [rsp+0], rax

.outer_loop:
	mov rax, 217 ; getdent64
	mov rdi, [rsp+0] ; Directory file handle
	lea rsi, [rsp+64] ; Beginning of buffer
	mov rdx, 8192 ; Buffer size
	syscall

	test rax, rax
	js error_getdent64
	jz .exit_outer_loop

	mov rbx, rax ; Read bytes
	lea rcx, [rsp+64] ; Head
	lea r15, [rsp+64+rbx] ; End of read bytes in buffer

.inner_loop:
	mov r14, rcx
	xor rax, rax
	mov ax, WORD [rcx+16]
	add rcx, rax ; rcx = next dirent, DO NOT USE THIS LOOP!

	lea rax, [r14+19]
	call strlen
	mov r11, rax

	push rcx
	mov rax, 1 ; WRITE
	mov rdi, 1 ; STDOUT
	lea rsi, [r14+19]
	mov rdx, r11
	syscall
	pop rcx

	call newline

	cmp rcx, r15
	jl .inner_loop

	jmp .outer_loop

.exit_outer_loop:

	jmp exit_success


strlen:
	push rbx
	push rcx
	xor rbx, rbx
	dec rbx
.loop:
	inc rbx
	mov cl, BYTE [rax+rbx]
	test cl, cl
	jnz .loop

.loop_exit:
	mov rax, rbx
	pop rcx
	pop rbx
	ret


error_opening_file:
	mov rax, 1 ; WRITE
	mov rdi, 2 ; STDERR
	mov rsi, STR_ERR_OPEN_DIR
	mov rdx, STR_ERR_OPEN_DIR_LEN
	syscall
	jmp exit_fail

error_getdent64:
	mov rax, 1 ; WRITE
	mov rdi, 2 ; STDERR
	mov rsi, STR_ERR_GETDENT64
	mov rdx, STR_ERR_GETDENT64_LEN
	syscall
	jmp exit_fail

print_test:
	push rax
	push rdi
	push rsi
	push rdx

	push rcx
	push r11

	mov rax, 1 ; WRITE
	mov rdi, 1 ; STDOUT
	mov rsi, STR_TEST
	mov rdx, STR_TEST_LEN
	syscall

	pop r11
	pop rcx

	pop rdx
	pop rsi
	pop rdi
	pop rax
	ret

newline:
	push rax
	push rdi
	push rsi
	push rdx
	push rcx
	push r11
	mov rax, 1 ; WRITE
	mov rdi, 1 ; STDOUT
	mov rsi, STR_NEWLINE
	mov rdx, 1
	syscall
	pop r11
	pop rcx
	pop rdx
	pop rsi
	pop rdi
	pop rax
	ret

exit_fail:
	mov rax, 60
	mov rdi, 1
	syscall

exit_success:
	mov rax, 1 ; WRITE
	mov rdi, 1 ; STDERR
	mov rsi, STR_PROG_COMPLETE
	mov rdx, STR_PROG_COMPLETE_LEN
	syscall

	mov rax, 60
	mov rdi, 0
	syscall

section .bss

section .data

STR_DOT: db ".", 0
STR_NEWLINE: db 10

STR_TEST: db "TEST", 10, 0
STR_TEST_LEN: equ $-STR_TEST

STR_PROG_COMPLETE: db "PROGRAM COMPLETE", 10
STR_PROG_COMPLETE_LEN: equ $-STR_PROG_COMPLETE

STR_ERR_OPEN_DIR: db "ERROR: COULD NOT OPEN CURRENT DIRECTORY!", 10
STR_ERR_OPEN_DIR_LEN: equ $-STR_ERR_OPEN_DIR

STR_ERR_GETDENT64: db "ERROR: GETDENT64 FAILED!", 10
STR_ERR_GETDENT64_LEN: equ $-STR_ERR_GETDENT64
