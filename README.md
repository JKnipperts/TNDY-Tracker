# TNDY-Tracker
A complete sound tracker for the Tandy 3-voice sound (TI SN76496A or compatible sound generator chip).
Should work well on real old Tandy 1000 or PCjr hardware (A memory expansion is needed here!) and is great to use with
new retro-hardware projects like Matze79's TNDY or Serdaco's TNDLPT sound devices. 

The tracker was written in old Borland Pascal 7.0, but with just a few modifications it should compile with Freepascal as well.

![Alt text](https://github.com/JKnipperts/TNDY-Tracker/blob/master/Images/TNDY_playing_ptn.png?raw=true "TNDY Tracker playing")

![Alt text](https://github.com/JKnipperts/TNDY-Tracker/blob/master/Images/TNDY_playing.png?raw=true "TNDY Tracker alternative player screen")

## Some of the features:
- Import of the Tandy/PCjr music from Sierra AGI (AGIv2 and AGIv3) games (Kings Quest etc.)
- Import of Amiga MOD pattern data
- Option to use the PC Speaker as additional voice 
- Supports typical "tracker effects" like portamento, volume slide, tone slide, arpeggio etc.
- Own, space-saving file format
- Supports various IO port settings, even parallel port, to support new hardware projects with this sound chip
- Complete and easy-to-use player code included (100% assembler)

I plan to support MIDI and VGM file formats in the future. 

This project is actively developed by me and therefore I will update the source code here regularly.
So it's worth checking back here from time to time.

## The latest version / program update:
The last comprehensive release with demo songs, player code etc. was the v.1.21 release on 05 May 2021.
The latest program version is 1.21a which fixes some small bugs and typos that were reported to me after the release of version 1.21 but otherwise contains no changes or new features.

## Player code:
PLAYER.ASM contains all code to play a TND file. The use is very simple: Just include PLAYER.ASM in your program, 
load a TND file at ES:00 and call TND_Init_Player.
Now everything is ready for playback and with calls of TND_Start and TND_Stop the playback can be started or stopped.
TNDTEST.ASM and TNDPLAY.ASM are examples of the use of the player code. They also show how the current player status 
can be queried or how I/O ports can be selected.

