jmp  main
;header to allow USB boot on some bios
    OEMname:            db       "MandelBoot",0
    bytesPerSector:     dw       512
    sectPerCluster:     db       1
    reservedSectors:    dw       1
    numFAT:             db       2
    numRootDirEntries:  dw       240
    numSectors:         dw       5760
    mediaType:          db       0xf0
    numFATsectors:      dw       9
    sectorsPerTrack:    dw       36
    numHeads:           dw       2
    numHiddenSectors:   dd       0
    numSectorsHuge:     dd       0
    driveNum:           db       0
    reserved:           db       0x00
    signature:          db       0x29
    volumeID:           dd       0x54428E71
    volumeLabel:        db       "NO NAME",0
    fileSysType:        db       "None",0

;;CONSTANTS:

;hlogn =log2(n)/2 used to accelerate divisions of fixed-point numbers
hlogn:equ 6
;fixed-point constant
n: equ 1<<(2*hlogn)

;scaling factor
scf equ n*2/150
n2: equ 2*n

;coordinates of the center
offsetx: equ 0
offsety: equ 0
centerx: equ 160 - offsetx
centery: equ 100 - offsety

;flag the start of the program in plain to memory since i have free space anyways
db "actual start->"
main:
;setup usefull registers
mov ax, 0x07c0
mov ds, ax
mov es, ax
mov ss, ax
mov sp, 0x7c00


;start colored VGA 320x200x256 mode
mov ah, 0
mov al, 13h
int 0x10

begin:
mov cx,0
mov dx,0
startx:
    push dx
    ;scaling the y coordinate
    mov [yc], dx
    sub [yc],word centery
    mov ax,[yc]
    mov bx,word scf
    mul bx
    mov [yc],ax
    pop dx
    starty:
        push dx
        push cx
        ;scaling the x coordinate
        mov [xc], cx
        sub [xc],word centerx
        mov ax,[xc]
        mov bx,word scf
        mul bx
        mov [xc],ax

        ;initializing "z"
        mov [x],ax
        mov ax,[yc]
        mov [y],ax
        
        mov bl,0
        mov bx, 0
        test [r],byte 0x02
        je nojul1
            ;julia set for .294 + .03i
            push word [yc]
            mov [xc],word 294*n/1000
            mov [yc],word 30*n/1000
        nojul1:
        xor ax,ax
        iteration_start:
            cmp al,128
            jns iteration_end
            push ax
                ;calc x+iy = (x+iy)²+(xc+iyc)
                    ;first part : x = x²-y²+xc
                    mov ax,[x]
                    sar ax,hlogn
                    mov [x],ax
                    mul ax
                        push ax
                    mov ax,[y]
                    sar ax,hlogn
                    mov [y],ax
                    mul ax
                    mov bx,ax
                        pop ax
                    test [r],byte 0x01
                    je noalt
                        ;mandelbar : x = y²-x²+xc
                        push ax
                        mov ax,bx
                        pop bx
                    noalt:
                    sub ax,bx
                    add ax, [xc]

                    ;second part : y = 2xy+yc
                    push ax
                    mov ax, [x]
                    mov bx,[y]
                    mul bx
                    sal ax,1
                    add ax,[yc]
                    mov [y],ax
                    pop ax
                    mov [x],ax
                ;check escape condition (abs(x)>2 or abs(y)>2)
                mov ax,[x]
                call Iabs
                cmp ax,n2
                jns black_pixel
                mov ax,[y]
                call Iabs
                cmp ax,n2
                jns black_pixel
            pop ax
            inc al
        jmp iteration_start
        iteration_end:
        xor al,al
        push ax
        black_pixel:
        pop ax
        test [r],byte 0x02
        je nojul1_1
            ;restore yc value for next column
            pop word [yc]
        nojul1_1:
        pop cx
        pop dx
        
        ;draw the pixel (color stored in al)
        mov ah, 0x0c
        int 10h
        inc cx
        cmp cx,320
        je endloopy
        jmp starty
    endloopy:
    mov cx,0
    inc dx
    cmp dx,200
    je endloopx
    jmp startx
endloopx:

;setup for next figure
mov al,[r]
inc al
mov [r],al

;wait for keyboard input
mov ah, 0
int 0x16

;shutdown after 2 full turns
test [r], word 0x08 
jne shutdown
cmp al, 27 ;if the key isn't esc, draw again
jne begin

shutdown :
;shutdown system, might not work on all systems
mov ax, 0x5307
mov bx, 1
mov cx, 3
int 0x15

;switch to text mode
mov ah, 0
mov al, 3
int 0x10

;in case shutdown didn't work, print message 
mov si,shutdown_fail
call printstr
;wait for keyboard input
mov ah, 0
int 0x16

;switch back to colored VGA 320x200x256 mode
mov ah, 0
mov al, 0x13
int 0x10

;loop forever in case shutdown fails
jmp begin

Iabs: ;simple absolute value
    test ax,ax
    jns pos
    neg ax
    pos:
    ret


printstr: ;print the null-terminated string at starting at si
    push ax
    push bx
    push si
    mov ah, 0x0e
    xor bl, bl
    printstr_loop:
        lodsb
        cmp al , 0
            je short printstr_endl
        int 0x10
        jmp short printstr_loop
    printstr_endl:
    pop si
    pop bx
    pop ax
    ret

shutdown_fail: db "Shutdown failed, press any key to restart",10,13,0

;zeros only after this point
x: dw 0
y: dw 0
xc:dw 0
yc:dw 0
r: db 0

;add plain text at the end to see the limits of the code
db "<-actual end of code"
times   510 - ($-$$)    db  0
;at bytes 511-512, boot sector identifier
db  0x55,   0xaa
