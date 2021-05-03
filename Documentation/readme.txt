TNDY Tracker (v.1.2)
Quickstart guide or how to get started?

TNDY Tracker is a program for MS-DOS and was created as a pure hobby project to support the retro soundcard projects TNDY and TNDLPT. With it you can create music tracks based on the TI SN76496A and compatible sound generator chips.  This sound chip was for example built into IBM's PCjr and early computers of the Tandy Cooperation and supports 3 voices + one additional channel for noise.
Additionally the TNDY Tracker offers the possibility to run another voice over the PC speaker. If your speaker is routed over a soundcard or you use a real Tandy 1000, this will provide a quite acceptable sounding additional voice. Especially for lower frequencies, because the "Tandy-Soundchip" does not support frequencies below 110 Hz.

The Pattern Editor:
-------------------
The design of the tracker more or less follows the tracker design introduced by the Protracker (on the Amiga): You can create patterns and define the order in which they should be played later.
After starting the program, you are in the pattern editor and you can start entering notes immediately. 
As with most trackers, this is done using the
2, 3, 5, 6...
Q, W, E, R...
S, D, G, H...
Z, X, C, V...
keys.
With Shift+Page up or Shift+Page down the okatve can be adjusted.
Behind the Note+Okatve the volume is indicated. Valid values here are that 0 to 15 which are given as 0 to F in hexadecimal form.
The volume can be entered there. You can also use Shift+Home or Shift+End to quickly select a volume that is set directly when you enter a new note.
Behind the volume, on a voice channel there is another column. Effects can be entered here (see below).

So an event for a channel looks like this:
C-4 2 401
This plays the note C in octave 4 by a volume of 2 and then performs a volume slide down with a speed of one (effect 4 with parameter 01).
You can use the cursor keys and tab to navigate the Pattern Editor. Ctrl+A adds a new empty pattern to your song.

The Order Editor:
-----------------
By pressing the return-key you enter the Order Editor where the order of the patterns can be altered (only already created patterns can be entered). 
Insert adds a new line to the order list and Delete removes it.

Pressing ESC or Return again will bring you back to the Pattern Editor.

By pressing ESC in Pattern Editor, you can enter the menu and navigate through the options by using the arrow keys.


The Menu
--------
Files can be saved and loaded via the first ribbon "File". Everything that has to do with playing music can be found under "Play".
"Edit gives you advanced editing tools, like Transpose. Patterns can also be added and removed here, the additional speaker track can be switched on or off and you can write a small message and save it with your song.
"Config" is the tab you should go to first. Here you select the correct I/O port for your sound chip under "Output Device".
In addition to the sound chip settings, there are options for importing audio data from Sierrea Online games and Amiga (Protracker) MOD files.

TNDY Tracker can read the tandy-music of Sierra Online's AGI games from the 1980s.
For this, the music resources must first be extracted from the volume files of the respective game (VOL files). TNDY-Tracker recognises .SND or numbers like .000, .001 etc. as file extensions.
Converting the timing of these files to a tracker format is a bit tricky and partly the games differ somewhat here. Therefore, you can set some options for it here.

The duration of a tone in the game music is given in units of 1/60 of a second. So a tempo of 60Hz by a speed of 1 tick per row is perfect for playing and editing this music.
But this creates very large modules with many patterns and as soon as you want to add effects, you need more ticks. To help you here, speed can be set to "AUTO". Then the smallest distance between two notes in the file is set as Speed (ticks per row).

Since some players and apparently some of the Sierra Online games use an alternative frequency for the sound chip, you can also select here between different clock frequencies.

Pattern data can also be imported from Amiga MOD files. For this purpose, settings can also be made, for example, how the fourth channel should be imported.
Since MODs are based on sampling, unfortunately, extensive revisions are often necessary to make the melody sound good on a tandy-3-voice.

"Help" gives you a quick help to keys and effects. And quit... I think you know what this is about.
Most of the menus should be self-explanatory, especially if you have already worked with a tracker. Just try them out :)


Keyboard shortcuts
------------------
TNDY-Tracker is operated completely via the keyboard. Many of the items from the menus can also be quickly called up using a key combination.
Here is an overview:

While in Pattern Editor:  

  Up,Down,Left,Right = Cursor navigation
  Shift+Up/down      = Mark a block
  PgUp,PgDn          = Move up/down 16 lines
  Home,End           = Move to the top/end of current pattern
  Tab, Shift+Tab     = Move to the next/previous track
  Backspace          = Delete previous event
  Del                = Clear note, attribute or marked block
  Shift+Del          = Delete event
  Ctrl+p             = Clear current pattern
  Ctrl+t             = Clear current track
  Ctrl+a             = Add a new, empty pattern to the file
  Ctrl+r             = Delete current pattern from file
  Ctrl+c             = Copy to clipboard
  Ctrl+x             = Cut to clipboard
  Ctrl+v             = Paste from clipboard
  Ins                = Insert new track line
  Shift+Ins          = Insert new pattern line

  Shift + Pgup/Pgdwn = Change octave
  Shift + Home/End   = Change volume
  Return             = Edit Order
  Shift + Right/Left,
  +/- (Numpad/Tandy) = Edit next / previous pattern
  Spacebar           = Play current row
  Alt+1,2,3,4,5      = Mute / Unmute channel
  Alt+s              = Mute all but current channel (Solo)
  ESC                = Menu / Cancel
  < or - (on PC AT),
  /? on a Tandy      = Enter key-off
  2, 3, 5, 6...
  Q, W, E, R...
  S, D, G, H...
  Z, X, C, V...      = Enter note (voice channels)
  1,2,3,4            = Insert noise freq. (noise channel)

  F1                 = Help
  F2 or Ctrl+s       = Save
  F3 or Ctrl+l       = Load
  F4                 = Toggle playing with trace
  F5                 = Play Song
  F6                 = Stop
  F7                 = Play from current position
  F8                 = Play current pattern
  F9                 = Transpose
  F10                = Mute all sound output

While in the Order Editor:  

  Cursor up/down     = Scroll through order list
  Cursor left/right  = Select digit of pattern number
  Home               = Jump to first entry
  End                = Jump to last entry
  Tab/Retrun         = Edit loop position
  ESC                = Jump back to the pattern editor
  0-9,A-F            = Enter digit (hex) of pattern number
  + / -              = Increase/Decrease pattern number
  Note: Only existing patterns can be entered.

While playing:  

  Shift + Right/Left
  or +/-             = jump to next / previous position
  up/down            = forward/rewind
  ESC                = open menu
  F6                 = Stop and return to last editor state
  F7                 = Stop at current position
  F4                 = Toggle player screen
  Alt+1,2,3,4,5      = Mute / Unmute channel
  Alt+s              = Mute all but current channel (Solo)
  
  
  
Effects
---------
As with most trackers, you can use additional effects. The effects supported by the TNDY tracker are based on the MOD format.
The following effects are supported by the current version 1.2:

  00 - Arpeggio                                              
  Arpeggio quickly alters the note pitch between the base    
  note and two given semitone offset.                        
                                                             
  01 = Portamento up                                         
  02 = Portamento down                                       
  Portamento slides the note pitch up or down.               
  The speed of the slide is defined by the parameter.        
                                                             
  03 = Tone Portamento                                       
  This variant of the portamento bends the already playing   
  note pitch towards another note, entered with it.          
  The speed of the slide is defined by the parameter.        
                                                             
  04 = Volume Slide                                          
  Slides note volume up/down at speed x/y depending on which 
  nibble of the parameter is specified.                      
   4 x0 increases note volume by x*0.23 units per tick.      
   4 0y decreases note volume by y*0.23 units per tick.      
                                                             
  05 = Volume Slide + Tone Portamento                        
  Combination of Toneslide and Volumeslide.                  
  The effect continues a previously started toneslide and    
  also performs a volume slide.                              
  The parameter works like the normal volume slide.          
                                                             
  0A = Fintetune                                             
  This effect is used to fine tune the pitch of a note.      
  The parameter specifies a value in Hertz (Hz) to be added  
  or subtracted from the pitch of the note.                  
  A value < 80h will be subtracted, > 80h will be added.     
                                                             
  0B = Jump                                                  
  Immediately breaks the current pattern and jumps to the    
  defined order in the pattern order table.                  
                                                             
  0D = Pattern Break                                         
  Breaks the current pattern and jumps jumps to the row      
  defined in the parameter on the next pattern.              
                                                             
  0F = Set Speed                                             
  Value less than 1F set a new speed value.                  
  Values above 1F change the tempo of your song.             
  (Speed = ticks per row, Tempo = timer ticks per second)    
                                                                                                                                                                         
I think with this information you'll be able to get started.
Have fun creating your chiptune!
