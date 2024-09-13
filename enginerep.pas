unit enginerep;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, Menus,main,global;

type
  TEngineReportForm = class(TForm)
    Memo1: TMemo;
    MainMenu1: TMainMenu;
    Clear1: TMenuItem;
    SaveDialog1: TSaveDialog;
    Save1: TMenuItem;
    procedure Clear1Click(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure Save1Click(Sender: TObject);

  private
    { Private declarations }
  public
    procedure add(s: string);
    procedure Clear;
    { Public declarations }
  end;

var
  EngineReportForm: TEngineReportForm;

implementation

{$R *.DFM}


procedure TEngineReportForm.add(S: string);
begin
    memo1.lines.add(s);
end;

procedure TEngineReportForm.Clear1Click(Sender: TObject);
begin
  memo1.lines.clear
end;

procedure TEngineReportForm.Clear;
begin
  memo1.lines.clear
end;


procedure TEngineReportForm.FormResize(Sender: TObject);
begin
   memo1.top :=1;
   memo1.left :=1;
   memo1.width := clientwidth-3;
   memo1.height := clientheight-3;
end;

procedure TEngineReportForm.Save1Click(Sender: TObject);
var F: TextFile;
    i: integer;
begin
    savedialog1.initialdir := progdir+'\games';
    if SaveDialog1.Execute then
    begin
     AssignFile(F,SaveDialog1.filename);
     {$I-}
     Rewrite(F);
     {$I+}
     if IOresult<>0 then exit;
     for i:=1 to memo1.lines.count do begin
        writeln(F,memo1.lines[i-1]);
     end;
     CloseFile(F);

    end;
end;

end.
