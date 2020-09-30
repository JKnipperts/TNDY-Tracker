{$G-,N-,E-}

Program PlaySND;
uses dos,tndy,pit,keyboard,textmode;

const
 title  : string = 'Sierra SND file player v1.1 by Jan Knipperts';
 title2 : string = 'Plays Sierra AGI game music on Tandy Soundcards';


 SNDRATE = 70;  {Timer rate in Hz}



type

 SNDHeader = record
   Offset        : array[0..3] of word;
 end;

 SNDNote    = record
   Duration      : word;
   Freq1, Freq2  : byte;
   Attenuation   : byte;
 end;

 var
   f            : file;
   Header       : SNDHeader;
   Channel      : array[0..3] of SNDNote;
   Posi         : array[0..3] of word;
   Endpos       : array[0..3] of word;
   Ended        : array[0..3] of boolean;
   i,i1         : byte;

   x,y		: byte;

   OldExitProc  : Pointer;

   oldint08     : Procedure;
   Tick         : byte;
   clock_tick	: real;
   OldTick      : byte;
   rate		: word;




 Function UpperCase(low : string) : string;
 var up : string;
    sz  : byte;
 begin
   up := '';
   for sz := 1 to length(low) do
   begin
     up := up+upcase(low[sz]);
   end;
   UpperCase := up;
 end;


 Function FindOption(paranr : byte; lookup : string) : boolean;
 var
    s   : string;
 begin
    FindOption := false;

    if length(paramstr(paranr)) > length(lookup) then
      s := copy(uppercase(paramstr(paranr)),1,length(lookup))
    else
      s := uppercase(paramstr(paranr));

    if pos(s,uppercase(lookup)) > 0 then
    begin
      FindOption := true;
    end;
 end;


 Function Tone_to_Freq(noteHi, noteLo : byte) : word;
 var frequency : word;
 begin
   frequency := ((noteHI and $3F) shl 4) + (noteLo and $0F);
   if noteHi = 0 then
    Tone_to_Freq := 0
   else
    Tone_to_Freq := round(99320 / frequency); {Alternative: 111860}
 end;



 Procedure TNDYint; interrupt;
 begin

  inc(tick);

  if clock_tick > 0 then
  begin
  asm
    cli
    mov al,20h
    out 20h,al
  end;
  end
  else
  begin
    asm
     pushf
    end;
    oldint08;
  end;

  clock_tick := clock_tick+Timer.Clock_Counter;
  If (clock_tick >= 1) then clock_tick := 0;

 end;


 Procedure init_irq;
 begin
  GetIntVec($08,@oldint08);
  set_timer(sndrate); {Reset timer to new frequency}
  rate := sndrate;
  SetIntVec($08,@TNDYint);
 end;


 Procedure done_irq;
 begin
  SetIntVec($08,@oldint08);
  Resettimer;		{Reset timer to its default state (18.2 Hz)}
 end;

 procedure Save_Exit; Far;
 begin
  done_irq;			{Set original interrupt}
  Tandy_Mute_All;	        {Mute all sound output}
  cursor(true);		        {display cursor}
  ExitProc := OldExitProc;	{And now run the original exit proc}
 end;






 begin
   clrscr;
   writeln(title);
   writeln(title2);
   writeln('');

   if (paramcount = 0) or (paramcount > 2) then
   begin
    writeln('Syntax is SNDPLAY.EXE <FILE.SND> <PORT>');
    writeln('Valid ports are C0, E0, 1E0, 205, 2C0 (for TNDY)');
    writeln('or LPT1,LPT2,LPT3 (for TNDLPT)');
    writeln('If no port is specified, C0 is used.');
    writeln('');
    halt(1);
   end;

   TLPT.LPT := false;

  if (paramcount = 2) then
  begin
   if findoption(2,'0C0') or findoption(2,'C0') then Tandy.IOPort := $0C0;
   if findoption(2,'0E0') or findoption(2,'E0') then TANDY.IOPort := $0C0;
   if findoption(2,'1E0') then TANDY.IOPort := $1E0;
   if findoption(2,'205') then TANDY.IOPort := $205;
   if findoption(2,'2C0') then TANDY.IOPort := $2C0;

   if findoption(2,'LPT1') then
   begin
     if not TLPT_Init(1) then
     begin
      writeln('ERROR: Parallel port LPT1 does not respond.');
      writeln('');
      halt(1);
     end;
   end;
   if findoption(2,'LPT2') then
   begin
     if not TLPT_Init(2) then
     begin
      writeln('ERROR: Parallel port LPT2 does not respond.');
      writeln('');
      halt(1);
     end;
   end;
   if findoption(2,'LPT3') then
   begin
     if not TLPT_Init(3) then
     begin
      writeln('ERROR: Parallel port LPT3 does not respond.');
      writeln('');
      halt(1);
     end;
   end;


  end
  else
   TANDY.IOPort := $0C0;

   TANDY_Mute_All;

   assign(f,paramstr(1));
   {$I-}
   reset(f,1);
   {$I+}

    If IOResult <> 0 then
    begin
     writeln('File not found!');
     writeln('');
     halt(1);
    end;

    if filesize(f) < sizeof(header) then
    begin
     writeln('File is corrupted or no Sierra AGI game music!');
     writeln('');
     halt(1);
    end;

    {$I-}
    blockread(f,Header,sizeof(Header));
    {$I+}

    If IOResult <> 0 then
    begin
     writeln('Disk read error!');
     writeln('');
     halt(1);
    end;

    Posi[0] := Header.Offset[0];
    Posi[1] := Header.Offset[1];
    Posi[2] := Header.Offset[2];
    Posi[3] := Header.Offset[3];
    Endpos[0] := Posi[1];
    Endpos[1] := Posi[2];
    Endpos[2] := Posi[3];
    Endpos[3] := filesize(f);
    Ended[0] := false;
    Ended[1] := false;
    Ended[2] := false;
    Ended[3] := false;

    if (posi[0] > filesize(f)) or
       (posi[1] > filesize(f)) or
       (posi[2] > filesize(f)) or
       (posi[3] > filesize(f)) then
    begin
     writeln('File is corrupted or no Sierra AGI game music!');
     writeln('');
     halt(1);
    end;

   while is_key_pressed do get_key;
   init_irq;
   OldExitProc := ExitProc; {Save the old and install the}
   ExitProc := @Save_Exit;  {new exit procedure}
   write('Playing '+uppercase(paramstr(1))+' on port ');
   if TLPT.lpt then
    writeln('LPT'+hexn(TANDY.IOPort))
   else
    writeln(hexw(TANDY.IOPort)+'h');

   writeln('Press +/- to adjust speed or ESC to quit');

   y := GetY;
   writeln('Timer: '+addspace(100,rate)+' Hz');
   cursor(false);
   repeat;


    for i := 0 to 3 do
    begin

      if posi[i] < Endpos[i]-2 then
      begin

        if Channel[i].Duration = 0 then
        begin

          seek(f,Posi[i]);
          {$I-}
           blockread(f,Channel[i],sizeof(SNDNote));
          {$I+}
          If IOResult <> 0 then
          begin
            writeln('Disk read error!');
            writeln('');
            halt(1);
          end;

          Posi[i] := filepos(f);

          Channel[i].Attenuation := Channel[i].Attenuation and not $F0; { shr 4; {get high nibble}

          if i < 3 then
          begin
            TANDY_PlaySound(i,Tone_to_Freq(Channel[i].Freq1,Channel[i].Freq2),Channel[i].Attenuation);
          end
         else
          begin
            {Bits 0 and 1 hold the freq. divider, bit 2 is the noise type (1 = white noise, 0 = periodic noise)}
            TANDY_Noise(Channel[i].Freq2 or $FC,Channel[i].Freq2 shr 2, Channel[i].Attenuation)
          end;

          gotoxy(1,y+2+i);
          writeln(' Channel'+addspace(10,i)+': '+addspace(10000,Tandy.freq[i])+
                  ' Hz, Attenuation: '+addspace(10,Channel[i].Attenuation)+
                  ', Duration: '+addspace(10000,Channel[i].duration)+' ticks');


        end;  {Duration = 0}



      end {Posi < Endpos}
      else
      begin
       Ended[i] := true;
       TANDY_MuteVoice(i);
      end;


     tick := 0;

     while tick < 1 do    {wait one tick}
     begin
     end;


     for i1 := 0 to 3 do   {Update duration values}
     begin
       if Channel[i1].Duration > 0 then dec(Channel[i1].Duration);
     end;

   end;



    if is_key_pressed then
    begin
      Get_Key;

      if key_code = 78 then {+}
      begin
        if rate < 224 then
        begin
         inc(rate);
         set_timer(rate); {Reset timer to new frequency}
         gotoxy(1,y);
         writeln('Timer: '+addspace(100,rate)+' Hz');
        end;
        Clear_keypress;
      end;

      if key_code = 74 then {-}
      begin
        if rate > 18 then
        begin
         dec(rate);
         set_timer(rate); {Reset timer to new frequency}
         gotoxy(1,y);
         writeln('Timer: '+addspace(100,rate)+' Hz');
        end;
        Clear_keypress;
      end;

      if key_code = 1 then {ESC}
      begin
       gotoxy(1,y+6);
       writeln('');
       Clear_keypress;
       close(f);
       TANDY_Mute_all;
       halt(0);
      end;
    end;





    until ((Ended[0] = true) and (Ended[1] = true) and (Ended[2] = true) and (Ended[3] = true));
    gotoxy(1,y+6);
    writeln('');
    writeln('Song ended');
    writeln('');
    close(f);
    TANDY_Mute_all;
 end.


