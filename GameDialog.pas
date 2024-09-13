unit GameDialog;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls,BaoGame;

type
  TGDialog = class(TForm)
    ListBox1: TListBox;
    Label1: TLabel;
    Button1: TButton;
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }

    game: TBaoGame;
  public
    { Public declarations }

    procedure setGame(g: TBaoGame);

  end;

var
  GDialog: TGDialog;

implementation

{$R *.DFM}

procedure TGDialog.Button1Click(Sender: TObject);
begin
  close;
end;

procedure TGDialog.FormCreate(Sender: TObject);
begin
   game:=nil;
end;


procedure TGDialog.setGame(g: TBaoGame);
begin
  game:=g;
end;

procedure TGDialog.FormShow(Sender: TObject);
var i: integer;
     s: string;
begin
  listbox1.Clear;
  game.resetgame;
  i:=1;
  repeat
    s:=inttostr(i)+': '+game.nextmove;
    if (not game.eog) then s:=s+' '+game.nextmove;
    listbox1.items.add(s);
    inc(i);    
  until game.eog;
end;

end.
