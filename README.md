# Stage1 Bootloader

This project is a stage1 bootloader written in x86 assembly. I started this because I became interested in assembly while I was taking a Computer Organization course [(CSC258)](https://utm.calendar.utoronto.ca/course/csc258h5) in my Fall semester of 2nd year of University.

## What?

In legacy systems (pre-UEFI), when the system boots, the BIOS loads the first sector of a bootable device to a hardcoded address, and transfers execution to it.

The first 446 bytes of this sector is the stage1 bootloader.
The next 64 bytes hold the partition table.
The last 2 bytes must be the boot signature (0x55AA) for the BIOS to recognize it as bootable.

The job of the stage1 bootloader is to read the partition table and copy the stage2 bootloader from disk into memory from a FAT32-formatted partition.
Then, it transfers execution to the stage2 bootloader.
It's usually written in assembly because of the strict size requirements (maximum 446 bytes).

## Build Dependencies

- `x86_64-elf` binutils
- `make`
- `qemu-system-x86_64`
- `fallocate`
- `fdisk`
- `dosfstools`

## Run

This creates a spare file image emulating the boot disk and executes it with the `qemu` virtual machine.

```bash
cd ./arch/x86_64
make img
qemu-system-x86_64 ../../targets/x86_64-mbr-ros.img
```

# License

[GPL-3.0](./LICENSE)
