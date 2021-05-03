{$G-,N-,E-}
{Added compiler directives for compiling TNDY Tracker}

{*******************************************************
 keyboard unit
 Version 1.2 - 18.03.2021
 Author: Jan Knipperts
***********************************************************1

}

Unit Keyboard;
interface

var
 key_code  : byte;
 key_ascii : char;


Procedure  Get_Key;
Function   Is_Key_pressed :boolean;
Procedure  Wait_for_keypress;
Procedure  Clear_Keypress;
Function   R_Shift_State : Boolean;
function   L_Shift_State : Boolean;
function   CTRL_State : Boolean;
function   ALT_State : Boolean;
function   NUM_State : Boolean;


implementation




Procedure Clear_Keypress;
begin
 memw[$40:$1A] := memw[$40:$1C]; {Clears Bios key buffer}
 key_code := 0;
 key_ascii := #0;
 asm         {Pre PC AT machines need an additional controler reset}
  in al,61h
  mov ah,al
  or al,80h
  out 61h,al
  mov al,ah
  out 61h,al
 end;
end;


Procedure Get_Key;
{Gets last pressed key codes from Bios
 Scan code and Ascii code}
assembler;
asm
 xor ax,ax
 int $16
 mov key_code,ah
 mov key_ascii,al
end;



Function Is_Key_Pressed :boolean;
assembler;
asm
  xor ax,ax
  mov ah,1
  int 16h
  mov al,0
  je  @Quit
  mov al,1

 @Quit:
end;




Procedure Wait_for_keypress;
begin
 while is_key_pressed do get_key;
 repeat until is_key_pressed;
 while is_key_pressed do get_key;
end;


function  R_Shift_State : Boolean;
begin
 if mem[$40:$17] and not $F0 = 1 then
  R_Shift_State := true
 else
  R_Shift_State := false;
end;

function  L_Shift_State : Boolean;
begin
 if (mem[$40:$17] and not $F0) shr 1 = 1 then
  L_Shift_State := true
 else
  L_Shift_State := false;
end;


function  CTRL_State : Boolean;
begin
 if (mem[$40:$17] and not $F0) shr 2 = 1 then
  CTRL_State := true
 else
  CTRL_State := false;
end;

function  ALT_State : Boolean;
begin
 if (mem[$40:$17] and not $F0) shr 3 = 1 then
  ALT_State := true
 else
  ALT_State := false;
end;

function  NUM_State : Boolean;
begin
 if (mem[$40:$17] and not $E0) shr 5 = 1 then
  NUM_State := true
 else
  NUM_State := false;
end;


end.
