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

    # print Hello, world!
    mov $0x0E, %ah

    mov $'H', %al
    int $0x10
    mov $'e', %al
    int $0x10
    mov $'l', %al
    int $0x10
    mov $'l', %al
    int $0x10
    mov $'o', %al
    int $0x10
    mov $',', %al
    int $0x10
    mov $' ', %al
    int $0x10
    mov $'W', %al
    int $0x10
    mov $'o', %al
    int $0x10
    mov $'r', %al
    int $0x10
    mov $'l', %al
    int $0x10
    mov $'d', %al
    int $0x10
    mov $'!', %al
    int $0x10

    hlt

.halt:
    jmp .halt

.fill 510 - (. - _start), 1, 0
.word 0xAA55
