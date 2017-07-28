org 00h
bits 16       

section .data
             
    active:         db       0
	BUTTON:         dw       0
	clok:           db       02Ch
	color:	        db       0
	COUNT:          dw       0
	eight:	        db       8
	EIGHTY:         db       80  	
	excode:         db       0
	fired:	        dw       0
	gamescore:      db       0
	lives:          db       1	
	n:	            dw       0
	outtime:        times    2  dw    0   
	positionX:      dw       49h 
	positionY:      dw       0
    seconds:        db       0	
	target:         resb     0
	temp:	        db       0
	temprandom:     dw       0
	timestamp:      db       0
	x:	            db       0 ;x coordinate of plane is initialized to 315	
	y:	            db       0
	YCOOR:	        dw       0
	 
section .text
MAIN :

WaitForKeyMAIN:
	
	xor eax, eax    
	;mov [gamescore], 0
	call VIDEOMODE3H     ;set mode 03h
	call ERASEPLANE       ;eraseplane is called to clear memory with black
	call INITIALIZEMOUSE  ;initialize mouse
WaitForKey:
	call ERASEPLANE
	call DRAWPLANE ;draws a blue box and has a mouse call which checks for BUTTON clicked	
	call randomobject
	call bulletrandomobject
	mov ax, 2
	call PAUSE
    mov     ah,1
    int     16h
jz      WaitForKey	
	
    call ERASEPLANE
  	mov     ah,1
    int     16h
    jz      WaitForKeyMAIN

	MOV AX, 4C00H
	INT 21H
ret 

PAUSE:
	push ax                 ; ax = # ticks to delay 
	xor ax, ax              ; bios get time 
	int 1ah                 ;  
	pop ax                  ; 
	add dx, ax              ; low byte 
	mov [outtime], dx         ; save low 
	xor ax, ax              ; 
	adc ax, cx              ; high byte         
	mov [outtime + 2], ax     ; save high 	
not_yet:             
	xor ax, ax              ; bios get time 
	int 1ah                 ;  
	cmp al, 0               ; has midnight passed 
	jne midnight            ; yup? reset outtime 
	cmp cx, outtime + 2     ; if current hi < outtime hi 
	jb  not_yet             ; then don't timeout 
	cmp dx, outtime         ; if current hi < outtime hi... 
							; AND current low < outtime low 
	jb not_yet              ; then don't timeout 
	jmp its_time            ; 	
midnight:                        
	sub dword [outtime], 00B0h      ; since there are 1800B0h ticks a day 
	sbb dword [outtime + 2], 0018h  ; outtime = 1800B0h - outtime 
	jmp not_yet               ; 	
its_time:                   
ret

mouse:
  
	sub dx, dx
	sub bx, bx
	mov ax,03h ;get BUTTON status
	int 33h
	mov [BUTTON],bx	
	mov [y],dl
      
	cmp dword [fired],1
	je   exitmouse

	cmp dword [BUTTON], 0001b
	je firebullet
	jmp exitmouse
	
firebullet:
	mov dword [fired], 1
	mov dword [positionX], 49h 
      shr dl,1
      shr dl,1
      shr dl,1
	mov [positionY], 	dx
exitmouse:
ret
	
INITIALIZEMOUSE:;------------------------------------------------------------------------------------------------
	mov ax,00h ;initialize the mouse
	int 33h
	
	mov ax,04h ; set pointer to 0,0
	mov bx,0
	mov cx, 0
	int 33h	
ret

VIDEOMODE3H:;------------------------------------------------------------------------------------
	mov ah, 0
	mov al, 3h	; 80x25
	int 10h	
ret

DRAWPLANE :;------------------------------------------------------------------------------------
    call score
	call mouse	
	call bullet
	mov byte [x], 46h     
;drawplane
    MOV AH, 6          ; scroll up function
	mov al,[y]         ;y position of mouse 
	shr al, 1
	shr al, 1
	shr al, 1
	mov [y],al
	mov ch, al
	MOV cl, [x]        ; x at 70 of 80	  
	mov dx, cx      
    add dl,5	   
    MOV BH, 10010000b  ;0000111b  ; white chars on black background
    MOV AL, 0          ; scroll all lines
     INT 10H 
ret

ERASEPLANE:

	 ; clear window to black
    ;
    MOV AH, 6         
    MOV CX, 0000     
    MOV DX, 8025   
    MOV BH, 00000000b 
    MOV AL, 0         
    INT 10H	
ret

bullet:;------------------------------------------------------------------------------------------------
	cmp dword [fired],1
	je bulletfired
	jmp exitbullet
 									;writes a block into memory
bulletfired:

	sub dword [positionX], 2	
	cmp dword [positionX], 4
	jle cancelbullet
   
  	  MOV AH, 6        					
	  MOV CX, [positionY]
	  mov CH, CL
	 
	  MOV dx, [positionX] 
	  mov cl, dl
	  mov dx, cx      
        add dl, 4
        MOV BH, 10110000b  					
        MOV AL, 0        					
        INT 10H
	jmp exitbullet


cancelbullet:
	mov dword [fired], 0
	mov dword [positionX], 49h  
	
exitbullet:

	ret

bulletrandomobject:
	sub ax, ax

	mov ax, [positionX]
	cmp al, 11          ;if target y and positionX are equal and positionX is less than 10
	jle score1
;else     
	jmp exitbulletrandomobject
	score1:
	mov ax, [positionY]
	mov bl, [target]
	cmp al, bl
	je score2
	jmp exitbulletrandomobject
score2:
	inc byte [gamescore]
	mov dword [fired], 0
	mov dword [positionX], 49h 

exitbulletrandomobject:
	ret

randomobject:;------------------------------------------------------------------------------------------------
	sub ax,ax
      ;get time seconds passed since last call 
	call gettime
	mov al, byte [seconds]
	mov ah, byte [timestamp]
	sub al, ah
	cmp al, 5
	jle createtarget
	jmp drawtarget
createtarget:
	call gettime
	mov al, [seconds]
	mov byte [timestamp],al 
	                   ;This sets the y coordinate and the timestamp for the instance of the object, almost like OOP.
	mov byte [target], al
		
drawtarget:
	   
        MOV AH, 6        
        MOV cl, 0ah       
	  mov ch, [target]  ;contains y coordinate of object called the target   temp
	  mov dl,cl
	  add dl,4
	  mov ch,dh
	
        MOV BH, 11110000b ; 
        MOV AL, 0         ; 
        INT 10H		
ret
	
gettime:;------------------------------------------------------------------------------------------------
	mov ah,[clok]
	int 21h
	mov [seconds], dh   ;save seconds for countdown
	             ;this generates a random number between 0-25
	cmp dh,10
	jle skip     ;if seconds is less than or equal to ten then skip this step, else get a -n for random value
	shr dh,1     ;this insures that any number 0-59 will be displayable if n/2-5 is at minimum 25, n - seconds 
	sub dh,5
 skip:     
ret

score:;------------------------------------------------------------------------------------------------
;draw score
    
	mov ah, 1h ;make cursor vanish
	mov ch, 20
	int 10h


	; move cursor
	
        MOV AH, 2         ; move cursor function
        MOV DX, 0000H     ; center of screen
        XOR BH, BH        ; page 0
        INT 10H

    ; display character with attribute
        MOV AH, 09        ; display character function   
        MOV BH, 0         ; page 0
        MOV BL, 00001111b  ; blinking cyan char, red back
        MOV CX, 1         ; display one character
        MOV AL, 'S'       ; character is 'S'
        INT 10H

	      ; move cursor
        MOV AH, 2         ; move cursor function
        inc dl
        XOR BH, BH        ; page 0
        INT 10H

    ; display character with attribute
        MOV AH, 09        ; display character function   
        MOV BH, 0         ; page 0
        MOV BL, 00001111b  ; blinking cyan char, red back
        MOV CX, 1         ; display one character
        MOV AL, 'C'       ; character is 'C'
        INT 10H

	     ; move cursor
        MOV AH, 2         ; move cursor function
        inc dl
        XOR BH, BH        ; page 0
        INT 10H

    ; display character with attribute
        MOV AH, 09        ; display character function   
        MOV BH, 0         ; page 0
        MOV BL, 00001111b  ; blinking cyan char, red back
        MOV CX, 1         ; display one character
        MOV AL, 'O'       ; character is 'O'
        INT 10H
       
	      ; move cursor
        MOV AH, 2         ; move cursor function
        inc dl
        XOR BH, BH        ; page 0
        INT 10H

    ; display character with attribute
        MOV AH, 09        ; display character function   
        MOV BH, 0         ; page 0
        MOV BL, 00001111b  ; blinking cyan char, red back
        MOV CX, 1         ; display one character
        MOV AL, 'R'       ; character is 'R'
        INT 10H

	    ; move cursor
        MOV AH, 2         ; move cursor function
        inc dl
        XOR BH, BH        ; page 0
        INT 10H

    ; display character with attribute
        MOV AH, 09        ; display character function   
        MOV BH, 0         ; page 0
        MOV BL, 00001111b  ; blinking cyan char, red back
        MOV CX, 1         ; display one character
        MOV AL, 'E'       ; character is 'E'
        INT 10H
	
	
		    ; move cursor
        MOV AH, 2         ; move cursor function
        mov dl, 7
        XOR BH, BH        ; page 0
        INT 10H


	 ; display character with attribute
        MOV AH, 09        ; display character function   
        MOV BH, 0         ; page 0
        MOV BL, 00001111b  ; blinking cyan char, red back
        MOV CX, 1         ; display one character
	  cmp byte [gamescore], 9
	  je resetscore
	  jmp nextcore
resetscore:
	  mov byte [gamescore],0
	  inc byte [lives]
nextcore:		
	  add byte [gamescore],48
        MOV AL, byte [gamescore]       ; 
        INT 10H
	sub byte [gamescore], 48
	;mov al,[gamescore]
        ;call putdec

exitscore:   
ret

