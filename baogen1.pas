unit baogen1;

interface

implementation
uses
  SysUtils,
  Math,
  classes,
  winprocs,
  Engine,
  Eval,
  global,
  Mersenne;

procedure output(s: string);
begin
//  writeln(s);
end;


var logname: string = 'exp.txt';
var log: Text;

procedure writelog(s: string);
begin
   AssignFile(log,logname);
   {$I-}
   append(log);
   {$I+}
   if IOresult<>0 then begin writeln('cannot append log'); exit; end;
   writeln(log,s);
   close(log);
end;

procedure createlog(name: string);
begin
   logname:=name;
   AssignFile(log,logname);
   {$I-}
   rewrite(log);
   {$I+}
   if IOresult<>0 then begin writeln('cannot log'); exit; end;
   writeln(log,' ');
   close(log);
end;


type TTimerThread = class(TThread)
   waittime: integer;
   procedure Execute; override;
   constructor start(t: integer);
end;

var  timer: TTimerThread = nil;

constructor TTimerThread.start(t: integer);
begin
   waittime:=t*10;
   Freeonterminate:=true;
   Create(false);
end;

procedure TTimerThread.Execute;
begin
   repeat
      sleep(100);
      dec(waittime);
   until (waittime<0) or terminated;
   if not terminated then terminate_search;
   timer:=nil;
end;

procedure stop_timer();
begin
  if timer<>nil then begin
     timer.terminate;
     timer.waitfor;
  end;
end;

procedure start_timer(t: integer);
begin
   if timer<>nil then stop_timer;
   timer:=Ttimerthread.start(t);
end;

// ---------------------------------------------------


type TevalParams = record
   store: array[0..1] of integer;
   hole: array[0..1, 0..15] of integer;
   capt: array[0..1, 0..15] of integer;
   ownsnyumba: array[0..1] of integer;
   captnyumba: array[0..1] of integer;
end;

var parama, paramb: TevalParams;

function eval(pos: TBaoPosition; param: TevalParams): integer;
var score,i: integer;
begin
   with pos do begin
      // stone balance
      score:=param.store[0]*store[rootplayer]-param.store[1]*store[1-rootplayer];
      for i:=0 to 15 do begin
        inc(score,param.hole[0,i]* hole[rootplayer,i]);
        dec(score,param.hole[1,i]* hole[1-rootplayer,i]);
      end;

      // captures
      for i:=0 to 7 do begin
         if (hole[rootplayer,i]>0) and (hole[1-rootplayer,7-i]>0) then begin
            if (7-i=NYUMBA) and ownsnyumba[1-rootplayer] then inc(score,param.captnyumba[0] );
            if (i=NYUMBA) and ownsnyumba[rootplayer] then dec(score,param.captnyumba[1]);
            inc(score, param.capt[0,i] * hole[rootplayer,i]);
            inc(score, param.capt[1,i] * hole[1-rootplayer,7-i]);
         end;
      end;

      // own nyumba
      // Admissiblity:  forget about onwning nyumba
      if ownsnyumba[rootplayer] then inc(score,param.ownsnyumba[0]);
      if ownsnyumba[1-rootplayer]then  inc(score,param.ownsnyumba[1]);
   end;
   if score=0 then score:=1;
   if score<-9000 then score :=-9000;
   if score>9000 then score := 9000;
   eval:=score;
end;


function evaluate_a(pos: TBaoPosition): integer;
begin
   evaluate_a := eval(pos,parama);
end;

function evaluate_b(pos: TBaoPosition): integer;
begin
   evaluate_b := eval(pos,paramb);
end;


function match(depth: integer): integer;
var pos: TBaoPosition;
    move: TBaoMove;
    play: integer;
begin
  pos := BAO_OFFICIALOPENING;
  game_score := -99999;
  play := SOUTH;
  repeat
     clear_hashtable;
     set_evaluator(@evaluate_a);
     search(pos,depth,100,false);
     move:=get_bestmove;
     pos := execute_move(pos,move,false);
     if (not endofgame(pos)) then begin
        play:=1-play;
        clear_hashtable;
        set_evaluator(@evaluate_b);
        search(pos,depth,100,false);
        move:=get_bestmove;
        pos := execute_move(pos,move,false);
     end;
  until endofgame(pos);
  if checkwinner(pos)=south then match:=1 else match:=0;
end;


// -------------
// genetic algorithm
// ---------------

// population
const ChromSize = 66;
const PopSize = 100;
type TIchromosome = record
   dat: array[0..ChromSize-1] of integer;
   evaluated: boolean;
   fitness: integer;
end;

type Tpopulation = record
   chr: array[0..PopSize-1] of TIChromosome;
   order: array[0..PopSize-1] of integer;
end;

function rand(i: integer): integer;
begin
  rand := integer(floor(GenRandMT*i)) - i div 2;
end;

procedure generate_population(var pop: Tpopulation);
var i,j: integer;
begin
   for j:=0 to PopSize-1 do begin
      for i:=0 to ChromSize-1 do
          pop.chr[j].dat[i]:=rand(100);
      pop.chr[j].fitness:=0;
      pop.chr[j].evaluated:=false;
      pop.order[j]:=j;
   end;
end;

procedure mutate(var chr: TIchromosome);
var i: integer;
begin
   i:=floor(GenRandMT*ChromSize); chr.dat[i]:=rand(100);
   chr.evaluated:=false;
end;

procedure cross(var chra,chrb: TIchromosome);
var i,j,t: integer;
begin
   j:=floor(GenRandMT*ChromSize);
   for i:=0 to j do begin t:=chra.dat[i]; chra.dat[i]:=chrb.dat[i]; chrb.dat[i]:=t; end;
   chra.evaluated:=false;
   chrb.evaluated:=false;
end;

procedure set_eval(var target: TevalParams; chr: TIchromosome);
var i,j: integer;
begin
   i:=0;
   with target do begin
      store[0]:=chr.dat[i]; inc(i);
      store[1]:=chr.dat[i]; inc(i);
      for j:=0 to 15 do begin
        hole[0,j]:=chr.dat[i]; inc(i);
        hole[1,j]:=chr.dat[i]; inc(i);
      end;
      // captures
      captnyumba[0]:=chr.dat[i]; inc(i);
      captnyumba[1]:=chr.dat[i]; inc(i);
      for j:=0 to 7 do begin
        capt[0,j]:=chr.dat[i]; inc(i);
        capt[1,j]:=chr.dat[i]; inc(i);
      end;
      // own nyumba
      ownsnyumba[0]:=chr.dat[i]; inc(i);
      ownsnyumba[1]:=chr.dat[i];
   end;
end;

procedure test(var chr: TIchromosome; depth: integer; input: string);
var pos: TBaoPosition;
    move: TBaoMove;
    play: integer;
    inp: Text;
    spos: string;
begin
   if chr.evaluated then begin write('-'); exit; end;
   set_eval(parama,chr);
   chr.fitness:=0;
   assign(inp,input);
   reset(inp);
   repeat
    readln(inp,spos);
    pos := strtopos(spos);
    game_score := -99999;
    play := SOUTH;
    repeat
      set_evaluator(@evaluate_a);
      search(pos,depth,100,false);
      move:=get_bestmove;
      pos := execute_move(pos,move,false);
      if (not endofgame(pos)) then begin
         play:=1-play;
         set_evaluator(@default_evaluate);
         search(pos,depth,100,false);
         move:=get_bestmove;
         pos := execute_move(pos,move,false);
     end;
   until endofgame(pos);
   if checkwinner(pos)=south then begin
     write('!');
     inc(chr.fitness);
   end else write('X');
  until eof(inp);
  chr.evaluated:=true;
end;


procedure sort_population(var pop: Tpopulation);
var i,j,t: integer;
begin
   for i:=1 to PopSize-1 do
      for j:=1 to PopSize-i do
         if pop.chr[pop.order[j-1]].fitness<
             pop.chr[pop.order[j]].fitness then
         begin
            t:=pop.order[j];
            pop.order[j]:=pop.order[j-1];
            pop.order[j-1]:=t;
         end;
end;


procedure store_population(var pop: Tpopulation; gen: integer; nr: integer);
var i,j: integer;
begin
   AssignFile(log,'temppop.txt');
   rewrite(log);
   writeln(log,gen);
   writeln(log,nr);
   for j:=0 to PopSize-1 do begin
      for i:=0 to ChromSize-1 do
          write(log,pop.chr[j].dat[i],' ');
      writeln(log);
      write(log,pop.chr[j].fitness,' ');
      if pop.chr[j].evaluated then write(log,'1 ') else write(log,'0 ');
      writeln(log,pop.order[j]);
   end;
   close(log);
end;


procedure load_population(var pop: Tpopulation; var gen: integer; var nr: integer);
var i,j,e: integer;
begin
   AssignFile(log,'temppop.txt');
   reset(log);
   readln(log,gen);
   readln(log,nr);
   for j:=0 to PopSize-1 do begin
      for i:=0 to ChromSize-1 do
          read(log,pop.chr[j].dat[i]);
      readln(log);
      read(log,pop.chr[j].fitness);
      read(log,e);
      pop.chr[j].evaluated:=(e=1);
      readln(log,pop.order[j]);
   end;
   close(log);
end;


procedure comm_gen(params: array of string);
var pop: TPopulation;
    generation,nr,i,ii,j,jj,totfit: integer;
begin
   init_search;
   disable_hash;
   if FileExists('temppop.txt') then
      load_population(pop,generation,nr)
   else begin
      generate_population(pop);
      generation:=1;
      nr:=0;
      store_population(pop,generation,nr);
   end;
   repeat
      Writeln('Generation '+inttostr(generation));
      totfit:=0;      
      repeat
         Write('chr '+inttostr(nr)+': ');
         test(pop.chr[nr],4,'startpos10kl.txt');
         Write(' ',inttostr(pop.chr[nr].fitness),'; ');
         store_population(pop,generation,nr);
         inc(totfit,pop.chr[nr].fitness);
         inc(nr);
      until nr>=PopSize;
      writeln;
      write('Average fitness: ');
      write(totfit*1.0/PopSize,' ');

      AssignFile(log,'result.txt');
      append(log);
      write(log,generation,' ');
      write(log,'Average fitness: ');
      write(log,totfit*1.0/PopSize,' ');
      sort_population(pop);
      write(log,'Max fitness: ');
      writeln(log,pop.chr[pop.order[0]].fitness);
      close(log);

      write('Max fitness: ');
      writeln(pop.chr[pop.order[0]].fitness);

      // best 10 for parents
      for nr:=0 to 9 do begin
         i:=pop.order[nr];
         j:= pop.order[integer(floor(GenRandMT*10))];
         ii:=pop.order[PopSize-1-nr*2];
         jj:=pop.order[PopSize-2-nr*2];
         if (i<>j) then begin
            pop.chr[ii]:=pop.chr[i];
            pop.chr[jj]:=pop.chr[j];
            cross(pop.chr[ii],pop.chr[jj]);
         end;
      end;
      // best 5 for mutate
      for nr:=0 to 4 do begin
         i:=pop.order[nr];
         ii:=pop.order[Popsize-21-nr];
         pop.chr[ii]:=pop.chr[i];
         mutate(pop.chr[ii]);
      end;
      inc(generation);
      nr:=0;
   until generation>1000;
end;

begin
   registercommand(@comm_gen,'genexp1');
end.

