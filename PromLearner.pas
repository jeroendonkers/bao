unit PromLearner;

interface

implementation
uses math, sysutils, engine, global, mersenne, randpos;

var targeteval : evaluator;
    targetevalname : string;
    evals: array of evaluator;
    evalnames: array of string;
    counts: array of longint;
    moves: array of TBaoMove;
    targetmove: TBaoMove;
    equal: array of boolean;
    reslogname: string;


procedure writereslog(s: string);
var reslog: text;
begin
   AssignFile(reslog,reslogname);
   {$I-}
   append(reslog);
   {$I+}
   if IOresult<>0 then begin writeln('cannot append reslog'); exit; end;
   writeln(reslog,s);
   close(reslog);
end;



procedure comm_learner(params: array of string);
var i,j,nevals: integer;
    totcount, countlimit, trials, posdepth, depth, equalcount, reps: integer;
    pos: TBaoPosition;
    s: string;
begin

  reslogname:='promlearn.txt';
  init_search;
  if high(params)<3 then begin
      writeln('usage: baodos learn depth totcount repeat eval eval1 eval2 ...');
      exit;
  end;

  depth:=strtoint(params[1]);
  countlimit:=strtoint(params[2]);
  reps:=strtoint(params[3]);

  targetevalname:=params[4];
  targeteval := getevaluator(targetevalname);
  write('learning ',targetevalname,' from ');

  nevals:=high(params)-4;
  setlength(evals,nevals);
  setlength(evalnames,nevals);
  setlength(counts,nevals);
  setlength(moves,nevals);
  setlength(equal,nevals);

  for i:=1 to nevals do begin
     evalnames[i-1] := params[i+4];
     evals[i-1] := getevaluator(evalnames[i-1]);
     write(evalnames[i-1],' ');
     counts[i-1]:=0;
  end;
  writeln;

  make_hashtables(nevals+1,18);

  for j:=1 to reps do begin
  write('take ',j,': ');
  totcount:=0; trials:=0;
  for i:=1 to nevals do counts[i-1]:=0;

  repeat

     inc(trials);
     posdepth :=  floor(3+GenRandMT*30);
     create_onerandpos(pos,posdepth);
//     clear_hashtable;
     switch_hashtable(0);
     set_evaluator(@targeteval);
     search(pos,depth,100,false);
     targetmove:=get_bestmove;
     equalcount:=0;
     for i:=1 to nevals do begin
        switch_hashtable(i);
        set_evaluator(@evals[i-1]);
        search(pos,depth,100,false);
        moves[i-1]:=get_bestmove;
        equal[i-1]:=equalMove(targetmove,moves[i-1]);
        if equal[i-1] then inc(equalcount);
        if equalcount>1 then break;
     end;
     if (equalcount=1) then begin
         write('.');
         inc(totcount);
         for i:=1 to nevals do
           if equal[i-1] then begin
              inc(counts[i-1]); break;
           end;
     end;
  until totcount=countlimit;
  writeln;
  for i:=1 to nevals do begin
     writeln(evalnames[i-1],' ',counts[i-1]);
  end;
  writeln('trials ',trials);
  s:=inttostr(j)+' '+targetevalname+' '+inttostr(depth)+' '+inttostr(countlimit)
        +' '+inttostr(trials);
  for i:=1 to nevals do s:=s+' '+evalnames[i-1]+' '+inttostr(counts[i-1]);
  writereslog(s);
 end;
end;




begin
   registercommand(@comm_learner,'learn');
end.
