AS = as
LD = ld

main.bin: build/main.o
	$(LD) --oformat binary -Ttext 0x7C00 -o main.bin build/main.o

build/main.o: boot/main.S | mkdir
	$(AS) -o build/main.o boot/main.S

mkdir:
	mkdir -p build

clean:
	rm -rf build main.bin main_floppy.img

.PHONY: clean
