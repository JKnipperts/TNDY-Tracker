{$G-,N-,E-}

{**************************************************************
 Control.pas - Procedures and functions for menu operation
	       and keyboard query

 Author: Jan Knipperts
 Program: TNDY-Tracker
 Version: 1.11
 - small bug fixes

***************************************************************
}



Unit Control;
interface

uses global,menu,tndy,play,PIT,keyboard,textmode,tracker,
     fselect,modules,help;

Procedure Control_Order_Editor;
Procedure Control_Pattern_Editor;
Procedure Control_Player;
Procedure Control_Menu;




implementation



{============ Controling the order list editor ==============}
Procedure Control_Order_Editor;
begin
  ox := GetX;
  oy := GetY;
  gotoxy(71,16);
  Clear_Keypress;

 repeat
  if is_key_pressed then Get_Key;

  if (key_code= 82) {Ins} then
  begin
    if Player.Songlength < $FF then
    begin
     for z := Player.Songlength-1 downto Player.Position do
     order[z+1] := order[z];
     order[Player.Position] := order[Player.Position+1];
     inc(Player.Songlength);
    end;

    UpdatePatternOrder(false);
    Player.pattern_num := order[Player.Position];
    UpdatePatternView(Editor.markedrow-8,true);
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
    UpdatePatternOrder(false);
    Player.pattern_num := order[Player.Position];
    UpdatePatternView(Editor.MarkedRow-8,true);
    Clear_Keypress;

  end;

  if (key_code= 77) {Right} then
  begin
   gotoxy(72,16);
   Clear_Keypress;
  end;


  if (key_code= 75) {Left} then
  begin
    gotoxy(71,16);
    Clear_Keypress;
  end;

  if (key_code= 72) {Up} then
  begin
   if Player.Position > 0 then dec(Player.Position);
   UpdatePatternOrder(false);
   Player.pattern_num := order[Player.Position];
   fastwrite(72,5,palette.text_color2,palette.window_color,hexb(Player.pattern_num));
   UpdatePatternView(Editor.MarkedRow-8,true);
   Clear_Keypress;
  end;

  if (key_code= 80) {Down} then
  begin
   if Player.Position < Player.Songlength-1 then inc(Player.Position);
   UpdatePatternOrder(false);
   Player.pattern_num := order[Player.Position];
   fastwrite(72,5,palette.text_color2,palette.window_color,hexb(Player.pattern_num));
   UpdatePatternView(Editor.MarkedRow-8,true);
   Clear_Keypress;
  end;

  if (key_code= 15) {Tab} or (key_code= 28) {Return} then
  begin
   mark(74,20,2);
   gotoxy(74,20);
   UpdatePatternOrder(true);
   Clear_Keypress;


   repeat
       if is_key_pressed then Get_Key;

         if (getX = 74) and ((key_code in [30,48,46,32,38,33]) or
            (key_code in [2..11])) then
         begin
           putchar(74,20,upcase(key_ASCII),14,4);
           gotoxy(75,20);
           ViewBuffer(buffer.screen1);
           if hex2dec(getchar(74,20)+getchar(75,20)) <= Player.MaxPattern then
           player.loop := hex2dec(getchar(74,20)+getchar(75,20));
           Clear_Keypress;
         end;

         if (getX = 75) and ((key_code in [30,48,46,32,38,33]) or
            (key_code in [2..11])) then
         begin
           putchar(75,20,upcase(key_ASCII),14,4);
           ViewBuffer(buffer.screen1);
           if hex2dec(getchar(74,20)+getchar(75,20)) <= Player.MaxPattern then
           player.loop := hex2dec(getchar(74,20)+getchar(75,20));
           Clear_Keypress;
         end;

         if (key_code= 77) {Right} then
         begin
          gotoxy(75,20);
          Clear_Keypress;
         end;

         if (key_code= 75) {Left} then
         begin
          gotoxy(74,20);
          Clear_Keypress;
         end;

   until (key_code= 1) or (key_code= 28) or (key_code= 15);

   fastwrite(74,20,palette.text_color2,palette.window_color,hexb(player.loop));
   Clear_Keypress;
   break;

 end;


  if (getX = 71) and ((key_code in [30,48,46,32,38,33]) or
     (key_code in [2..11])) then
  begin
    putchar(71,16,key_Ascii,14,4);
    gotoxy(72,16);
    if hex2dec(getchar(71,16)+getchar(72,16)) <= Player.MaxPattern then
    begin
     order[Player.Position] := hex2dec(getchar(71,16)+getchar(72,16));
    end;
    ViewBuffer(buffer.screen1);
    clear_keypress;
  end;

  if (getX = 72) and ((key_code in [30,48,46,32,38,33]) or
     (key_code in [2..11])) then
  begin
    putchar(72,16,key_Ascii,14,4);
    if hex2dec(getchar(71,16)+getchar(72,16)) <= Player.MaxPattern then
    begin
     order[Player.Position] := hex2dec(getchar(71,16)+getchar(72,16));
    end;
    ViewBuffer(buffer.screen1);
    clear_keypress;
  end;

  until (key_code= 1) or (key_code= 28);

  UpdatePatternOrder(false);
  Player.pattern_num := order[Player.Position];
  fastwrite(72,5,palette.text_color2,palette.window_color,hexb(Player.pattern_num));
  UpdatePatternView(Editor.MarkedRow-8,true);
  gotoxy(ox,oy);
  Clear_Keypress;
end;






{============ Control of the pattern editor ==============}
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
      	  Mute_All;
      	  move(buffer.screen1^,buffer.oldscreen^,4000);
      	  DrawMenu(active_menu);
      	  viewbuffer(buffer.screen1);
      	  cursor(false);
      	  exit;
    	end;


        57: {Space = Play}
        begin
            Mute_all;
            if (L_Shift_State = true) or
               (R_Shift_State = true) then   {Shift+SPace = Play pattern only}
             patternplay := true
            else
             patternplay := false;

            Player.row := Editor.MarkedRow;
            Draw_Player_State(true);
     	    pedit := false;
     	    clear_keyboard_buffer;
     	    Timing.ticks := 0;               {Reset counter}
     	    pause := false;
        end;


        59..63:			{F1 to F5 Mute/Unmute channel}
        begin

         if key_code-59 <= Editor.channels then
         begin
          if Player.muted[key_code-59] = true then
            Player.muted[key_code-59] := false
          else
          begin
            Player.muted[key_code-59] := true;
            MuteVoice(key_code-59);
          end;

          UpdatePatternView(Editor.MarkedRow-8,false);
         end;
          Clear_keyboard_buffer;
        end;



       72: {Up}
       begin
         if (Editor.MarkedRow >= 0) and (Editor.MarkedRow <= 63) then
         UpdatePatternView(Editor.MarkedRow-9,false);
       end;

       80: {Down}
       begin
         if (Editor.MarkedRow < 63) and (Editor.MarkedRow >= 0) then
         UpdatePatternView(Editor.MarkedRow-7,false);
       end;

       77: {Right}
       begin
         if Editor.chan < Editor.channels then
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
             if getX = (editor.p_xp+4)+((Editor.chan-1)*11) then gotoxy((editor.p_xp+8)+((Editor.chan-1)*11),14);
           end;


         end
         else
         begin
            if getX = ((editor.p_xp+10)+((Editor.chan-1)*11)) then
            begin
              Editor.chan := 1;
              Draw_Pattern_editor(true);

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


       75: {Left}
       begin

         if Editor.chan = Editor.channels then
         begin
           if getX = (editor.p_xp+4)+((Editor.chan-1)*11) then
           begin
             dec(Editor.chan);
             Draw_Pattern_editor(true);

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

             if getX = (editor.p_xp+8)+((Editor.chan-1)*11) then
             begin
               noteedit := true;
               gotoxy((editor.p_xp+4)+((Editor.chan-1)*11),14);
             end;

             if getX = (editor.p_xp+11)+((Editor.chan-1)*11) then gotoxy((editor.p_xp+8)+((Editor.chan-1)*11),14);
             if getX = (editor.p_xp+12)+((Editor.chan-1)*11) then gotoxy((editor.p_xp+11)+((Editor.chan-1)*11),14);
             if getX = (editor.p_xp+13)+((Editor.chan-1)*11) then gotoxy((editor.p_xp+12)+((Editor.chan-1)*11),14);

           end;

         end;


      end;



       15: {Tab}
       begin

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
            Draw_Pattern_Editor(true);
    	    noteedit := true;
    	    gotoxy((editor.p_xp+4)+((Editor.chan-1)*11),14);
           end;
         end
         else							 {Backtab - Jump to previous channel}
         begin
           if Editor.chan > 1 then
           begin
    	     dec(Editor.chan);
    	     Draw_Pattern_Editor(true);
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
           fastwrite(72,7,palette.text_color2,palette.window_color,hexn(Editor.curr_vol));
         end
         else
         begin      						       {Home = go on top of  pattern}
           Player.row := 0;
           Editor.MarkedRow := 0;
           UpdatePatternView(-8,false);
         end;
       end;

       79:   {End}
       begin
         if (L_Shift_State = true) or (R_Shift_State = true) then   {Shift + End = dec. volume}
         begin
           if Editor.curr_vol > 0 then dec(Editor.curr_vol);
           fastwrite(72,7,palette.text_color2,palette.window_color,hexn(Editor.curr_vol));
         end
         else                                                      {End = go to the end of the pattern}
         begin
           Player.row := 63;
           Editor.MarkedRow := 63;
           UpdatePatternView(55,false);
         end;
       end;

       73:  {Page up}
       begin
         if (L_Shift_State = true) or (R_Shift_State = true) then   {Shift + Pgup = increase octave}
         begin
           if (Editor.chan = Editor.channels) then
           begin
             if editor.noisetype < 2 then inc(editor.noisetype);
             Draw_Noise_Info;
           end
           else
           begin
             if editor.octave < 9 then inc(editor.octave);
             fastwrite(72,6,palette.text_color2,palette.window_color,hexb(editor.octave));
           end;
         end;

         if (L_Shift_State = false) and
           (R_Shift_State = false) then
         begin
           if Editor.MarkedRow >= 16 then dec(Editor.MarkedRow,16) else Editor.MarkedRow := 0;
           Player.row := Editor.MarkedRow;
           UpdatePatternView(Editor.MarkedRow-8,false);
         end;
       end;

       81:   {Pagedown}
       begin
         if (L_Shift_State = true) or (R_Shift_State = true) then   {Shift and Pgdown = decrease octave}
         begin
           if (Editor.chan < 4) then
           begin
             if editor.octave > 2 then dec(editor.octave);
             fastwrite(72,6,palette.text_color2,palette.window_color,hexb(editor.octave));
           end;
           if (Editor.chan = 4) and (Editor.channels = 5) then
           begin
             if editor.octave > 0 then dec(editor.octave);
             fastwrite(72,6,palette.text_color2,palette.window_color,hexb(editor.octave));
           end;
           if (Editor.chan = Editor.channels) then
           begin
             if editor.noisetype > 1 then dec(editor.noisetype);
             Draw_Noise_Info;
           end;
         end
         else
         begin
           inc(Editor.MarkedRow,16);
           if Editor.MarkedRow > 63 then Editor.MarkedRow := 63;
           Player.row := Editor.MarkedRow;
           UpdatePatternView(Editor.MarkedRow-8,false)
         end;
       end;

       14:  {Backspace}
       begin
         if Editor.MarkedRow = 0 then Editor.MarkedRow := 64;
         for z := Editor.MarkedRow-1 to 63 do
         begin
           Patterns[Player.pattern_num]^[z][Editor.chan-1] := Patterns[Player.pattern_num]^[z+1][Editor.chan-1];
         end;
        Patterns[Player.pattern_num]^[63][Editor.chan-1].note := 0;
        Patterns[Player.pattern_num]^[63][Editor.chan-1].octave := 0;
        Patterns[Player.pattern_num]^[63][Editor.chan-1].effect := 0;
        Patterns[Player.pattern_num]^[63][Editor.chan-1].ep := 0;
        Patterns[Player.pattern_num]^[63][Editor.chan-1].volume := 0;

        UpdatePatternView(Editor.MarkedRow-9,false);
       end;

       82: {Insert}
       begin

         if (L_Shift_State = false) and (R_Shift_State = false) then {Insert empty event}
         begin

           for z := 63 downto Editor.MarkedRow do    {Move down all existing events}
           begin
             Patterns[Player.pattern_num]^[z][Editor.chan-1] := Patterns[Player.pattern_num]^[z-1][Editor.chan-1];
           end;

           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 0;   {Clear event at marked position}
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].octave := 0;
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].effect := 0;
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].ep := 0;
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].volume := 0;

           if Editor.MarkedRow = 63 then    {if it's the last row, jump to the start of the pattern}
           begin
             Editor.MarkedRow := 0;
             UpdatePatternView(Editor.MarkedRow-8,false);
           end
           else
             UpdatePatternView(Editor.MarkedRow-7,false);
         end
         else						{shift+insert = add new pattern}
         begin
           {Update counter and player info}
           inc(Player.MaxPattern);
           Player.pattern_num := Player.MaxPattern;
           fastwrite(72,5,palette.text_color2,palette.window_color,hexb(Player.pattern_num)+'/'+hexb(Player.MaxPattern));

           new(patterns[Player.pattern_num]);        {Create new Pattern in memory}
           fillchar(patterns[Player.pattern_num]^,sizeof(TNDYPattern),0); {Clear it}
           Player.row := 0;
           UpdatePatternView(Player.row-8,false);
         end;

       end;


       83: {Delete}
       begin
         if (L_Shift_State = false) and (R_Shift_State = false) then
         begin
           if noteedit = true then
           begin
             Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 0;    {If cursor is on the note column..}
             Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].octave := 0;  {clear note and octave}
             Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].volume := 0;
           end
           else
           begin
             if (Editor.chan < Editor.channels) then
             begin
               if getX = (editor.p_xp+8)+((Editor.chan-1)*11) then                 {if it's on the volume column...}
                Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].volume := 0      {just clear the volume}
               else
               begin
                 {if it's on the effect or parameter column clear both}
                 Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].effect := 0;
                 Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].ep := 0;
               end;
             end
             else
             begin
               {is this the volume of the noise channel just clear the volume}
               if (getX = (editor.p_xp+10)+((Editor.chan-1)*11)) and (Editor.chan = Editor.channels) then
                Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].volume := 0
               else
               begin
                 {if not, clear note,octave and volume = freq, noise type and volume here}
                  Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 0;
                  Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].octave := 0;
                  Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].volume := 0;
               end;
             end;
           end;

           if Editor.MarkedRow = 63 then {if something has been changend on the last row, jump to row 0}
           begin
             Editor.MarkedRow := 0;
           end;

           UpdatePatternView(Editor.MarkedRow-8,false);		{Display the updated pattern}

         end
         else
         begin  {Shift+Delete = Delete Pattern}
           fillchar(patterns[Player.pattern_num]^,sizeof(TNDYPattern),0); {Clear data in memory}

           if Player.maxpattern > 0 then
           begin
             if Player.pattern_num < Player.maxpattern then
             begin
               dispose(patterns[Player.pattern_num]); {Free memory}
               for z := Player.pattern_num to player.maxpattern-1 do
               begin
                 Patterns[z] := Patterns[z+1];
               end;
               Patterns[player.maxpattern] := nil;
             end
             else
             begin
              dispose(patterns[Player.pattern_num]); {Free memory}
              dec(Player.pattern_num);
             end;

             dec(player.maxpattern);
             fastwrite(72,5,palette.text_color2,palette.window_color,hexb(Player.pattern_num)+'/'+hexb(Player.MaxPattern));



             for z := 0 to Player.songlength do       {update oder list}
             begin
               if order[z] > Player.pattern_num then dec(order[z]);
             end;
           end;

            Player.row := 0;
            Editor.Markedrow := 0;
            Editor.chan := 1;
            UpdatePatternOrder(false);
            UpdatePatternView(Editor.MarkedRow-8,false);
         end;

       end;


       28: {Enter/Return}
       begin
         Control_Order_Editor;
       end;

       78:  {+}
       begin
         if Player.pattern_num < Player.MaxPattern then {if there is a next pattern, load it}
         begin
           inc(Player.pattern_num);
           fastwrite(72,5,palette.text_color2,palette.window_color,hexb(Player.pattern_num));
           Player.row := 0;
           Editor.MarkedRow := 0;
           UpdatePatternView(Editor.MarkedRow-8,false);
         end;
       end;


       74: {-}
       begin
         if Player.pattern_num > 0 then {if there is a previous pattern, load it}
         begin
           dec(Player.pattern_num);
           Player.row := 0;
           Editor.MarkedRow := 0;
           fastwrite(72,5,palette.text_color2,palette.window_color,hexb(Player.pattern_num));
           UpdatePatternView(Editor.MarkedRow-8,false);
         end;
       end;

       25: {P}
       begin
         if (CTRL_State = true) then {Ctrl+P = Clear Pattern}
         begin
           fillchar(patterns[Player.pattern_num]^,sizeof(TNDYPattern),0);
           UpdatePatternView(Editor.MarkedRow-8,false);
            clear_keypress; {We do not want the pressed P to be processed as a note as well...}
         end;
       end;

       20:   {T}
       begin
         if (CTRL_State = true) then {Ctrl+T = Clear Track}
         begin
           for z := 0 to 63 do
           begin
             fillchar(patterns[Player.pattern_num]^[z][Editor.chan-1],sizeof(TNDYevent),0);
           end;
           UpdatePatternView(Editor.MarkedRow-8,false);
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

       case key_code of

       16,23,44:  {Q,I,Z  ( Note C )}
       begin
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 1;
           Editor.new_note := true;
       end;

       3,10,31:  {2,9,S (Note C#)}
       begin
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 2;
           editor.new_note := true;
       end;

       17,24,45:  {W,O,X (Note D)}
       begin
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 3;
           editor.new_note := true;
       end;

       4,11,32:  {3,0,D (Note D#)}
       begin
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 4;
           editor.new_note := true;
       end;

       18,25,46: {E,P,C (Note E)}
       begin
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 5;
           editor.new_note := true;
       end;

       19,26,47: {R,Ü,V (Note F)}
       begin
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 6;
           editor.new_note := true;
       end;

       6,13,34:  {5,´,G (Note F#)}
       begin
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 7;
           editor.new_note := true;
       end;

       20,27,48: {T,+,B (Note G)}
       begin
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 8;
           editor.new_note := true;
       end;

       7,35: {6,H (Note G#)}
       begin
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 9;
           editor.new_note := true;
       end;

       21,49: {Z,N (Note A)}
       begin
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 10;
           editor.new_note := true;
       end;

       8,36: {7,J (Note A#)}
       begin
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 11;
           editor.new_note := true;
       end;

       22,29,50: {U, ,M (Note B)}
       begin
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 12;
           editor.new_note := true;
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



        if Editor.new_note then   {A new note has been entered}
        begin

         {Add the actual volume}
          Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].volume := Editor.curr_vol+1;

          Fastwrite((editor.p_xp+4)+((Editor.chan-1)*11),14,palette.text_color1,palette.mark_color,
                    snote[Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note]+
                    hexn(Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].octave)+
                    ' '+hexn(Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].volume-1));
          ViewBuffer(buffer.screen1);

          Mute_All;
          Timing.ticks := 0;               {Reset tick counter}
          Editor.Note_edit_cnt := 0;

          {and play it}
          PlayVoice(Editor.chan-1,note_to_freq(Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note,
                            Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].octave),0);

          if Editor.MarkedRow < 63 then              {Update the patternview}
          UpdatePatternView(Editor.MarkedRow-7,false)
          else
          UpdatePatternView(-8,false);

          editor.new_note := false;
        end;

     end
    else
     begin  {We're on the Noise channel}

       if key_code in [2..5] then {1..3}
       begin
         Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := key_code-1;
         Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].volume := Editor.curr_vol+1;

         Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].octave := editor.noisetype;


         case Editor.noisetype of
          1: Fastwrite((editor.p_xp+9)+((Editor.chan-1)*11),14,palette.text_color1,palette.mark_color,' W');
          2: Fastwrite((editor.p_xp+9)+((Editor.chan-1)*11),14,palette.text_color1,palette.mark_color,' P');
         end;

         Fastwrite((editor.p_xp+4)+((Editor.chan-1)*11),14,palette.text_color1,palette.mark_color,
                   Snoise[Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note]+' ');

         Mute_All;

         Timing.ticks := 0;               {Reset counter}
         Editor.note_edit_cnt := 0;

         TANDY_Noise(Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note,
                     Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].octave,0);

         if Editor.MarkedRow < 63 then
          UpdatePatternView(Editor.MarkedRow-7,false)
         else
          UpdatePatternView(-8,false);

       end;
    end;  {Noise channel}




     if (key_code= 53) or (key_code= 86) then {-/<}          {key off}
     begin
          Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].note := 13;
          Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].volume := 0;
          Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].effect := 0;
          Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].ep := 0;

          Mute_All; 		{Mute all output}

          if Editor.MarkedRow < 63 then
           UpdatePatternView(Editor.MarkedRow-7,false)
          else
           UpdatePatternView(-8,false);
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
             Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].octave := 1;
             putchar((editor.p_xp+9)+((Editor.chan-1)*11),14,'W',palette.text_color2,palette.mark_color);
            end;
           25 :
            begin
             Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].octave := 2;
             putchar((editor.p_xp+9)+((Editor.chan-1)*11),14,'P',palette.text_color2,palette.mark_color);
            end;
          end;
       end;

     end;


      {Volume and FX Edit}
     if (key_code in [30,48,46,32,18,33]) or  (key_code in [2..11]) then
     begin

       {FX}
       if getX = (editor.p_xp+13)+((Editor.chan-1)*11) then			{second digit of parameter}
       begin
         putchar((editor.p_xp+13)+((Editor.chan-1)*11),14,upcase(key_Ascii),palette.text_color2,palette.mark_color);
         Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].ep :=
         hex2dec(getchar((editor.p_xp+12)+((Editor.chan-1)*11),14)+getchar((editor.p_xp+13)+((Editor.chan-1)*11),14));
       end;

       if getX = (editor.p_xp+12)+((Editor.chan-1)*11) then			{first digit of parameter}
       begin
        putchar((editor.p_xp+12)+((Editor.chan-1)*11),14,upcase(key_Ascii),palette.text_color2,palette.mark_color);
        Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].ep :=
        hex2dec(getchar((editor.p_xp+12)+((Editor.chan-1)*11),14)+getchar((editor.p_xp+13)+((Editor.chan-1)*11),14));
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
 	 0A = Set Fintetune, < 80h = decrease, > 80h = increase
 	 0B = Jump
 	 0D = Pattern break
 	 0F = Set Speed ( < 1F = set speed, >= 1F = set tempo)
        }

        if (upcase(key_Ascii) in ['0','1','2','3','4','5','A','B','D','F']) then	{valid command?}
        begin
          putchar((editor.p_xp+11)+((Editor.chan-1)*11),14,upcase(key_Ascii),palette.text_color2,palette.mark_color);
          Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].effect := hex2dec('0'+upcase(key_Ascii));
        end;
       end;

       {Volume}

       if getX = (editor.p_xp+8)+((Editor.chan-1)*11) then
       begin
        if (upcase(key_Ascii) in ['0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F']) then {volume of a voice}
        begin
          putchar((editor.p_xp+8)+((Editor.chan-1)*11),14,upcase(key_Ascii),palette.text_color2,palette.mark_color);
          dummy := hex2dec('0'+upcase(key_Ascii));
          if dummy <= $F then
          begin
           Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].volume := dummy+1;
          end;
        end;
       end;

       if (getX = (editor.p_xp+10)+((Editor.chan-1)*11)) and (Editor.chan = Editor.channels) then	{Volume of noise}
       begin
         if (upcase(key_Ascii) in ['0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F']) then
         begin
           putchar((editor.p_xp+10)+((Editor.chan-1)*11),14,upcase(key_Ascii),palette.text_color2,palette.mark_color);
           dummy := hex2dec('0'+upcase(key_Ascii));
           if dummy <= $F then
           begin
             Patterns[Player.pattern_num]^[Editor.MarkedRow][Editor.chan-1].volume := dummy+1;
           end;
         end;

      end;

   end; {Volume and FX edit}
 end; {Noteedit = false}
 end; {Pedit = true}

    ViewBuffer(buffer.screen1); {Update the screen}
    Clear_Keypress;


end;









{============ Controls while playing  ==============}

Procedure Control_Player;
begin
  	if key_code= 1 then		{ESC}
        begin
          move(buffer.screen1^,buffer.oldscreen^,4000);
          mainmenu := true;
          pause := true;
          Mute_ALL;
          DrawMenu(2);
          viewbuffer(buffer.screen1);
         end;

	if (key_code= 57) then {Space = Pause}
  	begin
      	    pause := true;
      	    pedit := true;
      	    Mute_ALL;
      	    Draw_Pattern_Editor(true);
   	end;

        if key_code in [59..63] then	{F1 to F5 Mute/Unmute channel}
        begin
          pause := true;
          if Player.muted[key_code-59] = true then
            Player.muted[key_code-59] := false
          else
          begin
            Player.muted[key_code-59] := true;
            MuteVoice(key_code-59);
          end;
          pause := false;
        end;


       if (key_code= 78) then		{+}
       begin
         if Player.Position < Player.Songlength-1 then
         begin
           inc(Player.Position);
           Player.pattern_num := order[Player.Position];
           Player.row := 0;
           UpdatePatternView(Player.row-8,false);
           Update_Player_State;
           Mute_ALL;
         end;
      end;

      if key_code= 74 then			{-}
      begin
        if Player.Position > 0 then
        begin
         dec(Player.Position);
         Player.pattern_num := order[Player.Position];
         Player.row := 0;
         UpdatePatternView(Player.row-8,false);
         Update_Player_State;
         Mute_ALL;
        end;
     end;

      Clear_Keyboard_buffer;


end;



{============ The controls of the main menu ==============}

Procedure Control_Menu;
var i : byte;
begin

  if mainmenu then
  begin

     if (key_code= 77)  then
     begin
       if (active_menu < 6) then
        inc(active_menu)
       else
       active_menu := 1;
       select := 1;
       move(buffer.oldscreen^,buffer.screen1^,4000);
       DrawMenu(active_menu);
       viewbuffer(buffer.screen1);
       Clear_Keypress;

     end;

     if (key_code= 75)  then
     begin
       if (active_menu > 1) then
        dec(active_menu)
       else
        active_menu := 6;
        select := 1;
        move(buffer.oldscreen^,buffer.screen1^,4000);
        DrawMenu(active_menu);
        viewbuffer(buffer.screen1);
        Clear_Keypress;

     end;

     if (key_code= 80) then {down}
     begin
       if select < menu_size[active_menu] then
       begin
        UnMark(Menu_pos[active_menu]+1,2+select,length(menu_text[active_menu][select]),15);
        inc(select);
        Mark(Menu_pos[active_menu]+1,2+select,length(menu_text[active_menu][select]));
        viewbuffer(buffer.screen1);
       end
       else
       begin
        UnMark(Menu_pos[active_menu]+1,2+select,length(menu_text[active_menu][select]),15);
        select := 1;
        Mark(Menu_pos[active_menu]+1,2+select,length(menu_text[active_menu][select]));
        viewbuffer(buffer.screen1);
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
        viewbuffer(buffer.screen1);
       end
       else
       begin
        UnMark(Menu_pos[active_menu]+1,2+select,length(menu_text[active_menu][select]),15);
        select := menu_size[active_menu];
        Mark(Menu_pos[active_menu]+1,2+select,length(menu_text[active_menu][select]));
        viewbuffer(buffer.screen1);
       end;
       Clear_Keypress;
     end;



    if (key_code= 1) then {ESC}
    begin
      clear_keyboard_buffer;
      Draw_Pattern_View(false);
      Draw_Pattern_Editor(true);
      Mute_All;
      mainmenu := false;
      pedit  := true;
      pause := true;
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
           Mute_All;
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
           set_timer(50);

           Editor.orderview := -2;
           Editor.octave := 4;
           Editor.chan := 1;
           Editor.Channels := 4;
           Editor.noisetype := 1;
           Player.songlength := 1;

           Draw_Pattern_View(false);
           Draw_Pattern_Editor(true);
           gotoxy(Editor.p_xp+4,14);
           pedit := true;
           mainmenu := false;
           Clear_Keypress;
          end;


          2:       {Load}
          begin
           Mute_All;
           move(buffer.blankscreen^,buffer.screen2^,4000);
           writeto(buffer.screen2);

           window(27,3,53,23,palette.text_color1,palette.menu_color,true);
           centeredtext(3,15,palette.menu_color,' Load a song ');
           for i := 1 to 25 do
           putchar(27+i,21,'Ä',palette.text_color1,palette.menu_color);
           LoadTNDY(User_selected_File('*.tnd',Sort_by_Name,30,4,17,buffer.screen2));
           Proceed_Errors;

           writeto(buffer.screen1);
           viewbuffer(buffer.screen1);

           if error <> 6 then {no user abort}
           begin
            Player.Position := 0;
            Player.pattern_num := order[Player.Position];
            Player.row := 0;
            Editor.chan := 1;
            Editor.markedrow := 0;
            Draw_Pattern_View(false);
            Draw_Pattern_Editor(true);
            gotoxy(Editor.p_xp+4,14);
            pedit := true;
            mainmenu := false;
           end;


           Clear_Keypress;
          end;

          3:       {Save}
          begin
	   Save_Song;
	   Clear_Keypress;
	   if error <> 6 then {no user abort}
           begin
            Draw_Pattern_View(false);
            Draw_Pattern_Editor(true);
            pedit := true;
            mainmenu := false;
           end;
          end;

          4:       {Import MOD}
          begin
           Mute_All;
           move(buffer.blankscreen^,buffer.screen2^,4000);
           writeto(buffer.screen2);

           window(27,3,53,23,palette.text_color1,palette.menu_color,true);
           centeredtext(3,15,palette.menu_color,' Import Module ');
           for i := 1 to 25 do
           putchar(27+i,21,'Ä',palette.text_color1,palette.menu_color);
           Import_MOD(User_selected_File('*.mod',Sort_by_Name,30,4,17,buffer.screen2));
           Proceed_Errors;

           writeto(buffer.screen1);
           viewbuffer(buffer.screen1);

           if error <> 6 then {no user abort}
           begin
            Player.Position := 0;
            Player.pattern_num := order[Player.Position];
            Player.row := 0;
            Editor.chan := 1;
            Editor.markedrow := 0;
            Draw_Pattern_View(false);
            Draw_Pattern_Editor(true);
            gotoxy(Editor.p_xp+4,14);
            pedit := true;
            mainmenu := false;
           end;


           Clear_Keypress;
          end;

          5:       {Import SND}
          begin
           Mute_All;
           move(buffer.blankscreen^,buffer.screen2^,4000);
           writeto(buffer.screen2);

           window(27,3,53,23,palette.text_color1,palette.menu_color,true);
           centeredtext(3,15,palette.menu_color,' Import AGI game music ');
           for i := 1 to 25 do
           putchar(27+i,21,'Ä',palette.text_color1,palette.menu_color);
           Import_SND(User_selected_File('*.snd',Sort_by_Name,30,4,17,buffer.screen2));
           Proceed_Errors;

           writeto(buffer.screen1);
           viewbuffer(buffer.screen1);

           if error <> 6 then {no user abort}
           begin
            Player.Position := 0;
            Player.pattern_num := order[Player.Position];
            Player.row := 0;
            Editor.markedrow := 0;
            Editor.chan := 1;
            Draw_Pattern_View(false);
            Draw_Pattern_Editor(true);
            gotoxy(Editor.p_xp+4,14);
            pedit := true;
            mainmenu := false;
           end;

           Clear_Keypress;
          end;
          end;
      end;

      2:              {Play}
      begin
          case select of
          1:                     {Play song}
          begin
            move(buffer.oldscreen^,buffer.screen1^,4000);
            viewbuffer(buffer.screen1);
            Mute_All;
            patternplay := false;
            Clear_Keyboard_Buffer;
            Player.Position := 0;
            Player.pattern_num := order[Player.Position];
            Player.row := 0;
            Draw_Pattern_View(false);
            Draw_Player_State(true);
            pause := false;
            pedit := false;
            mainmenu := false;
          end;

          2:                     {Play Pattern}
          begin
            move(buffer.oldscreen^,buffer.screen1^,4000);
            viewbuffer(buffer.screen1);
            Mute_All;
            patternplay := true;
            Clear_Keyboard_Buffer;
            Player.row := 0;
            Draw_Pattern_View(false);
            Draw_Player_State(true);
            pause := false;
            pedit := false;
            mainmenu := false;
          end;

          3:                     {Play from cursor}
          begin
            move(buffer.oldscreen^,buffer.screen1^,4000);
            viewbuffer(buffer.screen1);
            Mute_All;
            patternplay := false;
            Clear_Keyboard_Buffer;
            Player.row := Editor.MarkedRow;
            Draw_Player_State(true);
            pause := false;
            pedit := false;
            mainmenu := false;
          end;

         4:                       {Stop}
         begin
           pause := true;
           Mute_All;
           fillchar(Player.arp,sizeof(Player.arp),0);
           fillchar(Player.tsl,sizeof(Player.tsl),0);
           fillchar(Player.onote,sizeof(Player.onote),0);
           fillchar(Player.ooct,sizeof(Player.ooct),0);
           fillchar(TANDY.volume,sizeof(TANDY.volume),15);
           fillchar(TANDY.freq,sizeof(TANDY.freq),0);
           move(buffer.oldscreen^,buffer.screen1^,4000);
           viewbuffer(buffer.screen1);
           mainmenu := false;
           pedit := true;
           Clear_Keyboard_Buffer;
           Draw_Pattern_Editor(true);
         end;
        end;
      end;

      3:              {Edit}
      begin
          case select of


              1:  	{Enable / Disable Xtra Channel}
               begin
                Clear_Keypress;
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

                Mute_All;
                move(buffer.oldscreen^,buffer.screen1^,4000);
           	Draw_Pattern_View(false);
           	Draw_Pattern_Editor(false);
                move(buffer.screen1^,buffer.oldscreen^,4000);
           	DrawMenu(active_menu);
           	cursor(false);
      	        viewbuffer(buffer.screen1);
   	        gotoxy(Editor.p_xp+4,14);
                Editor.chan := 1;
                noteedit := true;

                mainmenu := true;
      	        pedit := false;
              end;


             2:
             begin
              Clear_Keypress;
              Edit_Message;
              Clear_Keypress;
 	     end;

            3:
             begin
              Clear_Keypress;
              Timing_Config;
              Clear_Keypress;
             end;

            4:
             begin
               Clear_Keypress;
               Swap_Tracks_Menu;
               Draw_Pattern_View(false);
               Draw_Pattern_Editor(false);
               DrawMenu(active_menu);
               UnMark(Menu_pos[active_menu]+1,2+select,length(menu_text[active_menu][select]),15);
               select := menu_size[active_menu];
               Mark(Menu_pos[active_menu]+1,2+select,length(menu_text[active_menu][select]));
               viewbuffer(buffer.screen1);
               gotoxy(Editor.p_xp+4,14);
               Editor.chan := 1;
               noteedit := true;
               cursor(false);
               mainmenu := true;
      	       pedit := false;
             end;


         end;
      end;

      4:              {Config}
      begin
        case select of

         1:	{Configure output device}
         begin
          Clear_Keypress;
          Output_config;
          Clear_Keypress;
         end;

        2:	{Configure AGI Import}
         begin
          Clear_Keypress;
          SND_Import_Config;
          Clear_Keypress;
         end;

        3:	{Configure MOD Import}
         begin
          Clear_Keypress;
          MOD_Import_Config;
          Clear_Keypress;
         end;


        end;
      end;

      5:              {Help}
      begin

       case select of

        1:	{Help about Keys}
         begin
          Clear_Keypress;
          Showt_Help(1);
          Clear_Keypress;
         end;

        2:	{Help about Effects}
         begin
          Clear_Keypress;
          Showt_Help(2);
          Clear_Keypress;
         end;

        3:	{About}
         begin
          Clear_Keypress;
          About_Window;
          Clear_Keypress;
         end;

       end;
      end;

      6:
      begin
       quit := true;    {Quit}
      end;
   end;
   end;
end;
end;

end.



