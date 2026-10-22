; 2x2 整数矩阵乘法 C = A * B
; 演示：二维数组行主序寻址、三层循环、IMUL、过程调用
        .model  small
        .stack  100h

        .data
A       dw      1, 2, 3, 4          ; [1 2]
                                    ; [3 4]
B       dw      5, 6, 7, 8          ; [5 6]
                                    ; [7 8]
MATC    dw      4 dup(0)
i       dw      0
j       dw      0
k       dw      0
sum     dw      0

msgA    db      'A = [1 2; 3 4]', 13, 10, '$'
msgB    db      'B = [5 6; 7 8]', 13, 10, '$'
msgC    db      'A*B = [', '$'
msgSemi db      '; $'
msgEnd  db      ']', 13, 10, '$'

        .code
main    proc
        mov     ax, @data
        mov     ds, ax

        lea     dx, msgA
        mov     ah, 9
        int     21h
        lea     dx, msgB
        mov     ah, 9
        int     21h

        ; ------------------------------------------------
        ; for i = 0..1
        ;   for j = 0..1
        ;     sum = 0
        ;     for k = 0..1
        ;       sum += A[i][k] * B[k][j]
        ;     C[i][j] = sum
        ; ------------------------------------------------
        mov     i, 0
outer_i:
        cmp     i, 2
        jae     calc_done

        mov     j, 0
outer_j:
        cmp     j, 2
        jae     next_i

        mov     sum, 0
        mov     k, 0
inner_k:
        cmp     k, 2
        jae     store_c

        ; A[i][k] 的字节偏移 = i*4 + k*2
        mov     ax, i
        shl     ax, 1
        shl     ax, 1
        mov     bx, k
        shl     bx, 1
        add     ax, bx
        mov     si, ax
        mov     ax, A[si]

        ; B[k][j] 的字节偏移 = k*4 + j*2
        mov     bx, k
        shl     bx, 1
        shl     bx, 1
        mov     dx, j
        shl     dx, 1
        add     bx, dx
        mov     di, bx
        mov     bx, B[di]

        imul    bx                  ; DX:AX = A[i][k] * B[k][j]
        add     sum, ax

        inc     k
        jmp     inner_k

store_c:
        ; C[i][j] 的字节偏移 = i*4 + j*2
        mov     ax, i
        shl     ax, 1
        shl     ax, 1
        mov     bx, j
        shl     bx, 1
        add     ax, bx
        mov     di, ax
        mov     ax, sum
        mov     MATC[di], ax

        inc     j
        jmp     outer_j

next_i:
        inc     i
        jmp     outer_i

calc_done:
        ; ------------------------------------------------
        ; 输出结果
        ; ------------------------------------------------
        lea     dx, msgC
        mov     ah, 9
        int     21h

        mov     ax, MATC
        call    print_signed
        mov     dl, ' '
        mov     ah, 2
        int     21h

        mov     ax, MATC + 2
        call    print_signed
        lea     dx, msgSemi
        mov     ah, 9
        int     21h

        mov     ax, MATC + 4
        call    print_signed
        mov     dl, ' '
        mov     ah, 2
        int     21h

        mov     ax, MATC + 6
        call    print_signed
        lea     dx, msgEnd
        mov     ah, 9
        int     21h

        mov     ah, 4ch
        int     21h
main    endp

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
