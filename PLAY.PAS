{$G-,N-,E-}

{**************************************************************
 Play.pas - Procedures and functions for playback

 Author: Jan Knipperts
 Program: TNDY-Tracker
 Version: 1.11

***************************************************************
}


Unit Play;
interface
uses global,tndy,tracker,PIT;

function  Note_to_Freq(note,octave : Byte) : Word;
Procedure Freq_to_Note(f : real;var  n,o : byte);
Function  Tone_to_Freq(noteHi, noteLo : byte) : word;


Procedure PlayVoice(voice:byte; tone : word; level:byte);
Procedure MuteVoice(voice : byte);
Procedure Mute_all;
Procedure MuteXtra;

Procedure UpdatePos;
Procedure UpdateFX(rownr : byte);
Procedure Playrow(rn : byte);

procedure SpkSound(hz:word);
procedure SpkNoSound;


implementation

{============ Frequency calculation ==============}
 function Power(base,exponent : real) : real;
 begin
  if base = 0.0 then Power := 0.0 else Power := exp(exponent*ln(base));
 end;

 function Log2(x : real) : real;
 begin
  Log2 := ln(x)/ln(2);
 end;


function Note_to_Freq(note,octave : Byte) : Word;
  var	r : real;
begin
  r := ((octave*12)+note) - 58; {58 = A4 (440 Hz)}
  r := Power(2,(r/12));
  Note_to_Freq := round(440*r);
end;


 Procedure Freq_to_Note(f : real;var  n,o : byte);
 var r,A4,C0 : real;
 begin
  if f > 0 then
  begin
   A4 := 440;
   C0 := A4*Power(2,-4.75);
   r := round(12*log2(f/C0));
   o := trunc(r / 12);
   n := (round(r) mod 12)+1;
  end
  else
  begin
   n := 13;
   o := 0;
  end;
 end;


 Function Tone_to_Freq(noteHi, noteLo : byte) : word;
 var frequency : word;
     clock : real;
 begin
   if SND.ClockFreq = 1 then
     clock := 99320
   else
     clock := 111860;

   frequency := ((noteHI and $3F) shl 4) + (noteLo and $0F);
   if noteHi = 0 then
    Tone_to_Freq := 0
   else
    Tone_to_Freq := round(clock / frequency);
 end;






{ PC SPEAKER }

procedure SpkNoSound;
assembler;
asm
  in al,61h
  and al,0fch
  out 61h,al
end;

procedure SpkSound(hz:word);
assembler;
asm
  mov bx,hz
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
end;


Procedure MuteXtra;
begin
 SpkNosound;
end;


{============ Playing on a voice channel ==============}
Procedure PlayVoice(voice:byte; tone : word; level:byte);
begin
if tone > 0 then
begin
 if (voice = 3) and (Editor.channels = 5) then {xtra channel}
 begin
  SpkSound(tone);
  TANDY.Freq[voice] := tone;
 end
 else
 begin
  if (voice <> Editor.channels-1) then
  TANDY_PlaySound(voice,tone,level);
 end;
end;
end;


Procedure MuteVoice(voice : byte);
begin
 if (Editor.channels = 5) and (voice = 3) then {xtra channel}
 begin
   MuteXtra;
 end
 else
 begin
  TANDY_MuteVoice(voice);
 end;

 TANDY.volume[voice] := 15;
 TANDY.freq[voice] := 0;
end;

{============ Mute all channels ==============}
Procedure Mute_all;
begin
 TANDY_Mute_All;
 MuteXtra;
end;





{============ Volume slide ==============}
Procedure Slidevolume_up(chan, slidespeed : byte);
var
 vol  : integer;
begin
       vol := TANDY.volume[chan];
       dec(vol, slidespeed);

       if vol < 0 then
       begin
         vol := 0;
       end;

       TANDY.Volume[chan] := vol;

       if (chan = 3) and (Editor.channels = 5) then {xtra channel}
       begin
        {Not supported by now}
       end
       else
        PlayVoice(chan,TANDY.freq[chan],TANDY.volume[chan]);
end;

Procedure Slidevolume_down(chan, slidespeed : byte);
var vol  : integer;

begin
       vol := TANDY.Volume[chan];
       inc(vol,slidespeed);

       if vol > $F then
       begin
         vol := $F;
       end;

       TANDY.Volume[chan] := vol;

       if (chan = 3) and (Editor.channels = 5) then {xtra channel}
       begin
        {Not supported by now}
       end
       else
        PlayVoice(chan,TANDY.freq[chan],TANDY.volume[chan]);
end;




{============ Portamento ==============}
Procedure Portamento_up(chan, portaspeed : byte; limit : word);
var  freqdum : word;
begin

 if (TANDY.freq[chan] > 0) and (Player.muted[chan] = false) then
 begin
  freqdum := TANDY.Freq[chan];

  If ((freqdum+portaspeed) < limit) then
  begin
    inc(freqdum,portaspeed);
    PlayVoice(chan,word(freqdum),TANDY.volume[chan]);
  end
  else
  begin
    PlayVoice(chan,limit,TANDY.volume[chan]);
  end;

 end;

end;



Procedure Portamento_down(chan,Portaspeed : byte; limit : word);
var freqdum : integer;
 begin

 if (TANDY.freq[chan] > 0) and (Player.muted[chan] = false) then
 begin
  freqdum := TANDY.Freq[chan];

  If ((freqdum-Portaspeed) > limit) then
  begin
    dec(freqdum,Player.speed);
    PlayVoice(chan,word(freqdum),TANDY.volume[chan]);
  end
  else
  begin
    PlayVoice(chan,limit,TANDY.volume[chan]);
  end;
 end;

end;


{============ Portamento to note / Toneslide ==============}
Procedure Toneslide(chan,slidespeed : byte; ToN : word);
var slidefreq : integer;
begin

if (TANDY.freq[chan] > 0) and (Player.muted[chan] = false) then
begin

 slidefreq := TANDY.freq[chan];

if (slidefreq < ToN) then
begin

 if slidefreq+slidespeed <= ToN then  {slide up}
 begin
  inc(slidefreq,slidespeed);
  if slidefreq > maxfreq then slidefreq := maxfreq;
 end
 else
  slidefreq := ToN;

end
else
begin

 if slidefreq-slidespeed >= ToN then  {slide down}
 begin
  dec(slidefreq,slidespeed);
  if slidefreq < minfreq then slidefreq := minfreq;
 end
 else
  slidefreq := ToN;
end;

  PlayVoice(chan,word(slidefreq),TANDY.volume[chan]);
end;

end;



{============ Arpeggio ==============}

Procedure DoArpeggio(chan : byte);
var dn,doc : byte;
begin

{This effect alternates the pitch rapidly to simulate a chord.  It usually
sounds very grating or harsh so it isnt used much except for chip tunes.

EG:
C-2 01 047 (I want to add to the pitch by 4 half notes then 7)
It is done something like this:
- increment arpcounter by 1
- if arpcounter > 2 arpcounter = 0
- if arpcounter = 0 set the frequency to the normal value
- if arpcounter = 1 set the frequency to the normal value + x # of fineetunes
- if arpcounter = 2 set the frequency to the normal value + y # of fineetunes}

if (Player.arp[chan].go = true) and (Player.muted[chan] = false) then
begin

if Player.arp[chan].cnt = 0 then
begin
 doc := Player.arp[chan].oc;
 dn := Player.arp[chan].on;
 PlayVoice(chan,note_to_freq(dn,doc),TANDY.volume[chan]); {spiele Note 0}
end;

if Player.arp[chan].cnt = 1 then
begin
 doc := Player.arp[chan].oc;
 dn := Player.arp[chan].on+Player.arp[chan].n1;
 if dn > 12 then
 begin
  dn := (dn - 12);
  doc := doc + 1;
  if dn = 0 then dn := 1;
 end;
 PlayVoice(chan,note_to_freq(dn,doc),TANDY.volume[chan]); {spiele Note 1}
end;

if Player.arp[chan].cnt = 2 then
begin
 doc := Player.arp[chan].oc;
 dn := Player.arp[chan].on+Player.arp[chan].n2;
 if dn > 12 then
 begin
  dn := (dn - 12);
  doc := doc + 1;
  if dn = 0 then dn := 1;
 end;
 PlayVoice(chan,note_to_freq(dn,doc),TANDY.volume[chan]); {spiele Note 2}
end;

 inc(Player.arp[chan].cnt);

if Player.arp[chan].cnt > 2 then
begin
 Player.arp[chan].cnt := 0;
end;


end;
end;



{======================================= The main Player routines ========================}



Procedure UpdateFX(rownr : byte);
{updates the special effects on ticks between two Player.rows}
var vol : integer;
    channr   : byte;
begin



   for channr := 0 to Editor.channels-2 do            {only the voice channels}
   begin

     if (Player.muted[channr] = false) then
     begin

        if (channr < Editor.channels-1) then  {Not the noise}
        begin


        DoArpeggio(channr); {Arpeggio?}

        if (patterns[Player.pattern_num]^[rownr][channr].effect = $01) then
        begin    {Portamento up}
          portamento_up(channr,patterns[Player.pattern_num]^[rownr][channr].ep,maxfreq);
        end;  {Portamento up}

        if (patterns[Player.pattern_num]^[rownr][channr].effect = $02) then
        begin    {Portamento down}
          portamento_down(channr,patterns[Player.pattern_num]^[rownr][channr].ep,minfreq);
        end;  {Portamento down}

        if (patterns[Player.pattern_num]^[rownr][channr].effect = $03) then
        begin                              {Toneslide?}
          toneslide(channr,Player.tsl[channr].speed,Player.tsl[channr].limit);
        end;

        if (patterns[Player.pattern_num]^[rownr][channr].effect = $04) then
        begin                              {Volume Slide}

         if (patterns[Player.pattern_num]^[rownr][channr].ep and $F0 > 0 ) and
            (patterns[Player.pattern_num]^[rownr][channr].ep and $0F = 0) then
          Slidevolume_up(channr,patterns[Player.pattern_num]^[rownr][channr].ep shr 4);

         if (patterns[Player.pattern_num]^[rownr][channr].ep and $0F > 0 ) and
            (patterns[Player.pattern_num]^[rownr][channr].ep and $F0 = 0) then
          Slidevolume_down(channr,patterns[Player.pattern_num]^[rownr][channr].ep and $0F);

        end;


        if (patterns[Player.pattern_num]^[rownr][channr].effect = $05) then
        begin                              {Tone and Volume Slide}

          if (patterns[Player.pattern_num]^[rownr][channr].ep and $F0 > 0 ) and
            (patterns[Player.pattern_num]^[rownr][channr].ep and $0F = 0) then
          begin
            vol := TANDY.volume[channr];
            dec(vol, patterns[Player.pattern_num]^[rownr][channr].ep shr 4);

            if vol < 0 then
            begin
              vol := 0;
            end;

           TANDY.Volume[channr] := vol;
          end;

          if (patterns[Player.pattern_num]^[rownr][channr].ep and $0F > 0 ) and
            (patterns[Player.pattern_num]^[rownr][channr].ep and $F0 = 0) then
          begin
           vol := TANDY.Volume[channr];
           inc(vol,patterns[Player.pattern_num]^[rownr][channr].ep and $0F);

           if vol > $0F then
           begin
             vol := $0F;
           end;

           TANDY.Volume[channr] := vol;
          end;

          toneslide(channr,Player.tsl[channr].speed,Player.tsl[channr].limit);

        end;

    end;

    end;

    end;



end;





Procedure UpdatePos;
{Updates the song Position}
begin

if (update = true) and not pause then
begin

  inc(Player.row);

  if Player.row = 64 then
  begin
   if not patternplay then
   begin
    inc(Player.Position);
    if Player.Position > Player.Songlength-1 then Player.Position := Player.loop;
    Player.pattern_num := order[Player.Position];
    Player.row := 0;
   end
   else
   begin
    pause := true;
    mainmenu := false;
    pedit := true;
    Mute_All;
    Draw_Pattern_Editor(true);
   end;

  end;

    update := false;

    UpdatePatternView(Player.row-8,true);
    if not pedit then Update_Player_State;

end;

end;





Procedure Playrow(rn : byte);
{Plays one Player.row}
var on,oc,eff,ep,chan   : byte;
    pitch               : integer;

    label Restart;

begin

  For chan := 0 to Editor.channels-1 do  {Channel}
  begin

   Restart:

    if not Player.muted[chan] then
    begin

       on  := patterns[Player.pattern_num]^[rn][chan].note;   {speichere Note & Oktave}
       oc  := patterns[Player.pattern_num]^[rn][chan].octave;
       eff := patterns[Player.pattern_num]^[rn][chan].effect; {Effekt}
       ep  := patterns[Player.pattern_num]^[rn][chan].ep;
       Player.arp[chan].go := false;



       if patterns[Player.pattern_num]^[rn][chan].volume > 0 then
       begin
         TANDY.Volume[chan] := patterns[Player.pattern_num]^[rn][chan].volume-1;
         if TANDY.Volume[chan] > 15 then TANDY.Volume[chan] := 15;

         if on = 0 then {Neue Lautstärke, aber keine neue Note}
         begin
            if (chan = Editor.channels-1) then
             begin
                TANDY_Noise(Player.onote[chan],Player.ooct[chan],TANDY.volume[chan]);
             end
            else
             begin
               PlayVoice(chan,TANDY.Freq[chan],TANDY.volume[chan]);
             end;
         end;
       end;




        if (eff = $0A) then            {Player.finetune}
        begin
          Player.finetune := ep;

          if on = 0 then {neuer Wert für Player.finetune, aber keine neue Note}
          begin

             pitch := note_to_freq(Player.onote[chan],Player.ooct[chan]);

             if Player.finetune > 0 then
             begin

               if Player.finetune <= $80 then
               begin
                 pitch := pitch-Player.finetune;
                 if pitch < minfreq then pitch := minfreq;
               end
               else
               begin
                 pitch := pitch+(Player.finetune-$80);
               end;

             end;

              if chan < Editor.channels-1 then PlayVoice(chan,pitch,TANDY.volume[chan]);
          end;

        end
       else
        begin
         Player.finetune := 0;
        end;



        if on = 13 then {key off}
        begin
         MuteVoice(chan);
         TANDY.volume[chan] := 15;
         TANDY.freq[chan] := 0;
        end;


        if (on > 0) and (on < 13)  then    {Richtige Note?}
        begin

            if (eff = $03) or (eff = $05) then       {Oder ein Toneslide?}
            begin
              Player.tsl[chan].limit := note_to_freq(on,oc);
              if ep > 0 then Player.tsl[chan].speed :=  ep;
            end
            else
            begin
              Player.tsl[chan].limit := 0;
              Player.tsl[chan].freq := 0;
              Player.tsl[chan].speed := 0;

              if chan < Editor.channels-1 then
              begin
                pitch := note_to_freq(on,oc);

                if Player.finetune > 0 then
                begin

                  if Player.finetune <= $80 then
                  begin
                    pitch := pitch-Player.finetune;
                    if pitch < minfreq then pitch := minfreq;
                  end
                  else
                  begin
                    pitch := pitch+(Player.finetune-$80);
                    if pitch > maxfreq then pitch := maxfreq;
                  end;

                end;

                PlayVoice(chan,pitch,TANDY.volume[chan]);
                Player.onote[chan] := on;                            {Sichern fr Effekte}
                Player.ooct[chan]  := oc;

              end
              else
              begin
               TANDY_Noise(on,oc,TANDY.volume[chan]);
              end;

           end;  {else}

       end;  {Note}




        if (eff = $0F)  then			 {set Player.speed}
        begin
          if ep >  0 then
          begin
            if ep < $1F then
            begin
              Player.speed := ep; {Set new Player.speed}
            end
           else
            begin
              Player.tempo := ep;
              set_timer(Player.tempo); {Set Player.tempo}
            end;
          end
        else
          begin
            Player.tempo := 18;
            set_timer(0); {18.2 Hz Mode}
          end;

          Update_Player_State;
        end;

        if (eff = $0) and					{Arpeggio}
           (ep > 0) and
           (Player.onote[chan] > 0) then
        begin
          Player.arp[chan].go := True;
          Player.arp[chan].cnt := 0;
          Player.arp[chan].on := Player.onote[chan];
          Player.arp[chan].oc := Player.ooct[chan];
          Player.arp[chan].n1 := (ep div 10);
          Player.arp[chan].n2 := (ep mod 10);
        end;


        if (eff = $01) then
        begin    {Portamento up}
          portamento_up(chan,ep,maxfreq);
        end;  {Portamento up}

        if (eff = $02) then
        begin    {Portamento down}
          portamento_down(chan,ep,minfreq);
        end;  {Portamento down}

        if (eff = $03) then  {Toneslide}
        begin
         toneslide(chan,Player.tsl[chan].speed,Player.tsl[chan].limit);
        end;


        if (eff = $04) or (eff = $05) then  {Volume Slide}
        begin

         if ((ep and $F0) > 0 ) and ((ep and $0F) = 0) then
          Slidevolume_up(chan,ep shr 4);

         if ((ep and $0F) > 0 ) and ((ep and $F0) = 0) then
          Slidevolume_down(chan,ep and $0F);

        end;



       if (eff = $0D)  then					{Pattern break}
        begin
          inc(Player.Position);
          if Player.Position > Player.Songlength-1 then Player.Position := 0;
          Player.pattern_num := order[Player.Position];
          Player.row := ep;

          rn  := Player.row;
          chan := 0;
          UpdatePatternView(Player.row-8,true);
          if not pedit then Update_Player_State;
          goto Restart;
        end;

        if (eff = $0B) then					{Player.Position jump}
        begin
          if ep <= Player.Songlength then
          begin
            Player.Position := ep;
            Player.pattern_num := order[Player.Position];
            Player.row := 0;

            rn  := Player.row;
            chan := 0;
            UpdatePatternView(Player.row-8,true);
            if not pedit then Update_Player_State;
            goto Restart;
          end;
        end;

   end; {muted}



 end; {Alle Channels played}

 update := true;  {Player.row has been played. Set flag to update Player.Position}

end;

end.
