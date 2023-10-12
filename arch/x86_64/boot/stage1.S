.code16
.globl _start

_start:
    # setup the stack
    mov %ax, %ss
    mov $_start, %sp

    call say_hi
    call check_mbrp1_is_bootable
    call check_mbrp1_is_fat32
    call load_bpb

    xor %ax, %ax
    mov %ax, %ds
    mov %ds:(bpb + 13), %ax

    jmp die

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

# void print_str(char* %ds:(%si))
print_str:
    movb $1, %al
    # call print_char

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
    ret

# void print_int(int ax)
print_int:
    push %ax

    mov %ax, %bx
    shr $15, %bx

    mov $0, %cx
    cmp %bx, %cx
    jz pos

    mov %ax, %bx
    movb $'-', %al
    call print_char
    mov %bx, %ax
    not %ax
    inc %ax
    call print_uint
    jmp end

    pos:
        call print_uint
    end:
    
    pop %ax
    ret

# void print_uint(uint ax)
print_uint:
    mov $0, %cx

    print_int_loop:
    # ax = ax / 10
    # bx = ax % 10
    mov $10, %bx
    mov $0, %dx
    div %bx

    // push
    push %dx
    inc %cx

    # stop if ax=0
    mov $0, %bx
    cmp %ax, %bx
    jz print_int_loop_end

    jmp print_int_loop

    print_int_loop_end:


    mov $0, %dx
    loop1:
    cmp %cx, %dx
    jz loop1_end

    pop %ax
    add $'0', %ax
    call print_char
    inc %dx
    
    jmp loop1
    loop1_end:

    ret

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

check_mbrp1_is_bootable:
    xor %ax, %ax
    mov %ax, %ds
    movb %ds:(partition_table), %al

    movb $0x80, %ah
    cmp %al, %ah
    jz is_bootable

    movb $'B', %al
    call print_char
    jmp die

    is_bootable:
    ret

check_mbrp1_is_fat32:
    xor %ax, %ax
    mov %ax, %ds
    movb %ds:(partition_table + 4), %al

    movb $0x0B, %ah
    cmp %al, %ah
    jz is_fat32

    movb $'F', %al
    call print_char
    jmp die

    is_fat32:
    ret

load_bpb:
    xor %ax, %ax
    mov %ax, %ds

    movb $0x02, %ah
    movb $1, %al                        # 1 sector
    movb %ds:(partition_table + 1), %dh # head
    movb %ds:(partition_table + 2), %cl # sector and cylinder
    movb %ds:(partition_table + 3), %ch # cylinder
    movb $0x80, %dl                     # hard drive 0
    mov $partition_table + 16*4+2, %bx  # 0x7E00

    int $0x13

    jnc loaded

    movb $'D', %al
    call print_char
    jmp die

    loaded:
    ret

die:
    hlt
    jmp die

.fill 446 - (. - _start), 1, 0
partition_table:
bpb:
