unit BaoRulePlayer;

interface
uses global;

type TBaoRulePlayer = class

public
  constructor make();
  procedure setMoveLimit(const n: integer);
  procedure setIgnoreTakasia(const b: boolean);
  function getBoard(): TBaoPosition;
  procedure setBoard(b: TBaoPosition);
  procedure reset;
  function domove(ahole,adir: integer; pnyumba: boolean): boolean;
  function getLastError(): string;

private
   openingboard, board: TBaoPosition;

   error: boolean;
   errorstr: string;
   player, acthole, dir: integer;
   capture, takasa, onlynyumba, playnyumba: boolean;
   longmove: boolean;

   checktakasa: boolean;
   istakasa: boolean;
   onemoveonly: boolean;
   movelimit: integer;
   ignoretakasia: boolean;

   procedure preparemove(var move: TBaoMove);
   procedure ExecuteMove;
end;


implementation

  constructor TBaoRulePlayer.make();
  begin
     movelimit:=100;
     ignoretakasia:=false;
     openingboard := BAO_OFFICIALOPENING;
     board := openingboard;
     onemoveonly:=false;
     longmove:=false;
  end;

  procedure TBaoRulePlayer.setMoveLimit(const n: integer);
  begin
     movelimit:=n;
  end;

  procedure TBaoRulePlayer.setIgnoreTakasia(const b: boolean);
  begin
     ignoretakasia:=b;
  end;


  function TBaoRulePlayer.getBoard: TBaoPosition;
   begin getBoard := board; end;

  procedure TBaoRulePlayer.setBoard(b: TBaoPosition);
  begin
     openingboard := b;
     reset;
  end;

  procedure TBaoRulePlayer.reset;
  begin
     board := openingboard;
  end;

  function TBaoRulePlayer.getLastError: String;
   begin getLastError:=errorstr; end;

   // call this domove for executing a single move,
   function TBaoRulePlayer.domove(ahole,adir: integer; pnyumba: boolean): boolean;
   var move: TBaoMove;
   begin
      checktakasa:= false; 
      move.hole:=ahole;
      move.dir:=adir;
      move.playnyumba:=pnyumba;
      move.takasa:=false;
      move.takasia:=NOTAKASIA;
      player := board.player;
      preparemove(move);
      if error then begin domove:=false; exit; end;
      ExecuteMove;
      domove:=not error;
    end;


   // ------------- PREPARE MOVE ----------------
   // check the legalness of the move and
   // fill move paramaters so the move can be executed
   // error = true if something is wrong

   procedure TBaoRulePlayer.preparemove(var move: TBaoMove);
   var
      i: integer;
      capturepossible, ownsnyumba, onlyonehole, onlysingles,
      activenyumba: boolean;

   begin
      error:=true; errorstr:='';

      acthole := move.hole;
      dir := move.dir;
      playnyumba := move.playnyumba;
      player := board.player;
      move.takasia:=board.intakasia;

      if (acthole<0) or (acthole>15) or (dir <-1) or (dir >1)
              or (not (player in [0,1])) then begin
          errorstr:='Parameters out of range';
          exit;
      end;
      if acthole>7 then dir:=-dir;

      takasa:=false;  onlynyumba := false;
      ownsnyumba := board.ownsnyumba[player];
      activenyumba := (ownsnyumba and (board.hole[player,NYUMBA]>=6));

      if not ownsnyumba then playnyumba := false;

      // cannot play from empty hole, rules 2.3, 2.4, 3.3
      if board.hole[player,acthole]=0 then begin
         errorstr:=' You Cannot select an empty hole! (rule 2.3, 2.4, 3.3)';
         exit;
      end;


      // namua stage: rule 2.1
      if board.store[player]>0 then begin    // NAMUA STAGE

         // play from front row: rule 2.3, 2.4
         if (acthole>7) then begin
            errorstr:=' You must play from front row! (rule 2.3, 2.4)';
            exit;
         end;

         // always capture, if possible (rule 2.3b)
         capturepossible := false;
         for i:=0 to 7 do
            if (board.hole[player,i]>0) and
                (board.hole[1-player,7-i]>0)   // rule 2.3
            then begin
               capturepossible:=true; break;
            end;

         if capturepossible and(board.hole[1-player,7-acthole]=0) then begin
            errorstr:=' You must capture! (rule 1.8a, 2.3b)';
            exit;
         end;

         capture := capturepossible;

         // check if direction must be specified (rule 2.3a)
         if (dir=0) then
            if (not capture) or (not (acthole in [0,1,6,7])) then begin
               errorstr:=' You must specify the move direction! (rule 2.3b)';
               exit;
            end;

         // takasa: rule 2.4
         takasa := not capturepossible;
         if takasa then begin

            // check if there is only one filled hole in the front row
            onlyonehole:=true;
            for i:=0 to 7 do
               if (i<>acthole) and (board.hole[player,i]>0) then begin
                  onlyonehole:=false;
                  break;
               end;

            // check whether takasa is played from a solitair, owned nyumba
            // with six or more stones (rule 2.4b)
            if (acthole = NYUMBA) and activenyumba then begin
               if (not onlyonehole) then begin
                  errorstr:=' You cannot takasa from the house now! (rule 2.4b)';
                  exit;
                end;
                onlynyumba := true;
            end;

            // singleton rule: rule 2.4c
            if (board.hole[player,acthole]=1) and (not onlyonehole) and
               (not ownsnyumba) then begin

               // check for only singletons
               onlysingles:=true;
               for i:=0 to 7 do
                  if (i<>acthole) and (board.hole[player,i]>1)
                  then begin
                     onlysingles:=false;
                     break;
                   end;

               if not onlysingles then begin
                   errorstr:=' You cannot play a singleton now! (rule 2.4c)';
                   exit;
               end;
            end;

            // not empty solitair kichwa in wrong directy (rule 2.4a)
            if (onlyonehole) and (acthole=0) and (dir=-1) then begin
               errorstr:='Playing that would lose the game! (rule 2.4a)';
               exit;
            end;

            if (onlyonehole) and (acthole=7) and (dir=1) then begin
               errorstr:='Playing that would lose the game! (rule 2.4a)';
               exit;
            end;

         end; // takasa

         // dir originally points to direction of kichwa
         // actual sowing is to the opposite direction
         if capture then dir := -dir;

         // get stone out of store and sow it on the board: rule 2.2
         dec(board.store[player]);
         inc(board.hole[player,acthole]);


      end else begin   //  MTAJI stage

         if dir=0 then begin
            errorstr:=' You must indicate a direction!';
            exit;
         end;


         if board.hole[player,acthole]=1 then begin
            errorstr:=' You Cannot select a singleton hole! (rule 3.3)';
            exit;
         end;

         if acthole=board.intakasia then begin
            errorstr:=' You Cannot play a takasiaed hole! (rule 4.1)';
            exit;
         end;

        // always capture, if possible
        // first try suggested move

        if not checkCapture(board,player,acthole,dir) then begin

           capturepossible := false;
           for i:=0 to 15 do
              if (board.hole[player,i]>1) and
                (checkCapture(board,player,i,1) or
                    checkCapture(board,player,i,-1))
               then begin
                  capturepossible := true;
                  break;
                end;
           if capturepossible then begin
              errorstr:=' You must capture! (rule 3.4)';
              exit;
           end;


           takasa := true;  // rule 3.5
           onlyonehole:=true;
           for i:=0 to 7 do
              if (i<>acthole) and (board.hole[player,i]>0) then begin
                 onlyonehole:=false;
                 break;
              end;

           if (onlyonehole) and (acthole=0) and (dir=-1) then begin
              errorstr:='Playing that would lose the game! (rule 3.5b)';
              exit;
           end;

           if (onlyonehole) and (acthole=7) and (dir=1) then begin
              errorstr:='Playing that would lose the game! (rule 3.5b)';
              exit;
           end;

           if (acthole>7) then for i:=0 to 7 do
              if (board.hole[player,i]>1) then begin
                 errorstr:=' You must takasa from front row! (rule 3.5a)';
                 exit;
              end;
        end;

        // houses are not owned anymore: rule 3.2
        if capture then begin
           board.ownsnyumba[player]:=false;
           board.ownsnyumba[1-player]:=false;
        end;

        // switch off capture flag, since capture will
        // take place after sowing...
        capture := false;
      end;

      // check if takasa notation '*' in loaded game is correct
      if checktakasa and (takasa<>istakasa) then begin
         if istakasa then errorstr:=' takasa expected but does not happen!'
         else errorstr:=' NO takasa expected!';
         exit;
      end;

      error:=false;
      move.takasa:=takasa;
   end;

   // -------- end prepare


   // executing a prepared move
  // the move should be prepared...
   procedure TBaoRulePlayer.ExecuteMove;
   var i,sow,sowcount: integer;
       stopmove: boolean;
   begin
      longmove:=false;
      stopmove:=false;
      sowcount:=0;
      repeat
          if capture then begin

            if acthole<=1 then dir:=1;  // rule 1.4a,b
            if acthole>=6 then dir:=-1;  // rule 1.4a,b
            sow := board.hole[1-player,7-acthole]; // rule 1.4
            board.hole[1-player,7-acthole] := 0;

            if (7-acthole=NYUMBA) then  // rule 2.5a
               setnonyumba(board,1-player);

            if dir=1 then acthole := 15 else acthole:=8;    // rule 1.4b,c
            //! shift one hole before sowing...

          end else begin

            if onlynyumba then begin  // rule 2.4b

               sow := 2;
               board.hole[player,acthole] := board.hole[player,acthole]-2;
               onlynyumba := false;

            end else begin

               sow := board.hole[player,acthole];    // also rule 1.6
               board.hole[player,acthole] := 0;

               if (acthole=NYUMBA) then
                  setnonyumba(board,player);  // rule 2.5a
            end;

          end;

          inc(sowcount,sow);

          // rule 1.3
          for i:=1 to sow do begin
             acthole := (acthole + dir) and 15;
             inc(board.hole[player,acthole]);
          end;

          capture := false;
          if board.hole[player,acthole]=1 then // rule 1.5
             stopmove := true
          else
             if not takasa // rule 1.7, 1.8
             then capture := ((acthole<8) and
                         (board.hole[1-player,7-acthole]>0)); // rule 1.6c

           // rule 1.6, 2.5b (1)
           if (not capture) and
              (not takasa) and
              (acthole=NYUMBA) and
              (board.ownsnyumba[player]) and
              (board.hole[player,acthole]>=6) and
              (not playnyumba) then stopmove:=true;

           // rule 1.6, 2.5b (2)
           if (takasa) and
              (acthole=NYUMBA) and
              (board.ownsnyumba[player]) and
              (board.hole[player,acthole]>=6) then stopmove:=true;

           // rule 4.1b
           if (takasa) and (acthole=board.intakasia)
              then stopmove:=true;

           if sowcount>movelimit then begin
              longmove:=true;
              error:=true;
              errorstr:='Long move';   
              exit;
           end;

           if checkloss(board,1-player) then stopmove:=true;

      until stopmove;

      if not endofgame(board) then
         switchplayer(board);

      if takasa then checkintakasia(board);
    end;


end.
