# mandelboot


A bios-based NASM bootloader for x86 architecture, drawing the mandelbrot set.

All the code is contanied in the 512 bytes boot sector.

The code itself is 279 bytes long, and could be reduced even more (i got it working with 169 bytes), but since the file has to be 512 bytes long anyways, it doesn't matter.

To assemble, just use `nasm -f mandelboot.asm -o *.img`

If you want to try on physical x86 compatible hardware, you can use Win32DiskImager to flash it to a USB stick.

It's my first real ASM project, and also my first boodloader, feel free to give advice.
