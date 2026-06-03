unit aioscapture;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  {$IFDEF MSWINDOWS}
  Windows,
  {$ELSE}
  LCLIntf, LCLType,
  {$ENDIF}
  Graphics, Controls, ExtCtrls, Forms, LResources;

type
  TOSMouseMoveEvent = procedure(Sender: TObject; X, Y: Integer) of object;
  TOSKeyInterceptEvent = procedure(Sender: TObject; KeyCode: Word; KeyChar: Char) of object;

  { TAIOSInputCapture }

  TAIOSInputCapture = class(TComponent)
  private
    FPrompt: string;
    FActive: Boolean;
    FPollingInterval: Integer;
    FPollTimer: TTimer;
    
    // Previous cursor coordinates for delta tracking
    FLastX: Integer;
    FLastY: Integer;
    
    // Tracking active properties
    FTrackMouse: Boolean;
    FTrackKeyboard: Boolean;
    
    // Key states for polling on non-hook platforms
    FLastKeyStates: array[0..255] of Boolean;
    
    FOnMouseMove: TOSMouseMoveEvent;
    FOnKeyIntercepted: TOSKeyInterceptEvent;
    
    procedure SetActive(AValue: Boolean);
    procedure SetPollingInterval(AValue: Integer);
    procedure OnPollTimer(Sender: TObject);
    procedure PollMouse;
    procedure PollKeyboard;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    
    function CaptureScreen(out ABmp: TBitmap): Boolean;
    function SaveScreenToBMP(const AFileName: string): Boolean;
  published
    property Prompt: string read FPrompt write FPrompt;
    property Active: Boolean read FActive write SetActive default False;
    property PollingInterval: Integer read FPollingInterval write SetPollingInterval default 50;
    property TrackMouse: Boolean read FTrackMouse write FTrackMouse default True;
    property TrackKeyboard: Boolean read FTrackKeyboard write FTrackKeyboard default True;
    
    property OnMouseMove: TOSMouseMoveEvent read FOnMouseMove write FOnMouseMove;
    property OnKeyIntercepted: TOSKeyInterceptEvent read FOnKeyIntercepted write FOnKeyIntercepted;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Communication', [TAIOSInputCapture]);
end;

{ TAIOSInputCapture }

constructor TAIOSInputCapture.Create(AOwner: TComponent);
var
  I: Integer;
begin
  inherited Create(AOwner);
  FPrompt := 'Component TAIOSInputCapture captures screen and intercepts global input systems. Properties: TrackMouse: Boolean, TrackKeyboard: Boolean, Active: Boolean, OnMouseMove: TMouseMoveEvent, OnKeyIntercepted: TKeyEvent. Methods: CaptureScreen(out ABmp: TBitmap): Boolean (takes standard desktop screenshot). AI Agent: Use this to record screen actions, take screenshots of user workflow, or track user interaction.';
  FActive := False;
  FPollingInterval := 50;
  FTrackMouse := True;
  FTrackKeyboard := True;
  FLastX := -1;
  FLastY := -1;
  
  for I := 0 to 255 do
    FLastKeyStates[I] := False;
    
  FPollTimer := TTimer.Create(Self);
  FPollTimer.Enabled := False;
  FPollTimer.Interval := FPollingInterval;
  FPollTimer.OnTimer := @OnPollTimer;
end;

destructor TAIOSInputCapture.Destroy;
begin
  FPollTimer.Enabled := False;
  inherited Destroy;
end;

procedure TAIOSInputCapture.SetActive(AValue: Boolean);
begin
  if FActive = AValue then Exit;
  FActive := AValue;
  FPollTimer.Enabled := FActive;
  
  if FActive then
  begin
    FLastX := -1;
    FLastY := -1;
  end;
end;

procedure TAIOSInputCapture.SetPollingInterval(AValue: Integer);
begin
  if FPollingInterval <> AValue then
  begin
    FPollingInterval := AValue;
    FPollTimer.Interval := FPollingInterval;
  end;
end;

procedure TAIOSInputCapture.OnPollTimer(Sender: TObject);
begin
  if FTrackMouse then
    PollMouse;
  if FTrackKeyboard then
    PollKeyboard;
end;

procedure TAIOSInputCapture.PollMouse;
var
  P: TPoint;
begin
  P := Mouse.CursorPos;
  
  // Trigger event if cursor (mouse/touch screen) position changed
  if (P.X <> FLastX) or (P.Y <> FLastY) then
  begin
    FLastX := P.X;
    FLastY := P.Y;
    if Assigned(FOnMouseMove) then
      FOnMouseMove(Self, P.X, P.Y);
  end;
end;

procedure TAIOSInputCapture.PollKeyboard;
var
  Key: Integer;
  IsDown: Boolean;
  C: Char;
begin
  {$IFDEF MSWINDOWS}
  // Windows: Direct virtual key polling using GetAsyncKeyState
  for Key := 8 to 255 do
  begin
    IsDown := (GetAsyncKeyState(Key) and $8000) <> 0;
    if IsDown and not FLastKeyStates[Key] then
    begin
      FLastKeyStates[Key] := True;
      
      // Simple character mapping
      if Key in [32..127] then
        C := Char(Key)
      else
        C := #0;
        
      if Assigned(FOnKeyIntercepted) then
        FOnKeyIntercepted(Self, Key, C);
    end
    else if not IsDown then
    begin
      FLastKeyStates[Key] := False;
    end;
  end;
  {$ELSE}
  // Linux: Read X11 event queue or read active keyboard keystates using LCL
  // For safety and compatibility in background CLI, simulate key logging or poll basic keys
  for Key := 8 to 127 do
  begin
    // LCL cross-platform keystate check
    IsDown := (LCLIntf.GetKeyState(Key) and $80) <> 0;
    if IsDown and not FLastKeyStates[Key] then
    begin
      FLastKeyStates[Key] := True;
      if Assigned(FOnKeyIntercepted) then
        FOnKeyIntercepted(Self, Key, Char(Key));
    end
    else if not IsDown then
    begin
      FLastKeyStates[Key] := False;
    end;
  end;
  {$ENDIF}
end;

function TAIOSInputCapture.CaptureScreen(out ABmp: TBitmap): Boolean;
var
  ScreenDC: HDC;
  LclCanvas: TCanvas;
  W, H: Integer;
begin
  Result := False;
  ABmp := TBitmap.Create;
  
  {$IFDEF MSWINDOWS}
  ScreenDC := GetDC(0);
  {$ELSE}
  ScreenDC := LCLIntf.GetDC(0);
  {$ENDIF}
  
  if ScreenDC = 0 then
    Exit;
    
  try
    LclCanvas := TCanvas.Create;
    try
      LclCanvas.Handle := ScreenDC;
      W := Screen.Width;
      H := Screen.Height;
      
      ABmp.Width := W;
      ABmp.Height := H;
      
      // Copy entire desktop screen context to bitmap canvas
      ABmp.Canvas.CopyRect(Classes.Rect(0, 0, W, H), LclCanvas, Classes.Rect(0, 0, W, H));
      Result := True;
    finally
      LclCanvas.Free;
    end;
  finally
    {$IFDEF MSWINDOWS}
    ReleaseDC(0, ScreenDC);
    {$ELSE}
    LCLIntf.ReleaseDC(0, ScreenDC);
    {$ENDIF}
  end;
end;

function TAIOSInputCapture.SaveScreenToBMP(const AFileName: string): Boolean;
var
  Bmp: TBitmap;
begin
  Result := False;
  Bmp := nil;
  try
    if CaptureScreen(Bmp) then
    begin
      Bmp.SaveToFile(AFileName);
      Result := True;
    end;
  finally
    if Bmp <> nil then
      Bmp.Free;
  end;
end;

initialization
  {$I aioscapture_icon.lrs}

end.
