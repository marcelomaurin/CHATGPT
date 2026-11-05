unit aispeechfilter;
{$mode objfpc}{$H+}
interface
uses SysUtils, Math;
type
  TSpeechBiquad = record
    B0,B1,B2,A1,A2,Z1,Z2: Double;
  end;
  { PCM16 interleaved, independent per-channel state. Two 2nd-order
    Butterworth sections select a 100..7000 Hz speech band at 16 kHz.
    This rejects rumble/high-frequency noise, not all sounds within speech. }
  TAISpeechFilter = class
  private
    FSampleRate,FChannels: Integer;
    FSections: array of array[0..1] of TSpeechBiquad;
    FNoiseFloor: Double;
    procedure Design(var B: TSpeechBiquad; Cutoff: Double; HighPass: Boolean);
    function Step(var B: TSpeechBiquad; X: Double): Double;
  public
    constructor Create;
    procedure Configure(ASampleRate,AChannels: Integer);
    procedure Reset;
    procedure Filter(const Input: PSmallInt; Count: Integer; out Output: TBytes);
    procedure ObserveBackground(RMS, VoiceThreshold: Double; IsCapturing: Boolean);
    function StartThreshold(ManualThreshold: Double): Double;
    function StopThreshold(ManualThreshold: Double): Double;
    property NoiseFloor: Double read FNoiseFloor;
  end;
implementation
constructor TAISpeechFilter.Create;
begin inherited Create; Configure(16000,1);end;
procedure TAISpeechFilter.Design(var B: TSpeechBiquad; Cutoff: Double; HighPass: Boolean);
var W,C,S,Alpha,A0:Double;
begin
  FillChar(B,SizeOf(B),0);
  W:=2*Pi*Cutoff/FSampleRate;C:=Cos(W);S:=Sin(W);Alpha:=S/Sqrt(2);A0:=1+Alpha;
  if HighPass then begin B.B0:=(1+C)/2/A0;B.B1:=-(1+C)/A0;end
  else begin B.B0:=(1-C)/2/A0;B.B1:=(1-C)/A0;end;
  B.B2:=B.B0;B.A1:=-2*C/A0;B.A2:=(1-Alpha)/A0;
end;
procedure TAISpeechFilter.Configure(ASampleRate,AChannels:Integer);
var I:Integer;
begin
  if (ASampleRate<8000) or (ASampleRate>192000) or not (AChannels in [1,2]) then
    raise Exception.Create('Filtro de voz requer PCM16, 8..192 kHz, mono ou stereo.');
  FSampleRate:=ASampleRate;FChannels:=AChannels;SetLength(FSections,FChannels);
  for I:=0 to FChannels-1 do
  begin
    Design(FSections[I][0],100,True);
    Design(FSections[I][1],Min(7000,FSampleRate*0.45),False);
  end;
  FNoiseFloor:=0;
end;
procedure TAISpeechFilter.Reset;
var I,J:Integer;
begin
  for I:=0 to High(FSections) do for J:=0 to 1 do
  begin FSections[I][J].Z1:=0;FSections[I][J].Z2:=0;end;
  FNoiseFloor:=0;
end;
function TAISpeechFilter.Step(var B:TSpeechBiquad;X:Double):Double;
begin
  Result:=B.B0*X+B.Z1;B.Z1:=B.B1*X-B.A1*Result+B.Z2;B.Z2:=B.B2*X-B.A2*Result;
end;
procedure TAISpeechFilter.Filter(const Input:PSmallInt;Count:Integer;out Output:TBytes);
var I,C:Integer;V:Double;P:PSmallInt;
begin
  SetLength(Output,0);if (Input=nil) or (Count<=0) then Exit;
  if Count mod FChannels<>0 then raise Exception.Create('Frame PCM incompleto.');
  SetLength(Output,Count*2);P:=PSmallInt(@Output[0]);
  for I:=0 to Count-1 do
  begin
    C:=I mod FChannels;
    V:=Step(FSections[C][1],Step(FSections[C][0],Input[I]));
    P[I]:=Round(EnsureRange(V,-32768.0,32767.0));
  end;
end;
procedure TAISpeechFilter.ObserveBackground(RMS,VoiceThreshold:Double;IsCapturing:Boolean);
begin
  { Do not learn a speaker as background. A threshold floor protects quiet
    microphones; separate start/stop thresholds provide hysteresis. }
  if not IsCapturing and (RMS<VoiceThreshold) then
    FNoiseFloor:=0.95*FNoiseFloor+0.05*RMS;
end;
function TAISpeechFilter.StartThreshold(ManualThreshold:Double):Double;
begin Result:=Max(ManualThreshold,FNoiseFloor*3);end;
function TAISpeechFilter.StopThreshold(ManualThreshold:Double):Double;
begin Result:=Max(ManualThreshold,FNoiseFloor*1.8);end;
end.
