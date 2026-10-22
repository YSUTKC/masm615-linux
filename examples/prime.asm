; 埃拉托色尼筛法：求 100 以内的素数
; 演示：字节数组、嵌套循环、乘法、数组下标寻址、过程调用
        .model  small
        .stack  100h

        .data
limit   equ     100
sieve   db      limit + 1 dup(1)
msg1    db      'Primes up to 100:', 13, 10, '$'
msg2    db      13, 10, 'Count: $'

        .code
main    proc
        mov     ax, @data
        mov     ds, ax

        ; 0 和 1 不是素数
        mov     byte ptr sieve, 0
        mov     byte ptr sieve + 1, 0

        ; p = 2 .. 10（sqrt(100) = 10）
        mov     cx, 2
outer_p:
        cmp     cx, 10
        ja      sieve_done
        mov     si, cx
        cmp     byte ptr [sieve + si], 0
        je      next_p

        ; k = p*p
        mov     ax, cx
        mul     cx
        mov     si, ax

mark_multiples:
        cmp     si, limit
        ja      next_p
        mov     byte ptr [sieve + si], 0
        add     si, cx
        jmp     mark_multiples

next_p:
        inc     cx
        jmp     outer_p

sieve_done:
        lea     dx, msg1
        mov     ah, 9
        int     21h

        mov     si, 2
        xor     bx, bx              ; 素数个数

print_primes:
        cmp     si, limit
        ja      print_done
        cmp     byte ptr [sieve + si], 0
        je      skip_prime

        mov     ax, si
        call    print_unsigned
        mov     dl, ' '
        mov     ah, 2
        int     21h
        inc     bx

skip_prime:
        inc     si
        jmp     print_primes

print_done:
        lea     dx, msg2
        mov     ah, 9
        int     21h
        mov     ax, bx
        call    print_unsigned

        mov     ah, 4ch
        int     21h
main    endp

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
