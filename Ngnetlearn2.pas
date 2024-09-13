unit Ngnetlearn2;

interface

implementation
uses global,sysutils,mersenne,engine,math;

const NInputs = 54;
      def_delta = 0.1;
      def_beta = 0.005;
      def_lambda = 0.8;
      def_alpha0 = 0.01;
      def_alphamu0 = 0.0005;
      def_anneal = 0.993;
      def_gamesperrun = 25;
      def_numstore = 25;
      def_avgupdlimit = 100;
      def_searchdepth = 6;
      def_sigma = 0.05;



type TNGnet = record
   sigma: double;
   w: array[1..NInputs] of double;
   mu: array[1..NInputs, 1..NInputs] of double;
end;

{$I ngn_d6.inc}

var ourgn, update: TNGnet;
    subtotupdate,totupdate,avgupdate,avgparam: double;
    o_eval: evaluator;
    alpha: double;
    alphamu: double;
    alpha0: double;
    alphamu0: double;
    delta: double;
    beta: double;
    lambda: double;
    anneal: double;
    gamesperrun,numstore: integer;
    avgupdlimit: double;
    searchdepth: integer;
    weakopponent: boolean;
    nobatch: boolean;
    minscore, maxscore: integer;


type TInputVector = array[1..NInputs] of double;

type TGameLogRec = record
    pos: TBaoPosition;
    PV: TBaoMoveList;
    oppmove: TBaomove;
    leafpos: TBaoPosition;
    score: integer;
    leafscore: integer;
    r,td: double;
    use: boolean;
    ended: boolean;
    s,g: TInputVector;
end;

type TGameLog = array of TGameLogRec;

procedure computeOutputs(const x: TInputVector; const ng: TNGnet; var g: TInputVector);
var i,j: integer;
    q,tmp,tot: double;
begin
    with ng do begin
      q:=sqrt(2*pi*sigma*sigma);
      tot:=0;
      for i:=1 to NINputs do begin
         tmp:=0;
         for j:=1 to NInputs do tmp:=tmp+(x[j]-mu[i,j])*(x[j]-mu[i,j]);
         tmp:= tmp/(2.0*sigma*sigma);
         tmp:=exp(-tmp);
         g[i]:=tmp/q;
         tot:=tot+g[i];
      end;
      if tot<>0 then
         for i:=1 to NINputs do g[i]:=g[i]/tot;
    end;
end;


function evaluateNgNet(const x: TInputVector; const ng: TNGnet): double;
var i: integer;
    tmp: double;
    g: TInputVector;
begin
    computeOutputs(x,ng,g);
    with ng do begin
      tmp:=0;
      for i:=1 to NINputs do tmp:=tmp+w[i]*g[i];
    end;
    result:=tmp;
end;

procedure makeinput(pos: TBaoPosition; var g: TInputvector);
var i,j: integer;
begin
   j:=1;
   with pos do begin
      g[j]:=1.0*store[rootplayer]/64.0; inc(j);
      g[j]:=1.0*store[1-rootplayer]/64.0; inc(j);      
      for i:=0 to 15 do begin
         g[j]:=1.0*hole[rootplayer,i]/64.0; inc(j);
         g[j]:=1.0*hole[1-rootplayer,i]/64.0; inc(j);
      end;

       for i:=0 to 7 do begin
         if (hole[rootplayer,i]>0) and (hole[1-rootplayer,7-i]>0) then begin
            g[j]:=1.0*hole[rootplayer,i]/64.0; inc(j);
            g[j]:=1.0*hole[1-rootplayer,7-i]/64.0; inc(j);
         end else begin
            g[j]:=0; inc(j);
            g[j]:=0; inc(j);
         end;
      end;

      if ownsnyumba[rootplayer] then g[j]:=0.1 else g[j]:=0;
      inc(j);
      if ownsnyumba[1-rootplayer] then g[j]:=0.1 else g[j]:=0;
      inc(j);

      if (hole[rootplayer,7-NYUMBA]>0) and (hole[1-rootplayer,NYUMBA]>0) and
            ownsnyumba[1-rootplayer] then g[j]:=0.1 else g[j]:=0;
      inc(j);
      if (hole[1-rootplayer,NYUMBA]>0) and (hole[rootplayer,7-NYUMBA]>0) and
             ownsnyumba[rootplayer] then g[j]:=0.1 else g[j]:=0;

   end;
end;



function eval(pos: TBaoPosition; ng: TNGnet): integer;
var score: integer;
    g: TInputVector;
begin
   makeInput(pos,g);
   score:=trunc(10000*evaluateNgNet(g,ng));
   if score=0 then score:=1;
   if score<-9000 then begin {write('underflow'); halt; } score:=-9000; end;
   if score>9000 then begin {write('overflow'); halt; } score:=+9000; end;
   if score<minscore then minscore:=score;
   if score>maxscore then maxscore:=score;
   eval:=score;
end;


function evaluate(pos: TBaoPosition): integer;
begin
   evaluate := eval(pos,ourgn);
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
     minscore:=10000;
     maxscore:=-10000;
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
      inc(num);
      if (not endofgame(pos)) then begin
         set_evaluator(@o_eval);
         switch_hashtable(1);
         search(pos,depth,100,false);
         move:=get_bestmove;
         if log[num].use then log[num].oppmove:=move;
         pos := execute_move(pos,move,false);
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
         log[i].td := log[i+1].r - log[i].r;
       makeinput(log[i].leafpos,log[i].s);
       computeOutputs(log[i].s,ourgn,log[i].g);
   end;
end;


procedure clear_updates();
var k,kk: integer;
begin
   for k:=1 to NINputs do begin
      update.w[k]:=0;
      for kk:=1 to NINputs do begin
          update.mu[k,kk]:=0;
      end;
   end;
end;

procedure collect_updates(const log: TGameLog; var haswon: boolean);
var i,j,k,kk,n: integer;
    signal,l,fac,v: double;
begin
   subtotupdate:=0;
   n:=length(log);
   // compute updates
   for k:=1 to NINputs do begin
      for i:=1 to n-1 do begin
         signal:=0; l:=1;
         for j:=i to n-1 do begin
            signal := signal + l*log[j-1].td;
            l := lambda * l;
         end;
         update.w[k]:=update.w[k]+log[i-1].g[k]*signal;
         v:=evaluateNgNet(log[i-1].s,ourgn);
         fac:=log[i-1].g[k]*signal*(ourgn.w[k]-v)/(ourgn.sigma*ourgn.sigma);
         for kk:=1 to NINputs do begin
            update.mu[k,kk]:=update.mu[k,kk]+fac*(log[i-1].s[kk]-ourgn.mu[k,kk]);
         end;
      end;
   end;
end;

procedure apply_updates();
var k,kk: integer;
begin
   avgparam:=0;
   for k:=1 to NINputs do begin
      ourgn.w[k]:=ourgn.w[k]+alpha*update.w[k];
      avgparam:=avgparam+ourgn.w[k];
      update.w[k]:=0;
      for kk:=1 to NINputs do begin
         ourgn.mu[k,kk]:=ourgn.mu[k,kk]+alphamu*update.mu[k,kk];
         avgparam:=avgparam+ourgn.mu[k,kk];
         update.mu[k,kk]:=0;
      end;
   end;
   avgparam:=avgparam/(NINputs*(NINputs+1));
end;


procedure sizeof_update();
var k,kk: integer;
    tot: double;
begin
   tot:=0; avgupdate:=0;
   for k:=1 to NINputs do begin
      tot:=tot+(alpha*update.w[k]*alpha*update.w[k]);
      avgupdate:=avgupdate+alpha*update.w[k];
      for kk:=1 to NINputs do begin
         tot:=tot+(alpha*update.mu[k,kk]*alpha*update.mu[k,kk]);
         avgupdate:=avgupdate+alpha*update.mu[k,kk];
      end;
   end;
   totupdate:=sqrt(tot);
   avgupdate:=avgupdate/(NINputs*(NINputs+1));
end;



procedure storenet(round, wins: integer);
var k,kk: integer;
    f: text;
begin
   assign(f,'ngn.xls');
   append(f);
   for k:=1 to NINputs do begin
      write(f,ourgn.w[k],chr(9));
   end;
   writeln(f);
   close(f);
   assign(f,'ngnmu.xls');
   append(f);
   write(f,round,chr(9),wins,chr(9));
   for k:=1 to NINputs do begin
      for kk:=1 to NINputs do
         write(f,ourgn.mu[k,kk],chr(9));
   end;
   writeln(f);
   close(f);
end;

procedure comm_ngntest(params: array of string);
var i,run,round,wins: integer;
    haswon: boolean;
    log: TGameLog;
    f: Text;
begin
    weakopponent:=true;
    delta:=def_delta;
    beta:=def_beta;
    lambda:=def_lambda;
    alpha0:=def_alpha0;
    alphamu0:=def_alphamu0;
    anneal:=def_anneal;
    gamesperrun:=def_gamesperrun;
    numstore:=def_numstore;
    avgupdlimit:=def_avgupdlimit;
    searchdepth:=def_searchdepth;
    ourgn.sigma:=def_sigma;
    nobatch:=true;

    for i:=1 to length(params) div 2 do begin
       if      params[2*i-1]='delta' then delta:=strtofloat(params[2*i])
       else if params[2*i-1]='lambda' then lambda:=strtofloat(params[2*i])
       else if params[2*i-1]='alpha' then alpha0:=strtofloat(params[2*i])
       else if params[2*i-1]='alphamu' then alphamu0:=strtofloat(params[2*i])
       else if params[2*i-1]='beta' then beta:=strtofloat(params[2*i])
       else if params[2*i-1]='anneal' then anneal:=strtofloat(params[2*i])
       else if params[2*i-1]='limit' then avgupdlimit:=strtofloat(params[2*i])
       else if params[2*i-1]='run' then gamesperrun:=strtoint(params[2*i])
       else if params[2*i-1]='depth' then searchdepth:=strtoint(params[2*i])
       else if params[2*i-1]='sigma' then ourgn.sigma:=strtofloat(params[2*i])
       else if params[2*i-1]='weak' then if params[2*i]='true' then weakopponent:=true;
    end;

//   RandomizeMT;
//   for i:=1 to NINputs do begin
//      ourgn.w[i]:=(genrandMT-0.5)/100;
//      for j:=1 to NINputs do ourgn.mu[i,j]:=(genrandMT-0.5)/100;
//   end;

   ourgn:=ngn_d6;

   assign(f,'ngn.xls');  rewrite(f);  close(f);
   assign(f,'ngnmu.xls');  rewrite(f);  close(f);

   o_eval:=getevaluator('ngnd6');
   init_search;
   make_hashtables(2,20);
   run:=1; round:=1; wins:=0;
   write(inttostr(round)+' ');
   alpha:=alpha0;
   alphamu:=alphamu0;

   clear_updates;
   repeat
      haswon:=play(searchdepth,BAO_OFFICIALOPENING,log);
      if haswon then begin
         write('!'); inc(wins);
      end else write('X');


      analyse(log);
      collect_updates(log,haswon);
      if run mod gamesperrun = 0 then begin
         write(' wins: ',wins);
         sizeof_update();

         if run mod numstore = 0 then storenet(round,wins);
         if abs(avgupdate)<avgupdlimit then
           apply_updates()
         else begin
           clear_updates();
           totupdate:=0;
           avgupdate:=0;
         end;
         writeln(' ',Format('%8.6f',[totupdate]),' ',Format('%8.6f',[avgupdate]),' ',minscore,' ',maxscore);
         inc(round); wins:=0;
         write(round,' ');
         alpha:=alpha*anneal;
         alphamu:=alphamu*anneal;
       end else if nobatch then begin
         if abs(avgupdate)<avgupdlimit then
           apply_updates()
         else begin
           clear_updates();
           totupdate:=0;
           avgupdate:=0;
         end;
       end;
      inc(run);
    until false;
end;


procedure  comm_ngnexport(params: array of string);
var f,g: text;
    n: TNGnet;
    i,j: integer;
begin
   assign(f,'ngn_'+params[1]+'.xls');
   reset(f);
   assign(g,'ngnmu_'+params[1]+'.xls');
   reset(g);
   repeat
      read(g,n.mu[1,1]);  //dummy
      read(g,n.mu[1,1]);  //dummy
      for i:=1 to NINPUTs do begin
         read(f,n.w[i]);
         for j:=1 to NINPUTs do read(g,n.mu[i,j]);
      end;
      readln(f);
      readln(g);
   until eof(f);
   close(f);
   close(g);
   assign(f,'ngn_'+params[1]+'.inc');
   rewrite(f);
   writeln(f,'const ngn_'+params[1]+': TNGnet = (sigma: ',def_sigma,'; w: (');
   for i:=1 to NINPUTs do begin
       write(f,'    ',n.w[i]);
       if i<NINPUTs then writeln(f,',') else writeln(f,');')
   end;
   writeln(f,' mu: (');
   for j:=1 to NINPUTs do begin
     for i:=1 to NINPUTs do begin
        if i=1 then  write(f,'    (') else write(f,'    ');
        write(f,n.mu[j,i]);
        if i<NINPUTs then writeln(f,',')
        else if j<NINPUTs then writeln(f,'),')
        else writeln(f,')')
     end;
   end;
   writeln(f,' ));');
   close(f);
end;


begin
   registercommand(@comm_ngntest,'ngn');
   registercommand(@comm_ngnexport,'ngnexport');
end.
