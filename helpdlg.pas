unit helpdlg;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  OleCtrls, SHDocVw, ExtCtrls, global;

type
  THelpDialog = class(TForm)
    Panel1: TPanel;
    WebBrowser1: TWebBrowser;
    procedure Panel1Resize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormResize(Sender: TObject);
  private
    { Private declarations }
  public
    showurl: string;
    { Public declarations }
  end;

var
  HelpDialog: THelpDialog;

implementation

{$R *.DFM}

procedure THelpDialog.Panel1Resize(Sender: TObject);
begin
   webbrowser1.top :=1;
   webbrowser1.left :=1;
   webbrowser1.width := panel1.width-3;
   webbrowser1.height := panel1.height-3;
end;

procedure THelpDialog.FormShow(Sender: TObject);
begin
   webbrowser1.navigate(showurl);
end;

procedure THelpDialog.FormResize(Sender: TObject);
begin
   panel1.top :=1;
   panel1.left :=1;
   panel1.width := clientwidth-3;
   panel1.height := clientheight-3;
end;

end.
