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

    mov ax, 0x0000
    mov es, ax
    mov bx, 0x8000
    mov ah, 0x02
    mov al, 2        
    mov ch, 0          
    mov cl, 2          
    mov dh, 0         
    mov dl, 0x80       
    int 0x13
    jc $               

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

    mov dword [0x8000], 0xC000 + 0x03
    mov dword [0x8004], 0
    mov dword [0xC000], 0x10000 + 0x03
    mov dword [0xC004], 0
    mov dword [0x10000], 0 + 0x83
    mov dword [0x10004], 0
    mov dword [0x10008], 0x200000 + 0x83
    mov dword [0x1000C], 0

    lea eax, [0x8000]
    mov cr3, eax

    mov ecx, 0xC0000080
    rdmsr
    or eax, 0x100         
    wrmsr

    mov eax, cr0
    or eax, 0x80000000    
    mov cr0, eax

    jmp 0x18:long_mode_start

use64
long_mode_start:
    mov rsi, msg
    mov rdi, 0xB8000
.print_loop:
    lodsb
    test al, al
    jz .done
    mov [rdi], al
    inc rdi
    mov byte [rdi], 0x0F
    inc rdi
    jmp .print_loop
.done:
    hlt
    jmp $

msg db 'arq is loading the kernel', 0

times 510 - ($ - $$) db 0
dw 0xAA55
