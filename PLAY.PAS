{$G-,N-,E-}

{**************************************************************
 Play.pas - Procedures and functions for playback

 Author: Jan Knipperts
 Program: TNDY-Tracker
 Version: 1.13
  - Changed frequency calculation
  - Fixed tone slide
  - improved screen buffering

***************************************************************
}


Unit Play;
interface
uses global,tndy,tracker,PIT;

function  Note_to_Freq(note,octave : Byte) : Word;
Procedure Freq_to_Note(f : word;var  n,o : byte);
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


const

 {Note (version 1.12):
  I've replaced the frequency calculation with a lookup table,
  because it took too much time to calculate freqs on slow CPUs}

Note_frequencies : array[2..9] of array[1..12] of word = (
   {C    C#     D    D#     E     F    F#     G    G#     A    A#    B}
(   65,   69,   73,   78,   82,   87,   92,   98,  104,  110,  117,  123), {Octave 2...}
(  131,  139,  147,  156,  165,  175,  185,  196,  208,  220,  233,  247),
(  262,  277,  294,  311,  330,  349,  370,  392,  415,  440,  466,  494),
(  523,  554,  587,  622,  659,  698,  740,  784,  831,  880,  932,  988),
( 1047, 1109, 1175, 1245, 1319, 1397, 1480, 1568, 1661, 1760, 1865, 1976),
( 2093, 2217, 2349, 2489, 2637, 2794, 2960, 3136, 3322, 3520, 3729, 3951),
( 4186, 4435, 4699, 4978, 5274, 5588, 5920, 6272, 6645, 7040, 7459, 7902),
( 8372, 8870, 9397, 9956,10548,11175,11840,12544,13290,14080,14917,15804)); {...Octave 9}


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

  if (octave < 2) or (octave > 9) then    {Only unusual frequencies will be calculated}
  begin
    r := ((octave*12)+note) - 58; {58 = A4 (440 Hz)}
    r := Power(2,(r/12));
    Note_to_Freq := round(440*r);
  end
  else
  {All others are looked up in the table to relieve the CPU}
   Note_to_Freq := Note_frequencies[octave,note];



end;


 Procedure Freq_to_Note(f : word;var  n,o : byte);
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




{============ Volume slide ==============}
Procedure Slidevolume_up(chan, slidespeed : byte);
begin
    if (TANDY.freq[chan] > 0) and (Player.muted[chan] = false) then
    begin

       if (Player.vsl[chan] = 0) then Player.vsl[chan] := TANDY.volume[chan];

       Player.vsl[chan] := Player.vsl[chan] - (slidespeed * 0.23); {experimental!}

       if Player.vsl[chan] < 0 then
       begin
         Player.vsl[chan] := 0;
       end;



       if (chan = 3) and (Editor.channels = 5) then {xtra channel}
       begin
        {Not supported by now}
       end
       else
       begin
        TANDY.volume[chan] := round(Player.vsl[chan]);
        PlayVoice(chan,TANDY.freq[chan],TANDY.volume[chan]);
       end;

    end;
end;

Procedure Slidevolume_down(chan, slidespeed : byte);
begin
    if (TANDY.freq[chan] > 0) and (Player.muted[chan] = false) then
    begin
       if (Player.vsl[chan] = 0) then Player.vsl[chan] := TANDY.volume[chan];

       Player.vsl[chan] := Player.vsl[chan] + (slidespeed * 0.23); {experimental!}

       if Player.vsl[chan] > $F then
       begin
         Player.vsl[chan] := $F;
       end;

       if (chan = 3) and (Editor.channels = 5) then {xtra channel}
       begin
        {Not supported by now}
       end
       else
       begin
        TANDY.volume[chan] := round(Player.vsl[chan]);
        PlayVoice(chan,TANDY.freq[chan],TANDY.volume[chan]);
       end;
    end;
end;




Procedure toneslide_and_volume_up(chan, slidespeed : byte);
begin
    if (TANDY.freq[chan] > 0) and (Player.muted[chan] = false) then
    begin
       {Calculate new volume}
       if (Player.vsl[chan] = 0) then Player.vsl[chan] := TANDY.volume[chan];

       Player.vsl[chan] := Player.vsl[chan] - (slidespeed * 0.23);

       if Player.vsl[chan] < 0 then
       begin
         Player.vsl[chan] := 0;
       end;

       TANDY.volume[chan] := round(Player.vsl[chan]);

       {And perform the toneslide}
       toneslide(chan,Player.tsl[chan].speed,Player.tsl[chan].limit);

    end;
end;



Procedure toneslide_and_volume_down(chan, slidespeed : byte);
begin
    if (TANDY.freq[chan] > 0) and (Player.muted[chan] = false) then
    begin
       {Calculate new volume}
       if (Player.vsl[chan] = 0) then Player.vsl[chan] := TANDY.volume[chan];

       Player.vsl[chan] := Player.vsl[chan] + (slidespeed * 0.23);

       if Player.vsl[chan] > $F then
       begin
         Player.vsl[chan] := $F;
       end;

       TANDY.volume[chan] := round(Player.vsl[chan]);

       {And perform the toneslide}
       toneslide(chan,Player.tsl[chan].speed,Player.tsl[chan].limit);

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



   for channr := 0 to Editor.channels-2 do     {only for the voice channels}
   begin

     if (Player.muted[channr] = false) then
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
          toneslide_and_volume_up(channr,patterns[Player.pattern_num]^[rownr][channr].ep shr 4);

         if (patterns[Player.pattern_num]^[rownr][channr].ep and $0F > 0 ) and
            (patterns[Player.pattern_num]^[rownr][channr].ep and $F0 = 0) then
          toneslide_and_volume_down(channr,patterns[Player.pattern_num]^[rownr][channr].ep and $0F);

        end;



    end;

    end;



end;





Procedure UpdatePos;
{Updates the song Position}
var p : pointer; {dummy pointer for buffer exchange}
begin

  if Player.Position < Player.Songlength-1 then {Create next pattern buffer in the background}
   Update_Pattern_Screenbuffer(buffer.pbuffer1,order[Player.Position+1],Player.row,Player.row)
  else
   Update_Pattern_Screenbuffer(buffer.pbuffer1,order[Player.loop],Player.row,Player.row);

  inc(Player.row);

  if Player.row = 64 then
  begin
   if not patternplay then
   begin
    inc(Player.Position);
    if Player.Position > Player.Songlength-1 then
    Player.Position := Player.loop;

    Player.pattern_num := order[Player.Position];
    Player.row := 0;

    p := buffer.pbuffer;  {Swap buffers}
    buffer.pbuffer := buffer.pbuffer1;
    buffer.pbuffer1 := p;

   end
   else
   begin
    pause := true;
    mainmenu := false;
    pedit := true;
    Mute_All;
    Draw_Pattern_Editor(true);
   end;

   Update_Player_State;

  end;

  UpdatePatternView(Player.row-8,true);
end;





Procedure Playrow(rn : byte);
{Plays one row}
var on,oc,eff,ep,chan   : byte;
    pitch               : integer;

    label Restart;

begin

  Restart:  {label for Position jump and pattern break to start playing the row again}



  For chan := 0 to Editor.channels-1 do  {Channel}
  begin


    if not Player.muted[chan] then
    begin

       on  := patterns[Player.pattern_num]^[rn][chan].note;   {save note and oktave}
       oc  := patterns[Player.pattern_num]^[rn][chan].octave;
       eff := patterns[Player.pattern_num]^[rn][chan].effect; {effect}
       ep  := patterns[Player.pattern_num]^[rn][chan].ep;
       Player.arp[chan].go := false;


      {============ 1. Update effects that must be processed before the note ==================}


      {Volume}
       if patterns[Player.pattern_num]^[rn][chan].volume > 0 then    {new value for volume?}
       begin
         TANDY.Volume[chan] := patterns[Player.pattern_num]^[rn][chan].volume-1; {update volume}
         Player.vsl[chan] := patterns[Player.pattern_num]^[rn][chan].volume-1; {also for a volume slide}

         if patterns[Player.pattern_num]^[rn][chan].volume-1 = $F then {Volume F = key off}
         begin
           on := 13;
           oc := 0;
         end;


         if on = 0 then {We have a new volume, but no new note...}
         begin
            if (chan = Editor.channels-1) then {Is this the noise channel?}
             begin
                {Yes? Then update last noise sound with new volume}
                TANDY_Noise(Player.onote[chan],Player.ooct[chan],TANDY.volume[chan]);
             end
            else
             begin
               {If not, update last voice with new volume}
               PlayVoice(chan,TANDY.Freq[chan],TANDY.volume[chan]);
             end;
         end;
       end;



       {Finetune}
       if (eff = $0A) and (ep > 0) and (chan < Editor.channels-1) then
       {Finetune effect, with valid parameter and not in the noise channel?}
       begin
         Player.finetune := ep;

         if on = 0 then {We have a new value for finetune, but no new note}
         begin
           {Calculate the frequency of the last note played on this channel}
           pitch := note_to_freq(Player.onote[chan],Player.ooct[chan]);

           if Player.finetune < $80 then
           begin
             pitch := pitch-Player.finetune;
             if pitch < minfreq then
             pitch := minfreq;
           end
          else
             pitch := pitch+(Player.finetune-$80);

           PlayVoice(chan,pitch,TANDY.volume[chan]); {Update channel with new frequency}
         end;

        end
       else
        begin
         Player.finetune := 0; {Clear last finetune value}
        end;


        {Key off}
        if on = 13 then
        begin
         MuteVoice(chan);
         TANDY.volume[chan] := 15;
         TANDY.freq[chan] := 0;
        end;



       {============ 2. Play Note ==================}


        if (on in [1..12]) then    {Valid note?}
        begin

            if (eff = $03) or (eff = $05) then       {Does the note belong to a toneslide?}
            begin
              Player.tsl[chan].limit := note_to_freq(on,oc);  {Update toneslide}
              if ep > 0 then Player.tsl[chan].speed :=  ep;
            end
            else
            begin
              Player.tsl[chan].limit := 0;   {If not, reset toneslide variables}
              Player.tsl[chan].speed := 0;

              if chan < Editor.channels-1 then  {Is a voice channel being processed?}
              begin
                pitch := note_to_freq(on,oc); {Calculate notes frequency in Hz}

                if Player.finetune > 0 then   {Is finetune active?}
                begin

                  if Player.finetune <= $80 then  {Values <= 80h have to be subtracted}
                  begin
                    pitch := pitch-Player.finetune;
                    {Make sure that we do not reach a frequency unplayable for the Tandy}
                    if pitch < minfreq then pitch := minfreq;
                  end
                  else
                  begin
                    pitch := pitch+(Player.finetune-$80); {vakues > 80h have to be addded}
                    {Make sure that we do not reach a frequency unplayable for the Tandy}
                    if pitch > maxfreq then pitch := maxfreq;
                  end;

                end;

                PlayVoice(chan,pitch,TANDY.volume[chan]); {Play the new frequency}
                Player.onote[chan] := on; {Save actual vales for effects}
                Player.ooct[chan]  := oc;
                Player.vsl[chan] := patterns[Player.pattern_num]^[rn][chan].volume-1;

              end
              else     {We're processing the noise channel}
              begin
               TANDY_Noise(on,oc,TANDY.volume[chan]);  {Play new noise}
              end;

           end;  {else}

       end;  {Note}


        {============ 3. Update effects that must be processed after the note starts playing ==================}

        if (eff = $0F)  then	{set speed}
        begin
          if ep >  0 then
          begin
            if ep < $1F then
            begin
              Player.speed := ep; {Set new speed}
            end
           else
            begin
              Player.tempo := ep;
              set_timer(Player.tempo); {Set tempo}
            end;
          end
        else
          begin
            Player.tempo := 18;
            set_timer(0); {18.2 Hz Mode}
          end;

          Update_Player_State;
        end;

        if (eff = $0) and	{Arpeggio}
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


        if (eff = $01) then  {Portamento up}
        begin
          portamento_up(chan,ep,maxfreq);
        end;

        if (eff = $02) then {Portamento down}
        begin
          portamento_down(chan,ep,minfreq);
        end;

        if (eff = $03) then  {Toneslide}
        begin
         toneslide(chan,Player.tsl[chan].speed,Player.tsl[chan].limit);
        end;

        if (eff = $04) then  {Volume Slide}
        begin
         if ((ep and $F0) > 0 ) and ((ep and $0F) = 0) then
          Slidevolume_up(chan,ep shr 4);

         if ((ep and $0F) > 0 ) and ((ep and $F0) = 0) then
          Slidevolume_down(chan,ep and $0F);
        end;

        if (eff = $05) then {Tone and Volume Slide}
        begin
          if ((ep and $F0) > 0 ) and ((ep and $0F) = 0) then
            toneslide_and_volume_up(chan,ep shr 4);

          if ((ep and $0F) > 0 ) and ((ep and $F0) = 0) then
            toneslide_and_volume_down(chan,ep and $0F);
        end;


       if (eff = $0D)  then	{Pattern break}
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

        if (eff = $0B) then	{Position jump}
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



 end; {All channels played}

 updatePOS;  {Row has been played. Up to the next..}

end;

end.
