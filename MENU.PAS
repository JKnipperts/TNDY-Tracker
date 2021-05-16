{$G-,N-,E-}

{**************************************************************
 Menu.pas - Procedures for displaying the menus
          - Control of additional options and configurations

 Author: Jan Knipperts
 Program: TNDY-Tracker
 Version: 1.18a
  - added misc configuration
  - support for new TNDYLPT
  - Updated message editor to new format
  - improved screen buffering
  - Some clean up
  - Adopted code to latest version of textmode-unit
  - Added better support of Monochrome graphics
  - Removed swap tracks menu because of new copy/paste functions
  - Removed misc config as it is no longer needed
  - fixed a little bug in the message editor
  - fixed some typos


*******************************************************************}


 Unit Menu;
 interface
 uses global,PIT,tndy,keyboard,textmode;

 Procedure Mark(x,y,l : byte);
 Procedure UnMark(x,y,l,col : byte);
 Procedure DrawMenu(mnr : byte);


 Procedure Edit_Message;
 Procedure Timing_Config;

 Procedure Output_Config;
 Procedure SND_Import_Config;
 Procedure MOD_Import_Config;

 Procedure Transpose_menu(tracknum : byte);




 const

 Menu_Title   : array[1..6] of string =
                ('File',
                 'Play',
                 'Edit',
                 'Config',
                 'Help',
                 'Quit');

 Menu_Text    : array[1..6] of array[1..6] of string = (
                ('New Song',
                 'Load Song',
                 'Save Song',
                 'Import Amiga MOD patterns',
                 'Import AGI music resource',
                 ''),

                ('Play Song',
                 'Stop',
                 'Play Pattern',
                 'Play from Cursor',
                 'Trace mode is    ',
                 ''),

                ('PC Speaker channel on/off',
                 'Edit song description',
                 'Change default timing',
                 'Add new Pattern',
                 'Delete current Pattern',
                 'Transpose'),

                ('Sound device',
                 'AGI music import',
                 'MOD import',
                 '',
                 '',
                 ''),

                ('Keys',
                 'Effects',
                 'About',
                 '',
                 '',
                 ''),


                ('Quit to DOS',
                 '',
                 '',
                 '',
                 '',
                 ''));


 Menu_Size       : array[1..6] of byte =
                (5,5,6,3,3,1);

 Menu_Pos       : array[1..6] of byte =
                (17,25,33,41,51,59);



 implementation


 Procedure Mark(x,y,l : byte);
 var c : byte;
 begin
    for c := x to x+(l-1) do
    begin
      if not Monochrome then
        changeattr(c,y,Attr(palette.text_color2,palette.mark_color,false))
      else
        changeattr(c,y,AttrMDA(false,false,true));
    end;
 end;

 Procedure UnMark(x,y,l,col : byte);
 var c : byte;
 begin
    for c := x to x+(l-1) do
    begin
      if not Monochrome then
        changeattr(c,y,Attr(col,palette.menu_color,false))
      else
        changeattr(c,y,AttrMDA(false,false,false));
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

   box(Menu_pos[mnr],2,Menu_pos[mnr]+s+3,3+Menu_size[mnr],palette.text_color1,palette.menu_color,true,true);

   for i := 1 to Menu_size[mnr] do
   begin
     fastwrite(Menu_pos[mnr]+1,2+i,palette.text_color1,palette.menu_color,menu_text[mnr][i]);
     if (mnr = 2) and (i = 5) then
     begin
       if ptn.tracemode then
         fastwrite(Menu_pos[mnr]+length(menu_text[mnr][5])-2,7,palette.text_color1,palette.menu_color,'ON')
       else
         fastwrite(Menu_pos[mnr]+length(menu_text[mnr][5])-2,7,palette.text_color1,palette.menu_color,'OFF');
     end;

   end;
   active_menu := mnr;
 end;







{============ The editor for the song description ==============}

Procedure Edit_Message;
var
  ox,oy,
  x,y,
  line_pos,line  : byte;		       {cursor positons}
  offset, cnt    : word;                       {offset in message buffer, counter}
  text           : array[1..10] of string[40]; {buffer for message in string form}

const
  min_x : byte = 20;   {screen coordinate constants}
  min_y : byte = 5;
  max_x : byte = 59;
  max_y : byte = 14;

Procedure Convert_buffer_to_text;
var lc,lp : byte;
begin
 for lc:= 1 to 10 do
 begin
   offset := ((lc-1)*40)+1;
   lp := 1;
   text[lc] := '';
   repeat
      text[lc] := text[lc]+chr(msg_buffer[offset]);
      inc(lp);
      inc(offset);
   until (lp = 41);
 end;
 dec(lp);
 while text[10][lp] = #0 do
 dec(lp);
 delete(text[10],lp,40-lp);
end;

Procedure Convert_text_to_buffer;
var lc,lp : byte;
begin
  for lc := 1 to 10 do
  begin
    for lp := 1 to 40 do
      msg_buffer[((lc-1)*40)+lp] := ord(text[lc][lp]);
  end;
end;



Procedure Print_Message;
var lc : byte;
begin
  block(20,5,60,14,15,0);
  for lc := 1 to 10 do
  begin
    fastwrite(min_x,(min_y-1)+lc,15,0,text[lc]);
  end;
  displaybuffer(buffer.screen2);
end;

Procedure Next_char_pos;
begin
  if (x < max_x) then
  begin
    inc(x);
    inc(line_pos);
  end
  else
  begin
    if (y < max_y) then
    begin
      inc(y);
      inc(line);
      x := min_x;
      line_pos := 1;
    end;
  end;

  gotoxy(x,y);
end;


Procedure Prev_char_pos;
begin
  if (x > min_x) then
  begin
    dec(x);
    dec(line_pos);
  end
  else
  begin
    if (y > min_y) then
    begin
      dec(y);
      dec(line);
      x := max_x;
      line_pos := 40;
    end;
  end;
  gotoxy(x,y);
end;


begin
  ox := GetX;
  oy := GetY;

  CopyBuffer(buffer.blankscreen,buffer.screen2);
  writeto(buffer.screen2);

  box(18,4,61,15,15,1,true,true);
  centeredtext(4,palette.text_color2,palette.menu_color,' Song description Editor: ');
  centeredtext(15,palette.text_color2,palette.menu_color,' Press ESC to return to the tracker ');

  x  := min_x;
  y  := min_y;
  line_pos := 1;
  line := 1;
  gotoxy(x,y);
  cursor(true);
  Change_cursor(6,7);
  Convert_buffer_to_text;
  Print_Message;
  Clear_keypress;
  repeat
  if is_key_pressed then Get_Key;

  if (ord(key_Ascii) > $20) then
  begin

     if length(text[line]) < 40 then
     begin
       if line_pos < length(text[line]) then
        text[line][line_pos] := key_Ascii
       else
        text[line] := text[line]+key_Ascii;
     end
     else
      text[line][line_pos] := key_Ascii;

     Next_char_pos;
     Print_Message;
     Clear_keypress;
     editor.saved := false;
  end;

  if key_code= 57 then   {space}
  begin
    text[line][line_pos] := #0;
    Next_char_pos;
    Print_Message;
    Clear_keypress;
    editor.saved := false;
  end;

  if (key_code= 14) then {Backspace}
  begin
    if (line_pos > 1) then
        delete(text[line],line_pos-1,1)
    else
        delete(text[line-1],40,1);
    text[line][40] := ' ';
    Prev_char_pos;
    Print_Message;
    Clear_keypress;
    editor.saved := false;
  end;

  if (key_code= 83) then {Entf}
  begin
    delete(text[line],line_pos,1);
    Print_Message;
    Clear_keypress;
    editor.saved := false;
  end;

  if (key_code= 77)  then {Right}
  begin
    if (x < max_x) then
    begin
      inc(x);
      inc(line_pos);
    end
    else
    begin
      if y < max_Y then
      begin
        x := min_X;
        inc(y);
        line_pos := 1;
        inc(line);
      end;
    end;

    gotoxy(x,y);
    Clear_Keypress;
  end;

  if (key_code= 75)  then {Left}
  begin
    if (x > min_X) then
    begin
      dec(x);
      dec(line_pos);
    end
    else
    begin
      if y > min_Y then
      begin
        dec(y);
        x := max_X;
        line_pos := 40;
        dec(line);
      end;
    end;
    gotoxy(x,y);
    Clear_Keypress;
  end;

  if (key_code= 72)  then {Up}
  begin
    if (y > min_y) then
    begin
      dec(y);
      dec(line);
    end;
    gotoxy(x,y);
    Clear_Keypress;
  end;

 if (key_code= 80)  then {Down}
 begin
   if (y < max_Y) then
   begin
     inc(y);
     inc(line);
   end;
   gotoxy(x,y);
   Clear_Keypress;
 end;

 if (key_code = 79) then {End}
 begin
   x := max_X;
   gotoxy(x,y);
   line_pos := 40;
   Clear_Keypress;
 end;

 if (key_code = 71) then {Pos1}
 begin
   x := min_X;
   gotoxy(x,y);
   line_pos := 1;
   Clear_Keypress;
 end;

 if key_code= 28 then  {Enter}
 begin
   if (y < max_y) then
   begin
     x := min_x;
     inc(y);
     inc(line);
     line_pos := 1;
     gotoxy(x,y);
   end;
   Clear_Keypress;
 end;


  until (key_code= 1);
  convert_text_to_buffer;
  gotoxy(ox,oy);
  cursor(false);

  writeto(buffer.screen1);
  displaybuffer(buffer.screen1);
  Clear_Keypress;
end;



{============ The menu to change default timing ==============}
Procedure Timing_Config;
var
    selected : byte;
    bpm	: real;
    s	: string;

begin
  CopyBuffer(buffer.blankscreen,buffer.screen2);
  writeto(buffer.screen2);

  box(10,5,70,14,15,1,false,true);
  centeredtext(5,palette.text_color2,palette.menu_color,' Song timing  ');
  centeredtext(7,palette.text_color1,palette.menu_color,'Default tempo (ticks per second):');
  centeredtext(10,palette.text_color1,palette.menu_color,'Default speed (ticks per row):');

  fastwrite(39,8,palette.text_color2,palette.mark_color,addspace(100,round(Player.Tempo)));
  fastwrite(40,11,palette.text_color2,palette.menu_color,addspace(10,Player.Speed));

  selected := 1;

  Clear_Keypress;
  displaybuffer(buffer.screen2);

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

    if (Player.Tempo > 0) and (Player.Speed > 0) then
     bpm := (60*Player.Tempo) / (4*Player.Speed)
    else
     bpm := 0;

{First find interrupts per minute: 60 seconds * 50 per second = 3000
 Divide by interrupts per quarter note = 4 notes * speed
 This gives: Tempo = 3000/(4*speed)
 simplified: Tempo = 750/speed
 For a normal song in speed 6 this formula gives: 750/6 = 125 BPM

 From " The MOD file format" by Lars "ZAP" Hamre/Amiga Freelancers 1990}

    str(bpm:3:0,s);
    centeredtext(13,palette.text_color2,palette.menu_color,'= '+s+ ' BPM');
    displaybuffer(buffer.screen2);

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

    if (key_code= 78) or (key_code= 27) {+} or (key_code= 77) {right} then
    begin
     editor.saved := false;
     case selected of
      1: if Player.Tempo < $E0 then
         begin
           inc(Player.Tempo);
           fastwrite(39,8,palette.text_color2,palette.mark_color,addspace(100,round(Player.Tempo)));
           set_timer(Player.Tempo); {Reset timer to new tepo}
         end;
      2: if Player.Speed < $1F then
         begin
           inc(Player.Speed);
           fastwrite(40,11,palette.text_color2,palette.mark_color,addspace(10,Player.Speed));
           set_timer(Player.Tempo); {Reset timer to new tepo}
         end;
     end;


     Clear_Keypress;
     displaybuffer(buffer.screen2);
    end;

    if (key_code= 53) or (key_code= 74) {-} or (key_code= 75) {left} then
    begin
         editor.saved := false;
      case selected of
       1: if Player.Tempo > 18 then
         begin
           dec(Player.Tempo);
           fastwrite(39,8,palette.text_color2,palette.mark_color,addspace(100,round(Player.Tempo)));
           set_timer(Player.Tempo); {Reset timer to new tepo}
         end;
      2: if Player.Speed > 1 then
         begin
           dec(Player.Speed);
           fastwrite(40,11,palette.text_color2,palette.mark_color,addspace(10,Player.Speed));
           set_timer(Player.Tempo); {Reset timer to new tepo}
         end;

     end;
     Clear_Keypress;
     displaybuffer(buffer.screen2);
    end;



  until (key_code= 28) or (key_code= 1);

  Editor.D_Tempo  := Player.Tempo;
  Editor.D_Speed  := Player.Speed;
  Editor.Playtime := Player.Tempo div 4;


  Clear_Keypress;
  writeto(buffer.screen1);
  displaybuffer(buffer.screen1);

end;






{============ The output device configuration window ==============}

Procedure Output_Config;
begin

  copybuffer(buffer.blankscreen,buffer.screen2);
  writeto(buffer.screen2);

  box(18,3,62,15,15,1,false,true);
  centeredtext(4,palette.text_color2,palette.menu_color,'Configure Tandy 3 Voice:');
  centeredtext(7,palette.text_color1,palette.menu_color,'I/O Port for soundchip:');
  centeredtext(13,palette.text_color1,palette.menu_color,'Use arrow keys or +/- to select port.');


  if TANDY.IOport > 3 then {I/O Port for TNDY card}
  begin
    HLine(19,9,40,palette.menu_color,palette.menu_color,#32);
    centeredtext(8,palette.text_color2,palette.mark_color,hexw(TANDY.IOport)+'h');
    centeredtext(10,palette.text_color1,palette.menu_color,'[ ] Use '+hexw(TANDY.IOport+1)+'h as second data port');
    if TANDY.useC1 then
    putchar(25,10,palette.text_color2,palette.menu_color,'x');
    centeredtext(14,palette.text_color1,palette.menu_color,'Space to enable/disable data port option.');

  end
  else
  begin                 {Parallel Port}
    centeredtext(8,palette.text_color2,palette.mark_color,'LPT'+hexn(TANDY.IOport)+' ');
    if not TLPT_Init(TANDY.IOport) then
    begin
      centeredtext(9,palette.text_color2,palette.menu_color,'Parallel port LPT'+hexn(TANDY.IOport)+' not found!');
    end
    else
    begin
      centeredtext(9,palette.menu_color,palette.menu_color,'Parallel port LPT'+hexn(TANDY.IOport)+' not found!');
    end;
 end;

 mark(38,8,5);

 displaybuffer(buffer.screen2);
 Clear_Keypress;

 repeat
   if is_key_pressed then Get_Key;



   if (key_code= 77) {right} or (key_code= 72) {up} or (key_code= 78) or (key_code= 27) {+} then
   begin
      case TANDY.IOport of
       $0C0: TANDY.IOport := $0E0;
       $0E0: TANDY.IOport := $1E0;
       $1E0: TANDY.IOport := $2C0;
       $2C0: TANDY.IOport := $2E0;
       $2E0: TANDY.IOport := 1;
       1: TANDY.IOport := 2;
       2: TANDY.IOport := 3;
       3: TANDY.IOport := $0C0;
      end;

      if TANDY.IOport > 3 then
      begin
       if TLPT.lpt then
       begin
        TLPT_Mute;
        TLPT.lpt := false;
       end;
       TANDY_Mute_all;
       HLine(19,9,43,palette.menu_color,palette.menu_color,#32);
       centeredtext(8,palette.text_color2,palette.mark_color,hexw(TANDY.IOport)+'h');

       centeredtext(10,palette.text_color1,palette.menu_color,'[ ] Use '+hexw(TANDY.IOport+1)+'h as second data port');
       if TANDY.useC1 then
       putchar(25,10,palette.text_color2,palette.menu_color,'x');
       centeredtext(14,palette.text_color1,palette.menu_color,'Space to enable/disable data port option.');


      end
      else
      begin
        HLine(19,10,43,palette.menu_color,palette.menu_color,#32);
        HLine(19,14,43,palette.menu_color,palette.menu_color,#32);
        centeredtext(8,palette.text_color2,palette.mark_color,'LPT'+hexn(TANDY.IOport)+' ');
        if not TLPT_Init(TANDY.IOport) then
        begin
          centeredtext(9,palette.text_color2,palette.menu_color,'Parallel port LPT'+hexn(TANDY.IOport)+' not found!');
        end
        else
        begin
          centeredtext(9,palette.menu_color,palette.menu_color,'Parallel port LPT'+hexn(TANDY.IOport)+' not found!');
        end;
      end;

      Clear_Keypress;
      mark(38,8,5);
      TANDY_Mute_all;
      displaybuffer(buffer.screen2);
   end;

  if (key_code= 75) {left} or (key_code= 80) {down} or  (key_code= 53) or (key_code= 74) {-}  then
  begin
    case TANDY.IOport of
     3: TANDY.IOport := 2;
     2: TANDY.IOport := 1;
     1: TANDY.IOport := $2E0;
     $2E0: TANDY.IOport := $2C0;
     $2C0: TANDY.IOport := $1E0;
     $1E0: TANDY.IOport := $0E0;
     $0E0: TANDY.IOport := $0C0;
     $0C0: TANDY.IOport := 3;
    end;


    if TANDY.IOport > 3 then
    begin
      HLine(19,9,43,palette.menu_color,palette.menu_color,#32);
      centeredtext(8,palette.text_color2,palette.mark_color,hexw(TANDY.IOport)+'h');

      centeredtext(10,palette.text_color1,palette.menu_color,'[ ] Use '+hexw(TANDY.IOport+1)+'h as second data port');
      if TANDY.useC1 then
      putchar(25,10,palette.text_color2,palette.menu_color,'x');
      centeredtext(14,palette.text_color1,palette.menu_color,'Space to enable/disable data port option.');

    end
    else
    begin
      HLine(19,10,43,palette.menu_color,palette.menu_color,#32);
      HLine(19,14,43,palette.menu_color,palette.menu_color,#32);
      centeredtext(8,palette.text_color2,palette.mark_color,'LPT'+hexn(TANDY.IOport)+' ');
      if not TLPT_Init(TANDY.IOport) then
      begin
        centeredtext(9,palette.text_color2,palette.menu_color,'Parallel port LPT'+hexn(TANDY.IOport)+' not found!');
      end
      else
      begin
        centeredtext(9,palette.menu_color,palette.menu_color,'Parallel port LPT'+hexn(TANDY.IOport)+' not found!');
      end;
    end;

    Clear_Keypress;
    mark(38,8,5);
    TANDY_Mute_all;
    displaybuffer(buffer.screen2);
  end;


  if (key_code = 57) and (TANDY.IOport > 3) then
  begin
   if TANDY.useC1 then
   begin
     TANDY.useC1 := false;
     putchar(25,10,palette.text_color2,palette.menu_color,' ');
   end
   else
   begin
     TANDY.useC1 := true;
     putchar(25,10,palette.text_color2,palette.menu_color,'x');
   end;
   Clear_Keypress;
   displaybuffer(buffer.screen2);
  end;



  until (key_code= 28) or (key_code= 1);
  Clear_Keypress;
  writeto(buffer.screen1);
  displaybuffer(buffer.screen1);


end;



{============ The options for the import of AGI files ==============}
Procedure SND_Import_Config;
var
    selected : byte;
begin
  CopyBuffer(buffer.blankscreen,buffer.screen2);
  writeto(buffer.screen2);

  box(10,5,70,16,15,1,false,true);
  centeredtext(5,palette.text_color2,palette.menu_color,' Options for the import of AGI SND files  ');
  centeredtext(7,palette.text_color1,palette.menu_color,'Use "Finetune" effect to correct frequencies:');
  centeredtext(9,palette.text_color1,palette.menu_color,'Default tempo (ticks per second):');
  centeredtext(11,palette.text_color1,palette.menu_color,'Default speed (ticks per row):');
  centeredtext(13,palette.text_color1,palette.menu_color,'Assumed clock frequency:');

  selected := 1;
  if SNDcfg.correct then
    fastwrite(37,8,palette.text_color2,palette.mark_color,'ENABLED ')
  else
    fastwrite(37,8,palette.text_color2,palette.mark_color,'DISABLED');

  centeredtext(10,palette.text_color2,palette.menu_color,addspace(100,SNDcfg.Tempo));

  if SNDcfg.Speed > 0 then
    fastwrite(39,12,palette.text_color2,palette.mark_color,addspace(100,SNDcfg.Speed))
  else
    fastwrite(39,12,palette.text_color2,palette.mark_color,'AUTO');


  If SNDcfg.ClockFreq = 1 then
    centeredtext(14,palette.text_color2,palette.menu_color,' 99320 Hz')
  else
    centeredtext(14,palette.text_color2,palette.menu_color,'111860 Hz');



  Clear_Keypress;
  displaybuffer(buffer.screen2);

  repeat
  if is_key_pressed then Get_Key;

    case selected of
     1:
      begin
    	mark(36,8,10);
       	unmark(39,10,4,palette.text_color2);
      	unmark(39,12,4,palette.text_color2);
      	unmark(35,14,10,palette.text_color2);
      end;

     2:
      begin
        unmark(36,8,10,palette.text_color2);
        mark(39,10,4);
      	unmark(39,12,4,palette.text_color2);
      	unmark(35,14,10,palette.text_color2);
      end;

     3:
      begin
        unmark(36,8,10,palette.text_color2);
       	unmark(39,10,4,palette.text_color2);
     	mark(39,12,4);
     	unmark(35,14,10,palette.text_color2);
      end;

     4:
      begin
        unmark(36,8,10,palette.text_color2);
       	unmark(39,10,4,palette.text_color2);
      	unmark(39,12,4,palette.text_color2);
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
      1: begin
           if SNDcfg.correct = false then
           begin
             SNDcfg.correct := true;
             fastwrite(37,8,palette.text_color2,palette.mark_color,'ENABLED ');
           end
           else
           begin
             SNDcfg.correct := false;
             fastwrite(37,8,palette.text_color2,palette.mark_color,'DISABLED');
           end;
         end;


      2: begin
           if SNDcfg.Tempo < 224 then inc(SNDcfg.Tempo);
           centeredtext(10,palette.text_color2,palette.mark_color,addspace(100,SNDcfg.Tempo));
         end;

      3: begin
           if SNDcfg.Speed < 31 then inc(SNDcfg.Speed);

           if SNDcfg.Speed > 0 then
             fastwrite(39,12,palette.text_color2,palette.mark_color,addspace(100,SNDcfg.Speed)+' ')
           else
             fastwrite(39,12,palette.text_color2,palette.mark_color,'AUTO')
         end;

      4: begin
           if SNDcfg.ClockFreq = 0 then
           begin
             SNDcfg.ClockFreq := 1;
   	     centeredtext(14,palette.text_color2,palette.menu_color,' 99320 Hz')
           end
          else
           begin
             SNDcfg.ClockFreq := 0;
    	     centeredtext(14,palette.text_color2,palette.menu_color,'111860 Hz');
           end;
         end;
     end;
    end;

    if  (key_code= 53) or (key_code= 74) {-} or (key_code= 75) then
    begin

     Clear_keypress;

      case selected of
      1: begin
          if SNDcfg.correct = false then
           begin
             SNDcfg.correct := true;
             fastwrite(37,8,palette.text_color2,palette.mark_color,'ENABLED ');
           end
           else
           begin
             SNDcfg.correct := false;
             fastwrite(37,8,palette.text_color2,palette.mark_color,'DISABLED');
           end;
         end;


      2: begin
           if SNDcfg.Tempo > 18 then dec(SNDcfg.Tempo);
           centeredtext(10,palette.text_color2,palette.mark_color,addspace(100,SNDcfg.Tempo));
         end;

      3: begin
           if SNDcfg.Speed > 0 then dec(SNDcfg.Speed);

           if SNDcfg.Speed > 0 then
             fastwrite(39,12,palette.text_color2,palette.mark_color,addspace(100,SNDcfg.Speed)+' ')
           else
             fastwrite(39,12,palette.text_color2,palette.mark_color,'AUTO')

         end;

      4: begin
           if SNDcfg.ClockFreq = 0 then
           begin
             SNDcfg.ClockFreq := 1;
             centeredtext(14,palette.text_color2,palette.mark_color,' 99320 Hz');
           end
          else
           begin
             SNDcfg.ClockFreq := 0;
             centeredtext(14,palette.text_color2,palette.mark_color,'111860 Hz');
           end;
         end;

     end;

   end;


      displaybuffer(buffer.screen2);

  until (key_code= 1) or (key_code= 28);
  Clear_Keypress;
  writeto(buffer.screen1);
  displaybuffer(buffer.screen1);
end;


{============ Options for the import of MOD files ==============}
Procedure MOD_Import_Config;
var
    selected : byte;
begin
  CopyBuffer(buffer.blankscreen,buffer.screen2);
  writeto(buffer.screen2);
  box(10,5,70,16,15,1,false,true);
  centeredtext(5,palette.text_color2,palette.menu_color,' Options for the import of Amiga MOD files  ');
  centeredtext(7,palette.text_color1,palette.menu_color,'Import 4th channel as:');
  centeredtext(9,palette.text_color1,palette.menu_color,'Default tempo (ticks per second):');
  centeredtext(11,palette.text_color1,palette.menu_color,'Default speed (ticks per row):');
  centeredtext(13,palette.text_color1,palette.menu_color,'Volume scaling:');

  case MODcfg.ch4 of
    1: fastwrite(36,8,palette.text_color2,palette.mark_color,'  Noise   ');
    2: fastwrite(36,8,palette.text_color2,palette.mark_color,'PC-Speaker');
    3: fastwrite(36,8,palette.text_color2,palette.mark_color,'   OFF    ');
  end;

  fastwrite(39,10,palette.text_color2,palette.menu_color,addspace(100,MODcfg.Tempo));
  fastwrite(40,12,palette.text_color2,palette.menu_color,addspace(10,MODcfg.Speed));

  case MODcfg.volscale of
    1: fastwrite(36,14,palette.text_color2,palette.menu_color,'  Direct   ');
    2: fastwrite(36,14,palette.text_color2,palette.menu_color,'Correct dB ');
  end;

  selected := 1;
  Clear_Keypress;
  displaybuffer(buffer.screen2);

  repeat
  if is_key_pressed then Get_Key;

    case selected of
     1:
      begin
       	mark(35,8,12);
      	unmark(38,10,5,palette.text_color2);
      	unmark(39,12,4,palette.text_color2);
      	unmark(36,14,11,palette.text_color2);
      end;

     2:
      begin
       	unmark(35,8,12,palette.text_color2);
      	mark(38,10,5);
      	unmark(39,12,4,palette.text_color2);
      	unmark(36,14,11,palette.text_color2);
      end;

     3:
      begin
      	unmark(35,8,12,palette.text_color2);
      	unmark(38,10,5,palette.text_color2);
      	mark(39,12,4);
      	unmark(36,14,11,palette.text_color2);
      end;

     4:
      begin
      	unmark(35,8,12,palette.text_color2);
      	unmark(38,10,5,palette.text_color2);
      	unmark(39,12,4,palette.text_color2);
      	mark(36,14,11);
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
       1: begin
            if MODcfg.ch4 < 3 then inc(MODcfg.ch4) else MODcfg.ch4 := 1;
	    case MODcfg.ch4 of
       	     1: fastwrite(36,8,palette.text_color2,palette.mark_color,'  Noise   ');
             2: fastwrite(36,8,palette.text_color2,palette.mark_color,'PC-Speaker');
             3: fastwrite(36,8,palette.text_color2,palette.mark_color,'   OFF    ');
            end;
          end;

       2: begin
            if MODcfg.Tempo < 224 then inc(MODcfg.Tempo);
            fastwrite(39,10,palette.text_color2,palette.mark_color,addspace(100,MODcfg.Tempo));
          end;

       3: begin
            if MODcfg.Speed < 31 then inc(MODcfg.Speed);
            fastwrite(40,12,palette.text_color2,palette.mark_color,addspace(10,MODcfg.Speed));
          end;

       4: begin
            if MODcfg.volscale < 2 then inc(MODcfg.volscale) else MODcfg.volscale := 1;
            case MODcfg.volscale of
             1: fastwrite(36,14,palette.text_color2,palette.mark_color,'  Direct   ');
 	     2: fastwrite(36,14,palette.text_color2,palette.menu_color,'Correct dB ');
            end;
          end;
      end;
    end;



    if  (key_code= 53) or (key_code= 74) {-} or (key_code= 75) then
    begin
      Clear_keypress;

       case selected of
       1: begin
            if MODcfg.ch4 > 1 then dec(MODcfg.ch4) else MODcfg.ch4 := 3;
	    case MODcfg.ch4 of
       	     1: fastwrite(36,8,palette.text_color2,palette.mark_color,'  Noise   ');
             2: fastwrite(36,8,palette.text_color2,palette.mark_color,'PC-Speaker');
             3: fastwrite(36,8,palette.text_color2,palette.mark_color,'   OFF    ');
            end;
          end;

       2: begin
            if MODcfg.Tempo > 18 then dec(MODcfg.Tempo);
            fastwrite(39,10,palette.text_color2,palette.mark_color,addspace(100,MODcfg.Tempo));
          end;

       3: begin
            if MODcfg.Speed > 1 then dec(MODcfg.Speed);
            fastwrite(40,12,palette.text_color2,palette.mark_color,addspace(10,MODcfg.Speed));
          end;

       4: begin
            if MODcfg.volscale > 1 then dec(MODcfg.volscale) else MODcfg.volscale := 2;
            case MODcfg.volscale of
             1: fastwrite(36,14,palette.text_color2,palette.mark_color,'  Direct   ');
             2: fastwrite(36,14,palette.text_color2,palette.menu_color,'Correct dB ');
            end;
          end;
      end;
    end;

      displaybuffer(buffer.screen2);


  until (key_code = 28) or (key_code= 1);
  Clear_Keypress;
  writeto(buffer.screen1);
  displaybuffer(buffer.screen1);
end;



 Procedure Do_Transpose(t_pattern,t_row,t_track,t_value : byte;t_direction : boolean);
 begin
   if t_pattern > player.maxpattern then exit;

   if t_direction = true then {transpose up}
   begin
     if (patterns[t_pattern]^[t_row][t_track].note < 13) and
        (patterns[t_pattern]^[t_row][t_track].note > 0) then
     begin
       if (t_value = 12) and (patterns[t_pattern]^[t_row][t_track].octave < 9) then
          inc(patterns[t_pattern]^[t_row][t_track].octave)
       else
       begin
         if (patterns[t_pattern]^[t_row][t_track].note+t_value > 12) and
            (patterns[t_pattern]^[t_row][t_track].octave < 9) then
         begin
           inc(patterns[t_pattern]^[t_row][t_track].octave);
           inc(patterns[t_pattern]^[t_row][t_track].note,t_value);
           dec(patterns[t_pattern]^[t_row][t_track].note,12);
         end
         else
           inc(patterns[t_pattern]^[t_row][t_track].note,t_value);
       end;

     end;
   end
   else
   begin
     if (patterns[t_pattern]^[t_row][t_track].note < 13) and
        (patterns[t_pattern]^[t_row][t_track].note > 0) then
     begin
       if (t_value = 12) and (patterns[t_pattern]^[t_row][t_track].octave > 1) then
          dec(patterns[t_pattern]^[t_row][t_track].octave)
       else
       begin
         if t_value >= patterns[t_pattern]^[t_row][t_track].note then
         begin
           if patterns[t_pattern]^[t_row][t_track].octave > 1 then
              dec(patterns[t_pattern]^[t_row][t_track].octave);

           dec(t_value,patterns[t_pattern]^[t_row][t_track].note);
           patterns[t_pattern]^[t_row][t_track].note := 12 - t_value;
         end
         else
           dec(patterns[t_pattern]^[t_row][t_track].note,t_value);

       end;

       if (t_track < 4) and (patterns[t_pattern]^[t_row][t_track].octave <= 2) then
       begin
         patterns[t_pattern]^[t_row][t_track].octave := 2;
         if patterns[t_pattern]^[t_row][t_track].note < 10 then
            patterns[t_pattern]^[t_row][t_track].note := 10;
       end;

     end;
   end;

 end;


Procedure Transpose_menu(tracknum : byte);
const

 song_str   : string[6] = ' song ';
 up_str     : string[4] = ' up ';
 down_str   : string[6] = ' down ';
 note_str   : string[11] = 'halftone(s)';
var
 trans,
 selected,
 tp,tr	    : byte;
 trans_up,
 whole_song : boolean;
 track_str  : string[8];

 Procedure Draw_Transpose_Text;
 begin
   if trans_up then
   begin
     fastwrite(21,9,palette.text_color1,palette.menu_color,'Transpose'+track_str+up_str+'by    '+note_str+'  ');
     if tracknum < 4 then fastwrite(37,9,palette.text_color2,palette.menu_color,addspace(1,tracknum));
     fastwrite(38,9,palette.text_color2,palette.menu_color,up_str);
     fastwrite(45,9,palette.text_color2,palette.menu_color,addspace(10,trans));
   end
   else
   begin
     fastwrite(21,9,palette.text_color1,palette.menu_color,'Transpose'+track_str+down_str+'by    '+note_str);
     if tracknum < 4 then fastwrite(37,9,palette.text_color2,palette.menu_color,addspace(1,tracknum));
     fastwrite(38,9,palette.text_color2,palette.menu_color,down_str);
     fastwrite(47,9,palette.text_color2,palette.menu_color,addspace(10,trans));
   end;

   case selected of
    1:
    begin
      if tracknum < 4 then
       mark(37,9,1)
      else
       mark(31,9,7);
    end;

    2:
    begin
      if trans_up then
       mark(39,9,2)
      else
       mark(39,9,4);
    end;

    3:
    begin
      if trans_up then
       mark(45,9,2)
      else
       mark(47,9,2);
    end;
   end;
   displaybuffer(buffer.screen2);
 end;





begin
  trans := 1;
  track_str := ' voice  ';
  selected := 1;
  trans_up := true;
  whole_song := false;

  if not mainmenu then
   CopyBuffer(buffer.screen1,buffer.screen2)
  else
   CopyBuffer(buffer.blankscreen,buffer.screen2);


  writeto(buffer.screen2);
  box(10,7,70,11,15,1,false,true);
  centeredtext(7,palette.text_color2,palette.menu_color,' Transpose ');


  Clear_Keypress;
  Draw_Transpose_Text;


  repeat;
  if is_key_pressed then Get_Key;

    if (key_code = 77) then  {right}
    begin
     inc(selected);
     if selected > 3 then selected := 1;
     Clear_keypress;
     Draw_Transpose_Text;
    end;

    if (key_code = 75) then  {left}
    begin
     dec(selected);
     if selected < 1 then selected := 3;
     Clear_keypress;
     Draw_Transpose_Text;
    end;

    if (key_code= 78) or (key_code= 27) {+} or (key_code= 72) {up} then
    begin
      case selected of
       1:
       begin
         if tracknum < editor.channels-1 then inc(tracknum);
         if tracknum < 4 then track_str := ' voice  ';
         if tracknum = 4 then track_str := ' speaker  ';
       end;

       2:
       begin
         if trans_up = true then
          trans_up := false
         else
          trans_up := true;
       end;
       3: if trans < 12 then inc(trans);
      end;
      Clear_keypress;
      Draw_Transpose_Text;
    end;

    if  (key_code= 53) or (key_code= 74) {-} or (key_code= 80) then
    begin
      case selected of
       1:
       begin
         if tracknum > 1 then dec(tracknum);
         if tracknum < 4 then track_str := ' voice  ';
         if tracknum = 4 then track_str := ' speaker  ';
       end;
       2:
       begin
         if trans_up = true then
          trans_up := false
         else
          trans_up := true;
       end;
       3: if trans > 1 then dec(trans);
      end;
      Clear_keypress;
      Draw_Transpose_Text;
    end;



  until (key_code= 28) or (key_code= 1);

  pstate := pause;
  if key_code = 28 then
  begin
    pause := true;
    for tp := 0 to player.maxpattern do
    begin
      for tr := 0 to 63 do
      begin
        Do_Transpose(tp,tr,tracknum-1,trans,trans_up);
      end; {row}
    end; {position}

    pause := pstate;
    error := 0;

  end {key code = 28}
  else
   error := 6;

  Clear_Keypress;
  writeto(buffer.screen1);

end;


end.


