unit eval;

// all evaluators collected in one unit


interface
uses global;

function default_evaluate(pos: TBaoPosition): integer;

implementation
uses engine;

// ---------- Evaluate -----------------------------------

function default_evaluate(pos: TBaoPosition): integer;
const STONE = 3;
      FRONT = 5;
var score,i: integer;
begin
   with pos do begin
      // stone balance
      score:=0;
      for i:=0 to 15 do begin
         inc(score,STONE * hole[rootplayer,i]);
         dec(score,STONE * hole[1-rootplayer,i]);
      end;

      // captures
      for i:=0 to 7 do begin
         if (hole[rootplayer,i]>0) and (hole[1-rootplayer,7-i]>0) then begin
            if (7-i=NYUMBA) and ownsnyumba[1-rootplayer] then inc(score,100);
            if (i=NYUMBA) and ownsnyumba[rootplayer] then dec(score,50);
            inc(score, FRONT * (hole[1-rootplayer,7-i] - hole[rootplayer,i]));
         end;
      end;

      // own nyumba
      if ownsnyumba[rootplayer] then inc(score,200);
      if ownsnyumba[1-rootplayer]then  inc(score,-200);

   end;
   if score=0 then score:=1;
   default_evaluate:=score;
end;



function material_evaluate(pos: TBaoPosition): integer;
var score,i: integer;
begin
   with pos do begin
      // stone balance
      score:=0;
      for i:=0 to 15 do begin
         inc(score,hole[rootplayer,i]);
         dec(score,hole[1-rootplayer,i]);
      end;
   end;
   material_evaluate:=score;
end;

function fixed_evaluate(pos: TBaoPosition): integer;
begin
   fixed_evaluate:=1;
end;


function random_evaluate(pos: TBaoPosition): integer;
var h: longword;
begin
   h:=hash(pos);
   h:=(h mod 500)-250;
   if h=0 then h:=1;
   random_evaluate:=h;
end;


// evaluator trained by GA
// trained at search depth of 6
// wins 71 of 100 games against default

function GA1_eval(pos: TBaoPosition): integer;
var score: integer;
begin
   with pos do begin
      // stone balance
      score:=-33*(store[rootplayer]-store[1-rootplayer]);

      inc(score,46*(hole[rootplayer,0]-hole[1-rootplayer,0]));
      inc(score,21*(hole[rootplayer,1]-hole[1-rootplayer,1]));
      inc(score,36*(hole[rootplayer,2]-hole[1-rootplayer,2]));
      inc(score,24*(hole[rootplayer,3]-hole[1-rootplayer,3]));
      inc(score,27*(hole[rootplayer,4]-hole[1-rootplayer,4]));
      inc(score,-2*(hole[rootplayer,5]-hole[1-rootplayer,5]));
      inc(score,7*(hole[rootplayer,6]-hole[1-rootplayer,6]));
      inc(score,27*(hole[rootplayer,7]-hole[1-rootplayer,7]));
      inc(score,15*(hole[rootplayer,8]-hole[1-rootplayer,8]));
      inc(score,35*(hole[rootplayer,9]-hole[1-rootplayer,9]));
      inc(score,46*(hole[rootplayer,10]-hole[1-rootplayer,10]));
      inc(score,18*(hole[rootplayer,11]-hole[1-rootplayer,11]));
      inc(score,32*(hole[rootplayer,12]-hole[1-rootplayer,12]));
      inc(score,31*(hole[rootplayer,13]-hole[1-rootplayer,13]));
      inc(score,36*(hole[rootplayer,14]-hole[1-rootplayer,14]));
      inc(score,21*(hole[rootplayer,15]-hole[1-rootplayer,15]));


      // captures
      if (hole[rootplayer,0]>0) and (hole[1-rootplayer,7]>0) then begin
         inc(score, -30 * hole[rootplayer,0]);
         inc(score, -30 * hole[1-rootplayer,7]);
      end;

      if (hole[rootplayer,1]>0) and (hole[1-rootplayer,6]>0) then begin
         inc(score, -49 * hole[rootplayer,1]);
         inc(score, -49 * hole[1-rootplayer,6]);
      end;

      if (hole[rootplayer,2]>0) and (hole[1-rootplayer,5]>0) then begin
         inc(score, 35 * hole[rootplayer,2]);
         inc(score, 35 * hole[1-rootplayer,5]);
      end;

      if (hole[rootplayer,3]>0) and (hole[1-rootplayer,4]>0) then begin
         if ownsnyumba[1-rootplayer] then inc(score,12);
         inc(score, 20 * hole[rootplayer,3]);
         inc(score, 20 * hole[1-rootplayer,4]);
      end;

      if (hole[rootplayer,4]>0) and (hole[1-rootplayer,3]>0) then begin
         if ownsnyumba[rootplayer] then dec(score,12);
         inc(score, 6 * hole[rootplayer,4]);
         inc(score, 6 * hole[1-rootplayer,3]);
      end;

      if (hole[rootplayer,5]>0) and (hole[1-rootplayer,2]>0) then begin
         inc(score, 29 * hole[rootplayer,5]);
         inc(score, 29 * hole[1-rootplayer,2]);
      end;

      if (hole[rootplayer,6]>0) and (hole[1-rootplayer,1]>0) then begin
         inc(score, -11 * hole[rootplayer,6]);
         inc(score, -11 * hole[1-rootplayer,1]);
      end;

      if (hole[rootplayer,7]>0) and (hole[1-rootplayer,0]>0) then begin
         inc(score, -25 * hole[rootplayer,7]);
         inc(score, -25 * hole[1-rootplayer,0]);
      end;

      // own nyumba
      // Admissiblity:  forget about onwning nyumba
      if ownsnyumba[rootplayer] then inc(score,23);
      if ownsnyumba[1-rootplayer]then  inc(score,23);
   end;
   if score=0 then score:=1;
   if score<-9000 then score :=-9000;
   if score>9000 then score := 9000;
   GA1_eval:=score;
end;


function GA2_eval(pos: TBaoPosition): integer;
var score: integer;
begin
   with pos do begin
      // stone balance
      score:=-36*(store[rootplayer]-store[1-rootplayer]);

      inc(score,26*(hole[rootplayer,0]-hole[1-rootplayer,0]));
      inc(score,35*(hole[rootplayer,1]-hole[1-rootplayer,1]));
      inc(score,20*(hole[rootplayer,2]-hole[1-rootplayer,2]));
      inc(score,17*(hole[rootplayer,3]-hole[1-rootplayer,3]));
      inc(score,28*(hole[rootplayer,4]-hole[1-rootplayer,4]));
      inc(score,2*(hole[rootplayer,5]-hole[1-rootplayer,5]));
      inc(score,48*(hole[rootplayer,6]-hole[1-rootplayer,6]));
      inc(score,-17*(hole[rootplayer,7]-hole[1-rootplayer,7]));
      inc(score,-7*(hole[rootplayer,8]-hole[1-rootplayer,8]));
      inc(score,-14*(hole[rootplayer,9]-hole[1-rootplayer,9]));
      inc(score,40*(hole[rootplayer,10]-hole[1-rootplayer,10]));
      inc(score,3*(hole[rootplayer,11]-hole[1-rootplayer,11]));
      inc(score,46*(hole[rootplayer,12]-hole[1-rootplayer,12]));
      inc(score,41*(hole[rootplayer,13]-hole[1-rootplayer,13]));
      inc(score,36*(hole[rootplayer,14]-hole[1-rootplayer,14]));
      inc(score,18*(hole[rootplayer,15]-hole[1-rootplayer,15]));


      // captures
      if (hole[rootplayer,0]>0) and (hole[1-rootplayer,7]>0) then begin
         inc(score, 9 * hole[rootplayer,0]);
         inc(score, 9 * hole[1-rootplayer,7]);
      end;

      if (hole[rootplayer,1]>0) and (hole[1-rootplayer,6]>0) then begin
         inc(score, -16 * hole[rootplayer,1]);
         inc(score, -16 * hole[1-rootplayer,6]);
      end;

      if (hole[rootplayer,2]>0) and (hole[1-rootplayer,5]>0) then begin
         inc(score, -44 * hole[rootplayer,2]);
         inc(score, -44 * hole[1-rootplayer,5]);
      end;

      if (hole[rootplayer,3]>0) and (hole[1-rootplayer,4]>0) then begin
         if ownsnyumba[1-rootplayer] then inc(score,-27);
         inc(score, 28 * hole[rootplayer,3]);
         inc(score, 28 * hole[1-rootplayer,4]);
      end;

      if (hole[rootplayer,4]>0) and (hole[1-rootplayer,3]>0) then begin
         if ownsnyumba[rootplayer] then dec(score,-27);
         inc(score, -37 * hole[rootplayer,4]);
         inc(score, -37 * hole[1-rootplayer,3]);
      end;

      if (hole[rootplayer,5]>0) and (hole[1-rootplayer,2]>0) then begin
         inc(score, 0 * hole[rootplayer,5]);
         inc(score, 0 * hole[1-rootplayer,2]);
      end;

      if (hole[rootplayer,6]>0) and (hole[1-rootplayer,1]>0) then begin
         inc(score, 2 * hole[rootplayer,6]);
         inc(score, 2 * hole[1-rootplayer,1]);
      end;

      if (hole[rootplayer,7]>0) and (hole[1-rootplayer,0]>0) then begin
         inc(score, 42 * hole[rootplayer,7]);
         inc(score, 42 * hole[1-rootplayer,0]);
      end;

      // own nyumba
      // Admissiblity:  forget about onwning nyumba
      if ownsnyumba[rootplayer] then inc(score,37);
      if ownsnyumba[1-rootplayer]then  inc(score,37);
   end;
   if score=0 then score:=1;
   if score<-9000 then score :=-9000;
   if score>9000 then score := 9000;
   GA2_eval:=score;
end;


function GA3_eval(pos: TBaoPosition): integer;
var score: integer;
begin
   with pos do begin
      // stone balance
      score:=-17*(store[rootplayer]-store[1-rootplayer]);

      inc(score,36*(hole[rootplayer,0]-hole[1-rootplayer,0]));
      inc(score,29*(hole[rootplayer,1]-hole[1-rootplayer,1]));
      inc(score,32*(hole[rootplayer,2]-hole[1-rootplayer,2]));
      inc(score,29*(hole[rootplayer,3]-hole[1-rootplayer,3]));
      inc(score,19*(hole[rootplayer,4]-hole[1-rootplayer,4]));
      inc(score,29*(hole[rootplayer,5]-hole[1-rootplayer,5]));
      inc(score,9*(hole[rootplayer,6]-hole[1-rootplayer,6]));
      inc(score,45*(hole[rootplayer,7]-hole[1-rootplayer,7]));
      inc(score,29*(hole[rootplayer,8]-hole[1-rootplayer,8]));
      inc(score,47*(hole[rootplayer,9]-hole[1-rootplayer,9]));
      inc(score,44*(hole[rootplayer,10]-hole[1-rootplayer,10]));
      inc(score,11*(hole[rootplayer,11]-hole[1-rootplayer,11]));
      inc(score,44*(hole[rootplayer,12]-hole[1-rootplayer,12]));
      inc(score,39*(hole[rootplayer,13]-hole[1-rootplayer,13]));
      inc(score,30*(hole[rootplayer,14]-hole[1-rootplayer,14]));
      inc(score,24*(hole[rootplayer,15]-hole[1-rootplayer,15]));


      // captures
      if (hole[rootplayer,0]>0) and (hole[1-rootplayer,7]>0) then begin
         inc(score, -46 * hole[rootplayer,0]);
         inc(score, -46 * hole[1-rootplayer,7]);
      end;

      if (hole[rootplayer,1]>0) and (hole[1-rootplayer,6]>0) then begin
         inc(score, -14 * hole[rootplayer,1]);
         inc(score, -14 * hole[1-rootplayer,6]);
      end;

      if (hole[rootplayer,2]>0) and (hole[1-rootplayer,5]>0) then begin
         inc(score, -18 * hole[rootplayer,2]);
         inc(score, -18 * hole[1-rootplayer,5]);
      end;

      if (hole[rootplayer,3]>0) and (hole[1-rootplayer,4]>0) then begin
         if ownsnyumba[1-rootplayer] then inc(score,-40);
         inc(score, 5 * hole[rootplayer,3]);
         inc(score, 5 * hole[1-rootplayer,4]);
      end;

      if (hole[rootplayer,4]>0) and (hole[1-rootplayer,3]>0) then begin
         if ownsnyumba[rootplayer] then dec(score,-40);
         inc(score, -7 * hole[rootplayer,4]);
         inc(score, -7 * hole[1-rootplayer,3]);
      end;

      if (hole[rootplayer,5]>0) and (hole[1-rootplayer,2]>0) then begin
         inc(score, -8 * hole[rootplayer,5]);
         inc(score, -8 * hole[1-rootplayer,2]);
      end;

      if (hole[rootplayer,6]>0) and (hole[1-rootplayer,1]>0) then begin
         inc(score, 15 * hole[rootplayer,6]);
         inc(score, 15 * hole[1-rootplayer,1]);
      end;

      if (hole[rootplayer,7]>0) and (hole[1-rootplayer,0]>0) then begin
         inc(score, 37 * hole[rootplayer,7]);
         inc(score, 37 * hole[1-rootplayer,0]);
      end;

      // own nyumba
      // Admissiblity:  forget about onwning nyumba
      if ownsnyumba[rootplayer] then inc(score,35);
      if ownsnyumba[1-rootplayer]then  inc(score,35);
   end;
   if score=0 then score:=1;
   if score<-9000 then score :=-9000;
   if score>9000 then score := 9000;
   GA3_eval:=score;
end;

// Td leaf- trained evaluators

Type Tdl_evalparams = record
   pstore: array[0..1] of double;
   phole: array[0..1,0..15] of double;
   pcapt: array[0..1,0..7] of double;
   pownsnyumba: array[0..1] of double;
   pcaptnyumba: array[0..1] of double;
end;

var tdl2b_param: Tdl_evalparams;

procedure init_Tdl2b;
begin
  with tdl2b_param do begin

pstore[0]:=0.351474927857933;
pstore[1]:=0.32508600926661;
phole[0,0]:=1.88013196365025;
phole[1,0]:=-1.66079635083487;
phole[0,1]:=1.56699582922007;
phole[1,1]:=-2.16905485409147;
phole[0,2]:=0.405355005310268;
phole[1,2]:=-0.658593866553247;
phole[0,3]:=1.36490456226865;
phole[1,3]:=-1.43308898965667;
phole[0,4]:=1.38899589179559;
phole[1,4]:=-1.86740571894509;
phole[0,5]:=0.459096726908925;
phole[1,5]:=-0.626610530787688;
phole[0,6]:=0.657972289739721;
phole[1,6]:=-1.60643797902663;
phole[0,7]:=1.77146058833537;
phole[1,7]:=-1.10081055020032;
phole[0,8]:=3.31786455100821;
phole[1,8]:=-3.6751352858897;
phole[0,9]:=3.10694857789177;
phole[1,9]:=-4.2539961006898;
phole[0,10]:=3.8539001319127;
phole[1,10]:=-4.04838909952595;
phole[0,11]:=4.96632872800839;
phole[1,11]:=-3.71547378130011;
phole[0,12]:=3.85892192691757;
phole[1,12]:=-4.05620116831693;
phole[0,13]:=3.43396231530757;
phole[1,13]:=-4.27286294327532;
phole[0,14]:=3.71895733323636;
phole[1,14]:=-4.00311439396186;
phole[0,15]:=3.74140930395362;
phole[1,15]:=-3.95207434437711;
pcaptnyumba[0]:=-0.00124134946096415;
pcaptnyumba[1]:=0.112300732480899;
pcapt[0,0]:=0.579827471289835;
pcapt[1,0]:=0.107170946421282;
pcapt[1,0]:=0.0840089183542116;
pcapt[1,1]:=0.898847391749641;
pcapt[0,2]:=0.487193941850986;
pcapt[1,2]:=0.424379947746011;
pcapt[0,3]:=1.24960877767929;
pcapt[1,3]:=1.1403448255455;
pcapt[0,4]:=0.43390705322692;
pcapt[1,4]:=0.445895542460544;
pcapt[0,5]:=0.646725616204503;
pcapt[1,5]:=0.856102386884854;
pcapt[0,6]:=1.80087711320325;
pcapt[1,6]:=0.760279069993385;
pcapt[0,7]:=0.572111218891128;
pcapt[1,7]:=0.0223543558713317;
pownsnyumba[0]:=0.32431004634718;
pownsnyumba[1]:=0.0147212018542772;

end;
end;

function Tdl2b_eval(pos: TBaoPosition): integer;
var score: double; i: integer;
begin
   with pos,tdl2b_param do begin
      score:=0;
      score:=score+pstore[0]*store[rootplayer];
      score:=score+pstore[1]*store[1-rootplayer];
      for i:=0 to 15 do begin
         score:=score+phole[0,i]*hole[rootplayer,i];
         score:=score+phole[1,i]*hole[1-rootplayer,i];
      end;

      // captures
      for i:=0 to 7 do begin
         if (hole[rootplayer,i]>0) and (hole[1-rootplayer,7-i]>0) then begin
            if (7-i=NYUMBA) and ownsnyumba[1-rootplayer] then score:=score+pcaptnyumba[0];
            if (i=NYUMBA) and ownsnyumba[rootplayer] then score:=score+pcaptnyumba[1];
            score:=score+pcapt[0,i] * hole[rootplayer,i];
            score:=score+pcapt[1,i] * hole[1-rootplayer,7-i];
         end;
      end;

      // own nyumba
      // Admissiblity:  forget about onwning nyumba
      if ownsnyumba[rootplayer] then score:=score+pownsnyumba[0];
      if ownsnyumba[1-rootplayer]then  score:=score+pownsnyumba[1];
   end;
   if round(score)=0 then score:=1.01;
   if score<-9000 then score :=-9000;
   if score>9000 then score := 9000;
   Tdl2b_eval:=round(score);
end;

// Normalized gaussian Nets

const NInputs = 54;
type TNGnet = record
   sigma: double;
   w: array[1..NInputs] of double;
   mu: array[1..NInputs, 1..NInputs] of double;
end;



function ngn_eval(pos: TBaoPosition; ng: TNGnet): integer;

type TInputVector = array[1..NInputs] of double;

var score: integer;
    x,g: TInputVector;
    i: integer;
    tmp: double;

procedure makeinput;
var i,j: integer;
begin
   j:=1;
   with pos do begin
      x[j]:=1.0*store[rootplayer]/64.0; inc(j);
      x[j]:=1.0*store[1-rootplayer]/64.0; inc(j);
      for i:=0 to 15 do begin
         x[j]:=1.0*hole[rootplayer,i]/64.0; inc(j);
         x[j]:=1.0*hole[1-rootplayer,i]/64.0; inc(j);
      end;

       for i:=0 to 7 do begin
         if (hole[rootplayer,i]>0) and (hole[1-rootplayer,7-i]>0) then begin
            x[j]:=1.0*hole[rootplayer,i]/64.0; inc(j);
            x[j]:=1.0*hole[1-rootplayer,7-i]/64.0; inc(j);
         end else begin
            x[j]:=0; inc(j);
            x[j]:=0; inc(j);
         end;
      end;

      if ownsnyumba[rootplayer] then x[j]:=0.1 else x[j]:=0;
      inc(j);
      if ownsnyumba[1-rootplayer] then x[j]:=0.1 else x[j]:=0;
      inc(j);

      if (hole[rootplayer,7-NYUMBA]>0) and (hole[1-rootplayer,NYUMBA]>0) and
            ownsnyumba[1-rootplayer] then x[j]:=0.1 else x[j]:=0;
      inc(j);
      if (hole[1-rootplayer,NYUMBA]>0) and (hole[rootplayer,7-NYUMBA]>0) and
             ownsnyumba[rootplayer] then x[j]:=0.1 else x[j]:=0;
   end;
end;

procedure computeOutputs;
var i,j: integer;
    q,tmp,tot: double;
begin
    with ng do begin
      q:=sqrt(2*pi*sigma*sigma);
      tot:=0;
      for i:=1 to NINputs do begin
         tmp:=0;
         for j:=1 to NInputs do tmp:=tmp+(x[j]-mu[i,j])*(x[j]-mu[i,j]);
         tmp:= tmp/(2.0*sigma*sigma);
         tmp:=exp(-tmp);
         g[i]:=tmp/q;
         tot:=tot+g[i];
      end;
      if tot<>0 then
         for i:=1 to NINputs do g[i]:=g[i]/tot;
    end;
end;



begin
   makeInput;
   computeOutputs;
   with ng do begin
      tmp:=0;
      for i:=1 to NINputs do tmp:=tmp+w[i]*g[i];
   end;
   score:=trunc(10000*tmp);
   if score=0 then score:=1;
   if score<-9000 then begin {write('underflow'); halt; } score:=-9000; end;
   if score>9000 then begin {write('overflow'); halt; } score:=+9000; end;
   ngn_eval:=score;
end;

{$I ngn_d6.inc}
function ngnd6_eval(pos: TBaoPosition): integer;
begin
   ngnd6_eval := ngn_eval(pos,ngn_d6);
end;

{$I ngn_d6a.inc}
function ngnd6a_eval(pos: TBaoPosition): integer;
begin
   ngnd6a_eval := ngn_eval(pos,ngn_d6a);
end;



begin
   registerEvaluator(@default_evaluate,'default');
   registerEvaluator(@fixed_evaluate,'fixed');
   registerEvaluator(@random_evaluate,'random');   
   registerEvaluator(@material_evaluate,'material');
   registerEvaluator(@GA1_eval,'ga1');
   registerEvaluator(@GA2_eval,'ga2');
   registerEvaluator(@GA3_eval,'ga3');
   init_Tdl2b;
   registerEvaluator(@Tdl2b_eval,'tdl2b');
   registerEvaluator(@ngnd6_eval,'ngnd6');
   registerEvaluator(@ngnd6a_eval,'ngnd6a');
end.

