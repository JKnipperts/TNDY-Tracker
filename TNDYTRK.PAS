{$G-,N-,E-}

{
 Tracker for TNDY and TLPT Tandy 3-Voice sound devices
 Version 1.1 - 09/22/20
 by Jan Knipperts

 A tracker for the TI SN76496A sound generator chip. Written in Pascal and assembler code on a 80486 at 100 MHz.
 Dedicated to all lovers of old hardware. And of course to all who will still be writing programs for MS-DOS in 2020.

 Changes to V. 1.0
  - Corrected a bug in TNDY unit. The TANDY_MuteVoice function didn't use LPT_Send....
  - A big change to the keyboard interface. Now IRQ handled.
  - Setting Speed to 1 is possible now (because of the new keyboard handler)
  - Cleaned up the code
  - Fixed a bug that occurs when saving an empty pattern
  - Improved menu handling
  - Fixed some small bugs and glitches (cursor does not disappear right after leaving the description editor etc.)
  - competely buffered screen output to reduce flicker
  - Added option to select clock freq. for AGI files
  - Added file loading via command line
  - Changed timer interrupt to 08h
}




Program TNDYTracker;
uses dos,
     global,
     keyboard,
     textmode,
     menu,
     control,
     modules,
     tndy,
     play,
     tracker,
     PIT;


var
     OldExitProc           : Pointer;  {Pointer to save the orig. exit proc.}
     oldint08              : procedure;

const
     Edit_Play_Duration = 15;{How many ticks long should a note sound that was entered in the editor?}




{================= IRQ / Timing ========================}


Procedure Poll_Player;
begin

  if pause then
  begin
    inc(Editor.note_edit_cnt);                               {delay for an entered note to sound}

    if Editor.note_edit_cnt = Edit_Play_Duration then
    begin
     Mute_All;
     Editor.note_edit_cnt := 0;
    end;

  end
  else
  begin
    inc(timing.ticks);

    if ((timing.ticks+1 >= Player.speed)) then
    begin
      Playrow(Player.row);
      UpdatePos;
      timing.ticks := 0;
    end
    else
    begin
      UpdateFx(Player.row);
    end;

    key_code:= port[$60];         {We have to check the keyboard here this way}

    if key_code in [1,57,59..64,78,74] then
    begin
      Control_Player;
      clear_keypress;
      exit;
    end;
  end;

end;



procedure TNDYint; interrupt;
begin

  Poll_Player;

  if Timing.clock_tick > 0 then
  begin
  asm
    cli
    mov al,20h
    out 20h,al
  end;
  end
  else
  begin
    asm
     pushf
    end;
    oldint08;
  end;

  Timing.clock_tick := Timing.clock_tick+round(Timer.Frequency / 18.2065);
  If (Timing.clock_tick >= 1) then Timing.clock_tick := 0;

end;






Procedure Handle_Keyboard;
begin
  if is_key_pressed then
  begin
    Get_Key;

    if mainmenu then
      Control_Menu
    else
    begin

      if pause then
         Control_Pattern_Editor
      else
         Control_Player;

    end;

  end;
end;



procedure init_irq;
begin
  GetIntVec($08,@oldint08);
  SetIntVec($08,@TNDYint);
end;


procedure done_irq;
begin
  SetIntVec($08,@oldint08);
  Resettimer;		{Reset timer to its default state (18.2}
end;





{================= Handle command line options ========================}

Function FindOption(lookup : string) : boolean;
var cnt : byte;
    s   : string;
begin
  FindOption := false;

  for cnt := 1 to paramcount do
  begin
    if length(paramstr(cnt)) > length(lookup) then
      s := copy(uppercase(paramstr(cnt)),1,length(lookup))
    else
      s := uppercase(paramstr(cnt));

    if pos(uppercase(lookup),s) > 0 then
    begin
      FindOption := true;
      break;
    end;
  end;

end;


Procedure Check_Commandline;
begin

  if FindOption('/?') or FindOption('?') then
  begin
    clrscr;
    writeln(title);
    writeln('');
    writeln(' Possible comand line parameters: ');
    writeln('');
    writeln(' /MDA         - Forces monochrome display output ');
    writeln(' /COLOR       - Forces color display output ');
    writeln('');
    halt(0);
  end;

  if FindOption('/MDA') then
  begin
    VidSeg := $B000;
  end;

  if FindOption('/COLOR') then
  begin
    VidSeg := $B800;
  end;

end;





{============ The save exit proc ==============}

procedure Save_Exit; Far;
begin
  done_irq;			{Set original interrupt}
  Mute_All;			{Mute all sound output}
  freemem(buffer.screen1,4000);       {Free buffers}
  freemem(buffer.screen2,4000);       {Free buffers}
  freemem(buffer.blankscreen,4000);
  freemem(buffer.oldscreen,4000);
  Clear_Pattern_Data;		{Clean up patterns and release additional memory}
  dispose(patterns[0]);
  ExitProc := OldExitProc;	{And now run the original exit proc}
end;



{============ The default configuration ====================}

Procedure Set_default_config;
begin
   tandyport := $0C0;
   Editor.channels := 5;
   SND.Correct := true;
   SND.Delay := 9;
   SND.Tempo := 55;
   SND.Speed := 1;
   SND.ClockFreq := 1;
   MODimp.ch4 := 2; {PC Speaker}
   MODimp.Tempo := 50;
   MODimp.Speed := 6;
   MODimp.VolScale := 1; {direct scaling}
end;



{============ Initialization of screen modes, sound, variables.. ==============}

Procedure Initialization;
begin

  lpt := false;

  if tandyport <= 3 then    {Init TNDLPT if selected}
  begin
    lpt := true;
    if not TLPT_Init(tandyport) then
    begin
      tandyport := $0C0;
      lpt := false;
    end;
  end;

  TANDY_Mute_all;

  {Set the initial values for our variables....}

  Editor.d_tempo := 50; {Default tempo is 50 Hz}
  Editor.d_speed := 6; {Default speed 6 = 125 BPM}

  Player.speed := 6;
  Player.tempo := 50;
  Editor.orderview := -2;
  Editor.octave := 4;
  Editor.chan := 1;
  Player.position := 0;
  Player.row := 0;
  Editor.curr_vol := 0;
  Player.songlength := 1;
  Player.maxpattern := 0;

  active_menu := 1;
  pedit := true;
  quit := false;
  noteedit := true;

  patternplay := false;
  fillchar(order,sizeof(order),0);
  fillchar(msg_buffer,sizeof(msg_buffer),0);
  fillchar(p_msg,sizeof(p_msg),0);
  msg_size := 0;

  {Depending on the number of channels,
  the edit window is larger or smaller...}
  if Editor.channels = 5 then
  begin
    Editor.p_xp := 4;
    Editor.p_yp := 6;
  end
  else
  begin
    Editor.p_xp := 14;
    Editor.p_yp := 6;
  end;


  {Alloc additional screen buffer...}
  getmem(buffer.screen1,4000);
  getmem(buffer.blankscreen,4000);
  getmem(buffer.screen2,4000);
  getmem(buffer.oldscreen,4000);

  if (buffer.screen1 = nil) or
     (buffer.screen2 = nil) or
     (buffer.oldscreen = nil) or
     (buffer.blankscreen = nil) or
     (maxavail < sizeof(TNDYPattern)) then
  begin
    clrscr;
    writeln('');
    writeln('Not enough memory!');
    writeln('');
    halt(1);
  end;

  Viewseg := VidSeg;   {configure video buffers}
  Writeseg := viewseg;

  OldExitProc := ExitProc; {Save the old and install the}
  ExitProc := @Save_Exit;  {new exit procedure}

  pause := true;
  set_timer(Player.tempo); {Reset timer to new frequency}
  init_irq;

  if VidSeg = $B800 then  {color display}
  begin
    Palette.window_color := 0;    {set sheme for color screens}
    Palette.menu_color   := 1;
    Palette.mark_color   := 4;
    Palette.text_color1  := 15;
    Palette.text_color2  := 14;
    Palette.text_color3  := 4;

    asm       			{enter 80x25 16 color text mode}
      xor ah,ah
      mov al,3
      int 10h
    end;
  end
  else                 {..and for monochrome}
  begin
    Palette.window_color := 0;
    Palette.menu_color   := 1;
    Palette.mark_color   := 4;
    Palette.text_color1  := 7;
    Palette.text_color2  := 7;
    Palette.text_color3  := 7;

    asm
      xor ah,ah
      mov al,7
      int 10h
    end;
  end;

  cursor(false);

  writeto(buffer.screen1);           {all write functions go to buffer}

  InitMenuScreen(menu_title[1]+'    '+ {Draw the menu bar}
                 menu_title[2]+'    '+
                 menu_title[3]+'    '+
                 menu_title[4]+'    '+
                 menu_title[5]+'    '+
                 menu_title[6],Palette.text_color1,Palette.menu_color);

  centeredline(25,Palette.text_color1,Palette.menu_color,title); {..and the title}

  move(buffer.screen1^,buffer.blankscreen^,4000);  {save this screen as "basic"}
  move(buffer.screen1^,buffer.oldscreen^,4000);
end;


Procedure Read_Configuration;
begin
  if fileexist('TNDYTRK.CFG') then		{is there a configuration file?}
  begin
    {$I-}
    assign(f,'TNDYTRK.CFG');                       {Yes? Then read it...}
    reset(f,1);
     blockread(f,tandyport,sizeof(tandyport));
     blockread(f,Editor.channels,sizeof(Editor.channels));
     blockread(f,SND,sizeof(SND));
     blockread(f,MODimp,sizeof(MODimp));
    close(f);
    {$I+}
    If IOResult <> 0 then       {if reading failed set default values}
    begin
     Set_default_config;
    end;
  end
  else {if there is no file set default values}
  begin
    Set_default_config;
  end;
end;


Procedure Save_Configuration;
begin
  {$I-}
  assign(f,'TNDYTRK.CFG'); {save actual configuration}
  rewrite(f,1);
   blockwrite(f,tandyport,sizeof(tandyport));
   blockwrite(f,Editor.channels,sizeof(Editor.channels));
   blockwrite(f,SND,sizeof(SND));
   blockwrite(f,MODimp,sizeof(MODimp));
  close(f);
  {$I+}
  if IOresult <> 0 then
  begin
    writeln('ERROR: Cannot save current settings! Failed to write configuration file.');
    writeln('');
    halt(1);
  end;
end;









{============== Main program ==============}
begin
  Check_Commandline;
  Read_Configuration;
  Initialization;

  Clear_Pattern_Data;

  if pos('.TND',uppercase(paramstr(1))) > 0 then
  {Was a filename with ".TND" extension passed as parameter?}
  begin
    move(buffer.blankscreen^,buffer.screen2^,4000);
    writeto(buffer.screen2);
    window(16,7,64,12,Palette.text_color1,Palette.menu_color,true);
    centeredtext(9,Palette.text_color1,Palette.menu_color,'Please wait...');
    viewbuffer(buffer.screen2);
    LoadTNDY(paramstr(1));  {Try to load it...}
    Proceed_Errors;
    writeto(buffer.screen1);
    viewbuffer(buffer.screen1);

    if error = 0 then
    begin
      Player.position := 0;
      Player.Pattern_num := order[Player.position];
      Player.row := 0;
      Editor.chan := 1;
    end;
  end;

  writeto(buffer.screen1);

  Draw_Pattern_View(false);
  Draw_Pattern_Editor(true);

  Clear_Keypress;

  repeat         {The main loop...}
    if pause then Handle_keyboard;
  until quit;

  clrscr;
  Cursor(true);
  Change_cursor(6,7);

  Save_configuration;

  writeln('Greetings to Matze, Serge and Peter and all members of DOSReloaded.de');
  writeln('');
end.
