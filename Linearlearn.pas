unit Linearlearn;

interface

implementation
uses global,sysutils,mersenne,engine,math;

const NParams = 54;
      def_delta = 1;
      def_beta = 0.025;
      def_lambda = 0.99;
      def_alpha0 = 0.1;
      def_anneal = 0.993;
      def_gamesperrun = 25;
      def_avgupdlimit = 1;
      def_searchdepth = 4;



type TevalParams = record
   store: array[0..1] of double;
   hole: array[0..1,0..15] of double;
   capt: array[0..1,0..7] of double;
   ownsnyumba: array[0..1] of double;
   captnyumba: array[0..1] of double;
end;


type TParamVector = array[1..NParams] of double;

type TGameLogRec = record
    pos: TBaoPosition;
    PV: TBaoMoveList;
    oppmove: TBaoMove;
    leafpos: TBaoPosition;
    score: integer;
    leafscore: integer;
    r,td: double;
    use: boolean;
    ended: boolean;
    deriv: TParamVector;
end;

type TGameLog = array of TGameLogRec;

var ourparam, ourparamdelta, update, opparam: TParamVector;
    param, opp: TEvalParams;
    subtotupdate,totupdate,avgupdate,avgparam: double;
    o_eval: evaluator;
    alpha: double;
    delta: double;
    beta: double;
    lambda: double;
    alpha0: double;
    anneal: double;
    gamesperrun: integer;
    avgupdlimit: double;
    searchdepth: integer;
    weakopponent: boolean;


function evaluate(pos: TBaoPosition): integer;
var score: double; i: integer;
begin
   with pos do begin
      score:=0;

      score:=score+param.store[0]*store[rootplayer];
      score:=score+param.store[1]*store[1-rootplayer];
      for i:=0 to 15 do begin
         score:=score+param.hole[0,i]*hole[rootplayer,i];
         score:=score+param.hole[1,i]*hole[1-rootplayer,i];
      end;

      // captures
      for i:=0 to 7 do begin
         if (hole[rootplayer,i]>0) and (hole[1-rootplayer,7-i]>0) then begin
            if (7-i=NYUMBA) and ownsnyumba[1-rootplayer] then score:=score+param.captnyumba[0];
            if (i=NYUMBA) and ownsnyumba[rootplayer] then score:=score+param.captnyumba[1];
            score:=score+param.capt[0,i] * hole[rootplayer,i];
            score:=score+param.capt[1,i] * hole[1-rootplayer,7-i];
         end;
      end;

      // own nyumba
      // Admissiblity:  forget about onwning nyumba
      if ownsnyumba[rootplayer] then score:=score+param.ownsnyumba[0];
      if ownsnyumba[1-rootplayer]then  score:=score+param.ownsnyumba[1];
   end;
   if round(score)=0 then score:=1.01;
   if score<-9000 then score :=-9000;
   if score>9000 then score := 9000;
   evaluate:=round(score);
end;

function evaluate_opp(pos: TBaoPosition): integer;
var score: double; i: integer;
begin
   with pos do begin
      score:=0;

      score:=score+opp.store[0]*store[rootplayer];
      score:=score+opp.store[1]*store[1-rootplayer];
      for i:=0 to 15 do begin
         score:=score+opp.hole[0,i]*hole[rootplayer,i];
         score:=score+opp.hole[1,i]*hole[1-rootplayer,i];
      end;

      // captures
      for i:=0 to 7 do begin
         if (hole[rootplayer,i]>0) and (hole[1-rootplayer,7-i]>0) then begin
            if (7-i=NYUMBA) and ownsnyumba[1-rootplayer] then score:=score+opp.captnyumba[0];
            if (i=NYUMBA) and ownsnyumba[rootplayer] then score:=score+opp.captnyumba[1];
            score:=score+opp.capt[0,i] * hole[rootplayer,i];
            score:=score+opp.capt[1,i] * hole[1-rootplayer,7-i];
         end;
      end;

      // own nyumba
      // Admissiblity:  forget about onwning nyumba
      if ownsnyumba[rootplayer] then score:=score+opp.ownsnyumba[0];
      if ownsnyumba[1-rootplayer]then  score:=score+opp.ownsnyumba[1];
   end;
   if round(score)=0 then score:=1.01;
   if score<-9000 then score :=-9000;
   if score>9000 then score := 9000;
   evaluate_opp:=round(score);
end;




procedure set_eval(p: TParamVector; var par: TEvalparams);
var i,j: integer;
begin
   i:=1;
   with par do begin
      store[0]:=p[i]; inc(i);
      store[1]:=p[i]; inc(i);
      for j:=0 to 15 do begin
        hole[0,j]:=p[i]; inc(i);
        hole[1,j]:=p[i]; inc(i);
      end;
      // captures
      captnyumba[0]:=p[i]; inc(i);
      captnyumba[1]:=p[i]; inc(i);
      for j:=0 to 7 do begin
        capt[0,j]:=p[i]; inc(i);
        capt[1,j]:=p[i]; inc(i);
      end;
      // own nyumba
      ownsnyumba[0]:=p[i]; inc(i);
      ownsnyumba[1]:=p[i];
   end;
end;


function eval(pos: TBaoPosition; p: TParamVector): integer;
begin
   set_eval(p,param);
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
         if log[num].use then log[num].oppmove:=move;
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
       if weakopponent and (movetostr(log[i].PV[1],rootplayer)<>movetostr(log[i].oppmove,rootplayer)) then
         log[i].td := 0
       else
         log[i].td := log[i+1].r - log[i].r
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

function readparams(var par: TparamVector; name: string): boolean;
var k: integer;
    f: text;
begin
   readparams:=false;
   assign(f,name);
   {$I-}
   reset(f);
   if ioresult<>0 then exit;
   for k:=1 to Nparams do begin
      readln(f,par[k]);
      if ioresult<>0 then begin close(f); exit; end;
   end;
   close(f);
   {$I+}
   readparams:=true;
end;


procedure storeparams(round, wins: integer);
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
    weakopponent:=false;
    delta:=def_delta;
    beta:=def_beta;
    lambda:=def_lambda;
    alpha0:=def_alpha0;
    anneal:=def_anneal;
    gamesperrun:=def_gamesperrun;
    avgupdlimit:=def_avgupdlimit;
    searchdepth:=def_searchdepth;

    for i:=1 to length(params) div 2 do begin
       if      params[2*i-1]='delta' then delta:=strtofloat(params[2*i])
       else if params[2*i-1]='lambda' then lambda:=strtofloat(params[2*i])
       else if params[2*i-1]='alpha' then alpha0:=strtofloat(params[2*i])
       else if params[2*i-1]='beta' then beta:=strtofloat(params[2*i])
       else if params[2*i-1]='anneal' then anneal:=strtofloat(params[2*i])
       else if params[2*i-1]='limit' then avgupdlimit:=strtofloat(params[2*i])
       else if params[2*i-1]='run' then gamesperrun:=strtoint(params[2*i])
       else if params[2*i-1]='depth' then searchdepth:=strtoint(params[2*i])
       else if params[2*i-1]='weak' then if params[2*i]='true' then weakopponent:=true;
    end;


   assign(f,'tdl.xls');  rewrite(f);  close(f);

   if not readparams(ourparam,'param.txt') then begin
      for i:=1 to NParams do begin
        ourparam[i]:=0;
      end;
   end;

   if readparams(opparam,'opp.txt') then begin
       set_eval(opparam,opp);
       o_eval:=@evaluate_opp;
   end else
       o_eval:=getevaluator('ga3');

   init_search;
   make_hashtables(2,20);
   run:=1; round:=1; wins:=0;
   write(inttostr(round)+' ');
   clear_updates;
   alpha:=alpha0;
   repeat
      set_eval(ourparam,param);
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
         storeparams(round,wins);
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
   registercommand(@comm_tdltest,'tdl');
end.
