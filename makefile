arch ?= x86_64
kernel := build/kernel-$(arch).bin
iso := build/kaos-$(arch).iso


linker_script := src/arch/$(arch)/linker.ld
grub_cfg := src/arch/$(arch)/grub.cfg
assembly_source_files := $(wildcard src/arch/$(arch)/*.asm)
assembly_object_files := $(patsubst src/arch/$(arch)/%.asm, \
	build/arch/$(arch)/%.o, $(assembly_source_files))

target ?= $(arch)-unknown-linux-gnu
rust_os := target/$(target)/debug/libkaos.a
rust_source_files := $(wildcard src/*.rs) 
cargo_cfg := Cargo.toml

.PHONY: all clean run iso

all: $(iso)

clean:
	@cargo clean
	@rm -rf build

run: $(iso)
	@qemu-system-x86_64 -cdrom $(iso)

kernel: $(kernel)

cargo: $(rust_os)

$(iso): $(kernel) $(grub_cfg)
	@echo "building iso..." 
	@mkdir -p build/isofiles/boot/grub
	@cp $(kernel) build/isofiles/boot/kernel.bin
	@cp $(grub_cfg) build/isofiles/boot/grub
	@grub-mkrescue -o $(iso) build/isofiles 2> /dev/null
	@rm -r build/isofiles

$(kernel): $(rust_os) $(assembly_object_files) $(linker_script)
	@echo "building kernel..."
	@ld -n --gc-section -T $(linker_script) -o $(kernel) $(assembly_object_files) $(rust_os)

$(rust_os) : $(rust_source_files)
	@echo "running cargo build --target $(target)" 
	@cargo build --target $(target) 

# compile assembly files
build/arch/$(arch)/%.o: src/arch/$(arch)/%.asm
	@echo "compiling $<" 
	@mkdir -p $(shell dirname $@)
	@nasm -felf64 $< -o $@
