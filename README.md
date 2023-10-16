# `ros` (Ryan's Operating System)

This is a toy operating system to help me learn systems programming.

## Build Dependencies

- `x86_64-elf` binutils
- `make`
- `qemu-system-x86_64`
- `fallocate`
- `fdisk`

## Run

This creates a spare file image emulating the boot disk and executes it with the `qemu` virtual machine.

```bash
cd ./arch/x86_64
make img
qemu-system-x86_64 ../../targets/x86_64-mbr-ros.img
```

# License

[GPL-3.0](./LICENSE)
