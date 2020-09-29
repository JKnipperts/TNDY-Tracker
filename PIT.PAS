{$G-,N-,E-}

{**************************************************************
 PIT.pas - Handle the PIT (Programmable Interval Time)

 Author: Jan Knipperts
 Program: TNDY-Tracker
 Version: 1.11

***************************************************************
}



unit PIT;
interface


type
 TimerType = record
  Frequency     : Real;
  Divider       : word;
  Clock_counter : Real;
end;

var
 Timer	: TimerType;


procedure Set_Timer(Hz : Real);
procedure ResetTimer;
Procedure Program_PIT(mode : byte; countdown : word);
procedure DisableTimerIRQ;
procedure EnableTimerIRQ;




implementation


procedure DisableTimerIRQ;
assembler;
asm
  in  al,21h
  or  al,1
  out 21h,al
end;

procedure EnableTimerIRQ;
assembler;
asm
 in   al,21h
 and  al,0feh
 out  21h,al
end;

Procedure Program_PIT(mode : byte; countdown : word);
{Mode:
 Bit 0   :  Counter Format bit (0 = binary counter, 1 decade BCD counter)
 Bit 1-3 :  Counter Mode bits
 Bit 4,5 :  read/write/latch format bits
 Bit 6,7 :  Counter Select Bits

 Default: 36h, 00110110
 bit 7,6 = (00) timer counter 0
 bit 5,4 = (11) write LSB then MSB
 bit 3-1 = (011) generate square wave
 bit 0 = (0) binary counter


 Counter Select Bits
 00  select counter 0
 01  select counter 1
 10  select counter 2
 11  read back command (8254 only, illegal on 8253!)

 Read/Write/Latch Format Bits
 00  latch present counter value
 01  read/write of MSB only
 10  read/write of LSB only
 11  read/write LSB, followed by write of MSB

 Counter Mode Bits
 000  mode 0, interrupt on terminal count;  countdown, interrupt,
      then wait for a new mode or count; loading a new count in the
      middle of a count stops the countdown

 001  mode 1, programmable one-shot; countdown with optional
      restart; reloading the counter will not affect the countdown
      until after the following trigger

 010  mode 2, rate generator; generate one pulse after 'count' CLK
      cycles; output remains high until after the new countdown has
      begun; reloading the count mid-period does not take affect
      until after the period

 011  mode 3, square wave rate generator; generate one pulse after
     'count' CLK cycles; output remains high until 1/2 of the next
      countdown; it does this by decrementing by 2 until zero, at
      which time it lowers the output signal, reloads the counter
      and counts down again until interrupting at 0; reloading the
      count mid-period does not take affect until after the period

 100  mode 4, software triggered strobe; countdown with output high
      until counter zero;  at zero output goes low for one CLK
      period;  countdown is triggered by loading counter;  reloading
      counter takes effect on next CLK pulse

 101  mode 5, hardware triggered strobe; countdown after triggering
      with output high until counter zero; at zero output goes low
      for one CLK period }

assembler;
asm
  cli
  mov al,mode
  out 43h,al
  mov ax,countdown
  out 40h,al
  mov al,ah
  out 40h,al
  sti
end;


procedure ResetTimer;
begin
 Program_PIT($36,0);
end;




procedure set_timer(Hz  : Real);
begin
  If (Hz < 19) then Hz := 19;
  If (Hz > 1193180) then Hz := 1193180;
  Timer.Frequency  := Hz;

  DisableTimerIRQ;

  if Hz > 32 then
   Timer.divider := round(1193180 / Hz)
  else
   Timer.divider := ($0ffff div Round(Hz/18.2));

  Program_PIT($34,Timer.divider);
  EnableTimerIRQ;

  Timer.Clock_Counter := round(Timer.Frequency / 18.2065);
end;




end.



