unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  pythonconnector, cnnclassifier;

type

  { TfrmCNNDemo }

  TfrmCNNDemo = class(TForm)
    pnlConfig: TPanel;
    lblDLLPath: TLabel;
    edDLLPath: TEdit;
    btnInitPython: TButton;
    btnInstallDeps: TButton;
    
    pnlImageArea: TPanel;
    imgPicture: TImage;
    btnSelectImage: TButton;
    
    pnlResult: TPanel;
    lblResultTitle: TLabel;
    lblLabel: TLabel;
    edLabel: TEdit;
    lblConfidence: TLabel;
    edConfidence: TEdit;
    btnClassify: TButton;
    
    meLogs: TMemo;
    lblLogs: TLabel;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnInitPythonClick(Sender: TObject);
    procedure btnInstallDepsClick(Sender: TObject);
    procedure btnSelectImageClick(Sender: TObject);
    procedure btnClassifyClick(Sender: TObject);
  private
    FPython: TPythonConnector;
    FClassifier: TCNNClassifier;
    FSelectedImage: string;
    procedure LogMsg(const AMsg: string);
  public

  end;

var
  frmCNNDemo: TfrmCNNDemo;

implementation

{$R *.lfm}

{ TfrmCNNDemo }

procedure TfrmCNNDemo.FormCreate(Sender: TObject);
begin
  FPython := TPythonConnector.Create(Self);
  FClassifier := TCNNClassifier.Create(Self);
  
  // Associa os componentes
  FClassifier.PythonConnector := FPython;
  FSelectedImage := '';

  // Configura DLL padrão do Python na pasta do executável ou no sistema
  edDLLPath.Text := 'python3.dll';
  
  LogMsg('Demonstração de Classificação CNN (MobileNetV2) iniciada.');
  LogMsg('1. Verifique se o caminho do interpretador Python (DLL) está correto.');
  LogMsg('2. Clique em "Ativar Interpretador" para carregar a DLL.');
  LogMsg('3. Se for a primeira execução, clique em "Instalar Dependências (TensorFlow/Pillow)".');
  LogMsg('4. Carregue uma imagem e execute a inferência da rede convolucional!');
end;

procedure TfrmCNNDemo.FormDestroy(Sender: TObject);
begin
  // Componentes autoliberados pelo Owner
end;

procedure TfrmCNNDemo.LogMsg(const AMsg: string);
begin
  meLogs.Lines.Append('[' + FormatDateTime('hh:nn:ss', Now) + '] ' + AMsg);
end;

procedure TfrmCNNDemo.btnInitPythonClick(Sender: TObject);
begin
  if FPython.Active then
  begin
    FPython.Active := False;
    btnInitPython.Caption := 'Ativar Interpretador';
    LogMsg('Interpretador Python desativado.');
  end
  else
  begin
    FPython.DLLPath := edDLLPath.Text;
    LogMsg('Carregando biblioteca do Python: ' + FPython.DLLPath + '...');
    FPython.Active := True;
    
    if FPython.IsInitialized then
    begin
      btnInitPython.Caption := 'Desativar Interpretador';
      LogMsg('Interpretador Python ativado com sucesso!');
      LogMsg('Versão: ' + FPython.Version);
    end
    else
    begin
      LogMsg('Erro ao inicializar Python: ' + FPython.LastError);
      ShowMessage('Falha ao carregar DLL do Python. Verifique o caminho e a arquitetura (32/64 bits).');
    end;
  end;
end;

procedure TfrmCNNDemo.btnInstallDepsClick(Sender: TObject);
begin
  if not FPython.IsInitialized then
  begin
    ShowMessage('Por favor, ative o interpretador Python antes de instalar dependências.');
    Exit;
  end;

  LogMsg('Executando instalação silenciosa das dependências (tensorflow, pillow) via pip...');
  LogMsg('Aviso: Este processo pode demorar alguns minutos dependendo da sua conexão...');
  Application.ProcessMessages;

  if FClassifier.InstallDependencies then
  begin
    LogMsg('Dependências (TensorFlow e Pillow) instaladas com sucesso!');
    ShowMessage('Dependências instaladas com sucesso!');
  end
  else
  begin
    LogMsg('Erro ao instalar dependências: ' + FClassifier.LastError);
    ShowMessage('Falha na instalação das dependências. Veja o log para mais detalhes.');
  end;
end;

procedure TfrmCNNDemo.btnSelectImageClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
begin
  OpenDlg := TOpenDialog.Create(nil);
  try
    OpenDlg.Title := 'Selecionar Imagem para Classificar';
    OpenDlg.Filter := 'Imagens (*.jpg;*.jpeg;*.png)|*.jpg;*.jpeg;*.png';
    if OpenDlg.Execute then
    begin
      FSelectedImage := OpenDlg.FileName;
      imgPicture.Picture.LoadFromFile(FSelectedImage);
      LogMsg('Imagem carregada: ' + FSelectedImage);
    end;
  finally
    OpenDlg.Free;
  end;
end;

procedure TfrmCNNDemo.btnClassifyClick(Sender: TObject);
var
  ClassLabel: string;
  Confidence: Double;
begin
  if not FPython.IsInitialized then
  begin
    ShowMessage('Por favor, ative o interpretador Python antes de realizar a inferência.');
    Exit;
  end;

  if FSelectedImage = '' then
  begin
    ShowMessage('Por favor, selecione uma imagem primeiro.');
    Exit;
  end;

  LogMsg('Enviando imagem para inferência na rede convolucional MobileNetV2...');
  LogMsg('Aviso: A primeira classificação pode demorar um pouco para carregar os pesos da rede na memória...');
  Application.ProcessMessages;

  if FClassifier.ClassifyImage(FSelectedImage, ClassLabel, Confidence) then
  begin
    edLabel.Text := ClassLabel;
    edConfidence.Text := Format('%0.2f%%', [Confidence * 100.0]);
    
    LogMsg('Classificação concluída com sucesso!');
    LogMsg('Classe detectada: ' + ClassLabel);
    LogMsg(Format('Confiança: %0.2f%%', [Confidence * 100.0]));
  end
  else
  begin
    LogMsg('Erro no processamento da imagem: ' + FClassifier.LastError);
    ShowMessage('Falha ao classificar imagem. Certifique-se de que as dependências estão corretas.');
  end;
end;

end.
