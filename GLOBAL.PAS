{$G-,N-,E-}

{**************************************************************
 Global.pas - All global variables, structures and constants

 Author: Jan Knipperts
 Program: TNDY-Tracker
 Version: 1.1

***************************************************************
}


Unit Global;
interface
uses dos;



const
 title          : string = 'TNDY Tracker by Jan Knipperts';
 version        : string = 'Version 1.1a Pre-release';


type

  TNDYevent   	 = record       {Structure of an event}
     note        : byte;
     octave      : byte;
     volume      : byte;
     effect      : byte;
     ep        	 : byte;
  end;

  Comp_event   	 = record       {Structure of a compressed event}
    n_o          : byte;
    v_e          : byte;
    ep	       	 : byte;
  end;


  TNDYheader     = record       {Header structure of a TNDY file}
     ID          : array[1..4] of char;
     Version     : byte;
     NChan       : byte;
     length      : byte;
     loop        : byte;
     NPatterns   : byte;
     speed       : byte;
     tempo       : byte;
  end;



 TNDYPattern     = array[0..63] of array[0..4] of TNDYevent;

 MODpattern      = array[0..63,0..15]of byte;

 TNDYpatPtr      = ^TNDYPattern;



 {============== Effects =================}

 Tonesl          = record     {Tone slide}
    limit        : word;      {Frequency limit}
    speed        : byte;      {Speed of the slide}
    freq         : word;      {Current frequency}
 end;

 arpeggio        = record     {Arpeggio}
    go  	 : boolean;   {is it running?}
    cnt          : byte;      {Counter of arpeggio steps}
    n1 	         : byte;      {First step  (note + n1)}
    n2           : byte;      {Second step (note + n2)}
    on           : byte;      {Original note}
    oc  	 : byte;      {Original octave}
 end;

 vslide    	 = record     {Volume slide}
    speed        : byte;      {Speed of the slide}
 end;



 SND_Import_cfg = record	{Options for the import of AGI music files}
   correct	: boolean;      {Correct frequency?}
   Delay        : byte;         {Delay value for playback}
   Speed        : byte;         {Speed value to use}
   Tempo	: byte;         {Tempo value to use}
   ClockFreq    : byte;         {Tandy or PCjr frequency? 0 = 111860 Hz, 1 = 99320 Hz}
  end;

 MOD_Import_cfg = record	{Options for the import of Amiga MOD files}
  ch4		: byte;         {What to do with channel 4? Noise, Speaker, nothing...}
  Speed		: byte;         {Speed to use}
  Tempo		: byte;         {Tempo to use}
  VolScale	: byte;         {How to scale the volume?}
 end;

 Timing_info    = record        {PIT / Interrupt}
    ticks       : word;         {Timer ticks for the player}
    clock_tick  : real;         {Timer ticks to call original Int 08h at 18.2 Hz}
 end;

 Colors	        = record        {Palette / Color definitions}
    window_color: byte;		{Color for window background}
    menu_color  : byte;		{Color for the background of the menu}
    mark_color  : byte;         {Color for marked items}
    text_color1 : byte;         {Color for Headlines}
    text_color2 : byte;		{Color for Text}
    text_color3	: byte;         {Color for highlighted items}
 end;

 Buffers        = record        {Pointers to additional Screnn buffer}
    screen1     : Pointer;      {Main buffer for screen drawing}
    screen2     : Pointer;      {additional buffer}
    oldscreen   : Pointer;      {buffer to hold a copy of the screen before modifying it}
    blankscreen : Pointer;      {buffer to hold a copy of the initial screen}
 end;

{================ Player ===================}

 Player_info    = record	{The variables needed by the player}
    maxpattern  : byte;         {Number of Patterns}
    row         : byte;         {current row}
    position    : byte;         {current order position}
    pattern_num : byte;         {number of the current pattern}
    speed       : byte;         {current speed}
    tempo       : byte;         {current tempo}
    songlength  : byte;         {song length / length of the order list}
    loop        : byte;         {pattern to loop to}

    muted       : array[0..4] of boolean;  {channel muted?}
    arp         : array[0..3] of arpeggio; {stores information for arpeggio effect}
    tsl         : array[0..3] of tonesl;   {stores information for tone slide effect}
    onote       : array[0..3] of byte;     {stores the last note played on each channel}
    ooct        : array[0..3] of byte;     {stores the octave of the last note played on each channel}
    finetune    : word;                    {the current finetune frequency}
 end;

{================== Editor ==================}

 Editor_info    = record       {Additional variables needed by the editor}
    markedrow   : byte;        {Current row for editing}
    octave      : byte;	       {Current octave}
    curr_vol    : byte;        {Current volume}
    chan        : byte;        {Current channel}
    Channels    : byte;        {Number of channels}
    new_note	: boolean;     {Was the note re-entered?}
    note_edit_cnt  : byte;     {TickCounter to time the playback of a note entered in the editor}
    orderview   : integer;     {current position of the order list to display}
    d_speed     : byte;        {default speed}
    d_tempo     : byte;        {default tempo}
    p_xp        : byte;        {X-position of the editor window (Depends on the number of channels)}
    p_yp        : byte;        {Y-position of the editor window}
 end;







var
 Palette	: Colors;
 Buffer  	: Buffers;
 Player		: Player_info;
 Editor		: Editor_info;
 Timing		: Timing_info;

 filename       : pathstr;
 f              : file;
 error          : byte;
 Header         : TNDYHeader;
 msg_buffer 	: array[1..400] of byte;
 p_msg  	: array[1..400] of byte;
 msg_size	: word;                 {Size of the song discription}

 SND		: SND_Import_CFG; {Configuration for the import of SND files}
 MODimp		: MOD_Import_CFG; {Configuration for the import of MOD files}

 xp,yp,
 ox,oy          : byte;    {Variables for positions and text alignment}

 dummy		: byte;    {the variables with secret powers...}
 z,i            : word;

 Patterns       : array[0..255]of TNDYpatptr; {Pointer to max. 256 ptterns}
 Order          : array[0..255] of byte;      {The order list}

 mainmenu,       	   {is the menu active?}
 pedit,          	   {is the pattern editor active?}
 noteedit,       	   {is the cursor in the position to enter a note?}
 pause,          	   {playing or paused?}
 patternplay,    	   {should only one pattern be played?}
 update,         	   {time to update player information?}
 quit           : boolean;

 active_menu,              {Number of the current active submenu}
 select         : byte;	   {Menu and entry selection}











implementation
end.
