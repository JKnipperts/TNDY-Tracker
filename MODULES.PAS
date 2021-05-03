{$G-,N-,E-}

{**************************************************************
 Modules.pas - Loading and saving songs

 Author: Jan Knipperts
 Program: TNDY-Tracker
 Version: 1.15

***************************************************************
}





Unit Modules;
interface
uses global,play,tndy,tracker,textmode,keyboard,PIT,IE;


Procedure Proceed_Errors;
Procedure Save_Song;
Procedure LoadTNDY(filename : string);

implementation


Procedure Proceed_Errors;
begin
if (error > 0) and (error < 6) then
begin
  CopyBuffer(buffer.blankscreen,buffer.screen2);
  writeto(buffer.screen2);

  box(10,7,70,12,palette.text_color1,palette.mark_color,false,true);
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
    centeredtext(9,palette.text_color1,palette.mark_color,'File is corrupted or no AGI 2.x music ressource!');
  end;
  5:
  begin
    centeredtext(9,palette.text_color1,palette.mark_color,'Not enough memory! ');
  end;
  end;

  centeredtext(10,palette.text_color1,palette.mark_color,'Press any key to continue.');

  displaybuffer(buffer.screen2);

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
  displaybuffer(buffer.screen1);
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

            dummy := $FF;                   {marker for empty row count}
            {$I-}
            blockwrite(f,dummy,1);
            blockwrite(f,erc,1);            {save number of empty rows}
            {$I+}

            if IOResult <> 0 then      {IO Error}
            begin
              error := 1;
              exit;
            end;
            erc := 0;
         end;


          if (tc < Editor.channels-1) then {normal voice data}
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

           dummy := $FF;                   {marker for empty row count}

           {$I-}
           blockwrite(f,dummy,1);
           blockwrite(f,erc,1);            {save number of empty rows}
           {$I+}

           {$I+}


           if IOResult <> 0 then      {IO Error}
           begin
             error := 1;
             exit;
           end;
          end;

        end;

    end; {row count}

  end; {track count}

 end; {pattern count}

end; {procedure}



Procedure Compress_Message;
var
 mc,pc  : word;
 nc,c   : word;
 oldc   : byte;


begin

 fillchar(p_msg,sizeof(p_msg),0);
 mc := 1;
 pc := 1;
 oldc := 1;
 repeat;
   if msg_buffer[mc] <> oldc then
   begin
    p_msg[pc] := msg_buffer[mc]; {put char in buffer}
    oldc  := msg_buffer[mc];  {save last charakter}
    inc(pc);
    inc(mc);
   end
   else
   begin

     nc := 1;

     repeat
      inc(nc);
      inc(mc);
     until (msg_buffer[mc] <> oldc) or
           (mc > 400);
     dec(nc);


     if nc = 399 then {empty description?}
     begin
       msg_size := 0;
       exit;
     end;

     if nc >= 2 then
     begin
       p_msg[pc] := 01;
       if nc > $FF then
       begin
         p_msg[pc+1] := $FF;
         p_msg[pc+2] := nc-$FF;
         inc(pc,3);
        end
        else
        begin
          p_msg[pc+1] := nc;
          inc(pc,2);
        end;
     end
     else
     begin
       for c := 0 to nc-1 do
       p_msg[pc+c] := oldc;
       inc(pc,nc);
     end;



    end;


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
    CopyBuffer(buffer.blankscreen,buffer.screen2);
    writeto(buffer.screen2);

    Box(16,7,64,12,palette.text_color1,palette.menu_color,false,true);
    centeredtext(7,palette.text_color2,palette.menu_color,' Warning! ');
    centeredtext(9,palette.text_color1,palette.menu_color,'File '+filename+' already exists!');
    centeredtext(10,palette.text_color1,palette.menu_color,'Overwrite it? Y/N');

    displaybuffer(buffer.screen2);

    Clear_Keypress;
    repeat
      if is_key_pressed then Get_Key;

      if (upcase(key_Ascii) = 'N') or (key_code = 1) then
      begin
       Clear_Keypress;
       writeto(buffer.screen1);
       displaybuffer(buffer.screen1);
       error := 6;
       exit;
      end;

    until (upcase(key_Ascii) = 'Y') or (upcase(key_Ascii) = 'Z') or (key_code = 27);
    Clear_Keypress;
    writeto(buffer.screen1);
    displaybuffer(buffer.screen1);
  end;





  Header.ID            := 'TNDY';
  Header.Version       := File_version;
  Header.Nchan	       := Editor.channels;
  Header.Length        := Player.Songlength;
  Header.loop          := Player.Loop;
  Header.NPatterns     := Player.MaxPattern+1;
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

 if msg_size > 0 then {only content will be saved}
 begin
   {$I-}
   blockwrite(f,p_msg,msg_size);
   {$I+}

   if IOResult <> 0 then      {IO Error}
   begin
     error := 1;
     close(f);
     exit;
   end;
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
  Box(20,7,60,12,15,1,false,true);
  centeredtext(7,palette.text_color2,palette.menu_color,' Save song ');
  centeredtext(9,palette.text_color1,palette.menu_color,' Please enter a filename:');
  HLine(34,10,12,15,0,' ');
  fastwrite(34,10,7,0,'.TND');
  ox := GetX;
  oy := GetY;
  x := 34;
  displaybuffer(buffer.screen2);

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
      displaybuffer(buffer.screen2);
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
      displaybuffer(buffer.screen2);
    end;

    if key_code = 28 then  {Enter}
    begin
      filename := filename+'.TND';
      SaveTNDY(filename);
      Proceed_Errors;
      Clear_Keypress;
      writeto(buffer.screen1);
      displaybuffer(buffer.screen1);
      gotoxy(ox,oy);
      change_cursor(0,7);
      cursor(false);
      exit;
    end;


   until key_code = 1;
   error := 6;
   Clear_Keypress;
   writeto(buffer.screen1);
   displaybuffer(buffer.screen1);
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

           inc(rc,(dummy-1));	{insert empty rows (-1 because we add 1 at the end of the loop)}
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


           patterns[pc]^[rc][tc].note := dummy shr 5; {Get frequency bit}
           patterns[pc]^[rc][tc].volume := (dummy and not $F0);

           asm
            mov  al,dummy
            mov  dummy,1
            test al,00010000b	{Get noise bit}
            jz   @1
            mov  dummy,2
            @1:
           end;


           patterns[pc]^[rc][tc].Octave := dummy; {Save noise bit +1}

           inc(patterns[pc]^[rc][tc].volume); {make it 1 to 16 in pattern}

          end;


       end;

        inc(rc);

    until rc >= 64;  {row count}

  end; {track count}

 end; {pattern count}

end; {procedure}


Procedure Uncompress_Message;
var
 mc,pc  : word;
 nc,c   : word;
 l,h,
 last	: byte;

begin
 fillchar(msg_buffer,sizeof(msg_buffer),0);
 mc := 1;
 pc := 1;
 repeat;

   if p_msg[pc] = 1 then {repeat last char}
   begin
    last := p_msg[pc-1];
    inc(pc);

    if header.version = 1 then {Of course the old format is still supported :)}
    begin
      last := 0;

      h := p_msg[pc];
      inc(pc);
      l := p_msg[pc];
      asm
       mov al,l
       mov ah,h
       mov nc,ax
      end;
    end
    else
    begin
      nc := p_msg[pc];

      if nc = $FF then
      begin
       inc(mc,255);
       inc(pc);
       nc := p_msg[pc];
      end;
    end;


    for c := 1 to nc do
    begin
      msg_buffer[mc] := last;
      inc(mc);
    end;
    inc(pc);

   end
   else
   begin
    msg_buffer[mc] := p_msg[pc];
    inc(mc);
    inc(pc);
   end;




  until pc > msg_size;
end;




Procedure LoadTNDY(filename : string);
begin
 if filename <> '' then
 begin
   error := 0;
   Clear_Pattern_Data;

   writeto(buffer.screen2);
   Box(16,8,64,12,palette.text_color1,palette.menu_color,false,true);
   centeredtext(10,palette.text_color1,palette.menu_color,'Please wait...');
   displaybuffer(buffer.screen2);

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


     if (header.id <> 'TNDY') or (header.version > File_version) then  {Not a valid TNDY file}
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

     if msg_size > 0 then
     begin
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
     end
     else
     fillchar(msg_buffer,sizeof(msg_buffer),0);


     if Header.Version = File_version then {Version 1 saved it -1}
     begin
       dec(Header.NPatterns);
     end;


     Player.loop 	:= header.loop;
     Editor.channels    := Header.Nchan;
     Player.Speed	:= header.Speed;
     Player.Songlength  := Header.Length;
     Player.MaxPattern  := Header.NPatterns;



     if header.tempo = 0 then
      Player.tempo := 18
     else
      Player.tempo := header.tempo;

     if Player.speed = 0 then Player.speed := 1; {Just to be save here...}

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

 set_timer(Player.tempo); {Reset timer to new tempo}

end
else
 error := 6; {Aborted by user}

end;








end.
