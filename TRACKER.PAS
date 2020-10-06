{$G-,N-,E-}

{**************************************************************
 Tracker.pas - Procedures for drawing the pattern editor and
               player windows

 Author: Jan Knipperts
 Program: TNDY-Tracker
 Version: 1.11

***************************************************************
}





Unit Tracker;
interface
uses global,textmode,keyboard,menu;

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


 Procedure UpdatePatternView(start : integer; update_screen : boolean);
 var x,y,ccnt,fc,bc : byte;
     rcnt           : integer;
 begin


    bc := palette.window_color;
    fc := palette.text_color2;
    y := Editor.p_yp;

    if start < -8 then start := -8;
    if start > 55 then start := 55;
    Editor.markedrow := start+8;

    for rcnt := start to start + 16 do          {Row count}
    begin

      if (rcnt = Editor.markedrow) then		{Is this the marked row?}
      begin
       bc := palette.mark_color;
       fc := palette.text_color1;
      end
      else
      begin
       bc := palette.window_color;
       fc := palette.text_color2;
      end;

      if (rcnt >= 0) and (rcnt < 64) then
        Fastwrite(Editor.p_xp,y,fc,bc,AddZero(10,rcnt))  {Write row count}
      else
        Fastwrite(Editor.p_xp,y,fc,bc,'  ');

      Fastwrite(Editor.p_xp+2,y,palette.text_color1,bc,' ³ ');

      x := Editor.p_xp+4;

      for ccnt := 0 to Editor.channels-1 do {Channel count}
      begin

         if (Player.muted[ccnt] = true) and (rcnt <> Editor.markedrow) then
         begin
          fc := 7;
         end
         else
          fc := palette.text_color2;

         if (rcnt >= 0) and (rcnt < 64) then
         begin

           if ccnt < Editor.channels-1 then
           begin
             if patterns[Player.pattern_num]^[rcnt][ccnt].note in [0..13] then
             begin
               if patterns[Player.pattern_num]^[rcnt][ccnt].note = 13 then
                Fastwrite(x,y,fc,bc,'OFF       ')
               else
               begin
                 if patterns[Player.pattern_num]^[rcnt][ccnt].Octave > 0 then
                  Fastwrite(x,y,fc,bc,snote[patterns[Player.pattern_num]^[rcnt][ccnt].note]+
                            hexn(patterns[Player.pattern_num]^[rcnt][ccnt].Octave)+' ')
                 else
                  Fastwrite(x,y,fc,bc,snote[patterns[Player.pattern_num]^[rcnt][ccnt].note]+'. ');

		 if patterns[Player.pattern_num]^[rcnt][ccnt].volume > 0 then
                  Fastwrite(x+4,y,fc,bc,hexn(patterns[Player.pattern_num]^[rcnt][ccnt].volume-1)+'  ')
                 else
                  Fastwrite(x+4,y,fc,bc,'.  ');

                 if (rcnt <> Editor.markedrow) then
                  Fastwrite(x+7,y,palette.text_color3,bc,hexn(patterns[Player.pattern_num]^[rcnt][ccnt].effect))
                 else
                  Fastwrite(x+7,y,palette.text_color2,bc,hexn(patterns[Player.pattern_num]^[rcnt][ccnt].effect));

                 Fastwrite(x+8,y,fc,bc,hexb(patterns[Player.pattern_num]^[rcnt][ccnt].ep));
               end;
             end;
            end
            else
            begin

             if patterns[Player.pattern_num]^[rcnt][ccnt].note in [0..4] then
             begin
               Fastwrite(x,y,fc,bc,Snoise[patterns[Player.pattern_num]^[rcnt][ccnt].note]+' ');

               if patterns[Player.pattern_num]^[rcnt][ccnt].Octave > 2 then
                patterns[Player.pattern_num]^[rcnt][ccnt].Octave := 2;

               case patterns[Player.pattern_num]^[rcnt][ccnt].Octave of
                0: Fastwrite(x+4,y,fc,bc,' .');
                1: Fastwrite(x+4,y,fc,bc,' W');
                2: Fastwrite(x+4,y,fc,bc,' P');
               end;

               if patterns[Player.pattern_num]^[rcnt][ccnt].volume > 0 then
               Fastwrite(x+6,y,fc,bc,hexn(patterns[Player.pattern_num]^[rcnt][ccnt].volume-1))
               else
               Fastwrite(x+6,y,fc,bc,'.');

             end
             else
             begin
               Fastwrite(x,y,fc,bc,'OFF    ');
             end;
           end;

        end
        else
        begin
          if ccnt < Editor.channels-1 then Fastwrite(x,y,fc,bc,'          ')
          else Fastwrite(x,y,fc,bc,'       ');
        end;

         if ccnt < Editor.channels-1 then
         begin
          Fastwrite(x+10,y,palette.text_color1,bc,'³');
          inc(x,11);
         end;
      end;
      inc(y);
    end;

  if start < 0 then start := 1;

 if Editor.channels = 5 then		{Mark marked line on B/W screens}
  MDA_Mark(Editor.p_xp,y-9,55)
 else
  MDA_Mark(Editor.p_xp,y-9,44);


  if update_screen then ViewBuffer(buffer.screen1);
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

 if update_screen then ViewBuffer(buffer.screen1);
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
