{Unit to interfere with TLPT nd TNDY Tandy-3-voice sound devices
Version 1.2 -TNDY -
- Modified version for TNDY-Tracker -

30.09.2020 by Jan Knipperts

Some cleanup and added support for new version of TNDYLPT}


Unit TNDY;
interface
uses misc;

type
     LPT_ports    = record
       data,
       status,
       ctrl,
       ecr        : word;
       LPT        : Boolean;
     end;

    TNDY_Globals  = record
     IOPort       : word;
     volume       : array[0..3] of byte;
     freq         : array[0..3] of word;
    end;


var
     TANDY        : TNDY_Globals;
     TLPT         : LPT_ports;


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

Procedure TANDY_PlaySound(voice:byte; tone:word; level:byte);
Procedure TANDY_Noise(divider, feedback, level:byte);
Procedure TANDY_MuteVoice(voice : byte);
Procedure TANDY_Mute_all;

implementation

Procedure LPT_Send(b : byte);
assembler;
 asm
  mov al,b
  mov dx,TLPT.data
  out dx,al

  mov al,$0C
  mov dx,TLPT.ctrl
  out dx,al

  mov dx,TLPT.status
  mov cx,$18

  @@1:
  in al,dx
  test al,$40
  loopnz @@1
  cmp cx,0
  je  @Timeout

  mov cx,$18
  @@2:
  in al,dx
  test al,$40
  loopz @@2

  @Timeout:
  mov dx,TLPT.ctrl
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
  mov dx,Tandy.IOPort
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
 TANDY.IOport := LPTnum;
    TLPT.data := memw[$40:6+LPTnum*2];

 if TLPT.data = 0 then
 begin
  TLPT.lpt    := false;
  TLPT.status := 0;
  TLPT.ctrl   := 0;
  TLPT.ecr    := 0;
 end
 else
 begin
  TLPT.lpt    := true;
  TLPT.status := TLPT.data + 1;
  TLPT.ctrl   := TLPT.data + 2;
  TLPT.ecr    := TLPT.data + $402;

  asm
   mov dx,TLPT.ctrl
   xor al,al
   out dx,al
   mov dx,TLPT.ecr
   in  al,dx
   and al,3
   cmp al,1        {Is ECR enabled?}
   jne  @No_ECR
   xor al,al       {then disable it}
   out dx,al

   @No_ECR:
  end;

  TLPT_Mute;

  asm
   mov dx,TLPT.ctrl
   mov al,07
   out dx,al
  end;
  xdelay(200);             {wait}
  asm
   mov dx,TLPT.ctrl
   mov al,09
   out dx,al
  end;
  xdelay(200);             {wait}

 end;

 TLPT_Init := TLPT.lpt;
end;

procedure TNDY_Sound(voice:byte; frequency :word; level:byte);
var tone : word;
begin
   if frequency > 0 then
   begin
      tone := tandyIntDivider div frequency;
      asm
	mov  dx,Tandy.IOPort
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

        mov  dx,Tandy.IOPort
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

   if TLPT.lpt then
    TLPT_Sound(voice,tone,level)
   else
    TNDY_Sound(voice,tone,level);

   TANDY.Freq[voice] := tone;
  end;
end;

Procedure TANDY_Noise(divider, feedback, level:byte);
begin
  if TLPT.lpt then
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
 if TLPT.lpt then
 begin
   TLPT_Mute;
 end
 else
 begin
   TNDY_Mute;
 end;
 fillchar(TANDY.Freq,sizeof(TANDY.Freq),0);
 fillchar(TANDY.Volume,sizeof(TANDY.Volume),15);
end;

Procedure TANDY_MuteVoice(voice : byte);
begin
 if TLPT.lpt then
   LPT_Send($9F + (voice * $20))
 else
   port[Tandy.IOport] := $9F + (voice * $20);

 Tandy.Freq[voice] := 0;
 Tandy.volume[voice] := 15;
end;


begin
 fillchar(TANDY.Freq,sizeof(TANDY.Freq),0);
 fillchar(TANDY.Volume,sizeof(TANDY.Volume),15);
end.
