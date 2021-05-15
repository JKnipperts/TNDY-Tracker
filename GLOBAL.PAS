{$G-,N-,E-}

{**************************************************************
 Global.pas - All global variables, structures and constants

 Author: Jan Knipperts
 Program: TNDY-Tracker
 Version: 1.22a

***************************************************************
}


Unit Global;
interface
uses dos;



const
 title              : string = 'TNDY Tracker by Jan Knipperts';
 version            : string = 'Version 1.21a';
 File_version       : byte = 2;  {File format version 2}




type

  TNDYevent   	    = record       {Structure of an event}
     note           : byte;
     octave         : byte;
     volume         : byte;
     effect         : byte;
     ep        	    : byte;
  end;

  Comp_event   	    = record       {Structure of a compressed event}
    n_o             : byte;
    v_e             : byte;
    ep	       	    : byte;
  end;


  TNDYheader        = record       {Header structure of a TNDY file}
     ID             : array[1..4] of char;
     Version        : byte;
     NChan          : byte;
     length         : byte;
     loop           : byte;
     NPatterns      : byte;
     speed          : byte;
     tempo          : byte;
  end;





 TNDYPattern        = array[0..63] of array[0..4] of TNDYevent;

 MODpattern         = array[0..63,0..15]of byte;

 TNDYpatPtr         = ^TNDYPattern;


 Clip_rec	    = record
   startpos	    : byte;
   endpos	    : byte;
   track	    : byte;
   noise	    : boolean;
   buffer	    : array[0..63] of TNDYevent;
   inuse,mark 	    : boolean;
 end;

  Ptn_display_rec   = record
    tracemode       : boolean;   {playing with trace?}
    ptnupdate       : boolean;   {time to update the displayed pattern?}
    infoupdate      : boolean;   {time to refresh player infos?}
    bufferswap	    : boolean;   {time to swap front- and backbuffer?}
  end;




 {============== Effects =================}

 Tonesl             = record     {Tone slide}
    limit           : word;      {Frequency limit}
    speed	    : byte;
 end;

 arpeggio           = record     {Arpeggio}
    cnt             : byte;      {Counter of arpeggio steps}
    n0              : byte;      {Original note}
    o0  	    : byte;      {Original octave}
    n1 	            : byte;      {First step  (note + n1)}
    o1		    : byte;
    n2              : byte;      {Second step (note + n2)}
    o2		    : byte;
 end;

 vslide    	    = record     {Volume slide}
    speed           : byte;      {Speed of the slide}
 end;


 {============== Configuration =================}



 SND_Import_cfg     = record	{Options for the import of AGI music files}
   correct	    : boolean;      {Correct frequency?}
   Speed            : byte;         {Speed value to use}
   Tempo	    : byte;         {Tempo value to use}
   ClockFreq        : byte;         { 0 = 111860 Hz, 1 = 99320 Hz}
  end;

 MOD_Import_cfg     = record	{Options for the import of Amiga MOD files}
  ch4		    : byte;         {What to do with channel 4? Noise, Speaker, nothing...}
  Speed		    : byte;         {Speed to use}
  Tempo		    : byte;         {Tempo to use}
  VolScale	    : byte;         {How to scale the volume?}
 end;

 Colors	            = record        {Palette / Color definitions}
  window_color      : byte;		{Color for window background}
  menu_color        : byte;		{Color for the background of the menu}
  mark_color        : byte;         {Color for marked items}
  text_color1       : byte;         {Color for Headlines}
  text_color2       : byte;	    {Color for Text}
  text_color3	    : byte;         {Color for highlighted items}
 end;


{============== Timing and buffers =================}

 Timing_info        = record        {PIT / Interrupt}
    ticks           : word;         {Timer ticks for the player}
    clock_tick      : real;         {Timer ticks to call original Int 08h at 18.2 Hz}
 end;


 Buffers            = record        {Pointers to additional Screnn buffer}
    screen1         : Pointer;      {Main buffer for screen drawing}
    screen2         : Pointer;      {additional buffer}
    oldscreen       : Pointer;      {buffer to hold a copy of the screen before modifying it}
    blankscreen     : Pointer;      {buffer to hold a copy of the initial screen}
    pbuffer	    : Pointer;      {Pattern screen buffers}
    pbuffer1	    : Pointer;      {Pattern screen buffer}
 end;

{================ Player ===================}

 Player_info        = record	{The variables needed by the player}
    maxpattern      : byte;         {Number of Patterns}
    row             : byte;         {current row}
    position        : byte;         {current order position}
    pattern_num     : byte;         {number of the current pattern}
    speed           : byte;         {current speed}
    tempo           : byte;         {current tempo}
    songlength      : byte;         {song length / length of the order list}
    loop            : byte;         {pattern to loop to}

    muted           : array[0..4] of boolean;  {channel muted?}
    onote           : array[0..4] of byte;     {stores the last note played on each channel}
    ooct            : array[0..4] of byte;     {stores the octave of the last note played on each channel}
    arp             : array[0..3] of arpeggio; {stores information for arpeggio effect}
    tsl             : array[0..3] of tonesl;   {stores information for tone slide effect}
    vsl		    : array[0..3] of real;     {volume for volume slide}
 end;

{================== Editor ==================}

 Editor_info        = record       {Additional variables needed by the editor}
    markedrow       : byte;        {Current row for editing}
    octave          : byte;	   {Current octave}
    curr_vol        : byte;        {Current volume}
    noisetype       : byte;	   {Type of noise for noise channel}
    chan            : byte;        {Current channel}
    Channels        : byte;        {Number of channels}
    play_note	    : boolean;     {Play the entered note?}
    play_row	    : boolean;     {Play single row?}
    solo	    : boolean;     {Play only current channel?}
    saved	    : boolean;     {All changes saved?}
    note_edit_cnt   : byte;        {TickCounter to time the playback of a note entered in the editor}
    orderview       : integer;     {current position of the order list to display}
    d_speed         : byte;        {default speed}
    d_tempo         : byte;        {default tempo}
    playtime	    : byte;        {time in ticks a note is played when entered}
    playticks	    : byte;
    p_xp            : byte;        {X-position of the editor window (Depends on the number of channels)}
    p_yp            : byte;        {Y-position of the editor window}
 end;


 Editor_position    = record
    pos	            : byte;
    patn	    : byte;
    row	            : byte;
    xp              : byte;
 end;







var
    Palette	    : Colors;      {Colorset}
    Buffer  	    : Buffers;     {Screen an pattern buffers in memory}
    Boffs           : word;        {Holds current offset in pattern buffer}

    Player          : Player_info;
    Editor	    : Editor_info;
    Timing	    : Timing_info;

    f               : file;
    filename        : pathstr;
    error           : byte;
    Header          : TNDYHeader;
    msg_buffer 	    : array[1..400] of byte; {song description}
    p_msg  	    : array[1..400] of byte; {compressed song description}
    msg_size	    : word;                 {Size of the song discription}

    SNDcfg	    : SND_Import_CFG; {Configuration for the import of SND files}
    MODcfg	    : MOD_Import_CFG; {Configuration for the import of MOD files}

    xp              : byte;   {Variables for positions and text alignment}
    yp              : byte;
    ox              : byte;
    oy              : byte;

    dummy	    : byte;   {variables with secret powers...}
    z		    : word;
    i               : word;

    Patterns        : array[0..127]of TNDYpatptr; {Pointer to max. 128 pattern buffers}
    Order           : array[0..127] of byte;      {The order list}

    mainmenu        : boolean;  {is the menu active?}
    pedit           : boolean;  {is the pattern editor active?}
    noteedit        : boolean;  {is the cursor in the position to enter a note?}
    pause           : boolean;  {playing or paused?}
    patternplay     : boolean;  {should only one pattern be played?}
    update          : boolean;  {time to update player information?}
    quit            : boolean;  {quit?}
    Monochrome      : boolean;  {Monochrome display in use?}

    active_menu     : byte;     {Number of the active menu}
    select          : byte;     {Number of the selected menu item}
    in_subscreen    : boolean;

    OldExitProc     : Pointer;  {Pointer to save the orig. exit proc. and interrupt vectors}
    oldint08        : Procedure;

    Volume	    : array[0..4] of byte; {Volume of each channel}
    Freq	    : array[0..4] of word; {Frequency of each channel}
    Current	    : array[0..4] of TNDYevent;	{Data of active events}
    Meter	    : array[0..4] of byte; {Values for peak meter}

    Ptn		    : Ptn_display_rec; {Infos to display the pattern}
    Clipboard	    : Clip_Rec;	{The Clipboard}

    pstate	    : boolean;  {to save pause state}
    screenwriting   : boolean;
    update_ptn	    : byte;

    update_ptn_j    : byte;
    j_row	    : byte;

    old             : editor_position;







Function  FileExist(name : string) : boolean;
Procedure Clear_Pattern_Data;



implementation


Function FileExist(name : string) : boolean;
var tf : file;
begin
 fileexist := true;
{$I-}
 assign(tf,name);
 reset(tf,1);
 close(tf);
{$I+}
 If IOResult <> 0 then fileexist := false;
end;



Procedure Clear_Pattern_Data;
var c : byte;
begin
   for c := 0 to Player.MaxPattern do			{Delete possible old pattern data}
    begin
      if patterns[c] <> nil then
      begin
       fillchar(patterns[c]^,sizeof(TNDYPattern),0);
       dispose(patterns[c]);
       patterns[c] := nil;
      end;
    end;
   new(patterns[0]);
   fillchar(patterns[0]^,sizeof(TNDYPattern),0);
end;

end.
