.code16
.globl _start

.equ PARTITION_TABLE, partition_table
.equ MBRP1_STATUS, partition_table + 0x00
.equ MBRP1_PARTITION_TYPE, partition_table + 0x04
.equ MBRP1_FIRST_SECTOR, partition_table + 0x08

.equ FAT32_BPB, partition_table + 16*4+2
.equ BS_OEMName, FAT32_BPB + 3
.equ BPB_SecPerClus, FAT32_BPB + 13
.equ BPB_RsvdSecCnt, FAT32_BPB + 14
.equ BPB_NumFATs, FAT32_BPB + 16
.equ BPB_FATSz32, FAT32_BPB + 36
.equ BPB_RootClus, FAT32_BPB + 44

.equ RootClus, FAT32_BPB + 512

_start:
    # setup data segments
    xor %ax, %ax
    mov %ax, %ds
    mov %ax, %es

    # setup the stack
    mov %ax, %ss
    mov $_start, %sp

    call check_mbrp1_is_bootable
    call check_mbrp1_is_fat32
    call check_mbrp1_start_16bit
    call load_bpb

    call check_bpb_rootclus_16bit
    call check_bpb_fatsz32_16bit
    call load_rootclus

    mov $RootClus, %si
    call print_str

    mov $'S', %al
    call print_char
    jmp exit_success

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

check_mbrp1_is_bootable:
    movb %ds:(MBRP1_STATUS), %al

    movb $0x80, %ah
    cmp %al, %ah
    jz is_bootable

    jmp exit_failure
    
    is_bootable:
    ret

check_mbrp1_is_fat32:
    movb %ds:(MBRP1_PARTITION_TYPE), %al

    movb $0x0C, %ah
    cmp %al, %ah
    jz is_fat32

    jmp exit_failure

    is_fat32:
    ret

check_mbrp1_start_16bit:
    xor %ax, %ax
    cmp %ds:(MBRP1_FIRST_SECTOR + 2), %ax
    jz check_mbrp1_start_16bit_success

    jmp exit_failure

    check_mbrp1_start_16bit_success:
    ret

load_bpb:
    mov %ds:(MBRP1_FIRST_SECTOR), %ax
    mov %ax, %ds:(disk_address_packet_sector)
    call load
    ret

check_bpb_rootclus_16bit:
    xor %ax, %ax
    cmp %ax, %ds:(BPB_RootClus + 2)
    jz check_bpb_rootclus_16bit_done

    jmp exit_failure

    check_bpb_rootclus_16bit_done:
    ret

check_bpb_fatsz32_16bit:
    xor %ax, %ax
    cmp %ax, %ds:(BPB_FATSz32 + 2)
    jz check_bpb_fatsz32_16bit_success

    jmp exit_failure

    check_bpb_fatsz32_16bit_success:
    ret

# %ax get_start_sector(%bx cluster);
get_start_sector:
    # cx = offset + RsvdSecCnt
    mov %ds:(MBRP1_FIRST_SECTOR), %cx
    add %ds:(BPB_RsvdSecCnt), %cx
    jc exit_failure

    # cx += FatSz32 * NumFATs
    mov %ds:(BPB_FATSz32), %ax
    mov %ds:(BPB_NumFATs), %dl
    xor %dh, %dh
    mul %dx
    jc exit_failure
    add %ax, %cx
    jc exit_failure

    # cx += (cluster - 2) * SecPerClus
    mov %bx, %ax
    add $-2, %ax
    movb %ds:(BPB_SecPerClus), %dl
    xor %dh, %dh
    mul %dx
    jc exit_failure
    add %ax, %cx
    jc exit_failure

    mov %cx, %ax
    ret

load_rootclus:
    # start sector
    mov %ds:(BPB_RootClus), %bx
    call get_start_sector
    mov %ax, %ds:(disk_address_packet_sector)

    # set number of sectors
    movb %ds:(BPB_SecPerClus), %al
    xor %ah, %ah
    mov %ax, %ds:(disk_address_packet_number_of_sectors)

    # set memory address
    movw $RootClus, %ds:(disk_address_packet_offset)

    call load
    ret

# void load(void);
load:
    movb $0x42, %ah
    movb $0x80, %dl
    mov $disk_address_packet, %si
    int $0x13

    jnc load_success

    jmp exit_failure

    load_success:
    ret

exit_failure:
    mov $'E', %al
    call print_char
exit_success:
    hlt
    jmp exit_success

bss:
disk_address_packet:
.byte 0x10
.byte 0x00
disk_address_packet_number_of_sectors:
.word 1 # number of sectors
disk_address_packet_offset:
.word partition_table + 16*4+2 # offset
.word 0 # segment
disk_address_packet_sector:
.quad 0 # lba sector

.fill 446 - (. - _start), 1, 0
partition_table:
