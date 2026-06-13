unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  Buttons, aihumanposedetector, aihumanpose_types, LCLType, lazpng, ComCtrls;

type

  { TfrmPoseDemo }

  TfrmPoseDemo = class(TForm)
    pnlLeft: TPanel;
    pnlClient: TPanel;
    pnlBottom: TPanel;
    
    pnlImage: TPanel;
    pnlDraw: TPanel;
    
    btnLoadImage: TButton;
    btnDetect: TButton;
    chkSkeleton: TCheckBox;
    chkPoints: TCheckBox;
    chkNames: TCheckBox;
    
    lblModelVariant: TLabel;
    cbModelVariant: TComboBox;
    
    lblScore: TLabel;
    lblBackend: TLabel;
    lblStatus: TLabel;
    
    imgPose: TImage;
    pbCanvas: TPaintBox;
    
    memLog: TMemo;
    OpenDialog1: TOpenDialog;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnLoadImageClick(Sender: TObject);
    procedure btnDetectClick(Sender: TObject);
    procedure pbCanvasPaint(Sender: TObject);
    procedure chkDrawOptionsChange(Sender: TObject);
  private
    FDetector: TAIHumanPoseDetector;
    FBmp: TBitmap;
    FPageControl: TPageControl;
    FTabDetect: TTabSheet;
    FTabSetup: TTabSheet;
    lblRuntimePath: TLabel;
    edRuntimePath: TEdit;
    btnBrowseRuntime: TButton;
    btnReinit: TButton;
    
    procedure LogMsg(const AMsg: string);
    procedure SyncBackendStatus;
    procedure LogDetectorSummary;
    function GetImageDestRect: TRect;
    procedure btnBrowseRuntimeClick(Sender: TObject);
    procedure btnReinitClick(Sender: TObject);
  public

  end;

var
  frmPoseDemo: TfrmPoseDemo;

implementation

{$R *.lfm}

{ TfrmPoseDemo }

procedure TfrmPoseDemo.FormCreate(Sender: TObject);
var
  LPanelSetupTop: TPanel;
begin
  FDetector := TAIHumanPoseDetector.Create(Self);
  FBmp := TBitmap.Create;
  
  // Create PageControl at root level
  FPageControl := TPageControl.Create(Self);
  FPageControl.Parent := Self;
  FPageControl.Align := alClient;
  
  // Tab Detect
  FTabDetect := TTabSheet.Create(FPageControl);
  FTabDetect.PageControl := FPageControl;
  FTabDetect.Caption := 'Detecção';
  
  // Move main display panels inside FTabDetect
  pnlLeft.Parent := FTabDetect;
  pnlBottom.Parent := FTabDetect;
  pnlClient.Parent := FTabDetect;
  
  // Tab Setup
  FTabSetup := TTabSheet.Create(FPageControl);
  FTabSetup.PageControl := FPageControl;
  FTabSetup.Caption := 'Setup';
  
  // Create Setup Top Panel (occupies the entire upper area)
  LPanelSetupTop := TPanel.Create(Self);
  LPanelSetupTop.Parent := FTabSetup;
  LPanelSetupTop.Align := alTop;
  LPanelSetupTop.Height := 180;
  LPanelSetupTop.BevelOuter := bvNone;
  
  // Create Setup Tab Controls inside LPanelSetupTop
  lblRuntimePath := TLabel.Create(Self);
  lblRuntimePath.Parent := LPanelSetupTop;
  lblRuntimePath.Left := 20;
  lblRuntimePath.Top := 20;
  lblRuntimePath.Caption := 'Caminho da Biblioteca Bridge (DLL/SO):';
  lblRuntimePath.Font.Style := [fsBold];
  
  edRuntimePath := TEdit.Create(Self);
  edRuntimePath.Parent := LPanelSetupTop;
  edRuntimePath.Left := 20;
  edRuntimePath.Top := 45;
  edRuntimePath.Width := 700;
  
  btnBrowseRuntime := TButton.Create(Self);
  btnBrowseRuntime.Parent := LPanelSetupTop;
  btnBrowseRuntime.Left := 730;
  btnBrowseRuntime.Top := 42;
  btnBrowseRuntime.Width := 200;
  btnBrowseRuntime.Height := 30;
  btnBrowseRuntime.Caption := 'Procurar DLL/SO...';
  btnBrowseRuntime.OnClick := @btnBrowseRuntimeClick;
  
  btnReinit := TButton.Create(Self);
  btnReinit.Parent := LPanelSetupTop;
  btnReinit.Left := 20;
  btnReinit.Top := 95;
  btnReinit.Width := 200;
  btnReinit.Height := 40;
  btnReinit.Caption := 'Carregar / Re-inicializar';
  btnReinit.Font.Style := [fsBold];
  btnReinit.OnClick := @btnReinitClick;
  
  cbModelVariant.ItemIndex := 1; // Default: hpmFull
  
  chkSkeleton.Checked := True;
  chkPoints.Checked := True;
  chkNames.Checked := False;
  
  lblScore.Caption := 'Landmarks: N/A';
  lblBackend.Caption := 'Backend: N/A';
  lblStatus.Caption := 'Estado: Não Iniciado';
  
  LogMsg('FormCreate: Human Pose Detector MediaPipe Demo Initialized. (Click "Carregar / Re-inicializar" to load library)');
end;

procedure TfrmPoseDemo.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FBmp);
  FreeAndNil(FDetector);
end;

procedure TfrmPoseDemo.btnLoadImageClick(Sender: TObject);
var
  LInitialDir: string;
  LPicture: TPicture;
begin
  LogMsg('btnLoadImageClick: Resolving initial path...');
  LInitialDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'images';
  if DirectoryExists(LInitialDir) then
  begin
    OpenDialog1.InitialDir := LInitialDir;
    LogMsg('btnLoadImageClick: Target images directory exists: ' + LInitialDir);
  end
  else
  begin
    OpenDialog1.InitialDir := ExtractFilePath(ParamStr(0));
    LogMsg('btnLoadImageClick: Target images directory missing. Fallback path set to: ' + OpenDialog1.InitialDir);
  end;

  LogMsg('btnLoadImageClick: Opening file select dialog...');
  if OpenDialog1.Execute then
  begin
    LogMsg('btnLoadImageClick: File selected: ' + OpenDialog1.FileName);
    LPicture := TPicture.Create;
    try
      try
        LogMsg('btnLoadImageClick: Instantiating graphic reader...');
        LPicture.LoadFromFile(OpenDialog1.FileName);
        LogMsg(Format('btnLoadImageClick: Decoded graphic type: %s', [LPicture.Graphic.ClassName]));
        
        LogMsg(Format('btnLoadImageClick: Setting canvas buffer size to %dx%d...', [LPicture.Width, LPicture.Height]));
        FBmp.SetSize(LPicture.Width, LPicture.Height);
        
        LogMsg('btnLoadImageClick: Rendering graphic onto bitmap canvas...');
        FBmp.Canvas.Draw(0, 0, LPicture.Graphic);
        
        LogMsg('btnLoadImageClick: Assigning bitmap to UI TImage component...');
        imgPose.Picture.Assign(FBmp);
        
        LogMsg('btnLoadImageClick: Clearing old detection points...');
        FDetector.ClearResult;
        lblScore.Caption := 'Landmarks: N/A';
        
        LogMsg('btnLoadImageClick: Requesting repaint on canvas overlay...');
        pbCanvas.Invalidate;
        
        LogMsg(Format('btnLoadImageClick: Loaded successfully (%dx%d)', [FBmp.Width, FBmp.Height]));
        except
          on E: Exception do
          begin
            LogMsg('btnLoadImageClick: Exception caught during loading: ' + E.Message);
            lblScore.Caption := 'Landmarks: N/A';
            ShowMessage('Failed to load image: ' + E.Message);
          end;
        end;
    finally
      LPicture.Free;
      LogMsg('btnLoadImageClick: Reader object instance freed.');
    end;
  end
  else
  begin
    LogMsg('btnLoadImageClick: User cancelled file selection dialog.');
  end;
end;

procedure TfrmPoseDemo.btnDetectClick(Sender: TObject);
var
  TStart, TEnd: TDateTime;
  ElapsedMs: Double;
  Success: Boolean;
  I: Integer;
begin
  LogMsg('btnDetectClick: Verification steps started.');

  if FBmp.Width = 0 then
  begin
    LogMsg('btnDetectClick: Error - No image loaded in active buffer.');
    lblScore.Caption := 'Landmarks: N/A';
    ShowMessage('Please load an image first.');
    Exit;
  end;

  if not FDetector.Initialized then
  begin
    LogMsg('btnDetectClick: Detector dynamic library not loaded. Attempting initialization...');
    if not FDetector.Initialize then
    begin
      LogMsg('btnDetectClick: Error - Detector initialization failed: ' + FDetector.LastError);
      lblStatus.Caption := 'Estado: Erro na inicialização';
      lblScore.Caption := 'Landmarks: N/A';
      SyncBackendStatus;
      ShowMessage('Error: detector initialization failed.' + sLineBreak + 'Details: ' + FDetector.LastError);
      Exit;
    end;
    LogMsg('btnDetectClick: DLL loaded successfully at runtime!');
    LogDetectorSummary;
    if SameText(FDetector.BridgeBackend, 'REAL') then
      cbModelVariant.ItemIndex := 1;
    lblStatus.Caption := 'Estado: Inicializado';
    SyncBackendStatus;
  end;

  LogMsg('btnDetectClick: Clearing old points...');
  FDetector.ClearResult;
  pbCanvas.Invalidate;

  SyncBackendStatus;

  LogMsg('btnDetectClick: Initializing detector configuration options...');
  
  // Set configuration
  case cbModelVariant.ItemIndex of
    0:
      begin
        FDetector.ModelVariant := hpmLite;
        LogMsg('btnDetectClick: Configuration set: ModelVariant = hpmLite');
      end;
    2:
      begin
        FDetector.ModelVariant := hpmHeavy;
        LogMsg('btnDetectClick: Configuration set: ModelVariant = hpmHeavy');
      end;
    else
      begin
        FDetector.ModelVariant := hpmFull;
        LogMsg('btnDetectClick: Configuration set: ModelVariant = hpmFull');
      end;
  end;

  FDetector.DrawSkeleton := chkSkeleton.Checked;
  FDetector.DrawLandmarkPoints := chkPoints.Checked;
  FDetector.DrawLandmarkNames := chkNames.Checked;
  LogMsg(Format('btnDetectClick: Options - Skeleton=%s, Points=%s, Names=%s',
    [BoolToStr(FDetector.DrawSkeleton, 'True', 'False'),
     BoolToStr(FDetector.DrawLandmarkPoints, 'True', 'False'),
     BoolToStr(FDetector.DrawLandmarkNames, 'True', 'False')]));

  LogMsg('btnDetectClick: Initiating MediaPipe detection sequence...');
  TStart := Now;
  try
    Success := FDetector.DetectBitmap(FBmp);
    TEnd := Now;
    ElapsedMs := (TEnd - TStart) * 24.0 * 60.0 * 60.0 * 1000.0;
    
    LogMsg(Format('btnDetectClick: Detection call finished in %.2f ms. Success flag: %s',
      [ElapsedMs, BoolToStr(Success, 'True', 'False')]));
      
    if Success and (FDetector.GetPoseCount > 0) then
    begin
      lblScore.Caption := Format('Landmarks: %d', [FDetector.LastResultData.Poses[0].LandmarkCount]);
      lblStatus.Caption := 'Estado: Pose Detectada';
      LogMsg('btnDetectClick: Pose detected.');
      LogMsg(Format('Landmarks: %d', [FDetector.LastResultData.Poses[0].LandmarkCount]));
      
      LogMsg('=== PONTOS IDENTIFICADOS ===');
      for I := 0 to 32 do
      begin
        LogMsg(Format('Ponto #%d [%s]: (X: %.4f, Y: %.4f, Z: %.4f, Visibilidade: %.2f, Presença: %.2f)',
          [I,
           LANDMARK_NAMES[I],
           FDetector.LastResultData.Poses[0].Landmarks[I].X,
           FDetector.LastResultData.Poses[0].Landmarks[I].Y,
           FDetector.LastResultData.Poses[0].Landmarks[I].Z,
           FDetector.LastResultData.Poses[0].Landmarks[I].Visibility,
           FDetector.LastResultData.Poses[0].Landmarks[I].Presence]));
      end;
      LogMsg('============================');
      
      LogMsg('=== LEGENDA DOS PONTOS ===');
      LogMsg('0..10: Cabeça/Rosto (Nariz, Olhos, Orelhas, Boca)');
      LogMsg('11..12: Ombros');
      LogMsg('13..16: Braços e Pulsos (Cotovelos, Pulsos)');
      LogMsg('17..22: Mãos e Dedos (Mindinho, Indicador, Polegar)');
      LogMsg('23..24: Quadris');
      LogMsg('25..26: Joelhos');
      LogMsg('27..28: Tornozelos');
      LogMsg('29..32: Calcanhares e Pés');
      LogMsg('==========================');
      LogMsg(Format('Tempo: %.2f ms', [ElapsedMs]));
      
      LogMsg('btnDetectClick: Requesting repaint on canvas overlay...');
      pbCanvas.Invalidate;
    end
    else
    begin
      lblScore.Caption := 'Landmarks: 0';
      lblStatus.Caption := 'Estado: Nenhuma Pose Detectada';
      LogMsg('btnDetectClick: No pose found in the processed bitmap.');
    end;
  except
    on E: Exception do
    begin
      LogMsg('btnDetectClick: Exception caught during processing: ' + E.Message);
      lblStatus.Caption := 'Estado: Erro na detecção';
      lblScore.Caption := 'Landmarks: N/A';
      ShowMessage('Error: ' + E.Message);
    end;
  end;
end;

procedure TfrmPoseDemo.pbCanvasPaint(Sender: TObject);
var
  LRect: TRect;
begin
  if Assigned(FDetector) and (FDetector.GetPoseCount > 0) then
  begin
    LRect := GetImageDestRect;
    FDetector.DrawResult(pbCanvas.Canvas, LRect);
  end;
end;

procedure TfrmPoseDemo.SyncBackendStatus;
begin
  if Assigned(FDetector) and FDetector.Initialized then
    lblBackend.Caption := 'Backend: ' + FDetector.BridgeBackend
  else
    lblBackend.Caption := 'Backend: N/A';
end;

procedure TfrmPoseDemo.LogDetectorSummary;
begin
  if not Assigned(FDetector) then
    Exit;

  LogMsg('DLL carregada: ' + FDetector.LoadedBridgeDLLPath);
  LogMsg('Bridge version: ' + FDetector.BridgeVersionText);
  LogMsg('MediaPipe version: ' + FDetector.RequiredMediaPipeVersion);
  LogMsg('Backend: ' + FDetector.BridgeBackend);

  if SameText(FDetector.BridgeBackend, 'SIM') then
    LogMsg('ATENÇÃO: backend SIM gera landmarks simulados. Ele não reconhece a imagem real.')
  else if SameText(FDetector.BridgeBackend, 'REAL') then
  begin
    LogMsg('Backend REAL ativo.');
    LogMsg('Modelo carregado: ' + FDetector.LoadedModelFile);
  end;
end;

function TfrmPoseDemo.GetImageDestRect: TRect;
var
  ImgW, ImgH: Integer;
  BoxW, BoxH: Integer;
  AspectImg, AspectBox: Double;
  TargetW, TargetH: Integer;
  TargetX, TargetY: Integer;
begin
  Result := Rect(0, 0, pbCanvas.Width, pbCanvas.Height);
  if (imgPose.Picture = nil) or (imgPose.Picture.Width = 0) or (imgPose.Picture.Height = 0) then
    Exit;

  ImgW := imgPose.Picture.Width;
  ImgH := imgPose.Picture.Height;
  BoxW := pbCanvas.Width;
  BoxH := pbCanvas.Height;

  if imgPose.Proportional then
  begin
    AspectImg := ImgW / ImgH;
    AspectBox := BoxW / BoxH;

    if AspectImg > AspectBox then
    begin
      TargetW := BoxW;
      TargetH := Round(BoxW / AspectImg);
    end
    else
    begin
      TargetH := BoxH;
      TargetW := Round(BoxH * AspectImg);
    end;
  end
  else if imgPose.Stretch then
  begin
    TargetW := BoxW;
    TargetH := BoxH;
  end
  else
  begin
    TargetW := ImgW;
    TargetH := ImgH;
  end;

  if imgPose.Center then
  begin
    TargetX := (BoxW - TargetW) div 2;
    TargetY := (BoxH - TargetH) div 2;
  end
  else
  begin
    TargetX := 0;
    TargetY := 0;
  end;

  Result := Rect(TargetX, TargetY, TargetX + TargetW, TargetY + TargetH);
end;

procedure TfrmPoseDemo.chkDrawOptionsChange(Sender: TObject);
begin
  if Assigned(FDetector) then
  begin
    FDetector.DrawSkeleton := chkSkeleton.Checked;
    FDetector.DrawLandmarkPoints := chkPoints.Checked;
    FDetector.DrawLandmarkNames := chkNames.Checked;
    LogMsg('chkDrawOptionsChange: Drawing parameters updated. Refreshing overlay...');
    pbCanvas.Invalidate;
  end;
end;

procedure TfrmPoseDemo.LogMsg(const AMsg: string);
var
  LFormatted: string;
  LFilePath: string;
  LFileStream: TStringList;
begin
  LFormatted := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' - ' + AMsg;
  memLog.Lines.Add(LFormatted);
  
  // Append message to persistent log file next to executable
  LFilePath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'detector_execution.log';
  LFileStream := TStringList.Create;
  try
    if FileExists(LFilePath) then
      LFileStream.LoadFromFile(LFilePath);
    LFileStream.Add(LFormatted);
    LFileStream.SaveToFile(LFilePath);
  finally
    LFileStream.Free;
  end;
end;

procedure TfrmPoseDemo.btnBrowseRuntimeClick(Sender: TObject);
var
  LOpenDlg: TOpenDialog;
begin
  LOpenDlg := TOpenDialog.Create(Self);
  try
    LOpenDlg.Title := 'Selecionar Biblioteca Pose Bridge (DLL/SO)';
    {$IFDEF MSWINDOWS}
    LOpenDlg.Filter := 'Bibliotecas Dynamic Link (*.dll)|*.dll|Todos Arquivos (*.*)|*.*';
    {$ELSE}
    LOpenDlg.Filter := 'Bibliotecas Shared Object (*.so)|*.so|Todos Arquivos (*.*)|*.*';
    {$ENDIF}
    if edRuntimePath.Text <> '' then
      LOpenDlg.InitialDir := ExtractFilePath(edRuntimePath.Text)
    else
      LOpenDlg.InitialDir := ExtractFilePath(ParamStr(0));
      
    if LOpenDlg.Execute then
    begin
      edRuntimePath.Text := LOpenDlg.FileName;
      LogMsg('btnBrowseRuntimeClick: Selected bridge library: ' + LOpenDlg.FileName);
    end;
  finally
    LOpenDlg.Free;
  end;
end;

procedure TfrmPoseDemo.btnReinitClick(Sender: TObject);
begin
  LogMsg('btnReinitClick: Updating bridge DLL path to: ' + edRuntimePath.Text);
  // Unload first
  FDetector.Active := False;
  
  // Set DLL path and load mode
  if edRuntimePath.Text <> '' then
  begin
    FDetector.LoadMode := mplmManualPath;
    FDetector.BridgeDLLPath := edRuntimePath.Text;
  end
  else
    FDetector.LoadMode := mplmAuto;

  LogMsg('btnReinitClick: Initializing detector...');
  if FDetector.Initialize then
  begin
    LogMsg('btnReinitClick: Detector re-initialized successfully!');
    LogDetectorSummary;
    if SameText(FDetector.BridgeBackend, 'REAL') then
      cbModelVariant.ItemIndex := 1;
    lblStatus.Caption := 'Estado: Inicializado';
    lblScore.Caption := 'Landmarks: N/A';
    SyncBackendStatus;
    edRuntimePath.Text := FDetector.LoadedBridgeDLLPath;
    ShowMessage('Detector re-inicializado com sucesso!' + sLineBreak + 'DLL: ' + FDetector.LoadedBridgeDLLPath);
  end
  else
  begin
    LogMsg('btnReinitClick: ERROR re-initializing detector: ' + FDetector.LastError);
    lblStatus.Caption := 'Estado: Erro na inicialização';
    lblScore.Caption := 'Landmarks: N/A';
    SyncBackendStatus;
    ShowMessage('Falha ao re-inicializar o detector: ' + FDetector.LastError);
  end;
end;

end.
