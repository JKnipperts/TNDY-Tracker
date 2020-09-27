{$G-,N-,E-}

{**************************************************************
 Menu.pas - Procedures for displaying the menus
          - Control of additional options

 Author: Jan Knipperts
 Program: TNDY-Tracker
 Version: 1.11

***************************************************************
}




 Unit Menu;
 interface
 uses global,PIT,tndy,keyboard,textmode;

 Procedure Mark(x,y,l : byte);
 Procedure UnMark(x,y,l,col : byte);
 Procedure MDA_Mark(x,y,l : byte); {Special Marker function for monochrome display}
 Procedure DrawMenu(mnr : byte);

 Procedure Edit_Message;
 Procedure Timing_Config;
 Procedure Swap_Tracks(from_track, to_track : byte; whole_song : boolean);
 Procedure Swap_Tracks_Menu;
 Procedure Output_Config;
 Procedure SND_Import_Config;
 Procedure MOD_Import_Config;



 const

 Menu_Title   : array[1..6] of string =
                ('File',
                 'Play',
                 'Edit',
                 'Config',
                 'Help',
                 'Quit');

 Menu_Text    : array[1..6] of array[1..5] of string = (
                 ('New Song',
                  'Load Song',
                  'Save Song',
                  'Import MOD',
                  'Import SND'),

                ('Play Song',
                 'Play Pattern',
                 'Play from Cursor',
                 'Stop',
                 ''),

                ('PC Speaker channel on/off',
                 'Edit song description',
                 'Change default timing',
                 'Swap tracks',
                 ''),

                ('Output device',
                 'AGI music import',
                 'MOD import',
                 '',
                 ''),

                ('Keys',
                 'Effects',
                 'About',
                 '',
                 ''),


                ('Quit to DOS',
                 '',
                 '',
                 '',
                 ''));

 Menu_Size       : array[1..6] of byte =
                (5,4,4,3,3,1);
 Menu_Pos       : array[1..6] of byte =
                (17,25,33,41,51,59);



 implementation


 Procedure Mark(x,y,l : byte);
 var c : byte;
 begin
    for c := x to x+(l-1) do
    begin
      if VidSeg = $B800 then changeattr(c,y,atr(palette.text_color2,palette.mark_color,false))
      else
      AttrMDA(c,y,true,false,true);
    end;
 end;

 Procedure UnMark(x,y,l,col : byte);
 var c : byte;
 begin
    for c := x to x+(l-1) do
    begin
      if VidSeg = $B800 then changeattr(c,y,atr(col,palette.menu_color,false))
      else
      AttrMDA(c,y,false,false,false);
    end;
 end;


 Procedure MDA_Mark(x,y,l : byte); {Special Marker function for monochrome display}
 var c : byte;
 begin
    for c := x to x+(l-1) do
    begin
      if VidSeg <> $B800 then
      AttrMDA(c,y,true,false,true);
    end;
 end;


 {============ Drawing a menu page ==============}


 Procedure DrawMenu(mnr : byte);
 var i,s : byte;
 begin
  Mark(Menu_pos[mnr],1,length(menu_title[mnr]));
  s := 0;
  for i := 1 to Menu_size[mnr] do
   if Length(menu_text[mnr][i]) > s then s := Length(menu_text[mnr][i]);
  box(Menu_pos[mnr],2,Menu_pos[mnr]+s+3,3+Menu_size[mnr],palette.text_color1,palette.menu_color,true);
  for i := 1 to Menu_size[mnr] do
  begin
   fastwrite(Menu_pos[mnr]+1,2+i,palette.text_color1,palette.menu_color,menu_text[mnr][i]);
  end;
  Mark(Menu_pos[mnr]+1,3,length(menu_text[mnr][1]));
  active_menu := mnr;
  select      := 1;
 end;







{============ The editor for the song description ==============}

 Procedure Edit_Message;
 var
     ox,oy,x,y : byte;
     posi      : word;

 const
  min_x : byte = 21;
  min_y : byte = 5;
  max_x : byte = 60;
  max_y : byte = 14;



 Procedure Print_Message;
 var x,y  : byte;
     posi : word;
 begin
   x  := min_x;
   y  := min_Y;

   for posi := 1 to 400 do
   begin
     if msg_buffer[posi] > $20 then
      fastwrite(x,y,15,0,chr(msg_buffer[posi]));

     inc(x);

     if (x > max_X) then
     begin
       x := min_x;
       inc(y);
     end;

   end;

 end;



 begin
   move(buffer.screen1^,buffer.screen2^,4000);
   move(buffer.blankscreen^,buffer.screen1^,4000);
   writeto(buffer.screen1);

   window(19,4,62,15,15,1,true);
   centeredtext(4,palette.text_color2,palette.menu_color,' Description Editor: ');
   ox := GetX;
   oy := GetY;


   block(21,5,60,14,15,0);

   Print_Message;

   ox := getX;
   oy := getY;
   x  := min_x;
   y  := min_y;
   posi := 1;

   cursor(true);
   gotoxy(x,y);
   Change_cursor(6,7);
   viewbuffer(buffer.screen1);


   repeat
     if is_key_pressed then Get_Key;

     if (ord(key_Ascii) > $20)  then
     begin

         if (posi < 400) then
         begin
          msg_buffer[posi] := ord(key_Ascii);

          inc(posi);

          inc(x);

          if (x > max_x) then
          begin
            if (y < max_y) then
            begin
              x := min_x;
              inc(y);
            end
            else
             x := max_x;

          end;
         end
         else
         begin
          msg_buffer[posi] := ord(key_Ascii);
         end;


         Print_Message;
         gotoxy(x,y);
         viewbuffer(buffer.screen1);
         Clear_Keypress;
     end;


     if key_code= 57 then   {space}
     begin
         msg_buffer[posi] := 0;
         putchar(x,y,' ',15,0);
         if (posi < 400) then
         begin
          inc(posi);

          inc(x);

          if (x > max_x) then
          begin
            if (y < max_y) then
            begin
              x := min_x;
              inc(y);
            end
            else
             x := max_x;

          end;
         end;
         gotoxy(x,y);
         viewbuffer(buffer.screen1);
         Clear_Keyboard_Buffer;
      end;



     if key_code= 28 then  {Enter}
     begin
       if (y < max_y) then
       begin
          x := min_x;
          inc(y);
          posi := ((y-min_y)*40)+1;
          gotoxy(x,y);
        end;
       Clear_Keypress;
     end;


     if (key_code= 14) then {Backspace}
     begin
      msg_buffer[posi] := 0;

      if (posi > 1) then
      begin
       dec(posi);
       dec(x);
       if (x < min_x) then
       begin
        if (y > min_y) then
        begin
         dec(y);
         x := max_x;
        end;
       end;

       gotoxy(x,y);
       putchar(x,y,' ',15,0);
       viewbuffer(buffer.screen1);
      end;
      Clear_Keypress;
     end;


     if (key_code= 83) then {Entf}
     begin
      msg_buffer[posi] := 0;
      putchar(x,y,' ',15,0);
      viewbuffer(buffer.screen1);
      Clear_Keypress;
     end;

     if (key_code= 77)  then {Right}
     begin
      if (x < max_x) then
      begin
       inc(x);
       inc(posi);
      end;

      gotoxy(x,y);
      Clear_Keypress;
     end;

     if (key_code= 75)  then {Left}
     begin
      if (x > min_X) then
      begin
       dec(x);
       dec(posi);
      end;
      gotoxy(x,y);
      Clear_Keypress;
     end;

     if (key_code= 72)  then {Up}
     begin
      if (y > min_y) then
      begin
       dec(y);
       dec(posi,40);
      end;
      gotoxy(x,y);
      Clear_Keypress;
     end;

     if (key_code= 80)  then {Down}
     begin
      if (y < max_Y) then
      begin
        inc(posi,40);
        inc(y);
        gotoxy(x,y);
      end;
      Clear_Keypress;
    end;


   until (key_code= 1);
   gotoxy(ox,oy);
   cursor(false);
   move(buffer.screen2^,buffer.screen1^,4000);
   viewbuffer(buffer.screen1);
   Clear_Keypress;
end;

{============ The menu to change default timing ==============}
Procedure Timing_Config;
var
    selected : byte;
    bpm	: real;
    s	: string;

begin
  move(buffer.blankscreen^,buffer.screen2^,4000);
  writeto(buffer.screen2);

  window(10,5,70,14,15,1,true);
  centeredtext(5,palette.text_color2,palette.menu_color,' Song timing  ');
  centeredtext(7,palette.text_color1,palette.menu_color,'Default tempo (ticks per second):');
  centeredtext(10,palette.text_color1,palette.menu_color,'Default speed (ticks per row):');

  centeredtext(8,palette.text_color2,palette.menu_color,addspace(2,round(Player.Tempo)));
  centeredtext(11,palette.text_color2,palette.menu_color,addspace(2,Player.Speed));
  selected := 1;

  Clear_Keypress;
  ViewBuffer(buffer.screen2);

  repeat
  if is_key_pressed then Get_Key;


    case selected of
     1:
      begin
       mark(38,8,5);
       unmark(39,11,4,palette.text_color2);
      end;

     2:
      begin
       mark(39,11,4);
       unmark(38,8,5,palette.text_color2);
      end;
    end;

     bpm := (4*Player.Speed); {ticks per beat}
     bpm := bpm * (1000/Player.Tempo);   {ms per beat}
     bpm := (bpm/1000);	{beats per second}
     bpm := 60 / bpm; {beats per minute}


    str(bpm:3:0,s);
    centeredtext(13,palette.text_color2,palette.menu_color,'= '+s+ ' BPM');
    ViewBuffer(buffer.screen2);

    if (key_code= 80) then  {down}
    begin
     inc(selected);
     if selected > 2 then selected := 1;
     Clear_Keypress;
    end;

    if (key_code= 72) then  {up}
    begin
     dec(selected);
     if selected < 1 then selected := 2;
     Clear_Keypress;
    end;

    if (key_code= 78) or (key_code= 27) {+} or (key_code= 77) {down} then
    begin
     case selected of
      1: if Player.Tempo < $E0 then inc(Player.Tempo);
      2: if Player.Speed < $1F then inc(Player.Speed);
     end;
     centeredtext(8,palette.text_color2,palette.menu_color,addspace(2,round(Player.Tempo)));
     centeredtext(11,palette.text_color2,palette.menu_color,addspace(2,Player.Speed));
     Clear_Keypress;
     ViewBuffer(buffer.screen2);
    end;

    if (key_code= 53) or (key_code= 74) {-} or (key_code= 75) {up} then
    begin
      case selected of
      1: if Player.Tempo > 18 then dec(Player.Tempo);
      2: if Player.Speed > 1 then dec(Player.Speed);
     end;
     centeredtext(8,palette.text_color2,palette.menu_color,addspace(2,round(Player.Tempo)));
     centeredtext(11,palette.text_color2,palette.menu_color,addspace(2,Player.Speed));
     Clear_Keypress;
     ViewBuffer(buffer.screen2);
    end;



  until (key_code= 28) or (key_code= 1);

  Editor.D_Tempo := Player.Tempo;
  Editor.D_Speed := Player.Speed;

  set_timer(Player.Tempo); {Reset timer to new tepo}

  Clear_Keypress;
  writeto(buffer.screen1);
  viewbuffer(buffer.screen1);
end;



{============ swap tracks ==============}

Procedure Swap_Tracks(from_track, to_track : byte; whole_song : boolean);
var pc,tc : byte;
   buffer_event : TNDYevent;
begin

  if (Editor.channels = 4) and (to_track = 5) then
  begin
   Editor.channels := 5;
  end;

if whole_song then
begin
  for pc := 0 to Player.MaxPattern do
  begin
    for tc := 0 to 63 do
    begin
     fillchar(buffer_event,sizeof(buffer_event),0);
     buffer_event := Patterns[pc]^[tc][to_track-1];
     Patterns[pc]^[tc][to_track-1] := Patterns[pc]^[tc][from_track-1];
     Patterns[pc]^[tc][from_track-1] := buffer_event;
    end;
  end;
end
else
begin
    for tc := 0 to 63 do
    begin
     fillchar(buffer_event,sizeof(buffer_event),0);
     buffer_event := Patterns[Player.pattern_num]^[tc][to_track-1];
     Patterns[Player.pattern_num]^[tc][to_track-1] := Patterns[Player.pattern_num]^[tc][from_track-1];
     Patterns[Player.pattern_num]^[tc][from_track-1] := buffer_event;
    end;
end;


end;



Procedure Swap_Tracks_Menu;
var
    from_track, to_track : byte;
    song	: boolean;
begin
  move(buffer.blankscreen^,buffer.screen2^,4000);
  writeto(buffer.screen2);
  window(10,5,70,15,15,1,true);
  centeredtext(5,palette.text_color2,palette.menu_color,' Swap tracks  ');
  centeredtext(7,palette.text_color1,palette.menu_color,'Swap track');
  centeredtext(10,palette.text_color1,palette.menu_color,'with track');
  centeredtext(13,palette.text_color1,palette.menu_color,'Pattern only   Whole Song');
  HLine(39,8,1,15,0,' ');
  HLine(39,11,1,15,0,' ');
  ox := GetX;
  oy := GetY;
  cursor(true);
  Change_cursor(6,7);
  gotoxy(39,8);

  song := false;
  Clear_Keypress;
  viewbuffer(buffer.screen2);

  repeat
    if is_key_pressed then Get_Key;

    if (key_code= 1) then {ESC}
    begin
      gotoxy(ox,oy);
      cursor(false);
      Clear_Keypress;
      writeto(buffer.screen1);
      viewbuffer(buffer.screen1);
      exit;
    end;

  until ord(key_Ascii) in [$31..$35];

  fastwrite(39,8,15,0,upcase(key_Ascii));
  from_track := ord(key_Ascii)-$30;
  viewbuffer(buffer.screen2);
  Clear_Keypress;

  gotoxy(39,11);

  repeat
    if is_key_pressed then Get_Key;

    if (key_code= 1)  then  {ESC}
    begin
      gotoxy(ox,oy);
      cursor(false);
      Clear_Keypress;
      writeto(buffer.screen1);
      viewbuffer(buffer.screen1);
      exit;
    end;

  until ord(key_Ascii) in [$31..$35];
  fastwrite(39,11,15,0,upcase(key_Ascii));
  to_track := ord(key_Ascii)-$30;

  cursor(false);
  mark(28,13,12);

  viewbuffer(buffer.screen2);
  Clear_Keypress;

  repeat
  if is_key_pressed then Get_Key;

    if (key_code= 78) or (key_code= 27) {+} or (key_code= 77) {down} then
    begin
     unmark(28,13,12,palette.text_color1);
     mark(43,13,10);
     song := true;
     viewbuffer(buffer.screen2);
     Clear_Keypress;
    end;

    if (key_code= 53) or (key_code= 74) {-} or (key_code= 75) {up} then
    begin
     unmark(43,13,10,palette.text_color1);
     mark(28,13,12);
     song := false;
     viewbuffer(buffer.screen2);
     Clear_Keypress;
    end;

    if (key_code= 1) then
    begin
     gotoxy(ox,oy);
     cursor(false);
     Clear_Keypress;
     writeto(buffer.screen1);
     viewbuffer(buffer.screen1);
     exit;
    end;


  until (key_code= 28);


  Swap_tracks(from_track,to_track,song);

  gotoxy(ox,oy);
  cursor(false);
  Clear_Keypress;
  writeto(buffer.screen1);
  viewbuffer(buffer.screen1);
end;




{============ The output device configuration window ==============}

Procedure Output_Config;
begin
  move(buffer.blankscreen^,buffer.screen2^,4000);
  writeto(buffer.screen2);

  window(20,3,60,15,15,1,true);
  centeredtext(4,palette.text_color2,palette.menu_color,' Configure Output Device  ');
  centeredtext(7,palette.text_color1,palette.menu_color,'I/O Port for TNDY or TNDLPT:');
  centeredtext(14,palette.text_color1,palette.menu_color,'Use arrow keys or +/- to select port.');

  if tandyport > 3 then {I/O Port for TNDY card}
  begin
    centeredtext(9,palette.menu_color,palette.menu_color,
                   'Parallel port LPT'+hexn(tandyport)+' not found!'); {clear this message}
    centeredtext(8,palette.text_color2,palette.mark_color,hexw(tandyport)+'h');
  end
  else
  begin                 {Parallel Port}
    centeredtext(8,palette.text_color2,palette.mark_color,'LPT'+hexn(tandyport)+' ');
    if not TLPT_Init(tandyport) then
    begin
      centeredtext(9,palette.text_color2,palette.menu_color,'Parallel port LPT'+hexn(tandyport)+' not found!');
    end
    else
    begin
      centeredtext(9,palette.menu_color,palette.menu_color,'Parallel port LPT'+hexn(tandyport)+' not found!');
    end;
 end;

 mark(38,8,5);

 Viewbuffer(buffer.screen2);
 Clear_Keypress;

 repeat
 if is_key_pressed then Get_Key;



   if (key_code= 77) {right} or (key_code= 72) {up} or (key_code= 78) or (key_code= 27) {+} then
   begin
      case tandyport of
       $0C0: tandyport := $0E0;
       $0E0: tandyport := $1E0;
       $1E0: tandyport := $2C0;
       $2C0: tandyport := $2E0;
       $2E0: tandyport := 1;
       1: tandyport := 2;
       2: tandyport := 3;
       3: tandyport := $0C0;
      end;

      if tandyport > 3 then
      begin
       if lpt then
       begin
        TLPT_Mute;
        lpt := false;
       end;
       TANDY_Init;
       TANDY_Mute_all;
       centeredtext(9,palette.menu_color,palette.menu_color,'Parallel port LPT'+hexn(tandyport)+' not found!');
       centeredtext(8,palette.text_color2,palette.mark_color,hexw(tandyport)+'h');
      end
      else
      begin
       centeredtext(8,palette.text_color2,palette.mark_color,'LPT'+hexn(tandyport)+' ');
       if not TLPT_Init(tandyport) then
       begin
        centeredtext(9,palette.text_color2,palette.menu_color,'Parallel port LPT'+hexn(tandyport)+' not found!');
       end
       else
       begin
        centeredtext(9,palette.menu_color,palette.menu_color,'Parallel port LPT'+hexn(tandyport)+' not found!');
        TANDY_Mute_all;
       end;
      end;

      Clear_Keypress;
      mark(38,8,5);
      Viewbuffer(buffer.screen2);
   end;

  if (key_code= 75) {left} or (key_code= 80) {down} or  (key_code= 53) or (key_code= 74) {-}  then
  begin
    case tandyport of
     3: tandyport := 2;
     2: tandyport := 1;
     1: tandyport := $2E0;
     $2E0: tandyport := $2C0;
     $2C0: tandyport := $1E0;
     $1E0: tandyport := $0E0;
     $0E0: tandyport := $0C0;
     $0C0: tandyport := 3;
    end;


    if tandyport > 3 then
    begin
      centeredtext(9,palette.menu_color,palette.menu_color,'Parallel port LPT'+hexn(tandyport)+' not found!');
      centeredtext(8,palette.text_color2,palette.mark_color,hexw(tandyport)+'h');
    end
    else
    begin
      centeredtext(8,palette.text_color2,palette.mark_color,'LPT'+hexn(tandyport)+' ');
      if not TLPT_Init(tandyport) then
      begin
        centeredtext(9,palette.text_color2,palette.menu_color,'Parallel port LPT'+hexn(tandyport)+' not found!');
      end
      else
      begin
        centeredtext(9,palette.menu_color,palette.menu_color,'Parallel port LPT'+hexn(tandyport)+' not found!');
      end;
    end;

    mark(38,8,5);
    Clear_Keypress;
    Viewbuffer(buffer.screen2);
  end;


  until (key_code= 28) or (key_code= 1);
  Clear_Keypress;
  writeto(buffer.screen1);
  viewbuffer(buffer.screen1);
end;



{============ The options for the import of AGI files ==============}
Procedure SND_Import_Config;
var
    selected : byte;
begin

  move(buffer.blankscreen^,buffer.screen2^,4000);
  writeto(buffer.screen2);

  window(10,5,70,23,15,1,true);
  centeredtext(5,palette.text_color2,palette.menu_color,' Options for the import of AGI SND files  ');
  centeredtext(7,palette.text_color1,palette.menu_color,'Use "Finetune" effect to correct frequencies:');
  centeredtext(11,palette.text_color1,palette.menu_color,'Delay value for note duration (in milliseconds):');
  centeredtext(13,palette.text_color1,palette.menu_color,'Default tempo (ticks per second):');
  centeredtext(15,palette.text_color1,palette.menu_color,'Default speed (ticks per row):');
  centeredtext(17,palette.text_color1,palette.menu_color,'Assumed clock frequency:');
  centeredtext(20,palette.text_color2,palette.menu_color,'The number of empty rows in the pattern corresponding');
  centeredtext(21,palette.text_color2,palette.menu_color,'to the note delay value is calculated as follows:');
  centeredtext(22,palette.text_color2,palette.menu_color,'(Note duration * Delay) / (Speed * (1000 / Tempo))');

  selected := 1;
  if SND.correct then
    centeredtext(8,palette.text_color2,palette.menu_color,'ENABLED ')
  else
    centeredtext(8,palette.text_color2,palette.menu_color,'DISABLED');

  centeredtext(12,palette.text_color2,palette.menu_color,addspace(100,SND.Delay));
  centeredtext(14,palette.text_color2,palette.menu_color,addspace(100,SND.Tempo));
  centeredtext(16,palette.text_color2,palette.menu_color,addspace(100,SND.Speed));

  If SND.ClockFreq = 1 then
    centeredtext(18,palette.text_color2,palette.menu_color,' 99,320 Hz')
  else
    centeredtext(18,palette.text_color2,palette.menu_color,'111,860 Hz');

  mark(36,8,8);

  Clear_Keypress;
  viewbuffer(buffer.screen2);

  repeat
  if is_key_pressed then Get_Key;

    case selected of
     1:
      begin
    	mark(36,8,8);
       	unmark(39,12,4,palette.text_color2);
      	unmark(39,14,4,palette.text_color2);
      	unmark(39,16,4,palette.text_color2);
      	unmark(35,18,10,palette.text_color2);
      end;

     2:
      begin
        unmark(36,8,8,palette.text_color2);
        mark(39,12,4);
      	unmark(39,14,4,palette.text_color2);
      	unmark(39,16,4,palette.text_color2);
      	unmark(35,18,10,palette.text_color2);
      end;

     3:
      begin
        unmark(36,8,8,palette.text_color2);
       	unmark(39,12,4,palette.text_color2);
     	mark(39,14,4);
     	unmark(39,16,4,palette.text_color2);
     	unmark(35,18,10,palette.text_color2);
      end;

     4:
      begin
        unmark(36,8,8,palette.text_color2);
       	unmark(39,12,4,palette.text_color2);
      	unmark(39,14,4,palette.text_color2);
      	mark(39,16,4);
      	unmark(35,18,10,palette.text_color2);
      end;

     5:
      begin
        unmark(36,8,8,palette.text_color2);
       	unmark(39,12,4,palette.text_color2);
      	unmark(39,14,4,palette.text_color2);
      	unmark(39,16,4,palette.text_color2);
      	mark(35,18,10);
      end;


    end;

    if (key_code= 80) then  {down}
    begin
     inc(selected);
     if selected > 5 then selected := 1;
     Clear_keypress;
    end;

    if (key_code= 72) then  {up}
    begin
     dec(selected);
     if selected < 1 then selected := 5;
     Clear_keypress;
    end;

    if (key_code= 78) or (key_code= 27) {+} or (key_code= 77) {right} then
    begin
     Clear_keypress;
     case selected of
      1: if SND.correct = false then SND.correct := true else SND.correct := false;
      2: if SND.Delay < 99 then inc(SND.Delay);
      3: if SND.Tempo < 224 then inc(SND.Tempo);
      4: if SND.Speed < 31 then inc(SND.Speed);
      5: if SND.ClockFreq = 0 then
       SND.ClockFreq := 1
       else
       SND.ClockFreq := 0;
     end;

     if SND.correct then
       centeredtext(8,palette.text_color2,palette.menu_color,'ENABLED ')
     else
       centeredtext(8,palette.text_color2,palette.menu_color,'DISABLED');

     centeredtext(12,palette.text_color2,palette.menu_color,addspace(100,SND.Delay));
     centeredtext(14,palette.text_color2,palette.menu_color,addspace(100,SND.Tempo));
     centeredtext(16,palette.text_color2,palette.menu_color,addspace(100,SND.Speed));
     If SND.ClockFreq = 1 then
      centeredtext(18,palette.text_color2,palette.menu_color,' 99,320 Hz')
     else
      centeredtext(18,palette.text_color2,palette.menu_color,'111,860 Hz');

    end;

    if  (key_code= 53) or (key_code= 74) {-} or (key_code= 75) then
    begin
     Clear_keypress;

     case selected of
      1: if SND.correct = false then SND.correct := true else SND.correct := false;
      2: if SND.Delay > 0 then dec(SND.Delay);
      3: if SND.Tempo > 18 then dec(SND.Tempo);
      4: if SND.Speed > 1 then dec(SND.Speed);
      5: if SND.ClockFreq = 0 then
          SND.ClockFreq := 1
         else
          SND.ClockFreq := 0;

     end;


     if SND.correct then
       centeredtext(8,palette.text_color2,palette.menu_color,'ENABLED ')
     else
       centeredtext(8,palette.text_color2,palette.menu_color,'DISABLED');

     centeredtext(12,palette.text_color2,palette.menu_color,addspace(100,SND.Delay));
     centeredtext(14,palette.text_color2,palette.menu_color,addspace(100,SND.Tempo));
     centeredtext(16,palette.text_color2,palette.menu_color,addspace(100,SND.Speed));
     If SND.ClockFreq = 1 then
      centeredtext(18,palette.text_color2,palette.menu_color,' 99,320 Hz')
     else
      centeredtext(18,palette.text_color2,palette.menu_color,'111,860 Hz');

   end;


      viewbuffer(buffer.screen2);

  until (key_code= 1) or (key_code= 28);
  Clear_Keypress;
  writeto(buffer.screen1);
  viewbuffer(buffer.screen1);
end;


{============ Options for the import of MOD files ==============}
Procedure MOD_Import_Config;
var
    selected : byte;
begin
  move(buffer.blankscreen^,buffer.screen2^,4000);
  writeto(buffer.screen2);
  window(10,5,70,16,15,1,true);
  centeredtext(5,palette.text_color2,palette.menu_color,' Options for the import of Amiga MOD files  ');
  centeredtext(7,palette.text_color1,palette.menu_color,'Import 4th channel as:');
  centeredtext(9,palette.text_color1,palette.menu_color,'Default tempo (ticks per second):');
  centeredtext(11,palette.text_color1,palette.menu_color,'Default speed (ticks per row):');
  centeredtext(13,palette.text_color1,palette.menu_color,'Volume scaling:');

  case MODimp.ch4 of
    1: centeredtext(8,palette.text_color2,palette.mark_color,'  Noise   ');
    2: centeredtext(8,palette.text_color2,palette.mark_color,'PC-Speaker');
    3: centeredtext(8,palette.text_color2,palette.mark_color,'   OFF    ');
  end;

  centeredtext(10,palette.text_color2,palette.menu_color,addzero(10,MODimp.Tempo));
  centeredtext(12,palette.text_color2,palette.menu_color,addzero(10,MODimp.Speed));

  case MODimp.volscale of
    1: centeredtext(14,palette.text_color2,palette.menu_color,'  Direct   ');
    2: centeredtext(14,palette.text_color2,palette.menu_color,'correct db ');
  end;

  selected := 1;
  Clear_Keypress;
  viewbuffer(buffer.screen2);

  repeat
  if is_key_pressed then Get_Key;

    case selected of
     1:
      begin
       	mark(35,8,10);
      	unmark(38,10,4,palette.text_color2);
      	unmark(38,12,4,palette.text_color2);
      	unmark(35,14,10,palette.text_color2);
      end;

     2:
      begin
       	unmark(35,8,10,palette.text_color2);
      	mark(38,10,4);
      	unmark(38,12,4,palette.text_color2);
      	unmark(35,14,10,palette.text_color2);
      end;

     3:
      begin
      	unmark(35,8,10,palette.text_color2);
      	unmark(38,10,4,palette.text_color2);
      	mark(38,12,4);
      	unmark(35,14,10,palette.text_color2);
      end;

     4:
      begin
      	unmark(35,8,10,palette.text_color2);
      	unmark(38,10,4,palette.text_color2);
      	unmark(38,12,4,palette.text_color2);
      	mark(35,14,10);
      end;
    end;


    if (key_code= 80) then  {down}
    begin
     inc(selected);
     if selected > 4 then selected := 1;
     Clear_keypress;
    end;

    if (key_code= 72) then  {up}
    begin
     dec(selected);
     if selected < 1 then selected := 4;
     Clear_keypress;
    end;

    if (key_code= 78) or (key_code= 27) {+} or (key_code= 77) {right} then
    begin
      Clear_keypress;
      case selected of
       1: if MODimp.ch4 < 3 then inc(MODimp.ch4) else MODimp.ch4 := 1;
       2: if MODImp.Tempo < 99 then inc(MODimp.Tempo);
       3: if MODImp.Speed < 99 then inc(MODimp.Speed);
       4: if MODimp.volscale < 2 then inc(MODimp.volscale) else MODimp.volscale := 1;
      end;

      case MODimp.ch4 of
       1: centeredtext(8,palette.text_color2,palette.menu_color,'  Noise   ');
       2: centeredtext(8,palette.text_color2,palette.menu_color,'PC-Speaker');
       3: centeredtext(8,palette.text_color2,palette.menu_color,'   OFF    ');
      end;

      case MODimp.volscale of
       1: centeredtext(14,palette.text_color2,palette.menu_color,'  Direct   ');
       2: centeredtext(14,palette.text_color2,palette.menu_color,'correct db ');
      end;

      centeredtext(10,palette.text_color2,palette.menu_color,addzero(10,MODimp.Tempo));
      centeredtext(12,palette.text_color2,palette.menu_color,addzero(10,MODimp.Speed));
    end;



    if  (key_code= 53) or (key_code= 74) {-} or (key_code= 75) then
    begin
      Clear_keypress;
      case selected of
       1: if MODimp.ch4 > 1 then dec(MODimp.ch4) else MODimp.ch4 := 3;
       2: if MODImp.Tempo > 18 then dec(MODimp.Tempo);
       3: if MODImp.Speed > 1 then dec(MODimp.Speed);
       4: if MODimp.volscale > 1 then dec(MODimp.volscale) else MODimp.volscale := 2;
      end;

      case MODimp.ch4 of
       1: centeredtext(8,palette.text_color2,palette.menu_color,'  Noise   ');
       2: centeredtext(8,palette.text_color2,palette.menu_color,'PC-Speaker');
       3: centeredtext(8,palette.text_color2,palette.menu_color,'   OFF    ');
      end;

      case MODimp.volscale of
       1: centeredtext(14,palette.text_color2,palette.menu_color,'  Direct   ');
       2: centeredtext(14,palette.text_color2,palette.menu_color,'correct db ');
      end;

      centeredtext(10,palette.text_color2,palette.menu_color,addzero(10,MODimp.Tempo));
      centeredtext(12,palette.text_color2,palette.menu_color,addzero(10,MODimp.Speed));
    end;


      viewbuffer(buffer.screen2);

  until (key_code= 27) or (key_code= 1);
  Clear_Keypress;
  writeto(buffer.screen1);
  viewbuffer(buffer.screen1);
end;






end.

