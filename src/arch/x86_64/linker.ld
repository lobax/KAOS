ENTRY(start)

SECTIONS { 
    . = 1M;

    .boot : 
    { 
        /* ensure the multiboot header is at the beginning of the file*/
        KEEP(*(.multiboot_header))
    } 

    .text : 
    { 
        *(.text .text.*)
    }

    .rodata : 
    {
        *(.rodata .rodata.*)
    }

    .data.rel.ro :
    {
        *(.data.rel.ro.local*) *(.data.rel.ro .data.rel.ro.*)
    }
}
