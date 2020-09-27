{$G-,N-,E-}

{**************************************************************
 Modules.pas - Loading and saving songs
             - Import of MOD and SND files

 Author: Jan Knipperts
 Program: TNDY-Tracker
 Version: 1.11

***************************************************************
}





Unit Modules;
interface
uses global,play,tndy,tracker,textmode,keyboard,PIT;

Function  FileExist(name : string) : boolean;
Procedure Clear_Pattern_Data;
Procedure Proceed_Errors;
Procedure SaveTNDY(filename : string);
Procedure Save_Song;
Procedure LoadTNDY(filename : string);
Procedure Import_SND(filename : string);
Procedure Import_Mod(filename : string);

implementation




Function fileexist(name : string) : boolean;
var tf : file;
begin
 fileexist := true;
{$I-}
 assign(tf,name);
 reset(tf,1);
 close(tf);
{$I+}
 If IOResult <> 0 then fileexist := false;
end;


Procedure Clear_Pattern_Data;
var c : byte;
begin
   for c := 0 to Player.MaxPattern do			{Delete possible old pattern data}
    begin
      if patterns[c] <> nil then
      begin
       fillchar(patterns[c]^,sizeof(TNDYPattern),0);
       dispose(patterns[c]);
       patterns[c] := nil;
      end;
    end;
   Player.MaxPattern := 0;
   Player.Songlength := 1;
   Player.loop := 0;
   Player.Position := 0;
   Player.pattern_num := 0;
   Player.row := 0;
   Editor.chan := 1;
   fillchar(Player.arp,sizeof(Player.arp),0);
   fillchar(Player.tsl,sizeof(Player.tsl),0);
   fillchar(Player.onote,sizeof(Player.onote),0);
   fillchar(Player.ooct,sizeof(Player.ooct),0);
   fillchar(volume,sizeof(volume),0);
   fillchar(freq,sizeof(freq),0);
   new(patterns[0]);
   fillchar(patterns[0]^,sizeof(TNDYPattern),0);
end;






Procedure Proceed_Errors;
begin
if (error > 0) and (error < 6) then
begin
  move(buffer.blankscreen^,buffer.screen2^,4000);
  writeto(buffer.screen2);

  window(16,7,64,12,palette.text_color1,palette.mark_color,true);
  centeredtext(7,palette.text_color2,palette.mark_color,' Error! ');

  case error of
  1:
  begin
    centeredtext(9,palette.text_color1,palette.mark_color,'A disk error occured!');
  end;
  2:
  begin
    centeredtext(9,palette.text_color1,palette.mark_color,'File is corrupted or not a TNDY-Tracker module!');
  end;
  3:
  begin
    centeredtext(9,palette.text_color1,palette.mark_color,'File is corrupted or not a Protracker module!');
  end;
  4:
  begin
    centeredtext(9,palette.text_color1,palette.mark_color,'File is corrupted or no Sierra AGI 2.x music ressource!');
  end;
  5:
  begin
    centeredtext(9,palette.text_color1,palette.mark_color,'Not enough memory to load pattern data! ');
  end;
  end;

  centeredtext(10,palette.text_color1,palette.mark_color,'Press any key to continue.');

  viewbuffer(buffer.screen2);

  Wait_for_Keypress;

  Clear_Pattern_Data; {To make sure, there is no garbage loaded in our buffer}
  Player.tempo := 50; {Default Player.tempo is 50 Hz}
  Player.Speed := 6; {and a Player.Speed of 6 = 125 BPM}
  set_timer(50);
  Editor.orderview := -2;
  Editor.Octave := 4;
  Editor.chan := 1;
  Player.Position := 0;
  Player.row := 0;
  Editor.curr_vol := 0;
  Player.Songlength := 1;
  Player.MaxPattern := 0;
  fillchar(order,sizeof(order),0);
  fillchar(msg_buffer,sizeof(msg_buffer),0);
  msg_size := 0;
  Editor.channels := 4;




  writeto(buffer.screen1);
  viewbuffer(buffer.screen1);
end;
end;




Procedure Compress_Pattern_Data;
var pc,tc,rc,erc,dummy,cv : byte;
    Cevent   : Comp_event;
begin
 for pc := 0 to Player.MaxPattern do
 begin

   for tc := 0 to Editor.channels-1 do
   begin
    erc := 0;

    for rc := 0 to 63 do
    begin

        fillchar(Cevent,sizeof(Cevent),0);

        if (patterns[pc]^[rc][tc].note > 0) or
           (patterns[pc]^[rc][tc].Octave > 0) or
           (patterns[pc]^[rc][tc].volume > 0) or
           (patterns[pc]^[rc][tc].effect > 0) or
           (patterns[pc]^[rc][tc].ep > 0) then
        begin

          if (erc > 0) then
          begin

           dummy := $FF;                   {marker for empty Player.row count}
           {$I-}
           blockwrite(f,dummy,1);
           blockwrite(f,erc,1);            {save number of empty Player.rows}
           {$I+}

           if IOResult <> 0 then      {IO Error}
           begin
             error := 1;
             exit;
           end;
           erc := 0;
         end;


          if (tc <> Editor.channels-1) then {normal voice data}
          begin
            cv := patterns[pc]^[rc][tc].volume;

            if (cv = 0) and (patterns[pc]^[rc][tc].note = 0) then  {if there is no volume, set note to 14}
            Cevent.n_o := (14 shl 4) or patterns[pc]^[rc][tc].Octave
            else
            Cevent.n_o := (patterns[pc]^[rc][tc].note shl 4) or
                           patterns[pc]^[rc][tc].Octave; {if not, store the full information}

            if (cv > 0) then dec(cv);		{save volume as 0 to 15 in the file}

            Cevent.v_e := (cv shl 4) or patterns[pc]^[rc][tc].effect;
            Cevent.ep := patterns[pc]^[rc][tc].ep;

            {$I-}
             blockwrite(f,cevent,sizeof(cevent));
            {$I+}
          end
          else
          begin 	{Noise data}
            cv := patterns[pc]^[rc][tc].volume;
            if cv > 0 then dec(cv);  {correct volume}

            dummy := (patterns[pc]^[rc][tc].note shl 5) or cv;

            if (patterns[pc]^[rc][tc].Octave = 2) then
      	    dummy := dummy or $10;      {set  bit 4 for noise type: 0=Periodic, 1 = White noise}

            {$I-}
             blockwrite(f,dummy,1);
            {$I+}
          end;


          if IOResult <> 0 then      {IO Error}
          begin
            error := 1;
            exit;
          end;

        end
        else
        begin
          inc(erc);

          if (rc = 63) then  {complete track is empty}
          begin

           dummy := $FF;                   {marker for empty Player.row count}

           {$I-}
           blockwrite(f,dummy,1);
           blockwrite(f,erc,1);            {save number of empty Player.rows}
           {$I+}

           {$I+}


           if IOResult <> 0 then      {IO Error}
           begin
             error := 1;
             exit;
           end;
          end;

        end;

    end; {Player.row count}

  end; {track count}

 end; {pattern count}

end; {procedure}



Procedure Compress_Message;
var
 mc,pc  : word;
 nc,c   : word;


begin

 fillchar(p_msg,sizeof(p_msg),0);
 mc := 1;
 pc := 1;
 repeat;
   if msg_buffer[mc] > 0 then
   begin
    p_msg[pc] := msg_buffer[mc];
    inc(pc);
   end
   else
   begin

     nc := 1;
     while msg_buffer[mc] = 0 do
     begin
      inc(nc);
      inc(mc);
     end;
     dec(nc);
     dec(mc);

     if nc > 3 then
     begin
       p_msg[pc] := $01;
       p_msg[pc+1] := hi(nc);
       p_msg[pc+2] := lo(nc);
       inc(pc,3);
     end
     else
     begin
       for c := 0 to nc-1 do
       begin
        p_msg[pc+c] := 0;
       end;
       inc(pc,nc);
     end;
    end;

    inc(mc);

  until mc > 400;
  msg_size := pc;
end;





Procedure SaveTNDY(filename : string);
var
    ncount : byte;

begin

if filename <> '.TND' then
begin
  error := 0;

  if fileexist(filename) then
  begin
    move(buffer.blankscreen^,buffer.screen2^,4000);
    writeto(buffer.screen2);

    window(16,7,64,12,palette.text_color1,palette.menu_color,true);
    centeredtext(7,palette.text_color2,palette.menu_color,' Warning! ');
    centeredtext(9,palette.text_color1,palette.menu_color,'File '+filename+' already exists!');
    centeredtext(10,palette.text_color1,palette.menu_color,'Overwrite it? Y/N');

    viewbuffer(buffer.screen2);

    Clear_Keypress;
    repeat
      if is_key_pressed then Get_Key;

      if (upcase(key_Ascii) = 'N') or (key_code = 1) then
      begin
       Clear_Keypress;
       writeto(buffer.screen1);
       viewbuffer(buffer.screen1);
       error := 6;
       exit;
      end;

    until (upcase(key_Ascii) = 'Y') or (upcase(key_Ascii) = 'Z') or (key_code = 27);
    Clear_Keypress;
    writeto(buffer.screen1);
    viewbuffer(buffer.screen1);
  end;





  Header.ID            := 'TNDY';
  Header.Version       := 1;
  Header.Nchan	       := Editor.channels;
  Header.Length        := Player.Songlength;
  Header.loop          := Player.Loop;
  Header.NPatterns     := Player.MaxPattern;
  Header.Speed	       := Editor.D_Speed;

  if (Editor.d_tempo <= 18) then
   header.tempo := 0
  else
   header.tempo := editor.d_tempo;




{$I-}
 assign(f,filename);
 rewrite(f,1);
{$I+}

 if IOResult <> 0 then      {IO Error}
 begin
   error := 1;
   exit;
 end;

{$I-}
  blockwrite(f,header,sizeof(header));
{$I+}

 if IOResult <> 0 then      {IO Error}
 begin
   error := 1;
   close(f);
   exit;
 end;

 Compress_Message;

 {$I-}
  blockwrite(f,msg_size,2);
 {$I+}

 if IOResult <> 0 then      {IO Error}
 begin
   error := 1;
   close(f);
   exit;
 end;

{$I-}
  blockwrite(f,p_msg,msg_size);
{$I+}

 if IOResult <> 0 then      {IO Error}
 begin
   error := 1;
   close(f);
   exit;
 end;

{$I-}
  blockwrite(f,order,Player.Songlength);
{$I+}

 if IOResult <> 0 then      {IO Error}
 begin
   error := 1;
   close(f);
   exit;
 end;

  Compress_Pattern_Data;

 close(f);

end
else
 error := 6;

end;


Procedure Save_Song;
var x : byte;
begin
  move(buffer.blankscreen^,buffer.screen2^,4000);
  writeto(buffer.screen2);

  filename := '';
  window(20,7,60,12,15,1,true);
  centeredtext(7,palette.text_color2,palette.menu_color,' Save song ');
  centeredtext(9,palette.text_color1,palette.menu_color,' Please enter a filename:');
  HLine(34,10,12,15,0,' ');
  fastwrite(34,10,7,0,'.TND');
  ox := GetX;
  oy := GetY;
  x := 34;
  Viewbuffer(buffer.screen2);

  cursor(true);
  change_cursor(6,7);
  Clear_Keypress;


  repeat
    gotoxy(x,10);
    if is_key_pressed then Get_Key;

    if ((upcase(key_Ascii) in ['A'..'Z']) or (upcase(key_Ascii) in ['0'..'9'])) and (length(filename) < 8) then
    begin
      filename := filename+upcase(key_Ascii);
      fastwrite(34,10,15,0,filename);
      fastwrite(34+length(filename),10,7,0,'.TND');
      inc(x);
      Clear_Keypress;
      Viewbuffer(buffer.screen2);
    end;

    if key_code = 14 then {Backspace}
    begin
      if length(filename) > 0 then
      begin
        delete(filename,length(filename),1);
        HLine(34,10,12,15,0,' ');
        fastwrite(34,10,15,0,filename);
        fastwrite(34+length(filename),10,7,0,'.TND');
        dec(x);
      end;
      Clear_Keypress;
      Viewbuffer(buffer.screen2);
    end;

    if key_code = 28 then  {Enter}
    begin
      filename := filename+'.TND';
      SaveTNDY(filename);
      Proceed_Errors;
      Clear_Keypress;
      writeto(buffer.screen1);
      viewbuffer(buffer.screen1);
      gotoxy(ox,oy);
      change_cursor(0,7);
      cursor(false);
      exit;
    end;


   until key_code = 1;
   error := 6;
   Clear_Keypress;
   writeto(buffer.screen1);
   viewbuffer(buffer.screen1);
   gotoxy(ox,oy);
   change_cursor(0,7);
   cursor(false);
end;














Procedure Uncompress_Pattern_Data;
var pc,tc,rc,dummy  : byte;
    Cevent          : Comp_event;
begin
 for pc := 0 to Player.MaxPattern do
 begin

   if maxavail < sizeof(TNDYPattern) then {Out of memory?}
   begin
     error := 5;
     exit;
   end;


   if patterns[pc] = nil then new(patterns[pc]);
   fillchar(patterns[pc]^,sizeof(TNDYPattern),0);


   for tc := 0 to Editor.channels-1 do
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

           inc(rc,(dummy-1));	{insert empty Player.rows (-1 because we add 1 at the end of the Player.loop)}
        end
        else
        begin

          seek(f,filepos(f)-1);  {go one byte back}

          fillchar(Cevent,sizeof(Cevent),0);

          if (tc <> Editor.channels-1) then {normal voice data}
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


Procedure Uncompress_Message;
var
 mc,pc  : word;
 nc,c   : word;
 l,h	: byte;

begin
 fillchar(msg_buffer,sizeof(msg_buffer),0);
 mc := 1;
 pc := 1;
 repeat;
   if p_msg[pc] <> 1 then
   begin
    msg_buffer[mc] := p_msg[pc];
    inc(mc);
   end
   else
   begin
    inc(pc);
    nc := 0;
    h := p_msg[pc];
    inc(pc);
    l := p_msg[pc];

    asm
     mov al,l
     mov ah,h
     mov nc,ax
    end;

    for c := 1 to nc do
    begin
      msg_buffer[mc] := 0;
      inc(mc);
    end;
   end;

   inc(pc);
  until pc > msg_size;
end;





Procedure LoadTNDY(filename : string);
begin
 if filename <> '' then
 begin
   error := 0;
   Clear_Pattern_Data;

   assign(f,filename);
   {$I-}
   reset(f,1);
   {$I+}

     if IOResult <> 0 then      {IO Error}
     begin
      error := 1;
      exit;
     end;

     if filesize(f) < sizeof(header) then {File corrput}
     begin
      close(f);
      error := 2;
      exit;
     end;

     {$I-}
     blockread(f,header,sizeof(header));
     {$I+}

     if IOResult <> 0 then      {IO Error}
     begin
      error := 1;
      exit;
     end;

     if header.id <> 'TNDY' then  {Not a TNDY file}
     begin
      error := 2;
      close(f);
      exit;
     end;


     {$I-}
      blockread(f,msg_size,2);
     {$I+}
      if IOResult <> 0 then      {IO Error}
      begin
       error := 1;
       close(f);
       exit;
      end;

     if filesize(f) <= (sizeof(header)+(msg_size+2)+header.length+
        (header.nchan*2)) then  {Not a TNDY file or currupted?}
     begin
      error := 2;
      close(f);
      exit;
     end;




     {$I-}
     blockread(f,p_msg,msg_size);
     {$I+}
      if IOResult <> 0 then      {IO Error}
      begin
       error := 1;
       close(f);
       exit;
      end;


     Uncompress_Message;


     Player.Songlength := Header.Length;
     Player.loop 	:= header.loop;
     Editor.channels    := Header.Nchan;
     Player.MaxPattern  := Header.NPatterns;
     Player.Speed	:= header.Speed;

     if header.tempo = 0 then
      Player.tempo := 18
     else
      Player.tempo := header.tempo;


     {$I-}
     blockread(f,order,Player.Songlength);
     {$I+}

     if IOResult <> 0 then      {IO Error}
     begin
      error := 1;
      close(f);
      exit;
     end;


     for z := 0 to Player.Songlength-1 do
     begin
      if order[z] > Player.MaxPattern then	{is there a invalid pattern number in the order list?}
      begin
       error := 2;
       close(f);
       exit;
      end;
    end;


   uncompress_pattern_data; {decrunsh pattern data}

 close(f);
 if Editor.channels = 4 then Player.muted[4] := true;
end
else
 error := 6; {Aborted by user}

end;


Procedure Import_SND(filename : string);
type
 SNDHeader = record
  Offset        : array[0..3] of word;
 end;

 SNDNote    = record
  Duration      : word;
  Freq1, Freq2  : byte;
  Attenuation   : byte;
 end;


 var
   f            : file;
   Header       : SNDHeader;
   Note         : SNDNote;
   i		: byte;
   time,r       : real;
   Endpos       : array[0..3] of word;
   orig_freq,
   note_freq	: word;
   n,o 		: byte;
   d,nt		: byte;
   c		: word;


begin
 if filename <> '' then
 begin

   writeto(buffer.screen2);
   window(16,7,64,12,palette.text_color1,palette.menu_color,true);
   centeredtext(9,palette.text_color1,palette.menu_color,'Loading Sierra AGI game music.');
   centeredtext(10,palette.text_color1,palette.menu_color,'Please wait...');
   viewbuffer(buffer.screen2);

   error := 0;
   Clear_Pattern_Data;

   assign(f,filename);
   {$I-}
   reset(f,1);
   {$I+}
   if IOResult <> 0 then      {IO Error}
   begin
    error := 1;
    exit;
   end;

   if filesize(f) < sizeof(header) then
   begin
    close(f);
    error := 4;
    exit;
   end;

   {$I-}
   blockread(f,Header,sizeof(Header));
   {$I+}

   If IOResult <> 0 then
   begin
    close(f);
    error := 1;
    exit;
   end;

   if (Header.Offset[0] > filesize(f)) or
       (Header.Offset[0] > Header.Offset[1]) or
       (Header.Offset[1] > filesize(f)) or
       (Header.Offset[1] > Header.Offset[2]) or
       (Header.Offset[2] > filesize(f)) or
       (Header.Offset[2] > Header.Offset[3]) or
       (Header.Offset[3] > filesize(f)) then
    begin
      close(f);
      error := 4;
      exit;
    end;



    Player.MaxPattern := 0;


    if patterns[0] = nil then new(patterns[0]);

    Endpos[0] := Header.Offset[1];
    Endpos[1] := Header.Offset[2];
    Endpos[2] := Header.Offset[3];
    Endpos[3] := filesize(f);

    for Editor.chan := 0 to 3 do
    begin

      seek(f,Header.Offset[Editor.chan]);                      {Go to start of track}

      Player.Position := 0;
      Player.row := 0;
      r := 0;

      while filepos(f) < Endpos[Editor.chan]-2 do		{Read complete track.
      							 Endpos-2 is because each voice's data section is usually terminated by two consecutive 0xFF codes}
      begin

        {$I-}
        blockread(f,Note,sizeof(SNDNote));		{Read Note data}
        {$I+}

        If IOResult <> 0 then				{Disk error?}
        begin
         close(f);
         error := 1;
         exit;
        end;


        Note.Attenuation := (Note.Attenuation and not $F0);    {get attenuation nibble}

        patterns[Player.Position]^[Player.row][Editor.chan].volume :=
        Note.Attenuation+1; {we save the volume as 1 to 16 in our pattern...}

        if Editor.chan < 3 then						{Normal note}
        begin

          orig_freq := Tone_to_Freq(Note.Freq1,Note.Freq2); {Convert tone command to a valid Frequency}
          Freq_to_Note(orig_freq,n,o);			    {Convert it to nearest note value}
          patterns[Player.Position]^[Player.row][Editor.chan].note := n;  	    {save it in pattern}
          patterns[Player.Position]^[Player.row][Editor.chan].Octave := o;
          note_freq := Note_to_Freq(n,o);		    {Get the frequency of this note}


          if (note_freq <> orig_freq) and (snd.correct = true) then
           {Use Finetune effect to correct deviations between the frequencies}
          begin

            if note_freq > orig_freq then
            begin
              patterns[Player.Position]^[Player.row][Editor.chan].effect := $0A;	{Finetune}
              patterns[Player.Position]^[Player.row][Editor.chan].ep := note_freq-orig_freq;
              if patterns[Player.Position]^[Player.row][Editor.chan].ep > $7F then
              patterns[Player.Position]^[Player.row][Editor.chan].ep := $7F;
            end;

            if note_freq < orig_freq then
            begin
              patterns[Player.Position]^[Player.row][Editor.chan].effect := $0A;	{Finetune}
              patterns[Player.Position]^[Player.row][Editor.chan].ep := orig_freq-note_freq;
              if patterns[Player.Position]^[Player.row][Editor.chan].ep > $7F then
              patterns[Player.Position]^[Player.row][Editor.chan].ep := $7F;
              inc(patterns[Player.Position]^[Player.row][Editor.chan].ep,$80);
           end;

          end;


        end
        else
        begin							{Noise}
          Note.Freq2 := Note.Freq2 and 7; {we are only interested in the lowest three bits}

          d := Note.Freq2 and not 4; {Kill bit 2 and get value for the frequency divider}
          nt := Note.Freq2 shr 2;  {Get bit 2 and the value for feedback / noise type}


          Note.Attenuation := (Note.Attenuation and not $F0);    {get attenuation value}
          patterns[Player.Position]^[Player.row][Editor.chan].volume :=
          Note.Attenuation+1; {we save the volume as 1 to 16 in our pattern...}

          case d of
            0: patterns[Player.Position]^[Player.row][Editor.chan].Octave := 2;  {Periodic noise}
            1: patterns[Player.Position]^[Player.row][Editor.chan].Octave := 1;  {White noise}
          end;

          case nt of
             0 : patterns[Player.Position]^[Player.row][Editor.chan].note := 3;
             1 : patterns[Player.Position]^[Player.row][Editor.chan].note := 2;
             2 : patterns[Player.Position]^[Player.row][Editor.chan].note := 1;
             3 : patterns[Player.Position]^[Player.row][Editor.chan].note := 4;
          end;

          if (note.attenuation = $F) and (d = 0) and (nt = 0) then
          begin
           patterns[Player.Position]^[Player.row][Editor.chan].note := 13;
           patterns[Player.Position]^[Player.row][Editor.chan].Octave := 0;
          end;
        end;



        r := 1000 / SND.tempo;  {tick duration in ms}
        r := SND.Speed*r;	{Player.row duration in ms}

        {Number of empty Player.rows to add after the note}
        time := (Note.Duration*SND.Delay) / r;




        for c := 1 to round(time) do
        begin

          inc(Player.row);

          if Player.row > 63 then
          begin
           Player.row := 0;
           if Player.Position < 255 then
            inc(Player.Position)
           else
            break;

           if (Player.Position > Player.MaxPattern) then
           begin

             if maxavail < sizeof(TNDYPattern) then {Out of memory?}
             begin
              close(f);
              error := 5;
              exit;
             end;

            order[Player.Position] := Player.Position;
            if patterns[Player.Position] = nil then new(patterns[Player.Position]);					{create new empty pattern}
            fillchar(patterns[Player.Position]^,sizeof(TNDYPattern),0);
            Player.MaxPattern := Player.Position;
           end;

         end;
        end;

        {keyoff after the duration has expired, may be overwritten by the next note}
        patterns[Player.Position]^[Player.row][Editor.chan].note := 13;



     end; {while}
     end; {for}
     close(f);

     fillchar(order,sizeof(order),0);
     for i := 0 to Player.MaxPattern do
     begin
      order[i] := i;
     end;

     Player.Songlength := Player.MaxPattern+1;
     Player.loop := 0;
     Player.Position := 0;
     Player.pattern_num := 0;
     Player.row := 0;
     Editor.chan := 1;

     Player.Speed := SND.Speed;						{Default timing for AGI Music}
     Player.tempo := SND.tempo;
     set_timer(Player.tempo); {Reset timer to new tepo}
     fillchar(msg_buffer,sizeof(msg_buffer),0);	{There is no title string or other info in AGI files :(}
     msg_size := 0;
     Editor.channels := 4;
     Player.muted[4] := true;
   end
   else
    error := 6; {Aborted by  user}


 end;




Procedure Import_Mod(filename : string);

const
 MOD_Octaves : array[1..60] of word =
     (1712,1616,1525,1440,1357,1281,1209,1141,1077,1017,0961,0907,  {Oct 0}
      0856,0808,0762,0720,0678,0640,0604,0570,0538,0508,0480,0453,
      0428,0404,0381,0360,0339,0320,0302,0285,0269,0254,0240,0226,
      0214,0202,0190,0180,0170,0160,0151,0143,0135,0127,0120,0113,
      0107,0101,0095,0090,0085,0080,0076,0071,0067,0064,0060,0057); {Oct 4}

type
 MOD_Sampleinfo = record
  Samplename	: array[1..22] of char;
  Samplelength	: word;
  finetune	: byte;
  Volume	: byte;
  Rpoint	: word;
  Rlength	: word;
 end;

var modid     : array[1..4] of char;
    p         : modpattern;
    ncount    : byte;
    period    : word;
    v         : real;
    I_volumes : array[1..31] of byte;
    sinfo     : MOD_Sampleinfo;
    snum      : byte;
    c         : byte;
    mod_title : array[1..20] of byte;



function toword(l,h : byte): word;    {Converts Motorola to Intel Byteorder}
assembler;
asm
  mov al,l
  mov ah,h
end;


begin
 if filename <> '' then
 begin
   Clear_Pattern_Data;

   writeto(buffer.screen2);
   window(16,7,64,12,palette.text_color1,palette.menu_color,true);
   centeredtext(9,palette.text_color1,palette.menu_color,'Loading and converting Amiga Module.');
   centeredtext(10,palette.text_color1,palette.menu_color,'Please wait...');
   viewbuffer(buffer.screen2);

   error := 0;

   assign(f,filename);
   {$I-}
   reset(f,1);
   {$I+}
     if IOResult <> 0 then      {IO Error}
     begin
      error := 1;
      exit;
     end;

   if filesize(f) < (1086+sizeof(MODPattern)) then
   begin
    close(f);
    error := 3;
    exit;
   end;


   seek(f,1080);
   blockread(f,Modid,4);

   if (modid <> 'M.K.') and (modid <> '4CHN') then
   begin
    close(f);
    error := 3;
    exit;
   end;


   {What to do with the 4th Editor.channel?}
   case MODimp.ch4 of
    1: begin		{import as noise Editor.channel}
        Editor.channels := 4;
        c := 3;
       end;
    2: begin		{import as PC Speaker Editor.channel}
        Editor.channels := 5;
        c := 3;
       end;
    3: begin		{don't import it}
        Editor.channels := 4;
        c := 2;
       end;
   end;




   fillchar(mod_title,20,0);
   seek(f,0);		{Back to the beginning}
   blockread(f,mod_title,20); {Read title}


   fillchar(msg_buffer,sizeof(msg_buffer),0);
   msg_size := 0;

   for ncount := 1 to 20 do
   begin
    if mod_title[ncount] > 0 then
    begin
     msg_buffer[ncount] := mod_title[ncount];
     inc(msg_size);
    end;
   end;


   seek(f,20);		{Back to the sample infos}

   fillchar(I_volumes, sizeof(I_volumes),0);
   for ncount := 1 to 31 do                      {Proceed Sample infos}
   begin
    blockread(f,sinfo,sizeof(sinfo));
    I_volumes[ncount] := sinfo.volume;           {get instrument volume}
   end;



   seek(f,950);
   blockread(f,Player.Songlength,1);
   if Player.Songlength = 0 then Player.Songlength := 1;

   blockread(f,Player.loop,1);
   if Player.loop = $7F then Player.loop := 0;

   blockread(f,order,128);

   for i := 0 to 127 do
   if order[i] > Player.MaxPattern then Player.MaxPattern := order[i];  {determine number of patterns}

   if maxavail < ((Player.MaxPattern+1)*sizeof(TNDYPattern)) then {Out of memory?}
   begin
     close(f);
     error := 5;
     exit;
   end;


  seek(f,1084);  {Skip ID}

  for Player.Position := 0 to Player.MaxPattern do
  begin

    fillchar(p,sizeof(modpattern),0);
    {$I-}
     blockread(f,p,64*16);
    {$I+}

    if IOResult <> 0 then      {IO Error}
    begin
      error := 1;
      close(f);
      exit;
     end;


    if patterns[Player.Position] = nil then new(patterns[Player.Position]);
    fillchar(patterns[Player.Position]^,sizeof(TNDYPattern),0);

    for Player.row := 0 to 63 do
    begin

     for Editor.chan := 0 to c do
     begin
      period   := toword(p[Player.row][4*Editor.chan+1],(p[Player.row][4*Editor.chan+0] and $0F));      {sample period}
      patterns[Player.Position]^[Player.row][Editor.chan].effect :=
      p[Player.row][4*Editor.chan+2] and $0F;         {effect number}
      patterns[Player.Position]^[Player.row][Editor.chan].ep     :=
      p[Player.row][4*Editor.chan+3];                 {effect argument}
      snum     := (p[Player.row][4*Editor.chan+0] and $F0)+p[Player.row][4*Editor.chan+2] shr 4;  	    {sample number}

      if snum in [1..31] then
      begin
         if MODimp.volscale = 1 then
         begin
          case I_volumes[snum] of				{direct scaling}
              61..64: patterns[Player.Position]^[Player.row][Editor.chan].volume := 0;
              57..60: patterns[Player.Position]^[Player.row][Editor.chan].volume := 1;
              53..56: patterns[Player.Position]^[Player.row][Editor.chan].volume := 2;
              49..52: patterns[Player.Position]^[Player.row][Editor.chan].volume := 3;
              45..48: patterns[Player.Position]^[Player.row][Editor.chan].volume := 4;
              41..44: patterns[Player.Position]^[Player.row][Editor.chan].volume := 5;
              37..40: patterns[Player.Position]^[Player.row][Editor.chan].volume := 6;
              33..36: patterns[Player.Position]^[Player.row][Editor.chan].volume := 7;
              29..32: patterns[Player.Position]^[Player.row][Editor.chan].volume := 8;
              25..28: patterns[Player.Position]^[Player.row][Editor.chan].volume := 9;
              21..24: patterns[Player.Position]^[Player.row][Editor.chan].volume := 10;
              17..20: patterns[Player.Position]^[Player.row][Editor.chan].volume := 11;
              13..16: patterns[Player.Position]^[Player.row][Editor.chan].volume := 12;
              09..12: patterns[Player.Position]^[Player.row][Editor.chan].volume := 13;
              01..08: patterns[Player.Position]^[Player.row][Editor.chan].volume := 14;
                   0: patterns[Player.Position]^[Player.row][Editor.chan].volume := 15;
          end;
         end
         else
         begin
          case I_volumes[snum] of				{scale by db value}
            52..64: patterns[Player.Position]^[Player.row][Editor.chan].volume := 0;   {0..-2 db = full volume}
            40..51: patterns[Player.Position]^[Player.row][Editor.chan].volume := 1;   {-2..-4 db = -2 db on Tandy}
            26..40: patterns[Player.Position]^[Player.row][Editor.chan].volume := 2;   {-4..-8 db = -4 db}
            10..25: patterns[Player.Position]^[Player.row][Editor.chan].volume := 4;   {-8..-16 db = - 8db}
             1..10: patterns[Player.Position]^[Player.row][Editor.chan].volume := 8;   {-16..-36 db = -16 db}
                 0: patterns[Player.Position]^[Player.row][Editor.chan].volume := 15;  {0 (minus inf.) = mute}
       	  end;
       	 end;

        inc(patterns[Player.Position]^[Player.row][Editor.chan].volume); {we store it 1 to 16}
      end;


      case patterns[Player.Position]^[Player.row][Editor.chan].effect of

        4,6,7,8,9,$D:     {not supported MOD effects}
        begin
         patterns[Player.Position]^[Player.row][Editor.chan].effect := 0;
         patterns[Player.Position]^[Player.row][Editor.chan].ep := 0;
        end;

        $5:
        begin
         patterns[Player.Position]^[Player.row][Editor.chan].effect := 5;
         patterns[Player.Position]^[Player.row][Editor.chan].ep := 1;
         {round(patterns[Player.Position]^[Player.row][Editor.chan].ep / 4);}
        end;


        $A:
        begin
         patterns[Player.Position]^[Player.row][Editor.chan].effect := 4;
         patterns[Player.Position]^[Player.row][Editor.chan].ep := 1;
         {round(patterns[Player.Position]^[Player.row][Editor.chan].ep / 4);  }
        end;


        $C:
        begin

         if MODimp.volscale = 1 then
         begin
          case patterns[Player.Position]^[Player.row][Editor.chan].ep of				{direct scaling}
              61..64: patterns[Player.Position]^[Player.row][Editor.chan].volume := 0;
              57..60: patterns[Player.Position]^[Player.row][Editor.chan].volume := 1;
              53..56: patterns[Player.Position]^[Player.row][Editor.chan].volume := 2;
              49..52: patterns[Player.Position]^[Player.row][Editor.chan].volume := 3;
              45..48: patterns[Player.Position]^[Player.row][Editor.chan].volume := 4;
              41..44: patterns[Player.Position]^[Player.row][Editor.chan].volume := 5;
              37..40: patterns[Player.Position]^[Player.row][Editor.chan].volume := 6;
              33..36: patterns[Player.Position]^[Player.row][Editor.chan].volume := 7;
              29..32: patterns[Player.Position]^[Player.row][Editor.chan].volume := 8;
              25..28: patterns[Player.Position]^[Player.row][Editor.chan].volume := 9;
              21..24: patterns[Player.Position]^[Player.row][Editor.chan].volume := 10;
              17..20: patterns[Player.Position]^[Player.row][Editor.chan].volume := 11;
              13..16: patterns[Player.Position]^[Player.row][Editor.chan].volume := 12;
              09..12: patterns[Player.Position]^[Player.row][Editor.chan].volume := 13;
              01..08: patterns[Player.Position]^[Player.row][Editor.chan].volume := 14;
                   0: patterns[Player.Position]^[Player.row][Editor.chan].volume := 15;
          end;
         end
         else
         begin
          case patterns[Player.Position]^[Player.row][Editor.chan].ep of				{scale by db value}
            52..64: patterns[Player.Position]^[Player.row][Editor.chan].volume := 0;   {0..-2 db = full volume}
            40..51: patterns[Player.Position]^[Player.row][Editor.chan].volume := 1;   {-2..-4 db = -2 db on Tandy}
            26..40: patterns[Player.Position]^[Player.row][Editor.chan].volume := 2;   {-4..-8 db = -4 db}
            10..25: patterns[Player.Position]^[Player.row][Editor.chan].volume := 4;   {-8..-16 db = - 8db}
             1..10: patterns[Player.Position]^[Player.row][Editor.chan].volume := 8;   {-16..-36 db = -16 db}
                 0: patterns[Player.Position]^[Player.row][Editor.chan].volume := 15;  {0 (minus inf.) = mute}
       	  end;
       	 end;

         patterns[Player.Position]^[Player.row][Editor.chan].ep := 0;
         patterns[Player.Position]^[Player.row][Editor.chan].effect := 0;
         inc(patterns[Player.Position]^[Player.row][Editor.chan].volume); {we store it 1 to 16}
        end;

        $E:
        begin
         case (patterns[Player.Position]^[Player.row][Editor.chan].ep shr 4) of
         1:
         begin
          patterns[Player.Position]^[Player.row][Editor.chan].effect := $A;
          patterns[Player.Position]^[Player.row][Editor.chan].ep :=
          $80+(patterns[Player.Position]^[Player.row][Editor.chan].ep shr 4);
         end;
         2:
         if (patterns[Player.Position]^[Player.row][Editor.chan].ep) in [2,5] then
         begin
          patterns[Player.Position]^[Player.row][Editor.chan].effect := $A;
          patterns[Player.Position]^[Player.row][Editor.chan].ep :=
          (patterns[Player.Position]^[Player.row][Editor.chan].ep and $0F);
         end;
        else
        begin
          patterns[Player.Position]^[Player.row][Editor.chan].effect := 0;
          patterns[Player.Position]^[Player.row][Editor.chan].ep := 0;
        end;

        end;
      end;

    end;
      ncount := 1;

      if period = 0 then
      begin
        ncount := 61;
        patterns[Player.Position]^[Player.row][Editor.chan].Octave := 0;
      end;

      while (NCount <= 60) do
      begin
       If (period = MOD_Octaves[NCount]) then
       begin
         dec(Ncount);
         patterns[Player.Position]^[Player.row][Editor.chan].Octave := (NCount div 12)+1;
         patterns[Player.Position]^[Player.row][Editor.chan].note   := (NCount-(NCount DIV 12)*12)+1;

         {Lowest Player.Positionsible tandy note is A-2...}
         if (Editor.chan < 3) then {except for pc speaker or noise...}
         begin
          if patterns[Player.Position]^[Player.row][Editor.chan].Octave < 2 then
          patterns[Player.Position]^[Player.row][Editor.chan].Octave := 2;
          if (patterns[Player.Position]^[Player.row][Editor.chan].Octave = 2) and
          (patterns[Player.Position]^[Player.row][Editor.chan].note > 10) then
          patterns[Player.Position]^[Player.row][Editor.chan].note := 10;
         end;


         NCount := 61;
       end;
       inc(Ncount);
      end;

     end; {chan}
    end; {row}
  end;  {position}

 close(f);

 Player.row := 0;
 Player.Position := 0;
 Player.pattern_num := 0;
 Editor.chan := 1;



 Player.Speed := MODimp.Speed;	 {Set timing for AMIGA Mods}
 Player.tempo := MODimp.tempo;
 set_timer(Player.tempo); {Reset timer to new tepo}

 if Editor.channels = 5 then
 begin
  Player.muted[4] := false;
 end
 else
 begin
  Player.muted[4] := true;
 end;

 writeto(buffer.screen1);
 Draw_Pattern_View(false);	{Update screen since the number of channels may have changed...}
 Draw_Pattern_Editor(true);

 end {no filename}
 else
    error := 6; {Aborted by  user}
end;


end.
