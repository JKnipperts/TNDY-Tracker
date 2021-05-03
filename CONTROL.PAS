{$G-,N-,E-}
{**************************************************************
 Control.pas - Procedures and functions for menu operation
	       and keyboard query

 Author: Jan Knipperts
 Program: TNDY-Tracker
 Version: 1.25
 - small bug fixes
 - improved screen buffering
 - improved monochrome graphics
 - improved speed and buffering
 - adapted to new player code
 - added copy/Paste, markings, delete blocks
 - added out of memory check for the fileselector
 - added "Save changes?" dialog
 - removed volume column for pc speaker channel
 - removed "export to snd"
 - fixed some glitches in the order editor
 - added home/end to order editor
 - added special key codes for tandy

***************************************************************
}



Unit Control;
interface

uses dos,global,menu,tndy,play,PIT,keyboard,textmode,tracker,
     fselect,modules,ie,help;

Procedure Control_Player;
Procedure Control_Order_Editor;
Procedure Control_Pattern_Editor;
Procedure Control_Menu;


Procedure Delete_Pattern_diag;
Procedure Add_new_Pattern_diag;




implementation




Procedure Toggle_Tracing;
begin
  if pause = false then
  begin
    CopyBuffer(buffer.blankscreen,buffer.screen1);
    if ptn.tracemode = true then
    begin
      ptn.tracemode := false;
      Draw_Player_State(false);
      Update_Player_State(true);
      CopyBuffer(buffer.screen1,buffer.oldscreen);
    end
    else
    begin
      ptn.tracemode := true;
      Update_Pattern_Screenbuffer(buffer.pbuffer,player.pattern_num,player.row-8,player.row+8);
      if player.row > 55 then
      Update_Pattern_Screenbuffer(buffer.pbuffer1,update_ptn,0,8);


      Draw_Pattern_Window(false);
      cursor(false);
      Draw_Player_State(false);
      Update_Player_State(false);
      Update_Order(false,true);
      CopyBuffer(buffer.screen1,buffer.oldscreen);
    end;
   end
   else
   begin
     if ptn.tracemode = true then
        ptn.tracemode := false
     else
        ptn.tracemode := true;
   end;
   Clear_Keypress;
end;


Function Save_changes_diag : byte;
begin
  Save_changes_diag := 0;

  if editor.saved = false then
  begin
    writeto(ptr(txtscreen.vidseg,0));

    box(14,8,66,14,palette.text_color1,palette.menu_color,false,true);
    centeredtext(10,palette.text_color1,palette.menu_color,'Your song has been modified.');
    centeredtext(11,palette.text_color1,palette.menu_color,'Do you want to save the changes?');
    centeredtext(12,palette.text_color1,palette.menu_color,'(Y)es / (N)o / (C)ancel');
    ChangeAttr(30,12,Attr(palette.text_color2,palette.menu_color,false));
    ChangeAttr(38,12,Attr(palette.text_color2,palette.menu_color,false));
    ChangeAttr(45,12,Attr(palette.text_color2,palette.menu_color,false));

    Clear_Keypress;
    repeat
       if is_key_pressed then Get_Key;

       if (upcase(key_Ascii) = 'N')  then
       begin
         Save_changes_diag := 2;
         Clear_Keypress;
         writeto(buffer.screen1);
         exit;
       end;

       if (key_code = 1) or  (upcase(key_Ascii) = 'C')  then
       begin
         Save_changes_diag := 3;
         Clear_Keypress;
         writeto(buffer.screen1);
         exit;
       end;

   until (upcase(key_Ascii) = 'Y') or (upcase(key_Ascii) = 'Z');
   Save_changes_diag := 1;
   writeto(buffer.screen1);
   Clear_Keypress;
  end;
end;



{============ Controls while playing  ==============}

Procedure Control_Player;
begin
        if is_key_pressed then Get_Key;


  	if key_code= 1 then		{ESC}
        begin
      	  Clear_Keypress; {Reset keyboard buffer}


          if (ptn.tracemode = true) then
          begin
            writeto(buffer.screen1);
            Draw_Pattern_Window(false);
    	    CopyBuffer(buffer.screen1,buffer.oldscreen); {save screen with empty pattern editor to buffer}
            Update_Pattern(Editor.MarkedRow-8,true);
          end
          else
          begin
            writeto(buffer.screen1);
            Draw_Player_State(false);
            CopyBuffer(buffer.screen1,buffer.oldscreen);
            Update_Player_State(true);
          end;


          cursor(false);
          select := 1;
          DrawMenu(2);
          Mark(Menu_pos[2]+1,2+select,length(menu_text[2][1]));
          displaybuffer(buffer.screen1);

          pedit := false;
          mainmenu := true;
        end;

        if (key_code >= $78) and (key_code <= $7C) and
           (alt_state = true) then			{Alt+1 to 5 Mute/Unmute channel}
        begin
          if key_code-$78 <= Editor.channels-1 then
          begin
            if Player.muted[key_code-$78] = true then
               Player.muted[key_code-$78] := false
            else
            begin
              Player.muted[key_code-$78] := true;
              Mute_Voice(key_code-$78);
            end;

            if ptn.tracemode then
               Update_Pattern(Editor.MarkedRow-8,true);
          end;
          Clear_Keypress;
       end;


         if (key_code = 31) and (Alt_State = true) then   {Alt+S = Solo}
         begin
           if not editor.solo then
           begin
             for z := 0 to Editor.channels-1 do
             begin
               if z <> editor.chan-1 then
               begin
                 Player.muted[z] := true;
                 Mute_Voice(z);
               end
               else
                Player.muted[z] := false;
             end;
             editor.solo := true;
           end
           else
           begin
             fillchar(player.muted,sizeof(player.muted),0);
             editor.solo := false;
           end;

          if ptn.tracemode then
             Update_Pattern(Editor.MarkedRow-8,true);

          Clear_Keypress;
         end;



	if (key_code= 64) then 			{F6 = Stop and return to last editor position}
        begin
          Stop_Playing;
        end;


	if (key_code= 65) then 			{F7 = Stop at current position}
        begin
         pause := true;
         mainmenu := false;
         pedit := true;
         Mute_all;
         Clear_Keypress;
         Editor.markedrow := Player.row;
         Player.pattern_num := order[Player.Position];
         CopyBuffer(buffer.blankscreen,buffer.screen1);
         Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,0,63);
         Draw_Pattern_Window(false);
         Draw_Editor_Window(false);
         Update_Pattern(Editor.markedrow-8,true);
        end;



        if key_code = 62 then		{F4 Toggle Trace mode}
        begin
          Toggle_Tracing;
        end;



       if (key_code= 78) or (key_code = 27) or (key_code = 13) or {+}
          ((key_code = 77) or (key_code = 244) and ((L_Shift_State = true) or (R_Shift_State = true))) then {Shift + Right}

       begin
         Mute_ALL;
         if Player.Position < Player.Songlength-1 then
         begin
           inc(Player.Position);
           Player.pattern_num := order[Player.Position];
         end;

         Player.row := 0;
         if ptn.tracemode then
         begin
           Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,0,63);
           Prepare_next_Patterns_buffer;  {Prepare row 0 of the next pattern}
           Update_Pattern(Player.row-8,false);
           Update_Order(false,true);
         end;
         Update_Player_State(true);
         Clear_Keypress;
      end;

      if (key_code= 74) or (key_code = 53) or (key_code = 12) or			{-}
         ((key_code = 75) and ((L_Shift_State = true) or (R_Shift_State = true))) then {Shift+Left}
      begin
        Mute_ALL;
        if Player.Position > 0 then
        begin
         dec(Player.Position);
         Player.pattern_num := order[Player.Position];
        end;

        Player.row := 0;
        if ptn.tracemode then
        begin
          Prepare_next_Patterns_buffer;  {Prepare row 0 of the next pattern}
          Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,0,63);
          Update_Pattern(Player.row-8,false);
          Update_Order(false,true);
        end;
        Update_Player_State(true);
        Clear_Keypress;
     end;


     if key_code = 72 then			{Up = rewind}
     begin
       if player.row > 0 then
       begin
         Mute_All;
         dec(player.row);
         timing.ticks := Player.speed-1;
         if ptn.tracemode then
            Update_Pattern(Player.row-8,false);
       end
       else
       begin
         if player.position > 0 then
         begin
           Mute_All;
           player.row := 63;
           dec(player.position);
           Player.pattern_num := order[Player.Position];
           timing.ticks := Player.speed-1;
           if ptn.tracemode then
           begin
             Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,0,63);
             Update_Pattern(Player.row-8,false);
           end;
         end;
       end;
        Update_Player_State(true);
     end;

     if key_code = 80 then		{Down = fast forward}
     begin
       Update_Pos; {Update position}
       timing.ticks := Player.speed-1;
     end;


end;





{============ Controling the order list editor ==============}
Procedure Control_Order_Editor;
begin
  ox := GetX;
  oy := GetY;

  Clear_Keypress;

  Player.pattern_num := order[Player.Position];
  Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,0,63);
  Update_Pattern(Editor.markedrow-8,false);
  Update_Order(true,true);
  gotoxy(73,16);

 repeat

  if is_key_pressed then Get_Key;

  if (key_code= 82) {ins} or (key_code = 155) {Ins on Tandy} then
  begin
    if Player.Songlength < $FF then
    begin
     for z := Player.Songlength-1 downto Player.Position do
     order[z+1] := order[z];
     order[Player.Position] := order[Player.Position+1];
     inc(Player.Songlength);
    end;

    Update_Order(false,true);
    Player.pattern_num := order[Player.Position];
    Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,Editor.markedrow-8,Editor.markedrow+8);
    Update_Pattern(Editor.markedrow-8,false);
    displaybuffer(buffer.screen1);
    Clear_Keypress;
  end;

  if (key_code= 83) {Del} then
  begin
    if Player.Songlength > 1 then
    begin
      for z := Player.Position to Player.Songlength-1 do
      order[z] := order[z+1];
      dec(Player.Songlength);
    end;

    if Player.Songlength-1 < Player.Position then dec(Player.Position);
    Update_Order(false,true);
    Player.pattern_num := order[Player.Position];
    Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,Editor.markedrow-8,Editor.markedrow+8);
    Update_Pattern(Editor.markedrow-8,false);
    displaybuffer(buffer.screen1);
    Clear_Keypress;
  end;

  if (key_code = 71) {home} then
  begin
    Player.Position := 0;
    Player.pattern_num := order[Player.Position];
    Update_Order(false,true);
    Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,Editor.markedrow-8,Editor.markedrow+8);
    Update_Pattern(Editor.markedrow-8,false);
    displaybuffer(buffer.screen1);
    Clear_Keypress;
  end;

  if (key_code = 79) {end} then
  begin
    Player.Position := Player.Songlength-1;
    Player.pattern_num := order[Player.Position];
    Update_Order(false,true);
    Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,Editor.markedrow-8,Editor.markedrow+8);
    Update_Pattern(Editor.markedrow-8,false);
    displaybuffer(buffer.screen1);
    Clear_Keypress;
  end;

  if (key_code= 77) or (key_code = 244) {Right} then
  begin
   gotoxy(73,16);
  end;

  if (key_code= 75) {Left} then
  begin
    gotoxy(72,16);
  end;

  if (key_code= 72) {Up} then
  begin
   if Player.Position > 0 then dec(Player.Position);
   Player.pattern_num := order[Player.Position];
   fastwrite(73,5,palette.text_color2,palette.window_color,hexb(Player.pattern_num));
   Update_Order(false,true);
   Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,Editor.markedrow-8,Editor.markedrow+8);
   Update_Pattern(Editor.markedrow-8,false);
   displaybuffer(buffer.screen1);
   Clear_Keypress;
  end;

  if (key_code= 80) {Down} then
  begin
   if Player.Position < Player.Songlength-1 then inc(Player.Position);
   Player.pattern_num := order[Player.Position];
   fastwrite(73,5,palette.text_color2,palette.window_color,hexb(Player.pattern_num));
   Update_Order(false,true);
   Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,Editor.markedrow-8,Editor.markedrow+8);
   Update_Pattern(Editor.markedrow-8,false);
   displaybuffer(buffer.screen1);
   Clear_Keypress;
  end;

  if (key_code= 15) {Tab} or (key_code= 28) {Return} then
  begin
   mark(75,20,2);
   gotoxy(76,20);
   ChangeAttrHLine(68,16,7,0);
   Update_Order(true,false);

   Clear_Keypress;

   repeat
       if is_key_pressed then Get_Key;

         if (key_code= 78) or (key_code = 27) or (key_code = 13) then		{+}
         begin
           if Player.loop < Player.MaxPattern then
           begin
            inc(Player.loop);
            fastwrite(75,20,14,4,hexb(Player.loop));
            displaybuffer(buffer.screen1);
           end;

           Clear_keypress;
         end;

         if (key_code= 74) or (key_code = 53) or (key_code = 12) then			{-}
         begin
           if Player.loop > 0 then
           begin
            dec(Player.loop);
            fastwrite(75,20,14,4,hexb(Player.loop));
            displaybuffer(buffer.screen1);
           end;

           Clear_keypress;
         end;


         if (getX = 75) and ((key_code in [30,48,46,32,38,33]) or
            (key_code in [2..11])) then
         begin
           putchar(75,20,14,4,upcase(key_ASCII));
           gotoxy(76,20);
           displaybuffer(buffer.screen1);
           if hex2dec(getchar(75,20)+getchar(76,20)) <= Player.MaxPattern then
           player.loop := hex2dec(getchar(75,20)+getchar(76,20));
           Clear_Keypress;
         end;

         if (getX = 76) and ((key_code in [30,48,46,32,38,33]) or
            (key_code in [2..11])) then
         begin
           putchar(76,20,14,4,upcase(key_ASCII));
           displaybuffer(buffer.screen1);
           if hex2dec(getchar(75,20)+getchar(76,20)) <= Player.MaxPattern then
           player.loop := hex2dec(getchar(75,20)+getchar(76,20));
           Clear_Keypress;
         end;

         if (key_code= 77) or (key_code = 244) {Right} then
         begin
          gotoxy(76,20);
          Clear_Keypress;
         end;

         if (key_code= 75) {Left} then
         begin
          gotoxy(75,20);
          Clear_Keypress;
         end;

   until (key_code= 1) or (key_code= 28) or (key_code= 15);

   fastwrite(75,20,palette.text_color2,palette.window_color,hexb(player.loop));

   Clear_Keypress;
   break;

 end;

  if (key_code= 78) or (key_code = 27) or (key_code = 13) then		{+}
  begin
    if order[Player.Position] < Player.MaxPattern then
    begin
      inc(order[Player.Position]);
    end;
    Player.pattern_num := order[Player.Position];
    fastwrite(72,16,14,4,hexb(Player.pattern_num));
    fastwrite(73,5,palette.text_color2,palette.window_color,hexb(Player.pattern_num));
    Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,Editor.markedrow-8,Editor.markedrow+8);
    Update_Pattern(Editor.markedrow-8,false);
    Mark(69,16,5);
    displaybuffer(buffer.screen1);
    Clear_Keypress;
  end;

  if (key_code= 74) or (key_code = 53) or (key_code = 12) then			{-}
  begin
    if order[Player.Position] > 0 then
    begin
      dec(order[Player.Position]);
    end;
    Player.pattern_num := order[Player.Position];
    fastwrite(72,16,14,4,hexb(Player.pattern_num));
    fastwrite(73,5,palette.text_color2,palette.window_color,hexb(Player.pattern_num));
    Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,Editor.markedrow-8,Editor.markedrow-8);
    Update_Pattern(Editor.markedrow-8,false);
    Mark(69,16,5);
    displaybuffer(buffer.screen1);
    Clear_Keypress;
  end;



  if (getX = 72) and ((key_code in [30,48,46,32,38,33]) or
     (key_code in [2..11])) then
  begin
    putchar(72,16,14,4,upcase(key_ASCII));
    gotoxy(73,16);
    if hex2dec(getchar(72,16)+getchar(73,16)) <= Player.MaxPattern then
    begin
     order[Player.Position] := hex2dec(getchar(72,16)+getchar(73,16));
    end;
    Player.pattern_num := order[Player.Position];
    fastwrite(72,16,14,4,hexb(Player.pattern_num));
    fastwrite(73,5,palette.text_color2,palette.window_color,hexb(Player.pattern_num));
    Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,Editor.markedrow-8,Editor.markedrow+8);
    Update_Pattern(Editor.markedrow-8,true);
    clear_keypress;
  end;

  if (getX = 73) and ((key_code in [30,48,46,32,38,33]) or
     (key_code in [2..11])) then
  begin
    putchar(73,16,14,4,upcase(key_ASCII));
    if hex2dec(getchar(72,16)+getchar(73,16)) <= Player.MaxPattern then
    begin
     order[Player.Position] := hex2dec(getchar(72,16)+getchar(73,16));
    end;
    Player.pattern_num := order[Player.Position];
    fastwrite(72,16,14,4,hexb(Player.pattern_num));
    fastwrite(73,5,palette.text_color2,palette.window_color,hexb(Player.pattern_num));
    Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,Editor.markedrow-8,Editor.markedrow+8);
    Update_Pattern(Editor.markedrow-8,true);
    clear_keypress;
  end;

  until (key_code= 1) or (key_code= 28);

  ChangeAttrHLine(68,16,7,0);
  Update_Order(false,false);
  Player.pattern_num := order[Player.Position];
  fastwrite(73,5,palette.text_color2,palette.window_color,hexb(Player.pattern_num));
  Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,0,63);
  Update_Pattern(Editor.markedrow-8,true);
  gotoxy(ox,oy);
  Clear_Keypress;
end;








{============ Control of the pattern editor ==============}

Procedure Print_Loading_Message(boxtitle : string);
begin
  CopyBuffer(buffer.blankscreen,buffer.screen2);
  writeto(buffer.screen2);
  box(27,3,53,23,palette.text_color1,palette.menu_color,false,true);
  centeredtext(3,15,palette.menu_color,boxtitle);

  for i := 1 to 25 do
  putchar(27+i,21,palette.text_color1,palette.menu_color,'Ä');

  fastwrite(30,6,palette.text_color1,palette.menu_color,'Reading disk...');
  displaybuffer(buffer.screen2);
end;




Procedure Control_Pattern_Editor;
begin

  if (pedit = true) and
     (mainmenu = false) then
  begin
    cursor(true);
    Change_cursor(0,7);

    case key_code of

        1: {ESC}
        begin
          mainmenu := true;
      	  pause := true;
          Clipboard.mark := false;
          Mute_All;

          CopyBuffer(buffer.screen1,buffer.oldscreen);


      	  select := 1;
      	  DrawMenu(active_menu);
      	  Mark(Menu_pos[active_menu]+1,2+select,length(menu_text[active_menu][select]));

      	  displaybuffer(buffer.screen1);
      	  cursor(false);
      	  Clear_keypress;
      	  exit;
    	end;


    	59:		{F1 = Help}
    	begin
    	  mainmenu := true;
      	  pause := true;
      	  Mute_All;
      	  CopyBuffer(buffer.screen1,buffer.oldscreen);
      	  active_menu := 5;
      	  select := 1;
      	  DrawMenu(active_menu);
      	  Mark(Menu_pos[active_menu]+1,2+select,length(menu_text[active_menu][select]));
      	  displaybuffer(buffer.screen1);
      	  cursor(false);
      	  Clear_keypress;
      	  exit;
        end;

        60,31:  		{F2, Ctrl+s = Save; Alt+s = Solo}

        begin
          if ((key_code = 31) and (Ctrl_State = true)) or
             (key_code = 60) then
          begin
            pause := true;
            Mute_All;
            cursor(false);
	    Save_Song;
	    if error <> 6 then editor.saved := true;
	    Clear_Keypress;
            Draw_Pattern_Window(false);
            Draw_Editor_Window(false);
            Update_Pattern(Editor.markedrow-8,true);
            exit;
          end;

          if (key_code = 31) and (Alt_State = true) then   {Alt+S = Solo}
         begin
           if not editor.solo then
           begin
             for z := 0 to Editor.channels-1 do
             begin
               if z <> editor.chan-1 then
               begin
                 Player.muted[z] := true;
                 Mute_Voice(z);
               end
               else
                Player.muted[z] := false;
             end;
             editor.solo := true;
           end
           else
           begin
             fillchar(player.muted,sizeof(player.muted),0);
             editor.solo := false;
           end;

          Update_Pattern(Editor.MarkedRow-8,true);
          Clear_Keypress;
         end;

        end;

	61, 38:  		{F3, Ctrl+L = Load}
        begin
          if ((key_code = 38) and (Ctrl_State = true)) or
             (key_code = 61) then
          begin
            pause := true;
            Mute_All;
            cursor(false);

	    Print_Loading_Message(' Load a song ');

  	    LoadTNDY(User_selected_File('*.tnd',Sort_by_Name,30,4,17,buffer.screen2));
  	    if dir_error = 2 then error := 5; {the fileselector ran out of mem...}
  	    Proceed_Errors;
	    writeto(buffer.screen1);
	    cursor(true);

            if error <> 6 then {no user abort}
            begin
              Player.Position := 0;
              Player.pattern_num := order[Player.Position];
              Player.row := 0;
              Editor.chan := 1;
              Editor.markedrow := 0;
              Editor.Playtime := Player.tempo div 4;
              editor.saved := true;
              CopyBuffer(buffer.blankscreen,buffer.screen1);
              Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,0,63);
              Draw_Pattern_Window(false);
              Draw_Editor_Window(false);
              mainmenu := false;
              Update_Pattern(Editor.markedrow-8,true);
              gotoxy(Editor.p_xp+4,14);
              pedit := true;
             end;

             Clear_Keypress;
             displaybuffer(buffer.screen1);
          end;
        end;


        62: 		{F4 Toggle Trace}
        begin
          if ptn.tracemode = true then
           ptn.tracemode := false
          else
           ptn.tracemode := true;
          Clear_Keypress;
        end;




        63:               {F5 = Play song}
        begin
          Start_Play_Song;
        end;


        65: 		 {F7 = Play song from current position}
        begin
          Start_Play_Cursor;
        end;


        66: 		 {F8 = Play current pattern}
        begin
         Start_Play_Pattern;
        end;

        67: 		 {F9 = Transpose}
        begin
          Cursor(false);
          if editor.chan < editor.channels then
            Transpose_Menu(editor.chan);
          Cursor(true);
        end;



        68: 		 {F10 = Stop all outout}
        begin
          Mute_all;                             {Mute all output}
          Clear_Keypress;
        end;


        $78..$7C:			{Alt+1 to 5 Mute/Unmute channel}
        begin
          if key_code-$78 <= Editor.channels-1 then
          begin
            if Player.muted[key_code-$78] = true then
               Player.muted[key_code-$78] := false
            else
            begin
              Player.muted[key_code-$78] := true;
              Mute_Voice(key_code-$78);
            end;
            Update_Pattern(Editor.MarkedRow-8,true);
          end;
          Clear_Keypress;
       end;



       57: {Space}
       begin
         cursor(false);
         Player.row := Editor.markedrow;
         Editor.play_row := true;
         fillchar(current,sizeof(current),0);  {Clear current event buffer}
         play_row(Player.row);  {Play current row}
         inc(Player.row);
         if Player.row = 64 then Player.row := 0;
         Editor.markedrow := Player.row;
         Update_Pattern(Player.row-8,true);
         editor.playticks := Player.speed-1;
         cursor(true);

       end;




       72, 133: {Up (133 for Tandy)}
       begin
         if (L_Shift_State = true) or (R_Shift_State = true) then   {Shift + Up = Mark}
         begin
           if not clipboard.mark then
           begin
             Clipboard.mark := true;
             Clipboard.track := Editor.chan-1;

             if Editor.chan = Editor.channels then
               Clipboard.noise := true
             else
               Clipboard.noise := false;

             Clipboard.endpos := Editor.Markedrow;

             if (Editor.MarkedRow > 0)  then
                Clipboard.startpos := Editor.Markedrow-1
             else
                Clipboard.startpos := Editor.Markedrow;

           end
           else
           begin
             if (editor.markedrow > clipboard.startpos) then
             begin
                if (editor.markedrow > 0) then
                dec(clipboard.endpos);
                if clipboard.endpos = clipboard.startpos then
                begin
                  Clipboard.mark := false;
                end;
             end
             else
             begin
                if editor.markedrow > 0 then
                dec(clipboard.startpos);
             end;

           end;

         end
         else
           Clipboard.mark := false;

         if (Editor.MarkedRow >= 0) and (Editor.MarkedRow <= 63) then
         Update_Pattern(Editor.MarkedRow-9,false);
       end;




       80, 134: {Down}
       begin
         if (L_Shift_State = true) or (R_Shift_State = true) then   {Shift + Up = Mark}
         begin
           if not clipboard.mark then
           begin
             Clipboard.mark := true;
             Clipboard.track := Editor.chan-1;

             if Editor.chan = Editor.channels then
               Clipboard.noise := true
             else
               Clipboard.noise := false;

             Clipboard.startpos := Editor.Markedrow;

             if (Editor.MarkedRow < 63)  then
                Clipboard.endpos := Editor.Markedrow+1
             else
                Clipboard.endpos := Editor.Markedrow;
           end
          else
           begin
             if (editor.markedrow >= clipboard.endpos) then
             begin
                if (editor.markedrow < 63) then
                inc(clipboard.endpos)
             end
             else
             begin
                if editor.markedrow < clipboard.endpos then
                inc(clipboard.startpos);

                if clipboard.startpos = clipboard.endpos then
                begin
                  Clipboard.mark := false;
                end;
             end;
           end;

         end
         else
            Clipboard.mark := false;

         if (Editor.MarkedRow < 63) and (Editor.MarkedRow >= 0) then
         Update_Pattern(Editor.MarkedRow-7,false);

       end;

       77, 136, 244: {Right}
       begin
         if (L_Shift_State = true) or (R_Shift_State = true) then
         {Shift + Right = Next pattern (workaround for pre xt machines)}
         begin
           Clipboard.mark := false;
           if Player.pattern_num < Player.MaxPattern then {if there is already a next pattern, load it}
           begin
             inc(Player.pattern_num);
             fastwrite(73,5,palette.text_color2,palette.window_color,hexb(Player.pattern_num));
             Player.row := 0;
             Editor.MarkedRow := 0;
             Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,0,63);
             Update_Pattern(Editor.MarkedRow-8,false);
           end;
         end
         else
         begin

           if (Editor.octave < 2) and (Editor.chan <> 3) then
           begin
             Editor.octave := 2;
             Draw_Voice_Info;
           end;

           if Editor.chan < Editor.channels then
           begin

             if (Editor.chan = 4) then   {Speaker track}
             begin
               if getX = (editor.p_xp+13)+((Editor.chan-1)*11) then
               begin
                 inc(Editor.chan);
                 Draw_Noise_Info;
                 noteedit := true;
                 gotoxy((editor.p_xp+4)+((Editor.chan-1)*11),14);
               end
               else
               begin
                 noteedit := false;
                 if getX = (editor.p_xp+12)+((Editor.chan-1)*11) then gotoxy((editor.p_xp+13)+((Editor.chan-1)*11),14);
                 if getX = (editor.p_xp+11)+((Editor.chan-1)*11) then gotoxy((editor.p_xp+12)+((Editor.chan-1)*11),14);
                 if getX = (editor.p_xp+6)+((Editor.chan-1)*11) then gotoxy((editor.p_xp+11)+((Editor.chan-1)*11),14);
                 if getX = (editor.p_xp+4)+((Editor.chan-1)*11) then gotoxy((editor.p_xp+6)+((Editor.chan-1)*11),14);
               end;
             end
             else
             begin

               if getX = (editor.p_xp+13)+((Editor.chan-1)*11) then
               begin
                 inc(Editor.chan);

                 If Editor.chan = Editor.channels then
                 Draw_Noise_Info;

                 noteedit := true;
                 gotoxy((editor.p_xp+4)+((Editor.chan-1)*11),14);
               end
               else
               begin
                 noteedit := false;
                 if getX = (editor.p_xp+12)+((Editor.chan-1)*11) then gotoxy((editor.p_xp+13)+((Editor.chan-1)*11),14);
                 if getX = (editor.p_xp+11)+((Editor.chan-1)*11) then gotoxy((editor.p_xp+12)+((Editor.chan-1)*11),14);
                 if getX = (editor.p_xp+8)+((Editor.chan-1)*11) then gotoxy((editor.p_xp+11)+((Editor.chan-1)*11),14);
                 if getX = (editor.p_xp+6)+((Editor.chan-1)*11) then gotoxy((editor.p_xp+8)+((Editor.chan-1)*11),14);
                 if getX = (editor.p_xp+4)+((Editor.chan-1)*11) then gotoxy((editor.p_xp+6)+((Editor.chan-1)*11),14);
               end;
             end;

           end
           else
           begin
             if getX = ((editor.p_xp+10)+((Editor.chan-1)*11)) then
             begin
               Editor.chan := 1;
               Draw_voice_info;

               noteedit := true;
               gotoxy((editor.p_xp+4)+((Editor.chan-1)*11),14);
             end
             else
             begin
               noteedit := false;
               if getX = (editor.p_xp+9)+((Editor.chan-1)*11) then gotoxy((editor.p_xp+10)+((Editor.chan-1)*11),14);
               if getX = (editor.p_xp+4)+((Editor.chan-1)*11) then gotoxy((editor.p_xp+9)+((Editor.chan-1)*11),14);
             end;
           end;
        end;
       end;


       75, 135: {Left}
       begin
         if (L_Shift_State = true) or (R_Shift_State = true) then
         {Shift + Left = Prev. pattern (workaround for pre xt machines)}
         begin
           Clipboard.mark := false;

           if Player.pattern_num > 0 then {if there is a previous pattern, load it}
           begin
             dec(Player.pattern_num);
             fastwrite(73,5,palette.text_color2,palette.window_color,hexb(Player.pattern_num));
             Player.row := 0;
             Editor.MarkedRow := 0;
             Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,0,63);
             Update_Pattern(Editor.MarkedRow-8,false);
           end;
         end
         else
         begin
           if (Editor.octave < 2) and (Editor.chan <> 3) then
           begin
             Editor.octave := 2;
             Draw_Voice_Info;
           end;

          if Editor.chan = Editor.channels then
          begin
            if getX = (editor.p_xp+4)+((Editor.chan-1)*11) then
            begin
              dec(Editor.chan);
              Draw_Voice_Info;

             gotoxy((editor.p_xp+13)+((Editor.chan-1)*11),14);
             noteedit := false;
           end;

           if getX = (editor.p_xp+9)+((Editor.chan-1)*11) then
           begin
             gotoxy((editor.p_xp+4)+((Editor.chan-1)*11),14);
             noteedit := true;
           end;

           if getX = (editor.p_xp+10)+((Editor.chan-1)*11) then gotoxy((editor.p_xp+9)+((Editor.chan-1)*11),14);

          end
          else
          begin

            if getX = (editor.p_xp+4)+((Editor.chan-1)*11) then
            begin

              if Editor.chan > 1 then
              begin
                dec(Editor.chan);
                gotoxy((editor.p_xp+13)+((Editor.chan-1)*11),14);
                noteedit := false;
              end
              else
              begin
                Editor.chan := Editor.channels;
                Draw_Noise_Info;

                gotoxy((editor.p_xp+10)+((Editor.chan-1)*11),14);
                noteedit := false;
              end;

            end
            else
            begin

              if getX = (editor.p_xp+6)+((Editor.chan-1)*11) then
              begin
                noteedit := true;
                gotoxy((editor.p_xp+4)+((Editor.chan-1)*11),14);
              end;

              if editor.chan <> 4 then
              begin
  	        if getX = (editor.p_xp+8)+((Editor.chan-1)*11) then gotoxy((editor.p_xp+6)+((Editor.chan-1)*11),14);
                if getX = (editor.p_xp+11)+((Editor.chan-1)*11) then gotoxy((editor.p_xp+8)+((Editor.chan-1)*11),14);
                if getX = (editor.p_xp+12)+((Editor.chan-1)*11) then gotoxy((editor.p_xp+11)+((Editor.chan-1)*11),14);
                if getX = (editor.p_xp+13)+((Editor.chan-1)*11) then gotoxy((editor.p_xp+12)+((Editor.chan-1)*11),14);
              end
              else
              begin
                if getX = (editor.p_xp+11)+((Editor.chan-1)*11) then gotoxy((editor.p_xp+6)+((Editor.chan-1)*11),14);
                if getX = (editor.p_xp+12)+((Editor.chan-1)*11) then gotoxy((editor.p_xp+11)+((Editor.chan-1)*11),14);
                if getX = (editor.p_xp+13)+((Editor.chan-1)*11) then gotoxy((editor.p_xp+12)+((Editor.chan-1)*11),14);
              end;


           end;

         end;
      end;
      end;


       15: {Tab}
       begin
         if (Editor.octave < 2) and (Editor.chan <> 3) then
          Editor.octave := 2;

         if (L_Shift_State = false) and (R_Shift_State = false) then   {Jump to next channel}
         begin
           if Editor.chan < Editor.channels then
           begin
    	     inc(Editor.chan);
    	     if Editor.chan = Editor.channels then Draw_noise_info;
    	     noteedit := true;
    	     gotoxy((editor.p_xp+4)+((Editor.chan-1)*11),14);
           end
           else
           begin
    	    Editor.chan := 1;
            Draw_voice_info;
    	    noteedit := true;
    	    gotoxy((editor.p_xp+4)+((Editor.chan-1)*11),14);
           end;
         end
         else							 {Backtab - Jump to previous channel}
         begin
           if Editor.chan > 1 then
           begin
    	     dec(Editor.chan);
    	     Draw_Voice_Info;
    	     noteedit := true;
    	     gotoxy((editor.p_xp+4)+((Editor.chan-1)*11),14);
           end
          else
           begin
    	     Editor.chan := Editor.channels;
    	     Draw_noise_info;
    	     noteedit := true;
    	     gotoxy((editor.p_xp+4)+((Editor.chan-1)*11),14);
           end;
         end;


      end;


       71:  {Home}
       begin
         if (L_Shift_State = true) or (R_Shift_State = true) then   {Shift + Home = inc. volume}
         begin
           if Editor.curr_vol < 15 then inc(Editor.curr_vol);
           fastwrite(73,7,palette.text_color2,palette.window_color,hexn(Editor.curr_vol));
         end
         else
         begin      						       {Home = go on top of  pattern}
           Player.row := 0;
           Editor.MarkedRow := 0;
           if clipboard.mark then
            clipboard.startpos := 0;

           Update_Pattern(-8,false);
         end;
       end;

       79:   {End}
       begin
         if (L_Shift_State = true) or (R_Shift_State = true) then   {Shift + End = dec. volume}
         begin
           if Editor.curr_vol > 0 then dec(Editor.curr_vol);
           fastwrite(73,7,palette.text_color2,palette.window_color,hexn(Editor.curr_vol));
         end
         else                                                      {End = go to the end of the pattern}
         begin
           Player.row := 63;
           Editor.MarkedRow := 63;

	   if clipboard.mark then
           clipboard.endpos := 63;

           Update_Pattern(55,false);
         end;
       end;

       73:  {Page up}
       begin
         if (L_Shift_State = true) or (R_Shift_State = true) then   {Shift + Pgup = increase octave}
         begin
           if (Editor.chan = Editor.channels) then
           begin
             if editor.noisetype < 1 then inc(editor.noisetype);
             Draw_Noise_Info;
           end
           else
           begin
             if editor.octave < 9 then inc(editor.octave);
             fastwrite(73,6,palette.text_color2,palette.window_color,hexn(editor.octave));
           end;
         end;

         if (L_Shift_State = false) and
           (R_Shift_State = false) then
         begin
           if Editor.MarkedRow >= 16 then dec(Editor.MarkedRow,16) else Editor.MarkedRow := 0;
           Player.row := Editor.MarkedRow;
           Update_Pattern(Editor.MarkedRow-8,false);
         end;
       end;

       81:   {Pagedown}
       begin
         if (L_Shift_State = true) or (R_Shift_State = true) then   {Shift and Pgdown = decrease octave}
         begin
           if (Editor.chan < 4) then
           begin
             if editor.octave > 2 then dec(editor.octave);
             fastwrite(73,6,palette.text_color2,palette.window_color,hexn(editor.octave));
           end;
           if (Editor.chan = 4) and (Editor.channels = 5) then
           begin
             if editor.octave > 1 then dec(editor.octave);
             fastwrite(73,6,palette.text_color2,palette.window_color,hexn(editor.octave));
           end;
           if (Editor.chan = Editor.channels) then
           begin
             if editor.noisetype > 0 then dec(editor.noisetype);
             Draw_Noise_Info;
           end;
         end
         else
         begin
           inc(Editor.MarkedRow,16);
           if Editor.MarkedRow > 63 then Editor.MarkedRow := 63;
           Player.row := Editor.MarkedRow;
           Update_Pattern(Editor.MarkedRow-8,false)
         end;
       end;

       14:  {Backspace}
       begin
         for z := Editor.Markedrow-1 to 63 do
         begin
             Patterns[Player.pattern_num]^[z][Editor.chan-1] :=
             Patterns[Player.pattern_num]^[z+1][Editor.chan-1];
         end;
         fillchar(Patterns[Player.pattern_num]^[63][Editor.chan-1],sizeof(TNDYevent),0);
         if Editor.MarkedRow = 0 then Editor.MarkedRow := 64;
         Update_Screenbuffer_Track(Buffer.Pbuffer,Player.pattern_num,Editor.chan-1,Editor.MarkedRow-1,63);
         Update_Pattern(Editor.MarkedRow-9,false);
         editor.saved := false;
       end;

       82 {Insert}, 155 {Ins on Tandy}:
       begin
           for z := 63 downto Editor.MarkedRow+1 do    {Move down all existing events}
           begin
             Patterns[Player.pattern_num]^[z][Editor.chan-1] :=
             Patterns[Player.pattern_num]^[z-1][Editor.chan-1];
           end;

           {Clear event at marked position}

           fillchar(Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1],sizeof(TNDYevent),0);

           Update_Screenbuffer_Track(Buffer.Pbuffer,Player.pattern_num,Editor.chan-1,Editor.MarkedRow,63);

           if Editor.MarkedRow = 63 then    {if it's the last row, jump to the start of the pattern}
           begin
             Editor.MarkedRow := 0;
             Update_Pattern(Editor.MarkedRow-8,false);
           end
           else
             Update_Pattern(Editor.MarkedRow-7,false);

           editor.saved := false;
       end;


       83: {Delete}
       begin

         if (L_Shift_State = false) and (R_Shift_State = false) then
         begin

           if clipboard.mark then				{clear block marked by user}
           begin
             for z := Clipboard.startpos to Clipboard.endpos do
                 fillchar(Patterns[Player.pattern_num]^[z][Clipboard.track],sizeof(tndyevent),0);
             Update_Screenbuffer_Track(Buffer.Pbuffer,Player.pattern_num,Clipboard.track,Clipboard.startpos,Clipboard.endpos);

           end
           else
           begin

             if (noteedit = true) or
                (getX = (editor.p_xp+6)+((Editor.chan-1)*11)) then
             begin
               Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 0;
               Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].octave := 0;  {clear note, octave and volume}
             end
             else
             begin
               if (getX = (editor.p_xp+8)+((Editor.chan-1)*11)) then
                Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].volume := 0;

               if (getX > (editor.p_xp+8)+((Editor.chan-1)*11)) and (Editor.chan < Editor.channels) then
               begin
                 {if it's on the effect or parameter column just clear them}
                 Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].effect := 0;
                 Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].ep := 0;
               end
               else
               begin
                 {clear note,octave and volume = freq, noise type and volume here}
                 Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 0;
                 Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].octave := 0;
                 Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].volume := 0;
               end;
             end;

              Update_Screenbuffer_Track(Buffer.Pbuffer,Player.pattern_num,Editor.chan-1,Editor.MarkedRow,Editor.MarkedRow);
           end;

         end
         else {Shift + Del = Delete complete event}
         begin
           fillchar(Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1],sizeof(TNDYEvent),0);
           Update_Screenbuffer_Track(Buffer.Pbuffer,Player.pattern_num,Editor.chan-1,Editor.MarkedRow,Editor.MarkedRow);
         end;

         Update_Pattern(Editor.MarkedRow-8,false);		{Display the updated pattern}
         editor.saved := false;
     end;


       28: {Enter/Return}
       begin
         Clipboard.mark := false;
         Control_Order_Editor;
       end;

       78,13:  {+ on PC and Tandy}
       begin
         Clipboard.mark := false;
         if Player.pattern_num < Player.MaxPattern then {if there is already a next pattern, load it}
         begin
           inc(Player.pattern_num);
           fastwrite(73,5,palette.text_color2,palette.window_color,hexb(Player.pattern_num));
           Player.row := 0;
           Editor.MarkedRow := 0;
           Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,0,63);
           Update_Pattern(Editor.MarkedRow-8,false);
         end;
       end;


       74,12: {- on PC and Tandy}
       begin
         Clipboard.mark := false;
         if Player.pattern_num > 0 then {if there is a previous pattern, load it}
         begin
           dec(Player.pattern_num);
           fastwrite(73,5,palette.text_color2,palette.window_color,hexb(Player.pattern_num));
           Player.row := 0;
           Editor.MarkedRow := 0;
           Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,0,63);
           Update_Pattern(Editor.MarkedRow-8,false);
         end;
       end;

       25: {P}
       begin
         if (CTRL_State = true) then {Ctrl+P = Clear Pattern}
         begin
           Clipboard.mark := false;
           fillchar(patterns[Player.pattern_num]^,sizeof(TNDYPattern),0);
           Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,0,63);
           Update_Pattern(Editor.MarkedRow-8,true);
           editor.saved := false;
           exit;
         end;
       end;


       19: {R}
       begin
         if (CTRL_State = true) then {Ctrl+R = Remove/delete Pattern}
         begin
           Clipboard.mark := false;
           Delete_Pattern_Diag;
           clear_keypress; {We do not want the pressed P to be processed as a note as well...}
           editor.saved := false;
           exit;
         end;
       end;

       30: {A}
       begin
         if (CTRL_State = true) then {Ctrl+A = Add Pattern}
         begin
           Clipboard.mark := false;
           Add_new_Pattern_Diag;
           clear_keypress; {We do not want the pressed P to be processed as a note as well...}
           editor.saved := false;
           exit;
         end;
       end;


       20:   {T}
       begin
         if (CTRL_State = true) then {Ctrl+T = Clear Track}
         begin
           Clipboard.mark := false;
           editor.saved := false;
           for z := 0 to 63 do
             fillchar(patterns[Player.pattern_num]^[z][Editor.chan-1],sizeof(TNDYevent),0);
           Update_Screenbuffer_Track(Buffer.Pbuffer,Player.pattern_num,Editor.chan-1,0,63);
           Update_Pattern(Editor.MarkedRow-8,false);
           clear_keypress; {We do not want the pressed T to be processed as a note as well...}
         end;
       end;


       45: {X}
       begin
        if (CTRL_State = true) then {Ctrl+X = Cut event or block}
        begin
          if clipboard.mark then
          begin
            for z := Clipboard.startpos to Clipboard.endpos do
            begin
              Clipboard.buffer[z] := Patterns[Player.pattern_num]^[z][Clipboard.track];
              fillchar(Patterns[Player.pattern_num]^[z][Clipboard.track],sizeof(tndyevent),0);
            end;

            clipboard.inuse := true;
          end
          else
          begin
            Clipboard.track := Editor.channels-1;
            Clipboard.buffer[0] := patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1];
            fillchar(patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1],sizeof(tndyevent),0);

            Clipboard.inuse := false;

            if Editor.chan = Editor.channels then
               Clipboard.noise := true
            else
               Clipboard.noise := false;
          end;
          Update_Screenbuffer_Track(Buffer.Pbuffer,Player.pattern_num,Clipboard.track,Clipboard.startpos,Clipboard.endpos);
          Update_Pattern(Editor.MarkedRow-8,false);
          clear_keypress; {We do not want the pressed T to be processed as a note as well...}
         end;

        end;



       46: {C}
       begin
         if (CTRL_State = true) then {Ctrl+C = Copy event or block}
         begin
           if clipboard.mark then
           begin
             for z := Clipboard.startpos to Clipboard.endpos do
             Clipboard.buffer[z] := Patterns[Player.pattern_num]^[z][Clipboard.track];
             clipboard.inuse := true;
           end
           else
           begin
             Clipboard.track := Editor.channels-1;
             Clipboard.buffer[0] := patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1];
             Clipboard.inuse := false;
              if Editor.chan = Editor.channels then
               Clipboard.noise := true
             else
               Clipboard.noise := false;
           end;

           clear_keypress; {We do not want the pressed C key to be handled as a note as well...}
         end;
       end;


       47:  {V}
       begin
         if (CTRL_State = true) then {Ctrl+V = Paste}
         begin
           {No voice data in noise channel and no noise data in voice channels}
             if ((Editor.chan = Editor.Channels) and (Clipboard.noise = false)) or
                ((Editor.chan < Editor.Channels) and (Clipboard.noise = true)) then
                exit;

           if clipboard.inuse then
           begin
             for z := Editor.Markedrow to Editor.Markedrow+(Clipboard.endpos-Clipboard.startpos) do
             begin
               if z > 63 then break;
                 Patterns[Player.pattern_num]^[z][Editor.chan-1] :=
                 Clipboard.buffer[Clipboard.startpos+(z-Editor.Markedrow)]

            end;
           end
           else
           begin
             Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1] := Clipboard.buffer[0];
           end;

           Update_Screenbuffer_Track(Buffer.Pbuffer,Player.pattern_num,Editor.chan-1,0,63);

           Update_Pattern(Editor.MarkedRow-8,false);
           editor.saved := false;

           clear_keypress; {We do not want the pressed T to be processed as a note as well...}
         end;
       end;



    end; {case}




   {=============== Notes =================}



   if noteedit then {We are in the note column of the pattern editor}
   begin


     if Editor.chan < Editor.channels then  {and this is a voice channel}
     begin

       {Note keys}
       if (key_code in [3,4,6,7,8,10,11,16,17,18,19,20,21,22,23,24,25,26,27,29,31,32,34,35,36,44,45,46,47,48,49,50]) then
       begin

         case key_code of

         16,23,44:  {Q,I,Z  ( Note C )}
         begin
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 1;
         end;

         3,10,31:  {2,9,S (Note C#)}
         begin
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 2;
         end;

         17,24,45:  {W,O,X (Note D)}
         begin
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 3;
         end;

         4,11,32:  {3,0,D (Note D#)}
         begin
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 4;
         end;

         18,25,46: {E,P,C (Note E)}
         begin
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 5;
         end;

         19,26,47: {R,Ü,V (Note F)}
         begin
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 6;
         end;

         6,13,34:  {5,´,G (Note F#)}
         begin
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 7;
         end;

         20,27,48: {T,B (Note G)}
         begin
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 8;
         end;

         7,35: {6,H (Note G#)}
         begin
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 9;
         end;

         21,49: {Z,N (Note A)}
         begin
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 10;
         end;

         8,36: {7,J (Note A#)}
         begin
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 11;
         end;

         22,29,50: {U, ,M (Note B)}
         begin
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 12;
         end;

         end; {case}



       {And now add the octave for the entered note...}

        if (key_code>= 16) and (key_code<= 22) or     {2,3,5,6,7...}
          (key_code in [3,4,6,7,8]) then
        begin
          Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].octave := editor.octave;
        end;

        if (key_code>= 23) and (key_code<= 28) or
          (key_code in [10,11,13]) then
        begin
          Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].octave := editor.octave+1;
        end;


        if (key_code>= 44) and (key_code<= 50) or
          (key_code in [31,32,34,35,36]) then
        begin
          Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].octave := editor.octave-1;

          if not ((Editor.channels =5) and ((Editor.chan-1) = 3)) then  {If this is not the speaker channel...}
          begin

            if Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].octave = 1 then
            begin
             Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].octave := 2;
            end;

            if (Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note in [11,12]) and
               (Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].octave = 2) then
            begin
            {make sure that we don't go lower than A2...}
             Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 10;
            end;
          end;
        end;



         {Add the actual volume}
          if Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].volume = 0 then
          Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].volume := Editor.curr_vol+1;


          {Check if the note is within range of the tandy sound chip}
          if (Editor.chan in [1..3]) then
          begin
            if (Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].octave < 2) then
             Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].octave := 2;


            if (Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].octave = 2) and
               (Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note < 10) then
               	{A-2 is the lowest note the chip can handle}
               Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 10;
          end;


          Fastwrite((editor.p_xp+4)+((Editor.chan-1)*11),14,palette.text_color1,palette.mark_color,
                    snote[Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note]+
                    hexn(Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].octave));

           if (editor.chan < 4) then
           Fastwrite((editor.p_xp+4)+((Editor.chan-1)*11)+4,14,palette.text_color1,palette.mark_color,
                     hexn(Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].volume-1));

          if Monochrome then
          ChangeAttrHLine((editor.p_xp+4)+((Editor.chan-1)*11),14,5,$70);

          displaybuffer(buffer.screen1);

          Mute_All;
          Editor.playticks := 0;               {Reset tick counter}
          Editor.play_note := true;
          {and play it}
          Play_Voice(Editor.chan-1,note_to_freq(Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note,
                            Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].octave),0);

          Update_Screenbuffer_Track(Buffer.Pbuffer,Player.pattern_num,Editor.chan-1,Editor.MarkedRow,Editor.MarkedRow);

          if Editor.MarkedRow < 63 then              {Update the patternview}
          Update_Pattern(Editor.MarkedRow-7,false)
          else
          Update_Pattern(-8,false);

          editor.saved := false; {we made unsaved changes here}

       end;

     end
    else
     begin  {We're on the Noise channel}

       if key_code in [2..5] then {1..3}
       begin
         Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := key_code-1;
         Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].volume := Editor.curr_vol+1;

         Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].octave := editor.noisetype+1;


         case Editor.noisetype of
          0: Fastwrite((editor.p_xp+9)+((Editor.chan-1)*11),14,palette.text_color1,palette.mark_color,' P');
          1: Fastwrite((editor.p_xp+9)+((Editor.chan-1)*11),14,palette.text_color1,palette.mark_color,' W');
         end;

         Fastwrite((editor.p_xp+4)+((Editor.chan-1)*11),14,palette.text_color1,palette.mark_color,
                   Snoise[Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note]+' ');

          if Monochrome then
          ChangeAttrHLine((editor.p_xp+4)+((Editor.chan-1)*11),14,3,$70);

         Mute_All;

         Editor.playticks := 0;               {Reset counter}
         Editor.play_note := true;

         TANDY_PlayNoise(Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note,
                         Editor.noisetype,0);

	 Update_Screenbuffer_Track(Buffer.Pbuffer,Player.pattern_num,Editor.chan-1,Editor.MarkedRow,Editor.MarkedRow);

         if Editor.MarkedRow < 63 then
          Update_Pattern(Editor.MarkedRow-7,false)
         else
          Update_Pattern(-8,false);

         editor.saved := false; {we made unsaved changes here}

       end;

    end;  {Noise channel}




     if (key_code= 53) or (key_code= 86) then {-/<}          {key off}
     begin
          Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 13;
          Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].volume := 0;
          Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].effect := 0;
          Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].ep := 0;

          Mute_All; 		{Mute all output}

          Update_Screenbuffer_Track(Buffer.Pbuffer,Player.pattern_num,Editor.chan-1,Editor.MarkedRow,Editor.MarkedRow);

          if Editor.MarkedRow < 63 then
           Update_Pattern(Editor.MarkedRow-7,false)
          else
           Update_Pattern(-8,false);

          editor.saved := false; {we made unsaved changes here}

     end;


  end     {Noteedit = true}
  else
  begin


        {Noisetype}
     if (key_code= 25) or (key_code= 17) then
     begin

       if (getX = (editor.p_xp+9)+((Editor.chan-1)*11)) and
          (Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note > 0) then  {Change type of Noise}
       begin
          case key_code of
           17 :
            begin
             Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].octave := 2;
             putchar((editor.p_xp+9)+((Editor.chan-1)*11),14,palette.text_color2,palette.mark_color,'W');
             if Monochrome then
             ChangeAttr((editor.p_xp+9)+((Editor.chan-1)*11),14,$70);
            end;
           25 :
            begin
             Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].octave := 1;
             putchar((editor.p_xp+9)+((Editor.chan-1)*11),14,palette.text_color2,palette.mark_color,'P');
             if Monochrome then
             ChangeAttr((editor.p_xp+9)+((Editor.chan-1)*11),14,$70);
            end;
          end;
          editor.saved := false; {we made unsaved changes here}
       end;
       Update_Screenbuffer_Track(Buffer.Pbuffer,Player.pattern_num,Editor.chan-1,Editor.MarkedRow,Editor.MarkedRow);



     end;




     {Change octave}

     if (key_code in [2..9]) then
     begin
       if (getX = (editor.p_xp+6)+((Editor.chan-1)*11)) and
          (Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note in [1..12]) then
       begin
        Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].octave := key_code-1;
        putchar((editor.p_xp+6)+((Editor.chan-1)*11),15,palette.text_color2,palette.mark_color,upcase(key_Ascii));
        if Monochrome then
        ChangeAttr((editor.p_xp+6)+((Editor.chan-1)*11),14,$70);
        editor.saved := false; {we made unsaved changes here}
       end;

     end;


      {Volume and FX Edit}
     if (key_code in [30,48,46,32,18,33]) or  (key_code in [2..11]) then
     begin

       {FX}
       if getX = (editor.p_xp+13)+((Editor.chan-1)*11) then			{second digit of parameter}
       begin
         putchar((editor.p_xp+13)+((Editor.chan-1)*11),14,palette.text_color2,palette.mark_color,upcase(key_Ascii));
         Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].ep :=
         hex2dec(getchar((editor.p_xp+12)+((Editor.chan-1)*11),14)+getchar((editor.p_xp+13)+((Editor.chan-1)*11),14));
         if Monochrome then
         ChangeAttr((editor.p_xp+13)+((Editor.chan-1)*11),14,$70);
         editor.saved := false; {we made unsaved changes here}
       end;

       if getX = (editor.p_xp+12)+((Editor.chan-1)*11) then			{first digit of parameter}
       begin
        putchar((editor.p_xp+12)+((Editor.chan-1)*11),14,palette.text_color2,palette.mark_color,upcase(key_Ascii));
        Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].ep :=
        hex2dec(getchar((editor.p_xp+12)+((Editor.chan-1)*11),14)+getchar((editor.p_xp+13)+((Editor.chan-1)*11),14));
        if Monochrome then
        ChangeAttr((editor.p_xp+12)+((Editor.chan-1)*11),14,$70);
        editor.saved := false; {we made unsaved changes here}
       end;


       if getX = (editor.p_xp+11)+((Editor.chan-1)*11) then			{effect command}
       begin
        {
	 00 = Arpeggio
 	 01 = Portamento up
 	 02 = Portamento down
 	 03 = Porta to note / Toneslide
 	 04 = Volume slide
 	 05 = Toneslide + Volume slide
 	 06 = Note delay
 	 07 = Cut note
 	 08 = Early note
 	 0A = Set Fintetune, < 80h = decrease, > 80h = increase
 	 0B = Jump
 	 0D = Pattern break
 	 0F = Set Speed ( < 1F = set speed, >= 1F = set tempo)
        }

        if (upcase(key_Ascii) in ['0','1','2','3','4','5','6','7','8','A','B','D','F']) then	{valid command?}
        begin
          putchar((editor.p_xp+11)+((Editor.chan-1)*11),14,palette.text_color2,palette.mark_color,upcase(key_Ascii));
          if Monochrome then
          ChangeAttr((editor.p_xp+11)+((Editor.chan-1)*11),14,$70);

          Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].effect := hex2dec('0'+upcase(key_Ascii));
          editor.saved := false; {we made unsaved changes here}
        end;
       end;

       {Volume}

       if getX = (editor.p_xp+8)+((Editor.chan-1)*11) then
       begin
        if (upcase(key_Ascii) in ['0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F']) then {volume of a voice}
        begin
          putchar((editor.p_xp+8)+((Editor.chan-1)*11),14,palette.text_color2,palette.mark_color,upcase(key_Ascii));
          if Monochrome then
          ChangeAttr((editor.p_xp+8)+((Editor.chan-1)*11),14,$70);

          dummy := hex2dec('0'+upcase(key_Ascii));
          if dummy <= $F then
          begin
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].volume := dummy+1;
          end;
          editor.saved := false; {we made unsaved changes here}
        end;
       end;

       if (getX = (editor.p_xp+10)+((Editor.chan-1)*11)) and (Editor.chan = Editor.channels) then	{Volume of noise}
       begin
         if (upcase(key_Ascii) in ['0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F']) then
         begin
           putchar((editor.p_xp+10)+((Editor.chan-1)*11),14,palette.text_color2,palette.mark_color,upcase(key_Ascii));
           if Monochrome then
           ChangeAttr((editor.p_xp+10)+((Editor.chan-1)*11),14,$70);

           dummy := hex2dec('0'+upcase(key_Ascii));
           if dummy <= $F then
           begin
             Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].volume := dummy+1;
           end;
           editor.saved := false; {we made unsaved changes here}
         end;
      end;

      Update_Screenbuffer_Track(Buffer.Pbuffer,Player.pattern_num,Editor.chan-1,Editor.MarkedRow,Editor.MarkedRow);

         if Editor.MarkedRow < 63 then              {Update the patternview}
          Update_Pattern(Editor.MarkedRow-7,false)
          else
          Update_Pattern(-8,false);


   end; {Volume and FX edit}

 end; {Noteedit = false}
 end; {Pedit = true}


 displaybuffer(buffer.screen1); {Update the screen}



end;












{========================== Dialogs for main menu ==================}






Procedure Create_new_song_diag;
begin
  Clear_Pattern_Data; {Erase patterns from memory}
  fillchar(p_msg,sizeof(p_msg),0);  {Clear song description/message}
  fillchar(msg_buffer,sizeof(msg_buffer),0);
  msg_size := 0;

  fillchar(editor,sizeof(editor),0); {clear all editor data}
  fillchar(player,sizeof(player),0); {clear all player data}

  {set default values}
  Editor.d_tempo := 50; {Default tempo is 50 Hz}
  Editor.d_speed := 6; {Default speed 6 = 125 BPM}
  Player.speed := 6;
  Player.tempo := 50;
  Editor.Playtime := Player.tempo div 4;

  set_timer(50);

  Editor.orderview := -2;
  Editor.octave := 4;
  Editor.chan := 1;
  Editor.Channels := 4;
  Editor.noisetype := 0;
  Player.songlength := 1;
  Editor.saved := true;
  Editor.markedrow := 0;

  CopyBuffer(buffer.blankscreen,buffer.screen1);
  Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,0,63);
  Draw_Pattern_Window(false);
  Draw_Editor_Window(false);
  mainmenu := false;
  Update_Pattern(Editor.markedrow-8,true);
  gotoxy(Editor.p_xp+4,14);
  pedit := true;
end;


Procedure Load_a_song_diag;
begin
  CopyBuffer(buffer.blankscreen,buffer.screen2);
  writeto(buffer.screen2);

  Box(27,3,53,23,palette.text_color1,palette.menu_color,false,true);
  centeredtext(3,15,palette.menu_color,' Load a song ');

  for i := 1 to 25 do
     putchar(27+i,21,palette.text_color1,palette.menu_color,'Ä');

  LoadTNDY(User_selected_File('*.tnd',Sort_by_Name,30,4,17,buffer.screen2));
  if dir_error = 2 then error := 5; {the fileselector ran out of mem...}
  Proceed_Errors;
  writeto(buffer.screen1);

  if error <> 6 then {no user abort}
  begin
    Player.Position := 0;
    Player.pattern_num := order[Player.Position];
    Player.row := 0;
    Editor.chan := 1;
    Editor.markedrow := 0;
    Editor.Playtime := Player.tempo div 4;
    Editor.saved := true;

    Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,0,63);
    CopyBuffer(buffer.blankscreen,buffer.screen1);
    Draw_Pattern_Window(false);
    Draw_Editor_Window(false);
    mainmenu := false;
    Update_Pattern(-8,true);
    gotoxy(Editor.p_xp+4,14);
    pedit := true;
  end
  else
    pause := pstate;
end;


Procedure Import_MOD_diag;
begin
  CopyBuffer(buffer.blankscreen,buffer.screen2);
  writeto(buffer.screen2);

  Box(27,3,53,23,palette.text_color1,palette.menu_color,false,true);
  centeredtext(3,15,palette.menu_color,' Import Module ');
  for i := 1 to 25 do
     putchar(27+i,21,palette.text_color1,palette.menu_color,'Ä');
  Import_MOD(User_selected_File('*.mod',Sort_by_Name,30,4,17,buffer.screen2));
  if dir_error = 2 then error := 5; {the fileselector ran out of mem...}
     Proceed_Errors;

  writeto(buffer.screen1);

  if error <> 6 then {no user abort}
  begin
    Player.Position := 0;
    Player.pattern_num := order[0];
    Player.row := 0;
    Editor.chan := 1;
    Editor.markedrow := 0;
    Editor.Playtime := Player.tempo div 4;
    Editor.saved := true;

    Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,0,63);
    CopyBuffer(buffer.blankscreen,buffer.screen1);
    Draw_Pattern_Window(false);
    Draw_Editor_Window(false);
    mainmenu := false;
    Update_Pattern(-8,true);
    gotoxy(Editor.p_xp+4,14);
    pedit := true;
  end
  else
    pause := pstate;
end;



Procedure Import_SND_diag;
begin
  CopyBuffer(buffer.blankscreen,buffer.screen2);
  Print_Loading_Message(' Import game music ');

  Import_SND(User_selected_File('*.snd;*.0**;*.1**;*.2**;*.3**;*.4**;*.5**;*.6**;*.7**;*.8**;*.9**',
                                         Sort_by_Name,30,4,17,buffer.screen2));
  if dir_error = 2 then error := 5; {the fileselector ran out of mem...}
     Proceed_Errors;

  writeto(buffer.screen1);

  if error <> 6 then {no user abort}
  begin
    Player.Position := 0;
    Player.pattern_num := order[Player.Position];
    Player.row := 0;
    Editor.markedrow := 0;
    Editor.chan := 1;
    Editor.Playtime := Player.tempo div 4;
    Editor.saved := true;

    Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,0,63);
    CopyBuffer(buffer.blankscreen,buffer.screen1);
    Draw_Pattern_Window(false);
    Draw_Editor_Window(false);
    mainmenu := false;
    Update_Pattern(-8,true);
    gotoxy(Editor.p_xp+4,14);
    pedit := true;
   end
   else
    pause := pstate;
end;




Procedure Add_new_Pattern_diag;
begin
  pause := true;
  Mute_all;
  Clipboard.mark := false;
  writeto(buffer.screen1);

  inc(Player.MaxPattern);
  Player.pattern_num := Player.MaxPattern;
  fastwrite(73,5,palette.text_color2,palette.window_color,hexb(Player.pattern_num)+'/'+hexb(Player.MaxPattern));
  new(patterns[Player.pattern_num]);        {Create new Pattern in memory}
  fillchar(patterns[Player.pattern_num]^,sizeof(TNDYPattern),0); {Clear it}
  Player.row := 0;
  Editor.MarkedRow := 0;
  CopyBuffer(buffer.blankscreen,buffer.screen1); {restore old screen state}
  Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,0,63);
  Draw_Pattern_Window(false);
  Draw_Editor_Window(false);
  mainmenu := false;
  Update_Pattern(Editor.markedrow-8,true);
  gotoxy(editor.p_xp+4,14);
  pedit := true;
  Clear_Keypress;
  editor.saved := false;
  pedit := true;
  displaybuffer(buffer.screen1);
end;




Procedure Delete_Pattern_diag;
begin
  pause := true;
  Mute_all;

  writeto(ptr(txtscreen.vidseg,0));
  cursor(false);
  box(14,8,66,14,palette.text_color1,Palette.mark_color,false,true);
  centeredtext(10,palette.text_color1,palette.mark_color,'Are you sure you really want');
  centeredtext(11,palette.text_color1,palette.mark_color,'to delete pattern '+hexb(player.pattern_num)+'?');
  centeredtext(12,palette.text_color1,palette.mark_color,'(Y)es / (N)o');

  Clear_Keypress;
  repeat
       if is_key_pressed then Get_Key;

       if (upcase(key_Ascii) = 'N')  or (key_code = 1) then
       begin
         Clear_Keypress;
         writeto(buffer.screen1);
         displaybuffer(buffer.screen1);
         cursor(pedit); 	{Enable cursor when in pattern editor}
         exit;
       end;

  until (upcase(key_Ascii) = 'Y') or (upcase(key_Ascii) = 'Z');
  Clear_Keypress;

  Clipboard.mark := false;


  fillchar(patterns[Player.pattern_num]^,sizeof(TNDYPattern),0); {Clear data in memory}

  if Player.maxpattern > 0 then
  begin
    if Player.pattern_num < Player.maxpattern then
    begin
      dispose(patterns[Player.pattern_num]); {Free memory}

      for z := Player.pattern_num to player.maxpattern-1 do
        Patterns[z] := Patterns[z+1];

      Patterns[player.maxpattern] := nil;
    end
    else
    begin
      dispose(patterns[Player.pattern_num]); {Free memory}
      dec(Player.pattern_num);
    end;
    dec(player.maxpattern);
  end;



  writeto(buffer.screen1);
  fastwrite(73,5,palette.text_color2,palette.window_color,hexb(Player.pattern_num)+'/'+hexb(Player.MaxPattern));

  for z := 0 to Player.songlength do       {update oder list}
    if order[z] > Player.pattern_num then dec(order[z]);

  Player.row := 0;
  Editor.Markedrow := 0;
  Editor.chan := 1;

  CopyBuffer(buffer.oldscreen,buffer.screen1); {restore old screen state}
  Draw_Pattern_Window(false);
  Draw_Editor_Window(false);
  mainmenu := false;
  Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,0,63); {Create text buffer for it}
  Update_Pattern(Editor.MarkedRow-8,false);
  Update_Order(false,false);
  gotoxy(Editor.p_xp+4,14);

  editor.saved := false;
  pedit := true;
  displaybuffer(buffer.screen1);
end;








{============ The controls of the main menu ==============}

Procedure Control_Menu;
var i : byte;
begin

  if mainmenu then
  begin

     if (key_code= 77)  or (key_code = 244) then {right}
     begin
       if (active_menu < 6) then
        inc(active_menu)
       else
        active_menu := 1;

       select := 1;
       CopyBuffer(buffer.oldscreen,buffer.screen1);
       DrawMenu(active_menu);
       Mark(Menu_pos[active_menu]+1,2+select,length(menu_text[active_menu][select]));

       if not pause then
       begin
         if (ptn.tracemode = true) then
         begin
            Prepare_next_Patterns_buffer;
            Update_Pattern(Player.row-8,false);
         end;
         Update_Player_state(false);
       end;

       displaybuffer(buffer.screen1);
       exit;
     end;

     if (key_code= 75)  then  {left}
     begin
       if (active_menu > 1) then
        dec(active_menu)
       else
        active_menu := 6;

        select := 1;

        CopyBuffer(buffer.oldscreen,buffer.screen1);
        DrawMenu(active_menu);
        Mark(Menu_pos[active_menu]+1,2+select,length(menu_text[active_menu][select]));

        if not pause then
        begin
          if (ptn.tracemode = true) then
          begin
            Prepare_next_Patterns_buffer;
            Update_Pattern(Player.row-8,false);
          end;
          Update_Player_state(false);
        end;

        displaybuffer(buffer.screen1);
        exit;

     end;

     if (key_code= 80) then {down}
     begin
       if select < menu_size[active_menu] then
       begin
        UnMark(Menu_pos[active_menu]+1,2+select,length(menu_text[active_menu][select]),15);
        inc(select);
        Mark(Menu_pos[active_menu]+1,2+select,length(menu_text[active_menu][select]));
        displaybuffer(buffer.screen1);
       end
       else
       begin
        UnMark(Menu_pos[active_menu]+1,2+select,length(menu_text[active_menu][select]),15);
        select := 1;
        Mark(Menu_pos[active_menu]+1,2+select,length(menu_text[active_menu][select]));
        displaybuffer(buffer.screen1);
       end;
       Clear_Keypress;
     end;

     if (key_code= 72) then       {Up}
     begin
       if select > 1 then
       begin
        UnMark(Menu_pos[active_menu]+1,2+select,length(menu_text[active_menu][select]),15);
        dec(select);
        Mark(Menu_pos[active_menu]+1,2+select,length(menu_text[active_menu][select]));
        displaybuffer(buffer.screen1);
       end
       else
       begin
        UnMark(Menu_pos[active_menu]+1,2+select,length(menu_text[active_menu][select]),15);
        select := menu_size[active_menu];
        Mark(Menu_pos[active_menu]+1,2+select,length(menu_text[active_menu][select]));
        displaybuffer(buffer.screen1);
       end;
       Clear_Keypress;
     end;



    if (key_code= 1) then {ESC}
    begin
      clear_keypress;
      CopyBuffer(buffer.oldscreen,buffer.screen1); {restore old screen state}

      if (pause = true) then
      begin
       cursor(true);
       displaybuffer(buffer.screen1);
      end;

      mainmenu := false;
      pedit  := true;
      exit;
    end;


    if (key_code= 28) then {Enter}
    begin

      case active_menu of
      1:                           {File menu}
      begin
          case select of

          1:       {New}
          begin
            pause := true;
            Mute_All;

            case Save_changes_diag of
             0: Create_New_Song_diag;
             1:
             begin
               Save_Song;
               if error <> 6 then Editor.saved := true;
               Create_new_song_diag;
             end;
             2: Create_new_song_diag;
            end;
            displaybuffer(buffer.screen1);
            Clear_Keypress;
          end;


          2:       {Load}
          begin
            pstate := pause;
            pause := true;
            Mute_All;

            case Save_changes_diag of
             0: Load_a_Song_diag; {No changes to save}
             1:                   {Yes}
             begin
               Save_Song;
               if error <> 6 then Editor.saved := true;
               Load_a_song_diag;
             end;
             2: Load_a_song_diag; {No}
             3: pause := pstate;  {Cancel}
            end;

            Clear_Keypress;
            displaybuffer(buffer.screen1);

          end;

          3:       {Save}
          begin
           pstate := pause;
           pause := true;
           Mute_All;

	   Save_Song;
	   Clear_Keypress;
	   if error <> 6 then {no user abort}
           begin
             CopyBuffer(buffer.oldscreen,buffer.screen1); {restore old screen state}
             Draw_Pattern_Window(false);
             Draw_Editor_Window(false);
             mainmenu := false;
             Update_Pattern(Editor.markedrow-8,true);
             gotoxy(Editor.p_xp+4,14);
             pedit := true;
             editor.saved := true;
           end
           else
              pause := pstate;

           Clear_Keypress;
           displaybuffer(buffer.screen1);
          end;

          4:       {Import MOD}
          begin
           pstate := pause;
           pause := true;
           Mute_All;

           case Save_changes_diag of
             0: Import_MOD_diag; {No changes to save}
             1:                   {Yes}
             begin
               Save_Song;
               if error <> 6 then Editor.saved := true;
               Import_MOD_diag;
             end;
             2: Import_MOD_diag; {No}
             3: pause := pstate; {Cancel}
            end;


           Clear_Keypress;
           displaybuffer(buffer.screen1);

          end;

          5:       {Import SND}
          begin
           pstate := pause;
           pause := true;
           Mute_All;

            case Save_changes_diag of
             0: Import_SND_diag; {No changes to save}
             1:                   {Yes}
             begin
               Save_Song;
               if error <> 6 then Editor.saved := true;
               Import_SND_diag;
             end;
             2: Import_SND_diag; {No}
             3: pause := pstate; {Cancel}
            end;

           Clear_Keypress;
           displaybuffer(buffer.screen1);
          end;


          end;
      end;

      2:              {Play}
      begin
          case select of
          1:                     {Play song}
          begin
  	    Start_Play_Song;
          end;

          2:                       {Stop}
          begin
           Stop_Playing;
          end;

          3:                     {Play Pattern}
          begin
            Start_Play_Pattern;
          end;

          4:                     {Play from cursor}
          begin
            Start_Play_Cursor;
          end;

          5:   			{Trace mode on/off}
          begin
             Toggle_Tracing;
    	     DrawMenu(active_menu);
             Mark(Menu_pos[active_menu]+1,2+select,length(menu_text[active_menu][select]));
    	     displaybuffer(buffer.screen1);
    	     Clear_Keypress;
          end;
        end;
      end;

      3:              {Edit}
      begin
          case select of


              1:  	{Enable / Disable Speaker channel}
               begin
                Clear_Keypress;
                pause := true;
                Clear_Sounddata;

                if Editor.channels = 4 then
           	begin
           	 Move_tracks(3,4,true);
           	 Editor.channels := 5;
           	end
            	else
            	begin
            	 Move_tracks(4,3,true);
    	         Editor.channels := 4;
            	end;

                CopyBuffer(buffer.blankscreen,buffer.screen1); {restore old screen state}
	        Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,0,63);
  	        Draw_Pattern_Window(false);
  	        Draw_Editor_Window(false);
  	        mainmenu := false;
  	        Update_Pattern(Editor.markedrow-8,true);
                gotoxy(editor.p_xp+4,14);
                pedit := true;
                editor.saved := false;
    	        Clear_Keypress;
	       end;


             2:
             begin
              in_subscreen := true;
              Clear_Keypress;
              Edit_Message;
              Clear_Keypress;
              in_subscreen := false;
 	     end;

            3:
             begin
              in_subscreen := true;
              Clear_Keypress;
              Timing_Config;
              Clear_Keypress;
              in_subscreen := false;
             end;

           4:
             begin
              Clear_Keypress;
              Add_new_Pattern_diag;
             end;

	   5:
             begin
              Clear_Keypress;
              Delete_Pattern_diag;
             end;

           6:
             begin
              in_subscreen := true;
              Clear_Keypress;
              Transpose_Menu(1);
              in_subscreen := false;


              if error = 0 then
              begin
                CopyBuffer(buffer.blankscreen,buffer.screen1); {restore old screen state}
    		Update_Pattern_Screenbuffer(Buffer.Pbuffer,Player.pattern_num,0,63);
    		Draw_Pattern_Window(false);
    		Draw_Editor_Window(false);
    		mainmenu := false;
    		Update_Pattern(Editor.markedrow-8,true);
    		pedit := true;
    		editor.saved := false;
    		if not pause then cursor(false);
    	      end
    	      else
    	      begin
    	        displaybuffer(buffer.screen1);
              end;

             end;


         end;
      end;

      4:              {Config}
      begin
        case select of

         1:	{Configure output device}
         begin
          in_subscreen := true;
          Clear_Keypress;
          Output_config;
          Clear_Keypress;
          in_subscreen := false;
         end;

        2:	{Configure AGI Import}
         begin
          in_subscreen := true;
          Clear_Keypress;
          SND_Import_Config;
          Clear_Keypress;
          in_subscreen := false;
         end;

        3:	{Configure MOD Import}
         begin
          in_subscreen := true;
          Clear_Keypress;
          MOD_Import_Config;
          Clear_Keypress;
          in_subscreen := false;
         end;
        end;
      end;

      5:              {Help}
      begin

       case select of

        1:	{Help about Keys}
         begin
          in_subscreen := true;
          Clear_Keypress;
          Show_Help(1);
          Clear_Keypress;
          in_subscreen := false;
         end;

        2:	{Help about Effects}
         begin
          in_subscreen := true;
          Clear_Keypress;
          Show_Help(2);
          Clear_Keypress;
          in_subscreen := false;
         end;

        3:	{About}
         begin
          in_subscreen := true;
          Clear_Keypress;
          About_Window;
          Clear_Keypress;
          in_subscreen := false;
         end;

       end;
      end;

      6:
      begin
        case Save_changes_diag of
             0: quit := true; {No changes to save}
             1:                   {Yes}
             begin
               Save_Song;
               if error <> 6 then Editor.saved := true;
               quit := true;
             end;
             2: quit := true; {No}
             3:                   {Cancel}
             begin
                quit := false;
                displaybuffer(buffer.screen1);
             end;
            end;
      end;
   end;
   end;
end;




end;

end.



