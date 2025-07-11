org 0x7C00

start:
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7C00

    call enable_a20
    call load_gdt
    call enter_protected_mode

.hang:
    jmp .hang

enable_a20:
.wait1: in al, 0x64
        test al, 2
        jnz .wait1
        mov al, 0xD1
        out 0x64, al

.wait2: in al, 0x64
        test al, 2
        jnz .wait2
        mov al, 0xDF
        out 0x60, al
        ret

gdt_start:
gdt_null:   dq 0
gdt_code32: dq 0x00CF9A000000FFFF
gdt_data32: dq 0x00CF92000000FFFF
gdt_code64: dq 0x00AF9A000000FFFF
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

load_gdt:
    lgdt [gdt_descriptor]
    ret

enter_protected_mode:
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp 0x08:protected_mode_start

use32
protected_mode_start:
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000

    mov eax, cr4
    or eax, 0x20          
    mov cr4, eax

    lea eax, [pml4]
    mov cr3, eax

    mov ecx, 0xC0000080
    rdmsr
    or eax, 0x100         
    wrmsr

    mov esi, msg
    mov edi, 0xB8000
.next:
    lodsb
    test al, al
    jz .done
    mov [edi], al
    inc edi
    mov byte [edi], 0x0F
    inc edi
    jmp .next
.done:
    hlt
    jmp $

msg db 'EFER MSR enabled - ARQ is stable', 0

times 510 - ($ - $$) db 0
dw 0xAA55

align 4096
pml4:
    dq pdpt + 0x03     

align 4096
pdpt:
    dq pd + 0x03

align 4096
pd:
    dq 0x0000000000000083
    dq 0x0000000000200083
    dq 0x0000000000400083
    dq 0x0000000000600083
    dq 0x0000000000800083
    dq 0x0000000000A00083
    dq 0x0000000000C00083
    dq 0x0000000000E00083
    times 504 dq 0

