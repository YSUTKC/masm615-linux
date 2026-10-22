; 递归阶乘 + 32 位无符号十进制输出
; 演示：32 位寄存器、32 位乘除、递归、栈帧
        .model  small
        .386
        .stack  100h

        .data
n       dd      12
msg     db      '12! = $'

        .code
main    proc
        mov     ax, @data
        mov     ds, ax

        lea     dx, msg
        mov     ah, 9
        int     21h

        mov     eax, n
        call    fact
        call    print_u32

        mov     ah, 4ch
        int     21h
main    endp

; ------------------------------------------------------------
; 递归阶乘：输入 EAX = n，输出 EAX = n!
; ------------------------------------------------------------
fact    proc
        cmp     eax, 1
        jbe     fact_base

        push    eax
        dec     eax
        call    fact
        pop     ecx
        imul    eax, ecx
        ret

fact_base:
        mov     eax, 1
        ret
fact    endp

; ------------------------------------------------------------
; 打印 EAX 中的无符号 32 位十进制数
; ------------------------------------------------------------
print_u32 proc
        push    eax
        push    ebx
        push    ecx
        push    edx

        xor     ecx, ecx
        mov     ebx, 10

pu32_div:
        xor     edx, edx
        div     ebx
        push    edx
        inc     ecx
        test    eax, eax
        jnz     pu32_div

pu32_print:
        pop     edx
        add     dl, '0'
        mov     ah, 2
        int     21h
        loop    pu32_print

        pop     edx
        pop     ecx
        pop     ebx
        pop     eax
        ret
print_u32 endp

        end     main
