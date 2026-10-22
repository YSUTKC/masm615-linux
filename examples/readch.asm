; 读取一个字符并回显，用于演示 dosrun 的管道输入
        .model  small
        .stack  100h

        .code
main    proc
        mov     ah, 1
        int     21h
        mov     dl, al
        mov     ah, 2
        int     21h
        mov     ah, 4ch
        int     21h
main    endp

        end     main
