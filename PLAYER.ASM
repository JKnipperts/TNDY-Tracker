; TND Player Code Version 1.1
; by Jan Knipperts Dec,Jan 20/21
;
; This code plays sound files for the TI SN76496A sound generator chip created with my TNDY tracker.
;
; Main player functions:
;
; TND_Init_Player
; Initialises the TND player and sets all variables.
; ES:00 must point to the song data and CS:IOPort must indicate the port to be used to address the sound chip.
;
; TND_Start
; Starts the playback
;
; TND_Stop
; Stops the playback
;
;
; Usage:
;
; Include this code in your programme. Load a TND song at ES:00 and call TND_Init_Player.
; Now everything is ready to play. TND_Start starts the playback of the song, TND_Stop stops it.
;
; You can read the variables CS:Pos, CS:Pattern, CS:Row , CS:Songlength etc. in your programme to get the status of the player.
;
; If you want to start playback from a certain point within the song, set the variables CS:Pos and CS:Row accordingly after
; calling TND_Init_Player and then call TND_Update_Pattern. Then you can start the song at the desired position with TND_Start.
;
; Have a look at the example files TNDTEST.ASM and TNDPLAY.ASM if something is still unclear.


		locals
		jumps



; ****************************************************************
; This routine initialises the player.
; IN:
;       ES:00   - points to tune in memory
;
; OUT:
;	Carry	- set on error (such as invalid module);
;	All variables used by the player set to inital values
; ****************************************************************

TND_Init_Player:
		mov	cs:modulseg,es
		cmp	word ptr es:[0],'NT'   	;correct file ID?
   		jne	@error
   		cmp	word ptr es:[2],'YD'
   		jne	@error
   		cmp	byte ptr es:[4],2	;correct version?
   		jne	@error


   		mov	al,es:[5]
   		mov  	cs:NumTracks,al
   		mov	al,es:[6]
   		mov  	cs:Songlength,al
   		mov	al,es:[7]
   		mov  	cs:LoopPos,al
   		mov	al,es:[8]
   		mov  	cs:NumPattern,al
   		mov	al,es:[9]
   		mov  	cs:Speed,al
   		mov	cs:SpeedCnt,al
   		mov	al,es:[10]
   		mov  	cs:Tempo,al
   		mov	cs:OldTempo,al		; Save initial tempo


                mov	ax,es:[11]              ;Read size of the song description

                mov	si,13
               	add  	si,ax              	;and skip it

                mov	cs:order_offset,si	;Save offset of order list
                xor	ax,ax
                mov	al,cs:Songlength
                add	si,ax			;And skip it for now

                call	Create_TOT 		;Scan through the module and save start offset of each track

                xor	ax,ax
                mov	cs:pos,al		; Start with position 0 and..


		call	TND_Update_Pattern	; ..prepare pattern data
		jc	@error

		call 	TANDY_Mute_All		; Mute all output on Tandy..
		call	Speaker_off		; and PC Speaker


		push	es
 		mov 	ax,0040h
		mov 	es,ax
		mov 	ax,es:[08h]             ; Get adress of first Parallel port
		pop	es
		mov	dx,cs:IOPort
                cmp 	dx,ax
                jae	@Parallel               ; test if a parallel port should be used

                jmp  	@Success	       	; successfull initialisation

        @Parallel:
        	call	Init_TLPT		; start initalising a TLPT device
                jmp	@Success

  	@error:
   		stc                     	; set carry on error
   		xor	al,al
                mov	cs:initialized,al
   		jmp	@Init_End

	@Success:
		clc				; clear carray if everything is ok
		mov	al,1
                mov	cs:initialized,al

  	@Init_End:
  		ret



;*******************************************************
; GET PACKED TRACK SIZE
;
;IN:   		si = start of track
;		dl = size of one event -1
;
;OUT		ax = Size of packed track
;		si = start of next track
; *******************************************************

Get_PTrack_Size:
                push	cx bx dx

	        xor	dh,dh
	        xor	cx,cx
	        mov	bx,si		;Save start offset

		@TSize_Loop:
		mov	al,es:[si]
		inc	si

           	cmp 	al,0FFh          ;empty event marker?
     		jb 	@@Event 	 ;No? Then handle this as a real event

                mov	al,es:[si]	 ;Get number of empty events
                inc	si
                add	cl,al		 ;add them to counter

                jmp	@@Check_next

		@@Event:
	        add	si,dx            ;Add remaining size of event to offset
	        inc	cl               ;Increase event counter
		jmp	@@Check_next


	        @@Check_next:
	        cmp	cl,64
	        jb	@TSize_Loop

	        mov	ax,si
	        sub	ax,bx             ;AX size of saved track in byte



                pop	dx bx cx

		ret



; *******************************************************
; GET TRACK NUMBER
; Converts Pattern/Track to absolute Track number
;
; IN:
;	AH	- Pattern number
;	AL	- Track number
;
; OUT:
;       AX	- Number of that Track
;	CF	- set if track / pattern is invalid
; *******************************************************

Get_Track_Number:
	        push 	bx cx dx
	        pushf

                mov	dl,cs:NumTracks
		dec	dl

		cmp	al,dl		;Valid track number?
                ja	@GTN_Error

                cmp	ah,cs:NumPattern	;Valid Pattern?
                ja	@GTN_Error

                clc

		xor 	bx,bx
		xor	cx,cx
                mov 	cl,al		;move track number to cl
                shr 	ax,8            ;move pattern number down to al

                mov 	bl,cs:NumTracks

               	mul 	bx		;calc Pattern * Tracks per Pattern
		add 	ax,cx		;add current Track in Pattern to result

		jmp	@GTN_Exit

		@GTN_Error:
		xor	ax,ax
		stc

                @GTN_Exit:
		popf
        	pop 	dx cx bx
	        ret

; *******************************************************
; GET TRACK START
; Returns the start offset of a track
;
; IN:
;	AH	- Pattern number
;	AL	- Track number
;
; OUT:
;       SI	- Offset to the start of that Track
;		  0 on error
;	CF	- Set on error
; *******************************************************

Get_Track_Start:
		push 	dx ax
		clc

                call 	Get_Track_Number
                jc      @GTS_Error

                mov 	dx,2
                mul 	dx          	;Track number * 2 for word offsets

                add	ax,offset cs:TStart
		mov 	si,ax  		;add start offset of array
        	mov	ax,cs:[si]
                mov	si,ax

		jmp	@GTS_Exit

                @GTS_Error:
                xor	ax,ax
                mov	si,ax

		@GTS_Exit:
        	pop 	ax dx
        	ret


; *******************************************************
; GET TRACK OFFSET
; Returns current offset for that track
;
; IN:
;	CL	- Track number
;
; OUT:
;       SI	- Current offset in that Track
;		  0 on error
; *******************************************************

Get_Track_Offset:
        	push 	ax dx

		xor	ax,ax
		mov	al,cl
       	        mov 	dx,2
                mul 	dx          	;Track number * 2 for word offsets
		mov	si,offset cs:COT
		add	si,ax
  	        mov	ax,cs:[si]
  	        mov	si,ax

		pop	dx ax
	        ret





; *******************************************************
; UPDATE TRACK OFFSET
; Saves current offset in that track
;
; IN:
;
;	CL	- Track number
;	SI	- Offset to save for this track
;
; OUT:
;	none
;
; *******************************************************

Update_Track_Offset:
		push 	ax dx di
		xor	ax,ax
		mov	al,cl
       	        mov 	dx,2
                mul 	dx          	;Track number * 2 for word offsets
		mov	di, offset cs:COT
		add	di,ax
	        mov	cs:[di],si
		pop 	di dx ax
		ret



; *******************************************************
; CREATE TRACK OFFSET TABLE
;
;IN:   		SI : Start of pattern data
;
;OUT		Tstart set to track offsets
; *******************************************************


Create_TOT:
		push	ax dx cx di

		mov	cl,cs:NumPattern
                xor	ch,ch

	    	mov 	di,offset cs:TStart

	  @Pcount:

	        push	cx

                mov	cl,cs:NumTracks
                dec	cl
                mov	word ptr cs:[di],si	;Save start of track 0
	       	add	di,2

                mov	dl,2			;consider the two additonal data bytes for voice events


                @tcount:

                call 	Get_PTrack_Size
         	mov	word ptr cs:[di],si
         	add	di,2


               	loop	@tcount

	       	xor	dl,dl                   ;no additonal data for noise
	       	call 	Get_PTrack_Size		;Si points to start of track 0 of the next pattern

		pop 	cx

	loop 	@PCount

		pop	di cx dx ax
                ret




; *******************************************************
; This routine prepares next patterns data for playing
; IN:
;       Actual position of the player in POS variable
;	(All varibales have to be initialised first!)
;
; OUT:
;	PATTERN holds the new pattern number
;	COT points to start offsets of the tracks
;	EMPTY is cleared
;	SI points to start of new pattern data
;	CF set if pattern is invalid
; *******************************************************

TND_Update_Pattern:
		xor	bx,bx
		xor	cx,cx

		mov	bl,cs:pos

		cmp	bl,cs:songlength    ;Check for invalid position
		ja	@PNP_failed


		mov	si,cs:order_offset
		add	si,bx
	        mov	al,es:[si]          ;Get pattern number from order list

	        cmp	al,cs:NumPattern    	; Is the Pattern number valid?
	        ja	@PNP_failed


	        mov	cs:Pattern,al
	        mov	ah,al
        	xor	al,al
         	call	Get_Track_Start		; Now SI points to start of first track



	        mov	cl,cs:NumTracks

	@Update_Offsets:                    	; Set COT (Current offset in track) array to initial values
	       	mov     al,cs:NumTracks
	       	sub	al,cl

	       	call	Get_Track_Start
	       	jc	@PNP_failed

	       	push	cx
	       	mov	cx,ax
	       	call	Update_Track_Offset
	       	pop	cx

	        loop	@Update_Offsets

       	       	xor	ax,ax

	       	lea	di,cs:Empty		; Clear empty event buffer
	       	mov	word ptr CS:[di],ax
		mov	word ptr CS:[di+2],ax
		mov	byte ptr CS:[di+4],al

		mov	cl,cs:row
	       	cmp	cl,0
	       	je	@PNP_exit

	@Skip_rows:			        ; If cs:row is not 0 move forward to the desired row
		xor	al,al
		@Chan_cnt:
	       	call	get_next_event
	       	inc	al
	       	cmp	al,cs:NumTracks
	       	jb	@Chan_cnt

	      	loop	@skip_rows


	        jmp	@PNP_exit

	@PNP_failed:
		stc
                ret

	@PNP_exit:
               	clc
                ret






; *******************************************************
; GET EVENT DATA
; This routine decompresses the packed data of one single
; event
;
; IN:
;	   ES:SI point to current data
;	   CL  = Track
;
; OUT:
;	   Unpacked event data in Variables
;          DL = number of empty events that follow
;	   SI = Offset of next event
; *******************************************************

Get_Event_Data:
		xor	ax,ax
                xor	dx,dx

     	        mov	al,es:[si]      ;get first byte of event
  	     	inc	si		;increase offset

     		cmp 	al,0FFh         ;empty event marker?
     		jb  	@Decrunsh_Event ;No? Then hanlde it as real event

     		mov	al,es:[si]      ;get number of empty events to add in track
     	        inc	si		;increase offset

                dec	al		;sub current event from count
     		mov	dl,al		;save the result in dl
	        jmp	@Return


     	        @Decrunsh_Event:
     	        mov	bl,cs:numtracks	;Get number of tracks in module
     	        dec	bl              ;-1
		cmp	cl,bl           ;is this the last (noise) track?
     	   	je 	@Decrunsh_Noise_Event


     		@Decrunsh_Voice_Event:
      	        mov	bl,al
      	        shr	al,4
      	        lea	di,cs:note
      	        call	Save_Byte     ;Get note


      		mov	al,bl
      		and 	al,0Fh
		lea	di,cs:octave
      	        call	Save_Byte     ;Get octave

      		mov	al,es:[si]
     	        inc	si
      		mov	bl,al
      		shr 	al,4
      		inc	al
      		lea	di,cs:volume
      	        call	Save_Byte     ;Get volume (+1)

      		mov	al,bl
      		and 	al,0Fh
                lea	di,cs:effect
      	        call	Save_Byte     ;Get effect

      		mov	al,es:[si]
     	        inc	si
      		lea	di,cs:parameter
      	        call	Save_Byte     ;Get effects parameter


      		jmp	@Return


     		@Decrunsh_Noise_Event:
     	    	mov	bl,al
      		shr 	al,5
      	        mov	cs:divider,al	;Get frequency divider

        	mov	al,bl
      		and 	al,0Fh
      		lea	di,cs:volume
      	        call	Save_Byte     	;Get volume

      		mov	al,bl
      		test	al,00010000b
      		jnz	.bit_set

      	        xor	al,al	      	;Feedback 0

      		jmp	.save_feedback

      		.bit_set:
      		mov	al,1          	;Feedback 1

      		.save_feedback:
      		mov	cs:feedback,al  ;Get feedback / noise type

     	        @Return:
		ret


; *******************************************************
; GET NEXT EVENT
; Returns next event for the given track
;
; IN:
;	AL	- Track number
; OUT:
;	Variables note,octave,volume,effect,parameter
;	or (divider, feedback, volume for noise) filled
; *******************************************************

Get_next_event:


		push	ax bx cx dx

                mov	cl,al			;save current track in cl
	        mov	dl,cs:NumTracks
		dec	dl
		cmp	cl,dl
                je	@GNE_noise

		xor	ax,ax			;Clear last used events data for this track
		lea	di,cs:note
	        call	Save_Byte
	        lea	di,cs:octave
	        call	Save_Byte
	        lea	di,cs:volume
	        call	Save_Byte
	        lea	di,cs:effect
	        call	Save_Byte
	        lea	di,cs:parameter
	        call	Save_Byte

	        jmp	@GNE_check_empty

		@GNE_noise:
		xor	ax,ax			;Clear last used events data for noise track
	       	mov     cs:divider,al
	       	mov     cs:feedback,al
	       	lea	di,cs:volume
	        call	Save_Byte


                @GNE_check_empty:
		lea	si,cs:Empty        	;Are there still empty events to add?
		call	Get_Byte

	        cmp	al,0
		je	@GNE_next       	;No? Proceed event

		dec	al              	;Yes? Decrease empty event counter...

		lea	di,cs:Empty
		call	Save_Byte       	;save the new value...

                jmp	@GNE_quit       	;and exit


	        @GNE_next:


	       	call	Get_Track_Offset 	;Get current offset in track data
	       	call	Get_Event_Data          ;Decrunsh event
                call	Update_Track_Offset	;Save new offset


                cmp	dl,0			;Empty events following?
	        je	@GNE_quit

		mov	al,dl           	;Set the empty event counter
		lea	di,cs:Empty		;and store new value for this track
		call	Save_Byte


	        @GNE_quit:

		pop	dx cx bx ax

		ret


; *******************************************************
; GET BYTE
; Returns a word from a track buffer
;
; IN:
;	CL	- Track number
;	SI	- Offset of buffer
;
; OUT:
;       AL	- byte from buffer
; *******************************************************

Get_Byte:
		pushf
       		push 	dx cx

	      	mov	dl,cs:NumTracks
		dec	dl
		cmp	cl,dl
                ja	@GB_Error

        	xor	ch,ch
		add 	si,cx  		;add start offset of array

		mov	al,cs:[si]
		inc	si

		jmp	@GB_Exit

		@GB_Error:
		xor	al,al

		@GB_Exit:
		pop	cx dx
		popf
                ret


; *******************************************************
; SAVE BYTE
; Saves current frequency of a channel
;
; IN:
;	CL	- Track number
;	DI	- Offset of buffer
;	AL	- Byte to save
;
; OUT:
;		nothing
; *******************************************************

Save_Byte:
		pushf
       	        push	cx dx ax

       	      	mov	dl,cs:NumTracks
		dec	dl
		cmp	cl,dl
                ja	@SW_Exit	;track number not valid?

                xor	ch,ch
		add 	di,cx		;add start offset of array
                pop	ax

		mov	cs:[di],al

		@SB_Exit:
		pop  	dx cx
		popf
	        ret



; *******************************************************
; GET WORD
; Returns a word from a track buffer
;
; IN:
;	CL	- Track number
;	SI	- Offset of buffer
;
; OUT:
;       AX	- word from buffer
; *******************************************************

Get_Word:
		pushf
       		push 	dx cx

              	mov	dl,cs:NumTracks
		dec	dl
		cmp	cl,dl
                ja	@GW_Error

		mov	al,cl
                xor	ah,ah
	        mov 	dx,2
                mul 	dx          	;mult 2 for words
		add 	si,ax  		;add start offset of array

		mov	ax,cs:[si]
		jmp	@GW_Exit

		@GW_Error:
		xor	ax,ax

		@GW_Exit:
	        pop	cx dx
	        popf
	        ret


; *******************************************************
; SAVE WORD
; Saves current frequency of a channel
;
; IN:
;	CL	- Track number
;	DI	- Offset of buffer
;	AX	- Word to save
;
; OUT:
;		nothing
; *******************************************************

Save_Word:
		pushf
       	        push	cx dx ax

                mov	dl,cs:NumTracks
		dec	dl
		cmp	cl,dl
                ja	@SW_Exit	;track number not valid?

		mov	al,cl
                xor	ah,ah
	        mov 	dx,2
                mul 	dx          	;mult 2 for word offsets
		add 	di,ax		;add start offset of array

                pop	ax

		mov	cs:[di],ax

		@SW_Exit:
		pop	dx cx
		popf
	        ret





 ;in: cl = track
Key_off:
		push	ax bx dx
                push    cx
		mov	al,cs:NumTracks
		cmp	al,5
		je	@Five_tracks_off

		@Tandy_off:
		xor 	ax,ax
		xor 	bx,bx
		xor 	dx,dx

		mov 	al,cl
		mov 	bl,020h
		mul 	bl
		add 	al,09Fh
		mov 	dx,cs:IOPort
		out 	dx,al
		jmp 	@Exit_key_off

                @Speaker_off:
		call	Speaker_off
		jmp 	@Exit_key_off

		@Five_tracks_off:
		cmp	cl,3
		je	@Speaker_off
		cmp     cl,4
		jne	@Tandy_off
		dec	cl
		jmp	@Tandy_off

		@Exit_key_off:
		pop     cx
		xor	ax,ax
	 	lea	di,cs:freq
	 	call	Save_Word
	 	pop	dx bx ax
	 	ret



;in: cl = track, dl = volume, bx = frequency
Play_voice:
		push	ax dx cx

	        mov	al,cs:NumTracks
		cmp	al,5
		je	@Play_five_tracks

		@Play_tandy:
		call	Freq_to_tone
		mov	al,dl
		call	TANDY_voice
		jmp	@PV_Exit

		@Play_five_tracks:
		cmp	cl,3
		je	@Play_Speaker
	        cmp     cl,4
		jne	@Play_tandy
		dec	cl
		jmp	@Play_tandy

         	@Play_Speaker:
		call	Speaker_play	;Play frequency on pc speaker


		@PV_exit:
		pop	cx dx ax
		ret



; *******************************************************
; PLAY EVENT
; Plays the Current event
;
; IN:
;	AL	- Track number
;	Variables set
; *******************************************************
Play_Event:
		push	si ax bx cx dx

        	mov	cl,al			;Move Track to cl
	        mov	bl,cs:NumTracks		;Get number of tracks in bl
               	dec	bl			;-1
               	cmp	cl,bl                   ;Is it the last (noise) track?
               	je	@PE_Play_Noise


               	lea	si,cs:volume		;Get event data
               	call	Get_Byte                ;al = note, ah = octave,  dl = volume
               	mov	dl,al

               	lea	si,cs:octave
               	call	Get_Byte
               	mov	ah,al
               	lea	si,cs:note
               	call	Get_Byte


                cmp	ax,0			;No note/octave?
		je	@PE_no_note

		cmp	dl,0Fh			;Volume 15?
		je	@PE_Key_off


		cmp	al,0Dh			;Key-off?
		je	@PE_Key_off

		cmp	al,0Eh			;FX without new note?
		je	@PE_just_fx

		lea	di,cs:last_note		;Save note/octave for effects
		call	Save_Word

	        call	Note_to_Freq		;Convert note/octave to frequency in Hz (BX = frequency)

	        lea	si,cs:parameter
               	call	Get_Byte
               	mov	ah,al
               	lea	si,cs:effect
               	call	Get_Byte    		;Now al = effect, ah = parameter


                cmp	ax,0			;No effect?
                je	@PE_Play_note

              	call	Handle_pre_note_FX 	;Handle effects that take place BEFORE the note has been played

        	cmp	al,03h  		;Skip playing the note if it belongs to a tone slide
                je	@PE_Skip_note
                cmp	al,05h
                je	@PE_Skip_note

@PE_Play_note:
		push	ax

               	mov	ax,bx			;Save fequency
        	lea	di,cs:freq
        	call	Save_Word

                mov	al,dl
                lea	di,cs:last_volume	;Save volume
                call	Save_byte
	        pop	ax

       		dec	dl			;Correct volume
	        call	Play_voice		;Play current note

@PE_Skip_note:
 	        call	Handle_post_note_FX	;Handle effects
                jmp	@PE_Exit

@PE_Key_off:
		call	Key_off
		jmp	@PE_Exit


@PE_Play_noise:
               	mov     dl,cs:divider
	        cmp     dl,0
               	je      @PE_Exit                ;No new frequency to play

                cmp	dl,5			;Key-off?
		jae	@PE_Key_off

                dec     dl

                lea	si,cs:volume		;Get volume
               	call	Get_Byte

                cmp	al,0Fh			;Volume 15?
		je	@PE_Key_off

                mov	dh,cs:feedback

	        ;al = volume, dl = divider,  dh = feedback
		call    TANDY_Noise
		jmp	@PE_Exit


@PE_no_note:
		cmp	dl,0			;No volume?
		je	@PE_Skip_Note

		lea	si,cs:last_volume	;get last used volume
		call	Get_Byte
		cmp	al,dl                   ;Is there a change?
		je	@PE_Skip_Note

		lea	si,cs:freq
		call	Get_Word
		cmp	ax,0
		je	@PE_Exit

		mov	bx,ax			;BX = last used freq. on this channel

               	jmp	@PE_Play_note		;Play last used freq with new volume and handle effects


@PE_Just_FX:

		lea	si,cs:last_volume	;get last used volume
		call	Get_Byte
		cmp	al,dl                   ;Is there a change?
		je	.PE_FX

		mov	dl,al			;Update volume
		lea	di,cs:last_volume
		call	Save_Byte



		.PE_FX:
		mov	si,cs:freq
		call	Get_Word
		mov	bx,ax			;BX = last used freq. on this channel

		lea	si,cs:parameter
               	call	Get_Byte
               	mov	ah,al
               	lea	si,cs:effect
               	call	Get_Byte    		;AL = effect, AH = parameter

		call	Handle_pre_note_FX	;Init possible new effect
		call	Handle_post_note_FX     ;Handle effects
		jmp	@PE_Exit


@PE_Exit:
		pop	dx cx bx ax si
		ret





; *******************************************************
; Handle pre / post note effects
;
; IN:
;	AL	- Effect
;	AH	- Parameter
;	CL	- Track number
;	BX	- Current frequency
;	DL	- Current volume
;
; *******************************************************


Handle_pre_note_fx:
		push	ax bx cx dx

		cmp	al,00h		;Arpeggio?
                je	@Setup_Arpeggio
                cmp	al,0Ah		;Finetune
                je	@Finetune
                cmp	al,03h
                je	@Setup_ToneSlide

 		xor	ax,ax
 	        lea	di,cs:vsl	;Reset pending volume slide
 	        call	Save_Word

                jmp	@HPrN_fx_exit   ;All other effects take place AFTER the note

                @Finetune:
  		shr	ax,8		;Move ah (parameter) to al
  		cmp	al,80h
  		jb	.HPrN_FT_sub
  		sub	al,80h
  		add	bx,ax
  		jmp     @HPrN_fx_exit

  		.HPrN_FT_sub:
  		sub	bx,ax
                jmp     @HPrN_fx_exit

                @Setup_Toneslide:
                lea	si,cs:note	;Is there a new note to update the ts limit to?
                call	Get_Byte
                cmp	al,0
                je	@HPrN_fx_exit
                cmp	al,14
                je	@HPrN_fx_exit

              	lea 	di,TSlide_Limit	;Save current frequency as new limit
              	mov	ax,bx
              	call	Save_Word
		jmp     @HPrN_fx_exit

		@Setup_Arpeggio:
          	cmp	ah,0 		;It's no arpeggio if the parameter is 0
		je	@HPrN_fx_exit

		xor	bx,bx
		mov	bl,ah
		shr	bl,4		;BL = first part of paramater
		mov	bh,ah
		and	bh,0fh          ;BH = second part of paramater

	        lea	si,cs:Last_note	;Get last played note for the current track
	        call	get_word


	        mov	dx,ax		;Save last played note in dx
              	add	al,bl		;Add parameter 1 to note
		call	.Correct_Octave	;Check octave


	     	lea	di,cs:Arp_n1
		call	Save_Word	;Save it

                mov	ax,dx		;Ax holds last played note again
                add	al,bh		;Add parameter 2 to note
                call	.Correct_Octave	;Check octave

		lea	di,cs:Arp_n2
		call	Save_Word	;Save it

		lea	si,cs:note
		call	Get_byte


		cmp	al,0Eh		;Just update effects?
		je	.Start_new_arp

		lea	di,cs:Arp_cnt 	;Set counter to 1 if there is a regular note to be played
		mov	al,1
		call	Save_Byte
		jmp	@HPrN_fx_exit

		.Start_new_Arp:
		lea	di,cs:Arp_cnt 	;Set counter to 0 if it's just the effect
		xor	al,al
		call	Save_Byte
		jmp	@HPrN_fx_exit


	        .Correct_Octave:
		cmp	al,13
		jb	.CO_exit
		inc	ah
		sub	al,13
		.CO_exit:
		ret

		@HPrN_fx_exit:
                pop	dx cx bx ax
                ret






Handle_post_note_fx:
		push	ax

               	cmp	ax,0
               	je	@HPN_Exit

            	cmp	al,0Fh
                je	@SpeedTempo

                cmp	al,0Bh
                je	@Jump

                cmp	al,0Dh
                je	@Break


                call	Update_FX;

                jmp	@HPN_Exit

	        @SpeedTempo:
                cmp	ah,01Fh
                jb	.Change_Speed

                mov	cs:tempo,ah

               	jmp	@HPN_Exit

                .Change_Speed:
                mov	cs:speed,ah
	       	jmp	@HPN_Exit

	       	@Jump:
	       	cmp	ah,cs:songlength
	       	ja	@HPN_Exit
	       	mov	cs:pos,ah
	       	mov	cs:row,0
	       	mov	cs:restart_row,1

	       	call	TND_Update_Pattern
	       	jmp	@HPN_Exit

	       	@Break:
	       	mov	al,cs:songlength
	       	dec	al

	       	cmp	cs:pos,al
	       	jbe	.Break_pattern

	       	mov	al,cs:looppos

	       	.Break_pattern:
	       	mov	cs:row,ah
	       	mov	cs:pos,al
	       	mov	cs:restart_row,1
	      	call	TND_Update_Pattern


                @HPN_Exit:
                pop	ax
                ret






Do_Arpeggio:
		push	ax dx
		lea	si,cs:Arp_cnt
		call	Get_Byte


                cmp	al,0
                je	@Arp_play_base
                cmp	al,1
                je	@Arp_play_n1
                cmp	al,2
                je	@Arp_play_n2

                jmp	@Arp_exit


                @Arp_play_base:
                inc	al
               	lea	di,cs:Arp_cnt		;increase counter
		call	Save_Byte

	        lea	si,cs:last_note		;get last note/octave
                call	Get_Word

                jmp	@Arp_Play_it

                @Arp_play_n1:
                inc	al
               	lea	di,cs:Arp_cnt		;increase counter
		call	Save_Byte

                lea	si,cs:Arp_n1		;get note/octave for n1
                call	Get_Word

                jmp	@Arp_Play_it

                @Arp_play_n2:
                xor	al,al
               	lea	di,cs:Arp_cnt		;reset counter
		call	Save_Byte

                lea	si,cs:Arp_n2	        ;get note/octave for n2
                call	Get_Word


                jmp	@Arp_Play_it

                @Arp_Play_it:
                call	Note_to_Freq		;Convert not/octacve to frequency (bx)

                lea	si,cs:last_volume		;Get current volume
                call	Get_Byte

                dec	al			;correct volume
                mov	dl,al

                call	Play_Voice		;play it

                @Arp_exit:
                pop	dx ax
		ret




Do_Porta_up:
		push	ax bx dx
		mov	dx,ax

		lea	si,cs:freq		;Get channels frequency
		call	Get_Word
		mov	bx,ax
		mov	ax,dx
		shr	ax,8
		add	bx,ax           ;Add parameter

                mov	ax,bx
		lea	di,cs:freq		;Save new frequency
		call	Save_Word

		lea	si,cs:last_volume	;Get current volume
                call	Get_Byte

		dec	al		;Correct volume
                mov	dl,al

                call	Play_Voice	;play new frequency
                pop	dx bx ax
                ret

Do_Porta_down:
		push	ax bx dx
		mov	dx,ax

		lea	si,cs:freq		;Get channels frequency
		call	Get_Word
		mov	bx,ax
		mov	ax,dx
		shr	ax,8
		sub	bx,ax           ;Sub parameter
		cmp	bx,cs:TandyMin
		jb	@Exit_Porta	;Frequency is to low


                mov	ax,bx
		lea	di,cs:freq		;Save new frequency
		call	Save_Word

	 	lea	si,cs:last_volume	;Get volume
                call	Get_Byte
                dec	al		;Correct volume

                mov	dl,al

                call	Play_Voice		;play it
                @Exit_Porta:
                pop	dx bx ax
                ret


Do_Tone_Slide:
		push	ax bx dx
		shr	ax,8			;Now Ax just holds the parameter
		mov	dx,ax			;Save it in dx

		lea 	si,cs:TSlide_Limit		;Get limit for tone slide
		call	Get_Word
              	mov	bx,ax			;Move it to bx

              	lea 	si,cs:freq         	;Get current frequency
		call	Get_Word
                                                ;AX = current freq, BX = limit
		cmp	ax,bx
		ja	@TS_down

		add	ax,dx
		cmp	ax,bx
		jae	@TS_done
		jmp	@TS_play

		@TS_down:
		sub	ax,dx

		cmp	ax,bx
		ja	@TS_play

		@TS_done:
		mov	ax,bx		;Set the limit as new freq

		@TS_play:
		lea	di,cs:freq		;Save new frequency
		call	Save_Word

        	mov	bx,ax

	 	lea	si,cs:last_volume	;Get volume
                call	Get_Byte
                dec	al		;Correct volume
                mov	dl,al

                call	Play_Voice		;play it

		pop	dx bx ax
		ret


;CF set = just calculate the new volume without playing
 Do_Volume_Slide:
 		push	ax bx
 		pushf
 		lea	si,cs:last_volume
 		call	Get_Byte
 		mov	dl,al

 		mov	bl,ah
 		shr	bl,4
 		mov	bh,ah
 		and	bh,0Fh

 		cmp	bl,0
 		ja	@VS_up

 		;Slide volume down
                shr	bx,8   ;BL = BH
                push	dx
 	        mov	ax,23
 	        mul	bx
 	        mov	bx,ax
 	        pop	dx

 	        lea	si,cs:vsl
 	        call	Get_Word
 	        add	ax,bx

 	        cmp	ax,100
 	        jb	.End_VSlide_dwn
 	        cmp	ax,200
 	        jb	.VS_Add_one
 	        cmp	ax,300
 	        jb	.VS_Add_two

 	        add	dl,3
 	        xor	ax,ax

 	        jmp	.End_VSlide_dwn

 		.VS_Add_one:
 		inc	dl
 	        xor	ax,ax
 		jmp	.End_VSlide_dwn

		.VS_Add_two:
 		add	dl,2
 	        xor	ax,ax

 		jmp	.End_VSlide_dwn


                .End_VSlide_dwn:
 	        cmp	dl,10h
 		jae	@VS_SetMin
		lea	di,vsl
 	        call	Save_Word

 		jmp	@VS_Play



 		;Slide Volume up
 		@VS_up:

 		cmp	dl,01h
 		jbe	.End_VSlide_up

                push	dx
                xor	bh,bh
 		mov	ax,23
 	        mul	bx
 	        mov	bx,ax
 	        pop	dx


 	        lea	si,cs:vsl
 	        call	Get_Word
 	        add	ax,bx

      	        cmp	ax,100
 	        jb	.End_VSlide_up
 	        cmp	ax,200
 	        jb	.VS_sub_one
 	        cmp	ax,300
 	        jb	.VS_sub_two

 	        sub	dl,3
 	        xor	ax,ax
 	        jmp	.End_VSlide_up

 		.VS_sub_one:
 		dec	dl
 	        xor	ax,ax
 		jmp	.End_VSlide_up

		.VS_sub_two:
 		sub	dl,2
 	        xor	ax,ax
 		jmp	.End_VSlide_up


                .End_VSlide_up:
 	       	cmp	dl,10h
 		ja	@VS_SetMax		;Overflow?
		lea	di,vsl
 	        call	Save_Word

 		jmp	@VS_Play


 		@VS_SetMax:
 		mov	dl,01h
 		xor	al,al
 	        lea	di,cs:vsl
 	        call	Save_Byte

 		jmp	@VS_Play

 		@VS_SetMin:
 		mov	dl,10h
 		xor	al,al
 	        lea	di,vsl
 	        call	Save_Byte



 		@VS_Play:

 		mov	al,dl

 		lea	di,cs:last_volume
 		call	Save_Byte

		popf
		jc	@VS_Skip_playing

 		dec	dl		;Correct volume

 		lea	si,cs:freq
 		call	Get_Word
 		mov 	bx,ax
 		call	Play_Voice

 		@VS_Skip_playing:
 		pop	bx ax
 		ret







; *******************************************************
; Update effects
;
; IN:
;	AL	- Effect
;	AH	- Parameter
;	CL	- Track number
;
; *******************************************************


Update_FX:
		cmp	ah,00h    	;No paramter? Then exit
	       	je 	@FX_exit


		cmp	al,00h
		je	@Arpeggio
                cmp	al,01h
                je	@Porta_up
                cmp	al,02h
                je	@Porta_dwn
                cmp	al,03h
                je	@Tslide
                cmp	al,04h
                je	@VSlide
                cmp	al,05h
                je	@TVSlide

                jmp	@FX_Exit


                @Arpeggio:
               	call	Do_Arpeggio
                jmp	@FX_Exit

   		@Porta_up:
   		call	Do_Porta_up
		jmp     @FX_Exit

  		@Porta_dwn:
  		call	Do_Porta_down
                jmp	@FX_Exit

                @TSlide:
                call	Do_Tone_Slide
                jmp	@FX_Exit

                @VSlide:
		call	Do_Volume_Slide
                jmp	@FX_Exit

                @TVSlide:
                stc			;set carry for just calculating the new volume
                call	Do_Volume_slide ;Perform the volume slide (without playing)
                call	Do_Tone_Slide   ;and finaly add a tone slide


		@FX_Exit:
                ret





; *******************************************************
; PLAY ROW
; Plays the current row
; *******************************************************


Play_Row:
		mov	al,cs:row
		xor	cx,cx
        	mov	cl,cs:NumTracks
        	xor	ax,ax
                mov	cs:restart_row,al



        @PR_track_cnt:
                call	get_next_event
	        call	Play_event

                cmp	cs:restart_row,1
                je 	Play_row		       ;Restart for break and jump fx

                inc	al
		cmp	al,cl
      	jb	@PR_track_cnt                          ;If I use loop at this point, on a real Tandy 1000 the keyboard query no longer works. No idea why...

      	@Exit_Play_Row:
   		ret





; *******************************************************
; PLAY MUSIC
; The main player funcion
; Must be called x times per second according to the
; tempo of the song
; *******************************************************

 Play_Music:
 		clc
  		mov	al,cs:speedcnt
  		cmp	al,0
  		ja	@PM_Update_fx

        @PM_Next_Row:
        	mov	al,cs:row
        	call	Play_row

   		mov	al,cs:speed		;Reset speed
   		dec	al
   		mov	cs:speedcnt,al

  		inc	cs:row			;Increase row count

  		cmp	cs:row,64		;End of pattern?
  		jb	@PM_Exit

           	inc	cs:pos			;Increase position

                mov	al,cs:songlength	;Position valid?
                dec     al
                cmp 	cs:pos,al
                jbe	@PM_Next_Pattern

                mov	al,cs:looppos		;Loop?
                mov	cs:pos,al
                jmp	@PM_Next_Pattern

        @PM_Update_fx:
        	dec	cs:speedcnt		;Decrease tick counter

        	xor	cx,cx
        	mov	cl,cs:Numtracks		;Check all tracks
        	dec	cl			;We don't need to check the noise channel
        	xor	ax,ax

        	.PM_Track_Loop:

        	push	ax cx
        	mov	cl,al

		lea	si,cs:parameter
               	call	Get_Byte
               	mov	ah,al
               	lea	si,cs:effect
               	call	Get_Byte    		;Now al = effect, ah = parameter

                call	Update_FX		;Update effects


        	pop	cx ax

		inc	al			;Up to the next channel
		cmp	al,cl
		jb	.PM_Track_Loop

		jmp	@PM_Exit

	@PM_Next_Pattern:
		mov	cs:row,0
        	call 	TND_Update_Pattern	;Load data of next pattern
	@PM_Exit:
		ret


;================================= Sound ===========================================

;in: al = note, ah = octave
;out: bx = frequency of the note in Hz

Note_to_freq:
		push	ax dx cx si
		xor	dx,dx

		mov	cl,al           ;save note
		shr	ax,8		;move octave down to al

		dec	al      	;make octave zero based
		mov	bx,12
		mul	bx
		add	al,cl		;Add note
		dec	al     		;make result zero based

                mov	bx,2            ;mult 2 for word offsets
		mul	bx

		lea	si,cs:FreqTable
		add	si,ax
		mov	bx,cs:[si]
		pop	si cx dx ax
		ret




;in: bx = freq
;out: bx = tone
Freq_to_tone:
		push 	dx ax

		cmp	bx,0
		je	@Exit_freq

		mov	ax,word ptr cs:[tandyDivider]
		mov 	dx,word ptr cs:[tandyDivider+2]
		div 	bx
		mov	bx,ax

		@Exit_freq:
		pop	ax dx
		ret

;in:
;al = data
TANDY_Out:
		mov  	dx,cs:IOPort
		cmp  	cs:parallel,1  	;Use parallel port?
		je  	@Write_LPT

		out	dx,al
		jmp	@Tout_End

		@Write_LPT:
		call	LPT_Send

		@Tout_end:
		ret




;AL = level
;CL = voice
;BX = tone


TANDY_Voice:
		push ax
		mov  al,010h
		shl  al,cl
		and  al,060h
		or   al,080h
		mov  ch,al    		;save channel for volume
		mov  ah,bl
		and  ah,0Fh
		or   al,ah

		call TANDY_Out		;write command byte with first 4 bits of freq.

		mov  cl,4
		shr  bx,cl
		mov  al,bl

                call TANDY_Out 		;write rest of frequency

		pop ax
		and  al,0Fh
		or   al,ch
		or   al,10h

		call TANDY_Out		;write volume byte

		ret

;In: AL = level; DL = Divider; DH = Feedback
TANDY_Noise:
		push	ax
  		xor  	al,al
  		mov  	al,11100000b
  		cmp 	dh,0
  		je  	@SkipFeedback
  		or   	al,4		;Set feedback bit for white noise

  		@SkipFeedback:
  		or   	al,dl		;Add  freq. divider bits
  		call	TANDY_Out	;write noise command byte to port

  		@Noise_Byte2:
  		pop	ax
  		or   	al,11110000b
  		call	TANDY_Out	;write volume byte
  		ret





TANDY_Mute_All:
		push dx ax
  		mov 	al,09Fh 	;Set volume for all channels to 0Fh (off)}
  		call	TANDY_Out
  		mov 	al,0BFh
  		call	TANDY_Out
  		mov 	al,0DFh
  		call	TANDY_Out
  		mov 	al,0FFh
  		call	TANDY_Out
  		pop ax dx
  		ret


;in: al = byte to write to LPT port

LPT_Send:
		push	dx cx
  		mov 	dx,cs:IOPort
  		out 	dx,al               	;Write byte to data port

		add 	dx,2			;Control port
  		mov 	al,0Ch
  		out 	dx,al

		dec 	dx			;Status port
		mov 	cx,18h			;Set counter

  		@@1:
  		in 	al,dx
  		test 	al,40h
  		loopnz 	@@1
  		cmp 	cx,0
  		je  	@Timeout

  		mov 	cx,18h
  		@@2:
  		in 	al,dx
  		test 	al,40h
  		loopz 	@@2

  		@Timeout:
  		inc 	dx			;Control port
  		mov 	al,9
  		out 	dx,al
		pop	cx dx
                ret


Init_TLPT:
		push	ax cx dx
		mov  	dx,cs:IOPort
   		add	dx,2			;Control port
   		xor 	al,al
   		out 	dx,al

   		add	dx,400h			;ECR control port (LPT+402h)
   		in  	al,dx
   		and 	al,3
   		cmp 	al,1        		;Is ECR enabled?
   		jne  	@No_ECR
   		xor 	al,al       		;then disable it
   		out 	dx,al

   		@No_ECR:
  		sub	dx,402h			;Back to normal data port

		mov	al,09Fh			;Mute all voices
  		call	LPT_Send
		mov	al,0BFh
		call	LPT_Send
		mov	al,0DFh
		call	LPT_Send
		mov	al,0FFh
		call	LPT_Send

  		add	dx,2                    ;Control port

   		mov 	al,07h			;Send init sequence for TLPT
   		out 	dx,al

		push	dx
   		mov 	cx,3			;Wait 200ms on faster systems
  		mov 	dx,3392                 ;This function of int 15h is only present on PC AT or better
  		mov 	ah,86h                  ;so we don't have to worry about useless delays on older systems
  		int 	15h
		pop	dx

  		mov 	al,09h
   		out 	dx,al

        	mov 	cx,3			;Wait 200ms again
  		mov 	dx,3392
  		mov 	ah,86h
  		int 	15h

  		mov	cs:parallel,1		;Set marker

		pop	dx cx ax

        	ret





;bx = Frequency to play on speaker

Speaker_play:
		push ax dx
  		mov ax,34ddh
  		mov dx,0012h
  		cmp dx,bx
  		jnc @2
  		div bx
  		mov bx,ax
  		in al,61h
  		test al,3
  		jnz @1
  		or al,3
  		out 61h,al
  		mov al,0b6h
  		out 43h,al
	@1:
  		mov al,bl
  		out 42h,al
  		mov al,bh
  		out 42h,al
	@2:
		pop dx ax
        	ret


Speaker_off:
		push	ax
	  	in 	al,61h
  		and 	al,0fch
  		out 	61h,al
  		pop	ax
  		ret







TND_Start:
 		mov	al,cs:initialized
 		cmp	al,1
 		jne	@Exit_Start

                call 	TANDY_Mute_All		; Mute all output on Tandy
		call	Speaker_off		; Mute PC Speaker
		call	TND_Update_Pattern	; Prepare pattern data

		call	SetInt     		; set up interrupt / start playing
		@Exit_Start:
		ret


TND_Stop:
 		mov	al,cs:initialized
 		cmp	al,1
 		jne	@Exit_Stop
		call	ReSetInt     		; set up interrupt / start playing
		call 	TANDY_Mute_All		; Mute all output on Tandy
		call	Speaker_off		; Mute PC Speaker
		@Exit_Stop:
		ret



; *******************************************************
; The player interrupt.
; *******************************************************

TND_Player_Interrupt:
		push	ax es
		mov	es,cs:modulseg		;ES could have been changed by the host program

		call	Play_Music
		mov	al,cs:OldTempo

		cmp	cs:tempo,al		;Was the tempo changed?
		je	@Call_orig_int		;No? Then check if it is time to call the original timer interrupt

		mov	al,cs:tempo             ;Save new tempo
		mov	cs:oldtempo,al
		xor	ah,ah
		call	SetTimer		;Update	Timer

	@Call_orig_int:
		mov	ax,cs:TimerSteps	; see if we have passed 18.2/s
		add	cs:TimerCnt,ax
		jnc	@Int_Exit		; no? So don't call timer interrupt

		pop	es ax                   ; Restore stack
		jmp	cs:OldInt		; call old interrupt handlers

	@Int_Exit:
		mov	al,20h			; send eoi to interrupt controller
		out	20h,al
		pop	es ax			; Restore stack
		iret




; *******************************************************
; Resets the interrupt timer back to 18.2/sec duty cycle.
; *******************************************************

ResetTimer:	push	ax

		in  	al,21h		; Disable timer
  		or  	al,1
  		out 	21h,al

		mov	al,36h
		out	43h,al
		xor	al,al
		out	40h,al
		out	40h,al

		in   	al,21h          ; Enable timer
 		and  	al,0feh
 		out  	21h,al

		pop	ax
		ret





; *******************************************************
; Sets the interrupt timer duty cycle.
; IN:
;	AX	- number of times per second for INT08.
; *******************************************************

SetTimer:

		mov	bx,ax
		mov	ax,13532	; 1193180 mod 65536
		mov	dx,18		; 1193180 div 65536
		div	bx
		mov	bx,ax

		in  	al,21h		; Disable timer
  		or  	al,1
  		out 	21h,al

		mov	al,36h		; Reprogram timer
		out	43h,al
		mov	al,bl
		out	40h,al
		mov	al,bh
		out	40h,al

		in   	al,21h          ; Enable timer
 		and  	al,0feh
 		out  	21h,al

		mov	cs:TimerSteps,bx	; for keeping 18.2 timer correct
		mov	cs:TimerCnt,0	; counter

		ret




; *******************************************************
; Enables and starts the player interrupt.
; *******************************************************

SetInt:		push	es

		cli

		;mov     ah,35h				;Get adress of old int 1Ch handler
		;mov	al,08h
		;int     21h
		;mov	word ptr cs:OldInt,es		;And save it
		;mov	word ptr cs:OldInt+2,bx

        	;mov     ah,25h				;Now set our own handler
        	;mov	al,1Ch
		;mov     dx,offset cs:PlayerInt
		;push	cs
		;pop	ds
		;int     21h

		xor	ax,ax
		mov	es,ax
		mov	ax,es:[8*4]
		mov	word ptr cs:OldInt,ax
		mov	ax,es:2[8*4]
		mov	word ptr cs:OldInt+2,ax
		mov	word ptr es:[8*4], offset TND_Player_Interrupt
		mov	es:2[8*4],cs


		xor	ah,ah				;And adjust the IRQ's duty cylces
		mov	al,cs:tempo
		call	SetTimer

		sti

		pop	es
		ret



; *******************************************************
; Disables the player interrupt.
; *******************************************************

ResetInt:	push	es

		cli

		xor	ax,ax
		mov	es,ax
		mov	ax,word ptr cs:OldInt
		mov	es:[8*4],ax
		mov	ax,word ptr cs:OldInt+2
		mov	es:2[8*4],ax
                call	ResetTimer
		;mov     ah,25h
		;mov	al,08h
		;mov	ds,word ptr cs:OldInt
		;mov	dx,word ptr cs:OldInt+2
		;int     21h


		sti

		pop	es
		ret





; ********************************************************************
; Data stored with the code (829 Byte)
; ********************************************************************


 	IOPort		dw 0C0h		;default value for I/O port - change if needed
 	TandyDivider	dd 111860
 	TandyMin	dw 110		;110 Hz is the minimum frequency the SN76496A can handle

 	Initialized	db 0            ;marker to signal successfull init of player
 	Parallel	db 0            ;use parallel port marker
 	restart_row	db 0		;Marker for restart playing the row (jump and break effect)


	;note frequencies (A4 = 440 Hz)
	;           	     C     C#    D     D#    E     F     F#    G    G#    A     A#    B    Octave
 	FreqTable	dw   33,   35,   37,   39,   41,   44,   46,   49,   52,   55,   58,   62 ;1
 			dw   65,   69,   73,   78,   82,   87,   92,   98,  104,  110,  117,  123 ;2
  	 		dw  131,  139,  147,  156,  165,  175,  185,  196,  208,  220,  233,  247 ;3
  	 		dw  262,  277,  294,  311,  330,  349,  370,  392,  415,  440,  466,  494 ;4
  	 		dw  523,  554,  587,  622,  659,  698,  740,  784,  831,  880,  932,  988 ;5
 			dw 1047, 1109, 1175, 1245, 1319, 1397, 1480, 1568, 1661, 1760, 1865, 1976 ;6
 			dw 2093, 2217, 2349, 2489, 2637, 2794, 2960, 3136, 3322, 3520, 3729, 3951 ;7
 			dw 4186, 4435, 4699, 4978, 5274, 5588, 5920, 6272, 6645, 7040, 7459, 7902 ;8
 			dw 8372, 8870, 9397, 9956,10548,11175,11840,12544,13290,14080,14917,15804 ;9


 	NumTracks     	db ?
 	Songlength 	db ?
 	Looppos    	db ?
 	NumPattern   	db ?
 	Pattern         db ?
 	Row             db ?
 	Pos             db ?
 	Speed      	db ?
 	Tempo      	db ?
	Order_offset    dw ?

	divider		db ?            ;Noise event
 	feedback	db ?

 	Note		db 4 dup (?)	;Current Event of each channel
 	Octave		db 4 dup (?)
 	Effect		db 4 dup (?)
 	Parameter	db 4 dup (?)

        Volume		db 5 dup (?)    ;Current volume for each channels

	last_volume	db 4 dup (0)    ;To save the last used values for effects
	last_note	dw 4 dup (0)
        freq		dw 4 dup (0)

  	TSlide_Limit	dw 4 dup (0)	;Limit for tone slide
  	Arp_cnt		db 4 dup (0)    ;Counter for arpeggio effect
  	Arp_n1		dw 4 dup (0)  	;first note (low byte = note, high byte = octave)
  	Arp_n2		dw 4 dup (0)  	;second note (low byte = note, high byte = octave)
	VSL		dw 4 dup (0)    ;Volume slide buffer

 	Tstart		dw 300 dup (?)  ;Table with offset for each track
 	COT		dw 5 dup(0)	;current offset in Track
 	Empty		db 5 dup(0)     ;number of empty events

	SpeedCnt	db ?
        OldTempo	db ?
       	OldInt		dd ?
	TimerCnt	dw ?
	TimerSteps	dw ?
	Modulseg	dw ?



