AS = x86_64-elf-as
LD = x86_64-elf-ld

DISK_SIZE = 8G
PARTITION_OFFSET_SECTORS = 2048
PARTITION_OFFSET_BYTES = 1048576

.PHONY: clean img stage1 stage2 

img: ../../targets/x86_64-mbr-ros.img
../../targets/x86_64-mbr-ros.img: boot/stage1.bin boot/stage2.bin
	mkdir -p ../../targets/
	rm -f ../../targets/x86_64-mbr-ros.img
	fallocate -l $(DISK_SIZE) ../../targets/x86_64-mbr-ros.img
	printf "n\np\n1\n2048\n+128M\na\nt\n0xc\nn\np\n2\n\n\nt\n2\n0xb\np\nw\n" | fdisk ../../targets/x86_64-mbr-ros.img
	dd if=boot/stage1.bin of=../../targets/x86_64-mbr-ros.img bs=1 count=446 conv=notrunc

	mkdir -p ../../targets/disk/boot/
	cp boot/stage2.bin ../../targets/disk/boot/
	
	mkfs.fat -F 32 --offset $(PARTITION_OFFSET_SECTORS) ../../targets/x86_64-mbr-ros.img
	mcopy -i ../../targets/x86_64-mbr-ros.img@@$(PARTITION_OFFSET_BYTES) ../../targets/disk/boot/* ::

stage1: boot/stage1.bin
boot/stage1.bin: boot/stage1.S
	$(AS) -o boot/stage1.o boot/stage1.S
	$(LD) --oformat binary -Ttext 0x7C00 -o boot/stage1.bin boot/stage1.o
	rm boot/stage1.o
	@if [ $$(stat -c %s boot/stage1.bin) -gt 446 ]; then \
		echo "Error: stage1.bin must not be larger than 446 bytes"; \
		rm boot/stage1.bin; \
		exit 1; \
	fi

stage2: boot/stage2.bin
boot/stage2.bin: boot/stage2.S
	$(AS) -o boot/stage2.o boot/stage2.S
	$(LD) --oformat binary -Ttext 0x8200 -o boot/stage2.bin boot/stage2.o
	rm boot/stage2.o

clean:
	rm -f boot/stage1.bin boot/stage2.bin ../../targets/x86_64-mbr-ros.img ../../targets/disk/boot/stage2.bin
