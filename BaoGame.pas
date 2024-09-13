unit BaoGame;

interface
uses global;

type TBaoGame = class

public
   title: string;
   south: string;
   north: string;
   event: string;
   place: string;
   date: string;
   time: string;
   winner: byte;


   constructor EmptyGame;
   constructor Read(filename: string);
   procedure Write(filename: string);
   procedure resetgame;
   function getNumMoves: integer;
   function getMoveAt(m: integer): string;
   function nextmove: string;
   function getMoveNr: integer;
   function eog: boolean;
   procedure setMove(move: string);
   procedure undoMove();
   procedure setOpening(pos: TBaoPosition);
   function getOpening: TBaoPosition;
   procedure ReadOpening(t: string);

 private
   openingboard: TBaoPosition;
   moves: array of string;
   moveptr: integer;

end;


implementation
uses sysutils, dialogs, main;

  constructor TBaoGame.EmptyGame;
  begin
     title:='';
     south:='';
     north:='';
     place:='';
     event:='';
     date:='';
     time:='';
     winner:=255;
     moves:=nil;
     moveptr:=0;
     openingboard:=BAO_OFFICIALOPENING;
  end;


  constructor TBaoGame.Read(filename: string);
  var F: Text;
      i,m: integer;
      s,t,head,m1,m2: string;
  begin
     EmptyGame;
     m:=0;
     AssignFile(F,filename);
     {$I-}
     Reset(F);
     {$I+}
     if IOresult<>0 then exit;

     // default values
     ignoretakasia:=false;

     repeat
        readln(F,s);
        s := trim(s);
        if s='' then continue;
        if s[1]='%' then continue;
        i := Pos(';', s);
        if i>0 then s := copy(s,1,i-1);

        i := Pos(':', s);
        if i<=1 then continue;
        head := lowercase(trim(copy(s,1,i-1)));
        if length(head)=0 then continue;

        t := trim(copy(s,i+1,length(s)));
        if length(t)=0 then continue;

        if head='title' then title:=t
        else if head='north' then north:=t
        else if head='south' then south:=t
        else if head='place' then place:=t
        else if head='event' then event:=t
        else if head='time' then time:=t
        else if head='date' then date:=t
        else if head='opening' then readopening(t)
        else if head='winner' then begin
           if lowercase(t)='south'
              then winner:=global.SOUTH;
           if lowercase(t)='north'
              then winner:=global.NORTH;
        end else if head='takasia' then begin
           if lowercase(t)='no' then ignoretakasia:=true
           else ignoretakasia:=false;
        end else begin
           inc(m);
           try
             if strtoint(head)<>m then continue;
           except
              on exception do continue;
           end;
           i := Pos(' ', t);
           m1 := '';
           m2 := '';
           if (i>0) then begin
             m1 := trim(copy(t,1,i-1));
             m2 := trim(copy(t,i+1,length(t)));
           end else m1 := trim(t);
           if m1 = '' then continue;
           setlength(moves,2*m-1);
           moves[2*m-2]:= m1;
           if m2 = '' then break;
           setlength(moves,2*m);
           moves[2*m-1]:= m2;
        end;
     until eof(F);
     CloseFile(F);
     resetgame;
  end;


  procedure TBaoGame.ReadOpening(t: string);
  begin
     if lowercase(t)='official' then begin
        openingboard:=BAO_OFFICIALOPENING;
        exit;
     end;
     if lowercase(t)='novice' then begin
        openingboard:=BAO_NOVICEOPENING;
        exit;
     end;
     openingboard:=strtopos(t);
  end;



  procedure TBaoGame.Write(filename: string);
  var F: Text;
      i,n: integer;
  begin
     AssignFile(F,filename);
     {$I-}
     Rewrite(F);
     {$I+}
     if IOresult<>0 then exit;
     writeln(f,'title: ',title,';');
     writeln(f,'south: ',south,';');
     writeln(f,'north: ',north,';');
     writeln(f,'place: ',place,';');
     writeln(f,'event: ',event,';');
     writeln(f,'date: ',date,';');
     if comparemem(@openingboard,@BAO_OFFICIALOPENING,sizeof(openingboard)) then
         writeln(f,'opening: official;')
     else if comparemem(@openingboard,@BAO_NOVICEOPENING,sizeof(openingboard)) then
         writeln(f,'opening: novice;')
     else
         writeln(f,'opening: '+postostr(openingboard)+';');
     writeln(f,'time: ',time,';');
     system.write(f,'winner: ');
     if winner=global.south then writeln(f,' south;') else
     if winner=global.north then writeln(f,' north;') else
     writeln(f,' ;');
     if ignoretakasia then writeln(f,'takasia: no;');
     i:=0;
     n:=1;
     while i<=length(moves)-1 do begin
           system.write(f,n,': ');
           system.write(f,moves[i]);
           if (i<length(moves)-1) then
               system.write(f,' ',moves[i+1]);
           writeln(f,';');
           inc(i,2);
           inc(n,1);
     end;
     CloseFile(F);
  end;


   procedure TBaoGame.setOpening(pos: TBaoPosition);
   begin
      openingboard:=pos;
   end;

   function TBaoGame.getOpening;
   begin
      getOpening:=openingboard;
   end;

   function TBaoGame.getNumMoves: integer;
   begin
      getNumMoves := 0;
      if (moves=NIL) then exit;
      getNumMoves := length(moves);
   end;

   function TBaoGame.getMoveAt(m: integer): string;
   begin
      getMoveAt:='';
      if (moves=NIL) then exit;
      if (m<0) or (m>=length(moves)) then exit;
      getMoveAt:=moves[m];
   end;


   procedure TBaoGame.resetgame;
   begin
       moveptr:=0;
   end;

   function TBaoGame.nextmove: string;
   begin
      nextmove:='';
      if moveptr>=length(moves) then exit;
      nextmove:=moves[moveptr];
      inc(moveptr);
   end;

   function TBaoGame.eog: boolean;
   begin
       eog := (moves=NIL) or (moveptr>=length(moves));
   end;

   function TBaoGame.getMoveNr: integer;
   begin
       getMoveNr:=moveptr;
   end;

   procedure TBaoGame.setMove(move: string);
   begin
      setlength(moves,moveptr+1);
      moves[moveptr]:=move;
      nextmove;
   end;

   procedure TBaoGame.undoMove();
   // undo last move
   begin
      if getnummoves=0 then exit;
      setlength(moves,getnummoves-1);
      if moveptr>=getnummoves then dec(moveptr);
   end;

 end.
