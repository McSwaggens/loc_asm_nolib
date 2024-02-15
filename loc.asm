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
	js error_open_dir

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

	lea r14, [rsp+64] ; Head
	lea r15, [r14+rax] ; End of read bytes in buffer

.inner_loop:

	xor rax, rax
	mov al, BYTE [r14+18]
	cmp rax, 8
	jnz .inner_loop_end

	; lea rax, [r14+19]
	; call strlen
	; mov r11, rax ; r11 = file name length

	; TODO: Check file extension

	; Open file
	mov rax, 2 ; OPEN
	lea rdi, [r14+19]
	xor rsi, rsi
	syscall ; rcx = ?, r11 = ?
	mov r13, rax ; r13 = file handle

	test rax, rax
	js error_open_file

	; Get file size
	sub rsp, 144
	mov rax, 5 ; FSTATUS
	mov rdi, r13
	mov rsi, rsp
	syscall ; rcx = ?, r11 = ?
	mov rax, QWORD [rsp+48]
	add rsp, 144
	mov r12, rax ; r12 = file size

	; Map file into virtual address space
	mov rax, 9 ; MMAP
	xor rdi, rdi
	lea rsi, [r12+4095] ; Align up to page boundry
	and rsi, -4096      ;
	mov rdx, 1
	mov r10, 2
	mov r8, r13
	syscall ; rcx = ?, r11 = ?

	cmp rax, -1
	jz error_map_file

	; Count lines of code
	xor rcx, rcx
	lea r12, [r12+rax]
	cmp rax, r12
	jge .count_loc_loop_exit

.count_loc_loop:
	mov bl, BYTE [rax]
	cmp bl, 10
	jnz .skip
	inc rcx
.skip:
	inc rax
	cmp rax, r12
	jl .count_loc_loop
.count_loc_loop_exit:

	; sub rsp, 21
	; mov [rsp+20], 10
	; ; div

	; add rsp, 21

	; call newline

.inner_loop_end:
	xor rax, rax
	mov ax, WORD [r14+16]
	add r14, rax ; rcx = next dirent, DO NOT USE THIS LOOP!
	cmp r14, r15
	jl .inner_loop

	jmp .outer_loop

.exit_outer_loop:

	jmp exit_success


query_file_size:
	ret

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


error_map_file:
	mov rax, 1 ; WRITE
	mov rdi, 2 ; STDERR
	mov rsi, STR_ERR_MAP_FILE
	mov rdx, STR_ERR_MAP_FILE_LEN
	syscall
	jmp exit_fail

error_open_dir:
	mov rax, 1 ; WRITE
	mov rdi, 2 ; STDERR
	mov rsi, STR_ERR_OPEN_DIR
	mov rdx, STR_ERR_OPEN_DIR_LEN
	syscall
	jmp exit_fail

error_open_file:
	mov rax, 1 ; WRITE
	mov rdi, 2 ; STDERR
	mov rsi, STR_ERR_OPEN_FILE
	mov rdx, STR_ERR_OPEN_FILE_LEN
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

STR_ERR_MAP_FILE: db "ERROR: COULD NOT MAP FILE INTO VIRTUAL ADDRESS SPACE!", 10
STR_ERR_MAP_FILE_LEN: equ $-STR_ERR_MAP_FILE

STR_ERR_OPEN_DIR: db "ERROR: COULD NOT OPEN CURRENT DIRECTORY!", 10
STR_ERR_OPEN_DIR_LEN: equ $-STR_ERR_OPEN_DIR

STR_ERR_OPEN_FILE: db "ERROR: COULD NOT OPEN FILE!", 10
STR_ERR_OPEN_FILE_LEN: equ $-STR_ERR_OPEN_FILE

STR_ERR_GETDENT64: db "ERROR: GETDENT64 FAILED!", 10
STR_ERR_GETDENT64_LEN: equ $-STR_ERR_GETDENT64
