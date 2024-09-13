unit baogen4;

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

var o_eval: evaluator;

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

// ---------------------------------------------------

type TevalParams = record
   store:  integer;
   hole: array[0..15] of integer;
   capt: array[0..7] of integer;
   ownsnyumba: integer;
   captnyumba: integer;
end;

var parama: TevalParams;

function eval(pos: TBaoPosition; param: TevalParams): integer;
var score,i: integer;
begin
   with pos do begin
      // stone balance
      score:=param.store*(store[rootplayer]-store[1-rootplayer]);
      for i:=0 to 15 do begin
         inc(score,param.hole[i]*(hole[rootplayer,i]-hole[1-rootplayer,i]));
      end;

      // captures
      for i:=0 to 7 do begin
         if (hole[rootplayer,i]>0) and (hole[1-rootplayer,7-i]>0) then begin
            if (7-i=NYUMBA) and ownsnyumba[1-rootplayer] then inc(score,param.captnyumba );
            if (i=NYUMBA) and ownsnyumba[rootplayer] then dec(score,param.captnyumba);
            inc(score, param.capt[i] * hole[rootplayer,i]);
            inc(score, param.capt[i] * hole[1-rootplayer,7-i]);
         end;
      end;

      // own nyumba
      // Admissiblity:  forget about onwning nyumba
      if ownsnyumba[rootplayer] then inc(score,param.ownsnyumba);
      if ownsnyumba[1-rootplayer]then  inc(score,param.ownsnyumba);
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


// -------------
// genetic algorithm
// ---------------

// population
const ChromSize = 27;
var PopSize: integer;
type TIchromosome = record
   dat: array[0..ChromSize-1] of integer;
   evaluated: boolean;
   fitness: integer;
end;

type Tpopulation = record
   chr: array of TIChromosome;
   order: array of integer;
end;

function rand(i: integer): integer;
begin
  rand := integer(floor(GenRandMT*i)) - i div 2;
end;

procedure generate_population(var pop: Tpopulation);
var i,j: integer;
begin
   setlength(pop.chr,popsize);
   setlength(pop.order,popsize);
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


procedure adapt(var chr: TIchromosome);
var i: integer;
begin
   i:=floor(GenRandMT*ChromSize); inc(chr.dat[i],rand(5)-rand(5));
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
      store:=chr.dat[i]; inc(i);
      for j:=0 to 15 do begin
        hole[j]:=chr.dat[i]; inc(i);
      end;
      // captures
      captnyumba:=chr.dat[i]; inc(i);
      for j:=0 to 7 do begin
        capt[j]:=chr.dat[i]; inc(i);
      end;
      // own nyumba
      ownsnyumba:=chr.dat[i];
   end;
end;

function checkmost(pos: TBAoPosition): integer;
var i: integer;
    tot: array[0..1] of integer;
begin
   tot[0]:=0; tot[1]:=0;
   for i:=0 to 15 do begin
      inc(tot[0],pos.hole[0,i]);
      inc(tot[1],pos.hole[1,i]);
   end;
   checkmost:=north;
   if tot[0]>tot[1] then checkmost:=south;
end;

function test(var chr: TIchromosome; depth: integer; input: string; maxmove: integer): boolean;
var pos: TBaoPosition;
    move: TBaoMove;
    play: integer;
    inp: Text;
    spos: string;
    num: integer;
begin
   if chr.evaluated then begin
      write('-'); test:=false; exit;
   end;
   set_eval(parama,chr);
   chr.fitness:=0;
   assign(inp,input);
   reset(inp);
   repeat
    readln(inp,spos);
    pos := strtopos(spos);
    game_score := -99999;
    play := SOUTH;
    num:=0;
    clear_hashtable;
    repeat
      set_evaluator(@evaluate_a);
      switch_hashtable(0);
      search(pos,depth,100,false);
      move:=get_bestmove;
      pos := execute_move(pos,move,false);
      if (not endofgame(pos)) then begin
         play:=1-play;
         set_evaluator(@o_eval);
         switch_hashtable(1);
         search(pos,depth,100,false);
         move:=get_bestmove;
         pos := execute_move(pos,move,false);
         inc(num);
     end;
   until endofgame(pos) or (num>maxmove);

   if endofgame(pos) then begin
     if checkwinner(pos)=south then begin
        write('!');
        inc(chr.fitness);
     end else write('X');
   end else begin
     if checkmost(pos)=south then begin
        write('!');
        inc(chr.fitness);
     end else write('X');
   end;

  until eof(inp);
  chr.evaluated:=true;
  test:=true;
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

function isnew(chr: TIchromosome; pop: Tpopulation): boolean;
var i,j: integer;
    found: boolean;
begin
   for j:=0 to PopSize-1 do begin
      found:=true;
      for i:=0 to ChromSize-1 do
         if pop.chr[j].dat[i]<>chr.dat[i] then begin found:=false; break; end;
      if found then begin
         isnew:=false;
         exit;
      end;
    end;
   isnew:=true;
   exit;
end;

procedure comm_gen(params: array of string);
var pop: TPopulation;
    generation,nr,i,ii,j,jj,totfit: integer;
    chr1,chr2: TIChromosome;
    depth,moves,keep: integer;
    opp_eval: string;

begin
  depth := 6;
  if (high(params)>=1) then begin
     depth := strtoint(params[1]);
  end;
  moves := 5;
  if (high(params)>=2) then begin
     moves := strtoint(params[2]);
  end;
  popsize:=100;
  if (high(params)>=3) then begin
     popsize := strtoint(params[3]);
  end;

  keep:=30;
  if (high(params)>=4) then begin
     keep := strtoint(params[4]);
  end;

  opp_eval:='default';
  if (high(params)>=5) then begin
     opp_eval := params[5];
  end;

  o_eval := getevaluator(opp_eval);


   if not FileExists('result.txt') then begin
      AssignFile(log,'result.txt');
      rewrite(log);
      Writeln(log,'Genexp 4: search depth '+inttostr(depth)+
                  ', moves ahead '+inttostr(moves)+
                  ', popsize '+inttostr(popsize)+
                  ', keep '+inttostr(keep)+
                  ', play against '+opp_eval);
      writeln(log);
      close(log);
   end;


   init_search;
   make_hashtables(2,20);
//   disable_hash;
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

      repeat
         Write('chr '+inttostr(nr)+': ');
         if test(pop.chr[nr],depth,'startpos.txt',moves) then
            store_population(pop,generation,nr);
         Write(' ',inttostr(pop.chr[nr].fitness),'; ');
         inc(nr);
      until nr>=PopSize;

      totfit:=0;
      for i:=0 to PopSize-1 do
         inc(totfit,pop.chr[i].fitness);

      sort_population(pop);

      writeln;
      write('Average fitness: ');
      write(totfit*1.0/PopSize,' ');
      write('Max fitness: ');
      writeln(pop.chr[pop.order[0]].fitness);

      AssignFile(log,'result.txt');
      append(log);
      write(log,generation,' ');
      write(log,'Average fitness: ');
      write(log,totfit*1.0/PopSize,' ');
      write(log,'Max fitness: ');
      writeln(log,pop.chr[pop.order[0]].fitness);
      close(log);


      // best <keep> for parents
      for nr:=0 to keep do begin
         i:=pop.order[nr];
         repeat
            j:= pop.order[integer(floor(GenRandMT*10))];
         until i<>j;
         ii:=pop.order[PopSize-1-nr*2];
         jj:=pop.order[PopSize-2-nr*2];
         chr1:=pop.chr[i];
         chr2:=pop.chr[j];
         repeat
            cross(chr1,chr2);
            if GenRandMT<0.05 then mutate(chr1);
            if GenRandMT<0.05 then mutate(chr2);
            if GenRandMT<0.2 then adapt(chr1);
            if GenRandMT<0.2 then adapt(chr2);
         until isnew(chr1,pop) and isnew(chr2,pop);
         pop.chr[ii]:=chr1;
         pop.chr[jj]:=chr2;
      end;
      inc(generation);
      nr:=0;
   until generation>1000;
end;


begin
   registercommand(@comm_gen,'genexp4');
end.
