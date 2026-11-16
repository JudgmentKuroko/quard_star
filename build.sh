SHELL_FOLDER=$(cd "$(dirname "$0")";pwd)

cd qemu-6.0.0
if [ ! -d "$SHELL_FOLDER/output/qemu" ]; then  
./configure --prefix=$SHELL_FOLDER/output/qemu  --target-list=riscv64-softmmu --enable-gtk  --enable-virtfs --disable-gio
fi  
make -j16
make install
cd ..
# Build low-level firmware
(
    set -e
    cd "$SHELL_FOLDER"

    CROSS_PREFIX=/opt/riscv64--glibc--bleeding-edge-2020.08-1/bin/riscv64-linux
    FW_DIR="$SHELL_FOLDER/output/lowlevelboot"

    mkdir -p "$FW_DIR"

    "$CROSS_PREFIX-gcc" -x assembler-with-cpp \
        -c lowlevelboot/startup.s \
        -o "$FW_DIR/startup.o"

    "$CROSS_PREFIX-gcc" -nostdlib -static \
        -T lowlevelboot/boot.lds \
        -Wl,--build-id=none \
        -Wl,-Map="$FW_DIR/lowlevel_fw.map" \
        -Wl,--gc-sections \
        "$FW_DIR/startup.o" \
        -o "$FW_DIR/lowlevel_fw.elf"

    "$CROSS_PREFIX-objcopy" -O binary -S \
        "$FW_DIR/lowlevel_fw.elf" "$FW_DIR/lowlevel_fw.bin"

    "$CROSS_PREFIX-objdump" --source --demangle --disassemble --reloc --wide \
        "$FW_DIR/lowlevel_fw.elf" > "$FW_DIR/lowlevel_fw.lst"

    dd if=/dev/zero of="$FW_DIR/fw.bin" bs=1M count=32
    dd if="$FW_DIR/lowlevel_fw.bin" of="$FW_DIR/fw.bin" \
        bs=1K seek=0 conv=notrunc
)