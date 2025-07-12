org 0x8000

mov ax, 0xB800
mov es, ax
mov di, 0
mov si, msg
print:
    lodsb
    test al, al
    jz $
    stosb
    mov byte [es:di], 0x0A
    inc di
    jmp print

msg db "KERNEL IS LOADED!", 0
