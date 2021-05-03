Data16		segment public use16

 	TitleStr        db 'TND Play-routine demonstration v1.0 - 2020 by Jan Knipperts',10,13,10,13,'$'
 	EmptyLine	db 10,13,'$'
 	Select		db 'Please select the port of your Tandy 3-voice sound device:',10,13,10,13,9
 			db '   0 - Port 0C0h ',10,13,9
 			db '   1 - Port 1E0h ',10,13,9
 			db '   2 - Port 2C0h ',10,13,9
 			db '   3 - Port 2E0h ',10,13,9
 			db '   4 - LPT1 ',10,13,9
 			db ' ESC - To Exit To DOS',10,13,'$'

 	Playing		db 'Playing included tune. Press any key to quit...',10,13,'$'
 	ErrorMSG   	db 'ERROR: An error occurred when loading the included tune!',10,13,'$'

ends





Code16		segment public use16
		assume cs:Code16, ds:Data16


Start:		mov	ax,Data16		; Align DS with out data segment
		mov	ds,ax

		mov	ax,03h			; 80x25 textmode
		int	10h

		mov  	dx,offset TitleStr	; Write title
  		mov	ah,09
  		int	21h

		mov  	dx,offset Select	; Print port selection
  		mov	ah,09
  		int	21h

  		call	Select_Port             ; Call I/O Port selection

		mov  	dx,offset EmptyLine	; Insert empty line
  		mov	ah,09
  		int	21h

            	mov  	dx,offset Playing	; Write message
  		mov	ah,09
  		int	21h

		mov	ax,Music
		mov	es,ax   		; Let es point to our Music-Segment

		call	TND_Init_Player		; Load the tune and initialise the Player
		jc    	@Failed			; Did an error occur?

          	call	TND_Start		; Start Playing

        	xor	ax,ax
        	int	16h

		call	TND_Stop		; Stop Playing

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



Select_Port:
		@Get_User_Entry:
  		xor	ax,ax
        	int	16h

        	cmp	al,27			;ESC pressed?
        	je	@Exit_to_DOS


        	cmp	al,'4'
        	ja	@Get_User_Entry
        	cmp	al,'0'
        	jb	@Get_User_Entry

                cmp     al,'4'
                je	@LPT
                cmp	al,'3'
                je	@2E0
                cmp	al,'2'
                je	@2C0
                cmp	al,'1'
                je	@1E0
                cmp	al,'0'
                je	@0C0

                jmp	@Exit_Port_Selection

                @LPT:
                mov	cs:IOPort,3F8h
		jmp	@Exit_Port_Selection

                @0C0:
                mov	cs:IOPort,0C0h
		jmp	@Exit_Port_Selection

		@1E0:
                mov	cs:IOPort,1E0h
		jmp	@Exit_Port_Selection

		@2C0:
                mov	cs:IOPort,2C0h
		jmp	@Exit_Port_Selection

		@2E0:
                mov	cs:IOPort,0C0h
		jmp	@Exit_Port_Selection

                @Exit_Port_Selection:
                ret


		include		Player.Asm	; Include the TND Player code
ends


Music		segment para public use16	; This segment holds the muisc data
                include Delta.Inc
		ends



Stack16		segment para public use16 stack  ; And we need some stack
		dw	100h dup (?)
		ends

		end	Start


