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
    FLastImageFile: string;

    FPageControl: TPageControl;
    FTabDetect: TTabSheet;
    FTabSetup: TTabSheet;

    lblRuntimePath: TLabel;
    edRuntimePath: TEdit;
    btnBrowseRuntime: TButton;

    lblModelFile: TLabel;
    edModelFile: TEdit;
    btnBrowseModel: TButton;

    chkRequireReal: TCheckBox;
    lblBackendInfo: TLabel;
    lblBridgeInfo: TLabel;
    lblModelInfo: TLabel;

    btnReinit: TButton;

    procedure LogMsg(const AMsg: string);
    procedure LogDetectorMetadata;
    procedure UpdateBackendLabels;
    procedure ApplyDetectorOptions;
    function EnsureDetectorReady: Boolean;
    function IsRealBackend: Boolean;
    function IsSimBackend: Boolean;
    function GetImageDestRect: TRect;
    function TrySuggestModelFileFromBridgePath: string;
    procedure btnBrowseRuntimeClick(Sender: TObject);
    procedure btnBrowseModelClick(Sender: TObject);
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
  OnDestroy := @FormDestroy;

  FDetector := TAIHumanPoseDetector.Create(Self);
  FBmp := TBitmap.Create;
  FLastImageFile := '';

  { O PaintBox passa a desenhar imagem + pontos. O TImage fica apenas como
    armazenamento visual auxiliar, evitando overlay frágil entre controles. }
  imgPose.Visible := False;

  { Create PageControl at root level }
  FPageControl := TPageControl.Create(Self);
  FPageControl.Parent := Self;
  FPageControl.Align := alClient;

  { Tab Detect }
  FTabDetect := TTabSheet.Create(FPageControl);
  FTabDetect.PageControl := FPageControl;
  FTabDetect.Caption := 'Detecção';

  { Move main display panels inside FTabDetect }
  pnlLeft.Parent := FTabDetect;
  pnlBottom.Parent := FTabDetect;
  pnlClient.Parent := FTabDetect;

  { Tab Setup }
  FTabSetup := TTabSheet.Create(FPageControl);
  FTabSetup.PageControl := FPageControl;
  FTabSetup.Caption := 'Setup / Runtime';

  LPanelSetupTop := TPanel.Create(Self);
  LPanelSetupTop.Parent := FTabSetup;
  LPanelSetupTop.Align := alTop;
  LPanelSetupTop.Height := 330;
  LPanelSetupTop.BevelOuter := bvNone;

  lblRuntimePath := TLabel.Create(Self);
  lblRuntimePath.Parent := LPanelSetupTop;
  lblRuntimePath.Left := 20;
  lblRuntimePath.Top := 20;
  lblRuntimePath.Caption := 'DLL/SO da Bridge MediaPipe Pose:';
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
  btnBrowseRuntime.Width := 220;
  btnBrowseRuntime.Height := 30;
  btnBrowseRuntime.Caption := 'Procurar DLL/SO...';
  btnBrowseRuntime.OnClick := @btnBrowseRuntimeClick;

  lblModelFile := TLabel.Create(Self);
  lblModelFile.Parent := LPanelSetupTop;
  lblModelFile.Left := 20;
  lblModelFile.Top := 90;
  lblModelFile.Caption := 'Modelo MediaPipe Pose (.task) — obrigatório somente no backend REAL:';
  lblModelFile.Font.Style := [fsBold];

  edModelFile := TEdit.Create(Self);
  edModelFile.Parent := LPanelSetupTop;
  edModelFile.Left := 20;
  edModelFile.Top := 115;
  edModelFile.Width := 700;

  btnBrowseModel := TButton.Create(Self);
  btnBrowseModel.Parent := LPanelSetupTop;
  btnBrowseModel.Left := 730;
  btnBrowseModel.Top := 112;
  btnBrowseModel.Width := 220;
  btnBrowseModel.Height := 30;
  btnBrowseModel.Caption := 'Procurar .task...';
  btnBrowseModel.OnClick := @btnBrowseModelClick;

  chkRequireReal := TCheckBox.Create(Self);
  chkRequireReal.Parent := LPanelSetupTop;
  chkRequireReal.Left := 20;
  chkRequireReal.Top := 160;
  chkRequireReal.Width := 500;
  chkRequireReal.Caption := 'Exigir backend REAL para detectar de verdade';
  chkRequireReal.Checked := True;

  btnReinit := TButton.Create(Self);
  btnReinit.Parent := LPanelSetupTop;
  btnReinit.Left := 20;
  btnReinit.Top := 200;
  btnReinit.Width := 220;
  btnReinit.Height := 40;
  btnReinit.Caption := 'Carregar / Re-inicializar';
  btnReinit.Font.Style := [fsBold];
  btnReinit.OnClick := @btnReinitClick;

  lblBackendInfo := TLabel.Create(Self);
  lblBackendInfo.Parent := LPanelSetupTop;
  lblBackendInfo.Left := 270;
  lblBackendInfo.Top := 200;
  lblBackendInfo.Width := 650;
  lblBackendInfo.Caption := 'Backend: não carregado';
  lblBackendInfo.Font.Style := [fsBold];

  lblBridgeInfo := TLabel.Create(Self);
  lblBridgeInfo.Parent := LPanelSetupTop;
  lblBridgeInfo.Left := 270;
  lblBridgeInfo.Top := 225;
  lblBridgeInfo.Width := 650;
  lblBridgeInfo.Caption := 'Bridge: não carregada';

  lblModelInfo := TLabel.Create(Self);
  lblModelInfo.Parent := LPanelSetupTop;
  lblModelInfo.Left := 270;
  lblModelInfo.Top := 250;
  lblModelInfo.Width := 650;
  lblModelInfo.Caption := 'Modelo: não carregado';

  cbModelVariant.ItemIndex := 1; // Default: hpmFull

  chkSkeleton.Checked := True;
  chkPoints.Checked := True;
  chkNames.Checked := False;

  lblScore.Caption := 'Confiança: N/A';
  lblStatus.Caption := 'Estado: Não iniciado';

  LogMsg('FormCreate: Demo inicializado. Selecione a DLL/SO versionada e, para REAL, o modelo .task.');
  LogMsg('Regra: backend SIM apenas simula pontos; backend REAL usa a imagem e o modelo MediaPipe.');
end;

procedure TfrmPoseDemo.FormDestroy(Sender: TObject);
begin
  if Assigned(FDetector) then
    FDetector.FinalizeDetector;
  FreeAndNil(FBmp);
end;

function TfrmPoseDemo.IsRealBackend: Boolean;
begin
  Result := Assigned(FDetector) and SameText(Trim(FDetector.BridgeBackend), 'REAL');
end;

function TfrmPoseDemo.IsSimBackend: Boolean;
begin
  Result := Assigned(FDetector) and SameText(Trim(FDetector.BridgeBackend), 'SIM');
end;

procedure TfrmPoseDemo.UpdateBackendLabels;
var
  LBackend: string;
begin
  if not Assigned(FDetector) then Exit;

  LBackend := Trim(FDetector.BridgeBackend);
  if LBackend = '' then LBackend := 'UNKNOWN';

  lblBackendInfo.Caption := 'Backend: ' + LBackend;
  lblBridgeInfo.Caption := Format('Bridge: %s | ABI: %d | Lazarus: %s | DLL Arch: %s',
    [FDetector.BridgeVersionText,
     FDetector.BridgeAbiVersion,
     FDetector.LazarusArchitecture,
     FDetector.BridgeArchitecture]);

  if FDetector.LoadedModelFile <> '' then
    lblModelInfo.Caption := 'Modelo: ' + FDetector.LoadedModelFile
  else if IsSimBackend then
    lblModelInfo.Caption := 'Modelo: não usado no backend SIM'
  else
    lblModelInfo.Caption := 'Modelo: não carregado';

  if IsRealBackend then
    lblStatus.Caption := 'Estado: Backend REAL carregado'
  else if IsSimBackend then
    lblStatus.Caption := 'Estado: Backend SIM carregado'
  else
    lblStatus.Caption := 'Estado: Backend desconhecido';
end;

procedure TfrmPoseDemo.LogDetectorMetadata;
begin
  if not Assigned(FDetector) then Exit;

  LogMsg('=== STATUS DO COMPONENTE TAIHumanPoseDetector ===');
  LogMsg('Active: ' + BoolToStr(FDetector.Active, True));
  LogMsg('LoadedBridgeDLLPath: ' + FDetector.LoadedBridgeDLLPath);
  LogMsg('BridgeVersionText: ' + FDetector.BridgeVersionText);
  LogMsg('BridgeAbiVersion: ' + IntToStr(FDetector.BridgeAbiVersion));
  LogMsg('BridgeBackend: ' + FDetector.BridgeBackend);
  LogMsg('RequiredMediaPipeVersion: ' + FDetector.RequiredMediaPipeVersion);
  LogMsg('LoadedModelFile: ' + FDetector.LoadedModelFile);
  LogMsg('LazarusArchitecture: ' + FDetector.LazarusArchitecture);
  LogMsg('BridgeArchitecture: ' + FDetector.BridgeArchitecture);
  LogMsg('===============================================');

  if IsSimBackend then
  begin
    LogMsg('ATENÇÃO: backend SIM está ativo. Os landmarks são simulados e NÃO vêm da imagem.');
    LogMsg('Para achar pontos reais do corpo, carregue uma DLL compilada com MP_BRIDGE_BACKEND=REAL e informe o arquivo .task.');
  end
  else if IsRealBackend then
  begin
    LogMsg('Backend REAL ativo: a detecção deverá usar os pixels da imagem e o modelo .task.');
  end
  else
  begin
    LogMsg('ATENÇÃO: backend desconhecido. Não declarar reconhecimento real sem validação.');
  end;
end;

procedure TfrmPoseDemo.ApplyDetectorOptions;
begin
  case cbModelVariant.ItemIndex of
    0:
      begin
        FDetector.ModelVariant := hpmLite;
        LogMsg('Configuração: ModelVariant = hpmLite');
      end;
    2:
      begin
        FDetector.ModelVariant := hpmHeavy;
        LogMsg('Configuração: ModelVariant = hpmHeavy');
      end;
  else
    begin
      FDetector.ModelVariant := hpmFull;
      LogMsg('Configuração: ModelVariant = hpmFull');
    end;
  end;

  FDetector.DrawSkeleton := chkSkeleton.Checked;
  FDetector.DrawLandmarkPoints := chkPoints.Checked;
  FDetector.DrawLandmarkNames := chkNames.Checked;

  if Trim(edModelFile.Text) <> '' then
    FDetector.ModelFile := Trim(edModelFile.Text)
  else
    FDetector.ModelFile := '';
end;

function TfrmPoseDemo.EnsureDetectorReady: Boolean;
begin
  Result := False;

  ApplyDetectorOptions;

  if not FDetector.Active then
  begin
    LogMsg('EnsureDetectorReady: detector inativo. Inicializando via Active=True...');
    FDetector.Active := True;
  end;

  if not FDetector.Active then
  begin
    LogMsg('EnsureDetectorReady: falha ao inicializar detector: ' + FDetector.LastError);
    UpdateBackendLabels;
    ShowMessage('Falha ao inicializar detector:' + sLineBreak + FDetector.LastError);
    Exit(False);
  end;

  UpdateBackendLabels;
  LogDetectorMetadata;
  Result := True;
end;

function TfrmPoseDemo.TrySuggestModelFileFromBridgePath: string;
var
  LDir: string;
begin
  Result := '';
  if Trim(edRuntimePath.Text) = '' then Exit;

  if FileExists(edRuntimePath.Text) then
    LDir := ExtractFilePath(edRuntimePath.Text)
  else
    LDir := IncludeTrailingPathDelimiter(edRuntimePath.Text);

  Result := IncludeTrailingPathDelimiter(LDir) + 'models' + DirectorySeparator + 'pose_landmarker_full.task';
  if not FileExists(Result) then
    Result := '';
end;

procedure TfrmPoseDemo.btnLoadImageClick(Sender: TObject);
var
  LInitialDir: string;
  LPicture: TPicture;
begin
  LogMsg('btnLoadImageClick: resolvendo diretório inicial...');
  LInitialDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'images';
  if DirectoryExists(LInitialDir) then
  begin
    OpenDialog1.InitialDir := LInitialDir;
    LogMsg('btnLoadImageClick: diretório de imagens encontrado: ' + LInitialDir);
  end
  else
  begin
    OpenDialog1.InitialDir := ExtractFilePath(ParamStr(0));
    LogMsg('btnLoadImageClick: diretório images não encontrado. Usando pasta do executável.');
  end;

  if OpenDialog1.Execute then
  begin
    FLastImageFile := OpenDialog1.FileName;
    LogMsg('btnLoadImageClick: arquivo selecionado: ' + FLastImageFile);
    LPicture := TPicture.Create;
    try
      try
        LPicture.LoadFromFile(FLastImageFile);
        LogMsg(Format('btnLoadImageClick: tipo gráfico decodificado: %s', [LPicture.Graphic.ClassName]));

        FBmp.SetSize(LPicture.Width, LPicture.Height);
        FBmp.Canvas.Draw(0, 0, LPicture.Graphic);
        imgPose.Picture.Assign(FBmp);

        FDetector.ClearResult;
        pbCanvas.Invalidate;

        lblStatus.Caption := 'Estado: imagem carregada';
        LogMsg(Format('btnLoadImageClick: imagem carregada (%dx%d)', [FBmp.Width, FBmp.Height]));
      except
        on E: Exception do
        begin
          LogMsg('btnLoadImageClick: erro ao carregar imagem: ' + E.Message);
          ShowMessage('Falha ao carregar imagem: ' + E.Message);
        end;
      end;
    finally
      LPicture.Free;
    end;
  end
  else
    LogMsg('btnLoadImageClick: seleção cancelada pelo usuário.');
end;

procedure TfrmPoseDemo.btnDetectClick(Sender: TObject);
var
  TStart, TEnd: TDateTime;
  ElapsedMs: Double;
  Success: Boolean;
  I: Integer;
begin
  LogMsg('btnDetectClick: iniciando detecção.');

  FDetector.ClearResult;
  pbCanvas.Invalidate;

  if (FBmp = nil) or (FBmp.Width = 0) or (FBmp.Height = 0) then
  begin
    LogMsg('btnDetectClick: nenhuma imagem carregada.');
    ShowMessage('Carregue uma imagem primeiro.');
    Exit;
  end;

  if not EnsureDetectorReady then
    Exit;

  if chkRequireReal.Checked and not IsRealBackend then
  begin
    LogMsg('btnDetectClick: bloqueado porque o usuário exigiu backend REAL e a bridge atual é: ' + FDetector.BridgeBackend);
    ShowMessage('Esta DLL não está reconhecendo a imagem de verdade.' + sLineBreak + sLineBreak +
      'Backend atual: ' + FDetector.BridgeBackend + sLineBreak +
      'Para achar pontos reais do corpo, carregue uma DLL compilada com MP_BRIDGE_BACKEND=REAL e informe o modelo .task.' + sLineBreak + sLineBreak +
      'Desmarque "Exigir backend REAL" apenas se quiser visualizar a simulação.');
    lblStatus.Caption := 'Estado: SIM bloqueado para detecção real';
    Exit;
  end;

  if IsSimBackend then
  begin
    LogMsg('AVISO: executando backend SIM. Os pontos serão fixos/simulados e não representam a pessoa da imagem.');
    lblStatus.Caption := 'Estado: detecção SIMULADA';
  end
  else if IsRealBackend then
  begin
    LogMsg('Backend REAL confirmado. Executando MediaPipe sobre a imagem: ' + FLastImageFile);
    lblStatus.Caption := 'Estado: detectando com backend REAL';
  end;

  TStart := Now;
  try
    Success := FDetector.DetectBitmap(FBmp);
    TEnd := Now;
    ElapsedMs := (TEnd - TStart) * 24.0 * 60.0 * 60.0 * 1000.0;

    LogMsg(Format('btnDetectClick: DetectBitmap finalizado em %.2f ms. Success=%s. Backend=%s',
      [ElapsedMs, BoolToStr(Success, 'True', 'False'), FDetector.BridgeBackend]));

    if Success and (FDetector.GetPoseCount > 0) then
    begin
      lblScore.Caption := Format('Landmarks: %d | Tempo: %.2f ms', [FDetector.GetPoseCount * 33, ElapsedMs]);

      if IsRealBackend then
        lblStatus.Caption := 'Estado: pose REAL detectada'
      else
        lblStatus.Caption := 'Estado: pose SIMULADA detectada';

      LogMsg('=== RESULTADO DA DETECÇÃO ===');
      LogMsg('Imagem: ' + FLastImageFile);
      LogMsg('Backend: ' + FDetector.BridgeBackend);
      LogMsg('Modelo carregado: ' + FDetector.LoadedModelFile);
      LogMsg('PoseCount: ' + IntToStr(FDetector.GetPoseCount));
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

      if IsSimBackend then
      begin
        LogMsg('AVISO FINAL: estes pontos são simulados. Se duas imagens gerarem os mesmos pontos, isso é esperado em SIM.');
      end;

      LogMsg('============================');
      pbCanvas.Invalidate;
    end
    else
    begin
      lblScore.Caption := 'Confiança: N/A';
      lblStatus.Caption := 'Estado: nenhuma pose detectada';
      LogMsg('btnDetectClick: nenhuma pose encontrada. LastError=' + FDetector.LastError);
    end;
  except
    on E: Exception do
    begin
      LogMsg('btnDetectClick: exceção durante processamento: ' + E.Message);
      ShowMessage('Erro: ' + E.Message);
    end;
  end;
end;

procedure TfrmPoseDemo.pbCanvasPaint(Sender: TObject);
var
  LRect: TRect;
begin
  if Assigned(FBmp) and (FBmp.Width > 0) and (FBmp.Height > 0) then
  begin
    LRect := GetImageDestRect;
    pbCanvas.Canvas.StretchDraw(LRect, FBmp);

    if Assigned(FDetector) and (FDetector.GetPoseCount > 0) then
      FDetector.DrawResult(pbCanvas.Canvas, LRect);
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

  if (FBmp = nil) or (FBmp.Width = 0) or (FBmp.Height = 0) then
    Exit;

  ImgW := FBmp.Width;
  ImgH := FBmp.Height;
  BoxW := pbCanvas.Width;
  BoxH := pbCanvas.Height;

  if (ImgW <= 0) or (ImgH <= 0) or (BoxW <= 0) or (BoxH <= 0) then
    Exit;

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

  TargetX := (BoxW - TargetW) div 2;
  TargetY := (BoxH - TargetH) div 2;

  Result := Rect(TargetX, TargetY, TargetX + TargetW, TargetY + TargetH);
end;

procedure TfrmPoseDemo.chkDrawOptionsChange(Sender: TObject);
begin
  if Assigned(FDetector) then
  begin
    FDetector.DrawSkeleton := chkSkeleton.Checked;
    FDetector.DrawLandmarkPoints := chkPoints.Checked;
    FDetector.DrawLandmarkNames := chkNames.Checked;
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
  LSuggestedModel: string;
begin
  LOpenDlg := TOpenDialog.Create(Self);
  try
    LOpenDlg.Title := 'Selecionar Biblioteca Pose Bridge versionada (DLL/SO)';
    {$IFDEF MSWINDOWS}
    LOpenDlg.Filter := 'Bridge versionada (*.dll)|*.dll|Todos Arquivos (*.*)|*.*';
    {$ELSE}
    LOpenDlg.Filter := 'Bridge versionada (*.so)|*.so|Todos Arquivos (*.*)|*.*';
    {$ENDIF}

    if edRuntimePath.Text <> '' then
      LOpenDlg.InitialDir := ExtractFilePath(edRuntimePath.Text)
    else
      LOpenDlg.InitialDir := ExtractFilePath(ParamStr(0));

    if LOpenDlg.Execute then
    begin
      edRuntimePath.Text := LOpenDlg.FileName;
      LogMsg('btnBrowseRuntimeClick: DLL/SO selecionada: ' + LOpenDlg.FileName);

      LSuggestedModel := TrySuggestModelFileFromBridgePath;
      if (edModelFile.Text = '') and (LSuggestedModel <> '') then
      begin
        edModelFile.Text := LSuggestedModel;
        LogMsg('btnBrowseRuntimeClick: modelo sugerido automaticamente: ' + LSuggestedModel);
      end;
    end;
  finally
    LOpenDlg.Free;
  end;
end;

procedure TfrmPoseDemo.btnBrowseModelClick(Sender: TObject);
var
  LOpenDlg: TOpenDialog;
begin
  LOpenDlg := TOpenDialog.Create(Self);
  try
    LOpenDlg.Title := 'Selecionar modelo MediaPipe Pose Landmarker (.task)';
    LOpenDlg.Filter := 'Modelos MediaPipe Task (*.task)|*.task|Todos Arquivos (*.*)|*.*';

    if edModelFile.Text <> '' then
      LOpenDlg.InitialDir := ExtractFilePath(edModelFile.Text)
    else if edRuntimePath.Text <> '' then
      LOpenDlg.InitialDir := IncludeTrailingPathDelimiter(ExtractFilePath(edRuntimePath.Text)) + 'models'
    else
      LOpenDlg.InitialDir := ExtractFilePath(ParamStr(0));

    if LOpenDlg.Execute then
    begin
      edModelFile.Text := LOpenDlg.FileName;
      LogMsg('btnBrowseModelClick: modelo .task selecionado: ' + LOpenDlg.FileName);
    end;
  finally
    LOpenDlg.Free;
  end;
end;

procedure TfrmPoseDemo.btnReinitClick(Sender: TObject);
begin
  LogMsg('btnReinitClick: reinicializando detector.');

  FDetector.FinalizeDetector;
  FDetector.Active := False;

  if Trim(edRuntimePath.Text) <> '' then
  begin
    FDetector.LoadMode := mplmManualPath;
    FDetector.BridgeDLLPath := Trim(edRuntimePath.Text);
  end
  else
  begin
    FDetector.LoadMode := mplmAuto;
    FDetector.BridgeDLLPath := '';
  end;

  ApplyDetectorOptions;

  LogMsg('btnReinitClick: BridgeDLLPath=' + FDetector.BridgeDLLPath);
  LogMsg('btnReinitClick: ModelFile=' + FDetector.ModelFile);
  LogMsg('btnReinitClick: ativando componente...');

  FDetector.Active := True;

  if FDetector.Active then
  begin
    LogMsg('btnReinitClick: detector inicializado com sucesso.');
    UpdateBackendLabels;
    LogDetectorMetadata;
    edRuntimePath.Text := FDetector.LoadedBridgeDLLPath;

    if IsSimBackend then
      ShowMessage('Detector carregado em backend SIM.' + sLineBreak + sLineBreak +
        'A DLL carregou, mas os pontos serão simulados. Para reconhecimento real, use uma DLL REAL e um modelo .task.')
    else if IsRealBackend then
      ShowMessage('Detector REAL inicializado com sucesso!' + sLineBreak +
        'DLL: ' + FDetector.LoadedBridgeDLLPath + sLineBreak +
        'Modelo: ' + FDetector.LoadedModelFile)
    else
      ShowMessage('Detector inicializado, mas o backend não foi identificado: ' + FDetector.BridgeBackend);
  end
  else
  begin
    LogMsg('btnReinitClick: erro ao inicializar: ' + FDetector.LastError);
    lblStatus.Caption := 'Estado: erro na DLL/modelo';
    UpdateBackendLabels;
    ShowMessage('Falha ao inicializar detector:' + sLineBreak + FDetector.LastError);
  end;
end;

end.
