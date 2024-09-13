unit expset;

interface


implementation
uses
  SysUtils,
  Math,
  classes,
  winprocs,
  Engine,
  eval,
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

function opp_evaluate(pos: TBaoPosition): integer;
const STONE = 3;
      FRONT = 5;
var score,i: integer;
begin
   with pos do begin
      // stone balance
      score:=store[rootplayer]-store[1-rootplayer];
      for i:=0 to 15 do begin
        inc(score,STONE * hole[rootplayer,i]);
        dec(score,STONE * hole[1-rootplayer,i]);
      end;

      // captures
      for i:=0 to 7 do begin
         if (hole[rootplayer,i]>0) and (hole[1-rootplayer,7-i]>0) then begin
//            if (7-i=NYUMBA) and ownsnyumba[1-rootplayer] then inc(score,100);
//            if (i=NYUMBA) and ownsnyumba[rootplayer] then dec(score,50);
//            inc(score, FRONT * (hole[1-rootplayer,7-i] - hole[rootplayer,i]));
         end;
      end;

      // own nyumba
      // Admissiblity:  forget about onwning nyumba
      if ownsnyumba[rootplayer] then inc(score,200);
      if ownsnyumba[1-rootplayer]then  inc(score,-200);

   end;
   if score=0 then score:=1;
   opp_evaluate:=score;
end;


procedure basictest(input: string; stime: integer);
var pos: TBaoPosition;
    move: TBaoMove;
    play: integer;
    nr,mnr,ns,nn: integer;
    inp: Text;
    spos: string;
begin
  writelog('input = '+input);
  writelog('search time = ' + inttostr(stime)+' sec.');
  writelog('om(3) defeval//oppeval vs. ab oppeval');

  assign(inp,input);
  reset(inp);
  nr:=0; ns:=0; nn:=0;
  repeat
   inc(nr);
   write(inttostr(nr)+': ');
   readln(inp,spos);
   pos := strtopos(spos);
   game_score := -99999;
   play := SOUTH;
   mnr:=0;
   repeat
     clear_hashtable;
     set_evaluator(@default_evaluate);
     set_opp_evaluator(@opp_evaluate);
     start_timer(stime);
     search_using_om(pos,3,1000,100,false);
     stop_timer;
     move:=get_bestmove;
     inc(mnr);
     write(inttostr(mnr)+' '+movetostr(move,play)+' ');
     pos := execute_move(pos,move,false);
     if (not endofgame(pos)) then begin
        play:=1-play;
        clear_hashtable;
        set_evaluator(@opp_evaluate);
        start_timer(stime);
        search(pos,1000,100,false);
        stop_timer;
        move:=get_bestmove;
        pos := execute_move(pos,move,false);
        write(movetostr(move,play)+'; ');
     end;
   until endofgame(pos);
   if checkwinner(pos)=south then begin
        writeln(' South wins');
        writelog(inttostr(nr)+' S');
        inc(ns);
   end else begin
        writeln(' North wins');
        writelog(inttostr(nr)+' N');
        inc(nn);
   end;
  until eof(inp);
  writelog('score: ');
  writelog('S: '+inttostr(ns));
  writelog('N: '+inttostr(nn));
end;


procedure comm_ommatch1(params: array of string);
begin
  if (high(params)<>3) then begin
    writeln('usage: baodos ommatch1 inputfile depth logfile');
    exit;
  end;
  createlog(params[3]);
  set_enginemessage(output);
  init_search;
  basictest(params[1],strtoint(params[2]));
end;


begin
   registercommand(@comm_ommatch1,'ommatch1');
end.
