; 冒泡排序：对 16 位有符号数组升序排序
; 演示：数组寻址、嵌套循环、过程调用、有符号比较、十进制输出
        .model  small
        .stack  100h

        .data
array   dw      9, -3, 0, 7, 2, -8, 5, 1
n       equ     ($ - array) / 2
msg1    db      'Before: $'
msg2    db      13, 10, 'After:  $'
msg3    db      13, 10, '$'

        .code
main    proc
        mov     ax, @data
        mov     ds, ax

        lea     dx, msg1
        mov     ah, 9
        int     21h
        call    print_array

        lea     dx, msg2
        mov     ah, 9
        int     21h

        call    bubble_sort
        call    print_array

        lea     dx, msg3
        mov     ah, 9
        int     21h

        mov     ah, 4ch
        int     21h
main    endp

; ------------------------------------------------------------
; 冒泡排序（有符号字数组，升序）
; ------------------------------------------------------------
bubble_sort proc
        mov     cx, n
        dec     cx
        jz      sort_done

outer_loop:
        push    cx
        lea     si, array
        mov     bx, cx

inner_loop:
        mov     ax, [si]
        mov     dx, [si + 2]
        cmp     ax, dx
        jle     no_swap
        mov     [si], dx
        mov     [si + 2], ax

no_swap:
        add     si, 2
        dec     bx
        jnz     inner_loop

        pop     cx
        loop    outer_loop

sort_done:
        ret
bubble_sort endp

; ------------------------------------------------------------
; 打印整个数组
; ------------------------------------------------------------
print_array proc
        lea     si, array
        mov     cx, n

print_loop:
        mov     ax, [si]
        call    print_signed
        mov     dl, ' '
        mov     ah, 2
        int     21h
        add     si, 2
        loop    print_loop
        ret
print_array endp

; ------------------------------------------------------------
; 打印 AX 中的有符号十进制数
; ------------------------------------------------------------
print_signed proc
        test    ax, ax
        jns     ps_positive
        push    ax
        mov     dl, '-'
        mov     ah, 2
        int     21h
        pop     ax
        neg     ax

ps_positive:
        call    print_unsigned
        ret
print_signed endp

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
