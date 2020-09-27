{$G-,N-,E-}

{**************************************************************
 TNDY.PAS
 Unit to interfere with TLPT nd TNDY Tandy-3-voice sound devices
 Version 1.11 -TNDY - 20.09.2020 by Jan Knipperts
 - Modified version for TNDY-Tracker -

 Author: Jan Knipperts
 Program: TNDY-Tracker

***************************************************************
}


{Added compiler directives for compiling TNDY Tracker}

Unit TNDY;
interface

var
     tandyport    : word;
     data,
     status,
     ctrl         : word;
     LPT          : Boolean;
     volume       : array[0..3] of byte;
     freq         : array[0..3] of word;

const
    tandyFreq      = 3579545;
    tandyDivider   = tandyFreq/32;
    tandyIntDivider= round(tandyDivider);
    minfreq        = 110;   {A2}
    maxfreq        = 14080; {A9}


Function  TLPT_Init(LPTnum : byte) : Boolean;
Procedure TLPT_Sound(voice:byte; tone:word; level:byte);
Procedure TLPT_Noise(divider, feedback, level:byte);
Procedure TLPT_Mute;

Procedure TNDY_Sound(voice:byte; frequency :word; level:byte);
Procedure TNDY_Noise(divider, feedback, level:byte);
Procedure TNDY_Mute;

Procedure TANDY_Init;
Procedure TANDY_PlaySound(voice:byte; tone:word; level:byte);
Procedure TANDY_Noise(divider, feedback, level:byte);
Procedure TANDY_MuteVoice(voice : byte);
Procedure TANDY_Mute_all;

implementation

Procedure XDelay(ms:word);
assembler;
asm
  mov ax,1000
  mul ms
  mov cx,dx
  mov dx,ax
  mov ah,86h
  int 15h
end;



Procedure LPT_Send(b : byte);
assembler;
 asm
  mov al,b
  mov dx,data
  out dx,al

  mov al,12
  mov dx,ctrl
  out dx,al

  mov dx,status
  mov cx,$18

  @@1:
  in al,dx
  test al,$40
  loopnz @@1

  inc cx

  @@2:
  in al,dx
  test al,$40
  loopnz @@2

  mov dx,ctrl
  mov al,9
  out dx,al
end;

procedure TLPT_Sound(voice:byte; tone:word; level:byte);
begin
  if tone > 0 then tone := tandyIntDivider div tone;
  LPT_Send($80 or (voice*$20) or (tone and $0F));
  LPT_Send(tone shr 4);
  LPT_Send($90 or (voice*$20) or (level and $0F));
end;

procedure TLPT_Noise(divider, feedback, level:byte);
var noisebyte : byte;
begin
  asm
    xor  al,al
    mov  al,11100000b
    mov  noisebyte,al
   end;

   if feedback > 0 then noisebyte := noisebyte or 4;
   noisebyte := noisebyte or divider;
   LPT_Send(noisebyte);

   asm
    xor  al,al
    mov  al,11110000b
    or   al,level
    mov  noisebyte,al
   end;
   LPT_Send(noisebyte);
end;


Procedure TLPT_Mute;
begin
 LPT_Send($9F);
 LPT_Send($BF);
 LPT_Send($DF);
 LPT_Send($FF);
end;

Procedure TNDY_Mute;
assembler;
 asm
  mov dx,TandyPort
  mov al,$9F
  out dx,al
  mov al,$BF
  out dx,al
  mov al,$DF
  out dx,al
  mov al,$FF
  out dx,al
 end;



Function TLPT_Init(LPTnum : byte) : Boolean;
begin
 tandyport := LPTnum;
 data := memw[$40:6+LPTnum*2];

 if data = 0 then
 begin
  lpt := false;
  status := 0;
  ctrl := 0;
 end
 else
 begin
  lpt := true;
  status := data + 1;
  ctrl := data + 2;

  asm                      {Unlock new version o LPT plug}
  mov dx,ctrl
  mov al,$E5
  out dx,al
  end;
  xdelay(150);             {wait least 150 ms}
 end;

 TLPT_Init := lpt;
end;

procedure TNDY_Sound(voice:byte; frequency :word; level:byte);
var tone : word;
begin
   if frequency > 0 then
   begin
      tone := tandyIntDivider div frequency;
      asm
	mov  dx,TandyPort
	mov  cl,voice
	mov  al,$10
	shl  al,cl
	and  al,$60
	or   al,$80
	mov  ch,al { save channel for level set }
	mov  bx,tone
	mov  ah,bl
	and  ah,$0F
	or   al,ah
	out  dx,al
	mov  cl,4
	shr  bx,cl
	mov  al,bl
	out  dx,al
	mov  al,level
	and  al,$0F
	or   al,ch
	or   al,$10
	out  dx,al
       end;
   end;
end;

procedure TNDY_Noise(divider, feedback, level:byte); assembler;
asm
        mov  ax,bx

        mov  dx,TandyPort
        xor  al,al
        mov  al,11100000b
        cmp feedback,0
        je  @SkipFeedback
        or   al,4

        @SkipFeedback:
        or   al,divider
        out  dx,al


        xor  al,al
        mov  al,11110000b
        or   al,level
	out  dx,al
end;

Procedure TANDY_PlaySound(voice:byte; tone:word; level:byte);
begin
  if tone > minfreq then
  begin
   if tone > maxfreq then tone := maxfreq;
   if level > 15 then level := 15;
   if voice > 2 then voice := 2;

   if lpt then
    TLPT_Sound(voice,tone,level)
   else
    TNDY_Sound(voice,tone,level);

   freq[voice] := tone;
  end;
end;

Procedure TANDY_Noise(divider, feedback, level:byte);
begin
  if lpt then
  begin
   TLPT_Noise(divider, feedback, level);
  end
  else
  begin
   TNDY_Noise(divider, feedback, level);
  end;
end;



Procedure TANDY_Mute_all;
begin
 if lpt then
 begin
   TLPT_Mute;
 end
 else
 begin
   TNDY_Mute;
 end;
 fillchar(freq,sizeof(freq),0);
 fillchar(volume,sizeof(volume),15);
end;

Procedure TANDY_MuteVoice(voice : byte);
begin

 if not LPT then
  port[Tandyport] := $9F + (voice * $20)
 else
  LPT_Send($9F + (voice * $20));

 freq[voice] := 0;
 volume[voice] := 15;
end;



Procedure TANDY_Init;      {Reset the sound chip}
begin
  if lpt then
  begin
    LPT_Send(1);
    xdelay(10);
    LPT_Send(9);
    xdelay(10);
  end
  else
  begin
    port[TandyPort] := 1;
    xdelay(10);
    port[TandyPort] := 9;
    xdelay(10);
  end;
  TANDY_Mute_ALL;
  xdelay(100);
  TANDY_Mute_ALL;
end;


begin
 fillchar(volume,sizeof(volume),15);
 fillchar(freq,sizeof(freq),0);
end.
