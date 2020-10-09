Program TNDY2AGI;
{Arpeggio noch nicht unterstütz}

uses crt;

type

  TNDYevent   	 = record       {Structure of an event}
     note        : byte;
     octave      : byte;
     volume      : byte;
     effect      : byte;
     ep        	 : byte;
  end;

  Comp_event   	 = record       {Structure of a compressed event}
    n_o          : byte;
    v_e          : byte;
    ep	       	 : byte;
  end;


  TNDYheader     = record       {Header structure of a TNDY file}
     ID          : array[1..4] of char;
     Version     : byte;
     NChan       : byte;
     length      : byte;
     loop        : byte;
     NPatterns   : byte;
     speed       : byte;
     tempo       : byte;
  end;

  TNDYPattern     = array[0..63] of array[0..4] of TNDYevent;
  TNDYpatPtr      = ^TNDYPattern;


 SNDNote    = record
  Duration      : word;
  Freq1,
  Freq2         : byte;
  Attenuation   : byte;
 end;




var
   f,f1           :   file;
   Patterns       : array[0..255]of TNDYpatptr; {Pointer to max. 256 ptterns}
   Order          : array[0..255] of byte;      {The order list}
   Header         : TNDYHeader;
   msg_size	  : word;
   dummy	  : word;
   error	  : byte;
   pos,row,chan   : byte;
   Note  	  : SNDNote;
   SND_offsets    : array[0..3] of word;


const
    tandyFreq      = 3579545;
    tandyDivider   = tandyFreq/32;
    tandyIntDivider= round(tandyDivider);
    minfreq        = 110;   {A2}
    maxfreq        = 14080; {A9}


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

Procedure Uncompress_Pattern_Data;
var pc,tc,rc,dummy  : byte;
    Cevent          : Comp_event;
begin
 for pc := 0 to Header.NPatterns do
 begin

   if maxavail < sizeof(TNDYPattern) then {Out of memory?}
   begin
     error := 5;
     exit;
   end;


   if patterns[pc] = nil then new(patterns[pc]);
   fillchar(patterns[pc]^,sizeof(TNDYPattern),0);


   for tc := 0 to Header.Nchan-1 do
   begin

    rc := 0;

    repeat;
        {$I-}
        blockread(f,dummy,1);
        {$I+}

         if IOResult <> 0 then      {IO Error}
         begin
           error := 1;
           exit;
         end;

        if dummy = $FF then
        begin
          {$I-}
           blockread(f,dummy,1);
          {$I+}

           if IOResult <> 0 then      {IO Error}
           begin
             error := 1;
             exit;
           end;

           inc(rc,(dummy-1));	{insert empty rows (-1 because we add 1 at the end of the loop)}
        end
        else
        begin

          seek(f,filepos(f)-1);  {go one byte back}

          fillchar(Cevent,sizeof(Cevent),0);

          if (tc <> Header.Nchan-1) then {normal voice data}
          begin
           {$I-}
             blockread(f,cevent,sizeof(cevent)); {Read normal event}
           {$I+}

           if IOResult <> 0 then      {IO Error}
           begin
             error := 1;
             exit;
           end;

           patterns[pc]^[rc][tc].note := Cevent.n_o shr 4;
           patterns[pc]^[rc][tc].Octave := Cevent.n_o and not $F0;
           patterns[pc]^[rc][tc].volume := (Cevent.v_e shr 4);
           patterns[pc]^[rc][tc].effect := Cevent.v_e and not $F0;
           patterns[pc]^[rc][tc].ep := Cevent.ep;

           if patterns[pc]^[rc][tc].note = 14 then  {Just an effect without volume or note}
           begin
            patterns[pc]^[rc][tc].note := 0;
            patterns[pc]^[rc][tc].Octave := 0;
            patterns[pc]^[rc][tc].volume := 0;
           end
           else
            inc(patterns[pc]^[rc][tc].volume); {make it 1 to 16 in pattern}


          end
          else
          begin
           {$I-}
             blockread(f,dummy,1); {Read noise data}
           {$I+}

           if IOResult <> 0 then      {IO Error}
           begin
             error := 1;
             exit;
           end;



           patterns[pc]^[rc][tc].Octave := dummy shr 4; {Get noise bit}
           patterns[pc]^[rc][tc].note := dummy shr 5; {Get frequency bit}
           patterns[pc]^[rc][tc].volume := (dummy and not $F0);
           inc(patterns[pc]^[rc][tc].Octave);

          end;


       end;

        inc(rc);

    until rc >= 64;  {Player.row count}

  end; {track count}

 end; {pattern count}

end; {procedure}


Procedure Set_Freq_Bytes(voice:byte; frequency :word);
var tone   : word;
begin
      if frequency > 0 then
       tone := tandyIntDivider div frequency;


      asm
	mov  cl,voice
	mov  al,$10
	shl  al,cl
	and  al,$60
	or   al,$80
	mov  bx,tone
	mov  ah,bl
	and  ah,$0F
	or   al,ah
	mov  note.freq2,al
	mov  cl,4
	shr  bx,cl
	mov  al,bl
	mov  note.freq1,al
      end;
end;

Procedure Set_Level_Byte(voice,level :byte);
begin
      asm
        mov  cl,voice
	mov  al,$10
	shl  al,cl
	and  al,$60
	or   al,$80
	mov  cl,al
       	mov  al,level
	and  al,$0F
	or   al,cl
	or   al,$10
	mov  note.Attenuation,al
      end;
end;


Procedure Set_noise_Byte(divider, feedback, level:byte);
begin
       asm
        xor  al,al
        mov  al,11100000b
        cmp  feedback,0
        je   @SkipFeedback
        or   al,4

        @SkipFeedback:
        or   al,divider
        mov  note.freq1,al

        xor  al,al
        mov  al,11110000b
        or   al,level
	mov  note.Attenuation,al
      end;
end;


Procedure Write_note;
begin
  if (note.freq1 >  0) or (note.freq2 > 0) or
     (note.duration > 0) then
  begin
    note.duration := round(note.duration * (1000/header.tempo)); {convert ticks to ms}
    note.duration := note.duration div 18; {one duration value is aprox. 18 ms}
    blockwrite(f,note,sizeof(note));
  end;
      fillchar(note,sizeof(note),0);
end;




Procedure Convert_Channel(channr : byte);
var pitch,finetune,limit : word;
    n,o,v,e,ep   : byte;
    nl,ol,vl,z,speed  : byte;

begin
  fillchar(note,sizeof(note),0);
  row := 0;
  pos := 0;
  pitch := 0;
  nl := 0;
  ol := 0;
  pos := 0;

 repeat;

  repeat;
    n := patterns[order[pos]]^[row][channr].note;
    o := patterns[order[pos]]^[row][channr].octave;
    v := patterns[order[pos]]^[row][channr].volume;
    e := patterns[order[pos]]^[row][channr].effect;
    ep:= patterns[order[pos]]^[row][channr].ep;

    if v > 0 then
    begin
      dec(v); {it's saved 1 to 16 in the pattern}

      if n = 0 then {new volume but no new note?}
      begin
        Write_note;

        {replay last note with new volume}
        if channr = 3 then {Noise}
          Set_noise_byte(nl,ol,v)
        else
        begin
          Set_freq_bytes(channr,pitch);
          Set_level_byte(channr,v);
        end;
        vl := v;
        note.duration := header.speed; {reset duration}
      end;

    end;



    if (e = $0A) and (ep > 0) and (chan < 3) then
    {Finetune effect, with valid parameter and not in the noise channel?}
    begin
      finetune := ep;

      if n = 0 then {We have a new value for finetune, but no new note}
      begin

        Write_note;

        {Calculate the frequency of the last note played on this channel}
         pitch := Note_frequencies[ol][nl];

         if finetune < $80 then
         begin
           pitch := pitch-finetune;
           if pitch < minfreq then
            pitch := minfreq
         end
         else
           pitch := pitch+(finetune-$80);


         Set_freq_bytes(channr,pitch);
         Set_level_byte(channr,vl);
         note.duration := header.speed; {reset duration}
      end;

    end
    else
     finetune := 0; {Clear last finetune value}




    if n in [1..13] then
    begin
      Write_note;


      if (e = 03) or (e = 05) then       {Does the note belong to a toneslide?}
      begin
        limit := Note_frequencies[o][n]; {Update toneslide}
        if ep > 0 then speed :=  ep;
      end
      else
      begin

        if channr = 3 then {Noise}
          Set_noise_byte(n,o,v)
        else
        begin
          pitch := Note_frequencies[o][n];
          if finetune < $80 then
          begin
            pitch := pitch-finetune;
            if pitch < minfreq then
            pitch := minfreq;
          end
          else
           pitch := pitch+(finetune-$80);

          Set_freq_bytes(channr,pitch);

         end;

          Set_level_byte(channr,v);
          note.duration := header.speed;

          nl := n;
          ol := o;
          vl := v;
        end;
    end;



     if (e = $01) then  {Portamento up}
     begin
       Write_note;
       for z := 1 to header.speed do
       begin
         pitch := pitch+ep;
         Set_freq_bytes(channr,pitch);
         Set_level_byte(channr,v);
         note.duration := 1;
         Write_note;
       end;
     end;


     if (e = $02) then {Portamento down}
     begin
       Write_note;
       for z := 1 to header.speed do
       begin
         if pitch-ep >= minfreq then
         begin
           pitch := pitch-ep;
           Set_freq_bytes(channr,pitch);
           Set_level_byte(channr,v);
           note.duration := 1;
           Write_note;
         end;
       end;
     end;

     if (e = $03) then  {Toneslide}
     begin
       Write_note;
       for z := 1 to header.speed do
       begin
         if pitch+speed <= limit then
         begin
           inc(pitch,speed);
           Set_freq_bytes(channr,pitch);
           Set_level_byte(channr,v);
           note.duration := 1;
           Write_note;
         end;
      end;
     end;


     if (e = $04) then  {Volume Slide}
     begin
       write_note;
       for z := 1 to header.speed do
       begin

         if ((ep and $F0) > 0 ) and ((ep and $0F) = 0) then {up}
         begin
           if round(v - ((ep shr 4) * 0.23)) > 0 then
              v := round(v - ((ep shr 4) * 0.23))
           else
              v := 0;
         end;

         if ((ep and $0F) > 0 ) and ((ep and $F0) = 0) then {down}
         begin
           if round(v + ((ep and $0F) * 0.23)) <= $F then
              v := v + round(v + ((ep and $0F) * 0.23))
           else
              v := $F;
         end;

         Set_freq_bytes(channr,pitch);
         Set_level_byte(channr,v);
         note.duration := header.speed;
         Write_note;
       end;
     end;


     if (e = $05) then {Tone and Volume Slide}
     begin
       write_note;
       for z := 1 to header.speed do
       begin
         {Calc next volume}
         if ((ep and $F0) > 0 ) and ((ep and $0F) = 0) then {up}
         begin
           if round(v - ((ep shr 4) * 0.23)) > 0 then
              v := round(v - ((ep shr 4) * 0.23))
           else
              v := 0;
         end;
         if ((ep and $0F) > 0 ) and ((ep and $F0) = 0) then {down}
         begin
           if round(v + ((ep and $0F) * 0.23)) <= $F then
              v := v + round(v + ((ep and $0F) * 0.23))
           else
              v := $F;
         end;

         {continue tone slide}
         if limit > pitch then
         begin
           if pitch+speed <= limit then
            inc(pitch,speed);
         end
         else
         begin
           if pitch-speed >= limit then
            dec(pitch,speed);
         end;

         Set_freq_bytes(channr,pitch);
         Set_level_byte(channr,v);
         note.duration := 1;
         Write_note;
       end;

     end;


     if (e = $0F)  then	{speed change}
     begin
      if ep >  0 then
      begin
        if ep < $1F then
          Header.speed := ep {Set new speed}
        else
          Header.tempo := ep;
      end
      else
       Header.tempo := 18; {18.2 Hz Mode}
     end;

     if (e = $0D)  then	{Pattern break}
     begin
       if Pos < Header.length-1 then
        break;
     end;

     if (e = $0B) then	{Position jump}
     begin
       if ep <= Header.length then
       begin
        Pos := ep-1;
        break;
       end;
     end;

    if (n = 0) and (v = 0) and (e = 0) then
    inc(note.duration,header.speed);


    inc(row);

   until row = 64;
   inc(pos);
   row := 0;

 until pos = header.length;

 pitch := $FFFF;
 blockwrite(f,pitch,2);
end;


Procedure Clear_Pattern_Data;
var c : byte;
begin
   for c := 0 to Header.NPatterns do			{Delete possible old pattern data}
    begin
      if patterns[c] <> nil then
      begin
       fillchar(patterns[c]^,sizeof(TNDYPattern),0);
       dispose(patterns[c]);
       patterns[c] := nil;
      end;
    end;
   new(patterns[0]);
   fillchar(patterns[0]^,sizeof(TNDYPattern),0);
end;







begin
   writeln('Reading delta.tnd');

   assign(f,'DELTA.TND');
   reset(f,1);
     blockread(f,header,sizeof(header));
     blockread(f,msg_size,sizeof(msg_size));
     seek(f,filepos(f)+msg_size);
     blockread(f,order,header.length);
     Clear_Pattern_Data;
     Uncompress_Pattern_Data;
   close(f);
   writeln('Speed: ',header.speed);
   writeln('Tempo: ',header.tempo);
   writeln('Patterns: ',header.npatterns);
   writeln('Length: ',header.length);
   writeln;
   writeln('Crating Delta.snd');
   assign(f,'DELTA.SND');
   rewrite(f,1);
     blockwrite(f,snd_offsets,sizeof(SND_offsets));
     SND_offsets[0] := filepos(f);
     Convert_Channel(0);
     SND_offsets[1] := filepos(f);
     Convert_Channel(1);
     SND_offsets[2] := filepos(f);
     Convert_Channel(2);
     SND_offsets[3] := filepos(f);
     Convert_Channel(3);
     seek(f,0);
     blockwrite(f,snd_offsets,sizeof(SND_offsets));
   close(f);
   Clear_Pattern_Data;
   dispose(patterns[0]);
end.





