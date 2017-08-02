;nasm barrel.asm -fbin -obarrel.com
;dosbox ./barrel.com -exit

org 100h
bits 16       

section .text
MAIN :
	   	
	call VIDEOMODE3H     ;set mode 03h
	call INITIALIZEMOUSE  ;initialize mouse
	
WaitForKey:

	call BLACK_SCREEN	
	call TRIGGER	
	call BULLET
	call GUN ;draws a blue box and has a mouse call which checks for button clicked	
	call RANDOM_TARGET_POSITION
	call BULLET_AND_RANDOM_TARGET_COLLISION
	call SCORE
	call PAUSE
	
    mov     ah,1
    int     16h
jz      WaitForKey	
	
     ;text mode
    mov     ax, 0003h
    int     10h     

ret 
;------------------------------------------------------------------------------------------------
GUN:    
	mov byte [mouse_x], 70    

    mov AH, 6          ; scroll up function
	mov al,[mouse_y]         ;y position of mouse 
	shr al, 1
	shr al, 1
	shr al, 1
	mov [mouse_y], al
	mov ch, al
	mov cl, [mouse_x]        ; x at 70 of 80	  
	mov dx, cx      
    add dl,5	   
    mov BH, 10010000b  ; white chars on black background
    mov AL, 0          ; scroll all lines
     int 10H 	 
ret
;------------------------------------------------------------------------------------------------
TRIGGER:
  
	xor edx, edx
	xor ebx, ebx
	mov ax,03h ;get button status
	int 33h
	mov [button], bx	
	mov [mouse_y], dl
      
	cmp dword [bullet_fired], 1
	je   exit_trigger

	cmp dword [button], 0001b
	je firebullet
	jmp exit_trigger
	
firebullet:
	
	mov dword [button], 0
	mov dword [bullet_fired], 1
	mov dword [bullet_x], 73 
    shr dl,1
    shr dl,1
    shr dl,1
	mov [bullet_y], 	dx
	
exit_trigger:
ret
;------------------------------------------------------------------------------------------------	
BULLET:

	cmp dword [bullet_fired], 1
	je bulletfired
	jmp exitbullet
 									;writes a block into memory
bulletfired:

	sub word [bullet_x], 2	;subtract from bullet position
	mov ax, word [bullet_x]
	cmp ax, 7; compare 	
	
jle cancelbullet   
  	      					
	mov CX, [bullet_y];the bullet is drawn here at ( bullet_x, bullet_y)
	mov CH, CL	 
	mov dx, [bullet_x] 
	mov cl, dl
	mov dx, cx      
    add dl, 4
    mov BH, 10110000b  		
    mov AL, 0    
	mov AH, 6  
    int 10H
	jmp exitbullet

cancelbullet:

	mov dword [bullet_fired], 0	
	
exitbullet:
	ret

BULLET_AND_RANDOM_TARGET_COLLISION:

	sub ax, ax
	mov ax, word [bullet_x]
	cmp al, 5          ;if target_y y and bullet_x are equal and bullet_x is less than 10
	jle compare_y_positions
;else     
	jmp exit_bullet_and_random_target_collision
compare_y_positions:
	mov ax, word [bullet_y]
	mov bl, byte [target_y]
	cmp al, bl
	je update_score
	jmp exit_bullet_and_random_target_collision
update_score:
	inc byte [gamescore]
	mov dword [bullet_fired], 0	
exit_bullet_and_random_target_collision:
	ret
;------------------------------------------------------------------------------------------------
RANDOM_TARGET_POSITION:
	xor eax, eax
      ;get time random_y_position passed since last call 
	call GET_RANDOM_Y_POSITION
	mov al, byte [random_y_position]
	mov ah, byte [previous_random_y_position]
	sub al, ah
	cmp al, 5
	jle createtarget
	jmp drawtarget
createtarget:
	call GET_RANDOM_Y_POSITION
	mov al, [random_y_position]
	mov byte [previous_random_y_position],al 
	                   ;This sets the y coordinate and the previous_random_y_position for the instance of the object, almost like OOP.
	mov byte [target_y], al
		
drawtarget:
	   
    mov AH, 6        
    mov cl, 0ah       
	mov ch, [target_y]  ;contains y coordinate of object called the target_y   temp
	mov dl, cl
	add dl, 4
	mov ch, dh
	
    mov BH, 11110000b ; 
    mov AL, 0         ; 
    int 10H		
ret
	
GET_RANDOM_Y_POSITION:;------------------------------------------------------------------------------------------------
	mov ah, 02Ch
	int 21h	
	             ;this generates a random number between 0-25
	cmp dh, 10
	jle skip     ;if random_y_position is less than or equal to ten then skip this step, else get a -n for random value
	shr dh,1     ;this insures that any number 0-59 will be displayable if n/2-5 is at minimum 25, n - random_y_position 
	sub dh,5
 skip:    
    mov [random_y_position],  dh   ;save random_y_position for countdown 
	
ret
;------------------------------------------------------------------------------------------------
SCORE:
;draw score
    
	mov ah, 1h ;make cursor vanish
	mov ch, 20
	int 10h

	; move cursor
	
        mov AH, 2         ; move cursor function
        mov DX, 0000H     ; center of screen
        XOR BH, BH        ; page 0
        int 10H

    ; display character with attribute
        mov AH, 09        ; display character function   
        mov BH, 0         ; page 0
        mov BL, 00001111b  ; blinking cyan char, red back
        mov CX, 1         ; display one character
        mov AL, 'S'       ; character is 'S'
        int 10H

	      ; move cursor
        mov AH, 2         ; move cursor function
        inc dl
        XOR BH, BH        ; page 0
        int 10H

    ; display character with attribute
        mov AH, 09        ; display character function   
        mov BH, 0         ; page 0
        mov BL, 00001111b  ; blinking cyan char, red back
        mov CX, 1         ; display one character
        mov AL, 'C'       ; character is 'C'
        int 10H

	     ; move cursor
        mov AH, 2         ; move cursor function
        inc dl
        XOR BH, BH        ; page 0
        int 10H

    ; display character with attribute
        mov AH, 09        ; display character function   
        mov BH, 0         ; page 0
        mov BL, 00001111b  ; blinking cyan char, red back
        mov CX, 1         ; display one character
        mov AL, 'O'       ; character is 'O'
        int 10H
       
	      ; move cursor
        mov AH, 2         ; move cursor function
        inc dl
        XOR BH, BH        ; page 0
        int 10H

    ; display character with attribute
        mov AH, 09        ; display character function   
        mov BH, 0         ; page 0
        mov BL, 00001111b  ; blinking cyan char, red back
        mov CX, 1         ; display one character
        mov AL, 'R'       ; character is 'R'
        int 10H

	    ; move cursor
        mov AH, 2         ; move cursor function
        inc dl
        XOR BH, BH        ; page 0
        int 10H

    ; display character with attribute
        mov AH, 09        ; display character function   
        mov BH, 0         ; page 0
        mov BL, 00001111b  ; blinking cyan char, red back
        mov CX, 1         ; display one character
        mov AL, 'E'       ; character is 'E'
        int 10H	
	
		    ; move cursor
        mov AH, 2         ; move cursor function
        mov dl, 7
        XOR BH, BH        ; page 0
        int 10H

	 ; display character with attribute
        mov AH, 09        ; display character function   
        mov BH, 0         ; page 0
        mov BL, 00001111b  ; blinking cyan char, red back
        mov CX, 1         ; display one character
	  ;cmp byte [gamescore], 9
	  ;je resetscore
	  ;jmp nextcore
;resetscore:
	  ;mov byte [gamescore],0
	 ; inc byte [lives]
;nextcore:		
	  ;add byte [gamescore],48
        mov AL, '1';byte [gamescore]       ; 
        int 10H
	;sub byte [gamescore], 48
	;mov al,[gamescore]
        ;call putdec

exitscore:   
ret
PAUSE:			
		
	xor ax, ax              ; bios get time 
	int 1ah      			; 
	mov ax, word [ticks]	;                       
	add dx, ax              ; low byte 
	mov word [outtime], dx  ; save low 
	xor ax, ax              ; 
	adc ax, cx              ; high byte         
	mov word [outtime + 2], ax     ; save high 
	
not_yet:            
 
	xor ax, ax              ; bios get time 
	int 1ah                 ;  
	cmp al, 0               ; has midnight passed 
	jne midnight            ; yup? reset outtime 
	cmp cx, word [outtime + 2]     ; if current hi < outtime hi 
	jb  not_yet             ; then don't timeout 
	cmp dx, word [outtime]         ; if current hi < outtime hi... 
							; AND current low < outtime low 
	jb not_yet              ; then don't timeout 
	jmp its_time            ; 
	
midnight:                   
     
	sub word [outtime], 00B0h      ; since there are 1800B0h ticks a day 
	sbb word [outtime + 2], 0018h  ; outtime = 1800B0h - outtime 
	jmp not_yet             ; 
	
its_time:  		
ret
;------------------------------------------------------------------------------------------------
BLACK_SCREEN:

	 ; clear window to black    
    mov AH, 6         
    mov CX, 0000     
    mov DX, 8025   
    mov BH, 00000000b 
    mov AL, 0         
    int 10H	
ret
;------------------------------------------------------------------------------------------------
INITIALIZEMOUSE:
	mov ax,00h ;initialize the mouse
	int 33h	
	mov ax,04h ; set pointer to 0,0
	mov bx,0
	mov cx, 0
	int 33h	
ret
;------------------------------------------------------------------------------------------------
VIDEOMODE3H:
    xor eax, eax 
	mov ah, 0
	mov al, 3h	; 80x25
	int 10h	
ret
;------------------------------------------------------------------------------------------------
section .data
             
    active:         db       0
	button:         dw       0	
	color:	        db       0
	COUNT:          dw       0
	eight:	        db       8
	;horizonal_length:         db       80  	
	excode:         db       0
	bullet_fired:	        dw       0
	gamescore:      db       0
	lives:          db       1	
	n:	            dw       0
	outtime:        times    2  dw    0   
	bullet_x:      dw       73
	bullet_y:      dw       0
    random_y_position:        db       0	
	target_y:         resb     0
	temp:	        db       0
	temprandom:     dw       0
	previous_random_y_position:      db       0
	ticks			dw		 2
	mouse_x:	            db       0 ;
	mouse_y:	            db       0
	;YCOOR:	        dw       0
