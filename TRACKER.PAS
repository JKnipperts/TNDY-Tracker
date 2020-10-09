{$G-,N-,E-}

{**************************************************************
 Tracker.pas - Procedures for drawing the pattern editor and
               player windows

 Author: Jan Knipperts
 Program: TNDY-Tracker
 Version: 1.12

***************************************************************
}





Unit Tracker;
interface
uses global,textmode,keyboard,menu;

Procedure Update_Pattern_Screenbuffer(buffer_ptr : pointer; pattern_number,start_row, end_row : integer);
Procedure UpdatePatternView(start : integer; update_screen : boolean);
Procedure UpdatePatternOrder(update_screen : boolean);
Procedure Draw_Pattern_View(update_screen : boolean);
Procedure Draw_Pattern_Editor(update_screen : boolean);
Procedure Draw_Player_State(update_screen : boolean);
Procedure Draw_Noise_Info;
Procedure Update_Player_State;




const
 {Note Names}

 SNote : array[0..13] of string[2]=
        ('..','C-','C#','D-','D#','E-','F-','F#','G-','G#','A-','A#','B-','--');
 Snoise : array[0..4] of string[4]=
        ('....',' 583','1165','2330','Voc3');



implementation


{============ Display the actual view of the current pattern ==============}


 Procedure Update_Pattern_Screenbuffer(buffer_ptr : pointer; pattern_number,start_row, end_row  : integer);
 {Prepares pattern data in a buffer for display}
 var xp,ccnt,fc,bc : byte;
     rcnt           : integer;
 begin
   writeto(buffer_ptr);
   if start_row < 0 then start_row := 0;
   if end_row > 63 then end_row := 63;


   txtscreen.maxX  := 54;
   txtscreen.maxY  := 64;

   bc := palette.window_color;

   for rcnt := start_row to end_row do          {Row count}
   begin

     for ccnt := 0 to Editor.channels-1 do {Channel count}
     begin
       xp  := 5+(ccnt*11);

       if player.muted[ccnt] = true then
        fc := 7
       else
        fc := palette.text_color2;


       if ccnt = 0 then
       begin
         Fastwrite(1,rcnt+1,fc,bc,AddZero(10,rcnt));  {Write row count}
         Fastwrite(3,rcnt+1,palette.text_color1,bc,' ³ ');
       end;


       if ccnt < Editor.channels-1 then
       begin
         if patterns[pattern_number]^[rcnt][ccnt].note <= 13 then
         begin

           if patterns[pattern_number]^[rcnt][ccnt].note = 13 then
              Fastwrite(xp,rcnt+1,fc,bc,'OFF       ')
           else
           begin
             if patterns[pattern_number]^[rcnt][ccnt].Octave > 0 then
                Fastwrite(xp,rcnt+1,fc,bc,snote[patterns[pattern_number]^[rcnt][ccnt].note]+
                            hexn(patterns[pattern_number]^[rcnt][ccnt].Octave)+' ')
             else
                Fastwrite(xp,rcnt+1,fc,bc,snote[patterns[pattern_number]^[rcnt][ccnt].note]+'. ');

             if patterns[pattern_number]^[rcnt][ccnt].volume > 0 then
                Fastwrite(xp+4,rcnt+1,fc,bc,hexn(patterns[pattern_number]^[rcnt][ccnt].volume-1)+'  ')
             else
                Fastwrite(xp+4,rcnt+1,fc,bc,'.  ');
                Fastwrite(xp+7,rcnt+1,palette.text_color3,bc,hexn(patterns[pattern_number]^[rcnt][ccnt].effect));
                Fastwrite(xp+8,rcnt+1,fc,bc,hexb(patterns[pattern_number]^[rcnt][ccnt].ep));
           end;
         end;
         Fastwrite(xp+10,rcnt+1,palette.text_color1,bc,'³');
       end
       else
       begin

         if patterns[pattern_number]^[rcnt][ccnt].note in [0..4] then
         begin
           Fastwrite(xp,rcnt+1,fc,bc,Snoise[patterns[pattern_number]^[rcnt][ccnt].note]+' ');

           if patterns[pattern_number]^[rcnt][ccnt].Octave > 2 then
              patterns[pattern_number]^[rcnt][ccnt].Octave := 2;

           case patterns[pattern_number]^[rcnt][ccnt].Octave of
                0: Fastwrite(xp+4,rcnt+1,fc,bc,' .');
                1: Fastwrite(xp+4,rcnt+1,fc,bc,' W');
                2: Fastwrite(xp+4,rcnt+1,fc,bc,' P');
           end;

           if patterns[pattern_number]^[rcnt][ccnt].volume > 0 then
              Fastwrite(xp+6,rcnt+1,fc,bc,hexn(patterns[pattern_number]^[rcnt][ccnt].volume-1))
           else
              Fastwrite(xp+6,rcnt+1,fc,bc,'.');

         end
         else
         begin
           Fastwrite(xp,rcnt+1,fc,bc,'OFF    ');
         end;

       end;



      end;

    end;

    txtscreen.maxX  := 80;
    txtscreen.maxY  := 25;
    writeto(buffer.screen1);

  end;



 Procedure Draw_Empty_row(y : byte);
 begin
   fastwrite(Editor.p_xp,y,palette.text_color1,palette.window_color,'   ³');
   fastwrite(Editor.p_xp+4,y,palette.text_color1,palette.window_color,'          ³');
   fastwrite(Editor.p_xp+15,y,palette.text_color1,palette.window_color,'          ³');
   fastwrite(Editor.p_xp+26,y,palette.text_color1,palette.window_color,'          ³');
   if Editor.Channels = 4 then
      fastwrite(Editor.p_xp+37,y,palette.text_color1,palette.window_color,'        ')
   else
   begin
     fastwrite(Editor.p_xp+37,y,palette.text_color1,palette.window_color,'          ³');
     fastwrite(Editor.p_xp+48,y,palette.text_color1,palette.window_color,'        ');
   end;
 end;





 Procedure UpdatePatternView(start : integer; update_screen : boolean);
 {Displays a section of the prepared pattern data in buffer.pbuffer on the screen}
 var x,y,nr,r,c,rowlength : byte;
     boffs : word;
     buf_ptr : pointer;
 begin
   writeto(buffer.screen1);
   y := Editor.p_yp;
   x := Editor.p_xp;
   nr := 16;
   if start < -8 then start := -8;
   if start > 55 then start := 55;
   Editor.markedrow := start+8;

   if start < 0 then
   begin
     for c := 1 to (start*(-1)) do
     begin
       Draw_Empty_row(y);
       inc(y);
     end;

     nr := nr - (start*(-1));
   end;

  if start <= 0 then
  begin
   boffs := ofs(buffer.pbuffer^);
   start := 0;
  end
  else
   boffs := ofs(buffer.pbuffer^)+(start*108);

  if Editor.Channels = 4 then
   rowlength := 88
  else
   rowlength := 108;

   for r := start to start+nr do
   begin
     if r <= 63 then
     begin
        move(ptr(seg(buffer.pbuffer^),boffs)^,
             ptr(seg(buffer.screen1^),
             ofs(buffer.screen1^)+(((y-1)*txtscreen.maxX)+(x-1)) shl 1)^,rowlength);

        inc(boffs,108);
     end
     else
      Draw_Empty_Row(y);

   inc(y);
  end;

  Mark(Editor.p_xp,Editor.p_yp+8,rowlength div 2);
  Fastwrite(Editor.p_xp,Editor.p_yp+8,palette.text_color1,palette.mark_color,
            AddZero(10,Editor.markedrow));  {Rewrite row number in white}
  fastwrite(Editor.p_xp+3,Editor.p_yp+8,palette.text_color1,palette.mark_color,'³');
  fastwrite(Editor.p_xp+14,Editor.p_yp+8,palette.text_color1,palette.mark_color,'³');
  fastwrite(Editor.p_xp+25,Editor.p_yp+8,palette.text_color1,palette.mark_color,'³');
  fastwrite(Editor.p_xp+36,Editor.p_yp+8,palette.text_color1,palette.mark_color,'³');
  if update_screen then displaybuffer(buffer.screen1);
 end;



{============ Show the actual pattern order list ==============}

Procedure UpdatePatternOrder(update_screen : boolean);
 var cnt : integer;
     bc  : byte;

 begin
 for cnt := Player.Position-2 to Player.Position+2 do
 begin
  if cnt = Player.Position then bc := 4 else bc := palette.window_color;

  if ((cnt >= 0) and (cnt < Player.Songlength)) then
  begin
   Fastwrite(68,16+(cnt-Player.Position),15,bc,hexb(cnt)+':');
   Fastwrite(71,16+(cnt-Player.Position),14,bc,hexb(order[cnt]));
  end
  else
   Fastwrite(68,16+(cnt-Player.Position),palette.text_color2,palette.window_color,'     ');
 end;

 if update_screen then displaybuffer(buffer.screen1);
 end;





 {============ Draw the frames and titles for the pattern view screen ==============}

 Procedure Draw_Pattern_View(update_screen : boolean);
 begin
   move(buffer.blankscreen^,buffer.screen1^,4000);

   if Editor.channels = 4 then
   begin
    Editor.p_xp := 14;
    Editor.p_yp := 6;

    Window(Editor.p_xp-2,3,59,23,palette.text_color1,palette.window_color,true);
    hline(Editor.p_xp-1,5,46,palette.text_color1,palette.window_color,'Ä');
    fastwrite(Editor.p_xp+38,4,palette.text_color1,palette.window_color,'Noise');
   end
   else
   begin
    Editor.p_xp := 4;
    Editor.p_yp := 6;

    Window(Editor.p_xp-2,3,60,23,palette.text_color1,palette.window_color,true);
    hline(Editor.p_xp-1,5,57,palette.text_color1,palette.window_color,'Ä');
    fastwrite(Editor.p_xp+40,4,palette.text_color1,palette.window_color,'Spk.   ³');
    fastwrite(Editor.p_xp+49,4,palette.text_color1,palette.window_color,'Noise');
    putchar(Editor.p_xp+47,5,'Å',palette.text_color1,palette.window_color);
   end;

   fastwrite(Editor.p_xp-1,4,palette.text_color1,palette.window_color,' Ln ³ ');
   fastwrite(Editor.p_xp+5,4,palette.text_color1,palette.window_color,'Voice 1  ³ ');
   fastwrite(Editor.p_xp+16,4,palette.text_color1,palette.window_color,'Voice 2  ³ ');
   fastwrite(Editor.p_xp+27,4,palette.text_color1,palette.window_color,'Voice 3  ³ ');

   putchar(Editor.p_xp+3,5,'Å',palette.text_color1,palette.window_color);
   putchar(Editor.p_xp+14,5,'Å',palette.text_color1,palette.window_color);
   putchar(Editor.p_xp+25,5,'Å',palette.text_color1,palette.window_color);
   putchar(Editor.p_xp+36,5,'Å',palette.text_color1,palette.window_color);

   mainmenu := false;
   UpdatePatternView(editor.markedrow-8,update_screen);
 end;


{============ Draw the extra windows for the pattern editor ==============}

Procedure Draw_Pattern_Editor(update_screen : boolean);
begin
   window(62,3,78,9,palette.text_color1,palette.window_color,true);
   fastwrite(65,3,palette.text_color2,palette.window_color,' Current: ');
   fastwrite(64,5,palette.text_color1,palette.window_color,'Pattern:');
   fastwrite(72,5,palette.text_color2,palette.window_color,hexb(Player.pattern_num)+'/'+hexb(Player.MaxPattern));
   fastwrite(65,6,palette.text_color1,palette.window_color,'Octave:');
   fastwrite(72,6,palette.text_color2,palette.window_color,hexb(Editor.octave));
   fastwrite(65,7,palette.text_color1,palette.window_color,'Volume:');
   fastwrite(72,7,palette.text_color2,palette.window_color,hexn(Editor.curr_vol));

   window(63,11,77,23,palette.text_color1,palette.window_color,true);
   fastwrite(67,11,palette.text_color2,palette.window_color,' Order: ');
   box(67,13,73,19,palette.text_color1,palette.window_color,true);
   fastwrite(65,20,palette.text_color1,palette.window_color,'Loop to:');
   fastwrite(74,20,palette.text_color2,palette.window_color,hexb(Player.loop));
   fastwrite(64,22,7,palette.window_color,'Enter to edit');

   cursor(true);
   Change_cursor(0,7);
   UpdatePatternOrder(update_screen);

end;


Procedure Draw_Noise_Info;
begin
   fastwrite(65,6,palette.text_color1,palette.window_color,' Noise:');
   if Editor.noisetype = 1 then
    fastwrite(72,6,palette.text_color2,palette.window_color,'White')
   else
    fastwrite(72,6,palette.text_color2,palette.window_color,'Peri.');
end;

{============ Draw the extra window for the player ==============}
Procedure Draw_Player_State(update_screen : boolean);
begin
   window(62,3,78,9,palette.text_color1,palette.window_color,true);
   fastwrite(63,3,palette.text_color2,palette.window_color,' Player State: ');
   fastwrite(64,5,palette.text_color1,palette.window_color,'Pattern:');
   fastwrite(72,5,palette.text_color2,palette.window_color,hexb(Player.pattern_num)+'/'+hexb(Player.MaxPattern));
   fastwrite(64,6,palette.text_color1,palette.window_color,'Speed:');
   fastwrite(72,6,palette.text_color2,palette.window_color,hexb(Player.speed));
   fastwrite(64,7,palette.text_color1,palette.window_color,'Tempo:');
   fastwrite(72,7,palette.text_color2,palette.window_color,addzero(100,round(Player.Tempo))+' Hz');

   window(63,11,77,23,palette.text_color1,palette.window_color,true);
   fastwrite(67,11,palette.text_color2,palette.window_color,' Order: ');
   box(67,13,73,19,palette.text_color1,palette.window_color,true);
   fastwrite(65,20,palette.text_color1,palette.window_color,'Loop to:');
   fastwrite(74,20,palette.text_color2,palette.window_color,hexb(Player.loop));
   UpdatePatternOrder(update_screen);
end;


{============ Just update the contents of the player window ==============}
Procedure Update_Player_State;
begin
   fastwrite(72,5,palette.text_color2,palette.window_color,hexb(Player.pattern_num)+'/'+hexb(Player.MaxPattern));
   fastwrite(72,6,palette.text_color2,palette.window_color,hexb(Player.speed));
   fastwrite(72,7,palette.text_color2,palette.window_color,addzero(100,round(Player.tempo))+' Hz');
   UpdatePatternOrder(true);
end;





end.
