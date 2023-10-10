AS = x86_64-elf-as
LD = x86_64-elf-ld

OS_NAME = ros
DISK_SIZE = 1G

.PHONY: clean img mbr

img: boot/x86_64-mbr-$(OS_NAME).img
boot/x86_64-mbr-$(OS_NAME).img: boot/mbr.bin
	qemu-img create -f qcow2 boot/x86_64-mbr-$(OS_NAME).img $(DISK_SIZE)
	qemu-img dd -f raw -O qcow2 if=boot/mbr.bin of=boot/x86_64-mbr-$(OS_NAME).img bs=512 count=1

mbr: boot/mbr.bin
boot/mbr.bin: boot/stage1.S
	$(AS) -o boot/stage1.o boot/stage1.S
	$(LD) --oformat binary -Ttext 0x7C00 -o boot/mbr.bin boot/stage1.o
	rm boot/stage1.o
	@if [ $$(stat -c %s boot/mbr.bin) -gt 512 ]; then \
		echo "Error: stage1.bin is larger than one sector (512 bytes)"; \
		rm boot/mbr.bin; \
		exit 1; \
	fi

clean:
	rm boot/mbr.bin boot/x86_64-mbr-$(OS_NAME).img
