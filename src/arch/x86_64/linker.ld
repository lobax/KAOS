ENTRY(start)

SECTIONS { 
    . = 1M;

    .rodata : 
    { 
        /* ensure the multiboot header is at the beginning of the file*/
        KEEP(*(.multiboot_header))
        *(.rodata .rodata.*)
        . = ALIGN(4K);
    } 

    .text : 
    { 
        *(.text .text.*)
        . = ALIGN(4k);
    }

    .data : 
    {
        *(.data .data.*)
        . = ALIGN(4k);
    }

    .bss : 
    {
        *(.bss .bss.*)
        . = ALIGN(4k);
    }
    
    .got : 
    {
        *(.got)
        . = ALIGN(4k);
    }

    .got.plt : 
    {
        *(.got.plt)
        . = ALIGN(4k);
    }

    .data.rel.ro : ALIGN(4K) {
        *(.data.rel.ro.local*) *(.data.rel.ro .data.rel.ro.*)
        . = ALIGN(4k);
    }

    .gcc_except_table : 
    {
        *(.gcc_except_table)
        . = ALIGN(4k);
    }
}
