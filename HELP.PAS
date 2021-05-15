{$G-,N-,E-}

{**************************************************************
 Help.pas - Help texts and procedures to display them

 Author: Jan Knipperts
 Program: TNDY-Tracker
 Version: 1.21b
 - added new keys
 - removed effects introduced on a test basis in v1.1 (sorry guys!)
 - updated buffering
***************************************************************
}



Unit Help;
interface
uses keyboard,textmode,global;

Procedure Print_FX_Help_Screen(start_line, help_nr :  byte);
Procedure Show_Help(helpnr : byte);
Procedure About_Window;


implementation


const
 about_msg    : string = 'A tracker for the TANDY/PCjr 3-voice sound generator.';
 about_v_msg  : string = '';
 dedi_msg1    : string = 'Dedicated to all those who enjoy';
 dedi_msg2    : string = 'old hardware and chiptunes.';


 Help_keys_lines = 71;
 Help_keys    : array[1..Help_keys_lines] of string[59] =
 ('                                                           ',
  'Pattern Editor:                                            ',
  '---------------                                            ',
  'Up,Down,Left,Right = Cursor navigation                     ',
  'Shift+Up/down      = Mark a block                          ',
  'PgUp,PgDn          = Move up/down 16 lines                 ',
  'Home,End           = Move to the top/end of current pattern',
  'Tab, Shift+Tab     = Move to the next/previous track       ',
  'Backspace          = Delete previous event                 ',
  'Del                = Clear note, attribute or marked block ',
  'Shift+Del          = Delete event                          ',
  'Ctrl+p             = Clear current pattern                 ',
  'Ctrl+t             = Clear current track                   ',
  'Ctrl+a             = Add a new, empty pattern to the file  ',
  'Ctrl+r             = Delete current pattern from file      ',
  'Ctrl+c             = Copy to clipboard                     ',
  'Ctrl+x             = Cut to clipboard                      ',
  'Ctrl+v             = Paste from clipboard                  ',
  'Ins                = Insert new track line                 ',
  'Shift+Ins          = Insert new pattern line               ',

  'Shift + Pgup/Pgdwn = Change octave                         ',
  'Shift + Home/End   = Change volume                         ',
  'Return             = Edit Order                            ',
  'Shift + Right/Left,                                        ',
  '+/- (Numpad/Tandy) = Edit next / previous pattern          ',
  'Spacebar           = Play current row                      ',
  'Alt+1,2,3,4,5      = Mute / Unmute channel                 ',
  'Alt+s              = Mute all but current channel (Solo)   ',
  'ESC                = Menu / Cancel                         ',
  '<,- (/? for Tandy) = Enter key-off                         ',
  '2, 3, 5, 6...    '+#191+'                                          ',
  'Q, W, E, R...    '+#179+'                                          ',
  'S, D, G, H...    '+#179+' = Enter note (voice channels)            ',
  'Z, X, C, V...    '+#217+'                                          ',
  '1,2,3,4           = Insert noise freq. (noise channel)     ',
  '                                                           ',
  'F1                 = Help                                  ',
  'F2 or Ctrl+s       = Save                                  ',
  'F3 or Ctrl+l       = Load                                  ',
  'F4                 = Toggle playing with trace             ',
  'F5                 = Play Song                             ',
  'F6                 = Stop                                  ',
  'F7                 = Play from current position            ',
  'F8                 = Play current pattern                  ',
  'F9                 = Transpose                             ',
  'F10                = Mute all sound output                 ',
  '                                                           ',
  'Pattern Order Editor:                                      ',
  '---------------------                                      ',
  'Cursor up/down     = Scroll through order list             ',
  'Cursor left/right  = Select digit of pattern number        ',
  'Home               = Jump to first entry                   ',
  'End                = Jump to last entry                    ',
  'Tab/Retrun         = Edit loop position                    ',
  'ESC                = Jump back to the pattern editor       ',
  '0-9,A-F            = Enter digit (hex) of pattern number   ',
  '+ / -              = Increase/Decrease pattern number      ',
  'Note: Only existing patterns can be entered.               ',
  '                                                           ',
  'While playing:                                             ',
  '---------------                                            ',
  'Shift + Right/Left                                         ',
  'or +/- (Numpad)    = jump to next / previous position      ',
  'up/down            = forward/rewind                        ',
  'ESC                = open menu                             ',
  'F6                 = Stop and return to last editor state  ',
  'F7                 = Stop at current position              ',
  'F4                 = Toggle player screen                  ',
  'Alt+1,2,3,4,5      = Mute / Unmute channel                 ',
  'Alt+s              = Mute all but current channel (Solo)   ',
  '                                                           ');



 Help_FX_lines = 48;
 Help_FX    : array[1..Help_FX_lines] of string[59] =
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
  ' 4 x0 increases note volume by x*0.23 units per tick.      ',
  ' 4 0y decreases note volume by y*0.23 units per tick.      ',
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



 Procedure Show_Help(helpnr : byte);
 var lc,my : byte;
     c  : char;
 begin
   CopyBuffer(buffer.blankscreen,buffer.screen2);
   writeto(buffer.screen2);

   Box(5,3,75,23,15,1,false,true);
   centeredtext(3,palette.text_color1,palette.menu_color,' Help ');

   lc := 2;
   case helpnr of
   1 : my := Help_keys_lines;
   2 : my := Help_fx_lines;
   end;
   Print_FX_Help_Screen(lc,helpnr);
   centeredtext(23,palette.text_color1,palette.menu_color,' You see line '+addspace(10,lc-1)+' to '+addspace(10,lc+16)+
                 ' of '+addspace(10,my-1)+' lines. ');

   displaybuffer(buffer.screen2);
   Clear_Keypress;

   repeat;
     if is_key_pressed then Get_Key;




   if (key_code= 80) then  {down}
   begin
    if lc < (my-17) then inc(lc);
    Print_FX_Help_Screen(lc,helpnr);

    centeredtext(23,palette.text_color1,palette.menu_color,' You see line '+addspace(10,lc-1)+' to '+addspace(10,lc+16)+
                 ' of '+addspace(10,my-1)+' lines. ');

    Clear_Keypress;
   end;

   if (key_code= 72) then  {up}
   begin
    if lc > 2 then dec(lc);
    Print_FX_Help_Screen(lc,helpnr);

    centeredtext(23,palette.text_color1,palette.menu_color,' You see line '+addspace(10,lc-1)+' to '+addspace(10,lc+16)+
                 ' of '+addspace(10,my-1)+' lines. ');


    Clear_Keypress;
   end;

   if (key_code = 79) then {End}
   begin
    lc := my-17;
    Print_FX_Help_Screen(lc,helpnr);

    centeredtext(23,palette.text_color1,palette.menu_color,' You see line '+addspace(10,lc-1)+' to '+addspace(10,lc+16)+
                 ' of '+addspace(10,my-1)+' lines. ');


    Clear_Keypress;
   end;

   if (key_code = 71) then {Pos1}
   begin
    lc := 2;
    Print_FX_Help_Screen(lc,helpnr);

    centeredtext(23,palette.text_color1,palette.menu_color,' You see line '+addspace(10,lc-1)+' to '+addspace(10,lc+16)+
                 ' of '+addspace(10,my-1)+' lines. ');


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

     Clear_Keypress;
   end;

     displaybuffer(buffer.screen2);

   until key_code= 1;
   writeto(buffer.screen1);
   displaybuffer(buffer.screen1);
   Clear_Keypress;
 end;

 {============ Show the "About TNDY Tracker" window ==============}

 Procedure About_Window;
 begin
   CopyBuffer(buffer.blankscreen,buffer.screen2);
   writeto(buffer.screen2);

   Box(7,7,73,18,15,1,false,true);

   centeredtext(7,palette.text_color1,palette.menu_color,' About TNDY Tracker ');
   centeredtext(9,palette.text_color2,palette.menu_color,title);
   centeredtext(10,palette.text_color2,palette.menu_color,about_msg);
   centeredtext(12,palette.text_color1,palette.menu_color,version);
   centeredtext(13,palette.text_color2,palette.menu_color,about_v_msg);
   centeredtext(15,palette.text_color2,palette.menu_color,dedi_msg1);
   centeredtext(16,palette.text_color2,palette.menu_color,dedi_msg2);
   centeredtext(18,palette.text_color1,palette.menu_color,' Press any key ');

   displaybuffer(buffer.screen2);

   Wait_for_keypress;
   writeto(buffer.screen1);
   displaybuffer(buffer.screen1);
   Clear_Keypress;
 end;




end.
