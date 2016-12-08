#![feature(lang_items, const_fn, unique, alloc, collections)]
#![no_std]

extern crate rlibc;
extern crate volatile;
extern crate spin;
extern crate multiboot2;
#[macro_use]
extern crate bitflags;
extern crate x86;
extern crate hole_list_allocator;
extern crate alloc;
#[macro_use]
extern crate collections; 
#[macro_use]
extern crate once;

#[macro_use]
mod vga_buffer;
mod memory;

use memory::FrameAllocator;

#[no_mangle]
pub extern fn rust_main(multiboot_information_adress: usize) {
    
    print_logo(); 
    enable_nxe_bit();
    enable_write_protect_bit();
    
    let boot_info = unsafe { multiboot2::load(multiboot_information_adress) }; 

    // set up guard page and map the heap pages
    memory::init(boot_info);

    use alloc::boxed::Box;
    let mut heap_test = Box::new(42);
    *heap_test -= 15;
    let heap_test2 = Box::new("hello");
    println!("{:?} {:?}", heap_test, heap_test2);

    let mut vec_test = vec![1,2,3,4,5,6,7];
    vec_test[3] = 42;
    for i in &vec_test {
            print!("{} ", i);
    }

    println!("It did not crash!"); 

    loop{}
}

fn enable_nxe_bit() { 
    use x86::msr::{IA32_EFER, rdmsr, wrmsr}; 

    let nxe_bit = 1 << 11; 
    unsafe { 
        let efer = rdmsr(IA32_EFER); 
        wrmsr(IA32_EFER, efer | nxe_bit); 
    }
}

fn enable_write_protect_bit() { 
    use x86::controlregs::{cr0, cr0_write}; 

    let wp_bit = 1 << 16; 
    unsafe { cr0_write(cr0() | wp_bit) };
}
    

fn print_logo() {
    // Set font color 
    vga_buffer::set_text_color(vga_buffer::Color::LightRed); 

    println!(""); 
    let title = "8  dP    db    .d88b. .d88b.\n8wdP    dPYb   8P  Y8 YPwww.\n88Yb   dPwwYb  8b  d8     d8\n8  Yb dP    Yb `Y88P' `Y88P'"; 
    println!("{}", title);  

    // Reset font color
    vga_buffer::set_text_color(vga_buffer::Color::LightGreen); 

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
