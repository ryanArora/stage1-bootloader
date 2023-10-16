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

    # Hello, world!
    mov $hello_world, %si
    call print_str

    call check_mbrp1_is_bootable
    call check_mbrp1_is_fat32
    call load_bpb
    call check_bpb_rootclus_16bit
    call load_sectors_per_track

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

# void print_str(char* %ds:(%si));
print_str:
    push %ax
    push %si

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

check_mbrp1_is_bootable:
    push %ax
    push %ds

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
    pop %ds
    pop %ax
    ret

check_mbrp1_is_fat32:
    push %ax
    push %ds

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
    pop %ds
    pop %ax
    ret

load_bpb:
    pushf
    push %ax
    push %bx
    push %cx
    push %dx
    push %ds
    push %es

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
    pop %es
    pop %ds
    pop %dx
    pop %cx
    pop %bx
    pop %ax
    popf
    ret

check_bpb_rootclus_16bit:
    push %ax
    push %bx
    push %ds
    
    xor %ax, %ax
    mov %ax, %ds

    # BPB_RootClus_HIGH
    mov %ds:(partition_table + 16*4+2 + 46), %ax

    mov $0, %bx
    cmp %ax, %bx
    jz check_bpb_rootclus_16bit_done

    movb $'F', %al
    call print_char
    movb $'R', %al
    call print_char
    jmp die

    check_bpb_rootclus_16bit_done:
    pop %ds
    pop %bx
    pop %ax
    ret

load_sectors_per_track:
    pushf
    push %ax
    push %cx
    push %dx
    push %es
    push %di

    xor %ax, %ax
    mov %ax, %es
    mov %ax, %di

    mov $0x08, %ah
    mov $0x80, %dl
    int $0x13
    
    and $0x3F, %cx
    inc %cx
    mov %cx, %es:(sectors_per_track)

    pop %di
    pop %es
    pop %dx
    pop %cx
    pop %ax
    popf
    ret

die:
    hlt
    jmp die

bss:
hello_world:
    .string "Hello, world!\r\n"
stage2_filename:
    .string "STAGE2  BIN"
sectors_per_track:
    .word 0

.fill 446 - (. - _start), 1, 0
partition_table:
