unit manualpos;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Grids, Global, StdCtrls;

type
  TManualForm = class(TForm)
    StringGrid1: TStringGrid;
    Button1: TButton;
    Button2: TButton;
    EditNorth: TEdit;
    EditSouth: TEdit;
    NyumbaNorth: TCheckBox;
    NyumbaSouth: TCheckBox;
    SouthButton: TRadioButton;
    NorthButton: TRadioButton;
    procedure FormCreate(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
    pos: TBaoPosition;

    procedure fillGrid;
    procedure getGrid;
  public
    canceled: boolean;
    function getPosition: TBaoPosition;
    { Public declarations }
  end;

var
  ManualForm: TManualForm;

implementation

{$R *.DFM}


procedure TManualForm.FillGrid;
var i: integer;
begin
    for i:=0 to 7 do begin
       StringGrid1.Cells[i,0] := inttostr(pos.hole[NORTH,8+i]);
       StringGrid1.Cells[i,1] := inttostr(pos.hole[NORTH,7-i]);
       StringGrid1.Cells[i,2] := inttostr(pos.hole[SOUTH,i]);
       StringGrid1.Cells[i,3] := inttostr(pos.hole[SOUTH,15-i]);
    end;
    editnorth.text := inttostr(pos.store[NORTH]);
    editsouth.text := inttostr(pos.store[SOUTH]);
    nyumbaNorth.checked := pos.ownsnyumba[NORTH];
    nyumbaSouth.checked := pos.ownsnyumba[SOUTH];
    southbutton.checked := (pos.player=SOUTH);
end;

procedure TManualForm.GetGrid;
var i: integer;
begin
    try
       for i:=0 to 7 do begin
         pos.hole[NORTH,8+i]  := StrToInt(StringGrid1.Cells[i,0]);
         pos.hole[NORTH,7-i]  := StrToInt(StringGrid1.Cells[i,1]);
         pos.hole[SOUTH,i]    := StrToInt(StringGrid1.Cells[i,2]);
         pos.hole[SOUTH,15-i] := StrToInt(StringGrid1.Cells[i,3]);
       end;
       pos.store[NORTH] := StrToInt(editnorth.text);
       pos.store[SOUTH] := StrToInt(editsouth.text);
     except
        on EConvertError do begin
        end;
     end;
     pos.ownsnyumba[NORTH]:=false;
     pos.ownsnyumba[SOUTH]:=false;
     if nyumbaNorth.checked then
         pos.ownsnyumba[NORTH]:=true;
     if nyumbaSouth.checked then
         pos.ownsnyumba[SOUTH]:=true;
    if northbutton.checked
        then pos.player:=NORTH else pos.player:=SOUTH;
end;

function TManualForm.getPosition: TBaoPosition;
begin
    getPosition := pos;
end;

procedure TManualForm.FormCreate(Sender: TObject);
begin
    pos:=BAO_EMPTYOPENING;
    fillgrid;
end;

procedure TManualForm.Button2Click(Sender: TObject);
begin
    canceled:=true;
    close;
end;

procedure TManualForm.Button1Click(Sender: TObject);
begin
   getgrid;
   canceled:=false;
   close;
end;

end.
