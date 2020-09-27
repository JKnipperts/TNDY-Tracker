{$G-,N-,E-}

{**************************************************************
 Help.pas - Help texts and procedures to display them

 Author: Jan Knipperts
 Program: TNDY-Tracker
 Version: 1.1

***************************************************************
}



Unit Help;
interface
uses keyboard,textmode,global;

Procedure Print_FX_Help_Screen(start_line, help_nr :  byte);
Procedure Showt_Help(helpnr : byte);
Procedure About_Window;


implementation


const
 about_msg    : string = 'A tracker for the TI SN76496A sound generator chip.';
 about_p_msg  : string = 'Written in Pascal and assembler code on a 80486 with 100 MHz.';
 dedi_msg1    : string = 'Dedicated to all who are still writing programs for DOS';
 dedi_msg2    : string = 'and all who love old hardware.';



 Help_keys    : array[1..42] of string[59] =
 ('                                                           ',
  'Pattern Editor:                                            ',
  '---------------                                            ',
  'Cursor keys        = Move around                           ',
  'PageUp             = Jump 16 rows up                       ',
  'PageDown           = Jump 16 rows down                     ',
  'Home               = Jump to first row                     ',
  'End                = Jump to last row                      ',
  'Backspace          = Delete previous note                  ',
  'Del                = Delete note at cursor                 ',
  'Ins                = Insert space at cursor position       ',
  'Return             = Edit Order                            ',
  'Shift + Pgup/Pgdwn = Change octave                         ',
  'Shift + Home/End   = Change volume                         ',
  'Shift+Ins          = Add pattern                           ',
  '+/-  (Numpad)      = Edit next / previous pattern          ',
  'Tab                = Jump to next track                    ',
  'Shift-Tab          = Jump to previous track                ',
  'Strg+p             = Clear current pattern                 ',
  'Strg+t             = Clear current track                   ',
  'Space              = Play song from current row / Stop/Edit',
  'Shift+Space        = Play current pattern from current row ',
  'F1 to F5           = Mute / Unmute channel                 ',
  'ESC                = Menu / Cancel                         ',
  '< or -             = Enter key-off                         ',
  '2, 3, 5, 6...                                              ',
  'Q, W, E, R...                                              ',
  'S, D, G, H...      = Insert notes (voice channels)         ',
  'Z, X, C, V...                                              ',
  '1,2,3,4            = Insert noise freq. (noise channel)    ',
  '                                                           ',
  'Pattern Order Editor:                                      ',
  '---------------------                                      ',
  'Cursor up/down     = Scroll through order list             ',
  'Cursor left/right  = Select digit of pattern number        ',
  'Home               = Jump to first entry                   ',
  'End                = Jump to last entry                    ',
  'Tab/Retrun         = Edit Loop position / Return to editor ',
  'ESC                = Jump back to the pattern editor       ',
  '0-9,A-F            = Enter digit (hex) of pattern number   ',
  'Only already created patterns can be entered!              ',
  '                                                           ');

 Help_keys_lines = 42;

 Help_FX    : array[1..48] of string[59] =
 ('                                                           ',
  'Effects:                                                   ',
  '---------                                                  ',
  '00 - Arpeggio                                              ',
  'Arpeggio quickly alters the note pitch between the base    ',
  'note and two given semitone offset.                        ',
  '                                                           ',
  '01 = Portamento up                                         ',
  '02 = Portamento down                                       ',
  'Portamento slides the note pitch up or down.               ',
  'The speed of the slide is defined by the parameter.        ',
  '                                                           ',
  '03 = Tone Portamento                                       ',
  'This variant of the portamento bends the already playing   ',
  'note pitch towards another note, entered with it.          ',
  'The speed of the slide is defined by the parameter.        ',
  '                                                           ',
  '04 = Volume Slide                                          ',
  'Slides note volume up/down at speed x/y depending on which ',
  'nibble of the parameter is specified.                      ',
  ' 4 x0 increases note volume by x units per tick.	      ',
  ' 4 0y decreases note volume by y units per tick.	      ',
  '                                                           ',
  '05 = Volume Slide + Tone Portamento                        ',
  'Combination of Toneslide and Volumeslide.                  ',
  'The effect continues a previously started toneslide and    ',
  'also performs a volume slide.                              ',
  'The parameter works like the normal volume slide.          ',
  '                                                           ',
  '0A = Fintetune                                             ',
  'This effect is used to fine tune the pitch of a note.      ',
  'The parameter specifies a value in Hertz (Hz) to be added  ',
  'or subtracted from the pitch of the note.                  ',
  'A value < 80h will be subtracted, > 80h will be added.     ',
  '                                                           ',
  '0B = Jump                                                  ',
  'Immediately breaks the current pattern and jumps to the    ',
  'defined order in the pattern order table.                  ',
  '                                                           ',
  '0D = Pattern Break                                         ',
  'Breaks the current pattern and jumps jumps to the row      ',
  'defined in the parameter on the next pattern.              ',
  '                                                           ',
  '0F = Set Speed                                             ',
  'Value less than 1F set a new speed value.                  ',
  'Values above 1F change the tempo of your song.             ',
  '(Speed = ticks per row, Tempo = timer ticks per second)    ',
  '                                                           ');

  Help_FX_lines = 48;




{============ The Help screens ==============}

 Procedure Print_FX_Help_Screen(start_line, help_nr :  byte);
 var lc : byte;
 begin
  for lc := 1 to 17 do
  begin

   if help_nr = 1 then
   begin
     if (start_line-1)+lc <= Help_keys_lines then
       centeredtext(4+lc,palette.text_color2,palette.menu_color,Help_Keys[(start_line-1)+lc]);
   end;

   if help_nr = 2 then
   begin
     if (start_line-1)+lc <= Help_FX_lines then
     centeredtext(4+lc,palette.text_color2,palette.menu_color,Help_FX[(start_line-1)+lc]);
   end;

  end;
 end;



 Procedure Showt_Help(helpnr : byte);
 var lc,my : byte;
     c  : char;
 begin
   move(buffer.screen1^,buffer.screen2^,4000);
   move(buffer.blankscreen^,buffer.screen1^,4000);
   writeto(buffer.screen1);
   window(5,3,75,23,15,1,true);
   centeredtext(3,palette.text_color1,palette.menu_color,' Help ');

   lc := 2;
   case helpnr of
   1 : my := Help_keys_lines;
   2 : my := Help_fx_lines;
   end;
   Print_FX_Help_Screen(lc,helpnr);
   centeredtext(23,palette.text_color1,palette.menu_color,' You see line '+addspace(10,lc-1)+' to '+addspace(10,lc+16)+
                 ' of '+addspace(10,my-1)+' lines. ');

   viewbuffer(buffer.screen1);
   Clear_Keypress;

   repeat;
     if is_key_pressed then Get_Key;




   if (key_code= 80) then  {down}
   begin
    if lc < (my-17) then inc(lc);
    Print_FX_Help_Screen(lc,helpnr);

   centeredtext(23,palette.text_color1,palette.menu_color,' You see line '+addspace(10,lc-1)+' to '+addspace(10,lc+16)+
                 ' of '+addspace(10,my-1)+' lines. ');

    viewbuffer(buffer.screen1);
    Clear_Keypress;
   end;

   if (key_code= 72) then  {up}
   begin
    if lc > 2 then dec(lc);
    Print_FX_Help_Screen(lc,helpnr);

    centeredtext(23,palette.text_color1,palette.menu_color,' You see line '+addspace(10,lc-1)+' to '+addspace(10,lc+16)+
                 ' of '+addspace(10,my-1)+' lines. ');

    viewbuffer(buffer.screen1);
    Clear_Keypress;
   end;

   if (key_code = 79) then {End}
   begin
    lc := my-17;
    Print_FX_Help_Screen(lc,helpnr);

    centeredtext(23,palette.text_color1,palette.menu_color,' You see line '+addspace(10,lc-1)+' to '+addspace(10,lc+16)+
                 ' of '+addspace(10,my-1)+' lines. ');

    viewbuffer(buffer.screen1);
    Clear_Keypress;
   end;

   if (key_code = 71) then {Pos1}
   begin
    lc := 2;
    Print_FX_Help_Screen(lc,helpnr);

    centeredtext(23,palette.text_color1,palette.menu_color,' You see line '+addspace(10,lc-1)+' to '+addspace(10,lc+16)+
                 ' of '+addspace(10,my-1)+' lines. ');

    viewbuffer(buffer.screen1);
    Clear_Keypress;
   end;

   if (key_code = 81) then {Pg dwn}
   begin
     if lc+17 <= my-17 then
      inc(lc,17)
     else
      lc := my-17;

     centeredtext(23,palette.text_color1,palette.menu_color,' You see line '+addspace(10,lc-1)+' to '+addspace(10,lc+16)+
                  ' of '+addspace(10,my-1)+' lines. ');

     Print_FX_Help_Screen(lc,helpnr);
     viewbuffer(buffer.screen1);
     Clear_Keypress;
   end;

   if (key_code = 73) then {Pg up}
   begin
     if lc-17 >= 2 then
      dec(lc,17)
     else
      lc := 2;

     centeredtext(23,palette.text_color1,palette.menu_color,' You see line '+addspace(10,lc-1)+' to '+addspace(10,lc+16)+
                  ' of '+addspace(10,my-1)+' lines. ');


     Print_FX_Help_Screen(lc,helpnr);
     viewbuffer(buffer.screen1);
     Clear_Keypress;
   end;



   until key_code= 1;
   Clear_Keypress;
   move(buffer.screen2^,buffer.screen1^,4000);
   viewbuffer(buffer.screen1);
 end;

 {============ Show the "About TNDY Tracker" window ==============}

 Procedure About_Window;
 begin
   move(buffer.screen1^,buffer.screen2^,4000);
   move(buffer.blankscreen^,buffer.screen1^,4000);
   writeto(buffer.screen1);

   window(7,7,73,18,15,1,true);

   centeredtext(7,palette.text_color1,palette.menu_color,' About TNDY Tracker ');
   centeredtext(9,palette.text_color2,palette.menu_color,title);
   centeredtext(10,palette.text_color2,palette.menu_color,about_msg);
   centeredtext(12,palette.text_color1,palette.menu_color,version);
   centeredtext(14,palette.text_color2,palette.menu_color,about_p_msg);
   centeredtext(15,palette.text_color2,palette.menu_color,dedi_msg1);
   centeredtext(16,palette.text_color2,palette.menu_color,dedi_msg2);
   centeredtext(18,palette.text_color1,palette.menu_color,' Press any key ');

   viewbuffer(buffer.screen1);

   Wait_for_keypress;
   move(buffer.screen2^,buffer.screen1^,4000);
   viewbuffer(buffer.screen1);
 end;




end.
