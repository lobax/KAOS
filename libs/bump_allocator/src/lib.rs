#![feature(allocator)]

#![allocator]
#![no_std]
#![feature(const_fn)] 


use spin::Mutex; 

extern crate spin; 

pub const HEAP_START: usize = 0o_000_001_000_000_0000;
pub const HEAP_SIZE: usize = 100 * 1024; // 100 KiB

static BUMP_ALLOCATOR: Mutex<BumpAllocator> = Mutex::new(
    BumpAllocator::new(HEAP_START, HEAP_SIZE));



#[no_mangle]
pub extern fn __rust_allocate(size: usize, align: usize) -> *mut u8 {
    BUMP_ALLOCATOR.lock().allocate(size, align).expect("out of memory")
}

#[no_mangle]
pub extern fn __rust_usable_size(size: usize, align: usize) -> usize {
    size
}

#[no_mangle]
pub extern fn __rust_deallocate(ptr: *mut u8, size: usize, align: usize) {
    // Just leak it
}

#[no_mangle]
pub extern fn __rust_reallocate(ptr: *mut u8, size: usize, new_size: usize,
                                align: usize) -> *mut u8 {
    use core::{ptr, cmp};

    let new_ptr = __rust_allocate(new_size, align); 
    unsafe { ptr::copy(ptr, new_ptr, cmp::min(size, new_size)) }; 
    __rust_deallocate(ptr, size, align); 
    new_ptr
}

#[no_mangle]
pub extern fn __rust_reallocate_inplace(ptr: *mut u8, size: usize,
                                        new_size: usize, align: usize)
    -> usize {
    size    
}

/// Align downwards. Returns the greatest x with alignment `align`
/// so that x <= addr. The alignment must be a power of 2
pub fn align_down(addr: usize, align: usize) -> usize { 
    if align.is_power_of_two() { 
        addr & !(align -1)
    } else if align == 0 { 
        addr
    } else { 
        panic!("`align` must be a power of 2"); 
    }
}

/// Align upwards. Returns the smallest x with alignment `align`
/// so that x >= addr. The alignment must be a power of 2. 
pub fn align_up(addr: usize, align: usize) -> usize { 
    align_down(addr + align - 1, align)
}

#[derive(Debug)]
struct BumpAllocator { 
    heap_start: usize, 
    heap_size: usize,
    next: usize, 
}

impl BumpAllocator { 
    /// Create a new allocator, which uses the memory in the
    /// range [heap_start, heap_start + heap_size).
    const fn new(heap_start: usize, heap_size: usize) -> BumpAllocator { 
        BumpAllocator { 
            heap_start: heap_start, 
            heap_size: heap_size, 
            next: heap_start, 
        } 
    }

    /// Allocates a block of memory with the give size and aligment. 
    fn allocate(&mut self, size: usize, align: usize) -> Option<*mut u8> { 
        let alloc_start = align_up(self.next, align); 
        let alloc_end = alloc_start.saturating_add(size); 

        if alloc_end <= self.heap_start + self.heap_size { 
            self.next = alloc_end; 
            Some(alloc_start as *mut u8)
        } else { 
            None
        }
    }
    
}

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
    }
}
