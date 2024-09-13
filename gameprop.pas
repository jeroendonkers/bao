unit gameprop;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, BaoGame, global;

type
  TGamePropForm = class(TForm)
    Panel1: TPanel;
    edTitle: TEdit;
    edSouth: TEdit;
    edNorth: TEdit;
    edDate: TEdit;
    edPlace: TEdit;
    edEvent: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    edTime: TEdit;
    Label8: TLabel;
    OKbutton: TButton;
    CancelButton: TButton;
    NorthComputer: TCheckBox;
    SouthComputer: TCheckBox;
    winnerbox: TGroupBox;
    rbSouth: TRadioButton;
    rbNorth: TRadioButton;
    rbNone: TRadioButton;
    GroupBox1: TGroupBox;
    cbOfficial: TRadioButton;
    cbNovice: TRadioButton;
    cbManual: TRadioButton;
    Label9: TLabel;
    procedure CancelButtonClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure OKbuttonClick(Sender: TObject);
  private
    { Private declarations }
  public
    canceled: boolean;

    procedure useGame(g: TbaoGame);
    { Public declarations }
  end;

var
  GamePropForm: TGamePropForm;

implementation
{$R *.DFM}

   var game: TBaoGame = nil;

procedure TGamePropForm.useGame(g: TbaoGame);
begin
  game:=g;
end;

procedure TGamePropForm.CancelButtonClick(Sender: TObject);
begin
   canceled:=true;
   close;
end;

procedure TGamePropForm.FormShow(Sender: TObject);
begin
   if game=nil then exit;
   edtitle.text:=game.title;
   edsouth.text:=game.south;
   ednorth.text:=game.north;
   eddate.text:=game.date;
   edplace.text:=game.place;
   edevent.text:=game.event;
   edtime.text:=game.time;
   if game.winner=SOUTH then rbSouth.checked:=true
   else if game.winner=NORTH then rbNorth.checked:=true
   else  rbNone.checked:=true;
end;

procedure TGamePropForm.OKbuttonClick(Sender: TObject);
begin
   if game=nil then exit;
   game.title:=edtitle.text;
   game.south:=edsouth.text;
   game.north:=ednorth.text;
   game.date:=eddate.text;
   game.place:=edplace.text;
   game.event:=edevent.text;
   game.time:=edtime.text;
   canceled:=false;
   if rbSouth.checked then game.winner:=SOUTH;
   if rbNorth.checked then game.winner:=NORTH;
   if rbNone.checked then game.winner:=255;
   close;
end;


end.
