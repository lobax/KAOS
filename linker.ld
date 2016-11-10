ENTRY(start)

SECTIONS { 
    . = 1M;

    .boot : 
    { 
        /* ensure the multiboot header is at the beginning of the file*/
        *(.multiboot_header)
    } 

    .text : 
    { 
        *(.text)
    }
}
