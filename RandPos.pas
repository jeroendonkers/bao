unit RandPos;

interface
uses global;

procedure create_randposlist(var poslist: TBaoPositionList; d: integer; n: integer);
procedure create_onerandpos(var pos: TBaoPosition; d: integer);

implementation

uses
  SysUtils,
  Math,
  classes,
  winprocs,
  Engine,
  Mersenne;


procedure create_onerandpos(var pos: TBaoPosition; d: integer);
var i,j: integer;
    moves: TBaoMoveList;
begin
 moves := nil;
 repeat
    pos := BAO_OFFICIALOPENING;
    for j:=1 to d*2 do begin
      moves := legal_moves(pos,100,false);
      i := floor(GenRandMT*length(moves));
      pos := execute_move(pos,moves[i],false);
      if  endofgame(pos) then break;
   end;
  until not endofgame(pos);
end;


procedure create_randposlist(var poslist: TBaoPositionList; d: integer; n: integer);
var i,j,k: integer;
    pos: TBaoPosition;
    moves: TBaoMoveList;
begin
 moves := nil;
 setlength(poslist,n);
 for k:=1 to n do begin
   repeat
    pos := BAO_OFFICIALOPENING;
    for j:=1 to d*2 do begin
      moves := legal_moves(pos,100,false);
      i := floor(GenRandMT*length(moves));
      pos := execute_move(pos,moves[i],false);
      if  endofgame(pos) then break;
   end;
   until not endofgame(pos);
   poslist[k-1]:=pos;
 end;
end;



procedure create_randpos(name: string; d: integer; n: integer);
var i,j,k: integer;
    pos: TBaoPosition;
    moves: TBaoMoveList;
    ot: Text;
begin
 moves := nil;
 assign(ot,name);
 {$I-}
 rewrite(ot);
 {$I+}
 for k:=1 to n do begin
   repeat
    pos := BAO_OFFICIALOPENING;
    for j:=1 to d*2 do begin
      moves := legal_moves(pos,100,false);
      i := floor(GenRandMT*length(moves));
      pos := execute_move(pos,moves[i],false);
      if  endofgame(pos) then break;
   end;
   until not endofgame(pos);
 {$I-}
  writeln(ot,postostr(pos));
 {$I+}
 end;
 {$I-}
 close(ot);
 {$I+}
end;






procedure comm_randPosFile(params: array of String);
begin
  if (high(params)<>3) then begin
    writeln('usage: baodos randposfile name moves count');
    exit;
  end;
  create_randpos(params[1],strtoint(params[2]),strtoint(params[3]));
end;

begin
   registercommand(@comm_randPosFile,'randposfile');
end.
