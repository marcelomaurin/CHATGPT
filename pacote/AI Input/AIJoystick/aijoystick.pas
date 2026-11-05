unit aijoystick;

{$mode objfpc}{$H+}

interface

uses Classes, SysUtils, aibase;

const
  AIJoystickAxes = 6;
  AIJoystickControls = 34;
  { XInput canonical controls, independent of the Windows button bit mask. }
  ajA=1; ajB=2; ajX=3; ajY=4; ajLB=5; ajRB=6;
  ajLT=33; ajRT=34;

type
  TAIJoystickState = record
    Connected: Boolean;
    DeviceID, DeviceName: string;
    Axes: array[0..AIJoystickAxes-1] of Double; { -1..1, Y positive upward }
    Controls: array[1..AIJoystickControls] of Boolean;
  end;
  TAIJoystickDevice = record ID, Name: string; end;
  TAIJoystickDevices = array of TAIJoystickDevice;

  { Poll on the caller's thread. No timer, LCL or motion side effects. }
  TAIJoystick = class(TAIBaseComponent)
  private
    FDeviceID: string;
    FState: TAIJoystickState;
    FLastScan: QWord;
    FScanned: Boolean;
    FXInputLibrary: THandle;
    FXInputGetState: Pointer;
    procedure InitXInput;
  protected
    FDevices: TAIJoystickDevices;
    function ReadDevice(const ID: string; out S: TAIJoystickState): Boolean; virtual;
    procedure ScanDevices; virtual;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure RefreshDevices;
    function Poll: Boolean;
    class function NormalizeAxis(Value, Minimum, Maximum: Int64): Double; static;
    property State: TAIJoystickState read FState;
    property Devices: TAIJoystickDevices read FDevices;
  published
    { Empty = automatic; retain the active controller until disconnected. }
    property DeviceID: string read FDeviceID write FDeviceID;
  end;

procedure Register;

implementation

uses Math {$ifdef windows}, Windows, MMSystem, Dynlibs{$endif};

{$ifdef windows}
type
  TXGamepad = packed record
    Buttons: Word;
    LeftTrigger, RightTrigger: Byte;
    LX, LY, RX, RY: SmallInt;
  end;
  TXState = packed record Packet: LongWord; Gamepad: TXGamepad; end;
  TXGetState = function(Index: LongWord; out S: TXState): LongWord; stdcall;
{$endif}

procedure Register;
begin RegisterComponents('AI Input', [TAIJoystick]); end;

constructor TAIJoystick.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Category:=ccInput;
  InitXInput;
end;

destructor TAIJoystick.Destroy;
begin
  {$ifdef windows}
  if FXInputLibrary<>0 then Dynlibs.UnloadLibrary(FXInputLibrary);
  {$endif}
  inherited Destroy;
end;

procedure TAIJoystick.InitXInput;
{$ifdef windows}
const Libraries: array[0..2] of string = ('xinput1_4.dll','xinput1_3.dll','xinput9_1_0.dll');
var Buffer: array[0..MAX_PATH] of WideChar; Folder: UnicodeString; I: Integer;
{$endif}
begin
  {$ifdef windows}
  if Windows.GetSystemDirectoryW(Buffer,Length(Buffer))=0 then Exit;
  Folder:=UnicodeString(PWideChar(@Buffer[0]));
  for I:=0 to High(Libraries) do
  begin
    FXInputLibrary:=Dynlibs.LoadLibrary(UTF8Encode(Folder)+'\'+Libraries[I]);
    if FXInputLibrary=0 then Continue;
    FXInputGetState:=Dynlibs.GetProcedureAddress(FXInputLibrary,'XInputGetState');
    if FXInputGetState<>nil then Exit;
    Dynlibs.UnloadLibrary(FXInputLibrary); FXInputLibrary:=0;
  end;
  {$endif}
end;

class function TAIJoystick.NormalizeAxis(Value, Minimum, Maximum: Int64): Double;
begin
  if Maximum<=Minimum then Exit(0);
  Result:=EnsureRange(2.0*(Value-Minimum)/(Maximum-Minimum)-1.0,-1.0,1.0);
end;

function TAIJoystick.ReadDevice(const ID: string; out S: TAIJoystickState): Boolean;
{$ifdef windows}
const Buttons: array[1..14] of Word = ($1000,$2000,$4000,$8000,$100,$200,$20,$10,$40,$80,1,2,4,8);
var I,N: Integer; X: TXState; J: TJOYINFOEX; C: TJOYCAPSW;
{$endif}
begin
  S:=Default(TAIJoystickState); Result:=False;
  {$ifdef windows}
  if Copy(ID,1,7)='xinput:' then
  begin
    if (FXInputGetState=nil) or not TryStrToInt(Copy(ID,8,MaxInt),N) or (N<0) or (N>3) then Exit;
    if TXGetState(FXInputGetState)(N,X)<>0 then Exit;
    S.DeviceName:='Xbox 360 / XInput '+IntToStr(N+1);
    S.Axes[0]:=NormalizeAxis(X.Gamepad.LX,-32768,32767);
    S.Axes[1]:=NormalizeAxis(X.Gamepad.LY,-32768,32767);
    S.Axes[2]:=NormalizeAxis(X.Gamepad.RX,-32768,32767);
    S.Axes[3]:=NormalizeAxis(X.Gamepad.RY,-32768,32767);
    S.Axes[4]:=X.Gamepad.LeftTrigger/255.0;
    S.Axes[5]:=X.Gamepad.RightTrigger/255.0;
    for I:=1 to High(Buttons) do S.Controls[I]:=(X.Gamepad.Buttons and Buttons[I])<>0;
    S.Controls[ajLT]:=X.Gamepad.LeftTrigger>64;
    S.Controls[ajRT]:=X.Gamepad.RightTrigger>64;
  end
  else if Copy(ID,1,6)='winmm:' then
  begin
    if not TryStrToInt(Copy(ID,7,MaxInt),N) or (N<0) or (N>=Integer(joyGetNumDevs)) then Exit;
    FillChar(J,SizeOf(J),0); J.dwSize:=SizeOf(J); J.dwFlags:=JOY_RETURNALL;
    if (joyGetPosEx(N,@J)<>JOYERR_NOERROR) or
       (joyGetDevCapsW(N,@C,SizeOf(C))<>JOYERR_NOERROR) then Exit;
    S.DeviceName:=UTF8Encode(UnicodeString(PWideChar(@C.szPname[0])))+' / generico '+IntToStr(N+1);
    S.Axes[0]:=NormalizeAxis(J.wXpos,C.wXmin,C.wXmax);
    S.Axes[1]:=-NormalizeAxis(J.wYpos,C.wYmin,C.wYmax);
    if (C.wCaps and JOYCAPS_HASZ)<>0 then S.Axes[2]:=NormalizeAxis(J.wZpos,C.wZmin,C.wZmax);
    if (C.wCaps and JOYCAPS_HASR)<>0 then S.Axes[3]:=NormalizeAxis(J.dwRpos,C.wRmin,C.wRmax);
    if (C.wCaps and JOYCAPS_HASU)<>0 then S.Axes[4]:=NormalizeAxis(J.dwUpos,C.wUmin,C.wUmax);
    if (C.wCaps and JOYCAPS_HASV)<>0 then S.Axes[5]:=NormalizeAxis(J.dwVpos,C.wVmin,C.wVmax);
    for I:=1 to 32 do S.Controls[I]:=(J.wButtons and (LongWord(1) shl (I-1)))<>0;
  end
  else Exit;
  S.Connected:=True; S.DeviceID:=ID; Result:=True;
  {$endif}
end;

procedure TAIJoystick.ScanDevices;
{$ifdef windows}
var S: TAIJoystickState; I: Integer;
  procedure Add(const ID: string);
  var N: Integer;
  begin
    if not ReadDevice(ID,S) then Exit;
    N:=Length(FDevices); SetLength(FDevices,N+1);
    FDevices[N].ID:=ID; FDevices[N].Name:=S.DeviceName;
  end;
{$endif}
begin
  SetLength(FDevices,0);
  {$ifdef windows}
  for I:=0 to 3 do Add('xinput:'+IntToStr(I));
  for I:=0 to Integer(joyGetNumDevs)-1 do Add('winmm:'+IntToStr(I));
  {$endif}
end;

procedure TAIJoystick.RefreshDevices;
begin ScanDevices; FLastScan:=GetTickCount64; FScanned:=True; end;

function TAIJoystick.Poll: Boolean;
var S: TAIJoystickState; ID: string; I: Integer;
begin
  if not FScanned or (GetTickCount64-FLastScan>=1000) then RefreshDevices;
  ID:=FDeviceID;
  if (ID='') and FState.Connected then ID:=FState.DeviceID;
  if (ID<>'') and ReadDevice(ID,S) then begin FState:=S; Exit(True); end;
  FState:=Default(TAIJoystickState);
  if FDeviceID='' then
    for I:=0 to High(FDevices) do
      if ReadDevice(FDevices[I].ID,S) then begin FState:=S; Exit(True); end;
  Result:=False;
end;

end.
