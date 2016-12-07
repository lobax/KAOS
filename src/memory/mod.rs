pub use self::area_frame_allocator::AreaFrameAllocator; 
use self::paging::PhysicalAddress;
pub use self::paging::test_paging;

mod area_frame_allocator; 
mod paging;


#[derive(Debug, PartialEq, Eq, PartialOrd, Ord)]
pub struct Frame { 
    number: usize,
}

pub const PAGE_SIZE: usize = 4096; 

impl Frame { 

    fn start_address(&self) -> PhysicalAddress { 
        self.number * PAGE_SIZE
    }

    fn containing_adress(adress: usize) -> Frame { 
        Frame { number: adress / PAGE_SIZE}  
    }
}

pub trait FrameAllocator { 
    fn allocate_frame(&mut self) -> Option<Frame>;
    fn deallocate_frame(&mut self, frame: Frame);
} 


