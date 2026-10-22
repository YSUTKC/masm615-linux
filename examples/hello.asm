; 最简单的 MASM 6.x 16 位 DOS 程序
        .model  small
        .stack  100h

        .data
msg     db      'Hello DOS!$'

        .code
main    proc
        mov     ax, @data
        mov     ds, ax
        mov     dx, offset msg
        mov     ah, 9
        int     21h
        mov     ah, 4ch
        int     21h
main    endp

        end     main
