section .multiboot_header

header_start: 
    dd 0xe85250d6               ; magic number (multiboot 2)
    dd 0                        ; i386 architecture 
    dd header_end - header_start    ; header length
    dd - (0xe85250d6 + 0 + (header_end - header_start)) ; checksum

    ; optional mutiboot tags

    ; required end tag
    dw 0                        ; type
    dw 0                        ; flags
    dd 8                        ; size
header_end: 
