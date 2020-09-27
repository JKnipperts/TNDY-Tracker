{$G-,N-,E-}
{*******************************************************
 Textmode
 Useful procedures and functions for fast drawing and
 buffering in 80x25 text mode
 Version 1.92 - 11.09.2020
 Author: Jan Knipperts
 *******************************************************
}

{Added compiler directives for compiling TNDY Tracker}


Unit Textmode;


interface
uses dos;

Function  Detect_VidSeg : word;
Function  atr(fg,bg : byte; blink : boolean) : byte;
Procedure AttrMDA(x,y : byte; underline,blink,bright : boolean);
Procedure ChangeAttr(x,y,atrib : byte);
Procedure Cursor(onoff : boolean);
Procedure Change_Cursor(start_line,bottom_line : byte);


Procedure Window(xp,yp,xp1,yp1 : word; c,b : byte; shadow : boolean);
Procedure Box(xp,yp,xp1,yp1 : word; foreground, background : byte; slim : boolean);
Procedure Block(x,y,x1,y1,fg,bg : byte);
Procedure HLine(x,y,l,foreground,background : byte; c : char);
Procedure VLine(x,y,l,foreground,background : byte; c : char);


Procedure SetBorder(Color : Word);
Procedure InitMenuScreen(title : string; fc, bc : byte);
Procedure Centeredline(y,c,b : byte; title : string);
Procedure PutChar(x,y: Byte; ch: Char; fg, bg : byte);
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
Procedure Fill(c : char; attr : byte);
Procedure SetWritePage(p : byte);
Procedure SetViewPage(p : byte);
Procedure ViewBuffer(p : pointer);
Procedure Writeto(p : pointer);
Function  Mouse_detected : boolean;
Function  Mouse_Init : Boolean;
Procedure Mouse_SetHLimits(xmin, xmax : Word);
Procedure Mouse_SetVLimits(ymin, ymax : Word);
Procedure Mouse_Show;
Procedure Mouse_Hide;
Procedure Mouse_Read;
Procedure Mouse_SetPos(x, y : Byte);
Procedure ShadowScreen;

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
  end;


var
 mi             : pointer;
 mouse          : mousedata;
 mouse_there    : boolean;
 page,tc,tbc,
 ocs,oce        : byte;
 writeseg,
 viewseg,
 vidseg          : word;


implementation

Function Detect_VidSeg : word;
begin
 if Mem[$0000:$0449] = 7 then Detect_VidSeg := $B000
 else Detect_VidSeg := $B800;
end;

Procedure AttrMDA(x,y : byte; underline,blink,bright : boolean);
var a : byte;
begin
   a := 7;
   if underline then a := $F;
   if bright then a := a or (1 shl 3);
   if blink then a := a or (1 shl 7);
   ChangeAttr(x,y,a);
end;

Function atr(fg,bg : byte; blink : boolean) :byte;
var a : byte;
begin
 if VidSeg = $B800 then {Color display}
 begin
  a := fg or (bg shl 4);
  if not blink then a := a and not (1 shl 7);
 end
 else
 begin                                   {Monochrome}
   a := 7;
   if fg > 7 then a := a or (1 shl 3);    {bright}
   if blink then a := a or (1 shl 7);
 end;
 atr := a;
end;


Procedure ChangeAttr(x,y,atrib : byte);
begin
  if x > 0 then x := x-1;
  if y > 0 then y := y-1;
  mem[writeseg:(((y*80)+x) shl 1)+1]:=atrib;
end;





Procedure PutChar(x,y: Byte; ch: Char; fg, bg : byte);
begin

  if x > 0 then x := x-1;
  if y > 0 then y := y-1;
  if (x <= 79) and (y <= 25) then
  begin
  mem[writeseg:(((y*80)+x) shl 1)]:=Byte(ch);
  mem[writeseg:(((y*80)+x) shl 1)+1]:=atr(fg,bg,false)
  end;
end;

Function GetChar(x,y: Byte): Char;
begin
  if x > 0 then x := x-1;
  if y > 0 then y := y-1;
  GetChar:=Char(mem[writeseg:((y*80)+x) shl 1]);
end;

Function GetTextColor(x,y: Byte): Byte;
begin
  if x > 0 then x := x-1;
  if y > 0 then y := y-1;

  GetTextColor:=mem[writeseg:(((y*80)+(x-1)) shl 1)+1] and $f;
end;

Function GetTextBackground(x,y: Byte): Byte;
begin
  if x > 0 then x := x-1;
  if y > 0 then y := y-1;

  GetTextBackground:=mem[writeseg:(((y*80)+(x-1)) shl 1)+1] or $f;
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
var z : byte;
begin
 for z := 1 to length(s) do
 begin
  putchar(x+(z-1),y,s[z],fg,bg);
 end;
end;

Procedure CenteredText(y,c,b : byte; s : string);
begin
 fastwrite(40-(length(s) div 2),y,c,b,s);
end;


Procedure Block(x,y,x1,y1,fg,bg : byte);
var xc,yc : byte;
begin
  for yc := y to y1 do
  begin
   for xc := x to x1 do
   begin
      putchar(xc,yc,' ',fg,bg);
   end;
  end;
end;


Procedure HLine(x,y,l,foreground,background : byte; c : char);
 var cnt : byte;
begin
     for cnt := 0 to l-1 do
      putchar(x+cnt,y,c,foreground,background);
end;

Procedure VLine(x,y,l,foreground,background : byte; c : char);
 var cnt : byte;
begin
     for cnt := 0 to l-1 do
      putchar(x,y+cnt,c,foreground,background);
end;


Procedure Box(xp,yp,xp1,yp1 : word; foreground, background : byte; slim : boolean);
var xc,yc : word;
begin
 Block(xp,yp,xp1,yp1,foreground,background);
 if slim then
 begin
   HLine(xp,yp,xp1-xp,foreground,background,'Ä');
   HLine(xp,yp1,xp1-xp,foreground,background,'Ä');
   Vline(xp,yp,yp1-yp,foreground,background,'³');
   Vline(xp1,yp,yp1-yp,foreground,background,'³');
   putchar(xp,yp,'Ú',foreground,background);
   putchar(xp1,yp,'¿',foreground,background);
   putchar(xp,yp1,'À',foreground,background);
   putchar(xp1,yp1,'Ù',foreground,background);
 end
 else
 begin
   HLine(xp,yp,xp1-xp,foreground,background,'Í');
   HLine(xp,yp1,xp1-xp,foreground,background,'Í');
   Vline(xp,yp,yp1-yp,foreground,background,'º');
   Vline(xp1,yp,yp1-yp,foreground,background,'º');
   putchar(xp,yp,'É',foreground,background);
   putchar(xp1,yp,'»',foreground,background);
   putchar(xp,yp1,'È',foreground,background);
   putchar(xp1,yp1,'¼',foreground,background);
 end;
end;


Procedure Window(xp,yp,xp1,yp1 : word; c,b : byte; shadow : boolean);
var xc,yc : word;
begin
 Box(xp,yp,xp1,yp1,c,b,false);

if shadow then
begin
 for yc := yp+1 to yp1+1 do
 begin
   putchar(xp1+1,yc,getchar(xp1+1,yc),8,0);
 end;
 for xc := xp+1 to xp1+1 do
 begin
   putchar(xc,yp1+1,getchar(xc,yp1+1),8,0);
 end;
end;
   cursor(false);
end;

Procedure SetBorder(Color : Word);
Assembler;
asm
 mov  ax, 0b00h
 mov  bx, Color
 int  10h
end;


Procedure Fill(c : char; attr : byte);
{Very fast screenfill}
assembler;
asm
   mov ax, writeseg;
   mov es, ax
   mov di, 4000;
   mov al, c
   mov ah, attr
   std
@Loop:
   stosw
   cmp di, 0
   jnz @Loop
   stosw
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
  for x := 1 to 80 do
  begin
    if (x >= (40-(length(title) div 2))) and (z <= length(title)) then
    begin
     putchar(x,y,title[z],c,b);
     inc(z);
    end
    else
    begin
      putchar(x,y,' ',c,b);
    end;
  end;
end;



Procedure InitMenuScreen(title : string; fc, bc : byte);
var x,y,z,c : byte;
begin
  z := 0 or 7 and not (1 shl 7);   {Textfarbe 7, Hintergrund 0, blinken aus}
  Fill('±',z);
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
  cmp mouse_there,0
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
  cmp mouse_there,0
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
  cmp mouse_there,0
  je  @fail
  mov ax,1
  int $33
  @fail:
 end;

Procedure Mouse_Hide;
assembler;
 asm
  cmp mouse_there,0
  je  @fail
  mov ax,2
  int $33
  @fail:
 end;

Procedure Mouse_Read;
assembler;
 asm
  cmp mouse_there,0
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
  cmp mouse_there,0
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
    mov bh,page
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
   mov bh,page
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
   mov bh,page
   int 10h
   mov y,dh
  end;
   GetY := Y+1;
 end;

 Procedure Textcolor(c : byte);
 begin
  tc := c;
 end;

 Procedure Textbackground(c : byte);
 begin
  tbc := c;
 end;

 Procedure Scrolldown(lines,x,y,x1,y1 : byte);
 var a : byte;
 begin
  a := atr(tc,tbc,false);
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
  a := atr(tc,tbc,false);
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
     putchar(x,y,s[c],f,b);
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
   putchar(x,y,s[cnt],tc,tbc);

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
 var cnt,y : byte;
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
  page := p;
 end;

 Procedure SetViewPage(p : byte);
 assembler;
 asm
  mov ah,5;
  mov al,p
  int 10h
 end;

 Procedure Writeto(p : pointer);
 begin
  writeseg := seg(p^);
 end;

 Procedure ViewBuffer(p : pointer);
 begin
  move(p^,ptr(viewseg,0)^,4000);
 end;

 Procedure ShadowScreen;
 var atr : byte;
     z   : word;
 begin
  atr := 0;
  atr := atr shl 4;
  atr := atr or 8;
  atr := atr and not (1 shl 7);   {Blinken aus}

  z := 1;
  repeat;
   mem[writeseg:z]:=atr;
   inc(z,2);
  until (z >= 4000);
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
    if (b > 10)  and (b < 100) then
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
    if (b > 10)  and (b < 100) then
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





begin
 mouse_there := mouse_detected;
 tc := 7;
 tbc := 0;

 VidSeg := Detect_VidSeg;
 viewseg := VidSeg;
 writeseg := viewseg;

end.

