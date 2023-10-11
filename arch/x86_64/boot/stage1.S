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
    call check_fat32_lba
    
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
    movb %ds:(partition_boot), %al

    movb $0x80, %ah
    cmp %al, %ah
    jz bootable

    movb $'B', %al
    call print_char
    jmp die

    bootable:
    ret

# void check_fat32_lba(void);
check_fat32_lba:
    xor %ax, %ax
    mov %ax, %ds
    movb %ds:(partition_boot + 4), %al

    movb $0x0C, %ah
    cmp %al, %ah
    jz fat32_lba

    movb $'F', %al
    call print_char
    jmp die

    fat32_lba:
    ret

.fill 446 - (. - _start), 1, 0

partition_table:
partition_boot:
.byte 0x80                   # Active (Bootable)
.byte 0x00, 0x00, 0x00       # CHS of first absolute sector
.byte 0x0C                   # Partition Type (FAT32 LBA) 0x0C
.byte 0x00, 0x00, 0x00       # CHS of first absolute sector
.byte 0x00, 0x00, 0x00, 0x00 # LBA of first absolute sector
.byte 0x00, 0x00, 0x00, 0x00 # Number of sectors
partition_root:
.byte 0x00
.fill 15, 1, 0
partition_three:
.fill 16, 1, 0
partition_four:
.fill 16, 1, 0
magic_word:
.word 0xAA55
