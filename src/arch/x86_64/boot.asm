global start
section .text
bits 32
start: 
    mov esp, stack_top
    ; print `OK` to scree
    mov dword [0xb8000], 0x2f4b2f4f
    hlt

; Prints 'ERR: ' and the given error code to the screen. 
; Parameter: error code (in ascii) in al
error: 
    mov dword [0xb8000], 0x4f524f45
    mov dword [0xb8004], 0x4f3a4f52
    mov dword [0xb8008], 0x4f204f20
    mov byte  [0xb800a], al
    hlt

; Throw error 0 if eax doesn't contain the Multiboot 2 magic value (0x36d76289) 
check_multiboot: 
    cmp eax, 0x36d76289
    jne .no_multiboot
    ret
.no_multiboot: 
    mov al, "0"
    jmp error

check_cpuid: 
    ; Check if CPUID is supported by attempting to flip the ID bit (bit 21)
    ; in the FLAGS register. IF we can flip it, CPUID is available. 

    ; Copy FLAGS in to EAX via stack 
    pushfd
    pop eax

    ; Copy to ECX as well for comparing later on
    mov ecx, eax

    ; Flip the ID bit
    xor eax, 1 << 21

    ; Copy EAX to FLAGS via the stack
    push eax
    popfd

    ; Copy FLAGS back to EAX (with the flipped bit if CPUID is supported) 
    pushfd
    pop eax

    ; Restore FLAGS from the old version 
    ; (flipping the ID bit back if it was ever supported)
    push ecx
    popfd

    ; Compare EAX and ECX. If they are equal then that means the bit
    ; wasn't flipped, and CPUID isn't supported 
    cmp eax, ecx
    je .no_cupid
    ret
.no_cpuid: 
    mov al, "1"
    jmp error

; Throw error 2 if the CPU doesn't support Long Mode. 
check_long_mode: 
    ; test if extended processor info is available
    mov eax, 0x80000000     ; implicit argument for cpuid
    cpuid                   ; get highest supported argument
    cmp eax, 0x80000001     ; it needs to be at least 0x80000001
    jb .no_long_mode        ; if it is less, the CPU is to old

    ; use extended info to test if long mode is available
    mov eax, 0x80000001     ; argument for extended processor info
    cpuid                   ; returns various feature bits in ecx and edx
    test edx, 1 << 29       ; test if the LM-bit is set in the D-register
    jz .no_long_mode        ; If it's not set, there is no long mode
    ret
.no_long_mode: 
    mov al, "2"
    jmp error

section .bss
stack_bottom: 
    resb 64
stack_top: 
