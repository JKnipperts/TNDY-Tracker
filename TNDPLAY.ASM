Data16		segment public use16

 	TitleStr        db 'Tiny TND Player v1.01 - 2021 by Jan Knipperts',10,13,10,13,'$'
 	Select		db 'Please select the port of your Tandy 3-voice sound device:',10,13,10,13,9
 			db '   0 - Port 0C0h ',10,13,9
 			db '   1 - Port 0E0h ',10,13,9
 			db '   2 - Port 1C0h ',10,13,9
 			db '   3 - Port 1E0h ',10,13,9
 			db '   4 - Port 2C0h ',10,13,9
 			db '   5 - Port 2E0h ',10,13,9
 			db '   6 - LPT1 ',10,13,9
 			db '   7 - LPT2 ',10,13,9
 			db ' ESC - To Exit To DOS',10,13,'$'

 	IOMsg		db 'Using TI SN76496A compatible sound device at port: ','$'

	PlayMSG		db 'Playing ','$'
 	KeyMSG		db 'Press any key to quit...',10,13,'$'
 	ErrorMSG   	db 'ERROR: Failed to load the TNDY module!',10,13,'$'

 	LoadMSG		db 'Loading '
 	FileName   	db 14 dup(0)
 	EmptyLine	db 10,13,'$'

 	NoFileMSG	db 'Please enter the file to be played as a parameter.',10,13,9
 			db 'Example: TNDPLAY.EXE TUNE.TND ',10,13,'$'

ends





Code16		segment public use16
		assume cs:Code16, ds:Data16


Start:		mov	ax,Data16		; Align DS with out data segment
		mov	ds,ax

		call	Get_Filename

		mov	al,byte ptr DS:[filename]
		cmp	al,0
		je	@No_Parameter

		mov  	dx,offset LoadMSG	; Write Loading message
  		mov	ah,09
  		int	21h

        	mov	ax,Music
		mov	es,ax   		; Let es point to our Music-Segment

  		call  	ReadFile        	; Read file to buffer
  		jc    	@Failed

		mov	ax,03h			; 80x25 textmode
		int	10h
		mov  	dx,offset TitleStr	; Write title
  		mov	ah,09
  		int	21h

  		call	Select_Port             ; Call I/O Port selection

		mov	ax,03h			; 80x25 textmode
		int	10h
		mov  	dx,offset TitleStr	; Write title
  		mov	ah,09
  		int	21h

		mov  	dx,offset EmptyLine	; Insert empty line
  		mov	ah,09
  		int	21h

        	mov  	dx,offset IOMSG		; Write message
  		mov	ah,09
  		int	21h
  		mov	ax,cs:IOPort
  		call	printhexw
  		mov  	dx,offset EmptyLine	; Insert empty line
  		mov	ah,09
  		int	21h

            	mov  	dx,offset PlayMSG	; Write message
  		mov	ah,09
  		int	21h
  		mov  	dx,offset Filename	; Write message
  		mov	ah,09
  		int	21h

  		mov  	dx,offset KeyMSG	; Write message
  		mov	ah,09
  		int	21h


		mov	ax,Music
		mov	es,ax   		; Let es point to our Music-Segment

		call	TND_Init_Player		; Load the tune and initialise the Player
		jc    	@Failed			; Did an error occur?

          	call	TND_Start		; Start Playing


          	xor	ah,ah			; Wait for keypress
          	int	16h

		call	TND_Stop		; Stop Playing

		jmp	@Exit_to_DOS		;Quit






		@No_Parameter:
		mov  	dx,offset NoFileMSG	; Write error message
  		mov	ah,09
  		int	21h

		@Exit_to_DOS:
		mov	ah,4Ch			; Return to DOS
		xor	al,al                   ; with exit code 0
		int	21h


		@Failed:
		mov  	dx,offset ErrorMSG	;Write error message
  		mov	ah,09
  		int	21h
  		mov 	ah,4Ch          	;Quit to DOS
  		mov     al,1			;with exit code 1
  		int 	21h



Get_Filename:
		mov     bx,82h			;Get file name from command line
		lea     di,FileName

	@Get_fname:
		mov     cl,es:[bx]
		cmp     cl,0Dh
		jz      @fname_end
		cmp     cl,20h
		jz      @fname_end
		or      cl,cl
		jz      @fname_end
		mov     ds:[di],cl
		inc     di
		inc     bx
		cmp     bx,82h+12
		jb      @Get_fname
	@fname_end:
		ret



; *******************************************************
; READFILE
; This routine reads the data from disk and stores it
; in a buffer at ES:00
;
; IN:
;	ES = Segment to load the file to
; OUT:
;	cf set on error
; *******************************************************


ReadFile:
		clc
  		mov 	ax,3D00h        ; ah = 3Dh, al = 0 (access mode: 0 = just read))
  		mov 	dx,offset FileName
  		xor     cl,cl
  		int 	21h
  		jc    	@FileError
  		mov	bx,ax		;Move file handle to bx

  		mov     ax,4202h        ; ah = 42h, al = 2 (END + cx:dx offset)
  		xor     cx,cx
  		xor     dx,dx           ; cx:dx = 0
  		int     21h             ; set the file pointer to end of file, returns position (file size) in dx:ax
  		jc    	@FileError      ; something went wrong

		cmp   	dx,0		; dx:ax contains the file size - check it
  		ja    	@FileError      ; file is to big ( > 64 KB)
  		push	ax	   	; save lower part of file size

  		mov     ax,4200h        ; ah = 42h, al = 0 (Start + cx:dx offset)
  		xor     cx,cx
  		xor     dx,dx           ; cx:dx = 0
  		int     21h             ; set the file pointer to start of file
  		jc    	@FileError      ; something went wrong

		pop	cx		; Restore file size to cx
        	push	ds
        	mov     ax,3F00h	; Now read the file
		xor     dx,dx		; Offset 0
		push	es
		pop	ds
		int     21h
		pop	ds
		jc    	@FileError      ; something went wrong

               	mov   	ax,3E00h        ; ah = 3E (close file)
  		int   	21h

  		jmp   	@Read_End

  	@FileError:
  		mov   	ax,3E00h        ; ah = 3E (close file)
  		int   	21h
  		stc
  	@Read_End:
  	 	ret





; *******************************************************
; Select Port
;
; Lets the user select the I/O port for the Tandy 3-voice
; *******************************************************


Select_Port:
		mov  	dx,offset Select	; Print port selection screen
  		mov	ah,09
  		int	21h


		@Get_User_Entry:
  		xor	ax,ax
        	int	16h

        	cmp	al,27			;ESC pressed?
        	je	@Abort


        	cmp	al,'7'
        	ja	@Get_User_Entry
        	cmp	al,'0'
        	jb	@Get_User_Entry

        	cmp     al,'7'
                je	@LPT2
		cmp     al,'6'
                je	@LPT1
		cmp     al,'5'
                je	@2E0
                cmp     al,'4'
                je	@2C0
                cmp	al,'3'
                je	@1E0
                cmp	al,'2'
                je	@1C0
                cmp	al,'1'
                je	@0E0
                cmp	al,'0'
                je	@0C0

                jmp	@Exit_Port_Selection

		@Abort:
		mov	ah,4Ch			; Return to DOS
		xor	al,al                   ; with exit code 0
		int	21h

                @0C0:
                mov	cs:IOPort,0C0h
		jmp	@Exit_Port_Selection

		@0E0:
                mov	cs:IOPort,0E0h
		jmp	@Exit_Port_Selection

		@1C0:
                mov	cs:IOPort,1C0h
		jmp	@Exit_Port_Selection

		@1E0:
                mov	cs:IOPort,1E0h
		jmp	@Exit_Port_Selection

		@2C0:
                mov	cs:IOPort,2C0h
		jmp	@Exit_Port_Selection

		@2E0:
                mov	cs:IOPort,2E0h
		jmp	@Exit_Port_Selection

		@LPT1:
                push	es
                mov 	ax,0040h
		mov 	es,ax
		mov 	ax,es:[08h]
		mov	cs:IOPort,ax
		pop	es

		cmp	ax,0           		;If this port is invalid - ask again
		jne	@Exit_Port_Selection

               	jmp	@Get_User_Entry

		@LPT2:
	        push	es
                mov 	ax,0040h
		mov 	es,ax
		mov 	ax,es:[0Ah]
		mov	cs:IOPort,ax
		pop	es

		cmp	ax,0
		jne	@Exit_Port_Selection	;If this port is invalid - ask again

	        jmp	@Get_User_Entry

                @Exit_Port_Selection:
                ret







; *******************************************************
; Print hex
;
; Functions to print hex numbers
; *******************************************************


printhexw:
		push ax
		mov  al,ah
		call printhexb
		pop  ax
		call printhexb
		ret



printhexb:
    		push ax
    		shr al, 04h
    		call print_nibble
    		pop ax
    		and al, 0Fh
    		call print_nibble
    		ret

print_nibble:
    		cmp al, 09h
    		jg .letter
    		add al, 30h
    		mov ah, 0Eh
    		int 10h
    		ret
		.letter:
    		add al, 37h
    		mov ah, 0Eh
    		int 10h
    		ret


		include		Player.Asm	; Include the TND Player code

ends


Music		segment para public use16	; This segment holds the muisc data
		db	0FFFFh dup (?)
		ends



Stack16		segment para public use16 stack  ; And we need some stack
		dw	100h dup (?)
		ends

		end	Start


