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
    lblSelectCat: TLabel;
    btnSelectImage: TButton;

    pnlResult: TPanel;
    lblResultTitle: TLabel;
    lblLabel: TLabel;
    edLabel: TEdit;
    lblConfidence: TLabel;
    edConfidence: TEdit;
    btnClassify: TButton;
    btnStop: TButton;

    meLogs: TMemo;
    lblLogs: TLabel;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnInitPythonClick(Sender: TObject);
    procedure btnInstallDepsClick(Sender: TObject);
    procedure btnSelectImageClick(Sender: TObject);
    procedure btnClassifyClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
  private
    FPython: TPythonConnector;
    FClassifier: TCNNClassifier;
    FSelectedImage: string;

    FClassifyThread: TThread;
    FProgressTimer: TTimer;
    FClassifyStartTime: TDateTime;
    FProgressCounter: Integer;
    FClassifyRunning: Boolean;
    FStopRequested: Boolean;

    procedure LogMsg(const AMsg: string);
    procedure LogStep(APercent: Integer; const AMsg: string);
    procedure ProgressTimerTimer(Sender: TObject);
    procedure SetClassifyUIBusy(ABusy: Boolean);
    function ElapsedSeconds: Integer;
  public
    procedure ClassifyFinished(
      ASuccess: Boolean;
      const AClassLabel: string;
      AConfidence: Double;
      const AError: string
    );

    procedure ThreadLog(const AMsg: string);
  end;

  { TCNNClassifyThread }

  TCNNClassifyThread = class(TThread)
  private
    FForm: TfrmCNNDemo;
    FClassifier: TCNNClassifier;
    FImageFile: string;

    FClassLabel: string;
    FConfidence: Double;
    FSuccess: Boolean;
    FError: string;
    FLogMessage: string;

    procedure SyncUpdateUI;
    procedure SyncLog;
    procedure DoLog(const AMsg: string);
  protected
    procedure Execute; override;
  public
    constructor Create(
      AForm: TfrmCNNDemo;
      AClassifier: TCNNClassifier;
      const AImageFile: string
    );
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
  // Force linking of PNG and JPEG classes so they register with TPicture
  TPortableNetworkGraphic.Create.Free;
  TJPEGImage.Create.Free;

  FPython := TPythonConnector.Create(Self);
  FClassifier := TCNNClassifier.Create(Self);

  // Para CNN/TensorFlow, usar processo externo.
  // Evita travar a aplicação ou derrubar o Lazarus caso alguma DLL nativa falhe.
  //FPython.ExecutionMode := pemProcess;

  FClassifier.PythonConnector := FPython;

  FSelectedImage := '';
  FClassifyThread := nil;
  FClassifyRunning := False;
  FStopRequested := False;
  FProgressCounter := 0;

  FProgressTimer := TTimer.Create(Self);
  FProgressTimer.Enabled := False;
  FProgressTimer.Interval := 3000;
  FProgressTimer.OnTimer := @ProgressTimerTimer;

  {$IFDEF CPU64}
  ArchStr := '64-bit';
  {$ELSE}
  ArchStr := '32-bit';
  {$ENDIF}

  {$IFDEF MSWINDOWS}
  Ext := '.dll';
  {$ELSE}
  Ext := '.so';
  {$ENDIF}

  lblDLLPath.Caption := 'Escolha a biblioteca/executável do Python (' + ArchStr + '):';

  lbDLLs.Items.Clear;
  AppDir := ExtractFilePath(ParamStr(0));

  {$IFDEF MSWINDOWS}
  if FindFirst(AppDir + 'python*' + Ext, faAnyFile, SR) = 0 then
  begin
    repeat
      if (SR.Attr and faDirectory) = 0 then
        lbDLLs.Items.Add(AppDir + SR.Name);
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;

  // Em modo processo, preferir executável Python.
  lbDLLs.Items.Add('python.exe');
  lbDLLs.Items.Add('python3.exe');

  // Candidatos DLL mantidos para testes em pemDLL.
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
  if FindFirst(AppDir + 'libpython*' + Ext, faAnyFile, SR) = 0 then
  begin
    repeat
      if (SR.Attr and faDirectory) = 0 then
        lbDLLs.Items.Add(AppDir + SR.Name);
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;

  // Em modo processo, preferir python3.
  lbDLLs.Items.Add('python3');
  lbDLLs.Items.Add('/usr/bin/python3');
  lbDLLs.Items.Add('/usr/local/bin/python3');

  // Candidatos SO mantidos para testes em pemDLL.
  lbDLLs.Items.Add('libpython3.so');

  {$IFDEF CPU64}
  lbDLLs.Items.Add('/usr/lib/x86_64-linux-gnu/libpython3.12.so');
  lbDLLs.Items.Add('/usr/lib/x86_64-linux-gnu/libpython3.11.so');
  lbDLLs.Items.Add('/usr/lib/x86_64-linux-gnu/libpython3.10.so');
  {$ELSE}
  lbDLLs.Items.Add('/usr/lib/i386-linux-gnu/libpython3.12.so');
  lbDLLs.Items.Add('/usr/lib/i386-linux-gnu/libpython3.11.so');
  lbDLLs.Items.Add('/usr/lib/i386-linux-gnu/libpython3.10.so');
  {$ENDIF}

  lbDLLs.Items.Add('/usr/local/lib/libpython3.12.so');
  lbDLLs.Items.Add('/usr/local/lib/libpython3.11.so');
  {$ENDIF}

  // Deduplicate
  for I := lbDLLs.Items.Count - 1 downto 0 do
  begin
    if lbDLLs.Items.IndexOf(lbDLLs.Items[I]) < I then
      lbDLLs.Items.Delete(I);
  end;

  if lbDLLs.Items.Count > 0 then
    lbDLLs.ItemIndex := 0;

  lblSelectCat.Caption := 'Selecione uma imagem no diretório:';
  edLabel.Text := '';
  edConfidence.Text := '';

  if Assigned(btnStop) then
  begin
    btnStop.Enabled := False;
    btnStop.Caption := 'Stop';
  end;

  LogMsg('Demonstração de Classificação CNN (MobileNetV2) iniciada.');
  LogMsg('Plataforma: ' + ArchStr);
  LogMsg('Modo recomendado para CNN: Python em processo externo.');
  LogMsg('1. Selecione python.exe/python3 ou uma biblioteca compatível.');
  LogMsg('2. Clique em "Ativar Python".');
  LogMsg('3. Se for a primeira execução, instale TensorFlow e Pillow.');
  LogMsg('4. Selecione uma imagem.');
  LogMsg('5. Clique em classificar e acompanhe a evolução no log.');
end;

procedure TfrmCNNDemo.FormDestroy(Sender: TObject);
begin
  if Assigned(FProgressTimer) then
    FProgressTimer.Enabled := False;

  if Assigned(FClassifyThread) then
  begin
    FClassifyThread.Terminate;
    FClassifyThread := nil;
  end;

  if Assigned(FPython) and FPython.Active then
    FPython.StopExecution;
end;

procedure TfrmCNNDemo.LogMsg(const AMsg: string);
begin
  meLogs.Lines.Append('[' + FormatDateTime('hh:nn:ss', Now) + '] ' + AMsg);
  meLogs.SelStart := Length(meLogs.Text);
end;

procedure TfrmCNNDemo.LogStep(APercent: Integer; const AMsg: string);
begin
  LogMsg(Format('[%3d%%] %s', [APercent, AMsg]));
end;

function TfrmCNNDemo.ElapsedSeconds: Integer;
begin
  Result := Round((Now - FClassifyStartTime) * 24 * 60 * 60);
end;

procedure TfrmCNNDemo.ProgressTimerTimer(Sender: TObject);
var
  Dots: string;
begin
  if not FClassifyRunning then
    Exit;

  Inc(FProgressCounter);
  Dots := StringOfChar('.', (FProgressCounter mod 4) + 1);

  case FProgressCounter of
    1:
      LogStep(35, 'Carregando TensorFlow/MobileNetV2' + Dots);
    2:
      LogStep(45, 'Preparando pesos do modelo e inicializando backend' + Dots);
    3:
      LogStep(55, 'Executando pré-processamento da imagem' + Dots);
    4:
      LogStep(65, 'Executando predição no modelo neural' + Dots);
    5:
      LogStep(75, 'Decodificando resultado da rede' + Dots);
  else
    LogStep(80, Format('Ainda processando. Tempo decorrido: %d segundos %s',
      [ElapsedSeconds, Dots]));
  end;
end;

procedure TfrmCNNDemo.SetClassifyUIBusy(ABusy: Boolean);
begin
  if Assigned(btnClassify) then
    btnClassify.Enabled := not ABusy;

  if Assigned(btnSelectImage) then
    btnSelectImage.Enabled := not ABusy;

  if Assigned(btnInitPython) then
    btnInitPython.Enabled := not ABusy;

  if Assigned(btnInstallDeps) then
    btnInstallDeps.Enabled := not ABusy;

  if Assigned(btnStop) then
    btnStop.Enabled := ABusy;

  if Assigned(btnClassify) then
  begin
    if ABusy then
      btnClassify.Caption := 'Classificando...'
    else
      btnClassify.Caption := 'Classificar Imagem';
  end;

  if Assigned(btnStop) and not ABusy then
    btnStop.Caption := 'Stop';
end;

procedure TfrmCNNDemo.btnInitPythonClick(Sender: TObject);
var
  SelectedPath: string;
  Ext: string;
begin
  if FPython.Active then
  begin
    if FClassifyRunning then
    begin
      ShowMessage('Existe uma classificação em andamento. Use Stop antes de desativar o Python.');
      Exit;
    end;

    FPython.Active := False;
    btnInitPython.Caption := 'Ativar Python';
    LogMsg('Interpretador Python desativado.');
    Exit;
  end;

  {$IFDEF MSWINDOWS}
  SelectedPath := 'python.exe';
  {$ELSE}
  SelectedPath := 'python3';
  {$ENDIF}

  if lbDLLs.ItemIndex >= 0 then
    SelectedPath := Trim(lbDLLs.Items[lbDLLs.ItemIndex]);

  Ext := LowerCase(ExtractFileExt(SelectedPath));

  FPython.DLLPath := SelectedPath;

  // Decide automaticamente o modo correto.
  if (Ext = '.dll') or (Ext = '.so') or (Ext = '.dylib') then
  begin
    FPython.ExecutionMode := pemDLL;
    LogStep(0, 'Iniciando Python em modo DLL/SO.');
    LogMsg('Biblioteca selecionada: ' + FPython.DLLPath);
  end
  else
  begin
    FPython.ExecutionMode := pemProcess;
    LogStep(0, 'Iniciando Python em modo processo.');
    LogMsg('Executável selecionado: ' + FPython.DLLPath);
  end;

  FPython.Active := True;

  if FPython.IsInitialized then
  begin
    btnInitPython.Caption := 'Desativar Python';
    LogStep(100, 'Interpretador Python ativado com sucesso.');
    LogMsg('Versão: ' + FPython.Version);
  end
  else
  begin
    LogMsg('Erro ao inicializar Python: ' + FPython.LastError);
    ShowMessage(
      'Falha ao iniciar Python.' + sLineBreak + sLineBreak +
      'Detalhes:' + sLineBreak +
      FPython.LastError
    );
  end;
end;



procedure TfrmCNNDemo.btnInstallDepsClick(Sender: TObject);
begin
  if not FPython.IsInitialized then
  begin
    ShowMessage('Por favor, ative o interpretador Python antes de instalar dependências.');
    Exit;
  end;

  LogStep(0, 'Iniciando instalação de dependências.');
  LogMsg('Pacotes: tensorflow, pillow');
  LogMsg('Aviso: este processo pode demorar alguns minutos e depende da internet.');
  Application.ProcessMessages;

  if FClassifier.InstallDependencies then
  begin
    LogStep(100, 'Dependências instaladas com sucesso.');
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
  if FClassifyRunning then
  begin
    ShowMessage('Aguarde finalizar ou clique em Stop antes de trocar a imagem.');
    Exit;
  end;

  OpenDlg := TOpenDialog.Create(nil);
  try
    OpenDlg.Title := 'Selecionar Imagem para Classificar';
    OpenDlg.Filter := 'Imagens (*.jpg;*.jpeg;*.png;*.bmp)|*.jpg;*.jpeg;*.png;*.bmp';
    OpenDlg.InitialDir := ExtractFilePath(ParamStr(0));

    if OpenDlg.Execute then
    begin
      FSelectedImage := OpenDlg.FileName;

      try
        imgPicture.Picture.LoadFromFile(FSelectedImage);
        edLabel.Text := '';
        edConfidence.Text := '';

        LogStep(0, 'Imagem selecionada.');
        LogMsg('Arquivo: ' + FSelectedImage);
        LogMsg('Extensão: ' + ExtractFileExt(FSelectedImage));
      except
        on E: Exception do
        begin
          FSelectedImage := '';
          LogMsg('Erro ao carregar imagem: ' + E.Message);
          ShowMessage('Não foi possível carregar a imagem selecionada.');
        end;
      end;
    end;
  finally
    OpenDlg.Free;
  end;
end;

procedure TfrmCNNDemo.btnClassifyClick(Sender: TObject);
var
  ClassifyThread: TCNNClassifyThread;
begin
  if FClassifyRunning then
  begin
    ShowMessage('Já existe uma classificação em andamento.');
    Exit;
  end;

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

  if not FileExists(FSelectedImage) then
  begin
    ShowMessage('A imagem selecionada não foi encontrada.');
    LogMsg('Erro: imagem selecionada não encontrada: ' + FSelectedImage);
    Exit;
  end;

  SetClassifyUIBusy(True);

  FStopRequested := False;
  FClassifyRunning := True;
  FClassifyStartTime := Now;
  FProgressCounter := 0;
  FProgressTimer.Enabled := True;

  edLabel.Text := 'Processando...';
  edConfidence.Text := '';

  LogStep(0, 'Iniciando classificação assíncrona.');
  LogStep(5, 'Validando imagem e interpretador Python.');
  LogMsg('Imagem enviada: ' + FSelectedImage);
  LogStep(10, 'Criando thread de classificação.');
  LogStep(20, 'Enviando imagem para o classificador CNN.');
  LogStep(30, 'Aguardando carregamento/processamento do modelo.');

  ClassifyThread := TCNNClassifyThread.Create(Self, FClassifier, FSelectedImage);
  FClassifyThread := ClassifyThread;
  ClassifyThread.Start;
end;

procedure TfrmCNNDemo.btnStopClick(Sender: TObject);
begin
  if not FClassifyRunning then
    Exit;

  FStopRequested := True;

  LogStep(0, 'Solicitada parada da classificação pelo usuário.');
  LogMsg('Encerrando execução Python em andamento...');

  if Assigned(btnStop) then
  begin
    btnStop.Enabled := False;
    btnStop.Caption := 'Parando...';
  end;

  if Assigned(FClassifyThread) then
    FClassifyThread.Terminate;

  if Assigned(FPython) then
    FPython.StopExecution;

  FClassifyRunning := False;

  if Assigned(FProgressTimer) then
    FProgressTimer.Enabled := False;

  edLabel.Text := '';
  edConfidence.Text := '';

  LogMsg('Execução interrompida.');
  LogMsg('O processo Python foi finalizado.');
  LogMsg('Será necessário ativar o Python novamente antes de nova classificação.');

  FClassifyThread := nil;

  SetClassifyUIBusy(False);
  btnInitPython.Caption := 'Ativar Python';
end;

procedure TfrmCNNDemo.ClassifyFinished(
  ASuccess: Boolean;
  const AClassLabel: string;
  AConfidence: Double;
  const AError: string
);
var
  TotalSec: Integer;
begin
  if FStopRequested then
  begin
    FClassifyThread := nil;
    FClassifyRunning := False;
    FProgressTimer.Enabled := False;
    SetClassifyUIBusy(False);
    Exit;
  end;

  FClassifyThread := nil;
  FProgressTimer.Enabled := False;
  FClassifyRunning := False;

  TotalSec := ElapsedSeconds;

  if ASuccess then
  begin
    edLabel.Text := AClassLabel;
    edConfidence.Text := Format('%0.2f%%', [AConfidence * 100.0]);

    LogStep(90, 'Resultado recebido do modelo.');
    LogStep(100, 'Classificação concluída com sucesso.');
    LogMsg('Classe detectada: ' + AClassLabel);
    LogMsg(Format('Confiança: %0.2f%%', [AConfidence * 100.0]));
    LogMsg(Format('Tempo total: %d segundos.', [TotalSec]));
  end
  else
  begin
    edLabel.Text := '';
    edConfidence.Text := '';

    LogMsg('Erro no processamento da imagem: ' + AError);
    LogMsg(Format('Tempo até o erro: %d segundos.', [TotalSec]));

    ShowMessage('Falha ao classificar imagem.' + sLineBreak + sLineBreak +
      'Detalhes:' + sLineBreak + AError);
  end;

  SetClassifyUIBusy(False);
end;

procedure TfrmCNNDemo.ThreadLog(const AMsg: string);
begin
  LogMsg(AMsg);
end;

{ TCNNClassifyThread }

constructor TCNNClassifyThread.Create(
  AForm: TfrmCNNDemo;
  AClassifier: TCNNClassifier;
  const AImageFile: string
);
begin
  inherited Create(True);

  FForm := AForm;
  FClassifier := AClassifier;
  FImageFile := AImageFile;

  FClassLabel := '';
  FConfidence := 0.0;
  FSuccess := False;
  FError := '';
  FLogMessage := '';

  FreeOnTerminate := True;
end;

procedure TCNNClassifyThread.DoLog(const AMsg: string);
begin
  FLogMessage := AMsg;
  Synchronize(@SyncLog);
end;

procedure TCNNClassifyThread.SyncLog;
begin
  if Assigned(FForm) then
    FForm.ThreadLog(FLogMessage);
end;

procedure TCNNClassifyThread.Execute;
begin
  try
    if Terminated then
      Exit;

    DoLog('Thread CNN iniciada.');

    if Terminated then
      Exit;

    DoLog('Chamando TCNNClassifier.ClassifyImage...');
    DoLog('O modelo pode demorar na primeira execução por carregar TensorFlow e pesos.');

    if Terminated then
      Exit;

    FSuccess := FClassifier.ClassifyImage(FImageFile, FClassLabel, FConfidence);

    if Terminated then
    begin
      FSuccess := False;
      FError := 'Classificação interrompida pelo usuário.';
      Exit;
    end;

    if not FSuccess then
      FError := FClassifier.LastError;

    DoLog('Thread CNN finalizou a chamada do classificador.');
  except
    on E: Exception do
    begin
      FSuccess := False;
      FError := 'Exceção na thread de classificação: ' + E.Message;
    end;
  end;

  if not Terminated then
    Synchronize(@SyncUpdateUI);
end;

procedure TCNNClassifyThread.SyncUpdateUI;
begin
  if Assigned(FForm) then
    FForm.ClassifyFinished(FSuccess, FClassLabel, FConfidence, FError);
end;

end.
