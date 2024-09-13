unit Linearlearn2;

interface

implementation
uses global,sysutils,mersenne,engine,math;

const NParams = 26;
      delta = 1;
      beta = 0.025;
      lambda = 0.99;
      alpha0 = 0.1;
      anneal = 0.99;
      gamesperrun = 25;
      avgupdlimit = 10;
      searchdepth = 4;



type TevalParams = record
   hole: array[0..15] of double;
   capt: array[0..7] of double;
   ownsnyumba: double;
   captnyumba: double;
end;


type TParamVector = array[1..NParams] of double;

type TGameLogRec = record
    pos: TBaoPosition;
    PV: TBaoMoveList;
    leafpos: TBaoPosition;
    score: integer;
    leafscore: integer;
    r,td: double;
    use: boolean;
    ended: boolean;
    deriv: TParamVector;
end;

type TGameLog = array of TGameLogRec;

var ourparam, ourparamdelta, update: TParamVector;
    param: TEvalParams;
    subtotupdate,totupdate,avgupdate,avgparam: double;
    o_eval: evaluator;
    alpha: double;


function evaluate(pos: TBaoPosition): integer;
var score: double; i: integer;
begin
   with pos do begin
      score:=0;
      for i:=0 to 15 do begin
         score:=score+param.hole[i]*hole[rootplayer,i];
         score:=score-param.hole[i]*hole[1-rootplayer,i];
      end;
      // captures
      for i:=0 to 7 do begin
         if (hole[rootplayer,i]>0) and (hole[1-rootplayer,7-i]>0) then begin
            if (7-i=NYUMBA) and ownsnyumba[1-rootplayer] then score:=score+param.captnyumba;
            if (i=NYUMBA) and ownsnyumba[rootplayer] then score:=score-param.captnyumba;
            score:=score+param.capt[i] * hole[rootplayer,i];
            score:=score-param.capt[i] * hole[1-rootplayer,7-i];
         end;
      end;
      if ownsnyumba[rootplayer] then score:=score+param.ownsnyumba;
      if ownsnyumba[1-rootplayer]then  score:=score-param.ownsnyumba;
   end;
   if round(score)=0 then score:=1.01;
   if score<-9000 then score :=-9000;
   if score>9000 then score := 9000;
   evaluate:=round(score);
end;


procedure set_eval(p: TParamVector);
var i,j: integer;
begin
   i:=1;
   with param do begin
      for j:=0 to 15 do begin
        hole[j]:=p[i]; inc(i);
      end;
      // captures
      for j:=0 to 7 do begin
        capt[j]:=p[i]; inc(i);
      end;
      ownsnyumba:=p[i]; inc(i);
      captnyumba:=p[i];
   end;
end;


function eval(pos: TBaoPosition; p: TParamVector): integer;
begin
   set_eval(p);
   eval:=evaluate(pos);
end;


procedure executePV(var pos: TBaoPosition; const pv: TBaoMoveList);
var i: integer;
begin
   for i:=0 to length(pv)-1 do execute_move(pos,pv[i],false);
end;

function play(depth: integer; startpos: TBaoPosition; var log: TGameLog): boolean;
var pos: TBaoPosition;
    move: TBaoMove;
    i,j,num: integer;
    moves: TBaoMoveList;
begin
     setlength(log,250);
     repeat
     pos := startpos;
     for j:=1 to 10 do begin
       moves := legal_moves(pos,100,false);
       i := floor(GenRandMT*length(moves));
       pos := execute_move(pos,moves[i],false);
       if  endofgame(pos) then break;
    end;
    until not endofgame(pos);

    game_score := -99999;
    num:=0;
    clear_hashtable;
    repeat
      set_evaluator(@evaluate);
      switch_hashtable(0);
      log[num].pos:=pos;
      search(pos,depth,100,false);
      log[num].use:=searched;
      if searched then begin
        log[num].score:=game_score;
        log[num].pv:=get_pv;
      end;
      move:=get_bestmove;
      pos := execute_move(pos,move,false);
//      write(inttostr(num+1)+': '+movetostr(move,SOUTH)+' ');
      inc(num);
      if (not endofgame(pos)) then begin
         set_evaluator(@o_eval);
         switch_hashtable(1);
         search(pos,depth,100,false);
         move:=get_bestmove;
         pos := execute_move(pos,move,false);
//         write(movetostr(move,NORTH)+'; ');
     end;
   until endofgame(pos);
   if checkwinner(pos)=startpos.player then begin
      play:=true;
      log[num].score:=10000
   end else begin
      play:=false;
      log[num].score:=-10000;
   end;
   log[num].use:=true;
   setlength(log,num+1);
//   writeln;
end;


function reward(score: double): double;
begin
   if score>9000 then reward:=1 else
   if score<-9000 then reward:=-1 else
   reward:=tanh(beta*score);
end;

procedure analyse(var log: TGameLog);
var i,j,n: integer;
begin
   n:=0;
   for i:=0 to length(log)-1 do with log[i] do begin
       if abs(score)>9000 then begin
          use:=true;
          ended:=true;
          r:=reward(score);
          n:=i;
          td:=0;
          break;
       end else begin
          ended:=false;
          rootplayer:=pos.player;
          leafpos:=pos;
          for j:=0 to length(pv)-1 do
            leafpos := execute_move(leafpos,pv[j],false);
          leafscore:=evaluate(leafpos);
          if leafscore<>score then use:=false;
          r:=reward(leafscore);
       end;
   end;
   j:=0;
   for i:=0 to n do begin
      if log[i].use then begin
         log[j]:=log[i]; inc(j);
      end;
   end;
   n:=j;
   setlength(log,n);

   for i:=0 to n-2 do begin
      log[i].td := log[i+1].r - log[i].r;
   end;
end;

procedure derivs(var log: TGameLog);
var i,k,n: integer;
begin
   n:=length(log);
   // compute partial deriviates
   for i:=1 to NParams do begin
      ourparamdelta:=ourparam;
      ourparamdelta[i]:=ourparamdelta[i]+delta;
      for k:=0 to n-2 do begin
         rootplayer:=log[k].pos.player;
         log[k].deriv[i]:=(reward(eval(log[k].leafpos,ourparamdelta))-log[k].r)/delta;
      end;
   end;
end;


procedure clear_updates();
var k: integer;
begin
   for k:=1 to NParams do update[k]:=0;
end;

procedure collect_updates(const log: TGameLog);
var i,j,k,n: integer;
    sum,l,tot: double;
begin
   n:=length(log);
   tot:=0;
   // compute updates
   for k:=1 to NParams do begin
      for i:=1 to n-1 do begin
         sum:=0; l:=1;
         for j:=i to n-1 do begin
            sum := sum + l*log[j-1].td;
            l := lambda * l;
         end;
         tot:=tot+(log[i-1].deriv[k]*sum)*(log[i-1].deriv[k]*sum);
         update[k]:=update[k]+log[i-1].deriv[k]*sum;
      end;
   end;
   subtotupdate:=tot;
end;

procedure apply_updates();
var k: integer;
begin
   avgparam:=0;
   for k:=1 to NParams do begin
      ourparam[k]:=ourparam[k]+(alpha*update[k]);
      avgparam:=avgparam+ourparam[k];
      update[k]:=0;
   end;
   avgparam:=avgparam/Nparams;
end;


procedure sizeof_update();
var k: integer;
    tot: double;
begin
   tot:=0; avgupdate:=0;
   for k:=1 to NParams do begin
      tot:=tot+(alpha*update[k]*alpha*update[k]);
      avgupdate:=avgupdate+alpha*update[k];
   end;
   totupdate:=sqrt(tot);
   avgupdate:=avgupdate/NParams;
end;



procedure storenet(round, wins: integer);
var k: integer;
    f: text;
begin
   assign(f,'tdl.xls');
   append(f);
   write(f,round,chr(9),wins,chr(9),totupdate,chr(9),avgupdate);
   for k:=1 to Nparams do begin
      write(f,chr(9),ourparam[k]);
   end;
   writeln(f);
   close(f);
end;

procedure comm_tdltest(params: array of string);
var i,run,round,wins: integer;
    log: TGameLog;
    f: Text;
begin
   assign(f,'tdl.xls');  rewrite(f);  close(f);
   assign(f,'result.txt');  rewrite(f);  close(f);

   RandomizeMT;
   for i:=1 to NParams do begin
      ourparam[i]:=0;
   end;
   o_eval:=getevaluator('ga3');
   init_search;
   make_hashtables(2,20);
   run:=1; round:=1; wins:=0;
   write(inttostr(round)+' ');
   clear_updates;
   alpha:=alpha0;
   repeat
      set_eval(ourparam);
      if play(searchdepth,BAO_OFFICIALOPENING,log) then begin
         write('!'); inc(wins);
      end else write('X');

      analyse(log);
      derivs(log);
      collect_updates(log);

      clear_hashtable;

      if run mod gamesperrun = 0 then begin
         write(' wins: ',wins);

         sizeof_update();
         storenet(round,wins);
         AssignFile(f,'result.txt');
         append(f);
         writeln(f,round,' ',wins);
         close(f);

         if abs(avgupdate)<avgupdlimit then
           apply_updates()
         else begin
           clear_updates();
           totupdate:=0;
           avgupdate:=0;
         end;
         writeln(' ',Format('%8.6f',[totupdate]),' ',Format('%8.6f',[avgupdate]),' ',Format('%8.6f',[alpha]));
         inc(round); wins:=0;
         write(round,' ');
         alpha:=alpha*anneal;
       end;
      inc(run);
    until false;
end;


begin
   registercommand(@comm_tdltest,'tdl2');
end.
