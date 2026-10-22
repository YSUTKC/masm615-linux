; 递归汉诺塔：打印 3 个盘子的移动步骤
; 演示：递归、栈保存现场、字符输出、计数器
        .model  small
        .stack  200h

        .data
n       equ     3
msg     db      'Hanoi(3):', 13, 10, '$'
msgTot  db      13, 10, 'Total moves: $'
moves   dw      0

        .code
main    proc
        mov     ax, @data
        mov     ds, ax

        lea     dx, msg
        mov     ah, 9
        int     21h

        ; hanoi(n, from, to, via)
        mov     cx, n
        mov     al, 'A'
        mov     bl, 'C'
        mov     dl, 'B'
        call    hanoi

        lea     dx, msgTot
        mov     ah, 9
        int     21h
        mov     ax, moves
        call    print_unsigned

        mov     ah, 4ch
        int     21h
main    endp

; ------------------------------------------------------------
; hanoi: CX = 盘子数, AL = 源柱, BL = 目标柱, DL = 辅助柱
; ------------------------------------------------------------
hanoi   proc
        cmp     cx, 0
        je      hanoi_ret

        ; hanoi(n-1, from, via, to)
        push    ax
        push    bx
        push    dx
        push    cx
        dec     cx
        xchg    bl, dl
        call    hanoi
        pop     cx
        pop     dx
        pop     bx
        pop     ax

        ; 打印 from -> to
        push    ax
        push    bx
        push    dx
        push    cx

        mov     dl, al
        mov     ah, 2
        int     21h
        mov     dl, '-'
        int     21h
        mov     dl, '>'
        int     21h
        mov     dl, bl
        int     21h
        mov     dl, 13
        int     21h
        mov     dl, 10
        int     21h
        inc     moves

        pop     cx
        pop     dx
        pop     bx
        pop     ax

        ; hanoi(n-1, via, to, from)
        push    ax
        push    bx
        push    dx
        push    cx
        dec     cx
        xchg    al, dl
        call    hanoi
        pop     cx
        pop     dx
        pop     bx
        pop     ax

hanoi_ret:
        ret
hanoi   endp

; ------------------------------------------------------------
; 打印 AX 中的无符号十进制数
; ------------------------------------------------------------
print_unsigned proc
        push    ax
        push    bx
        push    cx
        push    dx

        xor     cx, cx
        mov     bx, 10

pu_div:
        xor     dx, dx
        div     bx
        push    dx
        inc     cx
        cmp     ax, 0
        jne     pu_div

pu_print:
        pop     dx
        add     dl, '0'
        mov     ah, 2
        int     21h
        loop    pu_print

        pop     dx
        pop     cx
        pop     bx
        pop     ax
        ret
print_unsigned endp

        end     main
