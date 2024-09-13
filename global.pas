unit global;

interface

const
   ROWAA = 1;
   ROWBB = 2;
   ROWA  = 3;
   ROWB  = 4;
   ROWNS = 5;
   ROWSS = 6;
   NYUMBA = 4;
   CLOCKDIR = 0;
   ANTICLOCKDIR = 1;
   NORTH = 1;
   SOUTH = 0;
   NOTAKASIA = 255;
   STARTTAKASIA = 1;
   INTAKASIA = 2;

type TBaoPosition = record
   hole: array[0..1, 0..15] of byte;
   store: array[0..1] of byte;
   ownsnyumba: array[0..1] of boolean;
   player: byte;
   intakasia: byte;
end;

type TBaoMove = record
   hole: integer;
   dir: integer;
   playnyumba: boolean;
   takasa: boolean;
   takasia: byte;
end;

type TBaoMoveList = array of TbaoMove;
type TBaoPositionList = array of TbaoPosition;

type BaoCommand = procedure(params: array of String);

type evaluator = function(pos: TBaoPosition): integer;

const
 BAO_OFFICIALOPENING: TBaoPosition =
  (hole: ((0,0,0,0,6,2,2,0,0,0,0,0,0,0,0,0),  //rowbb
          (0,0,0,0,6,2,2,0,0,0,0,0,0,0,0,0)); //rowb
   store: (22,22);
   ownsnyumba: (true,true);
   player: SOUTH;
   intakasia: NOTAKASIA; );

  BAO_NOVICEOPENING: TBaoPosition =
  (hole: ((2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2),
          (2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2));
   store: (0,0);
   ownsnyumba: (false,false);
   player: SOUTH;
   intakasia: NOTAKASIA; );


  BAO_EMPTYOPENING: TBaoPosition =
  (hole: ((0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0),
          (0,0,0,0,0,0,0,0, 0,0,0,0,0,0,0,0));
   store: (0,0);
   ownsnyumba: (true,true);
   player: SOUTH;
   intakasia: NOTAKASIA; );

  procedure switchplayer(var pos: TBaoPosition);
  procedure setnonyumba(var pos: TBaoPosition; player: integer);
  function intakasa(pos: TBaoPosition; player: integer): boolean;
  function checkCapture(pos: TBaoPosition; player,phole,dir: integer): boolean;
  function checkLoss(pos: TBaoPosition; player: integer): boolean;
  function endOfGame(pos: TBaoPosition): boolean;
  function checkWinner(pos: TBaoPosition): integer;
  procedure checkinTakasia(var pos: TBaoPosition);
  function checkFrontEmpty(pos: TBaoPosition; player: integer): boolean;


  function equalMove(a,b: TbaoMove): boolean;
  function strtomove(s: string): TBaoMove;
  function movetostr(move: TBaoMove; player: integer): string;
  function postostr(pos: TBaoPosition): string;
  function strtopos(s: string): TBaoPosition;

  procedure registerCommand(proc: BaoCommand; name: String);
  procedure doCommand(name: String; params: array of String);

  procedure registerEvaluator(eval: Evaluator; name: String);
  function getEvaluator(name: String): evaluator;

  function isRealValue(val: integer): boolean;

implementation
uses sysutils,main;


type CommandEntry = record
      comm: BaoCommand;
      name: String;
end;
var commandlist: array of CommandEntry;

type EvalEntry = record
      eval: evaluator;
      name: String;
end;
var evallist: array of EvalEntry;

function noeval(pos: TBaoPosition): integer;
begin
  noeval:=0;
end;


  procedure switchplayer(var pos: TBaoPosition);
  begin
     pos.player := 1-pos.player;
  end;

  procedure setnonyumba(var pos: TBaoPosition; player: integer);
  begin
     pos.ownsnyumba[player]:=false;
  end;

  function intakasa(pos: TBaoPosition; player: integer): boolean;
  var i,j: integer;
      check: array[0..7] of boolean;
      cappossible: boolean;
  begin

     cappossible:=false;
     for i:=0 to 7 do begin
        check[i] := ((pos.hole[player,i]>0) and (pos.hole[1-player,7-i]>0));
        if check[i] then cappossible:=true;
     end;
     if pos.store[player]>0 then begin // namua stage
        intakasa := not cappossible;
        exit;
     end;

     // mtaji stage

     intakasa := false;
     // check whether player can capture any of check's
     for i:=0 to 7 do if check[i] then begin
         for j:=0 to 15 do
          if (i<>j) and (pos.hole[player,j]>1) and (pos.hole[player,j]<16) then begin
            if ((j+pos.hole[player,j]) and 15)=i then exit; // can capture
            if ((j-pos.hole[player,j]) and 15)=i then exit; // can capture
          end
     end;
     intakasa := true;
  end;


  function checkCapture(pos: TBaoPosition; player,phole,dir: integer): boolean;
  // check wether playing a hole leads to a capture (MTAJI stage)
  // rule 3.4
  var numsow,endhole: byte;
  begin
    with pos do begin
      checkcapture := false;
      // number to sow
      numsow := hole[player,phole];
      if (numsow<=1) or (numsow>=16) then exit; // rule 3.4 !!
      // compute end hole
      endhole := (phole + dir * numsow) and 15;
      if endhole>7 then exit; // ending on back row
      if (hole[1-player,7-endhole]>0) and (hole[player,endhole]>0)
         then checkcapture := true;
    end;
  end;


  // TAKASIA: rule 4.1, 4.1a
  // this is checked after a player takasa-ed
  // player has been switched already
  procedure checkinTakasia(var pos: TBaoPosition);
  var i,j,n,tkpos, numsow, numfilled, numsingle: integer;
      check: array[0..7] of boolean;
      tkpossible: boolean;
  begin
    with pos do begin
     intakasia:=NOTAKASIA;
     if ignoretakasia then exit;
     if store[player]>0 then exit;

     // find vulnerable opponent holes, filled holes and singletons
     tkpossible:=false;
     numfilled:=0; numsingle:=0;
     for i:=0 to 7 do begin
        check[i]:=false;
        if hole[player,i]>0 then begin
           inc(numfilled);
           if hole[player,i]=1 then inc(numsingle);
           check[i] := (hole[1-player,7-i]>0);
           if check[i] then tkpossible:=true;
         end;
     end;
     if not tkpossible then exit;

     // check whether takasia-ed player can capture, rule 4.1
     for i:=0 to 7 do if check[i] then begin
         for j:=0 to 15 do begin
          numsow:=hole[player,j];
          if (i<>j) and (numsow>1) and (numsow<16) then begin
            if ((j+numsow) and 15)=i then begin
                exit; // can capture
            end;
            if ((j-numsow) and 15)=i then begin
              exit; // can capture
            end;
          end
         end
     end;

     // check whether takasia-ing player can capture more other than once
     // rule 4.1
     n:=0; tkpos:=NOTAKASIA;
     for i:=0 to 7 do if check[i] then begin
         for j:=0 to 15 do begin
           numsow:=hole[1-player,j];
           if (j<>7-i) and (numsow>1) and (numsow<16) then begin
             if (((j+numsow) and 15)=7-i) or
                (((j-numsow) and 15)=7-i) then begin
                check[i]:=false;
             end; // can capture
           end;
         end;
         if not check[i] then begin
            inc(n); tkpos:=i;
         end;
     end;
     if n<>1 then exit; // can capture more than once

     // in takasia !  Hole tkpos is takasia-ed, however

     // cannot takasia the house, rule 4.1a
     if (tkpos=NYUMBA) and (ownsnyumba[player]) then exit;

     // cannot takasia the only occupied hole, rule 4.1a
     if numfilled=1 then exit;

     // cannot takasia the only hole with more than one stone, rule 4.1a
     if (numsingle=numfilled-1) and (hole[player,tkpos]>1) then exit;

     // now, tkpos is really takasia-ed
     intakasia:=tkpos;
   end;
  end;


  function checkFrontEmpty(pos: TBaoPosition; player: integer): boolean;
  begin
    checkFrontEmpty:=true;
    if ((pos.hole[player,0] + pos.hole[player,1] + pos.hole[player,2] + pos.hole[player,3] +
         pos.hole[player,4] + pos.hole[player,5] + pos.hole[player,6] + pos.hole[player,7]) = 0)
    then exit;
    checkFrontEmpty:=false;
  end;

  function checkLoss(pos: TBaoPosition; player: integer): boolean;
  var i: integer;
      full: boolean;
  begin
    checkLoss:=true;

    // first rule: all holes in front row are empty: rule 1.2
    if ((pos.hole[player,0] + pos.hole[player,1] + pos.hole[player,2] + pos.hole[player,3] +
         pos.hole[player,4] + pos.hole[player,5] + pos.hole[player,6] + pos.hole[player,7]) = 0)
    then exit;

   // second rule: player's store is empty and all holes contain
   // less than two stones: rule 1.2, 3.3
    if pos.store[player]=0 then begin
       full:=false;
       for i:=0 to 15 do
           if pos.hole[player,i]>1 then begin full:=true; break; end;
       if not full then exit;
    end;

    checkLoss:=false;
  end;

  function checkWinner(pos: TBaoPosition): integer;
  begin
     checkWinner := -1;
     if checkLoss(pos,NORTH) then checkWinner:=SOUTH;
     if checkLoss(pos,SOUTH) then checkWinner:=NORTH;
  end;

  function endOfGame(pos: TBaoPosition): boolean;
  begin
     endofgame := (checkWinner(pos)>=0);
  end;



  function strtomove(s: string): TBaoMove;
  // translate official move string in inner TBaoMove
  var move: TBaoMove;
      backrow: boolean;
      hole: integer;
  begin
      move.hole:=-1; move.dir:=0;
      move.playnyumba:=false;
      move.takasa:=false;
      move.takasia:=NOTAKASIA;

      if (s='') then begin
         strtoMove := move;
         exit;
      end;

      backrow:=false;
      if (s[1]='b') or (s[1]='B') then backrow:=true;
      if (s[1] in ['a','A','b','B']) then
        s:=copy(s,2,length(s));

      if (s='') then begin
         strtoMove := move;
         exit;
      end;
      hole := ord(s[1])-ord('1');
      if (hole<0) or (hole>7) then begin
         strtoMove := move;
         exit;
      end;

      if backrow then move.hole:=15-hole else move.hole:=hole;

      s:=copy(s,2,length(s));
      move.dir:=0;
      if s<>'' then begin
         if s[1]='L' then move.dir:=-1;
         if s[1]='R' then move.dir:=1;
         if (s[1] in ['L','R']) then s:=copy(s,2,length(s));
      end;

      if s<>'' then begin
         if s[1]='>' then begin
           move.playnyumba:=true;
           s:=copy(s,2,length(s));
         end;
      end;

      if s<>'' then begin
         if s[1]='*' then begin
             move.takasa:=true;
             s:=copy(s,2,length(s));
             if s<>'' then
               if s[1]='*' then
                 move.takasia:=INTAKASIA;
          end;
      end;

      strtoMove := move;
  end;


  function movetostr(move: TBaoMove; player: integer): string;
  var s:  string;
  begin
      if (player=NORTH) and (move.hole<=7)
         then s:='a'+inttostr(move.hole+1);
      if (player=NORTH) and (move.hole>7)
         then s:='b'+inttostr(16-move.hole);
      if (player=SOUTH) and (move.hole<=7)
         then s:='A'+inttostr(move.hole+1);
      if (player=SOUTH) and (move.hole>7)
         then s:='B'+inttostr(16-move.hole);
      if move.dir=1 then s:=s+'R';
      if move.dir=-1 then s:=s+'L';
      if move.playnyumba then s:=s+'>';
      if move.takasa then s:=s+'*';
      if move.takasia<>NOTAKASIA then s:=s+'*';
      movetostr:=s;
  end;


  function postostr(pos: TBaoPosition): string;
  var s:  string; i: integer;
  begin
      s:='[ ';
      for i:=0 to 7 do s:=s+inttostr(pos.hole[1,8+i])+' ';
      s:=s+'| ';
      for i:=0 to 7 do s:=s+inttostr(pos.hole[1,7-i])+' ';
      s:=s+'| ';
      for i:=0 to 7 do s:=s+inttostr(pos.hole[0,i])+' ';
      s:=s+'| ';
      for i:=0 to 7 do s:=s+inttostr(pos.hole[0,15-i])+' ';
      s:=s+'| '+inttostr(pos.store[0])+' '+inttostr(pos.store[1])+' | ';
      if pos.ownsnyumba[0] then s:=s+'T '  else s:=s+'F ';
      if pos.ownsnyumba[1] then s:=s+'T '  else s:=s+'F ';
      s:=s+'| '+inttostr(pos.intakasia)+' | '+inttostr(pos.player)+' ] ';
      postostr:=s;
  end;

  function nexttoken(var s: string): string;
  var i: integer;
  begin
     i:=1;
     nexttoken:='';
     s:= trim(s);
     if s='' then exit;
     if s[1] in ['0'..'9'] then begin
        while (i<=length(s)) and (s[i] in ['0'..'9']) do inc(i);
        if (i<=length(s))
          then nexttoken:=copy(s,1,i-1) else nexttoken:=s;
        delete(s,1,i-1);
        exit;
     end;
     nexttoken:=s[1];
     delete(s,1,1);
  end;


  function strtopos(s: string): TBaoPosition;
  var i: integer;
      t: string;
      pos: TBaoPosition;
  begin
      pos:=BAO_EMPTYOPENING;
      strtopos:=pos;
      s:=trim(s);
      t := nexttoken(s); if t<>'[' then exit;
      for i:=0 to 7 do begin
          t:=nexttoken(s);
          pos.hole[1,8+i]:=strtointdef(t,0);
      end;
      t := nexttoken(s); if t<>'|' then exit;
      for i:=0 to 7 do begin
          t:=nexttoken(s);
          pos.hole[1,7-i]:=strtointdef(t,0);
      end;
      t := nexttoken(s); if t<>'|' then exit;
      for i:=0 to 7 do begin
          t:=nexttoken(s);
          pos.hole[0,i]:=strtointdef(t,0);
      end;
      t := nexttoken(s); if t<>'|' then exit;
      for i:=0 to 7 do begin
          t:=nexttoken(s);
          pos.hole[0,15-i]:=strtointdef(t,0);
      end;
      t:=nexttoken(s); if t<>'|' then exit;
      t:=nexttoken(s); pos.store[0]:=strtointdef(t,0);
      t:=nexttoken(s); pos.store[1]:=strtointdef(t,0);
      t:=nexttoken(s); if t<>'|' then exit;
      t:=nexttoken(s); pos.ownsnyumba[0]:=(t='T');
      t:=nexttoken(s); pos.ownsnyumba[1]:=(t='T');
      t:=nexttoken(s); if t<>'|' then exit;
      t:=nexttoken(s); pos.intakasia:=strtointdef(t,0);
      t:=nexttoken(s); if t<>'|' then exit;
      t:=nexttoken(s); pos.player:=strtointdef(t,0);
      t := nexttoken(s); if t<>']' then exit;
      strtopos:=pos;
  end;


procedure registerEvaluator(eval: Evaluator; name: String);
var n: integer;
begin
   n:=High(evallist)+1;
   setlength(evallist,n+1);
   evallist[n].eval:=eval;
   evallist[n].name:=name;
end;

function getEvaluator(name: String): evaluator;
var i: integer;
begin
   for i:=0 to high(evallist) do
     if evallist[i].name=name then begin
        getevaluator := evallist[i].eval;
        exit;
     end;
   Writeln('Evaluator "'+name+'" not found...');
   getevaluator := @noeval;
end;

procedure evalCommand(params: array of String);
var i: integer;
begin
   write('Available evaluators: ');
   for i:=0 to high(evallist) do
      Write(evallist[i].name+' ');
   writeln;
end;



procedure registerCommand(proc: BaoCommand; name: String);
var n: integer;
begin
   n:=High(Commandlist)+1;
   setlength(commandlist,n+1);
   commandlist[n].comm:=proc;
   commandlist[n].name:=name;
end;

procedure doCommand(name: String; params: array of String);
var i: integer;
begin
   for i:=0 to high(Commandlist) do
     if commandlist[i].name=name then begin
        commandlist[i].comm(params);
        exit;
     end;
   Writeln('Command "'+name+'" not found...');
end;

procedure helpCommand(params: array of String);
var i: integer;
begin
   write('Available commands: ');
   for i:=0 to high(Commandlist) do
      Write(commandlist[i].name+' ');
   writeln;
end;

procedure inputCommand(params: array of String);
var i,j: integer;
    f: Text;
    line,s: string;
    par: Array of String;
begin
   if high(params)<>1 then begin
     writeln('usage: baodos run commandfile');
     exit;
   end;
   assign(f,params[1]);
   {$I-}
   reset(f);
   {$I+}
   if ioresult<>0 then begin
     writeln('Cannot open commandfile '+params[1]);
     exit;
   end;
   while not eof(f) do begin
      readln(f,line);  line:=trim(line);
      if line='' then continue;
      if copy(line,1,1)='#' then continue;
      setlength(par,0); i:=0;
      repeat
         j:=pos(' ',line);
         if j=0 then s:=line
         else begin
            s:=copy(line,1,j-1);
            line := trim(copy(line,j,length(line)));
         end;
         inc(i);
         setlength(par,i);
         par[i-1]:=s;
       until j=0;
       doCommand(par[0],par);
   end;
   close(f);
end;



function isRealValue(val: integer): boolean;
begin
   isRealValue:= (abs(val)>9000);
end;

function equalMove(a,b: TbaoMove): boolean;
begin
    result := (a.hole=b.hole) and ((a.dir=b.dir) or (a.dir=0) or (b.dir=0)) and (a.playnyumba=b.playnyumba)
       and (a.takasa=b.takasa) and (a.takasia=b.takasia);
end;


begin
   movelimit:=100;
   maxsearchdepth:=64;
   searchtime:=30;
   ignoretakasia:=false;
   setLength(commandlist,0);
   setLength(evallist,0);
   registerCommand(@helpCommand,'?');
   registerCommand(@helpCommand,'help');
   registerCommand(@inputCommand,'run');
   registerCommand(@evalCommand,'eval');
end.
