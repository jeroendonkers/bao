program bao;

uses
  Forms,
  main in 'main.pas' {BaoForm},
  global in 'global.pas',
  BaoPlayer in 'BaoPlayer.pas',
  manualpos in 'manualpos.pas' {ManualForm},
  BaoGame in 'BaoGame.pas',
  Engine in 'Engine.pas',
  gameprop in 'gameprop.pas' {GamePropForm},
  helpdlg in 'helpdlg.pas' {HelpDialog},
  enginerep in 'enginerep.pas' {EngineReportForm},
  infoform in 'infoform.pas' {info},
  Mersenne in 'Mersenne.pas',
  Enginethread in 'Enginethread.pas',
  MiniReg in 'MiniReg.pas',
  eval in 'eval.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TBaoForm, BaoForm);
  Application.CreateForm(TManualForm, ManualForm);
  Application.CreateForm(TGamePropForm, GamePropForm);
  Application.CreateForm(THelpDialog, HelpDialog);
  Application.CreateForm(TEngineReportForm, EngineReportForm);
  Application.CreateForm(Tinfo, info);
  Application.Run;
end.
