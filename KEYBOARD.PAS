{$G-,N-,E-}
{Added compiler directives for compiling TNDY Tracker}

{*******************************************************
 Keyboard control unit
 Version 1.0 - 20.07.2001
 Author: Jan Knipperts
***********************************************************1

}

Unit Keyboard;
interface

var
 key_code  : byte;
 key_ascii : char;

Procedure Get_Key;
Function  Is_Key_pressed :boolean;
Procedure Wait_for_keypress;
Procedure Clear_Keypress;
Procedure Clear_Keyboard_buffer;
function  R_Shift_State : Boolean;
function  L_Shift_State : Boolean;
function  CTRL_State : Boolean;
function  ALT_State : Boolean;
function  NUM_State : Boolean;


implementation

Procedure Get_Key;
assembler;
asm
   xor ah,ah     {Get scancode function}
   int 16h
   mov key_code,ah	 {Get scan code and store it in "key"}
   mov key_ASCII,al   {Get Ascii code and store it in "keyC"}
end;



Function Is_Key_Pressed :boolean;
assembler;
asm
    mov        ah,1
    int        16h
    jnz        @true
    mov        al,false
    jmp        @end
@true:
    mov        al,true
@end:
end;



Procedure Clear_Keypress;
{Clears Bios keyboard buffer}
assembler;
asm
@Clear_loop:
    mov ah, 01h
    int 16h         { is there a key pressed}
    jz @end         { if not, return   }
    mov ah, 00h
    int 16h          { "handle" the key}
    jmp @Clear_loop
@end:
    xor al,al
    mov key_code,al
    mov key_ASCII,al
end;


Procedure Clear_Keyboard_Buffer;
{same as above but makes sure all keys are released and the controller
 has aknowledged that}
begin
 while port[$60] shr 7 = 0 do
 begin
   Clear_Keypress;
 end;
end;


Procedure Wait_for_keypress;
begin
 Clear_Keypress;
 repeat until is_key_pressed;
 Clear_Keypress;
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
