unit Enginethread;

interface
uses global;

procedure computenextmove(pos: TBaoPosition);

implementation
uses dialogs,main,forms,sysutils,classes, engine;

type TEngineThread = class(TThread)
   startpos: TBaoPosition;
   procedure Execute; override;
   constructor makeThread(pos: TBaoPosition);
end;

var
   thr: TEngineThread = nil;

  procedure enginemessage2form(s: String);
  begin
     BaoForm.enginemessage(s);
  end;

 procedure computenextmove(pos: TBaoPosition);
 begin
    set_enginemessage(@enginemessage2form);
    if thr<>nil then begin
      enginemessage2form('cannot start engine: thread is in use');
      exit;
    end;
    thr := TEngineThread.makeThread(pos);
    thr.priority := tpHighest;
    thr.Resume;
 end;

 constructor TEngineThread.makeThread(pos: TBaoPosition);
 begin
   startpos:=pos;
   Create(true);
 end;

 procedure TEngineThread.Execute;
  begin
     BaoForm.timer2.Interval := searchtime * 1000;
{$IFDEF NOMTD}
     search_no_mtd(startpos,maxsearchdepth,movelimit,ignoretakasia);
{$ELSE}
     search(startpos,maxsearchdepth,movelimit,ignoretakasia);
{$ENDIF}
     BaoForm.timer2.Interval := 0;
     baoform.computerfinished(get_bestmove);
     thr:=nil;
  end;

end.
