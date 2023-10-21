.code16
.globl _start

.equ PARTITION_TABLE, _start + 446
.equ MBRP1_STATUS, PARTITION_TABLE + 0x00
.equ MBRP1_PARTITION_TYPE, PARTITION_TABLE + 0x04
.equ MBRP1_FIRST_SECTOR, PARTITION_TABLE + 0x08

.equ FAT32_BPB, _start + 512
.equ BS_OEMName, FAT32_BPB + 3
.equ BPB_SecPerClus, FAT32_BPB + 13
.equ BPB_RsvdSecCnt, FAT32_BPB + 14
.equ BPB_NumFATs, FAT32_BPB + 16
.equ BPB_FATSz32, FAT32_BPB + 36
.equ BPB_RootClus, FAT32_BPB + 44

.equ CURRENT_FAT, FAT32_BPB + 512
.equ CURRENT_CLUSTER, CURRENT_FAT + 512

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

	# Temporarily exit
	# If stage2.bin is not the first file found.

	# Check if it is a file.
	movb %ds:(CURRENT_CLUSTER + 11), %al
	movb $0x20, %ah # archive
	cmp %al, %ah
	jne exit_failure

	# Check name
	mov $CURRENT_CLUSTER, %si
	mov $stage2_filename, %di
	call strcmp11
	xor %bx, %bx
	cmp %ax, %bx
	je exit_failure
	
	# Load the first cluster of stage2
	call load_stage2
	jmp CURRENT_CLUSTER

	mov $'S', %al
	call print_char
	jmp exit_success

# void load_stage2(directory_entry %si);
# Limitation: Only one cluster...
load_stage2:
	# bx = FstClusLO
	mov %si, %di
	add $26, %di
	mov %ds:(%di), %bx
	call get_start_sector
	mov %ax, %ds:(disk_address_packet_sector)

	# set number of sectors
	movb %ds:(BPB_SecPerClus), %al
	xor %ah, %ah
	mov %ax, %ds:(disk_address_packet_number_of_sectors)

	# set memory address
	movw $0, %ds:(disk_address_packet_segment)
	movw $0x8200, %ds:(disk_address_packet_offset)

	call load
	ret

# %si, %di are both length 11
# returns %ax = 1 if %si = %di, else %ax = 0
#
# %ax strcmp11(str1 %si, str2 %di);
strcmp11:
	push %si
	push %di
	push %cx
	push %dx

	xor %cx, %cx // ctr = 0
	mov $11, %dx // max_count = 11
	strcmp11_loop:
	cmp %cx, %dx
	je strcmp11_loop_done

	movb %ds:(%si), %al
	movb %ds:(%di), %ah
	cmp %al, %ah

	jne strcmp11_ne
	strcmp11_loop_continue:
	inc %cx
	inc %si
	inc %di
	jmp strcmp11_loop
	strcmp11_loop_done:

	strcmp11_e:
	mov $1, %ax
	jmp strcmp11_done

	strcmp11_ne:
	xor %ax, %ax

	strcmp11_done:
	pop %dx
	pop %cx
	pop %di
	pop %si
	ret

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
	movw $CURRENT_CLUSTER, %ds:(disk_address_packet_offset)

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
stage2_filename:
.string "STAGE2  BIN"
disk_address_packet:
.byte 0x10
.byte 0x00
disk_address_packet_number_of_sectors:
.word 1 # number of sectors
disk_address_packet_offset:
.word FAT32_BPB # offset
disk_address_packet_segment:
.word 0 # segment
disk_address_packet_sector:
.quad 0 # lba sector
