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

    call say_hi
    call check_bootable
    call check_fat32_chs
    
    mov $1, %ax
    call read_sectors_from_drive
    
die:
    hlt
    jmp die

# void print_char(char %al);
print_char:
	mov $0x0E, %ah
	mov $0, %bh
    int $0x10
    ret

# void say_hi(void);
say_hi:
    mov $'H', %al
    call print_char
    mov $'i', %al
    call print_char
    mov $'\r', %al
    call print_char
    mov $'\n', %al
    call print_char
    ret

# void check_bootable(void);
check_bootable:
    xor %ax, %ax
    mov %ax, %ds
    movb %ds:(partition_table), %al

    movb $0x80, %ah
    cmp %al, %ah
    jz bootable

    movb $'B', %al
    call print_char
    jmp die

    bootable:
    ret

# void check_fat32_chs(void);
check_fat32_chs:
    xor %ax, %ax
    mov %ax, %ds
    movb %ds:(partition_table + 4), %al

    movb $0x0B, %ah
    cmp %al, %ah
    jz fat32_lba

    movb $'F', %al
    call print_char
    jmp die

    fat32_lba:
    ret

# al    = sectors to read count
# es:bx = buffer address pointer
read_sectors_from_drive:
    # ch    = cylinder
    # cl    = sector
    # dh    = head
    # dl    = drive
    mov $0, %ch # cylinder
    mov $2, %cl # sector 
    mov $0, %dh # drive
    mov $0x80, %dl

    xor %ax, %ax
    mov %ax, %es
    mov $partition_table + 16*4 + 2, %bx


    int $0x13

    ret

.fill 446 - (. - _start), 1, 0
partition_table:
