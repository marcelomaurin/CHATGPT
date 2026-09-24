unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  pythonconnector, yolodetect, aifaceprofile, aifacedescriptor, aifacematcher,
  aifacejson, aifaceregistry, aifacerecognition;

type
  { TfrmMain }
  TfrmMain = class(TForm)
    btnSelectRef: TButton;
    btnRegister: TButton;
    btnSelectQuery: TButton;
    btnRecognize: TButton;
    btnSimulateTracking: TButton;
    chkDebug: TCheckBox;
    chkEnableTracking: TCheckBox;
    edtName: TEdit;
    edtRole: TEdit;
    edtModel: TEdit;
    edtThreshold: TEdit;
    edtMargin: TEdit;
    grpEnrollment: TGroupBox;
    grpRecognition: TGroupBox;
    grpConfig: TGroupBox;
    grpTracking: TGroupBox;
    grpPreview: TGroupBox;
    grpOutput: TGroupBox;
    imgPreview: TImage;
    lblName: TLabel;
    lblRole: TLabel;
    lblRefFile: TLabel;
    lblQueryFile: TLabel;
    lblModel: TLabel;
    lblThreshold: TLabel;
    lblMargin: TLabel;
    lblTotalProfiles: TLabel;
    lblTrackingStats: TLabel;
    memLog: TMemo;
    OpenPictureDialog1: TOpenDialog;
    pnlLeft: TPanel;
    pnlRight: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnSelectRefClick(Sender: TObject);
    procedure btnRegisterClick(Sender: TObject);
    procedure btnSelectQueryClick(Sender: TObject);
    procedure btnRecognizeClick(Sender: TObject);
    procedure btnSimulateTrackingClick(Sender: TObject);
  private
    FPyConnector: TPythonConnector;
    FYolo: TYOLO;
    FFaceRec: TAIFaceRecognition;
    procedure Log(const AMsg: string);
    procedure UpdateProfileCounter;
    procedure ShowImageWithOverlay(const AFileName: string; const AObjects: TYoloObjectArray);
  public
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FPyConnector := TPythonConnector.Create(Self);
  FPyConnector.ExecutionMode := pemProcess;

  FYolo := TYOLO.Create(Self);
  FYolo.PythonConnector := FPyConnector;
  FYolo.ModelPath := edtModel.Text;

  FFaceRec := TAIFaceRecognition.Create(Self);
  FFaceRec.Yolo := FYolo;
  FFaceRec.DetectorMode := frmYOLO;
  FFaceRec.EnableTracking := True;

  Log('================================================================');
  Log('  SISTEMA DE RECONHECIMENTO FACIAL E IDENTIDADE (V2)');
  Log('  Componentes: TYOLO, TAIFaceRecognition, TAIFaceRegistry, TAIFaceTracker');
  Log('================================================================');
  Log('Pronto para cadastro, calibração e reconhecimento de identidades.');
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Componentes liberados pelo Owner
end;

procedure TfrmMain.Log(const AMsg: string);
begin
  memLog.Lines.Add(AMsg);
end;

procedure TfrmMain.UpdateProfileCounter;
begin
  lblTotalProfiles.Caption := Format('Perfis Cadastrados no Registry: %d', [FFaceRec.Registry.ProfileCount]);
end;

procedure TfrmMain.ShowImageWithOverlay(const AFileName: string; const AObjects: TYoloObjectArray);
var
  Pic: TPicture;
  Bmp: TBitmap;
  i, j: Integer;
begin
  if not FileExists(AFileName) then Exit;
  Pic := TPicture.Create;
  Bmp := TBitmap.Create;
  try
    Pic.LoadFromFile(AFileName);
    Bmp.SetSize(Pic.Width, Pic.Height);
    Bmp.Canvas.Draw(0, 0, Pic.Graphic);

    for i := 0 to High(AObjects) do
    begin
      Bmp.Canvas.Brush.Style := bsClear;
      Bmp.Canvas.Pen.Color := clLime;
      Bmp.Canvas.Pen.Width := 3;
      Bmp.Canvas.Rectangle(AObjects[i].X1, AObjects[i].Y1, AObjects[i].X2, AObjects[i].Y2);

      Bmp.Canvas.Brush.Style := bsSolid;
      for j := 0 to High(AObjects[i].KeyPoints) do
      begin
        Bmp.Canvas.Pen.Color := clRed;
        Bmp.Canvas.Brush.Color := clYellow;
        Bmp.Canvas.Ellipse(Round(AObjects[i].KeyPoints[j].X) - 4,
                           Round(AObjects[i].KeyPoints[j].Y) - 4,
                           Round(AObjects[i].KeyPoints[j].X) + 4,
                           Round(AObjects[i].KeyPoints[j].Y) + 4);
      end;
    end;

    imgPreview.Picture.Assign(Bmp);
  finally
    Bmp.Free;
    Pic.Free;
  end;
end;

procedure TfrmMain.btnSelectRefClick(Sender: TObject);
begin
  if OpenPictureDialog1.Execute then
  begin
    lblRefFile.Caption := OpenPictureDialog1.FileName;
    Log('Arquivo de referência selecionado: ' + OpenPictureDialog1.FileName);
    imgPreview.Picture.LoadFromFile(OpenPictureDialog1.FileName);
  end;
end;

procedure TfrmMain.btnSelectQueryClick(Sender: TObject);
begin
  if OpenPictureDialog1.Execute then
  begin
    lblQueryFile.Caption := OpenPictureDialog1.FileName;
    Log('Arquivo de consulta selecionado: ' + OpenPictureDialog1.FileName);
    imgPreview.Picture.LoadFromFile(OpenPictureDialog1.FileName);
  end;
end;

procedure TfrmMain.btnRegisterClick(Sender: TObject);
var
  RefFile, ProfName, ProfRole, ProfID: string;
  Prof: TAIFaceProfile;
  Sample: TAIFaceSample;
  Objects, FaceObjects: TYoloObjectArray;
  DescData: TAIFaceDescriptorData;
  i: Integer;
begin
  RefFile := lblRefFile.Caption;
  if not FileExists(RefFile) then
  begin
    ShowMessage('Por favor, selecione um arquivo de imagem válido primeiro.');
    Exit;
  end;

  ProfName := Trim(edtName.Text);
  if ProfName = '' then
  begin
    ShowMessage('Informe um nome para o perfil.');
    Exit;
  end;
  ProfRole := Trim(edtRole.Text);
  ProfID := SanitizeProfileID(ProfName);

  FYolo.ModelPath := Trim(edtModel.Text);
  Log('');
  Log('----------------------------------------------------------------');
  Log('INICIANDO CADASTRO DE AMOSTRA PARA IDENTIDADE');
  Log(Format('Nome: %s | Cargo: %s | ID Seguro: %s', [ProfName, ProfRole, ProfID]));
  Log('Arquivo: ' + RefFile);

  if not FYolo.DetectObjects(RefFile, Objects) then
  begin
    Log('[ERRO] Falha no detector YOLO: ' + FYolo.LastError);
    ShowMessage('Falha ao processar imagem: ' + FYolo.LastError);
    Exit;
  end;

  // Filtra apenas classes faciais usando a regra centralizada IsYoloFaceObject
  SetLength(FaceObjects, 0);
  for i := 0 to High(Objects) do
  begin
    if IsYoloFaceObject(Objects[i], FFaceRec.FaceClasses) then
    begin
      SetLength(FaceObjects, Length(FaceObjects) + 1);
      FaceObjects[High(FaceObjects)] := Objects[i];
    end;
  end;

  if Length(FaceObjects) = 0 then
  begin
    Log('[ERRO] Nenhuma face encontrada na imagem (objetos não faciais descartados).');
    ShowMessage('Nenhuma face encontrada na imagem.');
    Exit;
  end;

  if Length(FaceObjects) > 1 then
  begin
    Log(Format('[ERRO] Imagem contém múltiplas faces (%d). Exigido apenas uma para cadastro.', [Length(FaceObjects)]));
    ShowMessage('A imagem de cadastro deve conter somente uma pessoa.');
    Exit;
  end;

  // Atualiza preview com bounding box e landmarks da face encontrada
  ShowImageWithOverlay(RefFile, FaceObjects);

  Log(Format('-> [Detecção] BBox [%d, %d, %d, %d] | Confiança: %.4f',
    [FaceObjects[0].X1, FaceObjects[0].Y1, FaceObjects[0].X2, FaceObjects[0].Y2, FaceObjects[0].Confidence]));
  Log(Format('-> [Landmarks] %d keypoints disponíveis', [Length(FaceObjects[0].KeyPoints)]));

  if not FFaceRec.DescriptorBuilder.BuildDescriptor(FaceObjects[0], FYolo.KeyPointMapping, DescData) then
  begin
    Log('[ERRO] Validação de qualidade/landmarks falhou: ' + DescData.ErrorMessage);
    ShowMessage('Falha na validação de qualidade: ' + DescData.ErrorMessage);
    Exit;
  end;

  // Validação de qualidade de cadastro (Task 12)
  if DescData.Quality < FFaceRec.DescriptorBuilder.EnrollmentQualityThreshold then
  begin
    Log(Format('[ERRO] Qualidade insuficiente para cadastro: %.2f < %.2f',
      [DescData.Quality, FFaceRec.DescriptorBuilder.EnrollmentQualityThreshold]));
    ShowMessage('A face foi detectada, mas a qualidade é insuficiente para cadastro.');
    Exit;
  end;

  Log(Format('-> [Qualidade] Face: %.2f | Landmarks: %.2f | Geral: %.2f',
    [DescData.FaceConfidence, DescData.LandmarkConfidence, DescData.Quality]));

  // Adiciona ao Registry
  Prof := FFaceRec.Registry.FindByID(ProfID);
  if Prof = nil then
  begin
    Prof := TAIFaceProfile.Create;
    Prof.ID := ProfID;
    Prof.Name := ProfName;
    Prof.Role := ProfRole;
    Prof.AddImage(RefFile);
    FFaceRec.Registry.AddProfile(Prof);
  end;

  Sample := TAIFaceSample.Create;
  Sample.SampleID := Format('%s_s%d', [Prof.ID, Prof.SampleCount + 1]);
  Sample.ImageFile := RefFile;
  Sample.DescriptorVersion := DescData.Version;
  Sample.Algorithm := DescData.Algorithm;
  Sample.Vector := DescData.Values;
  Sample.DetectionConfidence := FaceObjects[0].Confidence;
  Sample.QualityScore := DescData.Quality;
  Prof.AddSample(Sample);

  Log(Format('[SUCESSO] Perfil "%s" cadastrado com sucesso!', [Prof.Name]));
  UpdateProfileCounter;
  ShowMessage('Perfil cadastrado com sucesso!');
end;

procedure TfrmMain.btnRecognizeClick(Sender: TObject);
var
  QueryFile: string;
  FS: TFormatSettings;
  Thresh, Marg: Double;
  Results: TFaceMatchResultArray;
  Objects, FaceObjects: TYoloObjectArray;
  i: Integer;
  ResStr: string;
  Diff: Double;
begin
  QueryFile := lblQueryFile.Caption;
  if not FileExists(QueryFile) then
  begin
    ShowMessage('Por favor, selecione um arquivo de imagem de consulta.');
    Exit;
  end;

  if FFaceRec.Registry.ProfileCount = 0 then
  begin
    ShowMessage('Nenhum perfil cadastrado no Registry. Cadastre pelo menos um antes de reconhecer.');
    Exit;
  end;

  FS := DefaultFormatSettings;
  FS.DecimalSeparator := '.';
  Thresh := StrToFloatDef(edtThreshold.Text, 0.82, FS);
  Marg := StrToFloatDef(edtMargin.Text, 0.05, FS);

  FFaceRec.Matcher.MatchThreshold := Thresh;
  FFaceRec.Matcher.AmbiguityMargin := Marg;
  FFaceRec.DebugLogging := chkDebug.Checked;
  FYolo.ModelPath := Trim(edtModel.Text);

  Log('');
  Log('================================================================');
  Log('INICIANDO RECONHECIMENTO FACIAL (CALIBRAÇÃO E DIAGNÓSTICO)');
  Log('Arquivo de consulta: ' + QueryFile);
  Log(Format('Threshold configurado: %.2f | Margem de ambiguidade: %.2f', [Thresh, Marg]));

  if not FFaceRec.RecognizeFile(QueryFile, Results) then
  begin
    Log('[ERRO] Falha no processo de reconhecimento: ' + FFaceRec.LastError);
    ShowMessage('Erro: ' + FFaceRec.LastError);
    Exit;
  end;

  // Obtém detecções para overlay
  if FYolo.DetectObjects(QueryFile, Objects) then
  begin
    SetLength(FaceObjects, 0);
    for i := 0 to High(Objects) do
    begin
      if IsYoloFaceObject(Objects[i], FFaceRec.FaceClasses) then
      begin
        SetLength(FaceObjects, Length(FaceObjects) + 1);
        FaceObjects[High(FaceObjects)] := Objects[i];
      end;
    end;
    ShowImageWithOverlay(QueryFile, FaceObjects);
  end;

  if Length(Results) = 0 then
  begin
    Log('Nenhuma face detectada na imagem.');
    Exit;
  end;

  for i := 0 to High(Results) do
  begin
    Log(Format('--- CANDIDATO PARA FACE %d ---', [i + 1]));

    case Results[i].Status of
      fmsMatched: ResStr := 'MATCHED';
      fmsUnknown: ResStr := 'UNKNOWN';
      fmsAmbiguous: ResStr := 'AMBIGUOUS';
      fmsError: ResStr := 'ERROR';
      else ResStr := 'NONE';
    end;

    // Formatação conforme requisitos de calibração (Tarefas 44 e 45)
    Log(Format('Melhor: %s %.2f', [Results[i].ProfileName, Results[i].Score]));
    if Results[i].SecondProfileName <> '' then
    begin
      Diff := Results[i].Score - Results[i].SecondScore;
      Log(Format('Segundo: %s %.2f', [Results[i].SecondProfileName, Results[i].SecondScore]));
      Log(Format('diferença: %.2f', [Diff]));
    end
    else
    begin
      Log('Segundo: (nenhum outro perfil avaliado)');
    end;

    Log(Format('threshold: %.2f', [Thresh]));
    Log(Format('resultado: %s', [ResStr]));
  end;
  Log('================================================================');
end;

procedure TfrmMain.btnSimulateTrackingClick(Sender: TObject);
var
  Bmp: TBitmap;
  Results: TFaceMatchResultArray;
  FrameIdx: Integer;
begin
  Log('');
  Log('--- SIMULAÇÃO DE VÍDEO CONTÍNUO COM TRACKING TEMPORAL ---');
  FFaceRec.EnableTracking := chkEnableTracking.Checked;
  FFaceRec.YoloRefreshIntervalMs := 1000;

  Bmp := TBitmap.Create;
  try
    Bmp.SetSize(320, 240);
    Bmp.Canvas.Brush.Color := clBlack;
    Bmp.Canvas.FillRect(0, 0, 320, 240);

    // Simula 10 frames contínuos
    for FrameIdx := 1 to 10 do
    begin
      FFaceRec.ProcessFrame(Bmp, Results);
      Sleep(50);
    end;

    Log(Format('inferências YOLO: %d', [FFaceRec.YoloInferenceCount]));
    Log(Format('frames rastreados: %d', [FFaceRec.TrackedFrameCount]));
    lblTrackingStats.Caption := Format('YOLO: %d | Rastreamento: %d',
      [FFaceRec.YoloInferenceCount, FFaceRec.TrackedFrameCount]);
    Log('Simulação concluída com sucesso.');
  finally
    Bmp.Free;
  end;
end;

end.
