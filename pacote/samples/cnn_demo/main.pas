unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  pythonconnector, cnnclassifier, lazpng;

type

  { TfrmCNNDemo }

  TfrmCNNDemo = class(TForm)
    pnlConfig: TPanel;
    lblDLLPath: TLabel;
    lbDLLs: TListBox;
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
var
  SR: TSearchRec;
  AppDir, Ext: string;
  ArchStr: string;
  I: Integer;
begin
  FPython := TPythonConnector.Create(Self);
  FClassifier := TCNNClassifier.Create(Self);
  
  // Associa os componentes
  FClassifier.PythonConnector := FPython;
  FSelectedImage := '';

  // Detect platform bitness
  {$IFDEF CPU64}
  ArchStr := '64-bit';
  Ext := '.dll';
  {$ELSE}
  ArchStr := '32-bit';
  Ext := '.dll';
  {$ENDIF}

  lblDLLPath.Caption := 'Escolha a DLL do Python (' + ArchStr + '):';

  // Search and populate ListBox
  lbDLLs.Items.Clear;
  AppDir := ExtractFilePath(ParamStr(0));
  
  if FindFirst(AppDir + 'python*' + Ext, faAnyFile, SR) = 0 then
  begin
    repeat
      if (SR.Attr and faDirectory) = 0 then
        lbDLLs.Items.Add(AppDir + SR.Name);
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;

  // Add default candidate paths
  {$IFDEF MSWINDOWS}
  lbDLLs.Items.Add('python3.dll');
  {$IFDEF CPU64}
  lbDLLs.Items.Add('python3_64.dll');
  {$ELSE}
  lbDLLs.Items.Add('python3_32.dll');
  {$ENDIF}
  lbDLLs.Items.Add('python312.dll');
  lbDLLs.Items.Add('python311.dll');
  lbDLLs.Items.Add('python310.dll');
  {$ELSE}
  lbDLLs.Items.Add('libpython3.so');
  lbDLLs.Items.Add('libpython3_64.so');
  lbDLLs.Items.Add('libpython3.12.so');
  lbDLLs.Items.Add('libpython3.11.so');
  {$ENDIF}

  // Deduplicate
  for I := lbDLLs.Items.Count - 1 downto 0 do
  begin
    if lbDLLs.Items.IndexOf(lbDLLs.Items[I]) < I then
      lbDLLs.Items.Delete(I);
  end;

  if lbDLLs.Items.Count > 0 then
    lbDLLs.ItemIndex := 0;
  
  LogMsg('Demonstração de Classificação CNN (MobileNetV2) iniciada. Plataforma: ' + ArchStr);
  LogMsg('1. Verifique se a DLL do Python selecionada na lista está correta.');
  LogMsg('2. Clique em "Ativar Python" para carregar o interpretador.');
  LogMsg('3. Se for a primeira execução, instale as dependências (TensorFlow e Pillow).');
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
var
  SelectedDLL: string;
begin
  if FPython.Active then
  begin
    FPython.Active := False;
    btnInitPython.Caption := 'Ativar Python';
    LogMsg('Interpretador Python desativado.');
  end
  else
  begin
    SelectedDLL := 'python3.dll';
    if lbDLLs.ItemIndex >= 0 then
      SelectedDLL := lbDLLs.Items[lbDLLs.ItemIndex];

    FPython.DLLPath := Trim(SelectedDLL);
    LogMsg('Carregando biblioteca do Python: ' + FPython.DLLPath + '...');
    FPython.Active := True;
    
    if FPython.IsInitialized then
    begin
      btnInitPython.Caption := 'Desativar Python';
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
