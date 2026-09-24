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
    chkDebug: TCheckBox;
    edtName: TEdit;
    edtRole: TEdit;
    edtModel: TEdit;
    edtThreshold: TEdit;
    edtMargin: TEdit;
    grpEnrollment: TGroupBox;
    grpRecognition: TGroupBox;
    grpConfig: TGroupBox;
    grpOutput: TGroupBox;
    lblName: TLabel;
    lblRole: TLabel;
    lblRefFile: TLabel;
    lblQueryFile: TLabel;
    lblModel: TLabel;
    lblThreshold: TLabel;
    lblMargin: TLabel;
    lblTotalProfiles: TLabel;
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
  private
    FPyConnector: TPythonConnector;
    FYolo: TYOLO;
    FFaceRec: TAIFaceRecognition;
    procedure Log(const AMsg: string);
    procedure UpdateProfileCounter;
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

  Log('================================================================');
  Log('  SISTEMA DE RECONHECIMENTO FACIAL INICIALIZADO');
  Log('  Reutilizando: TYOLO, TAIFaceRecognition, TAIFaceRegistry');
  Log('================================================================');
  Log('Pronto para cadastro e reconhecimento de identidades.');
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Componentes filhos liberados pelo Owner
end;

procedure TfrmMain.Log(const AMsg: string);
begin
  memLog.Lines.Add(AMsg);
end;

procedure TfrmMain.UpdateProfileCounter;
begin
  lblTotalProfiles.Caption := Format('Perfis Cadastrados no Registry: %d', [FFaceRec.Registry.ProfileCount]);
end;

procedure TfrmMain.btnSelectRefClick(Sender: TObject);
begin
  if OpenPictureDialog1.Execute then
  begin
    lblRefFile.Caption := OpenPictureDialog1.FileName;
    Log('Arquivo de referência selecionado: ' + OpenPictureDialog1.FileName);
  end;
end;

procedure TfrmMain.btnSelectQueryClick(Sender: TObject);
begin
  if OpenPictureDialog1.Execute then
  begin
    lblQueryFile.Caption := OpenPictureDialog1.FileName;
    Log('Arquivo de consulta selecionado: ' + OpenPictureDialog1.FileName);
  end;
end;

procedure TfrmMain.btnRegisterClick(Sender: TObject);
var
  RefFile, ProfName, ProfRole, ProfID, ErrorMsg: string;
  Prof: TAIFaceProfile;
  Sample: TAIFaceSample;
  Objects: TYoloObjectArray;
  DescData: TAIFaceDescriptorData;
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

  // Executa detecção no arquivo de referência para exibir etapas (Task 49)
  if not FYolo.DetectObjects(RefFile, Objects) then
  begin
    Log('[ERRO] Falha no detector YOLO: ' + FYolo.LastError);
    ShowMessage('Falha ao processar imagem: ' + FYolo.LastError);
    Exit;
  end;

  if Length(Objects) = 0 then
  begin
    Log('[ERRO] Nenhuma face encontrada na imagem.');
    ShowMessage('Nenhuma face encontrada na imagem.');
    Exit;
  end;

  if Length(Objects) > 1 then
  begin
    Log('[ERRO] Imagem contém múltiplas pessoas (' + IntToStr(Length(Objects)) + '). Regra 31: deve conter apenas uma.');
    ShowMessage('A imagem de cadastro deve conter somente uma pessoa.');
    Exit;
  end;

  Log(Format('-> [Etapa 1] Face detectada: BBox [%d, %d, %d, %d]',
    [Objects[0].X1, Objects[0].Y1, Objects[0].X2, Objects[0].Y2]));
  Log(Format('-> [Etapa 2] Confiança YOLO: %.4f', [Objects[0].Confidence]));
  Log(Format('-> [Etapa 3] Quantidade de Keypoints/Landmarks: %d', [Length(Objects[0].KeyPoints)]));

  if not FFaceRec.DescriptorBuilder.BuildDescriptor(Objects[0], FYolo.KeyPointMapping, DescData) then
  begin
    Log('[ERRO] Geração do descritor falhou: ' + DescData.ErrorMessage);
    ShowMessage('Falha na validação de qualidade: ' + DescData.ErrorMessage);
    Exit;
  end;

  Log(Format('-> [Etapa 4] Tamanho do Descritor Geométrico: %d valores gerados', [Length(DescData.Values)]));

  // Cadastra no Registry
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
  Sample.DetectionConfidence := Objects[0].Confidence;
  Sample.QualityScore := DescData.Quality;
  Prof.AddSample(Sample);

  Log(Format('[SUCESSO] Perfil "%s" cadastrado com amostra %s.', [Prof.Name, Sample.SampleID]));
  UpdateProfileCounter;
  ShowMessage('Perfil cadastrado com sucesso!');
end;

procedure TfrmMain.btnRecognizeClick(Sender: TObject);
var
  QueryFile: string;
  FS: TFormatSettings;
  Thresh, Marg: Double;
  Results: TFaceMatchResultArray;
  i: Integer;
  StatusStr: string;
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
  Log('INICIANDO RECONHECIMENTO FACIAL (PIPELINE)');
  Log('Arquivo de consulta: ' + QueryFile);
  Log(Format('Parâmetros: MatchThreshold=%.2f | AmbiguityMargin=%.2f', [Thresh, Marg]));

  if not FFaceRec.RecognizeFile(QueryFile, Results) then
  begin
    Log('[ERRO] Falha no processo de reconhecimento: ' + FFaceRec.LastError);
    ShowMessage('Erro: ' + FFaceRec.LastError);
    Exit;
  end;

  Log(Format('Total de faces analisadas na imagem: %d', [Length(Results)]));

  for i := 0 to High(Results) do
  begin
    Log(Format('--- FACE %d ---', [i + 1]));
    Log(Format('  Score de Similaridade: %.4f', [Results[i].Score]));
    Log(Format('  Distância Euclidiana : %.4f', [Results[i].Distance]));
    Log(Format('  Melhor Perfil        : %s (ID: %s)', [Results[i].ProfileName, Results[i].ProfileID]));

    case Results[i].Status of
      fmsMatched: StatusStr := 'MATCH (Reconhecido com Sucesso)';
      fmsUnknown: StatusStr := 'UNKNOWN (Não reconhecido / Abaixo do Threshold)';
      fmsAmbiguous: StatusStr := 'AMBIGUOUS (Ambiguidade entre perfis)';
      fmsError: StatusStr := 'ERROR: ' + Results[i].ErrorMessage;
      else StatusStr := 'DESCONHECIDO';
    end;

    Log('  >>> RESULTADO FINAL  : ' + StatusStr);
  end;
  Log('================================================================');
end;

end.
