TNDY Tracker
(v.1.1)

TNDY Tracker is a program for MS-DOS and was created as a pure hobby project to support the retro soundcard projects TNDY and TNDLPT. With it you can create music tracks based on the TI SN76496A and compatible sound generator chips.  This sound chip was for example built into IBM's PCjr and early computers of the Tandy Cooperation and supports 3 voices + one additional channel for noise.
Additionally the TNDY Tracker offers the possibility to run another voice over the PC speaker. If your speaker is routed over a soundcard, this will provide a quite acceptable sounding additional voice. Especially for low frequencies, because the "Tandy-Soundchip" does not support frequencies below 110 Hz.

The design of the tracker more or less follows the tracker design introduced by the Protracker (on the Amiga).  You can create patterns and define the order in which they should be played later.
After starting the program, you are directly in the pattern editor and can start entering notes. As with most trackers, this is done using the
2, 3, 5, 6...
Q, W, E, R...
S, D, G, H...
Z, X, C, V...

With Shift+Page up or Shift+Page down the okatve can be adjusted.
Behind the Note+Okatve the volume is indicated. Valid values here are that 0 to 15 which are given as 0 to F in hexadecimal form.
You can also specify a special effect with parameters (see below).

A line for a channel looks like this:
C-4 2 401
This plays the note C in octave 4 and a volume of 2 and performs a volume slide down with a speed of one (effect 4 with parameter 01).

You can use the cursor keys and Tab to navigate the Pattern Editor. Shift+Insert adds a new empty pattern.
With Enter you enter the Order Editor and can edit the order of the patterns (only already created patterns can be entered). Insert adds a new line to the order list.

Press ESC to enter the menu where you can navigate through the options using the arrow keys.

First you should navigate to the config item and select the correct port for your sound chip under "Output Device".
Hier können zudem die Import-Optionen eingestellt werden:

TNDY Tracker can read the music of Sierra AGI games from the 1980s (SND).
Converting the timing of these SND files to a tracker format is a bit tricky, so you can also set it in Config.
Sierra uses 18 ms delays in ther games. So it would be perfect if playing a row requires 18 ms. This is the case at 55 Hz tempo and a speed of 1.
(1000 / 55) = 18 ms per tick, used with a speed of 1 tick per row makes it the perfect timing.
If you would like to add effects etc. and need more ticks for that, try 110Hz with speed 1 and so on...
Since some players offer an alternative frequency for the sound chip, you can also select it here.

Pattern data can also be imported from Amiga MOD files. For this purpose, settings can also be made, for example, how the fourth channel should be imported.
Since MODs are based on sampling, larger edits are often necessary until they are played back acceptably via a sound chip.

The other menu items should be self-explanatory. Just try them out :)


Pattern Editor:
---------------
Cursor keys        = Move around
PageUp             = Jump 16 rows up
PageDown           = Jump 16 rows down
Home               = Jump to first row
End                = Jump to last row
Backspace          = Delete previous note
Del                = Delete note at cursor
Ins                = Insert space at cursor position
Return             = Edit Order
Shift + Pgup/Pgdwn = Change octave
Shift + Home/End   = Change volume
Shift+Ins          = Add pattern
+/-  (Numpad)      = Edit next / previous pattern
Tab                = Jump to next track
Shift-Tab          = Jump to previous track
Strg+p             = Clear current pattern
Strg+t             = Clear current track
Space              = Play song from current row / Stop/Edit
Shift+Space        = Play current pattern from current row
F1 to F5           = Mute / Unmute channel
ESC                = Menu / Cancel
< or -             = Enter key-off
2, 3, 5, 6...
Q, W, E, R...
S, D, G, H...      = Insert notes (voice channels)
Z, X, C, V...
1,2,3,4            = Insert noise freq. (noise channel)

Pattern Order Editor:
---------------------
Cursor up/down     = Scroll through order list
Cursor left/right  = Select digit of pattern number
Home               = Jump to first entry
End                = Jump to last entry
Tab/Retrun         = Edit Loop position / Return to editor
ESC                = Jump back to the pattern editor
0-9,A-F            = Enter digit (hex) of pattern number
Only already created patterns can be entered!
