unit uspeakerdemo;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, ExtCtrls,
  aispeakersignature;

type
  { TfrmSpeakerDemo }
  TfrmSpeakerDemo = class(TForm)
    grpCompare: TGroupBox;
    lblWav1: TLabel;
    edtWav1: TEdit;
    btnBrowseWav1: TButton;
    lblWav2: TLabel;
    edtWav2: TEdit;
    btnBrowseWav2: TButton;
    btnCompare: TButton;
    lblCompareResult: TLabel;

    grpCatalog: TGroupBox;
    lblSpeakerID: TLabel;
    edtSpeakerID: TEdit;
    lblSpeakerName: TLabel;
    edtSpeakerName: TEdit;
    btnRegister: TButton;
    lblCatalogList: TLabel;
    lstCatalog: TListBox;

    grpIdentify: TGroupBox;
    lblWavUnknown: TLabel;
    edtWavUnknown: TEdit;
    btnBrowseUnknown: TButton;
    btnIdentify: TButton;
    lblIdentifyResult: TLabel;
    memLog: TMemo;

    OpenDialog: TOpenDialog;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnBrowseWav1Click(Sender: TObject);
    procedure btnBrowseWav2Click(Sender: TObject);
    procedure btnBrowseUnknownClick(Sender: TObject);
    procedure btnCompareClick(Sender: TObject);
    procedure btnRegisterClick(Sender: TObject);
    procedure btnIdentifyClick(Sender: TObject);
  private
    FIdentifier: TAISpeakerIdentifier;
    FSession: TAISpeakerSession;
    FCatalogPath: string;
    procedure RefreshCatalogView;
    procedure LogMsg(const AMsg: string);
  public
  end;

var
  frmSpeakerDemo: TfrmSpeakerDemo;

implementation

{$R *.lfm}

{ TfrmSpeakerDemo }

procedure TfrmSpeakerDemo.FormCreate(Sender: TObject);
begin
  FCatalogPath := ExtractFilePath(Application.ExeName) + 'speakers_catalog.json';
  FIdentifier := TAISpeakerIdentifier.Create(Self);
  FIdentifier.RegistryFile := FCatalogPath;
  FIdentifier.AutoSave := True;

  FSession := TAISpeakerSession.Create;
  RefreshCatalogView;
  LogMsg('Sistema de Biometria Vocal inicializado. Catalogo: ' + FCatalogPath);
end;

procedure TfrmSpeakerDemo.FormDestroy(Sender: TObject);
begin
  FSession.Free;
end;

procedure TfrmSpeakerDemo.LogMsg(const AMsg: string);
begin
  memLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + ' - ' + AMsg);
end;

procedure TfrmSpeakerDemo.RefreshCatalogView;
var
  I: Integer;
begin
  lstCatalog.Items.Clear;
  for I := 0 to FIdentifier.Registry.Count - 1 do
  begin
    lstCatalog.Items.Add(Format('[%s] %s (Dimensoes: %d, Cadastrado em: %s)',
      [FIdentifier.Registry.Profiles[I].SpeakerID,
       FIdentifier.Registry.Profiles[I].SpeakerName,
       Length(FIdentifier.Registry.Profiles[I].Signature),
       FIdentifier.Registry.Profiles[I].CreatedAt]));
  end;
  if lstCatalog.Items.Count = 0 then
    lstCatalog.Items.Add('(Nenhum locutor cadastrado no catalogo ainda)');
end;

procedure TfrmSpeakerDemo.btnBrowseWav1Click(Sender: TObject);
begin
  if OpenDialog.Execute then
    edtWav1.Text := OpenDialog.FileName;
end;

procedure TfrmSpeakerDemo.btnBrowseWav2Click(Sender: TObject);
begin
  if OpenDialog.Execute then
    edtWav2.Text := OpenDialog.FileName;
end;

procedure TfrmSpeakerDemo.btnBrowseUnknownClick(Sender: TObject);
begin
  if OpenDialog.Execute then
    edtWavUnknown.Text := OpenDialog.FileName;
end;

procedure TfrmSpeakerDemo.btnCompareClick(Sender: TObject);
var
  Sig1, Sig2: TAISpeakerSignature;
  Err: string;
  Score: Double;
  Decision: TAISpeakerDecision;
  StatusText: string;
begin
  if not FileExists(edtWav1.Text) then
  begin
    ShowMessage('Selecione um arquivo WAV 1 valido.');
    Exit;
  end;
  if not FileExists(edtWav2.Text) then
  begin
    ShowMessage('Selecione um arquivo WAV 2 valido.');
    Exit;
  end;

  if not TAISpeakerExtractor.ExtractFromWav(edtWav1.Text, Sig1, Err) then
  begin
    lblCompareResult.Caption := 'Erro WAV 1: ' + Err;
    LogMsg('Erro na extracao WAV 1: ' + Err);
    Exit;
  end;

  if not TAISpeakerExtractor.ExtractFromWav(edtWav2.Text, Sig2, Err) then
  begin
    lblCompareResult.Caption := 'Erro WAV 2: ' + Err;
    LogMsg('Erro na extracao WAV 2: ' + Err);
    Exit;
  end;

  Score := FSession.Similarity(Sig1, Sig2);
  FSession.SetReference(Sig1);
  FSession.Evaluate(Sig2, Decision);

  case Decision of
    sdSame:
      StatusText := Format('MESMO LOCUTOR (Confianca: %0.2f%%)', [Score * 100.0]);
    sdDifferent:
      StatusText := Format('LOCUTORES DIFERENTES (Similaridade: %0.2f%%)', [Score * 100.0]);
    sdInconclusive:
      StatusText := Format('INCONCLUSIVO (Similaridade intermediaria: %0.2f%%)', [Score * 100.0]);
  end;

  lblCompareResult.Caption := 'Resultado: ' + StatusText;
  LogMsg(Format('Comparacao: %s vs %s -> %s', [ExtractFileName(edtWav1.Text), ExtractFileName(edtWav2.Text), StatusText]));
end;

procedure TfrmSpeakerDemo.btnRegisterClick(Sender: TObject);
var
  SpkID, SpkName, WavFile, Err: string;
  Sig: TAISpeakerSignature;
begin
  SpkID := Trim(edtSpeakerID.Text);
  SpkName := Trim(edtSpeakerName.Text);
  WavFile := edtWav1.Text;

  if SpkID = '' then
  begin
    ShowMessage('Informe um ID para o locutor.');
    Exit;
  end;
  if SpkName = '' then
  begin
    ShowMessage('Informe o nome do locutor.');
    Exit;
  end;
  if not FileExists(WavFile) then
  begin
    ShowMessage('Selecione um arquivo WAV 1 valido para extrair a biometria.');
    Exit;
  end;

  if not TAISpeakerExtractor.ExtractFromWav(WavFile, Sig, Err) then
  begin
    ShowMessage('Falha ao extrair assinatura vocal: ' + Err);
    LogMsg('Falha ao extrair: ' + Err);
    Exit;
  end;

  if FIdentifier.Registry.AddOrUpdate(SpkID, SpkName, Sig) then
  begin
    FIdentifier.SaveRegistry;
    RefreshCatalogView;
    ShowMessage(Format('Locutor "%s" (%s) cadastrado e persistido em disco com sucesso!', [SpkName, SpkID]));
    LogMsg(Format('Locutor cadastrado: %s (%s) a partir de %s', [SpkName, SpkID, ExtractFileName(WavFile)]));
  end;
end;

procedure TfrmSpeakerDemo.btnIdentifyClick(Sender: TObject);
var
  WavFile, SpkID, SpkName: string;
  Confidence: Double;
begin
  WavFile := edtWavUnknown.Text;
  if not FileExists(WavFile) then
  begin
    ShowMessage('Selecione um arquivo WAV de audio desconhecido.');
    Exit;
  end;

  if FIdentifier.Registry.Count = 0 then
  begin
    ShowMessage('O catalogo esta vazio. Cadastre pelo menos um locutor primeiro.');
    Exit;
  end;

  if FIdentifier.IdentifyFromWav(WavFile, SpkID, SpkName, Confidence) then
  begin
    lblIdentifyResult.Caption := Format('RECONHECIDO: %s (%s) - %0.1f%%', [SpkName, SpkID, Confidence * 100.0]);
    lblIdentifyResult.Font.Color := clGreen;
    LogMsg(Format('Locutor identificado: %s [%s] com confianca de %0.2f%% no arquivo %s',
      [SpkName, SpkID, Confidence * 100.0, ExtractFileName(WavFile)]));
  end
  else
  begin
    lblIdentifyResult.Caption := Format('REJEITADO: Locutor nao cadastrado na base (Max confianca: %0.1f%%)', [Confidence * 100.0]);
    lblIdentifyResult.Font.Color := clRed;
    LogMsg(Format('Identificacao rejeitada para %s (Score maximo: %0.2f%%, abaixo do limiar)',
      [ExtractFileName(WavFile), Confidence * 100.0]));
  end;
end;

end.