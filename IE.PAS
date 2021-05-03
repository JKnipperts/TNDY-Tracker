{$G-,N-,E-}

{**************************************************************
 Import/Export
 - Loading and saving Sierra AGI Music ressources
   and import of Protracker MOD files

 Author: Jan Knipperts
 Program: TNDY-Tracker
 Version: 1.31

***************************************************************
}





Unit IE;
interface
uses global,textmode,keyboard,PIT,tndy,play;

Procedure Import_SND(filename : string);
Procedure Import_MOD(filename : string);

implementation

type

 SNDNote        = record
  Duration      : word;
  Freq1,
  Freq2         : byte;
  Attenuation   : byte;
 end;

 SNDType  	= record
  Offset        : array[0..3] of word;
  Endpos        : array[0..3] of word;
  Note		: SNDNote;
 end;

var
 SND	        : SNDType;
 TND	        : TNDYevent;
 Curr_Speed	: byte;
 Curr_Tempo	: byte;
 Curr_Volume	: byte;
 Curr_pitch     : word;
 Curr_finetune  : byte;
 TNDY_Track     : byte;
 SND_Voice	: byte;
 TS_speed	: byte;
 TS_limit	: word;
 arp	        : arpeggio;
 duration	: word;






Procedure AddRow;
begin
  inc(Player.row);
  if Player.row > 63 then
  begin
    Player.row := 0;
    if Player.Position < 255 then
      inc(Player.Position)
    else
      exit;

    if (Player.Position > Player.MaxPattern) then
    begin
      if maxavail < sizeof(TNDYPattern) then {Out of memory?}
      begin
        close(f);
        error := 5;
        exit;
      end;

     order[Player.Position] := Player.Position;
     if patterns[Player.Position] = nil then new(patterns[Player.Position]);	 { new empty pattern}
     fillchar(patterns[Player.Position]^,sizeof(TNDYPattern),0);
     Player.MaxPattern := Player.Position;
   end;
 end;
end;







Procedure Import_SND(filename : string);
var
   i		: byte;
   empty_rows   : word;
   duration	: word;
   orig_freq,
   note_freq,
   last_nfreq	: word;
   n,o          : byte;
   last_attn    : byte;
   d,nt		: byte;
   c		: word;
   note_active  : array[0..3] of boolean;






begin
  if filename <> '' then
  begin

   writeto(buffer.screen2);
   box(16,7,64,12,palette.text_color1,palette.menu_color,false,true);
   centeredtext(9,palette.text_color1,palette.menu_color,'Converting Sierra AGI game music');
   centeredtext(10,palette.text_color1,palette.menu_color,'Please wait...');
   displaybuffer(buffer.screen2);

   error := 0;
   Clear_Pattern_Data;
   fillchar(player,sizeof(player),0);
   fillchar(editor,sizeof(editor),0);

   assign(f,filename);
   {$I-}
   reset(f,1);
   {$I+}
   if IOResult <> 0 then      {IO Error}
   begin
    error := 1;
    exit;
   end;

   if filesize(f) < sizeof(header) then
   begin
    close(f);
    error := 4;
    exit;
   end;

   {$I-}
   blockread(f,SND.Offset,sizeof(SND.Offset));
   {$I+}

   If IOResult <> 0 then
   begin
    close(f);
    error := 1;
    exit;
   end;

    if (SND.Offset[0] > filesize(f)) or
       (SND.Offset[0] > SND.Offset[1]) or
       (SND.Offset[1] > filesize(f)) or
       (SND.Offset[1] > SND.Offset[2]) or
       (SND.Offset[2] > filesize(f)) or
       (SND.Offset[2] > SND.Offset[3]) or
       (SND.Offset[3] > filesize(f)) then
    begin
      close(f);
      error := 4;
      exit;
    end;

    Player.MaxPattern := 0;


    if patterns[0] = nil then new(patterns[0]);

    SND.Endpos[0] := SND.Offset[1];
    SND.Endpos[1] := SND.Offset[2];
    SND.Endpos[2] := SND.Offset[3];
    SND.Endpos[3] := filesize(f);


    if sndcfg.speed = 0 then 	{Autodectect speed}
    begin
      Player.tempo := 60;
      player.speed := $FF;
      for Editor.chan := 0 to 3 do
      begin
        seek(f,SND.Offset[Editor.chan]);                      {Go to start of track}
        while filepos(f) < SND.Endpos[Editor.chan]-2 do	 {Read complete track}
        begin
          {$I-}
           blockread(f,SND.Note,sizeof(SND.Note));		{Read next note data}
          {$I+}

          If IOResult <> 0 then				{Disk error?}
          begin
            close(f);
            error := 1;  {If an error occured during speed detection then quit}
            exit;
          end;
          if SND.Note.duration < Player.Speed then Player.speed := SND.Note.duration;
        end;
      end;
      if player.speed = $FF then player.speed := 1;
    end
    else
    begin
     {Set timing for AGI Music}
     Player.tempo := SNDcfg.tempo;
     Player.speed := SNDcfg.Speed;
    end;


    note_active[0] := false;
    note_active[1] := false;
    note_active[2] := false;
    note_active[3] := false;


    for Editor.chan := 0 to 3 do
    begin

      seek(f,SND.Offset[Editor.chan]);                      {Go to start of track}

      Player.Position := 0;
      Player.row := 0;
      empty_rows := 1;
      note_freq := 0;
      last_nfreq := 0;

      while filepos(f) < SND.Endpos[Editor.chan]-2 do		{Read complete track.
      							 Endpos-2 is because each voice's data section is usually terminated by two consecutive 0xFF codes}
      begin
        last_attn := SND.Note.Attenuation;                  {save last attenuation value}

        {$I-}
        blockread(f,SND.Note,sizeof(SND.Note));		{Read next note data}
        {$I+}

        If IOResult <> 0 then				{Disk error?}
        begin
         close(f);
         error := 1;
         exit;
        end;


        if Editor.chan < 3 then						{Normal note}
        begin

          orig_freq := tone_to_Freq(SND.Note.Freq1,SND.Note.Freq2); {convert tone value from file to freq. in Hz}
          Freq_to_Note(orig_freq,n,o);			            {Convert it to nearest note value}

          last_nfreq := note_freq;			    {save last used frequency}
          note_freq := Note_to_Freq(n,o);		    {Get exact frequency of this note}


          SND.Note.Attenuation := (SND.Note.Attenuation and not $F0);    {get attenuation nibble}


          if  (note_freq <>  last_nfreq) or {Is there a change in frequency or volume?}
              (SND.note.Attenuation <> last_attn)  then
          begin
            if SND.Note.Attenuation = 15 then
            begin
              n := 0;
              o := 0;
            end;
            patterns[Player.Position]^[Player.row][Editor.chan].note := n;
            patterns[Player.Position]^[Player.row][Editor.chan].Octave := o;
            patterns[Player.Position]^[Player.row][Editor.chan].volume := SND.Note.Attenuation+1;

            if (sndcfg.correct = true) and (n > 0) then
               {Use Finetune effect to correct deviations between the frequencies if enabled}
            begin

              if note_freq > orig_freq+1 then
              begin
                patterns[Player.Position]^[Player.row][Editor.chan].effect := $0A;	{Finetune}
                patterns[Player.Position]^[Player.row][Editor.chan].ep := note_freq-orig_freq;
                if patterns[Player.Position]^[Player.row][Editor.chan].ep > $7F then
                patterns[Player.Position]^[Player.row][Editor.chan].ep := $7F;
              end;

              if note_freq < orig_freq-1 then
              begin
                 patterns[Player.Position]^[Player.row][Editor.chan].effect := $0A;	{Finetune}
                 patterns[Player.Position]^[Player.row][Editor.chan].ep := orig_freq-note_freq;
                 if patterns[Player.Position]^[Player.row][Editor.chan].ep > $7F then
                 patterns[Player.Position]^[Player.row][Editor.chan].ep := $7F;
                 inc(patterns[Player.Position]^[Player.row][Editor.chan].ep,$80);
              end;

            end;
           end;


        end
        else
        begin							{Noise}
          SND.Note.Freq2 := SND.Note.Freq2 and 7; {we are only interested in the lowest three bits}

          d := SND.Note.Freq2 and not 4; {Kill bit 2 and get value for the frequency divider}
          nt := SND.Note.Freq2 shr 2;  {Get bit 2 and the value for feedback / noise type}

          SND.Note.Attenuation := (SND.Note.Attenuation and not $F0);    {get attenuation value}
          patterns[Player.Position]^[Player.row][Editor.chan].volume :=
          SND.Note.Attenuation+1; {we save the volume as 1 to 16 in our pattern...}

          case d of
            0: patterns[Player.Position]^[Player.row][Editor.chan].Octave := 2;  {Periodic noise}
            1: patterns[Player.Position]^[Player.row][Editor.chan].Octave := 1;  {White noise}
          end;

          case nt of
             0 : patterns[Player.Position]^[Player.row][Editor.chan].note := 3;
             1 : patterns[Player.Position]^[Player.row][Editor.chan].note := 2;
             2 : patterns[Player.Position]^[Player.row][Editor.chan].note := 1;
             3 : patterns[Player.Position]^[Player.row][Editor.chan].note := 4;
          end;

          if  patterns[Player.Position]^[Player.row][Editor.chan].note > 0  then
          note_active[Editor.chan] := true;

          if (d = 0) and (nt = 0) and (SND.Note.Attenuation = 0) then
             patterns[Player.Position]^[Player.row][Editor.chan].note := 5;

          if (SND.Note.attenuation = 15) then
          begin
              patterns[Player.Position]^[Player.row][Editor.chan].note := 0;
              patterns[Player.Position]^[Player.row][Editor.chan].octave := 0;
          end;

        end;



        {========== Timing =================}

        {Duration, for agi sounds is defined as 1/60 of a second}

        i := SND.Note.Duration div Player.speed;
        if i > 0 then
        begin
       	  for c := 1 to i  do
          AddRow;
        end;

        if error > 0 then exit; {error?}

     end; {while}


     if sndcfg.mute_at_end then patterns[Player.Position]^[Player.row][Editor.chan].note := 13;

     end; {for}

     close(f);

     fillchar(order,sizeof(order),0);
     for i := 0 to Player.MaxPattern do
     begin
      order[i] := i;
     end;

     Player.Songlength := Player.MaxPattern+1;
     Player.loop := 0;
     Player.Position := 0;
     Player.pattern_num := 0;
     Player.row := 0;
     Editor.chan := 1;

     if Player.speed = 0 then Player.speed := 1; {Just to be save here...}
     if Player.tempo < 18 then Player.tempo := 18;

     set_timer(Player.tempo); {Reset timer to new tepo}
     fillchar(msg_buffer,sizeof(msg_buffer),0);	{There is no title string or other info in AGI files :(}
     msg_size := 0;
     Editor.channels := 4;
     Player.muted[4] := true;

  end
  else
    error := 6; {Aborted by  user}


 end;





Procedure Import_Mod(filename : string);

const
 MOD_Octaves : array[1..60] of word =
     (1712,1616,1525,1440,1357,1281,1209,1141,1077,1017,0961,0907,  {Oct 0}
      0856,0808,0762,0720,0678,0640,0604,0570,0538,0508,0480,0453,
      0428,0404,0381,0360,0339,0320,0302,0285,0269,0254,0240,0226,
      0214,0202,0190,0180,0170,0160,0151,0143,0135,0127,0120,0113,
      0107,0101,0095,0090,0085,0080,0076,0071,0067,0064,0060,0057); {Oct 4}

type
 MOD_Sampleinfo = record
  Samplename	: array[1..22] of char;
  Samplelength	: word;
  finetune	: byte;
  Volume	: byte;
  Rpoint	: word;
  Rlength	: word;
 end;

var modid     : array[1..4] of char;
    p         : modpattern;
    ncount    : byte;
    period    : word;
    v         : real;
    I_volumes : array[1..31] of byte;
    sinfo     : MOD_Sampleinfo;
    snum      : byte;
    c         : byte;
    mod_title : array[1..20] of byte;



function toword(l,h : byte): word;    {Converts Motorola to Intel Byteorder}
assembler;
asm
  mov al,l
  mov ah,h
end;


begin
 if filename <> '' then
 begin
   Clear_Pattern_Data;
   fillchar(player,sizeof(player),0);
   fillchar(editor,sizeof(editor),0);

   writeto(buffer.screen2);
   box(16,7,64,12,palette.text_color1,palette.menu_color,false,true);
   centeredtext(9,palette.text_color1,palette.menu_color,'Converting Amiga Module');
   centeredtext(10,palette.text_color1,palette.menu_color,'Please wait...');
   displaybuffer(buffer.screen2);

   error := 0;

   assign(f,filename);
   {$I-}
   reset(f,1);
   {$I+}
     if IOResult <> 0 then      {IO Error}
     begin
      error := 1;
      exit;
     end;

   if filesize(f) < (1086+sizeof(MODPattern)) then
   begin
    close(f);
    error := 3;
    exit;
   end;


   seek(f,1080);
   blockread(f,Modid,4);

   if (modid <> 'M.K.') and (modid <> '4CHN') then
   begin
    close(f);
    error := 3;
    exit;
   end;


   {What to do with the 4th Editor.channel?}
   case MODcfg.ch4 of
    1: begin		{import as noise Editor.channel}
        Editor.channels := 4;
        c := 3;
       end;
    2: begin		{import as PC Speaker Editor.channel}
        Editor.channels := 5;
        c := 3;
       end;
    3: begin		{don't import it}
        Editor.channels := 4;
        c := 2;
       end;
   end;




   fillchar(mod_title,20,0);
   seek(f,0);		{Back to the beginning}
   blockread(f,mod_title,20); {Read title}


   fillchar(msg_buffer,sizeof(msg_buffer),0);
   msg_size := 0;

   for ncount := 1 to 20 do
   begin
    if mod_title[ncount] > 0 then
    begin
     msg_buffer[ncount] := mod_title[ncount];
     inc(msg_size);
    end;
   end;


   seek(f,20);		{Back to the sample infos}

   fillchar(I_volumes, sizeof(I_volumes),0);
   for ncount := 1 to 31 do                      {Proceed Sample infos}
   begin
    blockread(f,sinfo,sizeof(sinfo));
    I_volumes[ncount] := sinfo.volume;           {get instrument volume}
   end;



   seek(f,950);
   blockread(f,Player.Songlength,1);
   if Player.Songlength = 0 then Player.Songlength := 1;

   blockread(f,Player.loop,1);
   if Player.loop = $7F then Player.loop := 0;

   blockread(f,order,128);

   for i := 0 to 127 do
   if order[i] > Player.MaxPattern then Player.MaxPattern := order[i];  {determine number of patterns}

   if maxavail < ((Player.MaxPattern+1)*sizeof(TNDYPattern)) then {Out of memory?}
   begin
     close(f);
     error := 5;
     exit;
   end;


  seek(f,1084);  {Skip ID}

  for Player.Position := 0 to Player.MaxPattern do
  begin

    fillchar(p,sizeof(modpattern),0);
    {$I-}
     blockread(f,p,64*16);
    {$I+}

    if IOResult <> 0 then      {IO Error}
    begin
      error := 1;
      close(f);
      exit;
     end;


    if patterns[Player.Position] = nil then new(patterns[Player.Position]);
    fillchar(patterns[Player.Position]^,sizeof(TNDYPattern),0);

    for Player.row := 0 to 63 do
    begin

     for Editor.chan := 0 to c do
     begin
      period   := toword(p[Player.row][4*Editor.chan+1],(p[Player.row][4*Editor.chan+0] and $0F));      {sample period}
      patterns[Player.Position]^[Player.row][Editor.chan].effect :=
      p[Player.row][4*Editor.chan+2] and $0F;         {effect number}
      patterns[Player.Position]^[Player.row][Editor.chan].ep     :=
      p[Player.row][4*Editor.chan+3];                 {effect argument}
      snum     := (p[Player.row][4*Editor.chan+0] and $F0)+p[Player.row][4*Editor.chan+2] shr 4;  	    {sample number}

      if snum in [1..31] then
      begin
         if MODcfg.volscale = 1 then
         begin
          case I_volumes[snum] of				{direct scaling}
              61..64: patterns[Player.Position]^[Player.row][Editor.chan].volume := 0;
              57..60: patterns[Player.Position]^[Player.row][Editor.chan].volume := 1;
              53..56: patterns[Player.Position]^[Player.row][Editor.chan].volume := 2;
              49..52: patterns[Player.Position]^[Player.row][Editor.chan].volume := 3;
              45..48: patterns[Player.Position]^[Player.row][Editor.chan].volume := 4;
              41..44: patterns[Player.Position]^[Player.row][Editor.chan].volume := 5;
              37..40: patterns[Player.Position]^[Player.row][Editor.chan].volume := 6;
              33..36: patterns[Player.Position]^[Player.row][Editor.chan].volume := 7;
              29..32: patterns[Player.Position]^[Player.row][Editor.chan].volume := 8;
              25..28: patterns[Player.Position]^[Player.row][Editor.chan].volume := 9;
              21..24: patterns[Player.Position]^[Player.row][Editor.chan].volume := 10;
              17..20: patterns[Player.Position]^[Player.row][Editor.chan].volume := 11;
              13..16: patterns[Player.Position]^[Player.row][Editor.chan].volume := 12;
              09..12: patterns[Player.Position]^[Player.row][Editor.chan].volume := 13;
              01..08: patterns[Player.Position]^[Player.row][Editor.chan].volume := 14;
                   0: patterns[Player.Position]^[Player.row][Editor.chan].volume := 15;
          end;
         end
         else
         begin
          case I_volumes[snum] of				{scale by db value}
            52..64: patterns[Player.Position]^[Player.row][Editor.chan].volume := 0;   {0..-2 db = full volume}
            40..51: patterns[Player.Position]^[Player.row][Editor.chan].volume := 1;   {-2..-4 db = -2 db on Tandy}
            26..40: patterns[Player.Position]^[Player.row][Editor.chan].volume := 2;   {-4..-8 db = -4 db}
            10..25: patterns[Player.Position]^[Player.row][Editor.chan].volume := 4;   {-8..-16 db = - 8db}
             1..10: patterns[Player.Position]^[Player.row][Editor.chan].volume := 8;   {-16..-36 db = -16 db}
                 0: patterns[Player.Position]^[Player.row][Editor.chan].volume := 15;  {0 (minus inf.) = mute}
       	  end;
       	 end;

        inc(patterns[Player.Position]^[Player.row][Editor.chan].volume); {we store it 1 to 16}
      end;


      case patterns[Player.Position]^[Player.row][Editor.chan].effect of

        4,6,7,8,9,$D:     {not supported MOD effects}
        begin
         patterns[Player.Position]^[Player.row][Editor.chan].effect := 0;
         patterns[Player.Position]^[Player.row][Editor.chan].ep := 0;
        end;

        $5:
        begin
         patterns[Player.Position]^[Player.row][Editor.chan].effect := 5;
         {patterns[Player.Position]^[Player.row][Editor.chan].ep := 1;}

        end;


        $A:
        begin
         patterns[Player.Position]^[Player.row][Editor.chan].effect := 4;
         {patterns[Player.Position]^[Player.row][Editor.chan].ep := 1;}
        end;


        $C:
        begin

         if MODcfg.volscale = 1 then
         begin
          case patterns[Player.Position]^[Player.row][Editor.chan].ep of				{direct scaling}
              61..64: patterns[Player.Position]^[Player.row][Editor.chan].volume := 0;
              57..60: patterns[Player.Position]^[Player.row][Editor.chan].volume := 1;
              53..56: patterns[Player.Position]^[Player.row][Editor.chan].volume := 2;
              49..52: patterns[Player.Position]^[Player.row][Editor.chan].volume := 3;
              45..48: patterns[Player.Position]^[Player.row][Editor.chan].volume := 4;
              41..44: patterns[Player.Position]^[Player.row][Editor.chan].volume := 5;
              37..40: patterns[Player.Position]^[Player.row][Editor.chan].volume := 6;
              33..36: patterns[Player.Position]^[Player.row][Editor.chan].volume := 7;
              29..32: patterns[Player.Position]^[Player.row][Editor.chan].volume := 8;
              25..28: patterns[Player.Position]^[Player.row][Editor.chan].volume := 9;
              21..24: patterns[Player.Position]^[Player.row][Editor.chan].volume := 10;
              17..20: patterns[Player.Position]^[Player.row][Editor.chan].volume := 11;
              13..16: patterns[Player.Position]^[Player.row][Editor.chan].volume := 12;
              09..12: patterns[Player.Position]^[Player.row][Editor.chan].volume := 13;
              01..08: patterns[Player.Position]^[Player.row][Editor.chan].volume := 14;
                   0: patterns[Player.Position]^[Player.row][Editor.chan].volume := 15;
          end;
         end
         else
         begin
          case patterns[Player.Position]^[Player.row][Editor.chan].ep of				{scale by db value}
            52..64: patterns[Player.Position]^[Player.row][Editor.chan].volume := 0;   {0..-2 db = full volume}
            40..51: patterns[Player.Position]^[Player.row][Editor.chan].volume := 1;   {-2..-4 db = -2 db on Tandy}
            26..40: patterns[Player.Position]^[Player.row][Editor.chan].volume := 2;   {-4..-8 db = -4 db}
            10..25: patterns[Player.Position]^[Player.row][Editor.chan].volume := 4;   {-8..-16 db = - 8db}
             1..10: patterns[Player.Position]^[Player.row][Editor.chan].volume := 8;   {-16..-36 db = -16 db}
                 0: patterns[Player.Position]^[Player.row][Editor.chan].volume := 15;  {0 (minus inf.) = mute}
       	  end;
       	 end;

         patterns[Player.Position]^[Player.row][Editor.chan].ep := 0;
         patterns[Player.Position]^[Player.row][Editor.chan].effect := 0;
         inc(patterns[Player.Position]^[Player.row][Editor.chan].volume); {we store it 1 to 16}
        end;

        $E:
        begin
         case (patterns[Player.Position]^[Player.row][Editor.chan].ep shr 4) of
         1:
         begin
          patterns[Player.Position]^[Player.row][Editor.chan].effect := $A;
          patterns[Player.Position]^[Player.row][Editor.chan].ep :=
          $80+(patterns[Player.Position]^[Player.row][Editor.chan].ep shr 4);
         end;
         2:
         if (patterns[Player.Position]^[Player.row][Editor.chan].ep) in [2,5] then
         begin
          patterns[Player.Position]^[Player.row][Editor.chan].effect := $A;
          patterns[Player.Position]^[Player.row][Editor.chan].ep :=
          (patterns[Player.Position]^[Player.row][Editor.chan].ep and $0F);
         end;
        else
        begin
          patterns[Player.Position]^[Player.row][Editor.chan].effect := 0;
          patterns[Player.Position]^[Player.row][Editor.chan].ep := 0;
        end;

        end;
      end;

    end;
      ncount := 1;

      if period = 0 then
      begin
        ncount := 61;
        patterns[Player.Position]^[Player.row][Editor.chan].Octave := 0;
      end;

      while (NCount <= 60) do
      begin
       If (period = MOD_Octaves[NCount]) then
       begin
         dec(Ncount);
         patterns[Player.Position]^[Player.row][Editor.chan].Octave := (NCount div 12)+1;
         patterns[Player.Position]^[Player.row][Editor.chan].note   := (NCount-(NCount DIV 12)*12)+1;

         {Lowest possible tandy note is A-2...}
         if (Editor.chan < 3) then {except for pc speaker or noise...}
         begin
          if patterns[Player.Position]^[Player.row][Editor.chan].Octave < 2 then
          patterns[Player.Position]^[Player.row][Editor.chan].Octave := 2;
          if (patterns[Player.Position]^[Player.row][Editor.chan].Octave = 2) and
          (patterns[Player.Position]^[Player.row][Editor.chan].note > 10) then
          patterns[Player.Position]^[Player.row][Editor.chan].note := 10;
         end;


         NCount := 61;
       end;
       inc(Ncount);
      end;

     end; {chan}
    end; {row}
  end;  {position}

 close(f);

 Player.row := 0;
 Player.Position := 0;
 Player.pattern_num := 0;
 Editor.chan := 1;



 Player.Speed := MODcfg.Speed;	 {Set timing for AMIGA Mods}
 Player.tempo := MODcfg.tempo;
 if Player.speed = 0 then Player.speed := 1; {Just to be save here...}
 if Player.tempo < 18 then Player.tempo := 18;
 set_timer(Player.tempo); {Reset timer to new tempo}

 if Editor.channels = 5 then
 begin
  Player.muted[4] := false;
 end
 else
 begin
  Player.muted[4] := true;
 end;

 end {no filename}
 else
    error := 6; {Aborted by  user}
end;









end.


