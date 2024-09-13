unit BaoMatch;

interface

implementation

uses
  SysUtils,
  Math,
  classes,
  winprocs,
  Engine,
  global,
  Mersenne;

procedure output(s: string);
begin
//  writeln(s);
end;

var logname: string = 'log.txt';
var reslogname: string = 'result.txt';
var reslog,log: Text;
var dolog: boolean;
var eval1, eval2: evaluator;
var eval1name, eval2name: string;

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

procedure basictest(input: string; depth1,depth2: integer; stime: integer);
var pos: TBaoPosition;
    move: TBaoMove;
    play: integer;
    nr,mnr,ns,nn: integer;
    inp: Text;
    spos: string;
begin
  writereslog('input = '+input);
  writereslog('search depth south = ' + inttostr(depth1));
  writereslog('search depth north = ' + inttostr(depth2));
  writereslog('search time = ' + inttostr(stime)+' sec.');
  writereslog(eval1name+' vs. '+eval2name);

  writelnlog('input = '+input);
  writelnlog('search depth south = ' + inttostr(depth1));
  writelnlog('search depth north = ' + inttostr(depth2));
  writelnlog('search time = ' + inttostr(stime)+' sec.');
  writelnlog(eval1name+' vs. '+eval2name);

  assign(inp,input);
  reset(inp);
  nr:=0; ns:=0; nn:=0;
  repeat
   inc(nr);
   write(inttostr(nr)+': ');
   writelog(inttostr(nr)+': ');
   readln(inp,spos);
   pos := strtopos(spos);
   game_score := -99999;
   play := SOUTH;
   mnr:=0;
   clear_hashtable;
   repeat
     set_evaluator(@eval1);
     start_timer(stime);
     switch_hashtable(0);
     search(pos,depth1,100,false);
     stop_timer;
     move:=get_bestmove;
     inc(mnr);
     pos := execute_move(pos,move,false);
     write(inttostr(mnr)+' '+movetostr(move,play)+' (',maxstack,') ');
     writelog(inttostr(mnr)+' '+movetostr(move,play)+' '+inttostr(game_score)+' ');
     play:=1-play;
     if (not endofgame(pos)) then begin
        set_evaluator(@eval2);
        start_timer(stime);
        switch_hashtable(1);
        search(pos,depth2,100,false);
        stop_timer;
        move:=get_bestmove;
        pos := execute_move(pos,move,false);
        write(movetostr(move,play)+' (',maxstack,'); ');
        writelog(movetostr(move,play)+' '+inttostr(game_score)+'; ');
        play:=1-play;
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
var depth1, depth2: integer;
begin
  if (high(params)<6) then begin
    writeln('usage: baodos match eval1 eval2 inputfile depthsouth time resfile logfile depthnorth');
    exit;
  end;
  eval1name:=params[1];
  eval2name:=params[2];
  eval1 := getevaluator(eval1name);
  eval2 := getevaluator(eval2name);
  createreslog(params[6]);
  depth1:=strtoint(params[4]);
  if high(params)>=7 then createlog(params[7]);
  if high(params)>=8 then depth2:=strtoint(params[8]) else depth2:=depth1;
  set_enginemessage(output);
  init_search;
  make_hashtables(2,20);
  basictest(params[3],depth1,depth2,strtoint(params[5]));
  if dolog then close(log);
end;



begin
   registercommand(@comm_match,'match');
end.
