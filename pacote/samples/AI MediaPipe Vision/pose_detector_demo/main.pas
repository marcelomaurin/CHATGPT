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

    btnLoadImage: TButton;
    btnDetect: TButton;
    chkSkeleton: TCheckBox;
    chkPoints: TCheckBox;
    chkNames: TCheckBox;
    chkRequireReal: TCheckBox;

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
    function  GetImageDestRect: TRect;
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
  FBmp      := TBitmap.Create;

  { ---- PageControl ---- }
  FPageControl            := TPageControl.Create(Self);
  FPageControl.Parent     := Self;
  FPageControl.Align      := alClient;

  { Tab Detecção }
  FTabDetect              := TTabSheet.Create(FPageControl);
  FTabDetect.PageControl  := FPageControl;
  FTabDetect.Caption      := 'Detecção';

  pnlLeft.Parent   := FTabDetect;
  pnlBottom.Parent := FTabDetect;
  pnlClient.Parent := FTabDetect;

  { Tab Setup }
  FTabSetup             := TTabSheet.Create(FPageControl);
  FTabSetup.PageControl := FPageControl;
  FTabSetup.Caption     := 'Setup / Runtime';

  LPanelSetupTop              := TPanel.Create(Self);
  LPanelSetupTop.Parent       := FTabSetup;
  LPanelSetupTop.Align        := alTop;
  LPanelSetupTop.Height       := 160;
  LPanelSetupTop.BevelOuter   := bvNone;

  lblRuntimePath              := TLabel.Create(Self);
  lblRuntimePath.Parent       := LPanelSetupTop;
  lblRuntimePath.Left         := 20;
  lblRuntimePath.Top          := 20;
  lblRuntimePath.Caption      := 'Biblioteca Bridge (DLL/SO):';
  lblRuntimePath.Font.Style   := [fsBold];

  edRuntimePath               := TEdit.Create(Self);
  edRuntimePath.Parent        := LPanelSetupTop;
  edRuntimePath.Left          := 20;
  edRuntimePath.Top           := 42;
  edRuntimePath.Width         := 700;

  btnBrowseRuntime            := TButton.Create(Self);
  btnBrowseRuntime.Parent     := LPanelSetupTop;
  btnBrowseRuntime.Left       := 730;
  btnBrowseRuntime.Top        := 39;
  btnBrowseRuntime.Width      := 200;
  btnBrowseRuntime.Height     := 30;
  btnBrowseRuntime.Caption    := 'Procurar DLL/SO...';
  btnBrowseRuntime.OnClick    := @btnBrowseRuntimeClick;

  btnReinit                   := TButton.Create(Self);
  btnReinit.Parent            := LPanelSetupTop;
  btnReinit.Left              := 20;
  btnReinit.Top               := 90;
  btnReinit.Width             := 220;
  btnReinit.Height            := 42;
  btnReinit.Caption           := 'Carregar / Re-inicializar';
  btnReinit.Font.Style        := [fsBold];
  btnReinit.OnClick           := @btnReinitClick;

  { ---- defaults de UI ---- }
  cbModelVariant.ItemIndex  := 1;   { Full }
  chkSkeleton.Checked       := True;
  chkPoints.Checked         := True;
  chkNames.Checked          := False;
  chkRequireReal.Checked    := False;

  lblScore.Caption   := 'Landmarks: N/A';
  lblBackend.Caption := 'Backend: N/A';
  lblStatus.Caption  := 'Estado: Não Iniciado';

  LogMsg('Demo iniciado. Clique em "Setup / Runtime" → "Carregar / Re-inicializar" para carregar a bridge.');
end;

procedure TfrmPoseDemo.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FBmp);
  FreeAndNil(FDetector);
end;

{ ------------------------------------------------------------------ }
{ Carregar imagem                                                     }
{ ------------------------------------------------------------------ }
procedure TfrmPoseDemo.btnLoadImageClick(Sender: TObject);
var
  LInitialDir: string;
  LPicture: TPicture;
begin
  LInitialDir := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'images';
  if DirectoryExists(LInitialDir) then
    OpenDialog1.InitialDir := LInitialDir
  else
    OpenDialog1.InitialDir := ExtractFilePath(ParamStr(0));

  if not OpenDialog1.Execute then
    Exit;

  LogMsg('Carregando: ' + OpenDialog1.FileName);
  LPicture := TPicture.Create;
  try
    try
      LPicture.LoadFromFile(OpenDialog1.FileName);
      FBmp.SetSize(LPicture.Width, LPicture.Height);
      FBmp.Canvas.Draw(0, 0, LPicture.Graphic);
      FDetector.ClearResult;
      lblScore.Caption := 'Landmarks: N/A';
      pbCanvas.Invalidate;
      LogMsg(Format('Imagem carregada: %dx%d', [FBmp.Width, FBmp.Height]));
    except
      on E: Exception do
      begin
        LogMsg('Erro ao carregar imagem: ' + E.Message);
        ShowMessage('Falha ao carregar imagem: ' + E.Message);
      end;
    end;
  finally
    LPicture.Free;
  end;
end;

{ ------------------------------------------------------------------ }
{ Detectar pose                                                       }
{ ------------------------------------------------------------------ }
procedure TfrmPoseDemo.btnDetectClick(Sender: TObject);
var
  TStart, TEnd: TDateTime;
  ElapsedMs: Double;
  Success: Boolean;
  I: Integer;
begin
  { Verificar imagem }
  if FBmp.Width = 0 then
  begin
    ShowMessage('Carregue uma imagem primeiro.');
    Exit;
  end;

  { Verificar / inicializar detector }
  if not FDetector.Initialized then
  begin
    LogMsg('Detector não inicializado — tentando inicializar...');
    if not FDetector.Initialize then
    begin
      LogMsg('Falha na inicialização: ' + FDetector.LastError);
      lblStatus.Caption := 'Estado: Erro na inicialização';
      SyncBackendStatus;
      ShowMessage('Inicialização falhou:' + sLineBreak + FDetector.LastError);
      Exit;
    end;
    LogMsg('Detector inicializado em tempo de execução.');
    LogDetectorSummary;
    lblStatus.Caption := 'Estado: Inicializado';
    SyncBackendStatus;
  end;

  { Validação de backend REAL }
  if chkRequireReal.Checked and not SameText(FDetector.BridgeBackend, 'REAL') then
  begin
    LogMsg('Detecção bloqueada — backend atual: ' + FDetector.BridgeBackend);
    ShowMessage(
      'Esta DLL não reconhece a imagem de verdade.' + sLineBreak +
      'Backend atual: ' + FDetector.BridgeBackend + sLineBreak + sLineBreak +
      'Para obter pontos reais, carregue uma DLL compilada com' + sLineBreak +
      'MP_BRIDGE_BACKEND=REAL e informe o modelo .task.' + sLineBreak + sLineBreak +
      'Desmarque "Exigir backend REAL" para ver pontos simulados (SIM).');
    Exit;
  end;

  { Configurar opções }
  case cbModelVariant.ItemIndex of
    0: FDetector.ModelVariant := hpmLite;
    2: FDetector.ModelVariant := hpmHeavy;
    else FDetector.ModelVariant := hpmFull;
  end;
  FDetector.DrawSkeleton        := chkSkeleton.Checked;
  FDetector.DrawLandmarkPoints  := chkPoints.Checked;
  FDetector.DrawLandmarkNames   := chkNames.Checked;

  FDetector.ClearResult;
  pbCanvas.Invalidate;

  { Detectar }
  LogMsg('Iniciando detecção...');
  TStart  := Now;
  Success := FDetector.DetectBitmap(FBmp);
  TEnd    := Now;
  ElapsedMs := (TEnd - TStart) * 86400000.0;

  LogMsg(Format('Detecção concluída em %.2f ms. Sucesso: %s', [ElapsedMs, BoolToStr(Success, 'True', 'False')]));

  if Success and (FDetector.GetPoseCount > 0) then
  begin
    lblScore.Caption  := Format('Landmarks: %d', [FDetector.LastResultData.Poses[0].LandmarkCount]);
    lblStatus.Caption := 'Estado: Pose Detectada';

    LogMsg('=== PONTOS DETECTADOS ===');
    for I := 0 to 32 do
      LogMsg(Format('  #%2d %-24s  X=%.4f  Y=%.4f  Z=%.4f  Vis=%.2f  Pres=%.2f',
        [I, LANDMARK_NAMES[I],
         FDetector.LastResultData.Poses[0].Landmarks[I].X,
         FDetector.LastResultData.Poses[0].Landmarks[I].Y,
         FDetector.LastResultData.Poses[0].Landmarks[I].Z,
         FDetector.LastResultData.Poses[0].Landmarks[I].Visibility,
         FDetector.LastResultData.Poses[0].Landmarks[I].Presence]));
    LogMsg(Format('Tempo: %.2f ms', [ElapsedMs]));

    if SameText(FDetector.BridgeBackend, 'SIM') then
      LogMsg('ATENÇÃO: backend SIM — pontos simulados, não reconhecimento real.');

    pbCanvas.Invalidate;
  end
  else
  begin
    lblScore.Caption  := 'Landmarks: 0';
    lblStatus.Caption := 'Estado: Nenhuma Pose Detectada';
    if not Success then
      LogMsg('Erro na detecção: ' + FDetector.LastError);
  end;

  SyncBackendStatus;
end;

{ ------------------------------------------------------------------ }
{ Pintura do canvas (imagem + overlay de landmarks)                  }
{ ------------------------------------------------------------------ }
procedure TfrmPoseDemo.pbCanvasPaint(Sender: TObject);
var
  LRect: TRect;
begin
  { Fundo }
  pbCanvas.Canvas.Brush.Color := clBlack;
  pbCanvas.Canvas.FillRect(Rect(0, 0, pbCanvas.Width, pbCanvas.Height));

  if (FBmp = nil) or (FBmp.Width = 0) then
    Exit;

  LRect := GetImageDestRect;

  { 1. Imagem }
  pbCanvas.Canvas.StretchDraw(LRect, FBmp);

  { 2. Landmarks por cima }
  if Assigned(FDetector) and (FDetector.GetPoseCount > 0) then
    FDetector.DrawResult(pbCanvas.Canvas, LRect);
end;

{ ------------------------------------------------------------------ }
{ Rect de destino — proporcional e centralizado dentro do pbCanvas   }
{ ------------------------------------------------------------------ }
function TfrmPoseDemo.GetImageDestRect: TRect;
var
  ImgW, ImgH, BoxW, BoxH: Integer;
  AspImg, AspBox: Double;
  TW, TH, TX, TY: Integer;
begin
  Result := Rect(0, 0, pbCanvas.Width, pbCanvas.Height);
  if (FBmp = nil) or (FBmp.Width = 0) or (FBmp.Height = 0) then
    Exit;

  ImgW := FBmp.Width;
  ImgH := FBmp.Height;
  BoxW := pbCanvas.Width;
  BoxH := pbCanvas.Height;

  AspImg := ImgW / ImgH;
  AspBox := BoxW / BoxH;

  if AspImg > AspBox then
  begin
    TW := BoxW;
    TH := Round(BoxW / AspImg);
  end
  else
  begin
    TH := BoxH;
    TW := Round(BoxH * AspImg);
  end;

  TX := (BoxW - TW) div 2;
  TY := (BoxH - TH) div 2;

  Result := Rect(TX, TY, TX + TW, TY + TH);
end;

{ ------------------------------------------------------------------ }
{ Opções de desenho                                                   }
{ ------------------------------------------------------------------ }
procedure TfrmPoseDemo.chkDrawOptionsChange(Sender: TObject);
begin
  if Assigned(FDetector) then
  begin
    FDetector.DrawSkeleton       := chkSkeleton.Checked;
    FDetector.DrawLandmarkPoints := chkPoints.Checked;
    FDetector.DrawLandmarkNames  := chkNames.Checked;
    pbCanvas.Invalidate;
  end;
end;

{ ------------------------------------------------------------------ }
{ Sincronizar label backend                                           }
{ ------------------------------------------------------------------ }
procedure TfrmPoseDemo.SyncBackendStatus;
begin
  if Assigned(FDetector) and FDetector.Initialized then
    lblBackend.Caption := 'Backend: ' + FDetector.BridgeBackend
  else
    lblBackend.Caption := 'Backend: N/A';
end;

{ ------------------------------------------------------------------ }
{ Resumo do detector no log                                           }
{ ------------------------------------------------------------------ }
procedure TfrmPoseDemo.LogDetectorSummary;
begin
  if not Assigned(FDetector) then Exit;

  LogMsg('--- Bridge carregada ---');
  LogMsg('DLL:      ' + FDetector.LoadedBridgeDLLPath);
  LogMsg('Bridge:   ' + FDetector.BridgeVersionText);
  LogMsg('Backend:  ' + FDetector.BridgeBackend);
  LogMsg('ABI:      ' + IntToStr(FDetector.BridgeAbiVersion));
  LogMsg('Arch:     ' + FDetector.BridgeArchitecture);
  if SameText(FDetector.BridgeBackend, 'SIM') then
    LogMsg('ATENÇÃO: backend SIM — landmarks simulados.')
  else if SameText(FDetector.BridgeBackend, 'REAL') then
    LogMsg('Modelo:   ' + FDetector.LoadedModelFile);
  LogMsg('------------------------');
end;

{ ------------------------------------------------------------------ }
{ Log                                                                 }
{ ------------------------------------------------------------------ }
procedure TfrmPoseDemo.LogMsg(const AMsg: string);
var
  LFormatted: string;
  LFilePath: string;
  LFile: TextFile;
begin
  LFormatted := FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' | ' + AMsg;
  memLog.Lines.Add(LFormatted);

  LFilePath := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0))) + 'detector_execution.log';
  AssignFile(LFile, LFilePath);
  try
    if FileExists(LFilePath) then
      Append(LFile)
    else
      Rewrite(LFile);
    WriteLn(LFile, LFormatted);
    CloseFile(LFile);
  except
    { ignora erros de log em disco }
  end;
end;

{ ------------------------------------------------------------------ }
{ Procurar DLL                                                        }
{ ------------------------------------------------------------------ }
procedure TfrmPoseDemo.btnBrowseRuntimeClick(Sender: TObject);
var
  LDlg: TOpenDialog;
begin
  LDlg := TOpenDialog.Create(Self);
  try
    LDlg.Title := 'Selecionar Biblioteca Pose Bridge (DLL/SO)';
    {$IFDEF MSWINDOWS}
    LDlg.Filter := 'Bibliotecas (*.dll)|*.dll|Todos (*.*)|*.*';
    {$ELSE}
    LDlg.Filter := 'Bibliotecas (*.so)|*.so|Todos (*.*)|*.*';
    {$ENDIF}
    if edRuntimePath.Text <> '' then
      LDlg.InitialDir := ExtractFilePath(edRuntimePath.Text)
    else
      LDlg.InitialDir := ExtractFilePath(ParamStr(0));

    if LDlg.Execute then
    begin
      edRuntimePath.Text := LDlg.FileName;
      LogMsg('Bridge selecionada: ' + LDlg.FileName);
    end;
  finally
    LDlg.Free;
  end;
end;

{ ------------------------------------------------------------------ }
{ Carregar / Re-inicializar                                           }
{ ------------------------------------------------------------------ }
procedure TfrmPoseDemo.btnReinitClick(Sender: TObject);
begin
  FDetector.Active := False;

  if edRuntimePath.Text <> '' then
  begin
    FDetector.LoadMode    := mplmManualPath;
    FDetector.BridgeDLLPath := edRuntimePath.Text;
  end
  else
    FDetector.LoadMode := mplmAuto;

  LogMsg('Re-inicializando detector...');

  if FDetector.Initialize then
  begin
    LogDetectorSummary;
    lblStatus.Caption := 'Estado: Inicializado';
    lblScore.Caption  := 'Landmarks: N/A';
    SyncBackendStatus;
    edRuntimePath.Text := FDetector.LoadedBridgeDLLPath;
    LogMsg('Detector re-inicializado.');
  end
  else
  begin
    LogMsg('Falha: ' + FDetector.LastError);
    lblStatus.Caption := 'Estado: Erro na inicialização';
    SyncBackendStatus;
    ShowMessage('Falha ao inicializar:' + sLineBreak + FDetector.LastError);
  end;
end;

end.
