{$G-,N-,E-}
{*******************************************************
 Textmode
 Useful procedures and functions for fast drawing and
 buffering in 80x25 text mode
 Version 2.1 - 22.02.2021
 Author: Jan Knipperts
 *******************************************************

 - Added compiler directives for compiling with TNDY Tracker
 - Removed limits to be able to write outside the visible area
 - Improved buffering
 - Improved speed
  (mit rep anweisung statt loop probieren!}




Unit Textmode;


interface
uses dos;

Function  Detect_VidSeg : word;

Function  Attr(fg,bg : byte; blink : boolean) : byte;
Function  AttrMDA(underline,blink,bright : boolean) : Byte;
Procedure ChangeAttr(x,y,atrib : byte);

Procedure ChangeAttrVLine(x,y,l,atrib : byte);
Procedure ChangeAttrHLine(x,y,l,atrib : byte);
Procedure ChangeAttrBlock(x,y,x1,y1,atrib : byte);

Procedure ChangeChar(x,y,ch : byte);
Procedure Cursor(onoff : boolean);
Procedure Change_Cursor(start_line,bottom_line : byte);


Procedure FillMem(c : char; attr : byte; startoffset, count : word);
Procedure Box(xp,yp,xp1,yp1 : word; foreground, background : byte; slim : boolean; shadow : boolean);
Procedure Block(x,y,x1,y1,fg,bg : byte);
Procedure HLine(x,y,l,foreground,background : byte; c : char);
Procedure VLine(x,y,l,foreground,background : byte; c : char);


Procedure SetBorder(Color : Word);
Procedure InitMenuScreen(title : string; fc, bc : byte);
Procedure Centeredline(y,c,b : byte; title : string);
Procedure PutChar(x,y, fg, bg : byte; ch: Char);
Function  GetChar(x,y: Byte): Char;
Function  GetTextColor(x,y: Byte): Byte;
Function  GetTextBackground(x,y: Byte): Byte;
Procedure Fastwrite(x,y,fg, bg : byte; s : string);
Procedure FastWriteNum(x, y, f, b: byte; num : longint);
Procedure CenteredText(y,c,b : byte; s : string);
Function  GetX : byte;
Function  GetY : byte;
Procedure GotoXy(x,y : byte);
Procedure Scrollup(lines,x,y,x1,y1 : byte);
Procedure Scrolldown(lines,x,y,x1,y1 : byte);
Procedure Write(s : string);
Procedure Writeln(s : string);
Procedure Textcolor(c : byte);
Procedure Textbackground(c : byte);
Procedure ClrScr;
Procedure ScreenFill(c : char; attr : byte);
Procedure SetWritePage(p : byte);
Procedure SetViewPage(p : byte);
Function  Mouse_detected : boolean;
Function  Mouse_Init : Boolean;
Procedure Mouse_SetHLimits(xmin, xmax : Word);
Procedure Mouse_SetVLimits(ymin, ymax : Word);
Procedure Mouse_Show;
Procedure Mouse_Hide;
Procedure Mouse_Read;
Procedure Mouse_SetPos(x, y : Byte);
Procedure ShadowScreen;


Procedure CopyBuffer(source,dest : pointer);
Procedure SwapBuffers(var buffer1,buffer2 : pointer);
Procedure DisplayBuffer(p : pointer);
Function  GetDisplayBuffer : pointer;
Procedure Writeto(p : pointer);
Function  GetWriteBuffer : pointer;
Procedure ChangeVSeg(seg : word);


function hex2dec(h:string) : byte;
Function hexn(h:byte):string;
function hexb(h:byte):string;
function hexw(h:word):string;
function addspace (base, b : word) : string;
function addzero (base, b : word) : string;
Function UpperCase(low : string) : string;

type
  mousedata     = record
   nb,b         : byte;
   x,y          : word;
   mouse_there  : boolean;
  end;

  screendata    = record
  maxX,
  maxY,
  page,
  tc,
  tbc           : byte;
  vidseg        : word;
  end;


var
 mouse          : mousedata;
 txtscreen	: screendata;


implementation
var
 ocs,oce        : byte;
 writebuffer,
 viewbuffer     : pointer;
 mi             : pointer;



Function Detect_VidSeg : word;
begin
 if Mem[$0000:$0449] = 7 then
    Detect_VidSeg := $B000
 else
    Detect_VidSeg := $B800;
end;

Function Attr(fg,bg : byte; blink : boolean) :byte;
var a : byte;
begin
 if txtscreen.VidSeg = $B800 then {Color display}
 begin
  a := fg or (bg shl 4);
  if not blink then a := a and not $80;
 end
 else   {Monochrome}
 begin
   a := AttrMDA(false,blink,false);
 end;
 attr := a;
end;


Function AttrMDA(underline,blink,bright : boolean) : Byte; {enhanced Attr function for monochrome display}
var a : byte;
begin
   a := 7;  {"Normal" setting for MDA = 00000111b}
   if underline then a := 0; {Clear bits 2-0}
   if bright then a := a or $8; {set bit 3}
   if blink then a := a or $80; {set bit 7 for blink}
   AttrMDA := a;
end;



Procedure ChangeAttr(x,y,atrib : byte);
assembler;
 asm
   push es
   push si
   push di

   lea si,writebuffer
   mov es,[ds:si+2]
   mov di,[ds:si]

   xor ah,ah
   xor bh,bh
   mov al,y
   dec al
   mov bl,txtscreen.maxX
   mul bl
   mov bl,x
   dec bl
   add ax,bx
   shl ax,1
   inc ax
   add di,ax


   mov al,atrib
   mov [es:di],al

   pop di
   pop si
   pop es
 end;




Procedure ChangeAttrHLine(x,y,l,atrib : byte);
assembler;
 asm
   push es
   push si
   push di

   lea si,writebuffer
   mov es,[ds:si+2]
   mov di,[ds:si]

   xor ah,ah		{calculate start offset}
   xor bh,bh
   mov al,y
   dec al
   mov bl,txtscreen.maxX
   mul bl
   mov bl,x
   dec bl
   add ax,bx
   shl ax,1
   inc ax
   add di,ax

   mov al,atrib

   mov cl,l
   xor ch,ch

   cld

 @XLoop:
   stosb
   inc di
 loop @XLoop

   pop di
   pop si
   pop es
 end;

Procedure ChangeAttrVLine(x,y,l,atrib : byte);
assembler;
 asm
   push es
   push si
   push di

   lea si,writebuffer
   mov es,[ds:si+2]
   mov di,[ds:si]

   xor ah,ah		{calculate start offset}
   xor bh,bh
   mov al,y
   dec al
   mov bl,txtscreen.maxX
   mul bl
   mov bl,x
   dec bl
   add ax,bx
   shl ax,1
   inc ax
   add di,ax

   mov al,txtscreen.maxX
   mov bl,2
   mul bl
   mov bx,ax



   mov al,atrib
   mov cl,l
   xor ch,ch

   cld

 @YLoop:
   stosb
   add di,bx
   dec di
 loop @YLoop

   pop di
   pop si
   pop es
 end;

Procedure ChangeAttrBlock(x,y,x1,y1,atrib : byte);
var yc : byte;
begin
  for yc := y to y1 do
    ChangeAttrHLine(x,yc,(x1-x),atrib);
end;



Procedure ChangeChar(x,y,ch : byte);
assembler;
 asm
   push es
   push si
   push di

   lea si,writebuffer
   mov es,[ds:si+2]
   mov di,[ds:si]

   xor ah,ah
   xor bh,bh
   mov al,y
   dec al
   mov bl,txtscreen.maxX
   mul bl
   mov bl,x
   dec bl
   add ax,bx
   shl ax,1
   add di,ax


   mov al,ch
   mov [es:di],al

   pop di
   pop si
   pop es
 end;





Procedure PutChar(x,y, fg, bg : byte; ch: Char);
begin
  if x > 0 then x := x-1;
  if y > 0 then y := y-1;
  mem[seg(writebuffer^):ofs(writebuffer^)+((y*txtscreen.maxX)+x) shl 1] := ord(ch);
  mem[seg(writebuffer^):ofs(writebuffer^)+(((y*txtscreen.maxX)+x) shl 1)+1] := Attr(fg,bg,false);
end;

Function GetChar(x,y: Byte): Char;
begin
  if x > 0 then x := x-1;
  if y > 0 then y := y-1;
  GetChar:=Char(mem[seg(writebuffer^):ofs(writebuffer^)+((y*txtscreen.maxX)+x) shl 1]);
end;

Function GetTextColor(x,y: Byte): Byte;
begin
  if x > 0 then x := x-1;
  if y > 0 then y := y-1;

  GetTextColor:=mem[seg(writebuffer^):ofs(writebuffer^)+(((y*txtscreen.maxX)+x) shl 1)+1] and $f;
end;

Function GetTextBackground(x,y: Byte): Byte;
begin
  if x > 0 then x := x-1;
  if y > 0 then y := y-1;

  GetTextBackground:=mem[seg(writebuffer^):ofs(writebuffer^)+(((y*txtscreen.maxX)+x) shl 1)+1] or $f;
end;

Procedure Cursor(onoff : boolean);
assembler;
asm
 cmp onoff,true
 je @on

 mov ah,3    {save old cursor shape}
 mov bh,0
 int 10h
 mov ocs,ch
 mov oce,cl

 mov ah,1       {Disable cursor}
 mov ch,32
 mov cl,7
 int 10h
 jmp @exit


 @on:
  mov ah,1       {Restore last cursor shape}
  mov ch,ocs
  mov cl,oce
  int 10h
  jmp @exit

@EXIT:
end;


Procedure Change_Cursor(start_line,bottom_line : byte);
assembler;
asm          {0,7 shows box-shaped text cursor}
 mov ch,start_line
 mov cl,bottom_line
 mov ah,1
 int 10h
end;

Procedure Fastwrite(x,y,fg, bg : byte; s : string);
var 	   c,a : byte;
        offset : word;
begin
 a := Attr(fg,bg,false);
 if x > 0 then x := x-1;
 if y > 0 then y := y-1;

 offset := ofs(writebuffer^)+((y*txtscreen.maxX)+x) shl 1;
 for c := 1 to length(s) do
 begin
  memw[seg(writebuffer^):offset] := (a shl 8)+ord(s[c]);
  offset := offset + 2;
 end;

end;



Procedure CenteredText(y,c,b : byte; s : string);
begin
 fastwrite(40-(length(s) div 2),y,c,b,s);
end;

Procedure Block(x,y,x1,y1,fg,bg : byte);
var yc,a : byte;
begin
  a := Attr(fg,bg,false);
  for yc := y to y1 do
  begin
   fillmem(' ',a,(((yc-1)*txtscreen.maxX)+(x-1)) shl 1,x1-x);
   end;
end;


Procedure HLine(x,y,l,foreground,background : byte; c : char);
begin
  fillmem(c,Attr(foreground,background,false),(((y-1)*txtscreen.maxX)+(x-1)) shl 1,l);
end;

Procedure VLine(x,y,l,foreground,background : byte; c : char);
 var cnt : byte;
begin
     for cnt := 0 to l-1 do
      putchar(x,y+cnt,foreground,background,c);
end;


Procedure Box(xp,yp,xp1,yp1 : word; foreground, background : byte; slim : boolean; shadow : boolean);
begin
 Block(xp,yp,xp1,yp1,foreground,background);
 if slim then
 begin
   HLine(xp,yp,xp1-xp,foreground,background,'Ä');
   HLine(xp,yp1,xp1-xp,foreground,background,'Ä');
   Vline(xp,yp,yp1-yp,foreground,background,'³');
   Vline(xp1,yp,yp1-yp,foreground,background,'³');
   putchar(xp,yp,foreground,background,'Ú');
   putchar(xp1,yp,foreground,background,'¿');
   putchar(xp,yp1,foreground,background,'À');
   putchar(xp1,yp1,foreground,background,'Ù');
 end
 else
 begin
   HLine(xp,yp,xp1-xp,foreground,background,'Í');
   HLine(xp,yp1,xp1-xp,foreground,background,'Í');
   Vline(xp,yp,yp1-yp,foreground,background,'º');
   Vline(xp1,yp,yp1-yp,foreground,background,'º');
   putchar(xp,yp,foreground,background,'É');
   putchar(xp1,yp,foreground,background,'»');
   putchar(xp,yp1,foreground,background,'È');
   putchar(xp1,yp1,foreground,background,'¼');
 end;

 if shadow then
 begin
    ChangeAttrHLine(xp+1,yp1+1,(xp1-xp)+1,8);
    ChangeAttrVLine(xp1+1,yp+1,(yp1-yp)+1,8);
 end;
end;


Procedure SetBorder(Color : Word);
Assembler;
asm
 mov  ax, 0b00h
 mov  bx, Color
 int  10h
end;


Procedure FillMem(c : char; attr : byte; startoffset, count : word);
{Fast 16-bit screenmemory filler}
assembler;
asm
   push es
   push di

   lea si,writebuffer
   mov es,[ds:si+2]
   mov di,[ds:si]
   add di,startoffset

   mov al,c
   mov ah,attr
   mov cx,count

   cld
@Loop:
   stosw
   loop @Loop

   pop di
   pop es
end;


Procedure Screenfill(c : char; attr : byte);
{Fast 16-bit screenfill}
assembler;
asm
   push es
   push di

   lea si,writebuffer
   mov es,[ds:si+2]
   mov di,[ds:si]

   mov al,c
   mov ah,attr
   mov cx,2000 {4000 / 2}

   cld
@Loop:
   stosw
   loop @Loop

   pop di
   pop es
end;




Procedure ClrScr;
begin
 scrollup(0,0,0,79,24);
 gotoxy(1,1);
end;


Procedure Centeredline(y,c,b : byte; title : string);
var z,x : byte;
begin
  z := 1;
  for x := 1 to txtscreen.maxX do
  begin
    if (x >= ((txtscreen.maxX div 2)-(length(title) div 2))) and (z <= length(title)) then
    begin
     putchar(x,y,c,b,title[z]);
     inc(z);
    end
    else
    begin
      putchar(x,y,c,b,' ');
    end;
  end;
end;



Procedure InitMenuScreen(title : string; fc, bc : byte);
var z : byte;
begin
  z := 0 or 7 and not $80;   {Textfarbe 7, Hintergrund 0, blinken aus}
  ScreenFill('±',z);
  Centeredline(1,fc,bc,title);
end;


Function Mouse_detected : boolean;
begin
  GetIntVec($33, mi);
  If (mi = NIL) then
    mouse_detected := False
  else
    if (Byte(mi^) = $CF) then mouse_detected := False
  else
    mouse_detected := True;
end;


Function Mouse_Init : Boolean;
assembler;
   asm
    xor ax,ax
    int $33
    cmp ax,0
    je  @failed
    mov mouse.nb,bl
    mov al,1
    jmp @quit
@failed:
    xor al,al
    mov mouse.nb,al
@quit:
end;

Procedure Mouse_SetHLimits(xmin, xmax : Word);
{ set horizontal limits }
assembler;
 asm
  cmp mouse.mouse_there,0
  je  @fail
  mov ax,7
  mov cx,xmin
  mov dx,xmax
  int $33
  @fail:
 end;

Procedure Mouse_SetVLimits(ymin, ymax : Word);
{ set vertical limits }
assembler;
 asm
  cmp mouse.mouse_there,0
  je  @fail
  mov ax,8
  mov cx,ymin
  mov dx,ymax
  int $33
  @fail:
 end;

Procedure Mouse_Show;
assembler;
 asm
  cmp mouse.mouse_there,0
  je  @fail
  mov ax,1
  int $33
  @fail:
 end;

Procedure Mouse_Hide;
assembler;
 asm
  cmp mouse.mouse_there,0
  je  @fail
  mov ax,2
  int $33
  @fail:
 end;

Procedure Mouse_Read;
assembler;
 asm
  cmp mouse.mouse_there,0
  je  @fail
  mov ax,3
  int $33
  mov mouse.x,cx
  mov mouse.y,dx
  mov mouse.b,bl
  @fail:
 end;

Procedure Mouse_SetPos(x, y : Byte);
assembler;
 asm
  cmp mouse.mouse_there,0
  je  @fail
  mov ax,4
  int $33
  mov mouse.x,cx
  mov mouse.y,dx
  @fail:
 end;


 Procedure GotoXY(x,y : byte);
 begin
   if x > 0 then x := x-1;
   if y > 0 then y := y-1;
   asm
    mov ah,2h
    mov bh,txtscreen.page
    mov dh,y
    mov dl,x
    int 10h
   end;
 end;

 function GetX : byte;
 var x : byte;
 begin
 asm
   mov ah,3
   mov bh,txtscreen.page
   int 10h
   mov x,dl
  end;
  GetX := x+1;
 end;

 function GetY : byte;
 var y : byte;
 begin
  asm
   mov ah,3
   mov bh,txtscreen.page
   int 10h
   mov y,dh
  end;
   GetY := Y+1;
 end;

 Procedure Textcolor(c : byte);
 begin
  txtscreen.tc := c;
 end;

 Procedure Textbackground(c : byte);
 begin
  txtscreen.tbc := c;
 end;

 Procedure Scrolldown(lines,x,y,x1,y1 : byte);
 var a : byte;
 begin
  a := Attr(txtscreen.tc,txtscreen.tbc,false);
 asm
  mov ah,7
  mov al,lines
  mov bh,a
  mov cl,x
  mov ch,y
  mov dl,x1
  mov dh,y1
  int 10h
 end;
 end;

 Procedure Scrollup(lines,x,y,x1,y1 : byte);
 var a : byte;
 begin
  a := Attr(txtscreen.tc,txtscreen.tbc,false);
 asm
  mov ah,6
  mov al,lines
  mov bh,a
  mov cl,x
  mov ch,y
  mov dl,x1
  mov dh,y1
  int 10h
 end;
 end;


Procedure FastWriteNum(x, y, f, b: byte; num : longint);

{ Does a direct video write -- extremely fast.
  X, Y = screen location of first byte;
  Num = Number to display;
  F = foreground color;
  B = background color. }

var    s      : string;
       c      : byte;
begin
    str(num,s);
    for c := 1 to length(s) do
    begin
     putchar(x,y,f,b,s[c]);
     inc(x);
    end;
end;




 Procedure Write(s : string);
 var cnt,x,y : word;
 begin
  x := GetX;
  y := GetY;

  for cnt := 1 to length(s) do
  begin
   putchar(x,y,txtscreen.tc,txtscreen.tbc,s[cnt]);

   inc(x);
   if x = 81 then
   begin
    x := 1;
    if y = 25 then
    begin
     scrollup(1,0,0,79,24);
    end
    else
    begin
      inc(y);
    end;
   end;

  end;
  gotoxy(x,y);
end;


 Procedure Writeln(s : string);
 var y : byte;
 begin
  write(s);
  y := getY;
  if y = 25 then
  begin
   scrollup(1,0,0,79,24);
   gotoxy(1,25);
  end
  else
  begin
   gotoxy(1,y+1);
  end;
  end;

 Procedure SetWritePage(p : byte);
 begin
  txtscreen.page := p;
 end;

 Procedure SetViewPage(p : byte);
 assembler;
 asm
  mov ah,5;
  mov al,p
  int 10h
 end;


 Procedure ShadowScreen;
 assembler;
 asm
   push ds
   push es
   push si
   push di

   lds si,writebuffer
   mov es,[ds:si+2]
   mov di,[ds:si]
   inc di

   xor al,al
   mov al,8
   mov cx,2000 {4000 / 2}

   cld

@CopyLoop:
   stosb
   inc di
loop @CopyLoop

   pop di
   pop si
   pop es
   pop ds
 end;



function hex_char(Zeichen :char):byte;
begin
  zeichen := upcase(zeichen);

  case zeichen of
    '0': hex_char := 0;
    '1': hex_char := 1;
    '2': hex_char := 2;
    '3': hex_char := 3;
    '4': hex_char := 4;
    '5': hex_char := 5;
    '6': hex_char := 6;
    '7': hex_char := 7;
    '8': hex_char := 8;
    '9': hex_char := 9;
    'A': hex_char := 10;
    'B': hex_char := 11;
    'C': hex_char := 12;
    'D': hex_char := 13;
    'E': hex_char := 14;
    'F': hex_char := 15;
  end;

end;


function hex2dec(h:string) : byte;
var hexa :byte;
begin
  hexa    := 0;
  hexa    := hexa+hex_char(h[2]);
  hexa    := hexa+hex_char(h[1])*16;
  hex2dec := hexa;
end;




Function hexn(h:byte):string;
const
  hexChars: array [0..$F] of Char =
    '0123456789ABCDEF';
begin
  hexn := hexChars[h and $F];

end;



function hexb(h:byte):string;
const
  hexChars: array [0..$F] of Char =
    '0123456789ABCDEF';
begin
   hexb := hexChars[h shr 4]+
           hexChars[h and $F];
end;


function hexw(h:word):string;
const
  hexChars: array [0..$F] of Char =
    '0123456789ABCDEF';
begin
    hexw := hexChars[hi(h) shr 4]+
            hexChars[hi(h) and $F]+
            hexChars[Lo(h) shr 4]+
            hexChars[Lo(h) and $F];
end;


function addspace (base, b : word) : string;
var
  c2 : string;

begin
   str(b, c2);

   case base of
   10   :
    if b < 10 then c2 := ' ' + c2;

   100  :
   begin
    if b < 10 then
    c2 := '  ' + c2;
    if (b >= 10)  and (b < 100) then
    c2 := ' ' + c2;
   end;

   1000  :
   begin
    if b < 10 then
    c2 := '   ' + c2;
    if (b >= 10) and (b < 100) then
    c2 := '  ' + c2;
    if (b >= 100) and (b < 1000) then
    c2 := ' ' + c2;
   end;

   10000  :
   begin
    if b < 10 then
    c2 := '    ' + c2;
    if (b >= 10) and (b < 100) then
    c2 := '   ' + c2;
    if (b >= 100) and (b < 1000) then
    c2 := '  ' + c2;
    if (b >= 1000) and (b < 10000) then
    c2 := ' ' + c2;
   end;

  end;

  addspace := c2;
end; {addspace}

function addzero (base, b : word) : string;
var
  c2 : string;
begin
  STR (b, c2);

  case base of
   10   :
    if b < 10 then c2 := '0' + c2;

   100  :
   begin
    if b < 10 then
    c2 := '00' + c2;
    if (b >= 10)  and (b < 100) then
    c2 := '0' + c2;
   end;

   1000  :
   begin
    if b < 10 then
    c2 := '000' + c2;
    if (b >= 10) and (b < 100) then
    c2 := '00' + c2;
    if (b >= 100) and (b < 1000) then
    c2 := '0' + c2;
   end;

   10000  :
   begin
    if b < 10 then
    c2 := '0000' + c2;
    if (b >= 10) and (b < 100) then
    c2 := '000' + c2;
    if (b >= 100) and (b < 1000) then
    c2 := '00' + c2;
    if (b >= 1000) and (b < 10000) then
    c2 := '0' + c2;
   end;

  end;

  addzero := c2;
end; {addzero}



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


Procedure CopyBuffer(source, dest : pointer);
assembler;
asm
   push ds
   push es
   push si
   push di

   lea di,source
   mov ds,[ss:di+2] {pascal stores local vars in the stack}
   mov si,[ss:di]

   lea di,dest
   mov es,[ss:di+2]
   mov di,[ss:di]

   mov cx,2000 {4000 / 2}

   cld

@CopyLoop:
   movsw
loop @CopyLoop

   pop di
   pop si
   pop es
   pop ds

end;

Procedure SwapBuffers(var buffer1, buffer2 : pointer);
var dummy : pointer;
begin
 dummy := buffer2;
 buffer2 := buffer1;
 buffer1 := dummy;
end;

Procedure Writeto(p : pointer);
begin
  writebuffer := p;
end;

Procedure DisplayBuffer(p : pointer);
begin
  CopyBuffer(p,viewbuffer);
end;

Function  GetWriteBuffer : pointer;
begin
 GetWriteBuffer := writebuffer;
end;

Function  GetDisplayBuffer : pointer;
begin
 GetDisplayBuffer := viewbuffer;
end;

Procedure ChangeVSeg(seg : word);
begin
 txtscreen.VidSeg := seg;
 viewbuffer := ptr(seg,0);
 writebuffer := viewbuffer;
end;


begin
 mouse.mouse_there := mouse_detected;
 txtscreen.tc := 7;
 txtscreen.tbc := 0;

 txtscreen.VidSeg := Detect_VidSeg;
 viewbuffer := ptr(txtscreen.VidSeg,0);
 writebuffer := viewbuffer;
 txtscreen.maxX  := 80;
 txtscreen.maxY  := 25;


end.

