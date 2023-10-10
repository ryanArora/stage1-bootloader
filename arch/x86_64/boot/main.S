.code16
.globl _start

_start:
    # setup data segments
    mov $0, %ax
    mov %ax, %ds
    mov %ax, %es

    # setup the stack
    mov %ax, %ss
    mov $_start, %sp

	# check a20, die if not set.
    call check_a20
	cmp $0, %ax
	jne check_a20_continue
	mov $'E', %ax
	call print_char
	jmp die
	check_a20_continue:
    
die:
    hlt
    jmp die

// char to be in al
print_char:
	mov $0x0E, %ah
    int $0x10
    ret

// a20 is enabled is in ax
check_a20:
	pushf
	push %ds
	push %es
	push %di
	push %si
	
	cli
	
	xor %ax, %ax
	mov %ax, %es
 
 	not %ax
	mov %ax, %ds
	
	mov $0x0500, %di
	mov $0x0510, %si
 
    movb %es:(%di), %al
    push %ax
	movb %ds:(%si), %al
    push %ax
	
	movb $0x00, %es:(%di)
    movb $0xFF, %ds:(%si)
 
	cmpb $0xFF, %es:(%di)
	pop %ax
	movb %al, %ds:(%si)
 
    pop %ax
	movb %al, %es:(%di)
	
	mov $0, %ax
    je check_a20__exit
    mov $1, %ax
 
check_a20__exit:
    pop %si
    pop %di
    pop %es
    pop %ds
    popf
 
    ret

.fill 510 - (. - _start), 1, 0
.word 0xAA55
