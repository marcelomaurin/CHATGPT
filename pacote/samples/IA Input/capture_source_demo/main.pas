unit main;

{$mode objfpc}{$H+}

{ ============================================================
  capture_source_demo — Sample for TAICaptureSource
  Demonstrates all 5 SourceKind modes in a single TPageControl:
    Tab 1 — cskCameraLocal     (local webcam via VFW/V4L2)
    Tab 2 — cskCameraIPSnapshot (IP camera HTTP snapshot)
    Tab 3 — cskScreen          (desktop capture + mouse/keyboard)
    Tab 4 — cskFile            (static image file)
    Tab 5 — cskCameraIPRTSP   (RTSP — shows "not implemented")
  ============================================================ }

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs,
  ExtCtrls, ComCtrls, StdCtrls, FileUtil,
  aicapturesource;

type

  { TfrmCaptureDemo }

  TfrmCaptureDemo = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FPageControl: TPageControl;
    FCapture: TAICaptureSource;  // shared, reconfigured per tab

    // ---- Shared controls (bottom panel) ----
    FSharedPanel: TPanel;
    FPreviewImg:  TImage;
    FLogMemo:     TMemo;
    FBtnStart:    TButton;
    FBtnStop:     TButton;
    FBtnFrame:    TButton;
    FBtnSave:     TButton;
    FBtnTest:     TButton;
    FBtnSources:  TButton;

    // ---- Tab 1: Local Camera ----
    FTabCamera:     TTabSheet;
    FEditCamIndex:  TEdit;
    FEditCamW:      TEdit;
    FEditCamH:      TEdit;
    FEditCamFPS:    TEdit;

    // ---- Tab 2: IP Snapshot ----
    FTabIPSnap:    TTabSheet;
    FEditIPAddr:   TEdit;
    FEditIPPort:   TEdit;
    FEditSnapURL:  TEdit;
    FEditIPUser:   TEdit;
    FEditIPPass:   TEdit;
    FChkHTTPS:     TCheckBox;
    FEditTimeout:  TEdit;

    // ---- Tab 3: Screen ----
    FTabScreen:       TTabSheet;
    FChkFullScreen:   TCheckBox;
    FChkTrackMouse:   TCheckBox;
    FChkTrackKey:     TCheckBox;
    FEditPollInt:     TEdit;

    // ---- Tab 4: File ----
    FTabFile:      TTabSheet;
    FEditFilePath: TEdit;
    FBtnBrowse:    TButton;

    // ---- Tab 5: RTSP ----
    FTabRTSP:      TTabSheet;
    FEditRTSPURL:  TEdit;

    // ---- Event handlers ----
    procedure BtnStartClick(Sender: TObject);
    procedure BtnStopClick(Sender: TObject);
    procedure BtnFrameClick(Sender: TObject);
    procedure BtnSaveClick(Sender: TObject);
    procedure BtnTestClick(Sender: TObject);
    procedure BtnSourcesClick(Sender: TObject);
    procedure BtnBrowseClick(Sender: TObject);
    procedure PageControlChange(Sender: TObject);

    procedure OnCaptureFrame(Sender: TObject; const AFrameFile: string);
    procedure OnCaptureError(Sender: TObject; const AError: string);
    procedure OnCaptureState(Sender: TObject; AActive: Boolean);
    procedure OnMouseMove(Sender: TObject; X, Y: Integer);
    procedure OnKeyIntercepted(Sender: TObject; KeyCode: Word; KeyChar: Char);

    procedure ApplyTabConfig;
    procedure Log(const AMsg: string);
    function  MakeLabel(AParent: TWinControl; const ACaption: string): TLabel;
    function  MakeEdit(AParent: TWinControl; const AText: string): TEdit;
    function  MakeCheckBox(AParent: TWinControl; const ACaption: string; AChecked: Boolean): TCheckBox;
  public
  end;

var
  frmCaptureDemo: TfrmCaptureDemo;

implementation

{$R *.lfm}

{ TfrmCaptureDemo }

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

procedure TfrmCaptureDemo.Log(const AMsg: string);
begin
  FLogMemo.Lines.Add('[' + FormatDateTime('hh:nn:ss', Now) + '] ' + AMsg);
  if FLogMemo.Lines.Count > 500 then
    FLogMemo.Lines.Delete(0);
  FLogMemo.SelStart := Length(FLogMemo.Text);
  FLogMemo.SelLength := 0;
end;

function TfrmCaptureDemo.MakeLabel(AParent: TWinControl; const ACaption: string): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := AParent;
  Result.Align := alTop;
  Result.Caption := ACaption;
  Result.Height := 20;
end;

function TfrmCaptureDemo.MakeEdit(AParent: TWinControl; const AText: string): TEdit;
begin
  Result := TEdit.Create(Self);
  Result.Parent := AParent;
  Result.Align := alTop;
  Result.Text := AText;
  Result.Height := 26;
end;

function TfrmCaptureDemo.MakeCheckBox(AParent: TWinControl; const ACaption: string; AChecked: Boolean): TCheckBox;
begin
  Result := TCheckBox.Create(Self);
  Result.Parent := AParent;
  Result.Align := alTop;
  Result.Caption := ACaption;
  Result.Checked := AChecked;
  Result.Height := 24;
end;

// ---------------------------------------------------------------------------
// FormCreate — build entire UI in code
// ---------------------------------------------------------------------------

procedure TfrmCaptureDemo.FormCreate(Sender: TObject);
var
  TopSplit, BotLeft, BotRight: TPanel;
  BtnPanel: TPanel;
  Spl: TSplitter;
begin
  Caption := 'TAICaptureSource — Unified Capture Demo';
  Width   := 1000;
  Height  := 680;
  Position := poScreenCenter;

  // ---------- Capture component ----------
  FCapture := TAICaptureSource.Create(Self);
  FCapture.OnFrame         := @OnCaptureFrame;
  FCapture.OnError         := @OnCaptureError;
  FCapture.OnStateChange   := @OnCaptureState;
  FCapture.OnMouseMove     := @OnMouseMove;
  FCapture.OnKeyIntercepted := @OnKeyIntercepted;

  // ---------- Top split: tabs | preview ----------
  TopSplit := TPanel.Create(Self);
  TopSplit.Parent := Self;
  TopSplit.Align  := alTop;
  TopSplit.Height := 320;
  TopSplit.BevelOuter := bvNone;

  // ---- Left: config tabs ----
  FPageControl := TPageControl.Create(Self);
  FPageControl.Parent := TopSplit;
  FPageControl.Align  := alLeft;
  FPageControl.Width  := 400;
  FPageControl.OnChange := @PageControlChange;

  // ---- Splitter ----
  Spl := TSplitter.Create(Self);
  Spl.Parent := TopSplit;
  Spl.Align  := alLeft;
  Spl.Width  := 5;

  // ---- Right: preview image ----
  FPreviewImg := TImage.Create(Self);
  FPreviewImg.Parent := TopSplit;
  FPreviewImg.Align  := alClient;
  FPreviewImg.Stretch := True;
  FPreviewImg.Proportional := True;
  FPreviewImg.Center := True;

  // ---------- Bottom panel ----------
  FSharedPanel := TPanel.Create(Self);
  FSharedPanel.Parent := Self;
  FSharedPanel.Align  := alClient;
  FSharedPanel.BevelOuter := bvNone;

  // Buttons at bottom of shared panel
  BtnPanel := TPanel.Create(Self);
  BtnPanel.Parent := FSharedPanel;
  BtnPanel.Align  := alTop;
  BtnPanel.Height := 42;
  BtnPanel.BevelOuter := bvNone;

  FBtnStart := TButton.Create(Self);
  FBtnStart.Parent  := BtnPanel;
  FBtnStart.Caption := 'Start';
  FBtnStart.Left := 4;  FBtnStart.Top := 4;  FBtnStart.Width := 80;
  FBtnStart.OnClick := @BtnStartClick;

  FBtnStop := TButton.Create(Self);
  FBtnStop.Parent  := BtnPanel;
  FBtnStop.Caption := 'Stop';
  FBtnStop.Left := 90; FBtnStop.Top := 4;  FBtnStop.Width := 80;
  FBtnStop.OnClick := @BtnStopClick;

  FBtnFrame := TButton.Create(Self);
  FBtnFrame.Parent  := BtnPanel;
  FBtnFrame.Caption := 'Capture Frame';
  FBtnFrame.Left := 176; FBtnFrame.Top := 4; FBtnFrame.Width := 110;
  FBtnFrame.OnClick := @BtnFrameClick;

  FBtnSave := TButton.Create(Self);
  FBtnSave.Parent  := BtnPanel;
  FBtnSave.Caption := 'Save Frame';
  FBtnSave.Left := 292; FBtnSave.Top := 4; FBtnSave.Width := 100;
  FBtnSave.OnClick := @BtnSaveClick;

  FBtnTest := TButton.Create(Self);
  FBtnTest.Parent  := BtnPanel;
  FBtnTest.Caption := 'Self Test';
  FBtnTest.Left := 398; FBtnTest.Top := 4; FBtnTest.Width := 90;
  FBtnTest.OnClick := @BtnTestClick;

  FBtnSources := TButton.Create(Self);
  FBtnSources.Parent  := BtnPanel;
  FBtnSources.Caption := 'List Sources';
  FBtnSources.Left := 494; FBtnSources.Top := 4; FBtnSources.Width := 100;
  FBtnSources.OnClick := @BtnSourcesClick;

  // Log memo
  FLogMemo := TMemo.Create(Self);
  FLogMemo.Parent := FSharedPanel;
  FLogMemo.Align  := alClient;
  FLogMemo.ScrollBars := ssAutoVertical;
  FLogMemo.ReadOnly := True;
  FLogMemo.Font.Name := 'Courier New';
  FLogMemo.Font.Size := 9;
  FLogMemo.Lines.Add('=== TAICaptureSource Demo — Log ===');

  // ============================================================
  // TAB 1 — Local Camera (cskCameraLocal)
  // ============================================================
  FTabCamera := FPageControl.AddTabSheet;
  FTabCamera.Caption := 'Local Camera';

  BotLeft := TPanel.Create(Self);
  BotLeft.Parent := FTabCamera;
  BotLeft.Align  := alClient;
  BotLeft.BevelOuter := bvNone;

  MakeLabel(BotLeft, 'Camera Index:');
  FEditCamIndex := MakeEdit(BotLeft, '0');

  MakeLabel(BotLeft, 'Width:');
  FEditCamW := MakeEdit(BotLeft, '640');

  MakeLabel(BotLeft, 'Height:');
  FEditCamH := MakeEdit(BotLeft, '480');

  MakeLabel(BotLeft, 'FPS:');
  FEditCamFPS := MakeEdit(BotLeft, '30');

  // ============================================================
  // TAB 2 — IP Snapshot (cskCameraIPSnapshot)
  // ============================================================
  FTabIPSnap := FPageControl.AddTabSheet;
  FTabIPSnap.Caption := 'IP Snapshot';

  BotLeft := TPanel.Create(Self);
  BotLeft.Parent := FTabIPSnap;
  BotLeft.Align  := alClient;
  BotLeft.BevelOuter := bvNone;

  MakeLabel(BotLeft, 'IP Address:');
  FEditIPAddr := MakeEdit(BotLeft, '192.168.1.50');

  MakeLabel(BotLeft, 'Port:');
  FEditIPPort := MakeEdit(BotLeft, '80');

  MakeLabel(BotLeft, 'Snapshot URL:');
  FEditSnapURL := MakeEdit(BotLeft, '/cgi-bin/snapshot.jpg');

  MakeLabel(BotLeft, 'Username:');
  FEditIPUser := MakeEdit(BotLeft, 'admin');

  MakeLabel(BotLeft, 'Password:');
  FEditIPPass := MakeEdit(BotLeft, 'admin');

  FChkHTTPS := MakeCheckBox(BotLeft, 'Use HTTPS', False);

  MakeLabel(BotLeft, 'Timeout (ms):');
  FEditTimeout := MakeEdit(BotLeft, '5000');

  // ============================================================
  // TAB 3 — Screen Capture (cskScreen)
  // ============================================================
  FTabScreen := FPageControl.AddTabSheet;
  FTabScreen.Caption := 'Screen Capture';

  BotLeft := TPanel.Create(Self);
  BotLeft.Parent := FTabScreen;
  BotLeft.Align  := alClient;
  BotLeft.BevelOuter := bvNone;

  FChkFullScreen  := MakeCheckBox(BotLeft, 'Capture Full Screen', True);
  FChkTrackMouse  := MakeCheckBox(BotLeft, 'Track Mouse (OnMouseMove)', True);
  FChkTrackKey    := MakeCheckBox(BotLeft, 'Track Keyboard (OnKeyIntercepted)', False);

  MakeLabel(BotLeft, 'Polling Interval (ms):');
  FEditPollInt := MakeEdit(BotLeft, '50');

  // ============================================================
  // TAB 4 — File Frame (cskFile)
  // ============================================================
  FTabFile := FPageControl.AddTabSheet;
  FTabFile.Caption := 'File Frame';

  BotLeft := TPanel.Create(Self);
  BotLeft.Parent := FTabFile;
  BotLeft.Align  := alClient;
  BotLeft.BevelOuter := bvNone;

  MakeLabel(BotLeft, 'Image File Path:');

  BotRight := TPanel.Create(Self);
  BotRight.Parent := BotLeft;
  BotRight.Align  := alTop;
  BotRight.Height := 30;
  BotRight.BevelOuter := bvNone;

  FEditFilePath := TEdit.Create(Self);
  FEditFilePath.Parent := BotRight;
  FEditFilePath.Align  := alClient;
  FEditFilePath.Text   := '';

  FBtnBrowse := TButton.Create(Self);
  FBtnBrowse.Parent  := BotRight;
  FBtnBrowse.Align   := alRight;
  FBtnBrowse.Caption := '...';
  FBtnBrowse.Width   := 32;
  FBtnBrowse.OnClick := @BtnBrowseClick;

  // ============================================================
  // TAB 5 — RTSP (cskCameraIPRTSP — not implemented)
  // ============================================================
  FTabRTSP := FPageControl.AddTabSheet;
  FTabRTSP.Caption := 'RTSP (N/A)';

  BotLeft := TPanel.Create(Self);
  BotLeft.Parent := FTabRTSP;
  BotLeft.Align  := alClient;
  BotLeft.BevelOuter := bvNone;

  MakeLabel(BotLeft, 'RTSP URL (for future use):');
  FEditRTSPURL := MakeEdit(BotLeft, 'rtsp://192.168.1.50:554/stream');

  with TLabel.Create(Self) do
  begin
    Parent  := BotLeft;
    Align   := alTop;
    Height  := 60;
    Caption := 'NOTE: RTSP mode (cskCameraIPRTSP) is not yet implemented.'#13#10 +
               'StartCapture will return False with a clear error message.'#13#10 +
               'Use an external FFmpeg/OpenCV bridge for RTSP streams.';
    Font.Color := clRed;
    WordWrap  := True;
  end;

  // Apply initial config for Tab 1
  ApplyTabConfig;
  Log('Ready. Select a tab, configure and press Start.');
end;

procedure TfrmCaptureDemo.FormDestroy(Sender: TObject);
begin
  if FCapture.Active then FCapture.StopCapture;
end;

// ---------------------------------------------------------------------------
// Tab-switch: re-configure FCapture for the selected mode
// ---------------------------------------------------------------------------

procedure TfrmCaptureDemo.PageControlChange(Sender: TObject);
begin
  if FCapture.Active then
  begin
    FCapture.StopCapture;
    Log('Stopped previous capture.');
  end;
  ApplyTabConfig;
end;

procedure TfrmCaptureDemo.ApplyTabConfig;
begin
  case FPageControl.ActivePageIndex of
    0: // Local Camera
      begin
        FCapture.SourceKind  := cskCameraLocal;
        FCapture.CameraIndex := StrToIntDef(FEditCamIndex.Text, 0);
        FCapture.Width       := StrToIntDef(FEditCamW.Text, 640);
        FCapture.Height      := StrToIntDef(FEditCamH.Text, 480);
        FCapture.FPS         := StrToIntDef(FEditCamFPS.Text, 30);
        Log('Mode: Local Camera (index ' + FEditCamIndex.Text + ')');
      end;
    1: // IP Snapshot
      begin
        FCapture.SourceKind  := cskCameraIPSnapshot;
        FCapture.IPAddress   := FEditIPAddr.Text;
        FCapture.Port        := StrToIntDef(FEditIPPort.Text, 80);
        FCapture.SnapshotURL := FEditSnapURL.Text;
        FCapture.Username    := FEditIPUser.Text;
        FCapture.Password    := FEditIPPass.Text;
        FCapture.UseHTTPS    := FChkHTTPS.Checked;
        FCapture.TimeoutMs   := StrToIntDef(FEditTimeout.Text, 5000);
        Log('Mode: IP Snapshot — ' + FEditIPAddr.Text + ':' + FEditIPPort.Text + FEditSnapURL.Text);
      end;
    2: // Screen
      begin
        FCapture.SourceKind      := cskScreen;
        FCapture.CaptureFullScreen := FChkFullScreen.Checked;
        FCapture.TrackMouse      := FChkTrackMouse.Checked;
        FCapture.TrackKeyboard   := FChkTrackKey.Checked;
        FCapture.PollingInterval := StrToIntDef(FEditPollInt.Text, 50);
        Log('Mode: Screen Capture');
      end;
    3: // File
      begin
        FCapture.SourceKind := cskFile;
        FCapture.InputFile  := FEditFilePath.Text;
        Log('Mode: File Frame — ' + FEditFilePath.Text);
      end;
    4: // RTSP
      begin
        FCapture.SourceKind := cskCameraIPRTSP;
        FCapture.StreamURL  := FEditRTSPURL.Text;
        Log('Mode: RTSP (not implemented — StartCapture will fail with error)');
      end;
  end;
end;

// ---------------------------------------------------------------------------
// Capture component events
// ---------------------------------------------------------------------------

procedure TfrmCaptureDemo.OnCaptureFrame(Sender: TObject; const AFrameFile: string);
var
  Bmp: TBitmap;
begin
  // Load and show latest frame
  if FCapture.CaptureToBitmap(Bmp) then
  begin
    try
      FPreviewImg.Picture.Assign(Bmp);
    finally
      Bmp.Free;
    end;
  end
  else
  begin
    // Frame was saved to file — load from file for preview
    if FileExists(AFrameFile) then
    begin
      Bmp := TBitmap.Create;
      try
        Bmp.LoadFromFile(AFrameFile);
        FPreviewImg.Picture.Assign(Bmp);
      except
      end;
      Bmp.Free;
    end;
  end;
end;

procedure TfrmCaptureDemo.OnCaptureError(Sender: TObject; const AError: string);
begin
  Log('[ERROR] ' + AError);
end;

procedure TfrmCaptureDemo.OnCaptureState(Sender: TObject; AActive: Boolean);
begin
  if AActive then
    Log('Capture STARTED.')
  else
    Log('Capture STOPPED.');
  FBtnStart.Enabled := not AActive;
  FBtnStop.Enabled  := AActive;
end;

procedure TfrmCaptureDemo.OnMouseMove(Sender: TObject; X, Y: Integer);
begin
  Log(Format('Mouse: X=%d Y=%d', [X, Y]));
end;

procedure TfrmCaptureDemo.OnKeyIntercepted(Sender: TObject; KeyCode: Word; KeyChar: Char);
begin
  if KeyChar <> #0 then
    Log(Format('Key: "%s" [code=%d]', [KeyChar, KeyCode]))
  else
    Log(Format('CtrlKey: [code=%d]', [KeyCode]));
end;

// ---------------------------------------------------------------------------
// Button handlers
// ---------------------------------------------------------------------------

procedure TfrmCaptureDemo.BtnStartClick(Sender: TObject);
begin
  ApplyTabConfig;
  if FCapture.StartCapture then
    Log('StartCapture OK.')
  else
    Log('[FAIL] StartCapture — ' + FCapture.LastError);
end;

procedure TfrmCaptureDemo.BtnStopClick(Sender: TObject);
begin
  FCapture.StopCapture;
end;

procedure TfrmCaptureDemo.BtnFrameClick(Sender: TObject);
var
  Bmp: TBitmap;
begin
  if not FCapture.Active then
  begin
    ApplyTabConfig;
    FCapture.StartCapture;
  end;

  if FCapture.CaptureToBitmap(Bmp) then
  begin
    try
      FPreviewImg.Picture.Assign(Bmp);
      Log('Frame captured: ' + IntToStr(Bmp.Width) + 'x' + IntToStr(Bmp.Height));
    finally
      Bmp.Free;
    end;
  end
  else
    Log('[FAIL] CaptureToBitmap — ' + FCapture.LastError);
end;

procedure TfrmCaptureDemo.BtnSaveClick(Sender: TObject);
var
  Dlg: TSaveDialog;
begin
  Dlg := TSaveDialog.Create(nil);
  try
    Dlg.Filter      := 'BMP files (*.bmp)|*.bmp|All files (*.*)|*.*';
    Dlg.DefaultExt  := 'bmp';
    Dlg.FileName    := 'capture_' + FormatDateTime('yyyymmdd_hhnnss', Now) + '.bmp';
    if Dlg.Execute then
    begin
      if FCapture.CaptureToFile(Dlg.FileName) then
        Log('Frame saved to: ' + Dlg.FileName)
      else
        Log('[FAIL] CaptureToFile — ' + FCapture.LastError);
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TfrmCaptureDemo.BtnTestClick(Sender: TObject);
begin
  ApplyTabConfig;
  if FCapture.SelfTest then
    Log('[SelfTest] ' + FCapture.LastResult)
  else
    Log('[SelfTest FAIL] ' + FCapture.LastError);
end;

procedure TfrmCaptureDemo.BtnSourcesClick(Sender: TObject);
var
  SL: TStringList;
  I: Integer;
begin
  SL := FCapture.ListAvailableSources;
  try
    Log('--- Available Sources ---');
    for I := 0 to SL.Count - 1 do
      Log('  ' + SL[I]);
  finally
    SL.Free;
  end;
end;

procedure TfrmCaptureDemo.BtnBrowseClick(Sender: TObject);
var
  Dlg: TOpenDialog;
begin
  Dlg := TOpenDialog.Create(nil);
  try
    Dlg.Filter := 'Image files (*.bmp;*.jpg;*.jpeg;*.png)|*.bmp;*.jpg;*.jpeg;*.png|All files (*.*)|*.*';
    if Dlg.Execute then
    begin
      FEditFilePath.Text  := Dlg.FileName;
      FCapture.InputFile  := Dlg.FileName;
    end;
  finally
    Dlg.Free;
  end;
end;

end.
