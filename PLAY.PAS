{$G-,N-,E-}

{**************************************************************
 Play.pas - Procedures and functions for playback

 Author: Jan Knipperts
 Program: TNDY-Tracker
 Version: 1.22
***************************************************************}



Unit Play;
interface
uses global,keyboard,textmode,tracker,tndy,PIT;

function  Note_to_Freq(note,octave : Byte) : Word;
function  Calc_Freq(note,octave : byte) : Word;
Procedure Freq_to_Note(f : word;var  n,o : byte);
function  Tone_to_Freq(High_Byte,Low_Byte  : byte) : word;

Procedure Play_Voice(voice : byte; frequency : word; level : byte);
Procedure Mute_Voice(voice : byte);
Procedure Mute_all;

Procedure Update_FX(chan : byte);
Procedure Play_Row(rn : byte);
Procedure Play_Event(chan : byte);
Procedure Handle_pre_note_FX(chan : byte);
Procedure Handle_post_note_FX(chan : byte);
Procedure Update_Pos;

Procedure Clear_Sounddata;

Procedure Start_Play_Song;
Procedure Start_Play_Pattern;
Procedure Start_Play_Cursor;
Procedure Stop_Playing;

const

 {Note:
  I've replaced the frequency calculation of version 1.0/1.1 with a lookup table,
  because it took too much time to calculate freqs on slower CPUs}

Note_frequencies : array[2..9] of array[1..12] of word = (
   {C    C#     D    D#     E     F    F#     G    G#     A    A#    B}
(   65,   69,   73,   78,   82,   87,   92,   98,  104,  110,  117,  123), {Octave 2...}
(  131,  139,  147,  156,  165,  175,  185,  196,  208,  220,  233,  247),  {3}
(  262,  277,  294,  311,  330,  349,  370,  392,  415,  440,  466,  494),  {4}
(  523,  554,  587,  622,  659,  698,  740,  784,  831,  880,  932,  988),  {5}
( 1047, 1109, 1175, 1245, 1319, 1397, 1480, 1568, 1661, 1760, 1865, 1976),  {6}
( 2093, 2217, 2349, 2489, 2637, 2794, 2960, 3136, 3322, 3520, 3729, 3951),  {7}
( 4186, 4435, 4699, 4978, 5274, 5588, 5920, 6272, 6645, 7040, 7459, 7902),  {8}
( 8372, 8870, 9397, 9956,10548,11175,11840,12544,13290,14080,14917,15804)); {...Octave 9}

var
 jump	   : boolean;
 newfreq   : word;

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


function Calc_Freq(note,octave : byte) : Word;
  var	r : real;
begin
    r := ((octave*12)+note) - 58; {58 = A4 (440 Hz)}
    r := Power(2,(r/12));
    Calc_Freq := round(440*r);
end;


function Note_to_Freq(note,octave : Byte) : Word;
begin

  if (octave < 2) or (octave > 9) then
   {Unusual frequencies will be calculated}
   Note_to_Freq := Calc_Freq(note,octave)
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


 Function Tone_to_Freq(High_Byte,Low_Byte  : byte) : word;
 var frequency, clock     : real;
 begin
   if SNDcfg.ClockFreq = 1 then
     clock := tandyFreq/36  {Alternative clock: 99.320 Hz}
   else
     clock := tandyFreq/32;  {Default clock: 111.860 Hz}

   frequency := ((High_Byte and $3F) shl 4) or (Low_Byte and $0F);

   if frequency = 0 then
    Tone_to_Freq := 0
   else
    Tone_to_Freq := round(clock / frequency);
 end;




{============ Playing on a voice channel ==============}

Procedure Play_Voice(voice : byte; frequency : word; level : byte);
begin
    if (voice < 3) then
    begin
      TANDY_PlaySound(voice,frequency,level);
      Meter[voice] := 15-level;
      volume[voice] := level;
    end;

    if (voice = 3) and (Editor.channels = 5) then {xtra channel}
    begin
     SpkSound(frequency);
     volume[voice] := 0; {Pc speaker is always 100%...}
     Meter[voice] := 15-level;
    end;
    freq[voice] := frequency;
end;



Procedure Mute_Voice(voice : byte);
begin
  if (Editor.channels = 5) and (voice = 3) then {xtra channel}
  begin
   SpkNoSound;
  end
  else
  begin
    if voice > 3 then voice := 3;
    TANDY_MuteVoice(voice);
  end;
end;



{============ Mute all channels ==============}


Procedure Mute_all;
begin
 TANDY_Mute_All;
 SpkNoSound;
 fillchar(volume,sizeof(volume),15);
 fillchar(freq,sizeof(freq),0);
 fillchar(meter,sizeof(meter),0);
end;






   Procedure Setup_Arpeggio(chan : byte);
   var n,o : byte;
   begin
      if current[chan].note > 0 then
      begin
        n := current[chan].note;
        o := current[chan].octave;
      end
      else
      begin
       n := player.onote[chan];
       o := player.ooct[chan];
      end;



      player.arp[chan].n0 := n;
      player.arp[chan].o0 := o;
      player.arp[chan].n1 := n + (current[chan].ep shr 4);
      player.arp[chan].o1 := o;
      player.arp[chan].n2 := n + (current[chan].ep and $0F);
      player.arp[chan].o2 := o;

      if player.arp[chan].n1 >= 13 then  {correct octave}
      begin
        dec(player.arp[chan].n1,13);
        inc(player.arp[chan].o1);
      end;
      if player.arp[chan].n2 >= 13 then
      begin
        dec(player.arp[chan].n2,13);
        inc(player.arp[chan].o2);
      end;

      if current[chan].note in [1..12] then {Set counter to 1 if there is a regular note to be played}
       player.arp[chan].cnt := 1
      else
       player.arp[chan].cnt := 0;
   end;



Procedure Setup_Toneslide(chan : byte; speedchange : boolean);
begin
   player.tsl[chan].limit := newfreq;
   if speedchange then player.tsl[chan].speed := current[chan].ep;
end;



Procedure Do_Finetune(chan : byte);
begin
    if current[chan].ep < $80 then
      dec(newfreq,current[chan].ep)
    else
      inc(newfreq,current[chan].ep-$80);
end;




Procedure Play_Event(chan : byte);
begin
  current[chan] := patterns[Player.pattern_num]^[player.row][chan];



  if chan < Editor.channels-1 then	{This is a voice channel}
  begin

    if (current[chan].note = 13) then  {Key-off?}
    begin
      Mute_Voice(chan);
      freq[chan] := 0;
      newfreq := 0;
      exit;
    end;


    if (current[chan].volume > 0) then {volume change}
    begin
        volume[chan] := current[chan].volume-1;
        player.vsl[chan] := volume[chan];	{Reset active volume slide}
    end;


    if current[chan].note = 0 then
    begin
      if current[chan].volume > 0 then
        Play_Voice(chan,freq[chan],volume[chan]);
      if (current[chan].effect = 0) and (current[chan].ep > 0) then
        Setup_Arpeggio(chan);
      Handle_post_note_FX(chan);
      exit;
    end;


    if current[chan].note in [1..12] then
    begin
      newfreq := Note_to_freq(current[chan].note,current[chan].octave);
      Handle_pre_note_FX(chan);

      if (current[chan].effect <> $3) and (current[chan].effect <> $5) then
      begin
       player.tsl[chan].limit := 0;
       player.tsl[chan].speed := 0;
       player.onote[chan] := current[chan].note;
       player.ooct[chan] := current[chan].octave;
       Play_Voice(chan,newfreq,volume[chan]);
      end;

      Handle_post_note_FX(chan);

    end;

  end
  else
  begin
    if (current[chan].note = 5) then  {Key-off noise channel?}
    begin
      TANDY_PlayNoise(0,0,$F);
      volume[chan] := $F;
      Meter[chan] := 0;
      freq[chan] := 0;
      exit;
    end;

    if current[chan].note in [1..4] then
    begin
      case current[chan].note of
       1: Freq[chan] := 2330;
       2: Freq[chan] := 1165;
       3: Freq[chan] := 583;
       4: Freq[chan] := Freq[2];
     end;
     volume[chan] := current[chan].volume-1;
     TANDY_PlayNoise(current[chan].note-1,current[chan].octave-1,current[chan].volume-1);  {Play new noise}
    end
    else
    begin
      if (current[chan].volume > 0) then {volume change}
      begin
        volume[chan] := current[chan].volume-1;
        TANDY_PlayNoise(player.onote[chan]-1,player.ooct[chan]-1,current[chan].volume-1);  {Play new noise}
      end;
    end;
  end;
  Meter[chan] := 15-volume[chan];
end;





   Procedure Set_Speed_Tempo(chan : byte);
   begin
     if current[chan].ep < $1F then
        player.speed := current[chan].ep
     else
     begin
       Player.tempo := current[chan].ep;
       Set_Timer(current[chan].ep);
     end;
     ptn.infoupdate := true; {signal to update the player info}
   end;

   Procedure Prepare_Jump(chan : byte);
   begin
      if not patternplay then
      begin
        Player.Position := current[chan].ep;

        if Player.Position > Player.Songlength-1 then
        Player.Position := 0;

        Player.pattern_num := order[Player.Position];
        Player.row := 0;

        if ptn.tracemode then
        begin
          Update_Pattern_Screenbuffer(buffer.pbuffer, Player.pattern_num,0,8);
          Update_Order(false,true);
          Update_Pattern(-8,true);
          ptn.infoupdate := true; {signal to update the player info}
        end;
        jump := true;
      end;
   end;

   Procedure Prepare_Break(chan : byte);
   begin
     if not patternplay then
     begin
      inc(Player.Position);
      if Player.Position > Player.Songlength-1 then
      Player.Position := Player.loop;
      Player.pattern_num := order[Player.Position];
      Player.row := current[chan].ep;
      if Player.row > 63 then Player.row := 63;

      if ptn.tracemode then
      begin
        Update_Pattern_Screenbuffer(buffer.pbuffer, Player.pattern_num,Player.row-8,Player.row+8);
        Update_Order(false,true);
        Update_Pattern(Player.row-8,true);
        ptn.infoupdate := true; {signal to update the player info}
      end;

      jump := true;
     end;
   end;

   	Procedure Do_Arpeggio(chan : byte);
	begin
	  case player.arp[chan].cnt of
	   0: Play_Voice(chan,note_to_freq(player.arp[chan].n0,player.arp[chan].o0),volume[chan]);
	   1: Play_Voice(chan,note_to_freq(player.arp[chan].n1,player.arp[chan].o1),volume[chan]);
	   2: Play_Voice(chan,note_to_freq(player.arp[chan].n2,player.arp[chan].o2),volume[chan]);
	  end;
	  inc(player.arp[chan].cnt);
	  if player.arp[chan].cnt = 3 then player.arp[chan].cnt := 0;
	end;

	Procedure Do_Porta_up(chan : byte);
	begin
	  if freq[chan] < maxfreq then
	  begin
	    inc(freq[chan],current[chan].ep);
            Play_Voice(chan,freq[chan],volume[chan]);
	  end;
	end;

	Procedure Do_Porta_dwn(chan : byte);
	begin
	  if freq[chan] > minfreq then
	  begin
	    dec(freq[chan],current[chan].ep);
            Play_Voice(chan,freq[chan],volume[chan]);
	  end;
	end;

	Procedure Do_Toneslide(chan : byte);
	begin
            if (freq[chan] = 0) and (chan < 3) then freq[chan] := MinFreq;

            if freq[chan] < player.tsl[chan].limit then
	    begin
	      if (freq[chan] + player.tsl[chan].speed) < player.tsl[chan].limit then
	         inc(freq[chan],player.tsl[chan].speed)
	      else
	         freq[chan] := player.tsl[chan].limit;
	    end;

	    if freq[chan] > player.tsl[chan].limit then
	    begin
	      if (freq[chan] - player.tsl[chan].speed) > player.tsl[chan].limit then
	         dec(freq[chan],player.tsl[chan].speed)
	      else
	         freq[chan] := player.tsl[chan].limit;
	    end;

	     Play_Voice(chan,freq[chan],volume[chan]);
	end;

	Procedure Do_Volumeslide(chan : byte; playit : boolean);
	begin

	  if (current[chan].ep and $F0) > 0 then	{slide up}
	   player.vsl[chan] := player.vsl[chan] - ((current[chan].ep shr 4)* 0.23)
	  else
	   player.vsl[chan] := player.vsl[chan] + ((current[chan].ep and $0F) * 0.23);

	  if player.vsl[chan] < 0 then player.vsl[chan] := 0;
	  if player.vsl[chan] > $F then player.vsl[chan] := $F;

	  volume[chan] := round(player.vsl[chan]);


	  if playit then Play_Voice(chan,freq[chan],volume[chan]);

	end;







Procedure Handle_pre_note_FX(chan : byte);
begin
    case current[chan].effect of
     $00: Setup_Arpeggio(chan);
     $03: Setup_Toneslide(chan,true);
     $05: Setup_Toneslide(chan,false);
     $0A: Do_Finetune(chan);
    end;
end;




Procedure Handle_post_note_FX(chan : byte);
begin
    case current[chan].effect of
     $0F: Set_Speed_Tempo(chan);
     $0B: Prepare_Jump(chan);
     $0D: Prepare_Break(chan);
    end;
    Update_FX(chan);

end;




Procedure Update_FX(chan : byte);
begin

  if player.muted[chan] = false then
  begin

    if (current[chan].effect = 0) and (current[chan].ep = 0) then exit;

    case current[chan].effect of
      $00: Do_Arpeggio(chan);
      $01: Do_Porta_up(chan);
      $02: Do_Porta_dwn(chan);
      $03: Do_Toneslide(chan);
      $04: Do_Volumeslide(chan,true);
      $05:
           begin
             Do_Volumeslide(chan,false);
             Do_Toneslide(chan);
           end;
    end;

  end;
end;


Procedure Play_Row(rn : byte);
{Plays one row}
var chan   : byte;
label restart;
begin

 restart:
  jump := false;
  chan := 0; {Channel}
  repeat

    if meter[chan] > 0 then dec(meter[chan]); {update Peak meter}

    if (Player.muted[chan] = false) then
    begin
     Play_Event(chan);
     if jump then goto restart;
    end
    else {muted?}
     meter[chan] := 0; {set peak meter to zero}

    inc(chan);
  until chan = Editor.channels {All channels played}
end;


Procedure Update_Pos;
{Updates the song Position}
begin
    inc(Player.row);

    if ptn.tracemode then
    begin
      Prepare_next_Patterns_buffer;  {Alredy render a row of the next pattern in the back buffer}
      ptn.ptnupdate := true;
    end
    else
      ptn.infoupdate := true;

    if Player.row = 64 then
    begin
      if not patternplay then
      begin
        inc(Player.Position);
        if Player.Position > Player.Songlength-1 then
        Player.Position := Player.loop;
        Player.pattern_num := order[Player.Position];
        Player.row := 0;
        ptn.infoupdate := true;
        if ptn.tracemode then ptn.bufferswap  := true; {it's time to swap buffer addresses}
      end
      else
       Stop_Playing;
    end;
end;



Procedure Clear_Sounddata;
begin
  Mute_all;
  fillchar(Player.arp,sizeof(Player.arp),0);
  fillchar(Player.tsl,sizeof(Player.tsl),0);
  fillchar(Player.onote,sizeof(Player.onote),0);
  fillchar(Player.ooct,sizeof(Player.ooct),0);
  fillchar(volume,sizeof(volume),15);
  fillchar(freq,sizeof(freq),0);
  fillchar(meter,sizeof(meter),0);
  fillchar(current,sizeof(current),0);
end;




Procedure Start_Play_Song;
begin
  Mute_all;                             {Mute all output}
  fillchar(current,sizeof(current),0);  {Clear current event buffer}
  mainmenu := false;
  pedit := false;

  old.pos    := player.position;
  old.patn   := player.pattern_num;
  old.xp     := GetX;
  old.row    := Editor.markedrow;

  patternplay := false;
  ptn.infoupdate := true; {signal to update the player info}
  player.position := 0;
  player.row := 0;
  player.pattern_num := order[player.position];
  CopyBuffer(buffer.blankscreen,buffer.screen1);

  if ptn.tracemode then
  begin
    Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,0,63);
    Draw_Editor_Window(false);
    Draw_Pattern_Window(false);
    Update_Order(false,true);
    Update_Pattern(-8,false);
  end;

  cursor(false);
  Draw_Player_State(true);

  Clear_Keypress;
  pause := false;
end;

Procedure Start_Play_Pattern;
begin
  Mute_all;                             {Mute all output}
  fillchar(current,sizeof(current),0);  {Clear current event buffer}
  mainmenu := false;
  pause := false;

  old.pos    := player.position;
  old.patn   := player.pattern_num;
  old.xp     := GetX;
  old.row    := Editor.markedrow;

  patternplay := true;
  ptn.infoupdate := true; {signal to update the player info}
  player.row := 0;
  Clear_Keypress;
  pedit := false;

  CopyBuffer(buffer.blankscreen,buffer.screen1);

  if ptn.tracemode then
  begin
    Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,0,63);
    Draw_Pattern_Window(false);
    Draw_Editor_Window(false);
    Update_Pattern(Editor.markedrow-8,false);
  end;

  Draw_Player_State(true);
  cursor(false);
  Clear_Keypress;
end;

Procedure Start_Play_Cursor;
begin
  Mute_all;                             {Mute all output}
  fillchar(current,sizeof(current),0);  {Clear current event buffer}


  mainmenu := false;
  pause := false;

  player.row := Editor.markedrow;
  old.pos    := player.position;
  old.patn   := player.pattern_num;
  old.xp     := GetX;
  old.row    := Editor.markedrow;

  patternplay := false;
  ptn.infoupdate := true; {signal to update the player info}
  Clear_Keypress;
  pedit := false;

  CopyBuffer(buffer.blankscreen,buffer.screen1);

  if ptn.tracemode then
  begin
    Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,Editor.markedrow-8,63);
    Draw_Pattern_Window(false);
    Draw_Editor_Window(false);
    Update_Pattern(Editor.markedrow-8,false);
    Update_Order(false,true);
    CopyBuffer(buffer.screen1,buffer.oldscreen);
  end;

  cursor(false);
  Draw_Player_State(true);

  Clear_Keypress;
end;

Procedure Stop_Playing;
begin
  Clear_Keypress;

  pause := true;
  Mute_all;
  Player.Position := old.pos;
  Player.row := old.row;
  Player.pattern_num := old.patn;
  Editor.markedrow := old.row;
  CopyBuffer(buffer.blankscreen,buffer.screen1);

  Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,0,63);
  Draw_Pattern_Window(false);
  Draw_Editor_Window(false);
  mainmenu := false;
  Update_Pattern(Editor.markedrow-8,true);
  gotoxy(old.xp,14);
  pedit := true;
end;





end.
