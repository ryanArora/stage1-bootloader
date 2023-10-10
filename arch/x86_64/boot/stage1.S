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

    mov $'H', %al
    call print_char
    mov $'i', %al
    call print_char
    
die:
    hlt
    jmp die

// char to be in al
print_char:
	mov $0x0E, %ah
	mov $0, %bh
    int $0x10
    ret

.fill 510 - (. - _start), 1, 0
.word 0xAA55
