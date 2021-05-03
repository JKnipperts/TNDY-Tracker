{$G-,N-,E-}

{**************************************************************
 Tracker.pas - Procedures for drawing the pattern editor and
               player windows

 Author: Jan Knipperts
 Program: TNDY-Tracker
 Version: 1.151

***************************************************************
}





Unit Tracker;
interface
uses global,textmode,keyboard,menu,tndy;

Procedure Update_Screenbuffer_Track(buffer_ptr : pointer; pattern_number, track_number, start_row, end_row  : integer);
Procedure Update_Pattern_Screenbuffer(buffer_ptr : pointer; pattern_number,start_row, end_row : integer);
Procedure Prepare_next_Patterns_buffer;

Procedure Update_Pattern(start : integer; update_screen : boolean);
Procedure Update_Order(update_screen, mark_current : boolean);
Procedure Draw_Pattern_Window(update_screen : boolean);
Procedure Draw_Editor_Window(update_screen : boolean);
Procedure Draw_Player_State(update_screen : boolean);
Procedure Draw_Noise_Info;
Procedure Draw_Voice_Info;
Procedure Update_Player_State(update_screen : boolean);
Procedure Flash_playing_note(update_screen : boolean);

Procedure Move_Tracks(from_track, to_track : byte; whole_song : boolean);





const
 eq_str      : char = #254;
 eq_color : array[0..15] of byte = (0,2,2,2,2,2,2,2,2,10,10,10,10,14,14,12);

 {Note Names}
 SNote : array[0..13] of string[2]=
        ('..','C-','C#','D-','D#','E-','F-','F#','G-','G#','A-','A#','B-',' -');
 Snoise : array[0..4] of string[4]=
        ('....','2330','1165',' 583','Voc3');






implementation




{============ Display the actual view of the current pattern ==============}

 Procedure Update_Screenbuffer_Track(buffer_ptr : pointer; pattern_number, track_number, start_row, end_row  : integer);
 var xp,fc,bc : byte;
     rcnt           : integer;
 begin
   writeto(buffer_ptr);
   if start_row < 0 then start_row := 0;
   if end_row > 63 then end_row := 63;
   txtscreen.maxX  := 55;
   txtscreen.maxY  := 64;

   bc := palette.window_color;
   fc := palette.text_color2;
   xp  := 5+(track_number*11);

   for rcnt := start_row to end_row do          {Row count}
   begin

     if track_number = 0 then
     begin
       Fastwrite(1,rcnt+1,fc,bc,AddZero(10,rcnt));  {Write row count}
       Fastwrite(3,rcnt+1,palette.text_color1,bc,' ³ ');
     end;


     if track_number < Editor.channels-1 then
     begin

       if patterns[pattern_number]^[rcnt][track_number].note <= 13 then
       begin

           if patterns[pattern_number]^[rcnt][track_number].note = 13 then
              Fastwrite(xp,rcnt+1,fc,bc,'OFF       ')
           else
           begin
             if patterns[pattern_number]^[rcnt][track_number].Octave > 0 then
                Fastwrite(xp,rcnt+1,fc,bc,snote[patterns[pattern_number]^[rcnt][track_number].note]+
                            hexn(patterns[pattern_number]^[rcnt][track_number].Octave)+' ')
             else
                Fastwrite(xp,rcnt+1,fc,bc,snote[patterns[pattern_number]^[rcnt][track_number].note]+'. ');

             if (editor.channels = 5) and (track_number = 3) then
                Fastwrite(xp+4,rcnt+1,fc,bc,'   ')
             else
             begin
                if (patterns[pattern_number]^[rcnt][track_number].volume = 0) then
                  Fastwrite(xp+4,rcnt+1,fc,bc,'.  ')
                else
                  Fastwrite(xp+4,rcnt+1,fc,bc,hexn(patterns[pattern_number]^[rcnt][track_number].volume-1)+'  ');
             end;

                Fastwrite(xp+7,rcnt+1,palette.text_color3,bc,hexn(patterns[pattern_number]^[rcnt][track_number].effect));
                Fastwrite(xp+8,rcnt+1,fc,bc,hexb(patterns[pattern_number]^[rcnt][track_number].ep));


           end;
       end;

       putchar(xp+10,rcnt+1,palette.text_color1,bc,'³');

     end
     else
     begin

       if patterns[pattern_number]^[rcnt][track_number].note in [0..4] then
       begin
         Fastwrite(xp,rcnt+1,fc,bc,Snoise[patterns[pattern_number]^[rcnt][track_number].note]+' ');

         if patterns[pattern_number]^[rcnt][track_number].Octave > 2 then
         patterns[pattern_number]^[rcnt][track_number].Octave := 2;

         case patterns[pattern_number]^[rcnt][track_number].Octave of
              0: fastwrite(xp+4,rcnt+1,fc,bc,' .');
              1: fastwrite(xp+4,rcnt+1,fc,bc,' P');
              2: fastwrite(xp+4,rcnt+1,fc,bc,' W');
         end;

         if patterns[pattern_number]^[rcnt][track_number].volume > 0 then
            fastwrite(xp+6,rcnt+1,fc,bc,hexn(patterns[pattern_number]^[rcnt][track_number].volume-1))
         else
            putchar(xp+6,rcnt+1,fc,bc,'.');

       end
       else
       begin
         Fastwrite(xp,rcnt+1,fc,bc,'OFF    ');
       end;

     end;

   end;

   txtscreen.maxX  := 80;
   txtscreen.maxY  := 25;

   if not in_subscreen then
     writeto(buffer.screen1)
   else
     writeto(buffer.screen2);


end;



 Procedure Update_Pattern_Screenbuffer(buffer_ptr : pointer; pattern_number,start_row, end_row  : integer);
 {Prepares pattern data in a buffer for display}
 var ccnt : byte;
 begin
     pstate := pause;
     pause := true;
     for ccnt := 0 to Editor.channels-1 do {Channel count}
       Update_Screenbuffer_Track(buffer_ptr, pattern_number, ccnt, start_row, end_row);
     pause := pstate;
  end;

 Procedure Prepare_next_Patterns_buffer;
 {Already load one row of the next pattern to play while playing}
 var ccnt : byte;
 begin

   if (player.row >= 0) and (player.row <= 55) then
     Update_Pattern_Screenbuffer(buffer.pbuffer,player.pattern_num,player.row+8,player.row+8)
   else
   begin
     if player.position <  player.songlength-1 then
      update_ptn := order[player.position+1]
     else
      update_ptn := order[player.loop];

     Update_Pattern_Screenbuffer(buffer.pbuffer1,update_ptn,player.row-56,player.row-56);
  end;


 end;



 Procedure Draw_Blank_space(y,rowlength : byte);
 {Draws an empty row in the pattern window}
 begin
   fillmem(#0,0,((((y-1)*txtscreen.maxX)+(Editor.p_xp-1)) shl 1),rowlength div 2);
   putchar(Editor.p_xp+3,y,palette.text_color1,palette.window_color,'³');
   putchar(Editor.p_xp+14,y,palette.text_color1,palette.window_color,'³');
   putchar(Editor.p_xp+25,y,palette.text_color1,palette.window_color,'³');
   putchar(Editor.p_xp+36,y,palette.text_color1,palette.window_color,'³');
   if Editor.channels = 5 then
   putchar(Editor.p_xp+47,y,palette.text_color1,palette.window_color,'³');
 end;


 Procedure Gray_muted(y : byte);
 {draw muted channels in gray color}
 var x,xp,chan,mx,a : byte;
 begin
  a := attr(7,palette.window_color,false);
  for chan := 0 to Editor.channels-1 do
  begin
    if player.muted[chan] then
    begin
      xp := (Editor.p_xp+4)+(chan*11);
      if chan = Editor.channels-1 then
        mx := 6
      else
        mx := 9;
      for  x := xp to xp + mx do
         ChangeAttr(x,y,a);
      end;
    end;
  end;



 Procedure Mark_current_row(rowlength : byte);
 {Marks current row}
 var o,s      : word;
     c,a1,a2  : byte;
 begin
   s := seg(Getwritebuffer^);
   o := ofs(Getwritebuffer^)+((((Editor.p_yp+7)*txtscreen.maxX)+(Editor.p_xp-1)) shl 1);

   if txtscreen.VidSeg = $B800 then  {color display}
   begin
     a1 := attr(palette.text_color1,palette.mark_color,false);
     a2 := attr(palette.text_color2,palette.mark_color,false);
   end
   else
   begin
     a1 := $70;
     a2 := $7F;
   end;


   c := 1;
   repeat;

     if (c < 4) or (mem[s:o+(c-1)] = 179) then
      mem[s:o+c] := a1
     else
      mem[s:o+c] := a2;

     inc(c,2);

   until c >= rowlength;


 end;


 Procedure Flash_playing_note(update_screen : boolean);
 {Flashes playing notes}
 var chan,a : byte;
 begin

   if monochrome then
   a := $70
   else
   a := Attr(palette.text_color1,palette.mark_color,false);


   if pause = false then
   begin
    for chan := 0 to Editor.channels-2 do
    begin
      if (patterns[player.pattern_num]^[editor.markedrow][chan].note > 0) then
      begin
        ChangeAttrHLine((Editor.p_xp+4)+(chan*11),Editor.p_yp+8,3,a);
      end;
      if (patterns[player.pattern_num]^[editor.markedrow][chan].volume > 0) then
      begin
        ChangeAttr((Editor.p_xp+4)+(chan*11)+4,Editor.p_yp+8,a);
      end;
      if (patterns[player.pattern_num]^[editor.markedrow][chan].ep > 0) then
      begin
        ChangeAttrHLine((Editor.p_xp+4)+(chan*11)+7,Editor.p_yp+8,3,a);
      end;
    end;

      if (patterns[player.pattern_num]^[editor.markedrow][Editor.channels-1].note > 0) then
      begin
        ChangeAttrHLine((Editor.p_xp+4)+((Editor.channels-1)*11),Editor.p_yp+8,7,a);
      end;


   end;

  if update_screen then displaybuffer(buffer.screen1);
 end;




 Procedure Draw_Row_from_buffer(y,rowlength : byte);
 {Moves one row from the pattern buffer into the screen buffer}
 begin
   move(ptr(seg(buffer.pbuffer^),boffs)^,
        ptr(seg(buffer.screen1^),
        ofs(buffer.screen1^)+(((y-1)*txtscreen.maxX)+(Editor.p_xp-1)) shl 1)^,rowlength);
   inc(boffs,110);
   Gray_muted(y);
 end;




 Procedure Update_Pattern(start : integer; update_screen : boolean);
 {Displays a section of the prepared pattern data in buffer.pbuffer on the screen}
 var y,nr,rowlength : byte;
     r	: integer;

 begin
   screenwriting := true;

   if (in_subscreen = false) then
   begin

     writeto(buffer.screen1);

     if start < -8 then start := -8;
     if start > 55 then start := 55;

     if Editor.Channels = 4 then
      rowlength := 88
     else
      rowlength := 110;

     Editor.markedrow := start+8;
     y := Editor.p_yp;

     if start < 0 then
     begin

       for r := start to -1 do
       begin
         Draw_Blank_space(y,rowlength);
         inc(y);
       end;

       nr := 16 - (start*(-1));
       boffs := ofs(buffer.pbuffer^);
       start := 0;
     end
     else
     begin
       boffs := ofs(buffer.pbuffer^)+(start*110);
       nr := 16;
     end;

     for r := start to start+nr do
     begin
       if r <= 63 then
        Draw_Row_from_buffer(y,rowlength)
       else
        Draw_Blank_space(y,rowlength);

       if (pause = true) and (clipboard.mark = true) then  {Is there an area to mark for copy/paste?}
       begin
         if (r >= clipboard.startpos) and
            (r <= clipboard.endpos) then
         begin
           if clipboard.track < Editor.channels-1 then
            mark((editor.p_xp+4)+(clipboard.track*11),y,10)
           else
            mark((editor.p_xp+4)+(clipboard.track*11),y,7);
         end;
       end;

       inc(y);
     end;


     Mark_current_row(rowlength);

     Flash_Playing_Note(false);

     if (mainmenu = true) then
     begin
       drawmenu(active_menu);
       Mark(Menu_pos[active_menu]+1,2+select,length(menu_text[active_menu][select]));
     end;

     if update_screen then displaybuffer(buffer.screen1);
  end;
   screenwriting := false;
end;



{============ Show the actual pattern order list ==============}

Procedure Update_Order(update_screen, mark_current : boolean);
 var cnt : integer;
     bc  : byte;

 begin
   screenwriting := true;
   if (in_subscreen = false) then
   begin
     for cnt := Player.Position-2 to Player.Position+2 do
     begin
       if ((cnt >= 0) and (cnt < Player.Songlength)) then
       begin
         Fastwrite(69,16+(cnt-Player.Position),15,palette.window_color,hexb(cnt)+':');
         Fastwrite(72,16+(cnt-Player.Position),14,palette.window_color,hexb(order[cnt]));
       end
       else
         Fastwrite(69,16+(cnt-Player.Position),palette.text_color2,palette.window_color,'     ');
     end;

     if mark_current then
     Mark(68,16,7);

     if update_screen then displaybuffer(buffer.screen1);
   end;
   screenwriting := false;
 end;





 {============ Draw the frames and titles for the pattern view screen ==============}

 Procedure Draw_Pattern_Window(update_screen : boolean);
 begin
   screenwriting := true;
   if (in_subscreen = false) then
   begin
     if Editor.channels = 4 then
     begin
       Editor.p_xp := 14;
       Editor.p_yp := 6;

       Box(Editor.p_xp-2,3,59,23,palette.text_color1,palette.window_color,false,true);
       Hline(Editor.p_xp-1,5,46,palette.text_color1,palette.window_color,'Ä');
       fastwrite(Editor.p_xp+38,4,palette.text_color1,palette.window_color,'Noise');
     end
     else
     begin
       Editor.p_xp := 4;
       Editor.p_yp := 6;

       Box(Editor.p_xp-2,3,60,23,palette.text_color1,palette.window_color,false,true);
       hline(Editor.p_xp-1,5,57,palette.text_color1,palette.window_color,'Ä');
       fastwrite(Editor.p_xp+40,4,palette.text_color1,palette.window_color,'Spk.   ³');
       fastwrite(Editor.p_xp+49,4,palette.text_color1,palette.window_color,'Noise');
       putchar(Editor.p_xp+47,5,palette.text_color1,palette.window_color,'Å');
       vline(Editor.p_xp+47,6,17,palette.text_color1,palette.window_color,'³');
     end;

     fastwrite(Editor.p_xp-1,4,palette.text_color1,palette.window_color,' Ln ³ ');
     fastwrite(Editor.p_xp+5,4,palette.text_color1,palette.window_color,'Voice 1  ³ ');
     fastwrite(Editor.p_xp+16,4,palette.text_color1,palette.window_color,'Voice 2  ³ ');
     fastwrite(Editor.p_xp+27,4,palette.text_color1,palette.window_color,'Voice 3  ³ ');

     putchar(Editor.p_xp+3,5,palette.text_color1,palette.window_color,'Å');
     putchar(Editor.p_xp+14,5,palette.text_color1,palette.window_color,'Å');
     putchar(Editor.p_xp+25,5,palette.text_color1,palette.window_color,'Å');
     putchar(Editor.p_xp+36,5,palette.text_color1,palette.window_color,'Å');

     vline(Editor.p_xp+3,6,17,palette.text_color1,palette.window_color,'³');
     vline(Editor.p_xp+14,6,17,palette.text_color1,palette.window_color,'³');
     vline(Editor.p_xp+25,6,17,palette.text_color1,palette.window_color,'³');
     vline(Editor.p_xp+36,6,17,palette.text_color1,palette.window_color,'³');


     if update_screen then displaybuffer(buffer.screen1);
   end;
   screenwriting := false;
 end;


{============ Draw the extra windows for the pattern editor ==============}

Procedure Draw_Noise_Info;
begin
   fastwrite(65,6,palette.text_color1,palette.window_color,' Noise:');
   if Editor.noisetype = 1 then
    fastwrite(73,6,palette.text_color2,palette.window_color,'White')
   else
    fastwrite(73,6,palette.text_color2,palette.window_color,'Peri.');
end;

Procedure Draw_Voice_Info;
begin
  fastwrite(65,6,palette.text_color1,palette.window_color,'Octave:');
  fastwrite(73,6,palette.text_color2,palette.window_color,hexn(Editor.octave)+'    ');
  fastwrite(65,7,palette.text_color1,palette.window_color,'Volume:');
  fastwrite(73,7,palette.text_color2,palette.window_color,hexn(Editor.curr_vol));
end;

Procedure Draw_Editor_Window(update_screen : boolean);
begin
  screenwriting := true;
  if (in_subscreen = false) then
  begin

    Box(62,3,79,9,palette.text_color1,palette.window_color,false,true);
    fastwrite(65,3,palette.text_color2,palette.window_color,' Current: ');
    fastwrite(64,5,palette.text_color1,palette.window_color,'Pattern:');
    fastwrite(73,5,palette.text_color2,palette.window_color,hexb(Player.pattern_num)+'/'+hexb(Player.MaxPattern));

    if editor.chan = editor.channels then
      Draw_Noise_Info
    else
      Draw_Voice_Info;

    box(63,11,79,23,palette.text_color1,palette.window_color,false,true);
    fastwrite(65,11,palette.text_color2,palette.window_color,' Order list: ');
    box(67,13,75,19,palette.text_color1,palette.window_color,true,false);
    fastwrite(66,20,palette.text_color1,palette.window_color,'Loop to:');
    fastwrite(75,20,palette.text_color2,palette.window_color,hexb(Player.loop));

    Update_Order(false,false);
    Change_cursor(0,7);

    if update_screen then
    begin
      cursor(true);
      displaybuffer(buffer.screen1);
    end;
  end;
  screenwriting := false;
end;




{============ Draw the extra window for the player ==============}
Procedure Draw_Player_State(update_screen : boolean);
begin
  screenwriting := true;
  if in_Subscreen = false then
  begin

  if ptn.tracemode then
  begin
    box(62,3,79,9,palette.text_color1,palette.window_color,false,true);
    fastwrite(64,3,palette.text_color2,palette.window_color,' Player info: ');
    fastwrite(64,5,palette.text_color1,palette.window_color,' Pos.:');
    fastwrite(64,6,palette.text_color1,palette.window_color,'Speed:');
    fastwrite(64,7,palette.text_color1,palette.window_color,'Tempo:');
    box(63,11,79,23,palette.text_color1,palette.window_color,false,true);
    fastwrite(65,11,palette.text_color2,palette.window_color,' Order list: ');
    box(67,13,75,19,palette.text_color1,palette.window_color,true,false);
    fastwrite(66,20,palette.text_color1,palette.window_color,'Loop to:');
    fastwrite(75,20,palette.text_color2,palette.window_color,hexb(Player.loop));
    Update_Order(update_screen,true);
  end
  else
  begin
    CopyBuffer(buffer.blankscreen,buffer.screen1);
    box(30,3,54,11,palette.text_color1,palette.window_color,false,true);
    fastwrite(35,3,palette.text_color2,palette.window_color,' Player State: ');
    fastwrite(35,5,palette.text_color1,palette.window_color,'Position:');
    putchar(49,5,palette.text_color1,palette.window_color,'/');
    fastwrite(50,5,palette.text_color2,palette.window_color,addspace(100,player.songlength-1));

    fastwrite(35,6,palette.text_color1,palette.window_color,'Pattern :');
    fastwrite(35,7,palette.text_color1,palette.window_color,'Row     :');
    fastwrite(35,8,palette.text_color1,palette.window_color,'Speed   :');
    fastwrite(35,9,palette.text_color1,palette.window_color,'Tempo   :');

    box(2,13,38,20,palette.text_color1,palette.window_color,false,true);
    fastwrite(13,13,palette.text_color2,palette.window_color,' Frequency: ');
    fastwrite(8,15,palette.text_color1,palette.window_color,'Voice 1 :');
    fastwrite(8,16,palette.text_color1,palette.window_color,'Voice 2 :');
    fastwrite(8,17,palette.text_color1,palette.window_color,'Voice 3 :');
    if editor.channels = 5 then
    begin
      fastwrite(8,18,palette.text_color1,palette.window_color,'Speaker :');
      fastwrite(8,19,palette.text_color1,palette.window_color,'Noise   :');
    end
    else
      fastwrite(8,18,palette.text_color1,palette.window_color,'Noise   :');

    box(44,13,79,20,palette.text_color1,palette.window_color,false,true);
    fastwrite(49,13,palette.text_color2,palette.window_color,' Volume: ');
    fastwrite(66,13,palette.text_color2,palette.window_color,' Peak: ');
    fastwrite(46,15,palette.text_color1,palette.window_color,'Voice 1 :');
    fastwrite(46,16,palette.text_color1,palette.window_color,'Voice 2 :');
    fastwrite(46,17,palette.text_color1,palette.window_color,'Voice 3 :');

    if editor.channels = 5 then
    begin
      fastwrite(46,18,palette.text_color1,palette.window_color,'Speaker :');
      fastwrite(46,19,palette.text_color1,palette.window_color,'Noise   :');
    end
    else
      fastwrite(46,18,palette.text_color1,palette.window_color,'Noise   :');

    Vline(61,14,6,palette.text_color1,palette.window_color,#179);

    if update_screen then displaybuffer(buffer.screen1);
  end;
  end;
  screenwriting := false;
end;


{============ Just update the contents of the player window ==============}




Procedure Update_Player_State(update_screen : boolean);
var z,c,col,n,o : byte;
begin
  if in_Subscreen = false then
  begin

  if (ptn.tracemode = true) then
  begin
   fastwrite(73,5,palette.text_color2,palette.window_color,hexb(Player.position)+'/'+hexb(Player.Songlength-1));
   fastwrite(73,6,palette.text_color2,palette.window_color,hexb(Player.speed));
   fastwrite(72,7,palette.text_color2,palette.window_color,addspace(100,round(Player.tempo))+'Hz');
   if (mainmenu = true) and (active_menu = 6) then	{Restore shadow of menu window}
   ChangeAttrHLine(73,5,3,8);
  end
  else
  begin

    if (mainmenu = false) or (active_menu > 4) then		{Dont update text hidden by a window}
    begin
      fastwrite(45,5,palette.text_color2,palette.window_color,addspace(100,Player.position));
      fastwrite(45,6,palette.text_color2,palette.window_color,addspace(100,Player.pattern_num));
      fastwrite(45,7,palette.text_color2,palette.window_color,addspace(100,Player.row));
      fastwrite(45,8,palette.text_color2,palette.window_color,addspace(100,Player.speed));
      fastwrite(45,9,palette.text_color2,palette.window_color,addspace(100,round(Player.Tempo))+' Hz');
    end
    else
    begin
         case active_menu of
           1:
           begin
             fastwrite(46,5,palette.text_color2,palette.window_color,addspace(10,Player.position mod 10));
             fastwrite(46,6,palette.text_color2,palette.window_color,addspace(10,Player.pattern_num mod 10));
             fastwrite(46,7,palette.text_color2,palette.window_color,addspace(10,Player.row mod 10));
             fastwrite(46,8,palette.text_color2,palette.window_color,addspace(10,Player.speed mod 10));
             fastwrite(45,9,palette.text_color2,palette.window_color,addspace(100,round(Player.Tempo))+' Hz');
             VLine(46,5,3,palette.text_color1,palette.menu_color,'³');
             putchar(46,8,palette.text_color1,palette.menu_color,'Ù');
             ChangeAttrVLine(47,5,5,8);
             ChangeAttrHLine(45,9,3,8);
           end;
           2:
           begin
             fastwrite(45,5,palette.text_color2,palette.window_color,addspace(100,Player.position));
             fastwrite(45,6,palette.text_color2,palette.window_color,addspace(100,Player.pattern_num));
             fastwrite(45,7,palette.text_color2,palette.window_color,addspace(100,Player.row));
             fastwrite(45,8,palette.text_color2,palette.window_color,addspace(100,Player.speed));
             fastwrite(45,9,palette.text_color2,palette.window_color,addspace(100,round(Player.Tempo))+' Hz');
             VLine(45,5,3,palette.text_color1,palette.menu_color,'³');
             putchar(45,8,palette.text_color1,palette.menu_color,'Ù');
             ChangeAttrVLine(46,5,5,8);
             ChangeAttrHLine(45,9,2,8);
           end;
           4:
           begin
             fastwrite(45,7,8,0,addspace(100,Player.row));
      	     fastwrite(45,8,palette.text_color2,palette.window_color,addspace(100,Player.speed));
      	     fastwrite(45,9,palette.text_color2,palette.window_color,addspace(100,round(Player.Tempo))+' Hz');
      	   end;
      	 end;
    end;




    for c := 0 to editor.channels-1 do
    begin

      if (editor.channels = 5) then
      begin
        case c of
        0..2,4:
        fastwrite(55,15+c,palette.text_color2,palette.window_color,' '+
                  addspace(100, round( ((15-volume[c]) / 15) * 100))+'%' );
        end;

      end
      else
         fastwrite(55,15+c,palette.text_color2,palette.window_color,' '+
                  addspace(100, round( ((15-volume[c]) / 15) * 100))+'%' );

        {now do the bars}

        if not monochrome then
        begin
          for z := 0 to meter[c] do
           putchar(62+z,15+c,eq_color[z],palette.window_color,eq_str);
          for z := meter[c]+1 to 15 do
           putchar(62+z,15+c,palette.window_color,palette.window_color,eq_str);
        end
        else
        begin
          for z := 0 to meter[c] do
           putchar(62+z,15+c,7,0,eq_str);

          ChangeAttr(62+meter[c],15+c,AttrMDA(false,false,true));

          for z := meter[c] to 15 do
           putchar(62+z,15+c,0,0,' ');
        end;


        if player.muted[c] then
        begin
          Fastwrite(18,15+c,7,palette.window_color,' MUTED        ');
        end
        else
        begin

          if (patterns[Player.pattern_num]^[Player.row][c].note > 0) then
          begin
             col := 11;
             n := patterns[Player.pattern_num]^[Player.row][c].note;
             o := patterns[Player.pattern_num]^[Player.row][c].octave;
          end
          else
          begin
             col := 3;
             if freq[c] > 0 then
             begin
               n := player.onote[c];
               o := player.ooct[c];
             end
             else
             begin
               n := 0;
               o := 0;
             end;
          end;


          if c in [0,1,2] then
          begin
            Fastwrite(18,15+c,col,palette.window_color,addspace(10000,freq[c])+' Hz ('+snote[n]+' )');

            if o > 0 then
               Fastwrite(30,15+c,col,palette.window_color,hexn(o))
            else
               Fastwrite(30,15+c,col,palette.window_color,'.');
          end;



         if (editor.channels = 5) then
         begin
           if (c = 3) then {write speaker channel info}
           begin
             Fastwrite(18,18,col,palette.window_color,addspace(10000,freq[c])+' Hz ('+snote[n]+' )');
             if o > 0 then
              Fastwrite(30,18,col,palette.window_color,hexn(o))
            else
              Fastwrite(30,18,col,palette.window_color,'.');
           end;

           if (c = 4) then  {write noise channel info}
           begin
             Fastwrite(18,19,col,palette.window_color,addspace(10000,freq[c])+' Hz');
             if (freq[c] > 0) then
             begin
               case o of
               1: Fastwrite(27,19,col,palette.window_color,'periodic');
               2: Fastwrite(27,19,col,palette.window_color,'white   ');
               end;
             end
             else
               Fastwrite(27,19,col,palette.window_color,'        ');
           end;

         end
         else
         begin

           if (c = 3) then  {write noise channel info}
           begin
             Fastwrite(18,18,col,palette.window_color,addspace(10000,freq[c])+' Hz');
    	     if (freq[c] > 0) then
             begin
               case o of
               1: Fastwrite(27,18,col,palette.window_color,'periodic');
               2: Fastwrite(27,18,col,palette.window_color,'white   ');
               end;
             end
             else
               Fastwrite(27,18,col,palette.window_color,'        ');
           end;
         end;

         if monochrome then
         begin
           if col = 11 then
            ChangeAttrHLine(18,15+c,18,AttrMDA(false,false,true))
           else
            ChangeAttrHLine(18,15+c,18,AttrMDA(false,false,false));
         end;

      end; {not muted}

    end; {for}



  end; {else}

   if update_screen then displaybuffer(buffer.screen1);
  end;

end;



Procedure Move_Tracks(from_track, to_track : byte; whole_song : boolean);
var pc,tc : byte;
   buffer_event : TNDYevent;
begin

  if (Editor.channels = 4) and ((to_track = 4) or (from_track = 4)) then
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
        Patterns[pc]^[tc][to_track] := Patterns[pc]^[tc][from_track];
        Patterns[pc]^[tc][from_track] := buffer_event;
      end;
    end;
  end
  else
  begin
    for tc := 0 to 63 do
    begin
     fillchar(buffer_event,sizeof(buffer_event),0);
     Patterns[Player.pattern_num]^[tc][to_track] := Patterns[Player.pattern_num]^[tc][from_track];
     Patterns[Player.pattern_num]^[tc][from_track] := buffer_event;
    end;
  end;


end;


end.
