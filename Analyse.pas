unit Analyse;

interface

implementation
uses
  SysUtils,
  Math,
  classes,
  winprocs,
  global,
  Engine,
  Mersenne;


procedure printrandomgame;
var pos: TBaoPosition;
    moves: TBaoMoveList;
    nr: integer;
    i: integer;
    play: integer;
begin
//   set_enginemessage(output);
   init_search;
   pos := BAO_OFFICIALOPENING;
   nr := 1;
   play := SOUTH;
   repeat
     moves := legal_moves(pos,100,false);
     if length(moves)=0 then begin
        writeln('No Moves!');
        exit;
     end;
     i:=floor(GenRandMT*length(moves));
     if (play=0) then begin write(nr,': '); inc(nr); end;
     write(movetostr(moves[i],play),' ',length(moves));
     if (play=1) then writeln(';') else write(' ');
     pos := execute_move(pos,moves[i],false);
     play:=1-play;
   until endofgame(pos);
   if play=NORTH then writeln;
   if checkwinner(pos)=SOUTH then writeln('SOUTH WINS')
      else writeln('NORTH WINS')  ;
end;


var
  gamelength: array[1..10000] of integer;
  hist: array[1..10000] of TBaoMove;
  maxgamelength,maxbf: integer;
  movecount: array[1..10000] of integer;
  bf: array[1..10000] of integer;
  nmoves: array[1..10000,1..32] of integer;
  southwins: array[1..10000] of integer;

procedure randomgame;
var pos: TBaoPosition;
    moves: TBaoMoveList;
    nr,i: integer;
    play: integer;
begin
   pos := BAO_OFFICIALOPENING;
   nr := 0;
   play := SOUTH;
   repeat
     moves := legal_moves(pos,100,false);
     i:=floor(GenRandMT*length(moves));
     pos := execute_move(pos,moves[i],false);
     play:=1-play;
     inc(nr);
     hist[nr]:=moves[i];

     inc(movecount[nr]);
     inc(bf[nr],length(moves));
     inc(nmoves[nr,length(moves)]);
     if length(moves)>maxbf then maxbf:=length(moves);
   until endofgame(pos);

   if nr=5 then begin // shortest game!
     play:=SOUTH;
     for i:=1 to 5 do begin
         write(movetostr(hist[i],play),' ');
         play := 1-play;
      end;
      writeln;
   end;
   if (nr>maxgamelength) then maxgamelength:=nr;
   inc(gamelength[nr]);

   if checkwinner(pos)=south then inc(southwins[nr]);
end;

procedure searchedgame(md: integer);
var pos: TBaoPosition;
    moves: TBaoMoveList;
    move: TBaoMove;
    nr: integer;
    play: integer;
begin
   pos := BAO_OFFICIALOPENING;
   nr := 0;
   play := SOUTH;
   repeat
     search(pos,md,100,false);
     move:=get_bestmove;
     moves := legal_moves(pos,100,false);
     pos := execute_move(pos,move,false);
     play:=1-play;
     inc(nr);
     hist[nr]:=move;

     inc(movecount[nr]);
     inc(bf[nr],length(moves));
     inc(nmoves[nr,length(moves)]);
     if length(moves)>maxbf then maxbf:=length(moves);
   until endofgame(pos);

   if (nr>maxgamelength) then maxgamelength:=nr;
   inc(gamelength[nr]);

   if checkwinner(pos)=south then inc(southwins[nr]);
end;

function random_evaluate(pos: TBaoPosition): integer;
begin
   result := 1+floor(GenRandMT*100);
end;

function fixed_evaluate(pos: TBaoPosition): integer;
begin
   result := 1;
end;

procedure comm_test_search(params: array of string);
var i,j: integer;
    f: text;
begin
//  set_enginemessage(output);
//  set_evaluator(@random_evaluate);
  init_search;
  maxgamelength:=0; maxbf:=0;
  for i:=1 to 1000 do begin
     writeln('game ',i);
     clear_hashtable;
     searchedgame(14);
  end;

  assign(f,'srch14_1000_dat.xls');
  rewrite(f);
  write(f,'ply',char(9),'ends',char(9),'movecount',char(9),
       'wins', char(9), 'bf');
  for j:=1 to maxbf do write(f,char(9),'bf=',j);
  writeln(f);

  for i:=1 to maxgamelength do begin
     write(f,i,char(9),gamelength[i],char(9),movecount[i],
        char(9),southwins[i],char(9),bf[i]);
     for j:=1 to maxbf do write(f,char(9),nmoves[i,j]);
     writeln(f);
  end;
  close(f);
end;

// --------------------

type Tnode = record
    move:  TBaoMove;
    children: array of integer;
    num: integer;
end;
const maxdepth = 120;
var Node: array of Tnode;
var count: array[0..maxdepth] of integer;


procedure addhistory(nr: integer);
var n,m: integer;
    i,j: integer;
    found: boolean;
begin
   n:=0;
   for i:=1 to nr do begin
     found:=false;
     for j:=0 to length(Node[n].children)-1 do begin
        m := Node[n].children[j];
        if equalMove(Node[m].move,hist[i]) then begin
           found:=true;
           inc(Node[m].num);
           n:=m;
           break;
        end
     end;
     if (not found) then begin
        m:=length(Node);
        setlength(Node,m+1);
        setlength(Node[m].children,0);
        Node[m].move := hist[i];
        Node[m].num := 1;
        j:=length(Node[n].children);
        setlength(Node[n].children,j+1);
        Node[n].children[j]:=m;
        n := m;
     end;
   end;
end;


procedure addgame(md: integer);
var pos: TBaoPosition;
    move: TBaoMove;
    nr: integer;
    play: integer;
begin
   pos := BAO_OFFICIALOPENING;
   nr := 0;
   play := SOUTH;
   repeat
     search(pos,md,100,false);
     move:=get_bestmove;
     pos := execute_move(pos,move,false);
     play:=1-play;
     inc(nr);
     hist[nr]:=move;
   until endofgame(pos);
   addhistory(nr);
end;


var branches: integer;

procedure analysenode(n, depth: integer);
var i: integer;
begin
   if (length(Node[n].children)=0) then begin
      for i:=depth to maxdepth do inc(count[i]);
   end else begin
      inc(branches,length(Node[n].children)-1);
      inc(count[depth],length(Node[n].children));
      for i:=0 to length(Node[n].children)-1 do
        analysenode(Node[n].children[i],depth+1);
   end;
end;

procedure printgames(var f: text; n, depth,md: integer);
var i: integer;
begin
   if depth>0 then hist[depth]:=Node[n].move;
   if (depth=md) or (length(Node[n].children)=0)then begin
      write(f,Node[n].num,' x ');
      for i:=1 to depth do write(f,movetostr(hist[i],0),' ');
      writeln(f);
   end else begin
      for i:=0 to length(Node[n].children)-1 do
        printgames(f,Node[n].children[i],depth+1,md);
   end;
end;

procedure comm_test_diversity(params: array of string);
var i: integer;
    f: text;
begin
  set_evaluator(@random_evaluate);
  setlength(Node,1);
  setlength(node[0].children,0);
  init_search;
  maxgamelength:=0; maxbf:=0;
  for i:=1 to 5000 do begin
     writeln('game ',i);
     clear_hashtable;
     addgame(6);
  end;
  branches:=0;
  analysenode(0,0);
  writeln('Branches: ',branches+1);
  assign(f,'diversity.txt');
  rewrite(f);
  for i:=1 to maxdepth do
     writeln(f,i,' ',count[i-1]);
  close(f);

  assign(f,'games.txt');
  rewrite(f);
  printgames(f,0,0,maxdepth);
  close(f);
end;



begin
   registercommand(@comm_test_search,'analyse');
   registercommand(@comm_test_diversity,'diversity');
end.
