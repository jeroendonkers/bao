unit Engine;

// Bao search engine
// independent of user-interface!
// only unit global is needed for global types and constants
//-------------------------------

// conditional compiler defines:

//{$define LOG}  // for logging
//{$define SWITCHROOT}
{$define PV}   // for constructing and showing PV's

interface
uses global;

type engineproc = procedure(s: string);


var
                             // search statistics ------------
   nodecount: Longint;       // number of nodes generated
   maxstack: integer;        // max depth searched
   TTHits: LongWord;         // number of exact hits in the TT
   TTErrors: LongWord;       // number of TT errors (should be 0)
   longmovecount: integer;   // number of long moves encountered
   longmovelosses: integer;  // number of positions in which only long moves
                             // are present
   longmoves: array[1..10] of string; // first 10 long moves encountered
   rootplayer: integer;   // who is rootplayer
   game_score: integer;   // what is the actual game score
   searched: boolean;     // has any search been done?

procedure set_enginemessage(p: engineproc); // specify where engine output
                                            // has to go

procedure set_evaluator(e: evaluator);
procedure set_opp_evaluator(e: evaluator);

procedure set_propp_evaluators(e: array of evaluator);
procedure set_propp_probs(p: array of double);


procedure init_search;                      // create all tables etc.
procedure clear_hashtable;                  // clear the hash tables

                                         // create n hashtables
procedure make_hashtables(n: integer; bits: integer);
                                         // switch to a certain one
procedure switch_hashtable(i: integer);

procedure disable_hash;
procedure enable_hash;

function hash(const pos: TBaoPosition): LongWord; // for external use


// basic search
procedure search(startpos: TBaoPosition;
                   md: integer;     // max depth
                   ml: integer;     // long move limit
                   igtak: boolean); // ignore takasia rule?

procedure search_no_mtd(startpos: TBaoPosition;
                   md: integer;     // max depth
                   ml: integer;     // long move limit
                   igtak: boolean); // ignore takasia rule?

procedure search_using_om(startpos: TBaoPosition;
                   omd: integer;    // max om depth
                   md: integer;     // max depth
                   ml: integer;     // long move limit
                   igtak: boolean); // ignore takasia rule?


procedure search_using_omtest(startpos: TBaoPosition;
                            md: integer; ml: integer; igtak: boolean;
                            var oppmoves: string;
                            var oppval: integer;
                            perfect,perfectopp,managerisk: boolean);

procedure search_using_prom(startpos: TBaoPosition;
                            md: integer; ml: integer; igtak: boolean);
                                                                    

procedure abort_engine;              // abort the search on user's request
procedure terminate_search;          // terminate search due to time

function engine_aborted: boolean;     // Was the search aborted?

// retrieve the best move that was found by search
function get_bestmove: TbaoMove;

// execute a move in a given position and return the new position
function execute_move(pos: TBaoPosition;
        move: TBaoMove; igtak: boolean): TBaoPosition;

// produce a list of legal moves in a position
function legal_moves(pos: TBaoPosition; ml: integer; igtak: boolean):
           TBaoMoveList;

{$IFDEF PV}
function get_PV: TBaoMoveList;
{$ENDIF}

procedure engine_startlog;
procedure engine_stoplog;

implementation
uses sysutils,classes, math, mersenne, eval;

const maxdepth = 100;    // maximum search depth = maximum stack size
      mindepth = 3;
      maxopponents = 32; // maximum number of opponent types

type Tmovelist = record
    size: integer;
    move: array[0..63] of TBaoMove;
    moveval: array[0..63] of integer;
    bestmove: integer;
    trying: integer;
    dotrynextmove: boolean;
{$IFDEF PV}
    pvsize: integer;
{$ENDIF}
end;

// data structure to prevent dynamic arrays in prom search
type Tpropprecord = record
    oppval: array[0..maxopponents-1] of integer;
    oppmove: array[0..maxopponents-1] of TbaoMove;
    invers: array[0..maxopponents-1] of integer;
    maxval: array[0..maxopponents-1] of double;
    newbeta: array[0..maxopponents-1] of integer;
end;


type
  Thashtable = array of longword;
  Phashtable = ^Thashtable;

var
   abortengine: boolean;     // flag for request to abort
   searchtimesup: boolean;   // flag for request to terminate

   computedmove: TbaoMove;   // result of search

   // procedure variables
   enginemessage: engineproc;  // engine output
   evaluate: evaluator;        // normal evaluator
   opp_evaluate: evaluator;    // opponent's evaluator

   propp_evaluate: array of evaluator; // all opponent type's evaluators
   propp_prob: array of double;          // opponent-type probabilities

   max_searchdepth: integer;   // maximum search depth indicated by user
   movelimit: integer;         // limit for long moves
   ignoretakasia: boolean;     // should we ignore the takasia rule?

   nohash: boolean;            // disable hashtables

   // stack containing the generated moves at every node in the search tree
   movestack: array[0..maxdepth] of TMoveList;

   // stack containing the position at every node in the search tree
   posstack: array[0..maxdepth] of TBaoPosition;

{$IFDEF PV}
   // stack containing principal variation during search
   pvstack: array[0..maxdepth, 1..maxdepth] of TBaoMove;
{$ENDIF}

   propstack: array[0..maxdepth] of Tpropprecord;

   // depth of the stack (= actual ply in search tree)
   stack: integer;


   longmove: boolean;     // did we encounter a long move
   moveerror: boolean;    // did the last move executed cause an error?
   stopiterate: boolean;  // do we want to stop the iteration at rootlevel




   // hashcode-constants
   hashconst: array[0..31,0..63] of LongWord;
   hashconst_store: array[0..1,0..63] of LongWord;
   hashconst_house: array[0..1] of LongWord;
   hashconst_play: array[0..1] of LongWord;
   hashconst_takasia: LongWord;
   hashconst_opp: LongWord; // hashentry used by om search
   hashconst_propp: array[0..31] of LongWord; // hashentries used by prom search

   // hashkey-constants
   hashconstk: array[0..31,0..63] of LongWord;
   hashconstk_store: array[0..1,0..63] of LongWord;
   hashconstk_house: array[0..1] of LongWord;
   hashconstk_play: array[0..1] of LongWord;
   hashconstk_takasia: LongWord;
   hashconstk_opp: LongWord; // hashentry used by om search
   hashconstk_propp: array[0..31] of LongWord; // hashentries used by prom search

   hash_opp: boolean; // is the hashtable used for the opponent?
   hash_propp: integer; // for which the opponent is the hashtable used (in proms)?
                        // -1: used for player

   mask: Longword;   // indicates number of bits used for the hashcode

   hashtables: array of Thashtable;
   hashtable: Phashtable;  // actual hashtable

   // hash flags
   const TTEXACT = 0;   // exact value in hashtable
   const TTLOWER = 1;   // lower bound in hashtable
   const TTUPPER = 2;   // upper bound in hashtable

   // default increase of depth per ply
   const INCPLY = 10;

   // global alpha cutoff in om search
   var global_alpha: integer;

   // prom search specifics:

   var nopponents: integer;

// ----------  forward definitions -------------------------

function showmoves: string; forward;
procedure performmove(m: integer); forward;
procedure sortroot; forward;

{$IFDEF LOG}
var dolog: boolean;
procedure writelog(s: string); forward;
procedure createlog(); forward;
{$ENDIF}

procedure engine_startlog;
begin
{$IFDEF LOG}
  dolog:= true;
 {$ENDIF}
end;

procedure engine_stoplog;
begin
{$IFDEF LOG}
  dolog:= false;
 {$ENDIF}
end;



// --------------- move generation ---------------------------

procedure addmove(h,d: integer; pn,tak: boolean; taki: byte);
begin
  with movestack[stack] do begin
     with move[size] do begin
        hole:=h; dir:=d; playnyumba:=pn;
        takasa:=tak; takasia:=taki;
     end;
     inc(size);
  end;
end;


{$R+}
procedure generatemoves(rnd: integer);
// rnd : random number between 0 and 7
var dir,i,ii,j,k,tosow: integer;
    ncap,nsing,nfil: integer;
    hp: array[0..7] of integer;
    hb: array[0..7] of boolean;
    capture,takasa,playhouse: boolean;
    takasia: byte;

begin
  with movestack[stack], posstack[stack] do begin

{$IFDEF norandom}
     rnd:=0;
{$ELSE}
     rnd := rnd and 7;
{$ENDIF}

     takasia:=NOTAKASIA;

     // manua or mitaji?
     if store[player]>0 then begin  // manua stage

        // count filled holes, singletons and captures
        ncap:=0; nsing:=0; nfil:=0; j:=0;
        for ii:=0 to 7 do begin
          i := (ii+rnd) and 7;  // random shift
          if hole[player,i]>0 then begin
            hp[j]:=i; inc(j);
            inc(nfil);
            if hole[1-player,7-i]>0 then inc(ncap);
            if hole[player,i]=1 then inc(nsing);
          end;
        end;

        // takasa?
        if ncap=0 then begin
           takasa:=true;  // rule 2.1
           if nfil=1 then begin
              j:=hp[0]; // see rule 2.4a and 2.4b
              if (j>0) then addmove(hp[0],-1,false,takasa,takasia);
              if (j<7) then addmove(hp[0],+1,false,takasa,takasia);
           end else if nfil=nsing then begin  // rule 2.4c
              for i:=0 to nfil-1 do begin
                 addmove(hp[i],-1,false,takasa,takasia);
                 addmove(hp[i],+1,false,takasa,takasia);
              end
           end else if (ownsnyumba[player]) then begin // rule 2.4c and 2.4b
              for i:=0 to nfil-1 do begin
                j:=hp[i];
                if (j<>NYUMBA) or (hole[player,j]<6) then begin
                      addmove(j,-1,false,takasa,takasia);
                      addmove(j,+1,false,takasa,takasia);
                end;
             end
           end else begin // rule 2.4
              for i:=0 to nfil-1 do begin
                j:=hp[i];
                if hole[player,j]>1 then begin
                   addmove(j,-1,false,takasa,takasia);
                   addmove(j,+1,false,takasa,takasia);
                end;
              end
           end
        end else begin

           // Deal with playing the house
           // ----------------------------
           // First add move without playing the house and
           // immediately add the same move with playing the house.
           // During move execution a flag will be set if the second
           // move has to be executed or not.

           // capture: rule 2.3, a and b
           takasa:=false;
           playhouse := ownsnyumba[player];
           for i:=0 to 7 do hb[i]:=false;

           // first protect NYUMBA  (heuristic move ordering)
           if ownsnyumba[player] and (hole[player,NYUMBA]>0) and
             (hole[1-player,7-NYUMBA]>0) then begin
              hb[NYUMBA]:=true;
              addmove(NYUMBA,-1,false,takasa,takasia);
              addmove(NYUMBA,-1,true,takasa,takasia);
              addmove(NYUMBA,+1,false,takasa,takasia);
              addmove(NYUMBA,+1,true,takasa,takasia);
           end;

           // then attack NYUMBA  (heuristic move ordering)
           if ownsnyumba[1-player] and (hole[player,7-NYUMBA]>0) and
               (hole[1-player,NYUMBA]>0) then begin
               hb[7-NYUMBA]:=true;
               addmove(7-NYUMBA,-1,false,takasa,takasia);
               addmove(7-NYUMBA,-1,true,takasa,takasia);
               addmove(7-NYUMBA,+1,false,takasa,takasia);
               addmove(7-NYUMBA,+1,true,takasa,takasia);
          end;

           for ii:=0 to 7 do begin
             i := (ii+rnd) and 7;  // random shift
             if (hole[player,i]>0) and (hole[1-player,7-i]>0) and (not hb[i]) then begin
              if (i<=1) or (i>=6) then begin // see rule 1.4b
                  addmove(i,0,false,takasa,takasia);
                  if playhouse then addmove(i,0,true,takasa,takasia);
              end else begin // rule 2.3a
                  addmove(i,-1,false,takasa,takasia);
                  if playhouse then addmove(i,-1,true,takasa,takasia);
                  addmove(i,+1,false,takasa,takasia);
                  if playhouse then addmove(i,+1,true,takasa,takasia);
              end;
            end;
          end; // for
        end

     end else begin // mitaji stage

         // first find all possible captures

        capture:=false;
        for i:=0 to 15 do
        if (hole[player,i]>1) then begin // rule 3.3
           tosow := hole[player,i];
           if (tosow<=1) or (tosow>=16) then continue;  // rule 3.4
            dir:=-1;
            repeat
              // compute target hole j
              j := (i + dir * tosow) and 15;
              if j<=7 then begin
                if (hole[1-player,7-j]>0) then begin
                  // get content of target hole before sowing
                  if (j=i) then k:=0 else k:=hole[player,j];
                 // check whether there are enough stones...
                  if (k>0) or (tosow>=16) then begin
                    // ok, can capture
                    // takasia is not possible
                    if i<=7 then addmove(i,dir,false,false,NOTAKASIA)
                    else addmove(i,-dir,false,false,NOTAKASIA);
                    capture:=true;
                  end;
                end;
              end;
             inc(dir,2); // skip dir=0!
            until dir>1;
        end;

        if capture then exit;

        // no captures, try takasa

        takasa:=true;
        // count playable holes in front row and singletons
        nfil:=0;  j:=0; nsing:=0;
        for i:=0 to 7 do begin
           if (hole[player,i]=1) then inc(nsing);
           if (hole[player,i]>1) then begin
              inc(nfil);
              hp[j]:=i; inc(j);
           end;
        end;
        if nfil>0 then begin
           if (nfil=1) and (nsing=0) then begin // cannot be takasiaed
              j:=hp[0];
              if (j>0) then addmove(j,-1,false,takasa,takasia);
              if (j<7) then addmove(j,+1,false,takasa,takasia);
           end else for i:=0 to nfil-1 do if (hp[i]<>intakasia) then begin
              addmove(hp[i],-1,false,takasa,takasia);
              addmove(hp[i],+1,false,takasa,takasia);
           end;
        end else begin
           // count playable holes in back row for
            nfil:=0;  j:=0;
            for i:=8 to 15 do if (hole[player,i]>1) then begin
              inc(nfil);
              hp[j]:=i; inc(j);
            end;
            for i:=0 to nfil-1 do  begin
              addmove(hp[i],-1,false,takasa,takasia);
              addmove(hp[i],+1,false,takasa,takasia);
            end;
         end;
     end;
  end;
end;
{$R-}


// this function is used for move generation outside search
// only legal moves are returned
function legal_moves(pos: TBaoPosition; ml: integer; igtak: boolean):
           TBaoMoveList;
var ta: TBaoMoveList;
    n,i: integer;
begin
  posstack[0]:=pos;
  ignoretakasia:=igtak;
  movelimit:=ml;
  stack:=0;
  with movestack[0],posstack[0] do begin
     size:=0;
     generatemoves(0);
     setLength(ta,size);
     if (size=0) then begin
        result:=ta;
        exit;
     end;
     if (size=1) then begin
         ta[0]:= move[0];
         result:=ta;
         exit;
     end;
     n:=size;
     if ownsnyumba[player] then begin
        n:=0;
        dotrynextmove:=true;
        for i:=1 to size do begin
          if not dotrynextmove then begin
            dotrynextmove:=true;
            continue;
          end;
          posstack[1]:=posstack[0];
          performmove(i-1);
          if longmove then continue;
          ta[n] := move[i-1];
          inc(n);
        end;
     end else begin
        for i:=1 to size do ta[i-1]:=move[i-1];
     end;
     setlength(ta,n);
     result := ta;
   end;
end;



// ------------- Move execution --------------------------

procedure performmove(m: integer);
var acthole: integer;
    actdir: integer;
    sow, i, sowcount: integer;
    playnyumba, takasa, capture, stopmove, onlynyumba: boolean;
begin
   longmove:=false; moveerror:=false;
   with movestack[stack], posstack[stack+1] do begin
      trying := m;
      sowcount:=0;
      acthole := move[m].hole; actdir:=move[m].dir;
      takasa := move[m].takasa;
      capture := not takasa;
      playnyumba := move[m].playnyumba;
      onlynyumba := false;

      if acthole>7 then actdir:=-actdir;

      if store[player]>0 then begin    // NAMUA STAGE
        if capture then begin
           actdir := -actdir;
           if (ownsnyumba[player]) and (not playnyumba) then
              dotrynextmove := false; // proof that playing the house makes sense
        end;

        if takasa and (acthole=NYUMBA) then begin
           onlynyumba := true;
           for i:=0 to 7 do if (i<>NYUMBA) and (hole[player,i]>0) then begin
               onlynyumba := false; break;
           end;
        end;

        // get stone out of store
        dec(store[player]);
        inc(hole[player,acthole]);

      end else begin   //  MTAJI stage

        // switch off capture flag, since capture will
        // take place after sowing...
        capture := false;
      end;

      // now sow....

      stopmove:=false;
      repeat
          if capture then begin

            if acthole<=1 then actdir:=1;      // rule 1.4a,b
            if acthole>=6 then actdir:=-1;   // rule 1.4a,b
            sow := hole[1-player,7-acthole]; // rule 1.4

            if sow=0 then begin
              moveerror:=true;
              exit;
            end;

            hole[1-player,7-acthole] := 0;

            if (7-acthole=NYUMBA) then  // rule 2.5a
               ownsnyumba[1-player]:=false;

            if actdir=1 then acthole := 15 else acthole:=8;    // rule 1.4b,c
            //! shift one hole before sowing...

          end else begin

            if not onlynyumba then begin
               sow := hole[player,acthole]; // also rule 1.6
               if sow=0 then begin
                   moveerror:=true;
                   exit;
               end;

               hole[player,acthole] := 0;

               if (acthole=NYUMBA) then
                   ownsnyumba[player]:=false; // rule 2.5a

            end else begin // rule 2.4b
               sow := 2;
               hole[player,acthole] := hole[player,acthole]-2;
               onlynyumba := false;
            end;
          end;

          inc(sowcount,sow);

          // rule 1.3
          for i:=1 to sow do begin
             acthole := (acthole + actdir) and 15;
             inc(hole[player,acthole]);
          end;

          if capture then begin
             if checkloss(posstack[stack+1],1-player) then
                stopmove:=true;
          end;

          capture := false;
          if hole[player,acthole]=1 then // rule 1.5
             stopmove := true
          else
             if not takasa // rule 1.7, 1.8
             then capture := ((acthole<8) and
                         (hole[1-player,7-acthole]>0));

           // rule 1.6, 2.5b (1)
           if (not capture) and
              (not takasa) and
              (acthole=NYUMBA) and
              (ownsnyumba[player]) and
              (not playnyumba) then
           begin
               stopmove:=true;
               dotrynextmove:=true;
           end;


           // rule 1.6, 2.5b (2)
           if (takasa) and
              (acthole=NYUMBA) and
              (ownsnyumba[player]) and
              (hole[player,NYUMBA]>=6)  then stopmove:=true;


           // rule 4.1b
           if (takasa) and (acthole=intakasia)
              then stopmove:=true;

           // rule 1.5a
           if sowcount>movelimit then begin
              {$IFDEF log}
                 writelog(Stringofchar(' ',stack*2)+'Long move');
              {$ENDIF}
              longmove:=true;
              inc(longmovecount);
              if longmovecount<=10 then
                longmoves[longmovecount]:=showmoves;
              exit;
           end;

           if abortengine then exit;
      until stopmove;

      if store[player]=0 then
         ownsnyumba[player]:=false; // nyuamba cannot be used any longer

      player:=1-player;

      if takasa then checkintakasia(posstack[stack+1]);
   end;
end;


// this function is to be used outside search
function execute_move(pos: TBaoPosition;
     move: TBaoMove; igtak: boolean): TBaoPosition;
begin
  posstack[0]:=pos;
  posstack[1]:=posstack[0];
  movestack[0].move[0]:=move;
  stack:=0;
  ignoretakasia:=igtak;
  performmove(0);
  result:=posstack[1];
end;


// ------------- Hash tables -----------------------

procedure create_hashconstants;
 var i,j: integer;
begin
  if nohash then exit;
  RandomizeMT;
  for i:=0 to 31 do begin
    for j:=0 to 63 do begin
       hashconst[i,j] := GenRandIntMT;
       hashconstk[i,j] := GenRandIntMT;
    end;
    hashconst_store[0,i] := GenRandIntMT;
    hashconst_store[1,i] := GenRandIntMT;
    hashconstk_store[0,i] := GenRandIntMT;
    hashconstk_store[1,i] := GenRandIntMT;
  end;
  for i:=0 to 1 do begin
     hashconst_house[i] := GenRandIntMT;
     hashconst_play[i] := GenRandIntMT;
     hashconstk_house[i] := GenRandIntMT;
     hashconstk_play[i] := GenRandIntMT;
  end;

  hashconst_takasia := GenRandIntMT;
  hashconstk_takasia := GenRandIntMT;
  hashconst_opp := GenRandIntMT;
  hashconstk_opp := GenRandIntMT;
  for i:=0 to 31 do begin
     hashconst_propp[i] := GenRandIntMT;
     hashconstk_propp[i] := GenRandIntMT;
  end;

end;

function hashcode: LongWord;
var c: LongWord;
    i,j: integer;
begin
   if nohash then begin hashcode:=0; exit; end;
   c:=0;
   with posstack[stack] do begin
      for i:=0 to 1 do for j:=0 to 15 do
         c:=c xor hashconst[i+(j*2),hole[i,j]];
      c:=c xor hashconst_store[0,store[0]] xor hashconst_store[1,store[1]];
      if ownsnyumba[0] then c:=c xor hashconst_house[0];
      if ownsnyumba[1] then c:=c xor hashconst_house[1];
      c := c xor hashconst_play[player];
      if intakasia<>NOTAKASIA then c:=c xor hashconst_takasia;
      if hash_opp then c:=c xor hashconst_opp;
      if hash_propp>=0 then c:=c xor hashconst_propp[hash_propp];
   end;
   hashcode:=c;
end;

function hashkey: LongWord;
var c: LongWord;
    i,j: integer;
begin
   if nohash then begin hashkey:=0; exit; end;
   c:=0;
   with posstack[stack] do begin
      for i:=0 to 1 do for j:=0 to 15 do
         c:=c xor hashconstk[i+(j*2),hole[i,j]];
      c:=c xor hashconstk_store[0,store[0]] xor hashconstk_store[1,store[1]];
      if ownsnyumba[0] then c:=c xor hashconstk_house[0];
      if ownsnyumba[1] then c:=c xor hashconstk_house[1];
      c := c xor hashconstk_play[player];
      if intakasia<>NOTAKASIA then c:=c xor hashconstk_takasia;
      if hash_opp then c:=c xor hashconstk_opp;
      if hash_propp>=0 then c:=c xor hashconstk_propp[hash_propp];
   end;
   hashkey:=c;
end;


function hash(const pos: TBaoPosition): LongWord;
var c: LongWord;
    i,j: integer;
begin
   c:=0;
   with pos do begin
      for i:=0 to 1 do for j:=0 to 15 do
         c:=c xor hashconstk[i+(j*2),hole[i,j]];
      c:=c xor hashconstk_store[0,store[0]] xor hashconstk_store[1,store[1]];
      if ownsnyumba[0] then c:=c xor hashconstk_house[0];
      if ownsnyumba[1] then c:=c xor hashconstk_house[1];
      c := c xor hashconstk_play[player];
      if intakasia<>NOTAKASIA then c:=c xor hashconstk_takasia;
      if hash_opp then c:=c xor hashconstk_opp;
   end;
   hash:=c;
end;



procedure make_hashtables(n: integer; bits: integer);
var i: integer;
    nn: longword;
begin
   if nohash then exit;
   nn := longword(1) shl bits;
   mask := nn-1;
   setlength(hashtables,n);
   for i:=0 to n-1 do
      setlength(hashtables[i],nn*4);
   hashtable:=@hashtables[0];
end;

procedure switch_hashtable(i: integer);
begin
   if nohash then exit;
   hashtable := @hashtables[i];
end;

procedure clear_hashtable;
begin
  if nohash then exit;
  fillchar(hashtable^[0], length(hashtable^)*sizeof(longword),0);
end;

procedure init_hashtables;
begin
   if nohash then exit;
   create_hashconstants;
   make_hashtables(1,22);
   hash_opp:=false;
   hash_propp:=-1;
end;

// store the info on the current position in the hashtable
procedure store_hashentry(value: integer; flag: integer;
                          depth: integer);
var i: LongWord;
    w,h,k: longword;
    bm: integer;
    newvalue: integer;
begin
   if movestack[stack].bestmove<0 then exit;

   if abs(value)>9000 then begin
      // recompute absolute score  : win distance from stack depth
      newvalue := abs(value) + stack;
      if value<0 then newvalue:=-newvalue;
      value := newvalue;
   end;

   h:= hashcode;  k:=hashkey;
   i :=  (h and mask) shl 2;
   hashtable^[i] := k; inc(i);
   hashtable^[i] := h; inc(i);
   w := word(value);
   w := (w shl 8) or (longword(depth) and 255);
   w := (w shl 8) or (longword(flag) and 255);
   hashtable^[i] := w; inc(i);
   bm := movestack[stack].bestmove;
   with movestack[stack].move[bm] do begin
      w := (hole and 15) shl 4;
      if (dir=-1) then w := w or 1;
      if (playnyumba) then
          w := w or 2;
      if (takasa) then w := w or 4;
      w := w shl 8;
      w := w or takasia;
   end;
   hashtable^[i] := w;
end;

// compute hashkey and hashcode of the current position and return index
// return -1 if the hash-entry is empty
// return -2 if the hash-entry is occupied by another position

function check_hashentry: integer;
var i,h,k: LongWord;
begin
   if nohash then begin result:=-1; exit; end;
// !!!
//   if (hash_opp) then begin result:=-1; exit; end;
// !!!
   h:= hashcode;  k:=hashkey;
   i := (h and mask) shl 2;
   if (hashtable^[i]=0) then result:= -1  // empty entry
   else if (hashtable^[i] <> k) then result:= -2 // collision
   else if (hashtable^[i+1] <> h) then result:= -2 // collision
   else check_hashentry:= i;
end;

// get the content of the hashtable at the given index
function get_hashentry(index: integer; var value: integer; var flag: integer;
                          var depth: integer): TBaoMove;
var w: longword;
    mv: TBaoMove;
    newvalue: integer;
type words = record L,H: word end;
begin
   if nohash then begin result:=mv; exit; end;
   w :=  hashtable^[index+2];
   flag := w and 255;  w := w shr 8;
   depth := w and 255; w := w shr 8;
   value := smallint(words(w).L);

   if abs(value)>9000 then begin
      // recompute absolute score  : win distance from stack depth
      newvalue := abs(value) - stack;
      if value<0 then newvalue:=-newvalue;
      value := newvalue;
   end;

   w :=  hashtable^[index+3];
   with mv do begin
     takasia := w and 255;
     w := w shr 8;
     takasa := ((w and 4)>0);
     playnyumba := ((w and 2)>0);
     if ((w and 1)>0) then dir:=-1 else dir:=1;
     w := w shr 4;
     hole := w and 15;
   end;
   get_hashentry := mv;
end;


procedure disable_hash;
begin
  nohash:=true;
end;

procedure enable_hash;
begin
  nohash:=false;
end;


{$IFDEF PV}
// ------------ principal variation admin -----------------------

procedure copyPV;
begin
   with movestack[stack] do
      pvstack[stack][1]:=move[bestmove];
   move(pvstack[stack+1][1],pvstack[stack][2],movestack[stack+1].pvsize*sizeof(TBaoMove));
   movestack[stack].pvsize:=movestack[stack+1].pvsize+1;
end;

procedure initPV;
begin
   with movestack[stack] do
      pvstack[stack][1]:=move[bestmove];
   movestack[stack].pvsize:=1;
end;

procedure showPV;
var i: integer;
    s: string;
begin
   for i:=0 to movestack[0].pvsize div 2 do begin
       s:=s+movetostr(pvstack[0][(2*i)+1],rootplayer)+' ';
     if ((2*i)+1)<=movestack[0].pvsize then
       s:=s+movetostr(pvstack[0][(2*i)+2],1-rootplayer)+'; ';
   end;
   enginemessage('PV: '+s);
end;


function get_PV: TBaoMoveList;
var ml: TBaoMoveList;
    i: integer;
begin
   setlength(ml,movestack[0].pvsize);
   for i:=1 to movestack[0].pvsize do ml[i-1]:=pvstack[0][i];
   get_PV:=ml;
end;
{$ENDIF}

// ------------------- Search ---------------------------------


// -------- Alpha Beta (negamax version) -------------------------

function ab_search(depth, alpha, beta: integer): integer;
var i: integer;
    val,bestval: integer;
    dosearch, searched: boolean;
    oldalpha: integer;
    ttply: integer;
    ttmv: TbaoMove;
    ttscore: integer;
    ttflag: integer;
    ttindex: integer;
    ttval: integer;
{$IFDEF log}
    ttmoverefound: boolean;
{$ENDIF}
begin

{$IFDEF log}
//    writelog(Stringofchar(' ',stack*2)+'a/b: '+inttostr(alpha)+'/'+inttostr(beta));
//    writelog(Stringofchar(' ',stack*2)+postostr(posstack[stack]));
//    val:=evaluate(posstack[stack]);
//    writelog(Stringofchar(' ',stack*2)+'eval: '+inttostr(val)+' player '+inttostr(posstack[stack].player));
      ttmoverefound:=false;
{$ENDIF}

   ab_search:=0;
   inc(nodecount);
   ttply := -1;
   ttval:=0;
   oldalpha := alpha;
   bestval := -10000;
   movestack[stack].bestmove:=-1;
{$IFDEF PV}
   movestack[stack].pvsize:=0;
{$ENDIF}
   dosearch := true;
   searched := false;
   if stack>maxstack then maxstack:=stack;

   i:=checkWinner(posstack[stack]);
   if i>=0 then begin
      val:=10000-stack;
      if (i<>rootplayer) then val:=-val;
      if (posstack[stack].player<>rootplayer) then val:=-val;
      ab_search:=val;
      {$IFDEF log}
         writelog(Stringofchar(' ',stack*2)+'end of game: '+inttostr(val));
      {$ENDIF}
      exit;
   end;


   ttindex:=check_hashentry;
   if (ttindex>=0)  then begin
      ttmv := get_hashentry(ttindex,ttscore,ttflag,ttply);
      if (ttply>=depth) then begin
         if (ttflag=TTEXACT) then with movestack[stack] do begin
            inc(TThits);
            size:=1;
            move[0] := ttmv; bestmove:=0;
            moveval[0]:=ttscore;
            ab_search := ttscore;
            {$IFDEF PV}
               initPV; // only one move for the PV
            {$ENDIF}
            {$IFDEF log}
               writelog(Stringofchar(' ',stack*2)+'TT X-hit '+inttostr(ttscore));
            {$ENDIF}
            exit;
         end else if (ttflag=TTLOWER) then begin
            if (ttscore>alpha) then alpha:=ttscore;
         end else if (ttflag=TTUPPER) then begin
            if (ttscore<beta) then beta:=ttscore;
         end;
         if (alpha>=beta) then with movestack[stack] do begin
            inc(TThits);
            size:=1;
            move[0] := ttmv; bestmove:=0; moveval[0]:=ttscore;
            ab_search := ttscore;
            {$IFDEF PV}
               initPV; // only one move for the PV
            {$ENDIF}
            {$IFDEF log}
                writelog(Stringofchar(' ',stack*2)+'TT R-hit '+inttostr(ttscore));
           {$ENDIF}
            exit;
         end;

        {$IFDEF log}
           writelog(Stringofchar(' ',stack*2)+'TT a/b: '+inttostr(alpha)+'/'+inttostr(beta));
         {$ENDIF}
      end;
   end; // ttindex>=0

   if (stack=maxdepth) or (depth<INCPLY) then begin

      val:=evaluate(posstack[stack]);

      if (posstack[stack].player<>rootplayer) then val:=-val;
      if (ttply>=depth) then begin
         if (ttflag=TTUPPER) and (val>ttscore) then val := ttscore;
         if (ttflag=TTLOWER) and (val<ttscore) then val := ttscore;
      end;

      ab_search:=val;
      {$IFDEF log}
        writelog(Stringofchar(' ',stack*2)+'leaf: '+inttostr(val));
      {$ENDIF}

      // no PV entry
      exit;
   end;


   // try tt-move first


    if (ttply>=0) and (ttmv.hole>=0) then
     with movestack[stack], posstack[stack] do begin
        bestmove:=0;
        move[0]:=ttmv; size:=1;

       {$IFDEF log}
          ttmoverefound:=false;
           writelog(Stringofchar(' ',stack*2)+'do stack move '+movetostr(move[0],player));
       {$ENDIF}

        posstack[stack+1]:=posstack[stack];
        performmove(0);

        if abortengine then exit;
        if moveerror then begin inc(TTerrors);
        end else if not longmove then begin
           searched := true;
           inc(stack);
           bestval := -ab_search(depth-INCPLY,-beta,-alpha);
           ttval := bestval;  moveval[0]:=ttval;
           dec(stack);
           if abortengine then exit;
           {$IFDEF PV}
             copyPV;
           {$ENDIF}

           if searchtimesup then begin
               exit;
           end;
           if (bestVal>=beta) then dosearch := false;
       end;
  end;


  if dosearch then begin

   movestack[stack].size:=0;
   generatemoves(GenRandIntMT);



   with movestack[stack], posstack[stack] do begin

      // search extension
     if (stack>1) and (size>0) and
       (not move[0].takasa) and (movestack[stack-1].move[0].takasa)
     then inc(depth,3);

      if size=0 then begin // should never happen!
           enginemessage('Illegal position encountered: no moves');
           abortengine:=true; exit;
       end;

      dotrynextmove:=true;

      for i:=1 to size do moveval[i-1]:=0;
      for i:=1 to size do begin

         if not dotrynextmove then begin
           dotrynextmove:=true;
           continue;
         end;

         if (ttply>=0) and (equalMove(move[i-1],ttmv)) then begin

            moveval[i-1]:=ttval;

          {$IFDEF log}
              ttmoverefound:=true;
              writelog(Stringofchar(' ',stack*2)+'was stack move '+movetostr(move[i-1],player));
          {$ENDIF}


            if (ttval>=bestval) then begin
              bestval:=ttval;
              if bestval>alpha then alpha:=bestval;
              bestmove:=i-1;
              {$IFDEF PV}
                copyPV;
              {$ENDIF}
            end;
            continue;
         end;

         {$IFDEF log}
             writelog(Stringofchar(' ',stack*2)+'do move '+movetostr(move[i-1],player));
         {$ENDIF}

         posstack[stack+1]:=posstack[stack];
         performmove(i-1);
         if abortengine then exit;
         if longmove then begin
            continue;
           {$IFDEF log}
               writelog(Stringofchar(' ',stack*2)+'long move!');
           {$ENDIF}
         end;

         searched:=true;

         if bestval>alpha then alpha:=bestval;

         {$IFDEF log}
            writelog(Stringofchar(' ',stack*2)+'Searching...');
        {$ENDIF}

         inc(stack);
         val := -ab_search(depth-INCPLY,-beta,-alpha);
         moveval[i-1]:=val;

         dec(stack);

         if abortengine then exit;
         if searchtimesup then begin
            exit;
         end;

         if val>bestval then begin
            bestval:=val;
            bestmove:=i-1;
            {$IFDEF PV}
               copyPV;
            {$ENDIF}
         end;

         if bestval>=beta then begin
            break;
         end;

      end;
      {$IFDEF log}
       if (ttply>=0) and (not ttmoverefound) and (not bestval>=beta) then
       begin
          writelog(Stringofchar(' ',stack*2)+'TTMOVE not refound');
       end
       {$endif}
   end;

   if not searched then begin // only long moves here... player looses
      inc(longmovelosses);
      val:=-10000+stack;
      if (posstack[stack].player<>rootplayer) then val:=-val;
      bestval:=val;
      {$IFDEF log}
        writelog(Stringofchar(' ',stack*2)+'not searched');
      {$ENDIF}
      ab_search:=bestval;
      // no PV entry
      exit;
   end;
  end;  // if dosearch

  if (bestVal <= oldalpha) then ttflag := TTUPPER
  else if (bestVal >= beta) then ttflag := TTLOWER
  else ttflag := TTEXACT;
  store_hashEntry(bestVal,ttflag,depth);

  ab_search:=bestval;
  {$IFDEF log}
    writelog(Stringofchar(' ',stack*2)+'bestval: '+inttostr(bestval));
  {$ENDIF}

end;


// ------------ Alpha Beta search at root node --------------------

function rootsearch(depth, alpha, beta: integer): integer;
var i: integer;
    val,bestval: integer;

begin

{$IFDEF log}
    writelog('root a/b: '+inttostr(alpha)+'/'+inttostr(beta));
{$ENDIF}

   stack:=0;
   rootsearch:=0;

   inc(nodecount);
   bestval := alpha;
   movestack[0].bestmove:=0;

   with movestack[0], posstack[0] do

      for i:=1 to size do begin

         {$IFDEF log}
             writelog(Stringofchar(' ',stack*2)+'do move '+movetostr(move[i-1],player));
         {$ENDIF}

         posstack[1]:=posstack[0];
         performmove(i-1);
         if abortengine then exit;

         inc(stack);
         val := -ab_search(INCPLY*(depth-1),-beta,-bestval);
//         if val=0 then
//            enginemessage('value = zero');
         dec(stack);

         moveval[i-1]:=val;

         if abortengine then exit;
         if searchtimesup then exit;

         if val>bestval then begin
            bestval:=val;
            bestmove:=i-1;
            {$IFDEF PV}
              copyPV;
//              showPV;
            {$ENDIF}
         end;

         if bestval>=beta then begin
            break;
         end;

  end;

  // put best move in front of movelist !!!!
  sortroot;


  rootsearch:=bestval;
   {$IFDEF log}
        writelog(' root bestval: '+inttostr(bestval));
   with movestack[0], posstack[0] do
        writelog(' root bestmove: '+movetostr(move[bestmove],rootplayer));
   {$ENDIF}
end;

// --------- prepare for root search ------------------------

// look at the number of moves and check
// whether search is needed.
// and, remove unnecessary moves

function prepare_rootsearch: boolean;
var i,n: integer;
begin
   prepare_rootsearch:= false;
   with movestack[0],posstack[0] do begin
     size:=0;
     generatemoves(GenRandIntMT);
     if (size=0) then begin
          // should not happen!
         enginemessage('No legal moves!');
         exit;
     end;
     if (size=1) then begin
         enginemessage('Only one move: '+movetostr(move[0],rootplayer));
         computedmove := move[0];
         exit;
     end;
     if ownsnyumba[player] then begin
        dotrynextmove:=true;
        n:=0;

        for i:=1 to size do begin
          if not dotrynextmove then begin
            dotrynextmove:=true;
            continue;
          end;
          posstack[1]:=posstack[0];
          performmove(i-1);
          if longmove then continue;
          move[n] := move[i-1];
          inc(n);
        end;
        size:=n;         

        if (n=0) then begin
          enginemessage('Only long moves...');
          computedmove := move[0];
          exit;
        end;

        if (n=1) then begin
          enginemessage('Only one move: '+movetostr(move[0],rootplayer));
          computedmove := move[0];
          exit;
        end;
     end;
   end;
   prepare_rootsearch:= true;

 {$IFDEF log}
    writelog('PREPARE ROOT');
    for i:=1 to movestack[0].size do
         writelog(movetostr(movestack[0].move[i-1],rootplayer));
{$ENDIF}

end;


// --------- sort the moves at root level after search --------------

procedure sortroot;
var i,j,tmp: integer;
    mv: TBaoMove;
begin
   // bubbles, bubbles
   with movestack[0] do begin
       for i:=1 to size-1 do for j:=1 to size-i do begin
          if moveval[j-1]<moveval[j] then begin
             mv:=move[j-1]; move[j-1]:=move[j]; move[j]:=mv;
             tmp:=moveval[j-1]; moveval[j-1]:=moveval[j]; moveval[j]:=tmp;
          end;
       end;
       bestmove:=0;
   end;

 {$IFDEF log}
    writelog('ROOT SORT');
    for i:=1 to movestack[0].size do
         writelog(movetostr(movestack[0].move[i-1],rootplayer));
{$ENDIF}
end;


// ----------


procedure search(startpos: TBaoPosition; md: integer; ml: integer; igtak: boolean);
var move: TBaoMove;
    ms,val, bestvalue: integer;
    cmp1,cmp2,cmp3: Comp;
    lastcount: longint;
    nps,ebf: real;
    n,i, alpha, beta:integer;
    depth: integer;
    upper,lower, guess, g: integer;

begin
  computedmove.hole:=-1;
  computedmove.dir:=0;
  searchtimesup := false;
  searched:=false;
  posstack[0]:=startpos;

  if md>=maxdepth then md:=maxdepth-1;
  max_searchdepth:=md;

  movelimit:=ml;
  ignoretakasia:=igtak;


{$IFDEF log}
//    createlog;
{$ENDIF}

   if not prepare_rootsearch then begin
     game_score:=0;
     exit; // nothing to do
   end;

   enginemessage('search started ... ('+inttostr(movestack[0].size)+' moves)');
   enginemessage('game score was: '+inttostr(game_score));
   abortengine:=false;
   game_score:=0;

   hash_opp := false;
   TThits:=0; TTErrors:=0;
   nodecount:=0; lastcount:=0;
   longmovecount:=0;
   longmovelosses:=0;
   stopiterate:=false;

   rootplayer:=posstack[0].player;
   stack:=0; maxstack:=0;
   alpha := -99999;
   bestvalue := alpha;
//   if game_score>9000 then bestvalue:=game_score;

   cmp1 := TimeStamptoMSecs(DateTimetoTimestamp(Now));
   cmp2 := cmp1;
   guess := 0;
   for depth:=mindepth  to  max_searchDepth do begin
      enginemessage('depth: '+inttostr(depth));
      {$IFDEF log}
         writelog('depth: '+inttostr(depth));
      {$ENDIF}

      // MTD(F) framework
      upper:=10000; lower:=-10000; g := guess;
      repeat

         if (g = lower) then beta := g+1 else beta := g;

         {$IFDEF log}
         writelog('MTD CALL BETA ='+inttostr(beta)+' DEPTH='+inttostr(depth));
         {$ENDIF}
         val := rootsearch(depth,beta-1,beta);

         {$IFDEF log}
         writelog('MTD RETURN: VAL='+inttostr(val)+ ' move = '+movetostr(movestack[0].move[0],rootplayer));
         {$ENDIF}


         if abortengine then begin
           enginemessage('search aborted...');
           exit;
         end;

         g:=val;
         if (g < beta) then upper:=g else lower:=g;

      until (upper<=lower);

      cmp3 := TimeStamptoMSecs(DateTimetoTimestamp(Now));
      enginemessage('Searched '+ inttostr(nodecount-lastcount) + ' nodes in '+
         format('%3.3f',[(cmp3-cmp2)/1000])+' seconds'+
         ' (total: '+format('%3.3f',[(cmp3-cmp1)/1000])+' sec) '+
         'maxdepth='+inttostr(maxstack));
      cmp2:=cmp3;
      if (nodecount>lastcount) then begin
         ebf := power(nodecount-lastcount, 1.0/ depth);
         enginemessage('Effective branching factor: '+format('%2.3f',[ebf]));
      end;
      lastcount:=nodecount;

      {$IFDEF PV}
      showPV;
      {$ENDIF}

      if searchtimesup then begin
        if (val<bestvalue) then break;
        if val=0 then break;
      end else begin
//         bestvalue := val;
         bestvalue := movestack[0].moveval[movestack[0].bestmove];
         move := movestack[0].move[movestack[0].bestmove];
      end;

      enginemessage('Select move '+movetostr(move,rootplayer)+' '+inttostr(bestvalue));
      if (abs(bestvalue)>9000) and (10000-abs(bestvalue)<=depth) then break;
//      if (abs(bestvalue)>9000)  then break;
      if searchtimesup or stopiterate then break;
      sortroot;
   end;

   cmp2 := TimeStamptoMSecs(DateTimetoTimestamp(Now));
   ms:=strtoint(format('%8.0f',[cmp2-cmp1]));
   if ms=0 then nps:=0 else begin
      nps:=nodecount; nps:=nps/ms; nps:=nps*1000;
   end;

   if (stopiterate) then enginemessage('Iteration stopped...');
   if (searchtimesup) then enginemessage('Search time is up...');
   enginemessage('Searched '+inttostr(nodecount)+' nodes; '+
         inttostr(ms)+' msecs; ' + Format('%8.3f',[nps])+ ' nps.');
   enginemessage('Counted '+ inttostr(longmovecount)+ ' long moves (>'+
                        inttostr(movelimit)+  '), leadning to '+
                        inttostr(longmovelosses) + ' losses.');
   if longmovecount<10 then n:=longmovecount else n:=10;
   for i:=1 to n do
        enginemessage('Long move '+inttostr(i)+': '+longmoves[i]);
   enginemessage('TT Hits: '+inttostr(TTHits));
   enginemessage('TT Errors: '+inttostr(TTErrors));
   enginemessage('max search depth: '+inttostr(maxstack));
   enginemessage('Best move: '+movetostr(move,rootplayer)+' ' +inttostr(bestvalue));
   computedmove:=move;
   searched:=true;
   game_score := bestvalue;
end;





procedure search_no_mtd(startpos: TBaoPosition; md: integer; ml: integer; igtak: boolean);
var move: TBaoMove;
    ms,val, bestvalue: integer;
    cmp1,cmp2,cmp3: Comp;
    lastcount: longint;
    nps,ebf: real;
    n,i, alpha:integer;
    depth: integer;

begin
  computedmove.hole:=-1;
  computedmove.dir:=0;
  searchtimesup := false;
  searched:=false;
  posstack[0]:=startpos;

  if md>=maxdepth then md:=maxdepth-1;
  max_searchdepth:=md;

  movelimit:=ml;
  ignoretakasia:=igtak;


{$IFDEF log}
    createlog;
{$ENDIF}

   if not prepare_rootsearch then begin
     game_score:=0;
     exit; // nothing to do
   end;

   enginemessage('search started ... ('+inttostr(movestack[0].size)+' moves)');
   enginemessage('game score was: '+inttostr(game_score));
   abortengine:=false;
   game_score:=0;

   hash_opp := false;
   TThits:=0; TTErrors:=0;
   nodecount:=0; lastcount:=0;
   longmovecount:=0;
   longmovelosses:=0;
   stopiterate:=false;
   rootplayer:=posstack[0].player;
   stack:=0; maxstack:=0;
   alpha := -99999;
   bestvalue := alpha;
//   if game_score>9000 then bestvalue:=game_score;

   cmp1 := TimeStamptoMSecs(DateTimetoTimestamp(Now));
   cmp2 := cmp1;

   for depth:=mindepth  to  max_searchDepth do begin
      enginemessage('depth: '+inttostr(depth));
      {$IFDEF log}
         writelog('depth: '+inttostr(depth));
      {$ENDIF}

       val := rootsearch(depth,-99999,99999);
       if abortengine then begin
          enginemessage('search aborted...');
          exit;
       end;

      cmp3 := TimeStamptoMSecs(DateTimetoTimestamp(Now));
      enginemessage('Searched '+ inttostr(nodecount-lastcount) + ' nodes in '+
         format('%3.3f',[(cmp3-cmp2)/1000])+' seconds'+
         ' (total: '+format('%3.3f',[(cmp3-cmp1)/1000])+' sec) '+
         'maxdepth='+inttostr(maxstack));
      cmp2:=cmp3;
      if (nodecount>lastcount) then begin
         ebf := power(nodecount-lastcount, 1.0/ depth);
         enginemessage('Effective branching factor: '+format('%2.3f',[ebf]));
      end;
      lastcount:=nodecount;

      {$IFDEF PV}
      showPV;
      {$ENDIF}

      if searchtimesup then begin
        if (val<bestvalue) then break;
        if val=0 then break;
      end else begin
         bestvalue := val;
         move := movestack[0].move[movestack[0].bestmove];
      end;

      enginemessage('Select move '+movetostr(move,rootplayer)+' '+inttostr(bestvalue));
      if (abs(bestvalue)>9000) and (10000-abs(bestvalue)<=depth) then break;
//      if (abs(bestvalue)>9000)  then break;
      if searchtimesup or stopiterate then break;
      sortroot;
   end;

   cmp2 := TimeStamptoMSecs(DateTimetoTimestamp(Now));
   ms:=strtoint(format('%8.0f',[cmp2-cmp1]));
   if ms=0 then nps:=0 else begin
      nps:=nodecount; nps:=nps/ms; nps:=nps*1000;
   end;

   if (stopiterate) then enginemessage('Iteration stopped...');
   if (searchtimesup) then enginemessage('Search time is up...');
   enginemessage('Searched '+inttostr(nodecount)+' nodes; '+
         inttostr(ms)+' msecs; ' + Format('%8.3f',[nps])+ ' nps.');
   enginemessage('Counted '+ inttostr(longmovecount)+ ' long moves (>'+
                        inttostr(movelimit)+  '), leadning to '+
                        inttostr(longmovelosses) + ' losses.');
   if longmovecount<10 then n:=longmovecount else n:=10;
   for i:=1 to n do
        enginemessage('Long move '+inttostr(i)+': '+longmoves[i]);
   enginemessage('TT Hits: '+inttostr(TTHits));
   enginemessage('TT Errors: '+inttostr(TTErrors));
   enginemessage('max search depth: '+inttostr(maxstack));
   enginemessage('Best move: '+movetostr(move,rootplayer)+' ' +inttostr(bestvalue));
   computedmove:=move;
   searched:=true;
   game_score := bestvalue;


end;




 procedure init_search;
 begin
   init_hashtables;
   game_score := -99999;
 end;



// -------- OM search -------------------------


function om_search(omdepth, depth, beta: integer): integer;
var i: integer;
    val,bestval: integer;
    searched: boolean;
    tmpeval: evaluator;
begin

{$IFDEF log}
    writelog(Stringofchar(' ',stack*2)+'OM: beta: '+inttostr(beta));
{$ENDIF}

   om_search:=0;
   inc(nodecount);
   movestack[stack].bestmove:=-1;
{$IFDEF PV}
   movestack[stack].pvsize:=0;
{$ENDIF}
   searched := false;
   if stack>maxstack then maxstack:=stack;

   i:=checkWinner(posstack[stack]);
   if i>=0 then begin
      val:=10000-stack;
      if (i<>rootplayer) then val:=-val;
      om_search:=val;
      {$IFDEF log}
         writelog(Stringofchar(' ',stack*2)+'end of game: '+inttostr(val));
      {$ENDIF}
      exit;
   end;

   if (stack=maxdepth) or (depth<INCPLY) then begin

      val:=evaluate(posstack[stack]);
      om_search:=val;
      {$IFDEF log}
        writelog(Stringofchar(' ',stack*2)+'om-realleaf: '+inttostr(val));
      {$ENDIF}

      // no PV entry
      exit;
   end;



   if  (omdepth<INCPLY) then begin

      if (posstack[stack].player=rootplayer) then
         val:=ab_search(depth, global_alpha, 99999)
      else
         val:=-ab_search(depth, -99999, -global_alpha);

      if val>global_alpha then global_alpha:=val;
      om_search:=val;

      {$IFDEF log}
        writelog(Stringofchar(' ',stack*2)+'om-partleaf: '+inttostr(val));
      {$ENDIF}

      // no PV entry
      exit;
   end;

   movestack[stack].size:=0;
   generatemoves(GenRandIntMT);

   with movestack[stack], posstack[stack] do begin

      // search extension
     if (stack>1) and (size>0) and
       (not move[0].takasa) and (movestack[stack-1].move[0].takasa)
     then begin inc(depth,3); inc(omdepth,3); end;

     if size=0 then begin // should never happen!
        enginemessage('Illegal position encountered: no moves');
        abortengine:=true; exit;
     end;

     if  (posstack[stack].player<>rootplayer) then begin

        // min node: call ab-search for opponent...

        bestmove := -1;
        tmpeval := evaluate; evaluate := opp_evaluate;
        hash_opp := true;
        rootplayer:=1-rootplayer;
        val := -ab_search(depth,-beta,99999);
        rootplayer:=1-rootplayer;         
        hash_opp := false;
        evaluate := tmpeval;

        if bestmove<>-1 then begin  // ab searched found a move
           searched:=true;

          // perform selected move and call om-search...
           posstack[stack+1]:=posstack[stack];
           performmove(bestmove);

         {$IFDEF log}
             writelog(Stringofchar(' ',stack*2)+'do Opp move '+movetostr(move[bestmove],player));
         {$ENDIF}

           inc(stack);
           bestval := om_search(omdepth-INCPLY, depth-INCPLY, val+1);
           dec(stack);
        end else
           bestval := val;  // ab search did not return a move

     end else begin
        // max node: maximize over children

       dotrynextmove:=true;
       bestval := -99999;

       for i:=1 to size do begin

         if not dotrynextmove then begin
           dotrynextmove:=true;
           continue;
         end;

         {$IFDEF log}
             writelog(Stringofchar(' ',stack*2)+'do om move '+movetostr(move[i-1],player));
         {$ENDIF}

         posstack[stack+1]:=posstack[stack];
         performmove(i-1);
         if abortengine then exit;
         if longmove then begin
            continue;
           {$IFDEF log}
               writelog(Stringofchar(' ',stack*2)+'long move!');
           {$ENDIF}
         end;

         searched:=true;

         inc(stack);
         val := om_search(omdepth-INCPLY,depth-INCPLY,beta);
         dec(stack);

         if abortengine then exit;
         if searchtimesup then begin
            exit;
         end;

         if val>bestval then begin
            bestval:=val;
            bestmove:=i-1;
            {$IFDEF PV}
               copyPV;
            {$ENDIF}
         end;

      end;
   end;

   if not searched then begin // only long moves here... player looses
      inc(longmovelosses);
      val:=-10000+stack;
      if (posstack[stack].player<>rootplayer) then val:=-val;
      bestval:=val;
      {$IFDEF log}
        writelog(Stringofchar(' ',stack*2)+'not searched');
      {$ENDIF}
      om_search:=bestval;
      // no PV entry
      exit;
   end;
  end;  // if dosearch

  om_search:=bestval;
  {$IFDEF log}
    writelog(Stringofchar(' ',stack*2)+'bestval: '+inttostr(bestval));
  {$ENDIF}
end;



procedure search_using_om(startpos: TBaoPosition; omd: integer; md: integer; ml: integer; igtak: boolean);
var move: TBaoMove;
    ms,val, bestvalue: integer;
    cmp1,cmp2,cmp3: Comp;
    lastcount: longint;
    nps,ebf: real;
    n,i:integer;
    depth: integer;

begin
  computedmove.hole:=-1;
  computedmove.dir:=0;
  searchtimesup := false;
  searched:=false;
  posstack[0]:=startpos;

  if md>=maxdepth then md:=maxdepth-1;
  if omd>=maxdepth then omd:=maxdepth-1;
  max_searchdepth:=md;

  movelimit:=ml;
  ignoretakasia:=igtak;


{$IFDEF log}
//    createlog;
{$ENDIF}

   if not prepare_rootsearch then begin
     game_score:=0;
     exit; // nothing to do
   end;

   enginemessage('OM search started ... ('+inttostr(movestack[0].size)+' moves)');
   enginemessage('game score was: '+inttostr(game_score));
   abortengine:=false;
   game_score:=0;

   hash_opp := false;
   TThits:=0; TTErrors:=0;
   nodecount:=0; lastcount:=0;
   longmovecount:=0;
   longmovelosses:=0;
   stopiterate:=false;
   rootplayer:=posstack[0].player;
   stack:=0; maxstack:=0;


   cmp1 := TimeStamptoMSecs(DateTimetoTimestamp(Now));
   cmp2 := cmp1;
   bestvalue := -99999;
   for depth:=mindepth  to  max_searchDepth do begin
      enginemessage('depth: '+inttostr(depth));
      {$IFDEF log}
         writelog('depth: '+inttostr(depth)+' omdepth: '+inttostr(omd));
      {$ENDIF}

      global_alpha := -99999;
      val := om_search(INCPLY*omd, INCPLY*depth,99999);
      if abortengine then begin
        enginemessage('search aborted...');
        exit;
      end;

      cmp3 := TimeStamptoMSecs(DateTimetoTimestamp(Now));
      enginemessage('Searched '+ inttostr(nodecount-lastcount) + ' nodes in '+
         format('%3.3f',[(cmp3-cmp2)/1000])+' seconds'+
         ' (total: '+format('%3.3f',[(cmp3-cmp1)/1000])+' sec) '+
         'maxdepth='+inttostr(maxstack));
      cmp2:=cmp3;
      if (nodecount>lastcount) then begin
         ebf := power(nodecount-lastcount,1.0/depth);
         enginemessage('Effective branching factor: '+format('%2.3f',[ebf]));
      end;
      lastcount:=nodecount;

      {$IFDEF PV}
      showPV;
      {$ENDIF}

      if searchtimesup then begin
        if (val<bestvalue) then break;
        if val=0 then break;
      end else begin
         bestvalue := val;
         move := movestack[0].move[movestack[0].bestmove];
      end;

      enginemessage('Select move '+movetostr(move,rootplayer)+' '+inttostr(bestvalue));
//      if (abs(bestvalue)>9000) and (10000-abs(bestvalue)<=depth) then break;
//      if (abs(bestvalue)>9000)  then break;
      if searchtimesup or stopiterate then break;
      sortroot;
   end;

   cmp2 := TimeStamptoMSecs(DateTimetoTimestamp(Now));
   ms:=strtoint(format('%8.0f',[cmp2-cmp1]));
   if ms=0 then nps:=0 else begin
      nps:=nodecount; nps:=nps/ms; nps:=nps*1000;
   end;

   if (stopiterate) then enginemessage('Iteration stopped...');
   if (searchtimesup) then enginemessage('Search time is up...');
   enginemessage('Searched '+inttostr(nodecount)+' nodes; '+
         inttostr(ms)+' msecs; ' + Format('%8.3f',[nps])+ ' nps.');
   enginemessage('Counted '+ inttostr(longmovecount)+ ' long moves (>'+
                        inttostr(movelimit)+  '), leadning to '+
                        inttostr(longmovelosses) + ' losses.');
   if longmovecount<10 then n:=longmovecount else n:=10;
   for i:=1 to n do
        enginemessage('Long move '+inttostr(i)+': '+longmoves[i]);
   enginemessage('TT Hits: '+inttostr(TTHits));
   enginemessage('TT Errors: '+inttostr(TTErrors));
   enginemessage('max search depth: '+inttostr(maxstack));
   enginemessage('Best move: '+movetostr(move,rootplayer)+' ' +inttostr(bestvalue));
   computedmove:=move;
   game_score := bestvalue;
   searched:=true;
end;


//===================================================


function om_searchtest(depth: integer;
                       var opppredict: string;
                       var oppval: integer;
                       perfect,perfectopp,managerisk: boolean): integer;
var i,j,s0,s1,s2: integer;
    myval,riskval,baseval,val,vopp,bestval,minval: integer;
    searched,update: boolean;
    tmpeval: evaluator;
    oppmove: TBaoMove;
    oppmoves: string;
begin

   s0:=stack; s1:=stack+1; s2:=stack+2;

   om_searchtest:=0;
   inc(nodecount);
   movestack[s0].bestmove:=-1;
{$IFDEF PV}
   movestack[s0].pvsize:=0;
{$ENDIF}
   searched := false;
   if stack>maxstack then maxstack:=stack;

   i:=checkWinner(posstack[s0]);
   if i>=0 then begin
      val:=10000-stack;
      if (i<>rootplayer) then val:=-val;
      om_searchtest:=val;
      {$IFDEF log}
         writelog(Stringofchar(' ',stack*2)+'end of game: '+inttostr(val));
      {$ENDIF}
      exit;
   end;

   if managerisk then begin
      if perfect then baseval := ab_search(depth+2*INCPLY,-99999,99999)  // ab search did not return a move
      else baseval := ab_search(depth,-99999,99999);  // ab search did not return a move
   end else baseval:=0;

   movestack[s0].size:=0;
   generatemoves(GenRandIntMT);

   if movestack[s0].size=0 then begin // should never happen!
      enginemessage('Illegal position encountered: no moves');
      abortengine:=true; exit;
   end;


     // max node: maximize over children

   movestack[s0].dotrynextmove:=true;
   bestval := -99999;
   oppmoves:='?';
   for i:=1 to movestack[s0].size do begin

       if not movestack[s0].dotrynextmove then begin
          movestack[s0].dotrynextmove:=true;
          continue;
       end;

       posstack[s1]:=posstack[s0];
       performmove(i-1);

       if longmove then begin
          continue;
         {$IFDEF log}
           writelog(Stringofchar(' ',stack*2)+'long move!');
         {$ENDIF}
       end;

      searched:=true;

      inc(stack);
      tmpeval := evaluate; evaluate := opp_evaluate;
      hash_opp := true;
      rootplayer:=1-rootplayer;  // BELANGRIJK!!!
      if perfectopp then vopp := ab_search(depth,-99999,99999)
      else vopp := ab_search(depth-INCPLY,-99999,99999);
      rootplayer:=1-rootplayer;
      hash_opp := false;


      evaluate := tmpeval;

      if movestack[s1].bestmove<>-1 then begin  // ab searched found a move

         searched:=true;
         oppmove:=movestack[s1].move[movestack[s1].bestmove];
         oppmoves:=movetostr(oppmove,1-rootplayer);

         minval:=88888;
         // find minimum over all equal moves
         for j:=1 to movestack[s1].size do
           if movestack[s1].moveval[j-1]=vopp then begin
             // perform selected move and call om-search...
             if j-1<>movestack[s1].bestmove then oppmoves:=oppmoves+','+movetostr(movestack[s1].move[j-1],1-rootplayer);

             posstack[s2]:=posstack[s1];
             performmove(j-1);
             inc(stack);
             if perfect then myval := ab_search(depth,-99999,99999)
             else myval := ab_search(depth-2*INCPLY,-99999,99999);

             dec(stack);
             if myval<minval then minval:=myval;
           end;
        if minval=88888 then begin
           write('!');
           if perfect then myval:=-ab_search(depth+INCPLY,-99999,99999)  // ab search did not return a move
           else myval:=-ab_search(depth-INCPLY,-99999,99999);  // ab search did not return a move
        end else myval:=minval;
      end else begin
         write('@');
         if perfect then myval := -ab_search(depth+INCPLY,-99999,99999)  // ab search did not return a move
         else myval := -ab_search(depth-INCPLY,-99999,99999);  // ab search did not return a move
      end;

      if managerisk then begin
         if perfect then riskval := -ab_search(depth+INCPLY,-99999,99999)  // ab search did not return a move
         else riskval := -ab_search(depth-INCPLY,-99999,99999);  // ab search did not return a move
      end else riskval:=myval;

      dec(stack);

      if abortengine then exit;
      if searchtimesup then begin
         exit;
      end;

      if myval>bestval then begin

         if managerisk and (riskval<myval) then begin
            if riskval<baseval then update:=false else update:=true;
         end else update:=true;

         if update then begin
            oppval:=vopp;
            opppredict:=oppmoves;
            bestval:=myval;
            movestack[s0].bestmove:=i-1;
            {$IFDEF PV}
            copyPV;
           {$ENDIF}
         end;
     end;

     game_score:=bestval;
  end;

  if not searched then begin // only long moves here... player looses
      inc(longmovelosses);
      val:=-10000+stack;
      if (posstack[stack].player<>rootplayer) then val:=-val;
      bestval:=val;
      {$IFDEF log}
        writelog(Stringofchar(' ',stack*2)+'not searched');
      {$ENDIF}
      om_searchtest:=bestval;
      // no PV entry
      exit;
  end;

  om_searchtest:=bestval;
  {$IFDEF log}
    writelog(Stringofchar(' ',stack*2)+'bestval: '+inttostr(bestval));
  {$ENDIF}
end;






procedure search_using_omtest(startpos: TBaoPosition;
                            md: integer; ml: integer; igtak: boolean;
                            var oppmoves: string;
                            var oppval: integer;
                            perfect,perfectopp,managerisk: boolean);
var move: TBaoMove;
    ms,val, bestvalue: integer;
    cmp1,cmp2,cmp3: Comp;
    lastcount: longint;
    nps,ebf: real;
    n,i:integer;
    depth: integer;

begin
  computedmove.hole:=-1;
  computedmove.dir:=0;
  searchtimesup := false;
  searched:=false;
  posstack[0]:=startpos;

  if md>=maxdepth then md:=maxdepth-1;
  max_searchdepth:=md;

  movelimit:=ml;
  ignoretakasia:=igtak;


{$IFDEF log}
    createlog;
{$ENDIF}

   if not prepare_rootsearch then begin
     game_score:=0;
     exit; // nothing to do
   end;

   enginemessage('OM search started ... ('+inttostr(movestack[0].size)+' moves)');
   enginemessage('game score was: '+inttostr(game_score));
   abortengine:=false;
   game_score:=0;

   hash_opp := false;
   TThits:=0; TTErrors:=0;
   nodecount:=0; lastcount:=0;
   longmovecount:=0;
   longmovelosses:=0;
   stopiterate:=false;
   rootplayer:=posstack[0].player;
   stack:=0; maxstack:=0;


   cmp1 := TimeStamptoMSecs(DateTimetoTimestamp(Now));
   cmp2 := cmp1;
   bestvalue := -99999;
   for depth:=minDepth to  max_searchDepth do begin
      enginemessage('depth: '+inttostr(depth));

      global_alpha := -99999;
      val := om_searchtest(INCPLY*depth,oppmoves,oppval,perfect,perfectopp,managerisk);
      if abortengine then begin
        enginemessage('search aborted...');
        exit;
      end;

      cmp3 := TimeStamptoMSecs(DateTimetoTimestamp(Now));
      enginemessage('Searched '+ inttostr(nodecount-lastcount) + ' nodes in '+
         format('%3.3f',[(cmp3-cmp2)/1000])+' seconds'+
         ' (total: '+format('%3.3f',[(cmp3-cmp1)/1000])+' sec) '+
         'maxdepth='+inttostr(maxstack));
      cmp2:=cmp3;
      if (nodecount>lastcount) then begin
         ebf := power(nodecount-lastcount,1.0/depth);
         enginemessage('Effective branching factor: '+format('%2.3f',[ebf]));
      end;
      lastcount:=nodecount;

      {$IFDEF PV}
      showPV;
      {$ENDIF}

      if searchtimesup then begin
        if (val<bestvalue) then break;
        if val=0 then break;
      end else begin
         bestvalue := val;
         move := movestack[0].move[movestack[0].bestmove];
      end;

      enginemessage('Select move '+movetostr(move,rootplayer)+' '+inttostr(bestvalue));
      if searchtimesup or stopiterate then break;
      sortroot;
   end;

   cmp2 := TimeStamptoMSecs(DateTimetoTimestamp(Now));
   ms:=strtoint(format('%8.0f',[cmp2-cmp1]));
   if ms=0 then nps:=0 else begin
      nps:=nodecount; nps:=nps/ms; nps:=nps*1000;
   end;

   if (stopiterate) then enginemessage('Iteration stopped...');
   if (searchtimesup) then enginemessage('Search time is up...');
   enginemessage('Searched '+inttostr(nodecount)+' nodes; '+
         inttostr(ms)+' msecs; ' + Format('%8.3f',[nps])+ ' nps.');
   enginemessage('Counted '+ inttostr(longmovecount)+ ' long moves (>'+
                        inttostr(movelimit)+  '), leadning to '+
                        inttostr(longmovelosses) + ' losses.');
   if longmovecount<10 then n:=longmovecount else n:=10;
   for i:=1 to n do
        enginemessage('Long move '+inttostr(i)+': '+longmoves[i]);
   enginemessage('TT Hits: '+inttostr(TTHits));
   enginemessage('TT Errors: '+inttostr(TTErrors));
   enginemessage('max search depth: '+inttostr(maxstack));
   enginemessage('Best move: '+movetostr(move,rootplayer)+' ' +inttostr(bestvalue));
   computedmove:=move;
   game_score := bestvalue;
   searched:=true;
end;


// --------------- PROM SEARCH -----------------------------



function prom_search(omdepth,depth: integer; beta: array of integer): double;
var i,j,cnt,fnd: integer;
    val,bestval: double;
    searched,anoppmove: boolean;
{$IFDEF log}
    s: string;
    vala: double;
    tmpdolog: boolean;
{$ENDIF}
begin
{$IFNDEF log}
    val := -99999;
{$ENDIF}
    anoppmove := true;

{$IFDEF log}
    s := Stringofchar(' ',stack*2)+'PROM: beta: ';
    for i:=0 to nopponents-1 do s:=s+inttostr(beta[i])+' ';
    writelog(s);
    writelog(Stringofchar(' ',stack*2)+postostr(posstack[stack]));
    evaluate := propp_evaluate[0];
    rootplayer:=1-rootplayer;
    vala:=evaluate(posstack[stack]);
    rootplayer:=1-rootplayer;
    val:=evaluate(posstack[stack]);
    writelog(Stringofchar(' ',stack*2)+'eval: '+floattostr(val)+' '+floattostr(vala)+' player '+inttostr(posstack[stack].player));
{$ENDIF}

   prom_search:=0;
   inc(nodecount);
   movestack[stack].bestmove:=-1;
{$IFDEF PV}
   movestack[stack].pvsize:=0;
{$ENDIF}
   searched := false;
   if stack>maxstack then maxstack:=stack;

   i:=checkWinner(posstack[stack]);
   if i>=0 then begin
      val:=10000-stack;
      if (i<>rootplayer) then val:=-val;
      prom_search:=val;
      {$IFDEF log}
         writelog(Stringofchar(' ',stack*2)+'end of game: '+inttostr(round(val)));
      {$ENDIF}
      exit;
   end;

   if (stack=maxdepth) or (depth<INCPLY) then begin

      evaluate := propp_evaluate[0];
      val:=evaluate(posstack[stack]);
      prom_search:=val;
      {$IFDEF log}
        writelog(Stringofchar(' ',stack*2)+'prom-realleaf: '+floattostr(val));
      {$ENDIF}

      // no PV entry
      exit;
   end;

(*
   if  (omdepth<INCPLY) then begin

      evaluate := propp_evaluate[0];
      if (posstack[stack].player=rootplayer) then
         val:=ab_search(depth, global_alpha, 99999)
      else
         val:=-ab_search(depth, -99999, -global_alpha);

      if val>global_alpha then global_alpha:=round(val);
      prom_search:=val;

      {$IFDEF log}
        writelog(Stringofchar(' ',stack*2)+'prom-partleaf: '+floattostr(val));
      {$ENDIF}

      // no PV entry
      exit;
   end;
*)

   movestack[stack].size:=0;
   generatemoves(GenRandIntMT);

   with movestack[stack], posstack[stack], propstack[stack] do begin

      // search extension
     if (stack>1) and (size>0) and
       (not move[0].takasa) and (movestack[stack-1].move[0].takasa)
     then begin inc(depth,3); inc(omdepth,3); end;

     if size=0 then begin // should never happen!
        enginemessage('Illegal position encountered: no moves');
        abortengine:=true; exit;
     end;


     if  (posstack[stack].player<>rootplayer) then begin

        // min node: call ab-search for all opponents...

        anoppmove:=true;

        for i:=0 to nopponents-1 do begin
          bestmove := -1;
          //tmpeval := evaluate;

          evaluate := propp_evaluate[i];
          hash_propp := i;

          {$IFDEF SWITCHROOT}
          rootplayer:=1-rootplayer;
          {$ENDIF}

          {$IFDEF log}
             tmpdolog:=dolog;
//             dolog:=false;
          {$ENDIF}
          oppval[i] := -ab_search(depth,-beta[i],99999);

          {$IFDEF SWITCHROOT}
          rootplayer:=1-rootplayer;
          {$ENDIF}

          hash_propp := -1;


          if isRealValue(oppval[i]) then begin
          {$IFDEF log}
             dolog:=tmpdolog;
             writelog(Stringofchar(' ',stack*2)+'opponent type '+inttostr(i)+': '+inttostr(oppval[i])+
             ' REAL VALUE - end PROM here');
          {$ENDIF}
             prom_search:=oppval[i];
             exit;
          end;


          if bestmove=-1 then begin
          {$IFDEF log}
             dolog:=tmpdolog;
             writelog(Stringofchar(' ',stack*2)+'opponent type '+inttostr(i)+': '+inttostr(oppval[i])+
             ' no move returned by alphabeta!');
          {$ENDIF}

             val := oppval[i];
             anoppmove:=false;
             break;

          end else begin
          {$IFDEF log}
             dolog:=tmpdolog;
             writelog(Stringofchar(' ',stack*2)+'opponent type '+inttostr(i)+': '+inttostr(oppval[i])+
             ' move '+movetostr(move[bestmove],player));
          {$ENDIF}

             oppmove[i] := move[bestmove];
          end;

        end;

         evaluate := propp_evaluate[0];

        {$IFDEF log}
         s:='';
         for j:=0 to nopponents-1 do
            s:=s+movetostr(oppmove[j],player)+' ';
         writelog(Stringofchar(' ',stack*2)+'inspecting moves: '+s);
        {$ENDIF}

        // turn move[] into a set (single occurences of moves)
        // and compute invers[]: move selected by opponent type

        if anoppmove then begin

          cnt:=1;
          for i:=1 to nOpponents-1 do begin
              fnd:=-1;
              for j:=0 to cnt-1 do
                 if equalMove(oppmove[j],oppmove[i]) then begin fnd:=j; break; end;
              if fnd=-1 then begin
                 oppmove[cnt]:=oppmove[i];
                 invers[i]:=cnt;
                 inc(cnt);
              end else invers[i]:=fnd;
          end;

        {$IFDEF log}
         s:='';
         for j:=0 to cnt-1 do begin
            s:=s+movetostr(oppmove[j],player)+' ';
         end;
         writelog(Stringofchar(' ',stack*2)+'inspect moves: '+s);
        {$ENDIF}

        for j:=0 to cnt-1 do begin
            for i:=0 to nOpponents-1 do
                if (invers[i]=j) then newbeta[i]:=oppval[i]+1 else newbeta[i]:=99999;

              searched:=true;

              // perform selected move and call prom-search...
              posstack[stack+1]:=posstack[stack];
              move[0]:=oppmove[j];
              performmove(0);

             {$IFDEF log}
                 writelog(Stringofchar(' ',stack*2)+'do Opp move '+movetostr(oppmove[j],player));
             {$ENDIF}

              inc(stack);
              maxval[j] := prom_search(omdepth-INCPLY, depth-INCPLY, newbeta);
              dec(stack);

              if isRealValue(round(maxval[j])) then begin
             {$IFDEF log}
                writelog(Stringofchar(' ',stack*2)+inttostr(round(maxval[j]))+
                ' REAL VALUE - end PROM here');
             {$ENDIF}
                prom_search:=maxval[j];
                exit;
             end;

          end;

         // calculate expected value

          val := 0;
          for i:=0 to nOpponents-1 do
              val := val +  propp_prob[i] * maxval[invers[i]];
          {$IFDEF log}
              writelog(Stringofchar(' ',stack*2)+'prob val '+floattostr(val));
          {$ENDIF}

        end; // if anoppmove;

        bestval := val;

     end else begin
        // max node: maximize over children

       dotrynextmove:=true;
       bestval := -99999;

       for i:=1 to size do begin

         if not dotrynextmove then begin
           dotrynextmove:=true;
           continue;
         end;

         {$IFDEF log}
             writelog(Stringofchar(' ',stack*2)+'do om move '+movetostr(move[i-1],player));
         {$ENDIF}

         posstack[stack+1]:=posstack[stack];
         performmove(i-1);
         if abortengine then exit;
         if longmove then begin
            continue;
           {$IFDEF log}
               writelog(Stringofchar(' ',stack*2)+'long move!');
           {$ENDIF}
         end;

         searched:=true;

         inc(stack);
         val := prom_search(omdepth-INCPLY,depth-INCPLY,beta);
         dec(stack);

         if abortengine then exit;
         if searchtimesup then begin
            exit;
         end;

         if val>bestval then begin
            bestval:=val;
            bestmove:=i-1;
            {$IFDEF PV}
               copyPV;
            {$ENDIF}
         end;
      end;
   end;

   if anoppmove and (not searched) then begin // only long moves here... player looses
      inc(longmovelosses);
      val:=-10000+stack;
      if (posstack[stack].player<>rootplayer) then val:=-val;
      bestval:=val;
      {$IFDEF log}
        writelog(Stringofchar(' ',stack*2)+'not searched');
      {$ENDIF}
      prom_search:=bestval;
      // no PV entry
      exit;
   end;
  end;  // if dosearch

  prom_search:=bestval;
  {$IFDEF log}
    writelog(Stringofchar(' ',stack*2)+'bestval: '+floattostr(bestval));
  {$ENDIF}
end;





procedure search_using_prom(startpos: TBaoPosition;
                            md: integer; ml: integer; igtak: boolean);
var move: TBaoMove;
    ms: integer;
    val, bestvalue: double;
    cmp1,cmp2,cmp3: Comp;
    lastcount: longint;
    nps,ebf: real;
    n,i:integer;
    depth: integer;
    beta: array of integer;

begin
   if (high(propp_prob)<1) or (high(propp_evaluate)<1) or
   (high(propp_prob)<>high(propp_evaluate)) then begin
      enginemessage('No (proper) probabilistic opponent model defined');
      exit;
   end;

  nopponents := high(propp_prob)+1;

  computedmove.hole:=-1;
  computedmove.dir:=0;
  searchtimesup := false;
  searched:=false;
  posstack[0]:=startpos;

  if md>=maxdepth then md:=maxdepth-1;
  max_searchdepth:=md;

  movelimit:=ml;
  ignoretakasia:=igtak;


{$IFDEF log}
    createlog;
{$ENDIF}

   if not prepare_rootsearch then begin
     game_score:=0;
     exit; // nothing to do
   end;

   enginemessage('PrOM search started ... ('+inttostr(movestack[0].size)+' moves)');
   enginemessage('game score was: '+inttostr(game_score));
   abortengine:=false;
   game_score:=0;

   hash_propp := -1;
   TThits:=0; TTErrors:=0;
   nodecount:=0; lastcount:=0;
   longmovecount:=0;
   longmovelosses:=0;
   stopiterate:=false;
   rootplayer:=posstack[0].player;
   stack:=0; maxstack:=0;


   cmp1 := TimeStamptoMSecs(DateTimetoTimestamp(Now));
   cmp2 := cmp1;
   bestvalue := -99999;
   setlength(beta,nopponents);
   for depth:=minDepth to  max_searchDepth do begin
      enginemessage('depth: '+inttostr(depth));

      global_alpha := -99999;
      for i:=0 to nopponents-1 do beta[i]:=99999;
      val := prom_search(INCPLY*depth,INCPLY*depth,beta);
      if abortengine then begin
        enginemessage('search aborted...');
        exit;
      end;

      cmp3 := TimeStamptoMSecs(DateTimetoTimestamp(Now));
      enginemessage('Searched '+ inttostr(nodecount-lastcount) + ' nodes in '+
         format('%3.3f',[(cmp3-cmp2)/1000])+' seconds'+
         ' (total: '+format('%3.3f',[(cmp3-cmp1)/1000])+' sec) '+
         'maxdepth='+inttostr(maxstack));
      cmp2:=cmp3;
      if (nodecount>lastcount) then begin
         ebf := power(nodecount-lastcount,1.0/depth);
         enginemessage('Effective branching factor: '+format('%2.3f',[ebf]));
      end;
      lastcount:=nodecount;

      {$IFDEF PV}
      showPV;
      {$ENDIF}

      if searchtimesup then begin
        if (val<bestvalue) then break;
        if val=0 then break;
      end else begin
         bestvalue := val;
         move := movestack[0].move[movestack[0].bestmove];
      end;

      enginemessage('Select move '+movetostr(move,rootplayer)+' '+inttostr(round(bestvalue)));
      if searchtimesup or stopiterate then break;
      sortroot;
   end;

   beta:=nil; // deallocate

   cmp2 := TimeStamptoMSecs(DateTimetoTimestamp(Now));
   ms:=strtoint(format('%8.0f',[cmp2-cmp1]));
   if ms=0 then nps:=0 else begin
      nps:=nodecount; nps:=nps/ms; nps:=nps*1000;
   end;

   if (stopiterate) then enginemessage('Iteration stopped...');
   if (searchtimesup) then enginemessage('Search time is up...');
   enginemessage('Searched '+inttostr(nodecount)+' nodes; '+
         inttostr(ms)+' msecs; ' + Format('%8.3f',[nps])+ ' nps.');
   enginemessage('Counted '+ inttostr(longmovecount)+ ' long moves (>'+
                        inttostr(movelimit)+  '), leadning to '+
                        inttostr(longmovelosses) + ' losses.');
   if longmovecount<10 then n:=longmovecount else n:=10;
   for i:=1 to n do
        enginemessage('Long move '+inttostr(i)+': '+longmoves[i]);
   enginemessage('TT Hits: '+inttostr(TTHits));
   enginemessage('TT Errors: '+inttostr(TTErrors));
   enginemessage('max search depth: '+inttostr(maxstack));
   enginemessage('Best move: '+movetostr(move,rootplayer)+' ' +inttostr(round(bestvalue)));
   computedmove:=move;
   game_score := round(bestvalue);
   searched:=true;

end;


// --------------- Auxillaries --------------------------




procedure defaultenginemessage(s: string);
begin
   s:= '';
end;

procedure set_enginemessage(p: engineproc);
begin
   enginemessage:=p;
end;

procedure set_evaluator(e: evaluator);
begin
   evaluate:=e;
end;

procedure set_opp_evaluator(e: evaluator);
begin
   opp_evaluate:=e;
end;


procedure set_propp_evaluators(e: array of evaluator);
var i: integer;
begin
  setlength(propp_evaluate,high(e)+1);
   for i:=0 to high(e) do propp_evaluate[i]:=e[i];
end;

procedure set_propp_probs(p: array of double);
var i: integer;
begin
   setlength(propp_prob,high(p)+1);
   for i:=0 to high(p) do propp_prob[i]:=p[i];
end;

procedure abort_engine;
begin
   abortengine:=true;
end;

procedure terminate_search;
begin
   searchtimesup:=true;
end;

function engine_aborted: boolean;
begin
  engine_aborted:=abortengine;
end;

function get_bestmove: TbaoMove;
begin
   result := computedmove;
end;


{$IFDEF LOG}

var log: Text;

procedure writelog(s: string);
begin
   if not dolog then exit;
   AssignFile(log,'bao.log');
   {$I-}
   append(log);
   {$I+}
   if IOresult<>0 then begin enginemessage('cannot append log'); exit; end;
   writeln(log,s);
   close(log);
end;

procedure createlog();
begin
   AssignFile(log,'bao.log');
   {$I-}
   rewrite(log);
   {$I+}
   if IOresult<>0 then begin enginemessage('cannot log'); exit; end;
   writeln(log,' ');
   close(log);
end;

{$ENDIF}


function showmoves: string;
var s: string; i,player: integer;
begin
   s:='';
   player:=posstack[0].player;
   for i:=0 to stack do begin
      s:=s+movetostr(movestack[i].move[movestack[i].trying],player)+' ';
      player:=1-player;
   end;
   showmoves:=s;
end;


begin
   nohash:=false;
   set_enginemessage(@defaultenginemessage);
   set_evaluator(@default_evaluate);
   set_opp_evaluator(@default_evaluate);
   setlength(propp_evaluate,0);
   setlength(propp_prob,0);

{$IFDEF LOG}
   dolog:=false;
{$ENDIF}
end.


