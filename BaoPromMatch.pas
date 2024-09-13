unit BaoPromMatch;

interface

implementation

uses
  SysUtils,
  Math,
  classes,
  winprocs,
  Engine,
  global,
  Mersenne,
  randpos;

procedure output(s: string);
begin
//  writeln(s);
end;

var logname: string = 'log.txt';
var reslogname: string = 'result.txt';
var reslog,log: Text;
var dolog: boolean;
var evalopp: evaluator;
var eval: array of evaluator;
var prob: array of double;
var evaloppname: string;
var evalname: array of string;

procedure createlog(name: string);
begin
   dolog:=false;
   logname:=name;
   AssignFile(log,logname);
   {$I-}
   rewrite(log);
   {$I+}
   if IOresult<>0 then begin writeln('cannot log'); exit; end;
   dolog:=true;
end;

procedure writelog(s: string);
begin
   if dolog then write(log,s);
end;

procedure writelnlog(s: string);
begin
   if dolog then writeln(log,s);
end;


procedure writereslog(s: string);
begin
   AssignFile(reslog,reslogname);
   {$I-}
   append(reslog);
   {$I+}
   if IOresult<>0 then begin writeln('cannot append reslog'); exit; end;
   writeln(reslog,s);
   close(reslog);
end;

procedure createreslog(name: string);
begin
   reslogname:=name;
   AssignFile(reslog,reslogname);
   {$I-}
   rewrite(reslog);
   {$I+}
   if IOresult<>0 then begin writeln('cannot log to reslog'); exit; end;
   writeln(reslog,' ');
   close(reslog);
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

procedure basictest(input: string; depth: integer; stime: integer; playsouth: boolean);
var pos: TBaoPosition;
    move: TBaoMove;
    play: integer;
    i,nr,ns,nn: integer;
    inp: Text;
    spos,s: string;
begin
  writereslog('input = '+input);
  writereslog('search depth = ' + inttostr(depth));
  writereslog('search time = ' + inttostr(stime)+' sec.');
  s:='[';
  for i:=0 to high(evalname) do s:=s+evalname[i]+' '+formatfloat('#.##',prob[i])+' ';
  s:=s+']';
  writereslog(s+' vs. '+evaloppname);

  writelnlog('input = '+input);
  writelnlog('search depth = ' + inttostr(depth));
  writelnlog('search time = ' + inttostr(stime)+' sec.');
  writelnlog(s+' vs. '+evaloppname);

  assign(inp,input);
  reset(inp);
  nr:=0; ns:=0; nn:=0;
  repeat
   inc(nr);
   writeln(inttostr(nr)+': ');
   writelnlog(inttostr(nr)+': ');
   readln(inp,spos);
   pos := strtopos(spos);
   game_score := -99999;
   play := SOUTH;
   clear_hashtable;
   repeat
     if playsouth then begin
       set_evaluator(@eval[0]);
       set_propp_evaluators(eval);
       set_propp_probs(prob);
       start_timer(stime);
       switch_hashtable(0);
       search_using_prom(pos,depth,100,false);
       stop_timer;
     end else begin
       set_evaluator(@evalopp);
       start_timer(stime);
       switch_hashtable(1);
       search(pos,depth,100,false);
       stop_timer;
     end;
     move:=get_bestmove;
     pos := execute_move(pos,move,false);

     write(' PROM: '+movetostr(move,play)+' (',game_score,') ');
     writelog(' PROM: '+movetostr(move,play)+' '+inttostr(game_score)+' ');

     play:=1-play;
     if (not endofgame(pos)) then begin

        if playsouth then begin
           set_evaluator(evalopp);
           start_timer(stime);
           switch_hashtable(1);
           search(pos,depth,100,false);
           move:=get_bestmove;
           writeln(movetostr(move,play)+' (',inttostr(game_score),'); ');
           writelnlog(movetostr(move,play)+' '+inttostr(game_score)+'; ');
           stop_timer;
        end else begin
          set_evaluator(@eval[0]);
          switch_hashtable(0);
          set_propp_evaluators(eval);
          set_propp_probs(prob);
          search_using_prom(pos,depth,100,false);
          stop_timer;
        end;
        move:=get_bestmove;
        pos := execute_move(pos,move,false);
        play:=1-play;
     end else begin
        writeln('');
        writelnlog('');
     end;
   until endofgame(pos);

   if checkwinner(pos)=south then begin
        writeln(' South wins');
        writereslog(inttostr(nr)+' S');
        writelnlog(' South wins');
        inc(ns);
   end else begin
        writeln(' North wins');
        writereslog(inttostr(nr)+' N');
        writelnlog(' North wins');
        inc(nn);
   end;
  until eof(inp);

  writereslog('score: ');
  writereslog('S: '+inttostr(ns));
  writereslog('N: '+inttostr(nn));

  writelnlog('score: ');
  writelnlog('South: '+inttostr(ns));
  writelnlog('North: '+inttostr(nn));

end;


procedure comm_match(params: array of string);
var playsouth: boolean;
    i,n: integer;
begin
  if (high(params)<9) then begin
    writeln('usage: baodos prommatch south/north inputfile depth time resfile logfile evalopp eval1 pr1 eval2 pr2 ..');
    exit;
  end;
  if params[1]='north' then playsouth:=false else playsouth:=true;
  n := (high(params)-7) div 2;

  setlength(eval,n);
  setlength(evalname,n);
  setlength(prob,n);

  evaloppname:=params[7];
  evalopp:=getevaluator(evaloppname);

  for i:=0 to n-1 do begin
     evalname[i]:=params[8+2*i];
     eval[i] := getevaluator(evalname[i]);
     prob[i] := strtofloat(params[9+2*i]);
  end;

  createreslog(params[5]);
  createlog(params[6]);
  set_enginemessage(output);
  init_search;
  make_hashtables(2,20);
  basictest(params[2],strtoint(params[3]),strtoint(params[4]),playsouth);
  if dolog then close(log);
end;



procedure largetest(num: integer; depth: integer);
var pos: TBaoPosition;
    move: TBaoMove;
    play: integer;
    k,i,nr,ns,nn,gamelength: integer;
    posdepth,firstscore: integer;
    gns,gnn: array[0..500] of integer;
    dns,dnn: array[3..33] of integer;
    sns,snn: array[-500..500] of integer;

    maxgamelength, minscore, maxscore: integer;
    firstmove, stop: boolean;
    s: string;
begin
  writereslog('samplesize = '+inttostr(num));
  writereslog('search depth = ' + inttostr(depth));
  s:='[';
  for i:=0 to high(evalname) do s:=s+evalname[i]+' '+formatfloat('#.##',prob[i])+' ';
  s:=s+']';
  writereslog(s+' vs. '+evaloppname);

  for i:=0 to high(gns) do begin gns[i]:=0; gnn[i]:=0 end;
  for i:=low(sns) to high(sns) do begin sns[i]:=0; snn[i]:=0 end;
  for i:=low(dns) to high(dns) do begin dns[i]:=0; dnn[i]:=0 end;
  maxgamelength:=0; minscore:=0; maxscore:=0;
  nr:=0; ns:=0; nn:=0;
  k:=1;
  repeat
   inc(nr);
   writeln(inttostr(nr)+'('+inttostr(k)+'): ');
   writelnlog(inttostr(nr)+'('+inttostr(k)+'): ');

//   posdepth:=floor(3+GenRandMT*30);
   posdepth:=floor(3+GenRandMT*6);
   create_onerandpos(pos,posdepth);

   firstmove:=true; stop:=false;

   gamelength:=0;
   firstscore:=0;
   game_score := -99999;
   play := SOUTH;
   clear_hashtable;
   repeat
     set_evaluator(@eval[0]);
     set_propp_evaluators(eval);
     set_propp_probs(prob);
     switch_hashtable(0);
     search_using_prom(pos,depth,100,false);

     if firstmove then firstscore:=game_score;

     move:=get_bestmove;
     pos := execute_move(pos,move,false);
     write(' PROM: '+movetostr(move,play)+' (',game_score,') ');

     inc(gamelength);
     play:=1-play;

     firstmove:=false;

     if not (endofgame(pos) or stop) then begin

        set_evaluator(evalopp);
        switch_hashtable(1);
        search(pos,depth,100,false);
        move:=get_bestmove;
        writeln(movetostr(move,play)+' (',inttostr(game_score),'); ');
        move:=get_bestmove;
        pos := execute_move(pos,move,false);
        play:=1-play;
        inc(gamelength);
     end else begin
     writeln('');
   end;
  until endofgame(pos) or stop;

  if gamelength>maxgamelength then maxgamelength:=gamelength;
  if (abs(firstscore)<9000) then begin
    if (minscore=0) or (firstscore<minscore) then minscore:=firstscore;
    if (maxscore=0) or (firstscore>maxscore) then maxscore:=firstscore;
  end;  
  if checkwinner(pos)=south then begin
        writeln(' South wins');
        inc(ns);
        inc(gns[gamelength]);
        inc(dns[posdepth]);
        if (abs(firstscore)<9000) and (firstscore<>0) then inc(sns[firstscore div 50]);

        writereslog(inttostr(k)+' S (' +inttostr(ns)+'-'+inttostr(nn)+') '+inttostr(posdepth)+' '+inttostr(gamelength)+' '+inttostr(firstscore));
   end else begin
        writeln(' North wins');
        inc(nn);
        inc(gnn[gamelength]);
        inc(dnn[posdepth]);
        if (abs(firstscore)<9000) and (firstscore<>0) then inc(snn[firstscore div 50]);
        writereslog(inttostr(k)+' N (' +inttostr(ns)+'-'+inttostr(nn)+') '+inttostr(posdepth)+' '+inttostr(gamelength)+' '+inttostr(firstscore));
   end;
   inc(k);

  until k>num;

  writereslog('score: ');
  writereslog('S: '+inttostr(ns));
  writereslog('N: '+inttostr(nn));

(*  writereslog('per gamelength: ');
  for i:=0 to maxgamelength do begin
    writereslog(inttostr(i)+': '+inttostr(gns[i])+' '+inttostr(gnn[i]));
  end;

  writereslog('per startpos depth: ');
  for i:=3 to 33 do begin
    writereslog(inttostr(i)+': '+inttostr(dns[i])+' '+inttostr(dnn[i]));
  end;

  writereslog('per first score: ');
  for i:=(minscore div 50) to (maxscore div 50) do begin
    writereslog(inttostr(i*50)+': '+inttostr(sns[i])+' '+inttostr(snn[i]));
  end;
*)

end;



procedure comm_largematch(params: array of string);
var i,n: integer;
begin
  if (high(params)<7) then begin
    writeln('usage: baodos promlargematch samplesize depth resfile evalopp eval1 pr1 eval2 pr2 ..');
    exit;
  end;
  n := (high(params)-4) div 2;

  setlength(eval,n);
  setlength(evalname,n);
  setlength(prob,n);

  evaloppname:=params[4];
  evalopp:=getevaluator(evaloppname);

  for i:=0 to n-1 do begin
     evalname[i]:=params[5+2*i];
     eval[i] := getevaluator(evalname[i]);
     prob[i] := strtofloat(params[6+2*i]);
  end;

  createreslog(params[3]);
  set_enginemessage(output);
  init_search;
  make_hashtables(2,20);
  largetest(strtoint(params[1]),strtoint(params[2]));
end;




procedure tryprom(input: string; depth: integer);
var pos: TBaoPosition;
    move: TBaoMove;
    i: integer;
    inp: Text;
    spos,s: string;
begin
  s:='[';
  for i:=0 to high(evalname) do s:=s+evalname[i]+' '+formatfloat('#.##',prob[i])+' ';
  s:=s+']';
  writelnlog('input = '+input);
  writelnlog('search depth = ' + inttostr(depth));
  writelnlog(s+' vs. '+evaloppname);
  assign(inp,input);
  reset(inp);
  repeat

  readln(inp,spos);
  pos := strtopos(spos);
  game_score := -99999;
  clear_hashtable;
  set_evaluator(@eval[0]);
  set_propp_evaluators(eval);
  set_propp_probs(prob);
  switch_hashtable(0);
  search_using_prom(pos,depth,100,false);
  move:=get_bestmove;
  writeln(' PROM: '+movetostr(move,SOUTH)+' (',game_score,') ');
  writelog(' PROM: '+movetostr(move,SOUTH)+' '+inttostr(game_score)+' ');
  clear_hashtable;
  search(pos,depth,100,false);
  move:=get_bestmove;
  writeln(' AB: '+movetostr(move,SOUTH)+' (',game_score,') ');
  writelnlog(' AB: '+movetostr(move,SOUTH)+' '+inttostr(game_score)+' ');
  
  until eof(inp);
  
end;




procedure comm_try(params: array of string);
var  i,n: integer;
begin
  if (high(params)<6) then begin
    writeln('usage: baodos promtry inputfile depth logfile evalopp eval1 pr1 eval2 pr2 ..');
    exit;
  end;
  n := (high(params)-4) div 2;

  setlength(eval,n);
  setlength(evalname,n);
  setlength(prob,n);

  evaloppname:=params[4];
  evalopp:=getevaluator(evaloppname);

  for i:=0 to n-1 do begin
     evalname[i]:=params[5+2*i];
     eval[i] := getevaluator(evalname[i]);
     prob[i] := strtofloat(params[6+2*i]);
  end;

  createlog(params[3]);
  set_enginemessage(output);
  init_search;
  make_hashtables(2,20);
  engine_startlog;
  tryprom(params[1],strtoint(params[2]));
  engine_stoplog;
  if dolog then close(log);
end;


begin
   registercommand(@comm_match,'prommatch');
   registercommand(@comm_largematch,'promlargematch');
   registercommand(@comm_try,'promtry');
end.
