unit BaoOmMatch;

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
var perf, perfopp, manrisk: boolean;

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
    oppvalue,nr,mnr,ns,nn: integer;
    inp: Text;
    oppmoves,spos: string;
begin
  writereslog('input = '+input);
  writereslog('search depth = ' + inttostr(depth));
  if perf then writereslog('Extended search for max player');
  if perfopp then writereslog('Extended search for min player');
  writereslog('search time = ' + inttostr(stime)+' sec.');
  writereslog(eval1name+' vs. '+eval2name);

  writelnlog('input = '+input);
  writelnlog('search depth = ' + inttostr(depth));
  if perf then writelnlog('Extended search for max player');
  if perfopp then writelnlog('Extended search for min player');
  writelnlog('search time = ' + inttostr(stime)+' sec.');
  writelnlog(eval1name+' vs. '+eval2name);

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
   mnr:=0;
   clear_hashtable;
   repeat
     if playsouth then begin
       set_evaluator(@eval1);
       set_opp_evaluator(@eval2);
       start_timer(stime);
       switch_hashtable(0);
       search(pos,depth,100,false);
       write(inttostr(mnr)+': NORMAL '+movetostr(get_bestmove,play)+' (',inttostr(game_score),') ');
       writelog(inttostr(mnr)+': NORMAL '+movetostr(get_bestmove,play)+' '+inttostr(game_score)+' ');
       search_using_omtest(pos,depth,100,false,oppmoves,oppvalue,perf,perfopp,manrisk);
       stop_timer;
     end else begin
       set_evaluator(@eval2);
       start_timer(stime);
       switch_hashtable(1);
       search(pos,depth,100,false);
       stop_timer;
     end;
     move:=get_bestmove;
     inc(mnr);
     pos := execute_move(pos,move,false);
     write(' OM: '+movetostr(move,play)+' (',game_score,') ');
     writelog(' OM: '+movetostr(move,play)+' '+inttostr(game_score)+' ');

     play:=1-play;
     if (not endofgame(pos)) then begin

       if game_score=0 then begin
         write(' - predict: xxx (0) does: ');
         writelog(' - predict: xxx(0) does: ');
        end else begin
         write(' - predict: '+oppmoves+' (',oppvalue,') does: ');
         writelog(' - predict: '+oppmoves+' '+inttostr(oppvalue)+' does: ');
       end;

        if playsouth then begin
           set_evaluator(@eval2);
           start_timer(stime);
           switch_hashtable(1);
           search(pos,depth,100,false);
           move:=get_bestmove;
           writeln(movetostr(move,play)+' (',inttostr(game_score),'); ');
           writelnlog(movetostr(move,play)+' '+inttostr(game_score)+'; ');

           stop_timer;

        end else begin
           set_evaluator(@eval1);
           set_opp_evaluator(@eval2);
           start_timer(stime);
           switch_hashtable(0);
           search_using_omtest(pos,depth,100,false,oppmoves,oppvalue,perf,perfopp,manrisk);
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
begin
  if (high(params)<6) then begin
    writeln('usage: baodos ommatch south/north eval1 eval2 inputfile depth time resfile logfile perf perfopt manrisk');
    exit;
  end;
  if params[1]='north' then playsouth:=false else playsouth:=true;
  eval1name:=params[2];
  eval2name:=params[3];
  eval1 := getevaluator(eval1name);
  eval2 := getevaluator(eval2name);
  createreslog(params[7]);
  if high(params)>=8 then createlog(params[8]);
  perf:=false;
  perfopp:=false;
  manrisk:=false;
  if high(params)>=9 then perf:=(params[9]='true');
  if high(params)>=10 then perfopp:=(params[10]='true');
  if high(params)>=11 then manrisk:=(params[11]='true');
  set_enginemessage(output);
  init_search;
  make_hashtables(2,20);
  basictest(params[4],strtoint(params[5]),strtoint(params[6]),playsouth);
  if dolog then close(log);
end;


begin
   registercommand(@comm_match,'ommatch');
end.
