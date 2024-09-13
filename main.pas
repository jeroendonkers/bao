unit main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls, ExtCtrls, global, Menus, ComCtrls, jpeg, Buttons, minireg;

type
  TBaoForm = class(TForm)
    Panel1: TPanel;
    sholeb8: TShape;
    sholeb7: TShape;
    sholeb6: TShape;
    sholeb5: TShape;
    sholeb4: TShape;
    sholeb3: TShape;
    sholeb2: TShape;
    sholeb1: TShape;
    sholea8: TShape;
    sholea7: TShape;
    sholea6: TShape;
    sholea5: TShape;
    sholea4: TShape;
    sholea3: TShape;
    sholea2: TShape;
    sholea1: TShape;
    sholeaa1: TShape;
    sholeaa2: TShape;
    sholeaa3: TShape;
    sholeaa4: TShape;
    sholeaa5: TShape;
    sholeaa6: TShape;
    sholeaa7: TShape;
    sholeaa8: TShape;
    sholebb1: TShape;
    sholebb2: TShape;
    sholebb3: TShape;
    sholebb4: TShape;
    sholebb5: TShape;
    sholebb6: TShape;
    sholebb7: TShape;
    sholebb8: TShape;
    sholenorth: TShape;
    sholesouth: TShape;
    holeb8: TLabel;
    holeb7: TLabel;
    holeb6: TLabel;
    holeb5: TLabel;
    holeb4: TLabel;
    holeb3: TLabel;
    holeb2: TLabel;
    holeb1: TLabel;
    holea8: TLabel;
    holea7: TLabel;
    holea6: TLabel;
    holea5: TLabel;
    holea4: TLabel;
    holea3: TLabel;
    holea2: TLabel;
    holea1: TLabel;
    holeaa1: TLabel;
    holeaa2: TLabel;
    holeaa3: TLabel;
    holeaa4: TLabel;
    holeaa5: TLabel;
    holeaa6: TLabel;
    holeaa7: TLabel;
    holeaa8: TLabel;
    holebb1: TLabel;
    holebb2: TLabel;
    holebb3: TLabel;
    holebb4: TLabel;
    holebb5: TLabel;
    holebb6: TLabel;
    holebb7: TLabel;
    holebb8: TLabel;
    holenorth: TLabel;
    holesouth: TLabel;
    MainMenu1: TMainMenu;
    File1: TMenuItem;
    Game1: TMenuItem;
    Exit1: TMenuItem;
    Start1: TMenuItem;
    Opening1: TMenuItem;
    Official1: TMenuItem;
    Novice1: TMenuItem;
    StatusBar1: TStatusBar;
    northlabel: TLabel;
    southlabel: TLabel;
    Timer1: TTimer;
    Manual1: TMenuItem;
    Stop1: TMenuItem;
    NyumbaBox: TCheckBox;
    Load1: TMenuItem;
    OpenDialog1: TOpenDialog;
    Animation1: TMenuItem;
    slow1: TMenuItem;
    fast1: TMenuItem;
    blitz1: TMenuItem;
    MoveListbox: TListBox;
    animoff1: TMenuItem;
    NorthBar: TShape;
    SouthBAr: TShape;
    MoveInput: TEdit;
    GoButton: TButton;
    Compute1: TMenuItem;
    Searchdepth1: TMenuItem;
    Longmovelimit1: TMenuItem;
    Compuc1: TMenuItem;
    NorthPlayer1: TMenuItem;
    SouthPlayer1: TMenuItem;
    Human1: TMenuItem;
    Computer1: TMenuItem;
    Human2: TMenuItem;
    Computer2: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    SaveDialog1: TSaveDialog;
    Save1: TMenuItem;
    Info1: TMenuItem;
    Help1: TMenuItem;
    AbortSearch1: TMenuItem;
    N4: TMenuItem;
    ShowEngineReport1: TMenuItem;
    Stop2: TMenuItem;
    Info2: TMenuItem;
    rules1: TMenuItem;
    userguide1: TMenuItem;
    Image1: TImage;
    BeginButton: TSpeedButton;
    Downbutton: TSpeedButton;
    stopbutton: TSpeedButton;
    UpButton: TSpeedButton;
    EndButton: TSpeedButton;
    rules2: TMenuItem;
    IgnoreTakasia1: TMenuItem;
    Searchtime1: TMenuItem;
    Timer2: TTimer;
    Continue1: TMenuItem;
    Undo1: TMenuItem;
    gametime: TLabel;
    movetime: TLabel;
    ClockTimer: TTimer;
    Nlabel: TLabel;
    SLabel: TLabel;
    FlipPlayers1: TMenuItem;
    N5: TMenuItem;
    Evaluator1: TMenuItem;
    seleval_default: TMenuItem;
    seleval_ga3: TMenuItem;
    seleval_tdl2b: TMenuItem;
    seleval_ngnd6a: TMenuItem;
    seleval_material: TMenuItem;
    seleval_fixed: TMenuItem;
    seleval_random: TMenuItem;
    N6: TMenuItem;


    procedure GoButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure makecaption;
    procedure sholeaa1DragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure sholeaa1DragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure sholeaa1StartDrag(Sender: TObject;
      var DragObject: TDragObject);
    procedure Official1Click(Sender: TObject);
    procedure Novice1Click(Sender: TObject);
    procedure Start1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure Manual1Click(Sender: TObject);
    procedure Stop1Click(Sender: TObject);
    procedure Load1Click(Sender: TObject);
    procedure slow1Click(Sender: TObject);
    procedure fast1Click(Sender: TObject);
    procedure blitz1Click(Sender: TObject);
    procedure animoff1Click(Sender: TObject);
    procedure MoveListboxDblClick(Sender: TObject);
    procedure reset;
    procedure UpButtonClick(Sender: TObject);
    procedure DownButtonCLick(Sender: TObject);
    procedure BeginButtonClick(Sender: TObject);
    procedure EndButtonClick(Sender: TObject);
    procedure MoveInputKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure Searchdepth1Click(Sender: TObject);
    procedure Longmovelimit1Click(Sender: TObject);
    procedure Compuc1Click(Sender: TObject);
    procedure Exit1Click(Sender: TObject);
    procedure Save1Click(Sender: TObject);
    procedure Info1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Human1Click(Sender: TObject);
    procedure Computer1Click(Sender: TObject);
    procedure Human2Click(Sender: TObject);
    procedure Computer2Click(Sender: TObject);
    procedure AbortSearch1Click(Sender: TObject);
    procedure ShowEngineReport1Click(Sender: TObject);
    procedure Stop2Click(Sender: TObject);
    procedure rules1Click(Sender: TObject);
    procedure Info2Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure userguide1Click(Sender: TObject);
    procedure IgnoreTakasia1Click(Sender: TObject);
    procedure Timer2Timer(Sender: TObject);
    procedure Searchtime1Click(Sender: TObject);
    procedure Undo1Click(Sender: TObject);
    procedure Continue1Click(Sender: TObject);
    procedure ClockTimerTimer(Sender: TObject);
    procedure FlipPlayers1Click(Sender: TObject);
    procedure seleval_defaultClick(Sender: TObject);
    procedure seleval_ga3Click(Sender: TObject);
    procedure seleval_tdl2bClick(Sender: TObject);
    procedure seleval_ngnd6aClick(Sender: TObject);
    procedure seleval_materialClick(Sender: TObject);
    procedure seleval_fixedClick(Sender: TObject);
    procedure seleval_randomClick(Sender: TObject);

  private

    holes: array[1..4,1..8] of ^TShape;
    holelabel: array[1..4,1..8] of ^Tlabel;

    player: integer;
    startdrag, actdrag: TShape;
    gameover: boolean;
    winner: integer;
    takasa: boolean;
    animating: boolean;
    animatewait: integer;
    gamechanged: boolean;
    computerplaysnorth, computerplayssouth: boolean;
    computeristhinking: boolean;
    computerisplaying: boolean; // is the computer involved in a game?
                      // true between start game and game over...


    { Private declarations }
    procedure collectholes;
    procedure holesettings;
    function findholelabel(row: integer; hole: integer): tlabel;
    function findhole(row: integer; hole: integer): tshape;
    function holenumber(name: string): integer;
    function holerow(name: string): integer;
    procedure clearnyumba(player: integer);
    procedure setnyumba(player: integer);
    procedure setplayer(pl: integer);
    procedure setcomputerplayer(pl: integer);
    procedure setnoplayer;
    procedure cleardrag;
    procedure domove(row1,hole1,row2,hole2: integer; pnyumba: boolean);

    procedure cleargame;
    procedure updatemovelistbox;
    procedure setAnimation(wait: integer);
    procedure computerplays;

    procedure asksave;

    procedure default_settings;
    procedure get_settings;
    procedure store_settings;

    function busy: boolean;

  public
    { Public declarations }
    procedure setholecontent(row: integer; hole: integer; value: integer);
    procedure setBaoPosition(pos: TBaoPosition; messages: boolean);

    procedure updateBoard(messages: boolean);
    procedure showmessage(s: string);
    procedure enginemessage(s: string);

    procedure startanimation();
    procedure stopanimation();

    procedure highlight(player, phole: integer);
    procedure nextmove;
    procedure addmove(move: string);
    procedure movefinished;
    procedure computerfinished(move: TBaoMove);

  end;

var
  BaoForm: TBaoForm;
  BaoBoard: TBaoPosition;
  manualopening: TBaoPosition;
  opening: string;
  maxsearchdepth: integer;
  searchtime: integer;
  movelimit: integer;
  ignoretakasia: boolean;
  progdir,gamesdir: string;


implementation
uses baoplayer, baogame, manualpos, gamedialog, engine, enginethread,
     gameprop, helpdlg,  enginerep, infoform;

var
  myPlayer: TBaoPlayer;
  myGame: TBaoGame;
  myPos: TBaoPosition;
  gamesecs, movesecs: integer;

{$R *.DFM}


procedure TBaoForm.FormCreate(Sender: TObject);
begin
   myPlayer := TBaoPlayer.make(self);
   collectholes;
   get_settings;
   holesettings;
   computerisplaying := (computerplaysnorth or computerplayssouth);
   startdrag := nil;
   actdrag := nil;
   clearGame;
   updateBoard(true);
   makecaption;
   progdir:=getcurrentdir;
   init_search;
end;

procedure TBaoForm.cleargame;
begin
   MyGame:=TBaoGame.EmptyGame;
   if opening='official' then
      mygame.setOpening(BAO_OFFICIALOPENING)
   else if opening='novice' then
      mygame.setOpening(BAO_NOVICEOPENING)
   else
      mygame.setOpening(manualopening);
   myPlayer.setBoard(MyGame.getOpening);

   mygame.date:=datetostr(date)+ ' '+ timetostr(time);
   if computerplaysnorth then mygame.north:='Computer';
   if computerplayssouth then mygame.south:='Computer';
   gamechanged:=false;
   computeristhinking:=false;
   computerisplaying:=false;
   gameover:=false;
   winner:=-1;
   MoveListBox.clear;
   makecaption;
   cleardrag;
end;

procedure TBaoForm.reset;
begin
   winner:=-1;
   gameOver:=false;
   cleardrag;
end;


function TBaoForm.busy;
begin
    busy:=false;
    if (Myplayer.isplaying or computeristhinking) then
    begin
       beep;
       busy:=true;
    end;
end;

// -------------

procedure TBaoForm.makeCaption;
var s: string;
begin
   s:='';
   if mygame.title<>'' then begin
      s:='Bao - '+ mygame.title;
      if mygame.south<>'' then
         s:=s+' ('+mygame.south+' vs. '+mygame.north+')';
      if gamechanged then s:=s+'*';
   end;
   if (s='') and computerplaysnorth then s:='Bao - human vs. computer';
   if (s='') and computerplayssouth then s:='Bao - computer vs. human';
   if s='' then s:='Bao - <no title>';
   caption:=s;
end;


procedure TBaoForm.nextmove;
var movecnt: integer;
begin
   movecnt := mygame.getmovenr;
   if myplayer.isanimating then begin
     movelistbox.topindex:=movecnt-6;
     movelistbox.itemindex:=movecnt-1;
   end;
end;

procedure TBaoForm.addmove(move: string);
begin
   Mygame.setmove(move);
   nextMove;
   updatemovelistbox;
   movelistbox.itemindex:=mygame.getmovenr-1;

   if computerisplaying then begin
      enginemessage('>> '+timetostr(time)+': move '+move)
   end;
end;


procedure TBaoForm.setholecontent(row: integer; hole: integer; value: integer);
var lab: Tlabel;
begin
    lab := findholelabel(row,hole);
    if lab = nil then exit;
    if value=0 then lab.caption:=''
    else lab.caption := inttostr(value);
end;

procedure TBaoForm.clearnyumba(player: integer);
//var hole: Tshape; row: integer;
begin
(*    if player = 0 then row:=ROWAA else row:=ROWA;
    hole := findhole(row,NYUMBA+1);
    if hole = nil then exit;
    hole.Shape := stCircle;
*)
end;

procedure TBaoForm.setnyumba(player: integer);
//var hole: Tshape; row: integer;
begin
(*
    if player = 0 then row:=ROWAA else row:=ROWA;
    hole := findhole(row,NYUMBA+1);
    if hole = nil then exit;
    hole.Shape := stRoundSquare;
*)
end;

procedure TBaoForm.setplayer(pl: integer);
var i: integer; hole: Tshape;
begin
   player := pl;
   if player = NORTH then begin
      NorthBar.Brush.color:=clNavy;
      SouthBar.Brush.Style:=bsClear;
      for i:=1 to 8 do begin
          hole:=findhole(ROWAA,i); hole.DragMode:=dmManual;
          hole:=findhole(ROWBB,i); hole.DragMode:=dmManual;
          hole:=findhole(ROWA,i); hole.DragMode:=dmAutomatic;
          hole:=findhole(ROWB,i); hole.DragMode:=dmAutomatic;
      end;
      StatusBar1.panels[1].text := 'North plays';
    end else begin
      SouthBar.Brush.color:=clNavy;
      NorthBar.Brush.Style:=bsClear;
      for i:=1 to 8 do begin
          hole:=findhole(ROWA,i); hole.DragMode:=dmManual;
          hole:=findhole(ROWB,i); hole.DragMode:=dmManual;
          hole:=findhole(ROWAA,i); hole.DragMode:=dmAutomatic;
          hole:=findhole(ROWBB,i); hole.DragMode:=dmAutomatic;
      end;
      StatusBar1.panels[1].text := 'South plays';
    end
end;

procedure TBaoForm.setcomputerplayer(pl: integer);
var i: integer; hole: Tshape;
begin
   for i:=1 to 8 do begin
       hole:=findhole(ROWAA,i); hole.DragMode:=dmManual;
       hole:=findhole(ROWBB,i); hole.DragMode:=dmManual;
       hole:=findhole(ROWA,i); hole.DragMode:=dmManual;
       hole:=findhole(ROWB,i); hole.DragMode:=dmManual;
   end;

   player := pl;
   if player = NORTH then begin
      NorthBar.Brush.color:=clRed;
      SouthBar.Brush.Style:=bsClear;
      StatusBar1.panels[1].text := 'Thinking...';
    end else begin
      SouthBar.Brush.color:=clRed;
      NorthBar.Brush.Style:=bsClear;
      StatusBar1.panels[1].text := 'Thinking...';
    end
end;



procedure TBaoForm.setnoplayer;
var i: integer; hole: Tshape;
begin
   for i:=1 to 8 do begin
       hole:=findhole(ROWAA,i); hole.DragMode:=dmManual;
       hole:=findhole(ROWBB,i); hole.DragMode:=dmManual;
       hole:=findhole(ROWA,i); hole.DragMode:=dmManual;
       hole:=findhole(ROWB,i); hole.DragMode:=dmManual;
    end;
    StatusBar1.panels[1].text := 'Game over';
    NyumbaBox.enabled:=false;
    NyumbaBox.checked:=false;
end;

procedure TBaoForm.showmessage(s: string);
begin
 StatusBar1.panels[2].text := s;
end;

procedure TBaoForm.enginemessage(s: string);
begin
  Enginereportform.add(s);
end;


procedure TBaoForm.updateBoard(messages: boolean);
begin
   setBaoPosition(myplayer.getBoard, messages);
end;

procedure TBaoForm.setBaoPosition(pos: TBaoPosition; messages: boolean);
var i: integer;
begin
   myPos:=pos;
   takasa:=false;
   moveinput.text:='';
   cleardrag;
   for i:=1 to 8 do begin
      setholecontent(ROWA,i,pos.hole[NORTH,i-1]);
      setholecontent(ROWB,i,pos.hole[NORTH,16-i]);
      setholecontent(ROWAA,i,pos.hole[SOUTH,i-1]);
      setholecontent(ROWBB,i,pos.hole[SOUTH,16-i]);
   end;
   setholecontent(ROWNS,0,pos.store[NORTH]);
   setholecontent(ROWSS,0,pos.store[SOUTH]);
   if pos.ownsnyumba[NORTH] then
       setnyumba(NORTH) else clearnyumba(NORTH);
   if pos.ownsnyumba[SOUTH]  then
       setnyumba(SOUTH) else clearnyumba(SOUTH);
   setplayer(pos.player);
   northlabel.caption := '';
   southlabel.caption := '';


   if endofgame(pos) then begin
      winner := checkWinner(pos);
      gameover := true;
      setnoplayer;
      if messages then begin
        if (winner=SOUTH) then begin
           northlabel.caption := 'LOSS';
           southlabel.caption := 'WIN';
        end else begin
           northlabel.caption := 'WIN';
           southlabel.caption := 'LOSS';
        end;
      end;
      exit;
   end;


   if intakasa(pos,player) then begin
      if messages then begin
         if player=NORTH then northlabel.caption := 'TAKASA'
         else southlabel.caption := 'TAKASA';
      end;
      takasa:=true;
   end;

   if pos.intakasia<>NOTAKASIA then begin
      if messages then begin
         if player=NORTH then northlabel.caption := 'TAKASIA! (a'
               +inttostr(pos.intakasia+1)+')'
        else southlabel.caption := 'TAKASIA! (A'
               +inttostr(pos.intakasia+1)+')';
      end;
      takasa:=true;
   end;


   NyumbaBox.enabled:=false;
   NyumbaBox.checked:=false;
   if gameover then exit;

   if (player=NORTH) and (pos.ownsnyumba[NORTH]) then
      NyumbaBox.enabled:=true;
   if (player=SOUTH) and (pos.ownsnyumba[SOUTH]) then
      NyumbaBox.enabled:=true;
end;


procedure TBaoForm.collectholes;
begin
    holelabel[ROWAA,1]:=@holeaa1;
    holelabel[ROWAA,2]:=@holeaa2;
    holelabel[ROWAA,3]:=@holeaa3;
    holelabel[ROWAA,4]:=@holeaa4;
    holelabel[ROWAA,5]:=@holeaa5;
    holelabel[ROWAA,6]:=@holeaa6;
    holelabel[ROWAA,7]:=@holeaa7;
    holelabel[ROWAA,8]:=@holeaa8;
    holelabel[ROWA,1]:=@holea1;
    holelabel[ROWA,2]:=@holea2;
    holelabel[ROWA,3]:=@holea3;
    holelabel[ROWA,4]:=@holea4;
    holelabel[ROWA,5]:=@holea5;
    holelabel[ROWA,6]:=@holea6;
    holelabel[ROWA,7]:=@holea7;
    holelabel[ROWA,8]:=@holea8;
    holelabel[ROWBB,1]:=@holebb1;
    holelabel[ROWBB,2]:=@holebb2;
    holelabel[ROWBB,3]:=@holebb3;
    holelabel[ROWBB,4]:=@holebb4;
    holelabel[ROWBB,5]:=@holebb5;
    holelabel[ROWBB,6]:=@holebb6;
    holelabel[ROWBB,7]:=@holebb7;
    holelabel[ROWBB,8]:=@holebb8;
    holelabel[ROWB,1]:=@holeb1;
    holelabel[ROWB,2]:=@holeb2;
    holelabel[ROWB,3]:=@holeb3;
    holelabel[ROWB,4]:=@holeb4;
    holelabel[ROWB,5]:=@holeb5;
    holelabel[ROWB,6]:=@holeb6;
    holelabel[ROWB,7]:=@holeb7;
    holelabel[ROWB,8]:=@holeb8;

    holes[ROWAA,1]:=@sholeaa1;
    holes[ROWAA,2]:=@sholeaa2;
    holes[ROWAA,3]:=@sholeaa3;
    holes[ROWAA,4]:=@sholeaa4;
    holes[ROWAA,5]:=@sholeaa5;
    holes[ROWAA,6]:=@sholeaa6;
    holes[ROWAA,7]:=@sholeaa7;
    holes[ROWAA,8]:=@sholeaa8;
    holes[ROWA,1]:=@sholea1;
    holes[ROWA,2]:=@sholea2;
    holes[ROWA,3]:=@sholea3;
    holes[ROWA,4]:=@sholea4;
    holes[ROWA,5]:=@sholea5;
    holes[ROWA,6]:=@sholea6;
    holes[ROWA,7]:=@sholea7;
    holes[ROWA,8]:=@sholea8;
    holes[ROWBB,1]:=@sholebb1;
    holes[ROWBB,2]:=@sholebb2;
    holes[ROWBB,3]:=@sholebb3;
    holes[ROWBB,4]:=@sholebb4;
    holes[ROWBB,5]:=@sholebb5;
    holes[ROWBB,6]:=@sholebb6;
    holes[ROWBB,7]:=@sholebb7;
    holes[ROWBB,8]:=@sholebb8;
    holes[ROWB,1]:=@sholeb1;
    holes[ROWB,2]:=@sholeb2;
    holes[ROWB,3]:=@sholeb3;
    holes[ROWB,4]:=@sholeb4;
    holes[ROWB,5]:=@sholeb5;
    holes[ROWB,6]:=@sholeb6;
    holes[ROWB,7]:=@sholeb7;
    holes[ROWB,8]:=@sholeb8;
end;

function TBaoForm.findholelabel(row: integer; hole: integer): tlabel;
begin
    findholelabel := nil;
    if (row in [1..4]) and (hole in [1..8]) then begin
      findholelabel := holelabel[row,hole]^;
      exit;
    end;
    if row=ROWNS then findholelabel:=holenorth;
    if row=ROWSS then findholelabel:=holesouth;
end;

function TBaoForm.findhole(row: integer; hole: integer): tshape;
begin
    findhole := nil;
    if (row in [1..4]) and (hole in [1..8]) then begin
      findhole := holes[row,hole]^;
      exit;
    end;
    if row=ROWNS then findhole:=sholenorth;
    if row=ROWSS then findhole:=sholesouth;
end;


function TBaoForm.holenumber(name: string): integer;
var c: char;
begin
  holenumber := 0;
  if name = '' then exit;
  c :=  name[length(name)];
  if c in ['1' .. '8'] then holenumber := (ord(c)-ord('1')) + 1;
end;

function TBaoForm.holerow(name: string): integer;
begin
  holerow := 0;
  if length(name)<3 then exit;
  if name[length(name)-1] = 'a' then begin
    if name[length(name)-2] = 'a'
    then holerow:=ROWAA else holerow:=ROWA;
  end;
  if name[length(name)-1] = 'b' then begin
    if name[length(name)-2] = 'b'
    then holerow:=ROWBB else holerow:=ROWB;
  end;
end;

procedure TBaoForm.holesettings;
var i,j: integer;
begin
   for i:=1 to 4 do for j:=1 to 8 do
      holelabel[i,j]^.font.color:=clWhite;
    holenorth.font.color:=clWhite;
    holesouth.font.color:=clWhite;
end;


// ======= MOVING ========================


procedure TBaoForm.computerplays;
begin
   computeristhinking:=true;
   setcomputerplayer(player);
   computeNextMove(Mypos);
end;

procedure TBaoForm.computerfinished(move: TBaoMove);
begin
   computeristhinking:=false;
   if engine_aborted then exit;

   if not computerisplaying then exit;

   myplayer.domove(move.hole,move.dir,move.playnyumba);
   gamechanged:=true;
end;


procedure TBaoForm.domove(row1,hole1,row2,hole2: integer; pnyumba: boolean);
var
      ahole,adir,frontrow,tohole: integer;
begin

      frontrow := (player*2)+1;
      if (row1=frontrow) then
         ahole := hole1-1
      else
         ahole := 16-hole1;

      if (row2=frontrow) then
         tohole := hole2-1
      else
         tohole := 16-hole2;

      if (row1=row2) and (hole1=hole2) then begin
        // we cannot detect direction...
         if takasa or (row1<>frontrow) or (not (ahole in [0,1,6,7]))
         or (mypos.store[player]=0)then exit;
      end;

     // detect move direction indicated by the user
      if (tohole>=ahole) then adir:=1 else adir:=-1;
      if abs(ahole-tohole)>8 then adir := -adir;

      if (ahole>7) then adir:=-adir;  // meaning of L and R in backrow!

      myplayer.domove(ahole,adir,pnyumba);

      gamechanged:=true;
      makecaption;
end;


procedure TBaoForm.movefinished;
begin
   movesecs:=0;
   if gameover then begin
      computerisplaying:=false;
      exit;
   end;
   if not computerisplaying then exit;
   if ((player=south) and computerplayssouth) or
      ((player=north) and computerplaysnorth) then computerplays;
end;

// ==============



procedure TBaoForm.Timer1Timer(Sender: TObject);
begin
   Myplayer.askresume;
end;

procedure TBaoForm.startanimation();
begin
   Timer1.enabled:=true;
end;

procedure TBaoForm.stopanimation();
begin
   Timer1.enabled:=false;
end;

procedure TBaoForm.setAnimation(wait: integer);
begin
   if wait<=0 then begin
      timer1.interval:=0;
      myplayer.setanimation(false);
      animating:=false;
      animatewait:=0;
   end else begin
      timer1.interval:=wait;
      myplayer.setanimation(true);
      animating:=true;
      animatewait:=wait;
   end;
end;


procedure TBaoForm.updatemovelistbox;
var i,j,m: integer;
     s: string;
begin
    Movelistbox.Clear;
    i:=1; j:=0;
    for m:=0 to Mygame.getNumMoves-1 do begin
      s:=inttostr(i);
      if (j=0) then s:=s+'S' else s:=s+'N';
      s:=s+': '+Mygame.getMoveAt(m);
      Movelistbox.items.add(s);
      if j=1 then inc(i);  j:=1-j;
    end;
end;


// ================================
// USER INPUT  (MENU, BUTTONS ETC)
// ================================

// -------- file io ---------------

procedure TBaoForm.Load1Click(Sender: TObject);
begin
  if busy then exit;
  asksave;
  opendialog1.initialdir:=gamesdir;
  if OpenDialog1.Execute then
  begin
    cleargame;
    Mygame := TbaoGame.read(OpenDialog1.FileName);
    gamesdir := extractfiledir(OpenDialog1.FileName);
    updatemovelistbox;
    myPlayer.setBoard(MyGame.getOpening);
    ignoretakasia1.Checked := ignoretakasia;
    makecaption;
  end;
end;


procedure TBaoForm.Save1Click(Sender: TObject);
begin
  if busy then exit;
  GamePropForm.useGame(mygame);
  GamePropForm.showmodal;
  if GamePropForm.canceled then exit;

  savedialog1.initialdir:=gamesdir;
  if SaveDialog1.Execute then
  begin
    gamechanged:=false;
    Mygame.write(SaveDialog1.FileName);
    gamesdir := extractfiledir(SaveDialog1.FileName);
  end;

  makecaption;
end;


procedure TBaoForm.asksave;
begin
  if not gamechanged then exit;
  if MessageDlg('Do you want to save the current game?', mtConfirmation,
    [mbYes, mbNo], 0) = mrYes then begin
     if SaveDialog1.Execute then
     begin
        gamechanged:=false;
        Mygame.write(SaveDialog1.FileName);
     end;
  end;
end;

procedure TBaoForm.Info1Click(Sender: TObject);
begin
  if busy then exit;
  GamePropForm.useGame(mygame);
  GamePropForm.showmodal;
  makecaption;
end;

// -------------------------------


procedure TBaoForm.Stop1Click(Sender: TObject);
// abort animation
begin
   if computerisplaying then exit;
   if myplayer.isplaying then begin
       MyPlayer.askterminate;
       Myplayer.reset;
       Mygame.resetgame;
       movelistbox.itemindex:=-1;
   end;
end;

procedure TBaoForm.slow1Click(Sender: TObject);
begin
  slow1.checked:=true;
  setAnimation(1000);
  Animation1.caption := 'Animation (slow)';
end;

procedure TBaoForm.fast1Click(Sender: TObject);
begin
  fast1.checked:=true;
  setAnimation(200);
  Animation1.caption := 'Animation (fast)';
end;

procedure TBaoForm.blitz1Click(Sender: TObject);
begin
  blitz1.checked:=true;
  setAnimation(10);
  Animation1.caption := 'Animation (blitz)';
end;

procedure TBaoForm.animoff1Click(Sender: TObject);
begin
   stop1click(Sender);
   setanimation(0);
   animoff1.checked:=true;
   Animation1.caption := 'Animation (off)';
end;

procedure TBaoForm.MoveListboxDblClick(Sender: TObject);
var i: integer;
begin
  if busy or computerisplaying then exit;
  i:=movelistbox.ItemIndex;
  myplayer.playgame(mygame,i+1);
end;


procedure TBaoForm.UpButtonClick(Sender: TObject);
var i: integer;
begin
  if busy or computerisplaying then exit;
  i:=movelistbox.ItemIndex;
  if i<0 then movelistbox.ItemIndex:=0;
  myplayer.playgame(mygame,i+2);
  if not animating then movelistbox.ItemIndex:=i+1;
end;

procedure TBaoForm.DownButtonCLick(Sender: TObject);
var i: integer;
begin
  if busy or computerisplaying then exit;
  i:=movelistbox.ItemIndex;
  if i=0 then begin
    movelistbox.ItemIndex:=-1;
    movelistbox.TopIndex:=0;
    mygame.resetgame;
    myplayer.reset;
  end else begin
    myplayer.playgame(mygame,i);
    movelistbox.ItemIndex:=i-1;
  end
end;

procedure TBaoForm.BeginButtonClick(Sender: TObject);
begin
  if busy or computerisplaying then exit;
  movelistbox.ItemIndex:=-1;
  movelistbox.TopIndex:=0;
  mygame.resetgame;
  myplayer.reset;
end;

procedure TBaoForm.EndButtonClick(Sender: TObject);
begin
  if busy or computerisplaying then exit;
  myplayer.playgame(mygame,mygame.getNumMoves);
  if not animating then movelistbox.ItemIndex:=mygame.getNumMoves-1;
end;


procedure TBaoForm.Searchdepth1Click(Sender: TObject);
var s: string;
    n: integer;
begin
    if busy then exit;
    s:= inttostr(maxsearchdepth);
    s:=inputbox('Bao Search','Maximum search depth',s);
    if s<>'' then begin
       try
          n:=strtointdef(s,maxsearchdepth);
          if (n<1) then exit;
          maxsearchdepth:=n;
       except
       end;
    end;
end;

procedure TBaoForm.Searchtime1Click(Sender: TObject);
var s: string;
    n: integer;
begin
    if busy then exit;
    s:= inttostr(searchtime);
    s:=inputbox('Bao Search','Search time (sec)',s);
    if s<>'' then begin
       try
          n:=strtointdef(s,searchtime);
          if (n<1) then exit;
          searchtime:=n;
       except
       end;
    end;
end;

procedure TBaoForm.Longmovelimit1Click(Sender: TObject);
var s: string;
    n: integer;
begin
    if busy then exit;
    s:= inttostr(movelimit);
    s:=inputbox('Bao Search','Infinite Move Limit',s);
    if s<>'' then begin
       try
          n:=strtointdef(s,movelimit);
          if (n<1) then exit;
          movelimit:=n;
       except
       end;
    end;
end;


procedure TBaoForm.Compuc1Click(Sender: TObject);
begin
   if busy then exit;
   enginereportform.show;
   computeristhinking:=true;
   computenextmove(Mypos);
end;

procedure TBaoForm.Exit1Click(Sender: TObject);
begin
   if busy then exit;
   close;
end;

procedure TBaoForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caNone;
  if busy then exit;
  if not gamechanged then begin
      Action := caFree;
  end else begin
     if MessageDlg('The game has not been saved, close anyway?', mtConfirmation,
      [mbYes, mbNo], 0) = mrYes then
      Action := caFree
    else
      Action := caNone;
      exit;
  end;
  store_settings;
end;

procedure TBaoForm.Human1Click(Sender: TObject);
begin
   if busy then exit;
   computerplaysnorth:=false;
   human1.checked:=true;
   Cleargame;
end;

procedure TBaoForm.Computer1Click(Sender: TObject);
begin
   if busy then exit;
   computerplaysnorth:=true;
   computer1.checked:=true;
   computerplayssouth:=false;
   human2.checked:=true;
   Cleargame;
end;

procedure TBaoForm.Human2Click(Sender: TObject);
begin
   if busy then exit;
   computerplayssouth:=false;
   human2.checked:=true;
   Cleargame;
end;

procedure TBaoForm.Computer2Click(Sender: TObject);
begin
   if busy then exit;
   computerplayssouth:=true;
   computer2.checked:=true;
   computerplaysnorth:=false;
   human1.checked:=true;
   Cleargame;
end;

procedure TBaoForm.AbortSearch1Click(Sender: TObject);
begin
   abort_engine;
   computeristhinking:=false;
   setplayer(player);
   computerisplaying:=false;
   clocktimer.interval := 0;   
end;

procedure TBaoForm.ShowEngineReport1Click(Sender: TObject);
begin
   if busy then exit;
   enginereportform.show
end;

procedure TBaoForm.Official1Click(Sender: TObject);
begin
   if busy then exit;
   official1.checked:=true;
   opening:='official';
   Cleargame;
end;

procedure TBaoForm.Novice1Click(Sender: TObject);
begin
   if busy then exit;
   novice1.checked:=true;
   opening:='novice';
   Cleargame;
end;

procedure TBaoForm.Manual1Click(Sender: TObject);
begin
   if busy then exit;
   ManualForm.showmodal;
   if not ManualForm.canceled then begin
      manual1.checked:=true;
      opening:='manual';
      manualopening:=ManualForm.getPosition;
      Cleargame;
   end;
end;


procedure TBaoForm.Start1Click(Sender: TObject);
// start a new game...
begin
   if busy then exit;
   asksave;
   clearGame;
   GamePropForm.useGame(mygame);
   GamePropForm.showmodal;
   makecaption;
   Myplayer.reset;
   enginereportform.clear;
   enginemessage('Date: '+DateToStr(Date)+ ' time: '+ timetostr(time));
   enginemessage('New game started');
   if computerplayssouth then begin
       enginemessage('Computer plays South');
       computerisplaying:=true;
   end;
   if computerplaysNorth then begin
       enginemessage('Computer plays North');
       computerisplaying:=true;
   end;
   enginemessage('Search depth = '+inttostr(maxsearchdepth));
   enginemessage('Long move limit = '+inttostr(movelimit));
   gamesecs:=-1;
   movesecs:=-1;
   clocktimer.interval := 1000;
   if computerisplaying then begin
      init_search;
   end;
   if computerplayssouth then computerplays;
end;


procedure TBaoForm.Continue1Click(Sender: TObject);
// continue the game that is played against the computer
begin
  if busy or gameover then exit;
  if computerplayssouth or computerplaysNorth then
     computerisplaying:=true;
  clocktimer.interval := 1000;
  if ((player=south) and computerplayssouth) or
     ((player=north) and computerplaysnorth) then computerplays;
end;


procedure TBaoForm.Stop2Click(Sender: TObject);
// stop the game that is played against the computer
begin
  if busy or gameover then exit;
  if computerisplaying then begin
    if MessageDlg('Do you want to stop the current game?', mtConfirmation,
       [mbYes, mbNo], 0) = mrYes then computerisplaying := false;
  end;
   clocktimer.interval := 0;
end;

procedure TBaoForm.Undo1Click(Sender: TObject);
// remove the last move entered
begin
   if busy then exit;
   mygame.undoMove();
   updatemovelistbox;
   mygame.resetgame;
   myplayer.reset;
   if mygame.getnummoves>0 then begin
      myplayer.playgame(mygame,mygame.getNumMoves);
      if not animating then movelistbox.ItemIndex:=mygame.getNumMoves-1;
   end;
   gamechanged:=true;
   makecaption;
end;


// ------- enter move -------------

// drag and drop

procedure TBaoForm.cleardrag;
begin
   if startdrag<> nil then begin
      startdrag.pen.color := clBlack;
      startdrag.pen.style := psClear;
      startdrag.pen.width := 1;
      startdrag:=nil;
   end;
   if actdrag<> nil then begin
      actdrag.pen.color := clBlack;
      actdrag.pen.style := psClear;
      actdrag.pen.width := 1;
      actdrag:=nil;
   end;
end;

procedure TBaoForm.highlight(player, phole: integer);
var
  row, hole: integer;
begin
    if player=NORTH then begin
       if phole<8 then begin row:=ROWA; hole:= phole+1 end
       else begin row:=ROWB; hole:= 16 - phole end;
    end else begin
       if phole<8 then begin row:=ROWAA; hole:= phole+1 end
       else begin row:=ROWBB; hole:= 16 - phole end;
    end;
    startdrag := findhole(row,hole);
    startdrag.pen.color := clRed;
    startdrag.pen.style := psSolid;
    startdrag.pen.width := 3;
end;


procedure TBaoForm.sholeaa1DragDrop(Sender, Source: TObject; X, Y: Integer);
var
   rowfr, rowto, holefr, holeto: integer;
begin
   if actdrag=nil then actdrag:=startdrag;
   rowfr := holerow(startdrag.name);
   rowto := holerow(actdrag.name);
   holefr := holenumber(startdrag.name);
   holeto := holenumber(actdrag.name);
   domove(rowfr,holefr,rowto,holeto,NyumbaBox.checked);
end;


procedure TBaoForm.sholeaa1DragOver(Sender, Source: TObject; X, Y: Integer;
  State: TDragState; var Accept: Boolean);
begin
   if Tshape(sender).dragmode <> dmAutomatic then begin
      accept:=false;
      exit;
   end;
   accept := true;
   if (actdrag = sender) or (startdrag = sender) then
      exit;
   if (actdrag <> nil) then begin
        actdrag.pen.color := clBlack;
        actdrag.pen.style := psClear;
        actdrag.pen.width := 1;
   end;
   actdrag := TShape(sender);
   Tshape(sender).pen.color := clGreen;
   Tshape(sender).pen.style := psSolid;
   Tshape(sender).pen.width := 3;
end;

procedure TBaoForm.sholeaa1StartDrag(Sender: TObject;
  var DragObject: TDragObject);
begin
    if (actdrag <> nil) then begin
       actdrag.pen.color := clBlack;
       actdrag.pen.style := psClear;
       actdrag.pen.width := 1;
       actdrag := nil;
    end;
    if (startdrag <> nil) then begin
       startdrag.pen.color := clBlack;
       startdrag.pen.style := psClear;
       startdrag.pen.width := 1;
    end;
    startdrag := Tshape(sender);
   Tshape(sender).pen.color := clYellow;
   Tshape(sender).pen.style := psSolid;
   Tshape(sender).pen.width := 3;
end;

// input move as text

procedure TBaoForm.GoButtonClick(Sender: TObject);
var move: TBaoMove;
begin
   if busy or gameover then exit;
   if moveinput.text<>'' then begin
      move := strtomove(moveinput.text);
      myplayer.domove(move.hole,move.dir,move.playnyumba);
   end;
end;


procedure TBaoForm.MoveInputKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if key=VK_RETURN then GoButtonClick(Sender);
  key:=0;
end;

// help

procedure TBaoForm.rules1Click(Sender: TObject);
begin
  if busy then exit;
  helpdialog.showurl:=progdir+'\help\rules.html';
  helpdialog.hide;
  helpdialog.show;
end;

procedure TBaoForm.userguide1Click(Sender: TObject);
begin
  if busy then exit;
  helpdialog.showurl:=progdir+'\help\userguide.html';
  helpdialog.hide;  
  helpdialog.show;
end;


procedure TBaoForm.Info2Click(Sender: TObject);
begin
   info.showmodal
end;

procedure TBaoForm.FormShow(Sender: TObject);
begin
   info.showmodal;

end;


procedure TBaoForm.IgnoreTakasia1Click(Sender: TObject);
begin
    ignoretakasia := not ignoretakasia;
    IgnoreTakasia1.checked := ignoretakasia;
end;

procedure TBaoForm.Timer2Timer(Sender: TObject);
begin
   terminate_search;
   Timer2.interval := 0;
end;


// registry settings

const regkey = 'Software\IkatUm\Donkers\Bao';

procedure TBaoForm.default_settings;
begin
  RegSetString(HKEY_CURRENT_USER, regkey+'\Version','1.0');
  RegSetString(HKEY_CURRENT_USER, regkey+'\InstalledAt',Datetostr(Now));
  RegSetString(HKEY_CURRENT_USER, regkey+'\North','computer');
  computer1.Click();
  RegSetString(HKEY_CURRENT_USER, regkey+'\South','human');
  human2.Click();
  RegSetString(HKEY_CURRENT_USER, regkey+'\opening','official');
  opening:='official'; opening1.checked:=true;
  RegSetString(HKEY_CURRENT_USER, regkey+'\IgnoreTakasia','false');
  ignoretakasia:=false; IgnoreTakasia1.checked := false;
  RegSetString(HKEY_CURRENT_USER, regkey+'\Animation','fast');
  fast1.click();
  searchtime:=30;
  RegSetString(HKEY_CURRENT_USER, regkey+'\SearchTime','30');
  maxsearchdepth:=64;
  RegSetString(HKEY_CURRENT_USER, regkey+'\SearchDepth','64');
  movelimit:=100;
  RegSetString(HKEY_CURRENT_USER, regkey+'\LongMoveLimit','100');
  gamesdir:=getcurrentdir+'\games';
  RegSetString(HKEY_CURRENT_USER, regkey+'\GamePath', gamesdir);
end;

procedure TBaoForm.get_settings;
var s: string;
begin
  // check whether initialization of registry is needed
  if not RegKeyExists(HKEY_CURRENT_USER, regkey) then default_settings;
  if not RegValueExists(HKEY_CURRENT_USER, regkey+'\Version') then default_settings;
  s:='';
  RegGetString(HKEY_CURRENT_USER, regkey+'\Version',s);
  if (s<>'1.0') then default_settings;
  if not RegValueExists(HKEY_CURRENT_USER, regkey+'\InstalledAt') then default_settings;

  s:='';
  RegGetString(HKEY_CURRENT_USER, regkey+'\GamePath',s);
  if s='' then gamesdir:=getcurrentdir+'\games' else gamesdir:=s;

  s:='';
  RegGetString(HKEY_CURRENT_USER, regkey+'\North',s);
  if (s='computer') then computer1.Click() else human1.Click();

  s:='';
  RegGetString(HKEY_CURRENT_USER, regkey+'\South',s);
  if (s='computer') then computer2.Click() else human2.Click();

  s:='';
  RegGetString(HKEY_CURRENT_USER, regkey+'\IgnoreTakasia',s);
  ignoretakasia:=false; IgnoreTakasia1.checked := false;
  if (s='true') then IgnoreTakasia1.Click();

  s:='';
  RegGetString(HKEY_CURRENT_USER, regkey+'\Animation',s);
  if (s='fast') then fast1.click()
  else if (s='slow') then slow1.click()
  else if (s='blitz') then blitz1.click()
  else animoff1.click();

  s:='0';
  RegGetString(HKEY_CURRENT_USER, regkey+'\Searchtime',s);
  searchtime:=strtointdef(s,30);
  RegGetString(HKEY_CURRENT_USER, regkey+'\Searchdepth',s);
  maxsearchdepth:=strtointdef(s,64);
  RegGetString(HKEY_CURRENT_USER, regkey+'\LongMoveLimit',s);
  movelimit:=strtointdef(s,100);

  s:='';
  RegGetString(HKEY_CURRENT_USER, regkey+'\Opening',s);
  if (s='official') then begin
     opening:='official'; official1.checked:=true;
  end else if (s='novice') then begin
     opening:='novice'; novice1.checked:=true;
  end else begin
     opening:='manual'; manual1.checked:=true;
     manualopening:=strtopos(s);
  end;

end;

procedure TBaoForm.store_settings;
begin
  RegSetString(HKEY_CURRENT_USER, regkey+'\GamePath', gamesdir);
  if computerplaysnorth then
      RegSetString(HKEY_CURRENT_USER, regkey+'\North', 'computer')
  else
      RegSetString(HKEY_CURRENT_USER, regkey+'\North', 'human');
  if computerplayssouth then
      RegSetString(HKEY_CURRENT_USER, regkey+'\South', 'computer')
  else
      RegSetString(HKEY_CURRENT_USER, regkey+'\South', 'human');

  if ignoretakasia then
     RegSetString(HKEY_CURRENT_USER, regkey+'\IgnoreTakasia', 'true')
  else
     RegSetString(HKEY_CURRENT_USER, regkey+'\IgnoreTakasia', 'false');

  if fast1.checked then
       RegSetString(HKEY_CURRENT_USER, regkey+'\Animation', 'fast');
  if slow1.checked then
       RegSetString(HKEY_CURRENT_USER, regkey+'\Animation', 'slow');
  if blitz1.checked then
       RegSetString(HKEY_CURRENT_USER, regkey+'\Animation', 'blitz');
  if animoff1.checked then
       RegSetString(HKEY_CURRENT_USER, regkey+'\Animation', 'off');

   RegSetString(HKEY_CURRENT_USER, regkey+'\SearchTime', inttostr(searchtime));
   RegSetString(HKEY_CURRENT_USER, regkey+'\SearchDepth', inttostr(maxsearchdepth));
   RegSetString(HKEY_CURRENT_USER, regkey+'\LongMoveLimit', inttostr(movelimit));

   if opening='official' then
      RegSetString(HKEY_CURRENT_USER, regkey+'\Opening', 'official')
   else if opening='novice' then
      RegSetString(HKEY_CURRENT_USER, regkey+'\Opening', 'novice')
   else
     RegSetString(HKEY_CURRENT_USER, regkey+'\Opening', postostr(manualopening))
end;

procedure TBaoForm.ClockTimerTimer(Sender: TObject);
begin
  inc(gamesecs);
  inc(movesecs);
  gametime.caption:=inttostr(gamesecs div 3600)+':'+inttostr((gamesecs div 60) mod 60)+':'+inttostr(gamesecs mod 60);
  movetime.caption:=inttostr(movesecs div 3600)+':'+inttostr((movesecs div 60) mod 60)+':'+inttostr(movesecs mod 60);
  if gameover then clocktimer.interval := 0;
end;

procedure swapControls(X,Y: TControl);
var t: integer;
begin
   t:=X.left; X.left:=Y.Left; Y.left:=t;
   t:=X.top; X.top:=Y.top; Y.top:=t;
end;

procedure TBaoForm.FlipPlayers1Click(Sender: TObject);
begin
    swapControls(Slabel,Nlabel);
    swapControls(sholea1,sholeaa1);
    swapControls(sholea2,sholeaa2);
    swapControls(sholea3,sholeaa3);
    swapControls(sholea4,sholeaa4);
    swapControls(sholea5,sholeaa5);
    swapControls(sholea6,sholeaa6);
    swapControls(sholea7,sholeaa7);
    swapControls(sholea8,sholeaa8);
    swapControls(sholeb1,sholebb1);
    swapControls(sholeb2,sholebb2);
    swapControls(sholeb3,sholebb3);
    swapControls(sholeb4,sholebb4);
    swapControls(sholeb5,sholebb5);
    swapControls(sholeb6,sholebb6);
    swapControls(sholeb7,sholebb7);
    swapControls(sholeb8,sholebb8);
    swapControls(holea1,holeaa1);
    swapControls(holea2,holeaa2);
    swapControls(holea3,holeaa3);
    swapControls(holea4,holeaa4);
    swapControls(holea5,holeaa5);
    swapControls(holea6,holeaa6);
    swapControls(holea7,holeaa7);
    swapControls(holea8,holeaa8);
    swapControls(holeb1,holebb1);
    swapControls(holeb2,holebb2);
    swapControls(holeb3,holebb3);
    swapControls(holeb4,holebb4);
    swapControls(holeb5,holebb5);
    swapControls(holeb6,holebb6);
    swapControls(holeb7,holebb7);
    swapControls(holeb8,holebb8);
    swapControls(sholesouth,sholenorth);
    swapControls(holesouth,holenorth);
    swapControls(southlabel,northlabel);
    swapControls(southbar,northbar);
end;

procedure TBaoForm.seleval_defaultClick(Sender: TObject);
begin
   set_evaluator(getEvaluator('default'));
   seleval_default.checked:=true;
end;

procedure TBaoForm.seleval_ga3Click(Sender: TObject);
begin
   set_evaluator(getEvaluator('ga3'));
   seleval_ga3.checked:=true;
end;

procedure TBaoForm.seleval_tdl2bClick(Sender: TObject);
begin
   set_evaluator(getEvaluator('tdl2b'));
   seleval_tdl2b.checked:=true;
end;


procedure TBaoForm.seleval_ngnd6aClick(Sender: TObject);
begin
   set_evaluator(getEvaluator('ngnd6a'));
   seleval_ngnd6a.checked:=true;
end;

procedure TBaoForm.seleval_materialClick(Sender: TObject);
begin
   set_evaluator(getEvaluator('material'));
   seleval_material.checked:=true;
end;

procedure TBaoForm.seleval_fixedClick(Sender: TObject);
begin
   set_evaluator(getEvaluator('fixed'));
   seleval_fixed.checked:=true;
end;

procedure TBaoForm.seleval_randomClick(Sender: TObject);
begin
   set_evaluator(getEvaluator('random'));
   seleval_random.checked:=true;
end;

end.

