{$G-,N-,E-}
{Added compiler directives for compiling TNDY Tracker}

{**************************************************************
 Fileselector
 Author: Jan Knipperts

 Version  1.1 - April 23, 2020
          (I wrote version 1.0 on July 12, 1998 :) )

          Changes:
           - Added screen buffering
           - Now uses my keyboard unit instead of borlands crt

***************************************************************
}



Unit FSelect;
interface
uses dos,textmode,keyboard;

const

 MaxDirSize = 512;        {Buffer size}
 max_path_to_show = 24;

type
 DirPtr   = ^DirRec;
 DirList  = array[0..MaxDirSize - 1] of DirPtr;
 DirRec   = record
               Attr: Byte;
               Time: Longint;
               Size: Longint;
               Name: string[12];
             end;

 LessFunc = function(X, Y: DirPtr): Boolean;


var
 Selector_DRVcol,
 Selector_DIRcol,
 Selector_FILEcol,
 Selector_BackCol,
 Selector_MarkCol : byte;



Function User_selected_File(wildcards : string; sortby : Lessfunc; xpos,ypos,num : byte; screenbuffer : pointer) : string;
{writes a file select menu at xpos,ypos with num entries on a page and
 lets the user choose a file. sortby can be Name, Size Time and defines how
 the entries will be sorted. The complete path of the chosen file is
 returned by this function
 Multiple wildcards must be separated by a ';'}

{The following funcions are to be entered as "sortby" and define,
how the filelist will be sorted}
function Sort_by_Name(X, Y: DirPtr): Boolean;
function Sort_by_Size(X, Y: DirPtr): Boolean;
function Sort_by_Time(X, Y: DirPtr): Boolean;

{Example for the call in your program:

 User_selected_File('*.exe',Sort_by_Name,2,4,22,ptr(Vidseg,0)^);
}


implementation


const


 ESC  = 01;  {Keyboard Scancodes}
 UP   = 72;
 DWN  = 80;
 POS1 = 71;
 ENDE = 79;
 ENTER= 28;
 PGUP = 73;
 PGDWN= 81;

 LW     = 1;  {types}
 DATEI  = 2;
 VERZ   = 3;



var
 sdir                         : searchrec;
 drive                        : DirRec;
 Dir                          : DirList;
 num_entries,fc               : word;
 mask                         : string;
 Path,Olddir                  : PathStr;
 D                            : DirStr;
 N                            : NameStr;
 E                            : ExtStr;
 w                            : array[1..10] of string[5];
 wc                           : byte;
 Less                         : LessFunc;
 screenbuffer		      : pointer;






Function Drive_Exist (Drive : Byte) : Boolean; Assembler;
{ This function will return True if the drive exists on the computer, false otherwise }
Asm
             Push Ds

             Cmp Drive, 2                  { Test if this is a floppy drive }
             Jbe @@A_or_B

             Mov Ax, 4409h                     { Hard disk or network one? }
             Mov Bl, Drive
             Int 21h

             Jc  @@False

             Mov Ax, 1
             Jmp @@Fin

@@A_or_B:    Mov Ah, 44h
             Mov Al, 0Eh
             Mov Bl, Drive
             Int 21h

             Cmp Al, Drive
             Jnz @@False

             Mov Ax, 1

             Jmp @@Fin

@@False:     Mov Ax, 1500h                     { Test if the disk is a CD }
             Mov Bx, 0000h
             Int 2Fh

             Xor Ax, Ax

             Cmp Bx, 0
             Jz @@Fin

             Inc Cl
             Cmp Cl, [Drive]
             Jne @@Fin

             Mov Ax, 1

@@Fin:       Pop Ds

End;


{$F+}

function Sort_by_Name(X, Y: DirPtr): Boolean;
begin
  Sort_by_Name := X^.Name < Y^.Name;
end;

function Sort_by_Size(X, Y: DirPtr): Boolean;
begin
  Sort_by_Size := X^.Size < Y^.Size;
end;

function Sort_by_Time(X, Y: DirPtr): Boolean;
begin
  Sort_by_Time := X^.Time > Y^.Time;
end;

{$F-}

procedure QuickSort(L, R: Integer);
var
  I, J: Integer;
  X, Y: DirPtr;
begin
  I := L;
  J := R;
  X := Dir[(L + R) div 2];
  repeat
    while Less(Dir[I], X) do Inc(I);
    while Less(X, Dir[J]) do Dec(J);
    if I <= J then
    begin
      Y := Dir[I];
      Dir[I] := Dir[J];
      Dir[J] := Y;
      Inc(I);
      Dec(J);
    end;
  until I > J;
  if L < J then QuickSort(L, J);
  if I < R then QuickSort(I, R);
end;

procedure SortFiles(start,ende : word);
begin
  if (ende <> 0) and (@Less <> nil) then
    QuickSort(start,ende - 1);
end;


Procedure FindFiles(wildcart :string);
begin
 fillchar(sdir,sizeof(sdir),0);
 findfirst(wildcart,anyfile,sdir); {Find Files}
 while doserror = 0 do   {While there is no error...}
 begin
    if (sdir.attr in [ReadOnly,Hidden,Sysfile,Archive]) then
    begin
     GetMem(dir[num_entries], Length(sdir.Name) + 10);
     Move(sdir.Attr, dir[num_entries]^, Length(sdir.Name) + 10);
     inc(num_entries);
    end;
    findnext(sdir);
 end;
 doserror := 0;
end;

Procedure FindDirs;
begin
 fillchar(sdir,sizeof(sdir),0);
 findfirst('*.*',anyfile,sdir); {Find Directories}
 while (doserror = 0) do   {While there is no error...}
 begin
   if (sdir.attr = Directory) then
   begin
   GetMem(dir[num_entries], Length(sdir.Name) + 10);
   Move(sdir.Attr, dir[num_entries]^, Length(sdir.Name) + 10);
   inc(num_entries);
   end;
   findnext(sdir);

 end;
end;


Procedure GetWildcards(maske : string);
var ss,se : byte;
begin
 fillchar(w,sizeof(w),0);
 if (length(maske) >= 3) and (pos('*',maske) > 0) then
 begin
  while pos(' ',maske) > 0 do
  begin
   Delete(maske,pos(' ',maske),1);
  end;
  wc := 1;

  if pos(';',maske) = 0 then
  begin
   w[1] := maske;
  end
  else
  begin
    w[wc] := copy(maske,1,(pos(';',maske)));
    inc(wc);

    while (pos(';',maske) > 0) and (wc <= 10) do
    begin
     ss := pos(';',maske)+1;
     maske[pos(';',maske)] := ' ';
     if pos(';',maske) = 0 then se := length(maske)
     else se := pos(';',maske)-1;
     w[wc] := copy(maske,ss,se);
     inc(wc);
    end;
    dec(wc);
  end;

 end
 else
 begin
  wc := 1;
  w[1] := '*.*';
 end;

end;


Procedure Create_Record; {Stores file and directory names in a buffer}
var i : byte;
    intermediate : word;
begin
 num_entries := 0;

 fillchar(dir,sizeof(dir),0);
 FindDirs;                 {Find directory}
 intermediate := num_entries;
 SortFiles(0,intermediate);



 GetWildcards(mask);

 for i := 1 to wc do
 begin
  FindFiles(w[i]);       {Find valid files}
 end;
 SortFiles(intermediate, num_entries);



 for i := 1 to 26 do       {Add drives}
 begin
  if Drive_Exist(i) then
  begin
   fillchar(sdir,sizeof(sdir),0);
   sdir.name := chr(64+i)+':';
   sdir.attr := $FF;
   GetMem(dir[num_entries], Length(sdir.Name) + 10);
   Move(sdir.Attr, dir[num_entries]^, Length(sdir.Name) + 10);
   inc(num_entries);
  end;
 end;



end;


Procedure WriteEntry(x,y : byte; index : word; mark : boolean);
{writes a filename at given position,
 x/y = Position; index = index in file record, c = textcolor}
var c : byte;
begin
   fsplit(dir[index]^.name,d,n,e);

   if (dir[index]^.attr and Directory <> 0) and
      (dir[index]^.attr <> $FF) then {Verzeichnisse}
   begin
    if (mark = false) then
    begin
     if (VidSeg = $B800) then c := Selector_DIRcol else c := 7;
    end
    else
    begin
     if (VidSeg = $B800) then c := Selector_Markcol else c := 15;
    end;
    fastwrite(x,y,c,Selector_BackCol,n+e);
    fastwrite(x+14,y,c,Selector_BackCol,'<DIR>');
   end
   else
   begin                        {Normale Datei}

    if (mark = false) then
    begin
     if (VidSeg = $B800) then c := Selector_FILEcol else c := 7;
    end
    else
    begin
     if (VidSeg = $B800) then c := Selector_Markcol else c := 15;
    end;

    fastwrite(x,y,c,Selector_BackCol,n+e);
   end;

   if (dir[index]^.attr = $FF) then
   begin
    if (mark = false) then
    begin
     if (VidSeg = $B800) then c := Selector_DRVcol else c := 7;
    end
    else
    begin
     if (VidSeg = $B800) then c := Selector_Markcol else c := 15;
    end;
    fastwrite(x,y,c,Selector_BackCol,dir[index]^.name);
    fastwrite(x+14,y,c,Selector_BackCol,'<DRIVE>');
   end;
end;


Procedure ClearList(x,y,num : byte);
var i : byte;
begin
    for i := y to y+num-1 do
    begin
      FastWrite(x,i,Selector_BackCol,Selector_BackCol,'                     ');
    end;
end;




Procedure List(x,y,start,ende : byte);
var i : byte;
begin

 if ende > num_entries then ende := num_entries-1;

 for i := start to ende do
 begin
  WriteEntry(x,y+(i-start),i,false);
 end;

end;


Function User_selected_File(wildcards : string; sortby : Lessfunc; xpos,ypos,num : byte; screenbuffer : pointer) : string;
{writes a file select menu at xpos,ypos with num entries on a page and
 lets the user choose a file. sortby can be Name, Size Time and defines how
 the entries will be sorted. The complete path of the chosen file is
 returned by this function.
 If you don't use a screenbuffer make the pointer point to video memory}
var start,marked : word;
    mx,my,lp,z   : byte;
    cs           : Pathstr;

begin
 if screenbuffer = nil then exit; {No buffer?}
 Writeto(screenbuffer);

 mask := wildcards;
 marked := 1;
 start := 1;
 mx := xpos;
 my := ypos;
 Less := sortby;

 getdir(0,olddir);
 path := olddir;
 if length(path) > max_path_to_show then
 begin
  Delete(path,max_path_to_show-3,length(path));
  path := path + '...';
 end;
 centeredtext(ypos+num+1,Selector_FILEcol,Selector_BackCol,path);
 cs := path;

 Create_Record;        {Do the search}
 List(xpos,ypos,start,start+num-1);
 WriteEntry(mx,my,marked,true);   {Mark selected file}

 clear_keypress;
 ViewBuffer(screenbuffer);

 repeat;

  if is_key_pressed then Get_Key;

  if key_code = UP then
  begin
   if my > ypos then
   begin
    WriteEntry(mx,my,marked,false);   {Unmark selected file}
    dec(marked);
    dec(my);
    WriteEntry(mx,my,marked,true);   {Mark selected file}
   end
   else
   begin
    if (start > 1) then                             {scroll list up}
    begin
     dec(start);
     ClearList(xpos,ypos,num);
     List(xpos,ypos,start,start+num-1);
     dec(marked);
     my := ypos;
     WriteEntry(mx,my,marked,true);   {Mark selected file}
    end;
   end;
   Clear_Keypress;
   ViewBuffer(screenbuffer);
  end;

  if key_code = DWN then
  begin
   if (my < ypos+num-1) and (marked < num_entries-1) then
   begin
    WriteEntry(mx,my,marked,false);   {Unmark selected file}
    inc(marked);
    inc(my);
    WriteEntry(mx,my,marked,true);   {Mark selected file}
   end
   else
   begin
    if (marked < num_entries-1) then                             {scroll list down}
    begin
     inc(start);
     inc(marked);
     ClearList(xpos,ypos,num);
     List(xpos,ypos,start,start+num-1);
     WriteEntry(mx,my,marked,true);   {Mark selected file}
    end;
   end;
   Clear_Keypress;
   ViewBuffer(screenbuffer);
  end;


 if (key_code = POS1) and (marked > 1) then
  begin
     ClearList(xpos,ypos,num);
     start := 1;
     marked := 1;
     my := ypos;
     List(xpos,ypos,start,start+num-1);
     WriteEntry(mx,my,marked,true);   {Mark selected file}
     Clear_Keypress;
     ViewBuffer(screenbuffer);
  end;

  if (key_code = ENDE) and (marked < num_entries-1) then
  begin
     ClearList(xpos,ypos,num);
     if num_entries < num then
     begin
      start := 1;
      marked := num_entries-1;
      my := ypos+(num_entries-2);
     end
     else
     begin
      marked := num_entries-1;
      start := marked-num;
      my := ypos+num-1;
     end;

     List(xpos,ypos,start,start+num-1);
     WriteEntry(mx,my,marked,true);   {Mark selected file}
     Clear_Keypress;
     ViewBuffer(screenbuffer);
  end;

  if (key_code = PGUP) and (marked > 1) then
  begin
     ClearList(xpos,ypos,num);
      if (my > ypos) then
      begin
       my := ypos;
      end
      else
      begin
        if (integer(start-(num-1)) >= 1) then
        begin
          dec(start,num-1);
        end
        else
        begin
          start := 1;
        end;
        end;

        marked := start;
        my := ypos;
        List(xpos,ypos,start,start+num-1);
        WriteEntry(mx,my,marked,true);   {Mark selected file}
        Clear_Keypress;
        ViewBuffer(screenbuffer);
     end;

  if (key_code = PGDWN) and (marked < num_entries-1) then
  begin
     ClearList(xpos,ypos,num);
     if num_entries < num then
     begin
      start := 1;
      marked := num_entries-1;
      my := ypos+(num_entries-2);
     end
     else
     begin
       if my < (ypos+num-1) then
       begin
        marked := start+num-1;
       end
      else
       begin
        if marked+(num-1) <= num_entries then
        begin
         marked := marked+(num-1);
        end
        else
        begin
         marked := num_entries-1;
        end;
        start := marked-num;
       end;
       my := ypos+(num-1);
     end;

     List(xpos,ypos,start,start+num-1);
     WriteEntry(mx,my,marked,true);   {Mark selected file}
     Clear_Keypress;
     ViewBuffer(screenbuffer);
  end;


  if key_code = ENTER then
  begin

   if (dir[marked]^.attr and Directory <> 0) then {Verzeichnis?}
   begin
    chdir(dir[marked]^.name);
    getdir(0,path);
    if length(path) > max_path_to_show then
    begin
     Delete(path,max_path_to_show-3,length(path));
     path := path + '...';
    end;

    if length(path) > length(cs) then cs := path;

    if (VidSeg = $B800) then
     centeredtext(ypos+num+1,Selector_BackCol,Selector_BackCol,cs)
    else
    begin
     cs := '';
     for z := 1 to max_path_to_show do
     cs := cs + ' ';

     centeredtext(ypos+num+1,0,0,cs);
    end;


    centeredtext(ypos+num+1,Selector_FILEcol,Selector_BackCol,path);

    marked := 1;
    start  := 1;
    my := ypos;
    Create_Record;  {Search new directory}
    ClearList(xpos,ypos,num);
    list(xpos,ypos,start,num);
    WriteEntry(mx,my,marked,true);   {Mark selected file}
   end
   else
   begin
    User_selected_File := fexpand(dir[marked]^.name);
    chdir(olddir);
    exit;
   end;


   if dir[marked]^.attr = $FF then {Laufwerk}
   begin
    {$I-}
     chdir(fexpand(dir[marked]^.name)+'\');
    {$I+}
     if  (IOresult > 0) then
     begin
      {Disk error!}
     end
     else
     begin
      marked := 1;
      start  := 1;
      my := ypos;

      Create_Record;                {Search new drive}
      ClearList(xpos,ypos,num);
      list(xpos,ypos,start,num);
      WriteEntry(mx,my,marked,true);   {Mark selected file}
      getdir(0,path);
      if length(path) > max_path_to_show then
      begin
       Delete(path,max_path_to_show-3,length(path));
       path := path + '...';
      end;

      if (VidSeg = $B800) then
       centeredtext(ypos+num+1,Selector_BackCol,Selector_BackCol,cs)
      else
      begin
       cs := '';
       for z := 1 to max_path_to_show do
       cs := cs + ' ';

       centeredtext(ypos+num+1,0,0,cs);
      end;

      if length(path) > length(cs) then cs := path;
      end;
   end;

   Clear_Keypress;
   ViewBuffer(screenbuffer);
 end;

  until key_code = ESC;
  User_selected_File := '';
  chdir(olddir);
end;


begin
 {These are my default colors, change them as you like :) }
  Selector_DRVcol  := 7;
  Selector_DIRcol  := 3;
  Selector_FILEcol := 11;
  Selector_BackCol := 1;
  Selector_MarkCol := 15;
end.
