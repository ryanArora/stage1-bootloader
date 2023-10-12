AS = x86_64-elf-as
LD = x86_64-elf-ld

OS_NAME = ros
DISK_SIZE = 8G

.PHONY: clean img stage1

img: boot/x86_64-mbr-$(OS_NAME).img
boot/x86_64-mbr-$(OS_NAME).img: boot/stage1.bin
	fallocate -l $(DISK_SIZE) boot/x86_64-mbr-$(OS_NAME).img
	printf "n\np\n1\n2048\n+128M\na\nt\n0xb\nn\np\n2\n\n\nt\n2\n0xb\np\nw\n" | fdisk boot/x86_64-mbr-ros.img
	dd if=boot/stage1.bin of=boot/x86_64-mbr-$(OS_NAME).img bs=1 count=446 conv=notrunc

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

clean:
	rm -f boot/stage1.bin boot/x86_64-mbr-$(OS_NAME).img
