program test_speaker_signature;
{$mode objfpc}{$H+}
uses SysUtils, aispeakersignature;
var Gate: TAISpeakerSession; Decision: TAISpeakerDecision;
procedure Check(Condition: Boolean; const Msg: string);
begin if not Condition then raise Exception.Create(Msg); end;
function Sig(X, Y: Double): TAISpeakerSignature;
begin SetLength(Result,2); Result[0]:=X; Result[1]:=Y; end;
begin
 Gate:=TAISpeakerSession.Create;
 try
  Check(Gate.Evaluate(Sig(1,0),Decision),'first accepted');
  Check(Gate.Active,'reference locked');
  Check(Gate.Evaluate(Sig(1,0),Decision) and (Decision=sdSame),'same');
  Check(not Gate.Evaluate(Sig(0,1),Decision) and (Decision=sdDifferent),'different');
  Check(Gate.Evaluate(Sig(0.7,0.7),Decision) and (Decision=sdInconclusive),'inconclusive accepted');
  Check(Gate.Evaluate(nil,Decision) and (Decision=sdInconclusive),'missing signature accepted');
  Check(not Gate.Evaluate(Sig(0,1),Decision),'reference unchanged');
  Gate.Reset;
  Check(Gate.Evaluate(Sig(0,1),Decision),'new speaker after reset');
  WriteLn('PASS: speaker session policy');
 finally Gate.Free; end;
end.
