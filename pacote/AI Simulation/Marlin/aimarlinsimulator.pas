unit aimarlinsimulator;
{$mode objfpc}{$H+}
interface
uses Classes, SysUtils, Math, aibase, aigcodeparser;
type
  TAIMarlinPosition = record X, Y, Z, E: Double; end;
  TAIMarlinState = record
    Position: TAIMarlinPosition; // physical mm; G92 changes offsets, not this position
    Hotend, HotendTarget, Bed, BedTarget, Feed, LaserPower: Double;
    SimulatedSeconds, DepositedFilament, RetractedFilament: Double;
    Fan: Integer;
    RelativeXYZ, RelativeE, MotorsEnabled, Killed, Paused: Boolean;
  end;
  TAIMarlinMotionEvent = procedure(Sender: TObject;
    const FromPosition, ToPosition: TAIMarlinPosition;
    DepositedFilament: Double) of object;
  TAIMarlinResponseEvent = procedure(Sender: TObject; const Text: string) of object;
  TAIMarlinPending = (mpNone, mpMove, mpHotend, mpBed, mpDwell);
  TAIMarlinSimulator = class(TAIBaseComponent)
  private
    FParser: TAIGCodeParser;
    FQueue: TStringList;
    FBuffer: string;
    FDiscardLine, FHeatCooling, FInAdvance: Boolean;
    FState: TAIMarlinState;
    FOffset, FDestination, FG28Home: TAIMarlinPosition;
    FG28HomeSet: Boolean;
    FPending: TAIMarlinPending;
    FRemaining, FBusyTime, FUnits, FSpeedFactor, FFlowFactor: Double;
    FMinExtrudeTemperature, FVolumeX, FVolumeY, FVolumeZ: Double;
    FAllowZ: Boolean;
    { Laser/spindle no estilo GRBL: M3/M4 liga, M5 desliga, S define a
      potencia (tambem quando vem na linha do G0/G1). }
    FLaserOn, FRapidMove: Boolean;
    FLaserS: Double;
    FLastLine: Integer;
    FOnResponse: TAIMarlinResponseEvent;
    FOnMotion: TAIMarlinMotionEvent;
    FOnStateChanged: TNotifyEvent;
    function GetWorkPosition: TAIMarlinPosition;
    function GetG92Active: Boolean;
    procedure UpdateLaserPower;
    procedure Emit(const Text: string);
    procedure Reject(const Text: string; Resend: Boolean);
    function NormalizeGrblJog(const Line: string; out Normalized, ErrorText: string): Boolean;
    procedure Execute(const C: TAIGCodeCommand);
    procedure Finish;
    procedure TemperatureStep(Dt: Double);
    function TemperatureReport: string;
    function StartMove(const C: TAIGCodeCommand): Boolean;
    function HasUnsupportedParameters(const C: TAIGCodeCommand;
      const Allowed: string): Boolean;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Reset;
    procedure Receive(const Bytes: string);
    function SubmitLine(const Line: string): Boolean;
    procedure Advance(Seconds: Double);
    procedure Pause;
    procedure Resume;
    procedure EmergencyStop;
    procedure SetBuildVolume(X, Y, Z: Double);
    procedure SetHotendTarget(ATemp: Double);
    procedure SetBedTarget(ATemp: Double);
    procedure SetHotendActual(ATemp: Double);
    procedure SetBedActual(ATemp: Double);
    property AllowZ: Boolean read FAllowZ write FAllowZ;
    function IsIdle: Boolean;
    property State: TAIMarlinState read FState;
    property WorkPosition: TAIMarlinPosition read GetWorkPosition;
    property G28Home: TAIMarlinPosition read FG28Home;
    property G28HomeSet: Boolean read FG28HomeSet;
    property G92Active: Boolean read GetG92Active;
    property LastLineNumber: Integer read FLastLine;
    property Pending: TAIMarlinPending read FPending;
    { True enquanto executa um G0. No GRBL em modo laser ($32=1) o laser nao
      queima em movimentos rapidos. }
    property RapidMove: Boolean read FRapidMove;
  published
    property OnResponse: TAIMarlinResponseEvent read FOnResponse write FOnResponse;
    property OnMotion: TAIMarlinMotionEvent read FOnMotion write FOnMotion;
    property OnStateChanged: TNotifyEvent read FOnStateChanged write FOnStateChanged;
  end;
implementation
function MinD(A,B: Double): Double;
begin if A < B then Result := A else Result := B; end;
function MaxD(A,B: Double): Double;
begin if A > B then Result := A else Result := B; end;
constructor TAIMarlinSimulator.Create(AOwner: TComponent);
begin
  inherited Create(AOwner); FCategory := ccSimulation;
  FPrompt := 'Deterministic Marlin subset emulator. Receive/SubmitLine then Advance(seconds). No hardware or graphical dependencies.';
  FQueue := TStringList.Create; FParser := TAIGCodeParser.Create(Self);
  FVolumeX := 220; FVolumeY := 220; FVolumeZ := 250; FAllowZ := True; Reset;
end;
destructor TAIMarlinSimulator.Destroy;
begin FQueue.Free; inherited Destroy; end;
procedure TAIMarlinSimulator.Emit(const Text: string);
begin if Assigned(FOnResponse) then FOnResponse(Self, Text + #10); end;
procedure TAIMarlinSimulator.Reject(const Text: string; Resend: Boolean);
begin
  SetError(Text); Emit('Error:' + Text);
  if Resend then Emit('Resend:' + IntToStr(FLastLine + 1));
end;
procedure TAIMarlinSimulator.Reset;
begin
  FQueue.Clear; FBuffer := ''; FDiscardLine := False;
  FillChar(FState, SizeOf(FState), 0); FillChar(FOffset, SizeOf(FOffset), 0);
  FillChar(FG28Home, SizeOf(FG28Home), 0); FG28HomeSet := False;
  FState.Hotend := 25; FState.Bed := 25; FState.Feed := 1500; FState.LaserPower := 0;
  FUnits := 1; FSpeedFactor := 1; FFlowFactor := 1;
  FMinExtrudeTemperature := 170; FLastLine := 0;
  FPending := mpNone; FRemaining := 0; FBusyTime := 0;
  FLaserOn := False; FLaserS := 0; FRapidMove := False;
  ClearError; Emit('start');
end;
function TAIMarlinSimulator.GetWorkPosition: TAIMarlinPosition;
begin
  Result.X := FState.Position.X + FOffset.X;
  Result.Y := FState.Position.Y + FOffset.Y;
  Result.Z := FState.Position.Z + FOffset.Z;
  Result.E := FState.Position.E + FOffset.E;
end;

function TAIMarlinSimulator.GetG92Active: Boolean;
begin
  Result := (Abs(FOffset.X) > 1e-6) or (Abs(FOffset.Y) > 1e-6) or
            (Abs(FOffset.Z) > 1e-6) or (Abs(FOffset.E) > 1e-6);
end;

procedure TAIMarlinSimulator.UpdateLaserPower;
begin
  if FLaserOn then FState.LaserPower := FLaserS else FState.LaserPower := 0;
end;
procedure TAIMarlinSimulator.SetBuildVolume(X, Y, Z: Double);
begin
  if not IsIdle then raise EInvalidOperation.Create('Printer must be idle');
  if IsNan(X) or IsNan(Y) or IsNan(Z) or IsInfinite(X) or IsInfinite(Y) or
    IsInfinite(Z) or (X <= 0) or (Y <= 0) or (Z <= 0) or
    (X > 10000) or (Y > 10000) or (Z > 10000) then
    raise EArgumentException.Create('Invalid build volume');
  FVolumeX := X; FVolumeY := Y; FVolumeZ := Z;
end;

procedure TAIMarlinSimulator.SetHotendTarget(ATemp: Double);
begin
  FState.HotendTarget := MaxD(0, ATemp);
  if Assigned(FOnStateChanged) then FOnStateChanged(Self);
end;

procedure TAIMarlinSimulator.SetBedTarget(ATemp: Double);
begin
  FState.BedTarget := MaxD(0, ATemp);
  if Assigned(FOnStateChanged) then FOnStateChanged(Self);
end;

procedure TAIMarlinSimulator.SetHotendActual(ATemp: Double);
begin
  FState.Hotend := MaxD(0, ATemp);
  if Assigned(FOnStateChanged) then FOnStateChanged(Self);
end;

procedure TAIMarlinSimulator.SetBedActual(ATemp: Double);
begin
  FState.Bed := MaxD(0, ATemp);
  if Assigned(FOnStateChanged) then FOnStateChanged(Self);
end;
function TAIMarlinSimulator.IsIdle: Boolean;
begin Result := (FPending = mpNone) and (FQueue.Count = 0); end;
procedure TAIMarlinSimulator.Pause;
begin FState.Paused := True; end;
procedure TAIMarlinSimulator.Resume;
begin FState.Paused := False; end;
procedure TAIMarlinSimulator.EmergencyStop;
begin
  FQueue.Clear; FPending := mpNone; FBuffer := '';
  FState.Killed := True; FState.HotendTarget := 0; FState.BedTarget := 0;
  FState.MotorsEnabled := False; FState.Fan := 0; FState.LaserPower := 0;
  FLaserOn := False; FRapidMove := False;
  Reject('Printer halted. Reset required', False);
  if Assigned(FOnStateChanged) then FOnStateChanged(Self);
end;
procedure TAIMarlinSimulator.Receive(const Bytes: string);
var I: Integer; Line: string;
begin
  for I := 1 to Length(Bytes) do begin
    if Bytes[I] in [#10, #13] then begin
      if not FDiscardLine and (FBuffer <> '') then begin
        Line := FBuffer; FBuffer := ''; SubmitLine(Line);
      end;
      FBuffer := ''; FDiscardLine := False;
    end else if not FDiscardLine then begin
      if Length(FBuffer) >= 1024 then begin
        FBuffer := ''; FDiscardLine := True; Reject('Input line too long', True);
      end else FBuffer := FBuffer + Bytes[I];
    end;
  end;
end;
function TAIMarlinSimulator.SubmitLine(const Line: string): Boolean;
var C: TAIGCodeCommand; ErrorText, NormalizedLine, RawLine: string; ResetNumber, Immediate: Boolean;
begin
  Result := False;
  NormalizedLine := Trim(Line);
  if SameText(NormalizedLine, '$H') then begin
    FState.Position.X:=0; FState.Position.Y:=0; FState.Position.Z:=0;
    FOffset.X:=0; FOffset.Y:=0; FOffset.Z:=0; FState.MotorsEnabled:=True;
    Emit('ok'); Exit(True);
  end;
  if SameText(NormalizedLine, '$X') or SameText(NormalizedLine, 'M30') then begin
    Emit('ok'); Exit(True);
  end;
  if NormalizedLine='?' then begin
    Emit('<Idle|MPos:' + GCodeFloat(FState.Position.X) + ',' +
      GCodeFloat(FState.Position.Y) + ',' + GCodeFloat(FState.Position.Z) + '>');
    Exit(True);
  end;
  if UpperCase(Copy(NormalizedLine, 1, 3)) = '$J=' then begin
    RawLine := NormalizedLine;
    if not NormalizeGrblJog(RawLine, NormalizedLine, ErrorText) then begin
      Reject(ErrorText, False); Exit;
    end;
  end;
  if not FParser.Parse(NormalizedLine, C, ErrorText) then begin Reject(ErrorText, True); Exit; end;
  if C.Empty then Exit(True);
  if (C.Letter = 'M') and (C.Code = 112) then begin EmergencyStop; Exit(True); end;
  if FState.Killed then begin Reject('Printer halted. Reset required', False); Exit; end;
  ResetNumber := (C.Letter = 'M') and (C.Code = 110);
  if C.HasLineNumber and not C.HasChecksum then begin Reject('Missing checksum', True); Exit; end;
  if C.HasChecksum and not C.HasLineNumber then begin Reject('Missing line number', True); Exit; end;
  if C.HasLineNumber and not ResetNumber and (C.LineNumber <> FLastLine + 1) then
    begin Reject('Line number out of sequence', True); Exit; end;
  Immediate := (C.Letter = 'M') and (C.Code in [105,108,110,114,115]);
  if (FQueue.Count >= 128) and not Immediate then begin Reject('Queue full', True); Exit; end;
  if ResetNumber then begin
    if HasUnsupportedParameters(C,'N') then begin
      Emit('Resend:' + IntToStr(FLastLine + 1)); Exit;
    end;
    if C.Present['N'] then begin
      if (C.Values['N'] < 0) or (Frac(C.Values['N']) <> 0) then
        begin Reject('Invalid reset line number', True); Exit; end;
      FLastLine := Round(C.Values['N']);
    end else if C.HasLineNumber then FLastLine := C.LineNumber;
  end else if C.HasLineNumber then FLastLine := C.LineNumber;
  ClearError;
  if Immediate then Execute(C) else FQueue.Add(NormalizedLine);
  Result := True;
end;

function TAIMarlinSimulator.NormalizeGrblJog(const Line: string;
  out Normalized, ErrorText: string): Boolean;
var C: TAIGCodeCommand; Payload, Work: string; I: Integer; Relative: Boolean;
  V: Double; HasAxis: Boolean;
  procedure AddAxis(const Name: string; Present: Boolean; Value, Current, Offset: Double);
  begin
    if not Present then Exit;
    HasAxis := True;
    if Relative then V := Current + Offset + Value else V := Value;
    Normalized := Normalized + ' ' + Name + GCodeFloat(V);
  end;
begin
  Result := False; Normalized := ''; ErrorText := '';
  Payload := Trim(Copy(Line, 4, Length(Line)));
  Relative := Pos('G91', UpperCase(Payload)) > 0;
  I := Pos('G91', UpperCase(Payload)); if I > 0 then Delete(Payload, I, 3);
  I := Pos('G90', UpperCase(Payload)); if I > 0 then Delete(Payload, I, 3);
  Work := 'G0 ' + Trim(Payload);
  if not FParser.Parse(Work, C, ErrorText) then Exit;
  Normalized := 'G0'; HasAxis := False;
  AddAxis('X', C.Present['X'], C.Values['X'], FState.Position.X, FOffset.X);
  AddAxis('Y', C.Present['Y'], C.Values['Y'], FState.Position.Y, FOffset.Y);
  AddAxis('Z', C.Present['Z'], C.Values['Z'], FState.Position.Z, FOffset.Z);
  AddAxis('E', C.Present['E'], C.Values['E'], FState.Position.E, FOffset.E);
  if C.Present['F'] then Normalized := Normalized + ' F' + GCodeFloat(C.Values['F']);
  if not HasAxis then begin ErrorText := 'GRBL jog has no axis'; Exit; end;
  Result := True;
end;
function TAIMarlinSimulator.TemperatureReport: string;
begin
  Result := 'T:' + GCodeFloat(FState.Hotend) + ' /' + GCodeFloat(FState.HotendTarget) +
    ' B:' + GCodeFloat(FState.Bed) + ' /' + GCodeFloat(FState.BedTarget);
end;
function TAIMarlinSimulator.HasUnsupportedParameters(const C: TAIGCodeCommand;
  const Allowed: string): Boolean;
var K: Char;
begin
  Result := False;
  for K := 'A' to 'Z' do if C.Present[K] then begin
    if Pos(K, Allowed) = 0 then begin
      Reject('Unsupported parameter ' + K, False); Exit(True);
    end;
    if not C.HasValue[K] and not ((C.Letter='G') and (C.Code=28)) then begin
      Reject('Missing value for ' + K, False); Exit(True);
    end;
  end;
end;
function TAIMarlinSimulator.StartMove(const C: TAIGCodeCommand): Boolean;
var P: TAIMarlinPosition; Feed, Distance: Double;
  function Axis(K: Char; Current, Offset: Double; Relative: Boolean): Double;
  begin
    Result := Current;
    if not C.Present[K] then Exit;
    if Relative then Result := Current + C.Values[K] * FUnits
    else Result := C.Values[K] * FUnits - Offset;
  end;
begin
  Result := False;
  if HasUnsupportedParameters(C, 'XYZEFS') then Exit;
  if C.Present['S'] and ((C.Values['S'] < 0) or (C.Values['S'] > 1000)) then
    begin Reject('Invalid laser power', False); Exit; end;
  Feed := FState.Feed;
  if C.Present['F'] then Feed := C.Values['F'] * FUnits;
  if (Feed <= 0) or (Feed > 100000) then begin Reject('Invalid feed', False); Exit; end;
  P := FState.Position;
  if C.Present['Z'] and not FAllowZ then begin Reject('Z axis unavailable for this machine', False); Exit; end;
  P.X := Axis('X', P.X, FOffset.X, FState.RelativeXYZ);
  P.Y := Axis('Y', P.Y, FOffset.Y, FState.RelativeXYZ);
  P.Z := Axis('Z', P.Z, FOffset.Z, FState.RelativeXYZ);
  P.E := Axis('E', P.E, FOffset.E, FState.RelativeE);
  if (P.X < 0) or (P.X > FVolumeX) or (P.Y < 0) or (P.Y > FVolumeY) or
     (P.Z < 0) or (P.Z > FVolumeZ) then begin Reject('Move outside build volume', False); Exit; end;
  if (P.E > FState.Position.E) and (FState.Hotend < FMinExtrudeTemperature) then
    begin Reject('Cold extrusion prevented', False); Exit; end;
  Distance := Sqrt(Sqr(P.X - FState.Position.X) + Sqr(P.Y - FState.Position.Y) +
    Sqr(P.Z - FState.Position.Z));
  if Distance < 1e-9 then Distance := Abs(P.E - FState.Position.E);
  { So altera a potencia depois de validar o movimento inteiro. }
  if C.Present['S'] then begin FLaserS := C.Values['S']; UpdateLaserPower; end;
  FRapidMove := C.Code = 0;
  FDestination := P; FState.Feed := Feed; FState.MotorsEnabled := True;
  FRemaining := Distance / (Feed * FSpeedFactor / 60);
  FPending := mpMove; Result := True;
end;
procedure TAIMarlinSimulator.Execute(const C: TAIGCodeCommand);
var V: Double; AllAxes: Boolean; Allowed: string;
  procedure Done;
  begin Emit('ok'); end;
begin
  if ((C.Letter='G') and not (C.Code in [0,1,4,20,21,28,90,91,92])) or
     ((C.Letter='M') and not ((C.Code in [17,18,82,83,84,104,105,106,107,108,
       109,110,114,115,119,140,190,220,221,3,4,5]) or (C.Code=302) or (C.Code=400))) or
     ((C.Letter='T') and (C.Code<>0)) then begin
    Reject('Unsupported '+C.Letter+IntToStr(C.Code),False); Done; Exit;
  end;
  Allowed := '';
  if C.Letter = 'G' then case C.Code of
    0,1: Allowed := 'XYZEFS'; 4: Allowed := 'PS';
    28: Allowed := 'XYZ'; 92: Allowed := 'XYZE';
  end;
  if C.Letter = 'M' then case C.Code of
    3,4: Allowed := 'S'; 5: Allowed := '';
    104,109,140,190: Allowed := 'SRT';
    106,220,221: Allowed := 'S'; 110: Allowed := 'N'; 302: Allowed := 'SP';
  end;
  if HasUnsupportedParameters(C,Allowed) then begin Done; Exit; end;
  if C.Letter = 'G' then begin
    case C.Code of
      0,1: begin if not StartMove(C) then Done; Exit; end;
      4: begin
        if HasUnsupportedParameters(C, 'PS') then begin Done; Exit; end;
        V := 0; if C.Present['P'] then V := C.Values['P'] / 1000;
        if C.Present['S'] then V := C.Values['S'];
        if (V < 0) or (V > 86400) then Reject('Invalid dwell', False)
        else begin FPending := mpDwell; FRemaining := V; Exit; end;
      end;
      20: FUnits := 25.4;
      21: FUnits := 1;
      28: begin
        if C.HasSubCode and (C.SubCode = 1) then
        begin
          FG28Home := FState.Position;
          FG28HomeSet := True;
          Done;
          Exit;
        end;
        if HasUnsupportedParameters(C, 'XYZ') then begin Done; Exit; end;
        // Deterministic ideal homing; no physical endstop seeking.
        AllAxes := not (C.Present['X'] or C.Present['Y'] or C.Present['Z']);
        if AllAxes or C.Present['X'] then
        begin
          if FG28HomeSet then FState.Position.X := FG28Home.X else FState.Position.X := 0;
          FOffset.X := 0;
        end;
        if AllAxes or C.Present['Y'] then
        begin
          if FG28HomeSet then FState.Position.Y := FG28Home.Y else FState.Position.Y := 0;
          FOffset.Y := 0;
        end;
        if AllAxes or C.Present['Z'] then
        begin
          if FG28HomeSet then FState.Position.Z := FG28Home.Z else FState.Position.Z := 0;
          FOffset.Z := 0;
        end;
        FState.MotorsEnabled := True;
      end;
      90: begin FState.RelativeXYZ := False; FState.RelativeE := False; end;
      91: begin FState.RelativeXYZ := True; FState.RelativeE := True; end;
      92: begin
        if HasUnsupportedParameters(C, 'XYZE') then begin Done; Exit; end;
        if C.Present['X'] then FOffset.X := C.Values['X'] * FUnits - FState.Position.X;
        if C.Present['Y'] then FOffset.Y := C.Values['Y'] * FUnits - FState.Position.Y;
        if C.Present['Z'] then FOffset.Z := C.Values['Z'] * FUnits - FState.Position.Z;
        if C.Present['E'] then FOffset.E := C.Values['E'] * FUnits - FState.Position.E;
      end;
      else Reject('Unsupported G' + IntToStr(C.Code), False);
    end;
  end else if C.Letter = 'M' then begin
    case C.Code of
      17: FState.MotorsEnabled := True;
      18,84: FState.MotorsEnabled := False;
      82: FState.RelativeE := False;
      83: FState.RelativeE := True;
      104,109,140,190: begin
        if HasUnsupportedParameters(C, 'SRT') or
          (C.Present['T'] and (C.Values['T'] <> 0)) then begin
          if C.Present['T'] and (C.Values['T'] <> 0) then Reject('Only tool 0 is supported', False);
          Done; Exit;
        end;
        if C.Code in [104,109] then V := FState.HotendTarget else V := FState.BedTarget;
        if C.Present['S'] then V := C.Values['S'];
        if C.Present['R'] then V := C.Values['R'];
        if (V < 0) or ((C.Code in [104,109]) and (V > 300)) or
          ((C.Code in [140,190]) and (V > 130)) then begin
          Reject('Invalid temperature target', False); Done; Exit;
        end;
        if C.Code in [104,109] then FState.HotendTarget := V else FState.BedTarget := V;
        if C.Code in [109,190] then begin
          FHeatCooling := C.Present['R'];
          if C.Code = 109 then FPending := mpHotend else FPending := mpBed;
          Exit;
        end;
      end;
      3,4: begin
        V := FLaserS; if C.Present['S'] then V := C.Values['S'];
        if (V < 0) or (V > 1000) then Reject('Invalid laser power', False)
        else begin FLaserS := V; FLaserOn := True; UpdateLaserPower; end;
      end;
      5: begin FLaserOn := False; UpdateLaserPower; end;
      105: begin Emit('ok ' + TemperatureReport); Exit; end;
      106: begin
        V := 255; if C.Present['S'] then V := C.Values['S'];
        if (V < 0) or (V > 255) then Reject('Invalid fan value', False)
        else FState.Fan := Round(V);
      end;
      107: FState.Fan := 0;
      108: if FPending in [mpHotend,mpBed] then Finish;
      110: ; // applied by SubmitLine, before subsequent numbered input
      114: Emit('X:' + GCodeFloat(FState.Position.X + FOffset.X) +
        ' Y:' + GCodeFloat(FState.Position.Y + FOffset.Y) +
        ' Z:' + GCodeFloat(FState.Position.Z + FOffset.Z) +
        ' E:' + GCodeFloat(FState.Position.E + FOffset.E));
      115: Emit('FIRMWARE_NAME:Marlin-Simulator SOURCE_CODE_URL:https://github.com/marcelomaurin/CHATGPT PROTOCOL_VERSION:1.0 MACHINE_TYPE:VirtualCartesian EXTRUDER_COUNT:1');
      119: begin
        Emit('Reporting endstop status');
        if FState.Position.X <= 0 then Emit('x_min: TRIGGERED') else Emit('x_min: open');
        if FState.Position.Y <= 0 then Emit('y_min: TRIGGERED') else Emit('y_min: open');
        if FState.Position.Z <= 0 then Emit('z_min: TRIGGERED') else Emit('z_min: open');
      end;
      220,221: begin
        if not C.Present['S'] or (C.Values['S'] <= 0) or (C.Values['S'] > 1000) then
          Reject('Percentage must be 0 < S <= 1000', False)
        else if C.Code = 220 then FSpeedFactor := C.Values['S'] / 100
        else FFlowFactor := C.Values['S'] / 100;
      end;
      302: begin
        if C.Present['S'] then begin
          if (C.Values['S'] < 0) or (C.Values['S'] > 300) then Reject('Invalid minimum temperature',False)
          else FMinExtrudeTemperature := C.Values['S'];
        end;
        if C.Present['P'] then begin
          if C.Values['P'] <> 0 then FMinExtrudeTemperature := 0
          else FMinExtrudeTemperature := 170;
        end;
      end;
      400: ; // FIFO execution: previous motion has already finished
      else Reject('Unsupported M' + IntToStr(C.Code), False);
    end;
  end else if (C.Letter <> 'T') or (C.Code <> 0) then
    Reject('Only tool 0 is supported', False);
  Done;
end;
procedure TAIMarlinSimulator.Finish;
begin FPending := mpNone; FRemaining := 0; FBusyTime := 0; FRapidMove := False; Emit('ok'); end;
procedure TAIMarlinSimulator.TemperatureStep(Dt: Double);
  procedure Adjust(var Temp: Double; Target, Heating, Cooling: Double);
  begin
    Target := MaxD(25, Target);
    if Temp < Target then Temp := MinD(Target, Temp + Heating * Dt)
    else Temp := MaxD(Target, Temp - Cooling * Dt);
  end;
begin
  Adjust(FState.Hotend, FState.HotendTarget, 3, 1);
  Adjust(FState.Bed, FState.BedTarget, 0.8, 0.3);
  FState.SimulatedSeconds := FState.SimulatedSeconds + Dt;
end;
procedure TAIMarlinSimulator.Advance(Seconds: Double);
var C: TAIGCodeCommand; Line, ErrorText: string; Dt, Ratio, DeltaE, Deposit,
    Available, Target, Temp, Rate, WaitTime: Double; Old: TAIMarlinPosition; Iter: Integer;
begin
  if FInAdvance then raise EInvalidOperation.Create('Advance is not reentrant');
  if IsNan(Seconds) or IsInfinite(Seconds) or (Seconds < 0) or (Seconds > 3600) then
    raise EArgumentException.Create('Advance requires 0..3600 finite seconds');
  FInAdvance := True;
  try
    Available := Seconds; Iter := 0;
    while Iter < 1024 do begin
      Inc(Iter);
      if FState.Killed or FState.Paused then begin TemperatureStep(Available); Break; end;
      if FPending = mpNone then begin
        if FQueue.Count = 0 then begin TemperatureStep(Available); Break; end;
        Line := FQueue[0]; FQueue.Delete(0);
        if FParser.Parse(Line, C, ErrorText) then Execute(C);
        Continue;
      end;
      if FPending in [mpHotend,mpBed] then begin
        if FPending = mpHotend then begin Temp := FState.Hotend; Target := MaxD(25,FState.HotendTarget); Rate := 3; end
        else begin Temp := FState.Bed; Target := MaxD(25,FState.BedTarget); Rate := 0.8; end;
        if (Abs(Temp-Target) <= 1e-7) or ((Temp >= Target) and not FHeatCooling) then begin Finish; Continue; end;
        if Temp > Target then begin if FPending = mpHotend then Rate := 1 else Rate := 0.3; end;
        WaitTime := Abs(Temp-Target) / Rate;
        Dt := MinD(Available, WaitTime);
      end else Dt := MinD(Available, FRemaining);
      if (FPending in [mpMove,mpDwell]) and (FRemaining <= 1e-9) then begin Finish; Continue; end;
      if Dt <= 0 then Break;
      TemperatureStep(Dt); Available := MaxD(0, Available - Dt);
      if FPending = mpMove then begin
        Old := FState.Position; Ratio := MinD(1, Dt / FRemaining);
        FState.Position.X := Old.X + (FDestination.X-Old.X)*Ratio;
        FState.Position.Y := Old.Y + (FDestination.Y-Old.Y)*Ratio;
        FState.Position.Z := Old.Z + (FDestination.Z-Old.Z)*Ratio;
        FState.Position.E := Old.E + (FDestination.E-Old.E)*Ratio;
        DeltaE := (FState.Position.E - Old.E) * FFlowFactor; Deposit := 0;
        if DeltaE < 0 then FState.RetractedFilament := FState.RetractedFilament - DeltaE
        else begin
          Deposit := MaxD(0, DeltaE-FState.RetractedFilament);
          FState.RetractedFilament := MaxD(0,FState.RetractedFilament-DeltaE);
          FState.DepositedFilament := FState.DepositedFilament + Deposit;
        end;
        if Assigned(FOnMotion) then FOnMotion(Self,Old,FState.Position,Deposit);
      end;
      if FPending in [mpMove,mpDwell] then begin
        FRemaining := MaxD(0,FRemaining-Dt);
        if FRemaining <= 1e-9 then begin Finish; Continue; end;
      end;
      FBusyTime := FBusyTime + Dt;
      if FBusyTime >= 2 then begin FBusyTime := 0; Emit('echo:busy: processing'); end;
    end;
    if Assigned(FOnStateChanged) then FOnStateChanged(Self);
  finally FInAdvance := False; end;
end;
end.
