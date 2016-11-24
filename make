#![feature(lang_items)]
#![feature(const_fn, unique)]
#![no_std]

extern crate rlibc;
extern crate volatile;
extern crate spin;
extern crate multiboot2;

#[macro_use]
mod vga_buffer;

#[no_mangle]
pub extern fn rust_main(multiboot_information_adress: usize) {
    let title = b"8  dP    db    .d88b. .d88b.\n8wdP    dPYb   8P  Y8 YPwww.\n88Yb   dPwwYb  8b  d8     d8\n8  Yb dP    Yb `Y88P' `Y88P'"; 
    let color_byte = 0x0c; // Light red foreground, black background

    // Home made print function
    print(title, &color_byte, 10, 26); 
    
    let boot_info = unsafe { multiboot2::load(multiboot_information_adress) }; 
    let memory_map_tag = boot_info.memory_map_tag()
             .expect("Memory map tag required"); 

    println!("Memory areas:");
    for area in memory_map_tag.memory_areas() {
        println!("  Start: 0x{:x}, length: 0x{:x}",
                 area.base_addr, area.length); 
    }

    loop{}
}

fn print(string: &[u8], color: &u8, mut row: u64, column: u64) {
    let mut col = column; 
    for char_byte in string { 
        if is_new_line(char_byte) { 
            row += 1; 
            col = column;
            continue;
        }
        let buffer_ptr = (0xb8000 + row*0xa0 + col*2) as *mut _;
        let colored_string = [*char_byte, *color];
        unsafe { *buffer_ptr = colored_string };
        col += 1; 

    }
}

fn is_new_line(val: &u8) -> bool {
    let b: bool = match *val as char {
            '\n' => true,
            _ => false
    };
    return b;
}

#[lang = "eh_personality"] 
extern fn eh_personality() {} 

#[lang = "panic_fmt"]
extern fn panic_fmt(fmt: core::fmt::Arguments, file: &str, line: u32) -> ! {
    vga_buffer::clear_screen(); 
    vga_buffer::set_text_color(vga_buffer::Color::Red); 
    println!("PANIC in {} at line {}:", file, line);
    println!("      {}", fmt);
    loop{}
}

#[allow(non_snake_case)]
#[no_mangle]
pub extern "C" fn _Unwind_Resume() -> ! { 
    loop {} 
}

