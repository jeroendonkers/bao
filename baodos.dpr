program baodos;
{$APPTYPE CONSOLE}
uses
  SysUtils,
  Engine in 'Engine.pas',
  global in 'global.pas',
  Mersenne in 'Mersenne.pas',
  expset in 'expset.pas',
  baogen1 in 'baogen1.pas',
  baogen2 in 'baogen2.pas',
  BaoOmMatch in 'BaoOmMatch.pas',
  RandPos in 'RandPos.pas',
  baogen3 in 'baogen3.pas',
  baogen4 in 'baogen4.pas',
  baogen5 in 'baogen5.pas',
  Analyse in 'Analyse.pas',
  Linearlearn2 in 'Linearlearn2.pas',
  Linearlearn in 'Linearlearn.pas',
  eval in 'eval.pas',
  Ngnetlearn2 in 'Ngnetlearn2.pas',
  BaoMatch in 'BaoMatch.pas',
  PromLearner in 'PromLearner.pas',
  BaoPromMatch in 'BaoPromMatch.pas';

var params: array of string;
    i: integer;

begin
  if paramcount<1 then begin
     setlength(params,2);
     params[1]:='input.txt';
     docommand('run',params);
     exit;
  end;
  setlength(params,paramcount);
  for i := 1 to ParamCount do params[i-1]:=ParamStr(i);
  docommand(ParamStr(1),params);
end.
