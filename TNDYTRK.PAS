{$G-,N-,E-}
{$S-,R-}
(*{-$M32768,0,655360}*)

{
 Tracker for TNDY and TLPT Tandy 3-Voice sound devices
 Version 1.2
 by Jan Knipperts

 A tracker for the TI SN76496A sound generator chip.

 Project pages:
 https://github.com/JKnipperts/TNDY-Tracker
 https://www.vogons.org/viewtopic.php?f=62&t=76603
 https://dosreloaded.de/forum/index.php?thread/3616-tndy-tracker-für-tandy-3-voice-sound


}




Program TNDYTracker;
uses dos,
     global,
     keyboard,
     textmode,
     menu,
     control,
     modules,
     IE,
     tndy,
     play,
     tracker,
     PIT;




{================= IRQ / Timing ========================}


Procedure Poll_Player;
begin
   if not pause then
   begin
       if timing.ticks > 0 then
       begin
         dec(timing.ticks);
         Update_fx(0);
         Update_fx(1);
         Update_fx(2);
         if editor.channels = 5 then
         Update_fx(3);
       end
       else
       begin
         Play_row(Player.row);  {Play new row}
         Update_Pos; {Update position}
         timing.ticks := Player.speed-1;
       end;
   end
   else
   begin
     if editor.play_note then
     begin
      if (editor.playticks < editor.playtime) then
       inc(editor.playticks)
      else
      begin
        Mute_all;
        editor.play_note := false;
      end;
     end;

     if editor.play_row then
     begin
       if editor.playticks > 0 then
       begin
         dec(editor.playticks);
         Update_fx(0);
         Update_fx(1);
         Update_fx(2);
         if editor.channels = 5 then
         Update_fx(3);
       end
       else
         Editor.Play_Row := false;
     end;



   end;


end;



Procedure TNDYint; interrupt;
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
     call [oldint08];
    end;
  end;

  Timing.clock_tick := Timing.clock_tick+Timer.Clock_Counter;
  If (Timing.clock_tick >= 1) then Timing.clock_tick := 0;

end;


procedure init_irq;
begin
  GetIntVec($08,@oldint08);
  SetIntVec($08,@TNDYint);
end;


procedure done_irq;
begin
  SetIntVec($08,@oldint08);
  Resettimer;		{Reset timer to its default state (18.2 Hz)}
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
    writeln('Possible comand line parameters: ');
    writeln('');
    writeln(' /MDA         - Forces monochrome display ');
    writeln(' /COLOR       - Forces color display ');
    writeln('');
    writeln('Or you can enter a Filename to load the song directly at the start.');
    writeln('Filename and options can also be combined.');
    writeln('Example: TNDYTRK.EXE C:\SONGS\TUNE.TND /MDA');
    writeln('');
    halt(0);
  end;

  if FindOption('/MDA') then
  begin
     ChangeVSeg($B000);
  end;

  if FindOption('/COLOR') then
  begin
     ChangeVSeg($B800);
  end;

end;





{============ The save exit proc ==============}

procedure Save_Exit; Far;
begin
  done_irq;			{Set original interrupt}
  Mute_All;			{Mute all sound output}
  fillchar(buffer.screen1^,4000,0);  {clean up memory}
  fillchar(buffer.screen2^,4000,0);
  fillchar(buffer.blankscreen^,4000,0);
  fillchar(buffer.oldscreen^,4000,0);
  fillchar(buffer.pbuffer^,7040,0);
  fillchar(buffer.pbuffer1^,7040,0);


  freemem(buffer.screen1,4000);       {Free buffers / allocated memory}
  freemem(buffer.screen2,4000);
  freemem(buffer.blankscreen,4000);
  freemem(buffer.oldscreen,4000);
  freemem(buffer.pbuffer,7040);
  freemem(buffer.pbuffer1,7040);

  Clear_Pattern_Data;		{Clean up patterns and release additional allocate memory}
  dispose(patterns[0]);         {also for pattern 0}
  ExitProc := OldExitProc;	{run the original exit proc}
end;



{============ The default configuration ====================}

Procedure Set_default_config;
begin
   TANDY.IOport := $0C0;
   Editor.channels := 5;
   SNDcfg.Correct := true;
   SNDcfg.Tempo := 60;
   SNDcfg.Speed := 0; {Auto detect speed}
   SNDcfg.ClockFreq := 1;
   MODcfg.ch4 := 2; {PC Speaker}
   MODcfg.Tempo := 50;
   MODcfg.Speed := 6;
   MODcfg.VolScale := 1; {direct scaling}
   ptn.tracemode := true;
end;



{============ Initialization of screen modes, sound, variables.. ==============}

Procedure Initialization;
begin
  TLPT.lpt := false;

  if TANDY.IOport <= 3 then    {Init TNDLPT if selected}
  begin
    TLPT.lpt := true;
    if not TLPT_Init(TANDY.IOport) then
    begin
      TANDY.IOport := $0C0;
      TLPT.lpt := false;
    end;
  end;

  TANDY_Mute_all;

  {Set the initial values for our variables....}

  Editor.d_tempo := 50; {Default tempo is 50 Hz}
  Editor.d_speed := 6; {Default speed 6 = 125 BPM}

  Player.speed := 6;
  Player.tempo := 50;
  Editor.D_tempo := Player.tempo;
  Editor.D_speed := Player.speed;
  Editor.Playtime := Player.tempo div 4;
  Editor.orderview := -2;
  Editor.octave := 4;
  Editor.chan := 1;
  Editor.noisetype := 0;
  Editor.play_row := false;
  Editor.play_note := false;
  Editor.saved  := true;


  Player.position := 0;
  Player.row := 0;
  Editor.curr_vol := 0;
  Player.songlength := 1;
  Player.maxpattern := 0;

  ptn.tracemode := true;

  active_menu := 1;
  pedit := true;
  quit := false;
  noteedit := true;
  clipboard.inuse := false;
  patternplay := false;

  fillchar(order,sizeof(order),0);
  fillchar(msg_buffer,sizeof(msg_buffer),0);
  fillchar(p_msg,sizeof(p_msg),0);
  fillchar(volume,sizeof(volume),15);
  fillchar(freq,sizeof(freq),0);
  fillchar(current,sizeof(current),0);
  fillchar(meter,sizeof(meter),0);
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
  getmem(buffer.pbuffer,7040);
  getmem(buffer.pbuffer1,7040);

  if (buffer.screen1 = nil) or
     (buffer.screen2 = nil) or
     (buffer.oldscreen = nil) or
     (buffer.blankscreen = nil) or
     (buffer.pbuffer = nil) or
     (buffer.pbuffer1 = nil) or
     (maxavail < sizeof(TNDYPattern)) then
  begin
    clrscr;
    writeln('');
    writeln('Not enough memory!');
    writeln('');
    halt(1);
  end;

  fillchar(buffer.screen1^,4000,0);
  fillchar(buffer.screen2^,4000,0);
  fillchar(buffer.blankscreen^,4000,0);
  fillchar(buffer.oldscreen^,4000,0);
  fillchar(buffer.pbuffer^,7040,0);
  fillchar(buffer.pbuffer1^,7040,0);

  OldExitProc := ExitProc; {Save the old and install the}
  ExitProc := @Save_Exit;  {new exit procedure}

  pause := true;
  set_timer(Player.tempo); {Reset timer to new frequency}

  init_irq;

  if txtscreen.VidSeg = $B800 then  {color display}
  begin
    Palette.window_color := 0;    {set sheme for color screens}
    Palette.menu_color   := 1;
    Palette.mark_color   := 4;
    Palette.text_color1  := 15;
    Palette.text_color2  := 14;
    Palette.text_color3  := 4;
    Monochrome := false;
    asm       			{enter 80x25 16 color text mode}
      xor ah,ah
      mov al,3
      int 10h
    end;
  end
  else                 {..and for monochrome}
  begin
    Palette.window_color := 0;
    Palette.menu_color   := 7;
    Palette.mark_color   := 7;
    Palette.text_color1  := 7;
    Palette.text_color2  := 7;
    Palette.text_color3  := 7;
    Monochrome := true;
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
    assign(f,'TNDYTRK.CFG');                       {Yes? Then read it...}
    reset(f,1);

     if filesize(f) <> (sizeof(SNDcfg)+Sizeof(MODcfg)+4) then
     begin
      close(f);            {wrong size? -> set default values}
      Set_default_config;
     end
     else
     begin
       {$I-}
       blockread(f,TANDY.IOport,sizeof(TANDY.IOport));
       blockread(f,TANDY.useC1,sizeof(TANDY.useC1));
       blockread(f,Editor.channels,sizeof(Editor.channels));
       blockread(f,SNDcfg,sizeof(SNDcfg));
       blockread(f,MODcfg,sizeof(MODcfg));
       close(f);
       {$I+}
       If IOResult <> 0 then       {Reading failed? -> set default values}
       begin
         Set_default_config;
       end;
     end;

  end
  else {there is no cfg file? -> set default values}
  begin
    Set_default_config;
  end;

end;


Procedure Save_Configuration;
begin
  {$I-}
  assign(f,'TNDYTRK.CFG'); {save actual configuration}
  rewrite(f,1);
   blockwrite(f,TANDY.IOport,sizeof(TANDY.IOport));
   blockwrite(f,TANDY.useC1,sizeof(TANDY.useC1));
   blockwrite(f,Editor.channels,sizeof(Editor.channels));
   blockwrite(f,SNDcfg,sizeof(SNDcfg));
   blockwrite(f,MODcfg,sizeof(MODcfg));
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

  Clear_Pattern_Data;
  Initialization;


  if (pos('.TND',uppercase(paramstr(1))) > 0) or
     (pos('.SND',uppercase(paramstr(1))) > 0) or
     (pos('.MOD',uppercase(paramstr(1))) > 0) then
  begin

    if (pos('.TND',uppercase(paramstr(1))) > 0) then
    LoadTNDY(paramstr(1));

    if (pos('.SND',uppercase(paramstr(1))) > 0) then
    Import_SND(paramstr(1));

    if (pos('.MOD',uppercase(paramstr(1))) > 0) then
    Import_MOD(paramstr(1));

    Proceed_Errors;
    writeto(buffer.screen1);
    displaybuffer(buffer.screen1);

    if error = 0 then
    begin
      Player.position := 0;
      Player.Pattern_num := order[Player.position];
      Player.row := 0;
      Editor.chan := 1;
    end;
  end;


  Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,0,63);

  writeto(buffer.screen1);
  Draw_Pattern_Window(false);
  Draw_Editor_Window(false);
  gotoxy(Editor.p_xp+4,14);
  Update_Pattern(-8,true);




  Clear_Keypress;
  repeat         {The main loop...}

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
          Control_Player
        end;

     end;


     if (pause = false) then  {while playing...}
     begin

       if ptn.bufferswap then  {time to swap patterns front and buckbuffer?}
       begin
         SwapBuffers(buffer.pbuffer,buffer.pbuffer1);
         ptn.bufferswap := false;
       end;

       if ptn.tracemode = true then
       begin
         if ptn.ptnupdate then
         begin
           Update_Order(false,true);
           Update_Pattern(Player.row-8,true);
           ptn.ptnupdate := false;
         end;
       end;

       if ptn.infoupdate then  {time to update screen contents?}
       begin
          Update_Player_State(true);
         ptn.infoupdate := false;
       end;




    end;



  until (quit);
  pause := true;
  TANDY_Mute_all;
  Clear_Keypress;
  writeto(ptr(txtscreen.vidseg,0));
  Save_Configuration;
  clrscr;
  writeln('Have a nice day and thank you for using TNDY-Tracker!');
  writeln('Greetings go to all members of DOSReloaded.de and Vogons.org and special');
  writeln('thanks to Matze and Serge for their great hardware projects!');
  writeln('');
  writeln('TNDY-Tracker is open source. Visit https://github.com/JKnipperts/TNDY-Tracker');
  writeln('for the latest version or if you are interested in the source code.');
  writeln('');
  Cursor(true);
  Change_cursor(6,7);

end.
