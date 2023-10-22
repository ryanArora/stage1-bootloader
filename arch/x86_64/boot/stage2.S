.code16
.globl _start

_start:
	# setup data segments
	xor %ax, %ax
	mov %ax, %ds
	mov %ax, %es

	# setup the stack
	mov %ax, %ss
	mov $_start, %sp

	# Hello, world!
	mov $hello_world, %si
	call print_str

	jmp exit_success

exit_failure:
	mov $error_msg, %si
	call print_str
exit_success:
	hlt
	jmp exit_success

data:
error_msg:
.string "error in stage2 bootloader\r\n"

# void print_char(char %al);
print_char:
	push %ax
	push %bx

	mov $0x0E, %ah
	mov $0, %bh
	int $0x10

	pop %bx
	pop %ax
	ret

# void print_str(char* %ds:(%si));
print_str:
	push %ax
	push %si

	movb $1, %al
	
	print_str_loop:
	# read
	movb %ds:(%si), %al
	
	# break if zero.
	movb $0, %ah
	cmp %al, %ah
	jz print_str_loop_end

	# print
	call print_char

	# loop end
	add $1, %si
	jmp print_str_loop
	
	print_str_loop_end:
	pop %si
	pop %ax
	ret

# void print_int(int %ax);
print_int:
	push %ax
	push %bx
	push %cx

	mov %ax, %bx
	shr $15, %bx

	mov $0, %cx
	cmp %bx, %cx
	jz print_int_pos

	mov %ax, %bx
	movb $'-', %al
	call print_char
	mov %bx, %ax
	not %ax
	inc %ax
	call print_uint
	jmp print_int_end

	print_int_pos:
	call print_uint
	print_int_end:
	
	pop %cx
	pop %bx
	pop %ax
	ret

# void print_uint(uint %ax);
print_uint:
	push %ax
	push %bx
	push %cx
	push %dx

	xor %cx, %cx

	print_int_loop:
	# ax = ax / 10
	# bx = ax % 10
	mov $10, %bx
	xor %dx, %dx
	div %bx

	// push
	push %dx
	inc %cx

	# stop if ax=0
	xor %bx, %bx
	cmp %ax, %bx
	jz print_int_loop_end

	jmp print_int_loop

	print_int_loop_end:


	xor %dx, %dx
	loop1:
	cmp %cx, %dx
	jz loop1_end

	pop %ax
	add $'0', %ax
	call print_char
	inc %dx
	
	jmp loop1
	loop1_end:

	# print newline
	mov $'\r', %al
	call print_char
	mov $'\n', %al
	call print_char

	pop %dx
	pop %cx
	pop %bx
	pop %ax
	ret

.fill 16384, 1, 0x00
hello_world:
.string "Welcome to stage2\r\n"
