unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DateUtils, Math,
  Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls, StdCtrls, Clipbrd,
  LCLIntf, FileUtil,
  aiaudio, aispeechrecognizer;

type
  TSpeechDemoState = (
    sdsIdle,
    sdsRecording,
    sdsReady,
    sdsTranscribing,
    sdsSuccess,
    sdsError,
    sdsCancelled
  );

  { TfrmMain }

  TfrmMain = class(TForm)
  private
    FRecognizer: TAISpeechRecognizer;
    FAudio: TAIAudioInput;
    FState: TSpeechDemoState;
    FRecordingStartedAt: TDateTime;
    FCurrentFile: string;
    FCancelRequested: Boolean;

    // Root UI
    FTopPanel: TPanel;
    FBottomPanel: TPanel;
    FStatusLabel: TLabel;
    FPageControl: TPageControl;
    FTimer: TTimer;

    // Tabs
    FTabOperation: TTabSheet;
    FTabBackends: TTabSheet;
    FTabConfig: TTabSheet;
    FTabResult: TTabSheet;
    FTabLog: TTabSheet;

    // Operation tab
    FOpLeft: TPanel;
    FOpRight: TPanel;
    FLblFile: TLabel;
    FEditFile: TEdit;
    FBtnBrowseFile: TButton;
    FBtnRecord: TButton;
    FBtnStop: TButton;
    FBtnPushToTalk: TButton;
    FBtnTranscribe: TButton;
    FBtnCancel: TButton;
    FBtnOpenFile: TButton;
    FBtnOpenFolder: TButton;
    FLblOpState: TLabel;
    FLblElapsed: TLabel;
    FProgress: TProgressBar;
    FMemoOperation: TMemo;
    FChkAutoTranscribe: TCheckBox;

    // Backends tab
    FBackendGroup: TGroupBox;
    FBackendCombo: TComboBox;
    FChkOnlineConsent: TCheckBox;
    FChkStrictWav: TCheckBox;
    FChkAutoFallback: TCheckBox;
    FBtnValidateBackend: TButton;
    FBtnRefreshHint: TButton;
    FMemoBackendInfo: TMemo;

    // Config tab
    FConfigScroll: TScrollBox;
    FEditRecordFolder: TEdit;
    FEditFilePrefix: TEdit;
    FEditSampleRate: TEdit;
    FEditChannels: TEdit;
    FEditDurationLimit: TEdit;
    FEditWhisperExec: TEdit;
    FEditWhisperModel: TEdit;
    FEditWhisperThreads: TEdit;
    FEditWhisperArgs: TEdit;
    FEditSherpaLib: TEdit;
    FEditSherpaEncoder: TEdit;
    FEditSherpaDecoder: TEdit;
    FEditSherpaTokens: TEdit;
    FEditSherpaProvider: TEdit;
    FEditSherpaThreads: TEdit;
    FEditSherpaTask: TEdit;
    FEditOpenAIToken: TEdit;
    FEditOpenAIModel: TEdit;
    FEditOpenAIEndpoint: TEdit;
    FEditOpenAIResponseFormat: TEdit;
    FEditAzureKey: TEdit;
    FEditAzureRegion: TEdit;
    FEditAzureEndpoint: TEdit;
    FEditAzureFormat: TEdit;
    FBtnApplyConfig: TButton;
    FBtnLoadDefaults: TButton;

    // Result tab
    FEditResultFile: TEdit;
    FEditResultBackend: TEdit;
    FLabelValidation: TLabel;
    FEditTranscriptFile: TEdit;
    FMemoTranscript: TMemo;
    FMemoResultInfo: TMemo;
    FBtnCopyTranscript: TButton;
    FBtnClearResult: TButton;

    // Log tab
    FMemoLog: TMemo;
    FBtnClearLog: TButton;

    function BuildNewFileName: string;
    function SelectedBackend: TAISpeechBackend;
    function SelectedBackendName: string;
    function BackendDescription(const ABackend: TAISpeechBackend): string;
    function BackendTitle(const ABackend: TAISpeechBackend): string;
    function StateText: string;
    function IsOnlineBackend(const ABackend: TAISpeechBackend): Boolean;
    function CurrentOutputFolder: string;

    procedure BuildUI;
    procedure BuildHeader;
    procedure BuildTabs;
    procedure BuildOperationTab;
    procedure BuildBackendsTab;
    procedure BuildConfigTab;
    procedure BuildResultTab;
    procedure BuildLogTab;
    procedure BuildGroupCaption(AParent: TWinControl; const ACaption: string; ATop: Integer; AHeight: Integer);

    function CreateLabel(AParent: TWinControl; const ACaption: string; ALeft, ATop, AWidth: Integer): TLabel;
    function CreateEdit(AParent: TWinControl; const AText: string; ALeft, ATop, AWidth: Integer): TEdit;
    function CreateButton(AParent: TWinControl; const ACaption: string; ALeft, ATop, AWidth, AHeight: Integer; AOnClick: TNotifyEvent): TButton;
    function CreateCheckBox(AParent: TWinControl; const ACaption: string; ALeft, ATop, AWidth: Integer; AChecked: Boolean): TCheckBox;
    function CreateMemo(AParent: TWinControl; ALeft, ATop, AWidth, AHeight: Integer): TMemo;

    procedure AddLog(const AMsg: string);
    procedure SetState(const AState: TSpeechDemoState; const AMessage: string);
    procedure UpdateStatus(const AMessage: string);
    procedure UpdateOperationControls;
    procedure UpdateBackendHint;
    procedure UpdateResultPanel;
    procedure ApplyUIToComponents;
    procedure LoadComponentValuesToUI;
    procedure SetResultTranscript(const AText: string);
    procedure ValidateRecordingFile;
    procedure StartRecording(const AAutoTranscribeAfterStop: Boolean);
    procedure StopRecording(const AAutoTranscribeAfterStop: Boolean);
    procedure TranscribeSelectedFile;
    procedure RequestCancel;
    procedure RefreshProgress;
    procedure CopyTranscriptToClipboard;
    procedure OpenCurrentFile;
    procedure OpenCurrentFolder;

    // Events
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TimerTick(Sender: TObject);
    procedure BackendComboChange(Sender: TObject);
    procedure BtnBrowseFileClick(Sender: TObject);
    procedure BtnRecordClick(Sender: TObject);
    procedure BtnStopClick(Sender: TObject);
    procedure BtnPushToTalkMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure BtnPushToTalkMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure BtnTranscribeClick(Sender: TObject);
    procedure BtnCancelClick(Sender: TObject);
    procedure BtnOpenFileClick(Sender: TObject);
    procedure BtnOpenFolderClick(Sender: TObject);
    procedure BtnValidateBackendClick(Sender: TObject);
    procedure BtnRefreshHintClick(Sender: TObject);
    procedure BtnApplyConfigClick(Sender: TObject);
    procedure BtnLoadDefaultsClick(Sender: TObject);
    procedure BtnCopyTranscriptClick(Sender: TObject);
    procedure BtnClearResultClick(Sender: TObject);
    procedure BtnClearLogClick(Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
  end;

var
  frmMain: TfrmMain;

implementation

const
  CBackendDescriptions: array[TAISpeechBackend] of string = (
    'Auto seleciona o primeiro backend configurado e disponivel.',
    'Roda o executavel do whisper.cpp por processo externo.',
    'Carrega a C API do Sherpa-ONNX dinamicamente.',
    'Envia o WAV para a API de transcricao da OpenAI.',
    'Envia o WAV para o REST Speech-to-Text da Azure.'
  );

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  Caption := 'speech_recognizer_demo - TAISpeechRecognizer';
  Width := 1240;
  Height := 820;
  Position := poScreenCenter;

  FRecognizer := TAISpeechRecognizer.Create(Self);
  FAudio := TAIAudioInput.Create(Self);
  FState := sdsIdle;
  FCancelRequested := False;
  FCurrentFile := '';

  BuildUI;
  LoadComponentValuesToUI;
  ApplyUIToComponents;
  SetState(sdsIdle, 'Pronto para gravar ou transcrever um WAV real.');
  UpdateBackendHint;
  UpdateResultPanel;
  AddLog('speech_recognizer_demo inicializado.');
end;

constructor TfrmMain.Create(AOwner: TComponent);
begin
  inherited CreateNew(AOwner, 0);
  FormCreate(Self);
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  if FAudio.Recording then
    FAudio.StopRecord;
end;

function TfrmMain.CreateLabel(AParent: TWinControl; const ACaption: string; ALeft, ATop, AWidth: Integer): TLabel;
begin
  Result := TLabel.Create(Self);
  Result.Parent := AParent;
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Width := AWidth;
  Result.Caption := ACaption;
end;

function TfrmMain.CreateEdit(AParent: TWinControl; const AText: string; ALeft, ATop, AWidth: Integer): TEdit;
begin
  Result := TEdit.Create(Self);
  Result.Parent := AParent;
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Width := AWidth;
  Result.Text := AText;
end;

function TfrmMain.CreateButton(AParent: TWinControl; const ACaption: string; ALeft, ATop, AWidth, AHeight: Integer; AOnClick: TNotifyEvent): TButton;
begin
  Result := TButton.Create(Self);
  Result.Parent := AParent;
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Width := AWidth;
  Result.Height := AHeight;
  Result.Caption := ACaption;
  Result.OnClick := AOnClick;
end;

function TfrmMain.CreateCheckBox(AParent: TWinControl; const ACaption: string; ALeft, ATop, AWidth: Integer; AChecked: Boolean): TCheckBox;
begin
  Result := TCheckBox.Create(Self);
  Result.Parent := AParent;
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Width := AWidth;
  Result.Caption := ACaption;
  Result.Checked := AChecked;
end;

function TfrmMain.CreateMemo(AParent: TWinControl; ALeft, ATop, AWidth, AHeight: Integer): TMemo;
begin
  Result := TMemo.Create(Self);
  Result.Parent := AParent;
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Width := AWidth;
  Result.Height := AHeight;
  Result.ScrollBars := ssAutoVertical;
end;

procedure TfrmMain.BuildGroupCaption(AParent: TWinControl; const ACaption: string; ATop: Integer; AHeight: Integer);
var
  Panel: TPanel;
begin
  Panel := TPanel.Create(Self);
  Panel.Parent := AParent;
  Panel.Align := alTop;
  Panel.BevelOuter := bvNone;
  Panel.Height := AHeight;
  Panel.Caption := '';

  with TLabel.Create(Self) do
  begin
    Parent := Panel;
    Left := 12;
    Top := 8;
    Caption := ACaption;
    Font.Style := [fsBold];
  end;
end;

procedure TfrmMain.BuildHeader;
begin
  FTopPanel := TPanel.Create(Self);
  FTopPanel.Parent := Self;
  FTopPanel.Align := alTop;
  FTopPanel.Height := 76;
  FTopPanel.BevelOuter := bvNone;

  with TLabel.Create(Self) do
  begin
    Parent := FTopPanel;
    Left := 16;
    Top := 12;
    Caption := 'speech_recognizer_demo';
    Font.Height := -18;
    Font.Style := [fsBold];
  end;

  with TLabel.Create(Self) do
  begin
    Parent := FTopPanel;
    Left := 16;
    Top := 42;
    Caption := 'Grava, valida e transcreve WAV real com Whisper.cpp, Sherpa-ONNX, OpenAI ou Azure.';
  end;

  FBottomPanel := TPanel.Create(Self);
  FBottomPanel.Parent := Self;
  FBottomPanel.Align := alBottom;
  FBottomPanel.Height := 34;
  FBottomPanel.BevelOuter := bvNone;

  FStatusLabel := TLabel.Create(Self);
  FStatusLabel.Parent := FBottomPanel;
  FStatusLabel.Left := 16;
  FStatusLabel.Top := 9;
  FStatusLabel.Caption := 'Status: pronto';
  FStatusLabel.Font.Style := [fsBold];
end;

procedure TfrmMain.BuildTabs;
begin
  FPageControl := TPageControl.Create(Self);
  FPageControl.Parent := Self;
  FPageControl.Align := alClient;
  FPageControl.TabPosition := tpTop;

  FTabOperation := FPageControl.AddTabSheet;
  FTabOperation.Caption := 'Operação';
  FTabBackends := FPageControl.AddTabSheet;
  FTabBackends.Caption := 'Backends';
  FTabConfig := FPageControl.AddTabSheet;
  FTabConfig.Caption := 'Configuração';
  FTabResult := FPageControl.AddTabSheet;
  FTabResult.Caption := 'Resultado';
  FTabLog := FPageControl.AddTabSheet;
  FTabLog.Caption := 'Log';

  FPageControl.ActivePage := FTabOperation;
end;

procedure TfrmMain.BuildOperationTab;
begin
  FOpLeft := TPanel.Create(Self);
  FOpLeft.Parent := FTabOperation;
  FOpLeft.Align := alLeft;
  FOpLeft.Width := 430;
  FOpLeft.BevelOuter := bvNone;

  FOpRight := TPanel.Create(Self);
  FOpRight.Parent := FTabOperation;
  FOpRight.Align := alClient;
  FOpRight.BevelOuter := bvNone;

  FLblFile := CreateLabel(FOpLeft, 'Arquivo WAV atual:', 12, 12, 200);
  FEditFile := CreateEdit(FOpLeft, 'output\\speech_recognizer_demo.wav', 12, 34, 300);
  FEditFile.Width := 300;
  FBtnBrowseFile := CreateButton(FOpLeft, 'Selecionar WAV', 320, 32, 100, 28, @BtnBrowseFileClick);

  FBtnRecord := CreateButton(FOpLeft, 'Gravar', 12, 76, 92, 34, @BtnRecordClick);
  FBtnStop := CreateButton(FOpLeft, 'Parar', 112, 76, 92, 34, @BtnStopClick);
  FBtnPushToTalk := CreateButton(FOpLeft, 'Push-to-talk', 212, 76, 104, 34, nil);
  FBtnPushToTalk.OnMouseDown := @BtnPushToTalkMouseDown;
  FBtnPushToTalk.OnMouseUp := @BtnPushToTalkMouseUp;
  FBtnTranscribe := CreateButton(FOpLeft, 'Transcrever', 324, 76, 96, 34, @BtnTranscribeClick);

  FBtnCancel := CreateButton(FOpLeft, 'Cancelar', 12, 118, 92, 30, @BtnCancelClick);
  FBtnOpenFile := CreateButton(FOpLeft, 'Abrir arquivo', 112, 118, 98, 30, @BtnOpenFileClick);
  FBtnOpenFolder := CreateButton(FOpLeft, 'Abrir pasta', 218, 118, 96, 30, @BtnOpenFolderClick);

  FChkAutoTranscribe := CreateCheckBox(FOpLeft, 'Transcrever automaticamente ao parar a gravação', 12, 160, 360, True);
  FChkAutoTranscribe.Hint := 'Quando ligado, o demo valida o WAV e tenta transcrever assim que a gravação termina.';

  FLblOpState := CreateLabel(FOpLeft, 'Estado: idle', 12, 200, 350);
  FLblElapsed := CreateLabel(FOpLeft, 'Tempo: 00:00', 12, 224, 220);

  FProgress := TProgressBar.Create(Self);
  FProgress.Parent := FOpLeft;
  FProgress.Left := 12;
  FProgress.Top := 252;
  FProgress.Width := 390;
  FProgress.Height := 18;
  FProgress.Min := 0;
  FProgress.Max := 100;

  FMemoOperation := CreateMemo(FOpRight, 12, 12, 740, 430);
  FMemoOperation.ReadOnly := True;
  FMemoOperation.Lines.Text :=
    'Operação do sample:'#13#10 +
    '- Grave um WAV real.'#13#10 +
    '- Pare a gravação ou use push-to-talk.'#13#10 +
    '- Transcreva com o backend selecionado.'#13#10 +
    '- O sucesso só é marcado após validação real.'#13#10#13#10 +
    'Não existe modo de simulação.';
end;

procedure TfrmMain.BuildBackendsTab;
var
  I: Integer;
  ABackend: TAISpeechBackend;
begin
  FBackendGroup := TGroupBox.Create(Self);
  FBackendGroup.Parent := FTabBackends;
  FBackendGroup.Align := alLeft;
  FBackendGroup.Width := 360;
  FBackendGroup.Caption := 'Seleção e consentimento';

  CreateLabel(FBackendGroup, 'Backend:', 12, 28, 80);
  FBackendCombo := TComboBox.Create(Self);
  FBackendCombo.Parent := FBackendGroup;
  FBackendCombo.Left := 12;
  FBackendCombo.Top := 48;
  FBackendCombo.Width := 320;
  FBackendCombo.Style := csDropDownList;
  for ABackend := Low(TAISpeechBackend) to High(TAISpeechBackend) do
    FBackendCombo.Items.Add(BackendTitle(ABackend));
  FBackendCombo.ItemIndex := 0;
  FBackendCombo.OnChange := @BackendComboChange;

  FChkOnlineConsent := CreateCheckBox(FBackendGroup, 'Autorizo envio de áudio para serviços online', 12, 86, 320, False);
  FChkStrictWav := CreateCheckBox(FBackendGroup, 'Exigir WAV PCM válido antes de transcrever', 12, 116, 320, True);
  FChkAutoFallback := CreateCheckBox(FBackendGroup, 'Permitir fallback automático quando backend atual falhar', 12, 146, 320, True);

  FBtnValidateBackend := CreateButton(FBackendGroup, 'Validar backend', 12, 184, 140, 30, @BtnValidateBackendClick);
  FBtnRefreshHint := CreateButton(FBackendGroup, 'Atualizar dica', 168, 184, 140, 30, @BtnRefreshHintClick);

  FMemoBackendInfo := CreateMemo(FTabBackends, 380, 12, 780, 430);
  FMemoBackendInfo.ReadOnly := True;
  FMemoBackendInfo.Lines.Text :=
    'Backends reais disponíveis:'#13#10 +
    '- offline.whispercpp: executável externo.'#13#10 +
    '- offline.sherpaonnx: C API carregada dinamicamente.'#13#10 +
    '- online.openai: endpoint de transcrição.'#13#10 +
    '- online.azure: REST Speech-to-Text.'#13#10#13#10 +
    'O consentimento online é obrigatório para OpenAI e Azure.';
end;

procedure TfrmMain.BuildConfigTab;
var
  Y: Integer;
  LGroup: TGroupBox;
  procedure AddSection(const ACaption: string; const AHeight: Integer; out AGroup: TGroupBox);
  begin
    AGroup := TGroupBox.Create(Self);
    AGroup.Parent := FConfigScroll;
    AGroup.Align := alTop;
    AGroup.Caption := ACaption;
    AGroup.Height := AHeight;
    AGroup.BorderSpacing.Top := 6;
  end;
begin
  FConfigScroll := TScrollBox.Create(Self);
  FConfigScroll.Parent := FTabConfig;
  FConfigScroll.Align := alClient;
  FConfigScroll.HorzScrollBar.Visible := False;

  AddSection('Gravação', 182, LGroup);
  FEditRecordFolder := CreateEdit(LGroup, 'output', 16, 36, 280);
  CreateLabel(LGroup, 'Pasta de gravação:', 16, 18, 180);
  FEditFilePrefix := CreateEdit(LGroup, 'speech_recognizer_demo', 320, 36, 180);
  CreateLabel(LGroup, 'Prefixo do arquivo:', 320, 18, 180);
  FEditSampleRate := CreateEdit(LGroup, '16000', 16, 86, 120);
  CreateLabel(LGroup, 'Sample rate:', 16, 68, 120);
  FEditChannels := CreateEdit(LGroup, '1', 160, 86, 120);
  CreateLabel(LGroup, 'Canais:', 160, 68, 120);
  FEditDurationLimit := CreateEdit(LGroup, '30', 304, 86, 120);
  CreateLabel(LGroup, 'Limite (seg):', 304, 68, 120);
  FBtnApplyConfig := CreateButton(LGroup, 'Aplicar', 16, 126, 90, 30, @BtnApplyConfigClick);
  FBtnLoadDefaults := CreateButton(LGroup, 'Padrões', 116, 126, 90, 30, @BtnLoadDefaultsClick);

  AddSection('Whisper.cpp', 150, LGroup);
  FEditWhisperExec := CreateEdit(LGroup, 'main', 16, 36, 260);
  CreateLabel(LGroup, 'Executável:', 16, 18, 100);
  FEditWhisperModel := CreateEdit(LGroup, '', 296, 36, 260);
  CreateLabel(LGroup, 'Modelo:', 296, 18, 100);
  FEditWhisperThreads := CreateEdit(LGroup, '4', 16, 86, 120);
  CreateLabel(LGroup, 'Threads:', 16, 68, 80);
  FEditWhisperArgs := CreateEdit(LGroup, '', 160, 86, 396);
  CreateLabel(LGroup, 'Args extras:', 160, 68, 120);

  AddSection('Sherpa-ONNX', 170, LGroup);
  FEditSherpaLib := CreateEdit(LGroup, '', 16, 36, 250);
  CreateLabel(LGroup, 'Biblioteca:', 16, 18, 100);
  FEditSherpaEncoder := CreateEdit(LGroup, '', 280, 36, 250);
  CreateLabel(LGroup, 'Encoder:', 280, 18, 100);
  FEditSherpaDecoder := CreateEdit(LGroup, '', 16, 86, 250);
  CreateLabel(LGroup, 'Decoder:', 16, 68, 100);
  FEditSherpaTokens := CreateEdit(LGroup, '', 280, 86, 250);
  CreateLabel(LGroup, 'Tokens:', 280, 68, 100);
  FEditSherpaProvider := CreateEdit(LGroup, 'cpu', 16, 136, 120);
  CreateLabel(LGroup, 'Provider:', 16, 118, 80);
  FEditSherpaThreads := CreateEdit(LGroup, '1', 160, 136, 120);
  CreateLabel(LGroup, 'Threads:', 160, 118, 80);
  FEditSherpaTask := CreateEdit(LGroup, 'transcribe', 304, 136, 226);
  CreateLabel(LGroup, 'Task:', 304, 118, 80);

  AddSection('OpenAI', 150, LGroup);
  FEditOpenAIToken := CreateEdit(LGroup, '', 16, 36, 560);
  CreateLabel(LGroup, 'Token:', 16, 18, 100);
  FEditOpenAIModel := CreateEdit(LGroup, 'whisper-1', 16, 86, 160);
  CreateLabel(LGroup, 'Modelo:', 16, 68, 100);
  FEditOpenAIEndpoint := CreateEdit(LGroup, 'https://api.openai.com/v1/audio/transcriptions', 196, 86, 380);
  CreateLabel(LGroup, 'Endpoint:', 196, 68, 100);
  FEditOpenAIResponseFormat := CreateEdit(LGroup, 'json', 16, 126, 160);
  CreateLabel(LGroup, 'Formato:', 16, 108, 100);

  AddSection('Azure', 160, LGroup);
  FEditAzureKey := CreateEdit(LGroup, '', 16, 36, 280);
  CreateLabel(LGroup, 'Subscription key:', 16, 18, 140);
  FEditAzureRegion := CreateEdit(LGroup, '', 316, 36, 140);
  CreateLabel(LGroup, 'Region:', 316, 18, 100);
  FEditAzureEndpoint := CreateEdit(LGroup, '', 16, 86, 440);
  CreateLabel(LGroup, 'Endpoint opcional:', 16, 68, 150);
  FEditAzureFormat := CreateEdit(LGroup, 'simple', 476, 86, 120);
  CreateLabel(LGroup, 'Format:', 476, 68, 100);
end;

procedure TfrmMain.BuildResultTab;
begin
  CreateLabel(FTabResult, 'Arquivo validado:', 12, 14, 120);
  FEditResultFile := CreateEdit(FTabResult, '', 12, 34, 600);
  FEditResultFile.ReadOnly := True;

  CreateLabel(FTabResult, 'Backend executado:', 12, 68, 120);
  FEditResultBackend := CreateEdit(FTabResult, '', 12, 88, 280);
  FEditResultBackend.ReadOnly := True;

  CreateLabel(FTabResult, 'Validação:', 12, 124, 120);
  FLabelValidation := CreateLabel(FTabResult, 'N/A', 12, 144, 400);
  FLabelValidation.Font.Style := [fsBold];

  CreateLabel(FTabResult, 'Arquivo transcrito:', 12, 176, 120);
  FEditTranscriptFile := CreateEdit(FTabResult, '', 12, 196, 600);
  FEditTranscriptFile.ReadOnly := True;

  FBtnCopyTranscript := CreateButton(FTabResult, 'Copiar texto', 630, 194, 120, 30, @BtnCopyTranscriptClick);
  FBtnClearResult := CreateButton(FTabResult, 'Limpar resultado', 630, 230, 120, 30, @BtnClearResultClick);

  FMemoTranscript := CreateMemo(FTabResult, 12, 240, 620, 220);
  FMemoTranscript.ReadOnly := True;

  FMemoResultInfo := CreateMemo(FTabResult, 650, 34, 360, 426);
  FMemoResultInfo.ReadOnly := True;
  FMemoResultInfo.Lines.Text := 'O resultado só ganha status de sucesso depois da validação real do WAV e da transcrição retornar texto não vazio.';
end;

procedure TfrmMain.BuildLogTab;
begin
  FMemoLog := CreateMemo(FTabLog, 12, 12, 940, 430);
  FMemoLog.ReadOnly := True;
  FMemoLog.Font.Name := 'Consolas';
  FMemoLog.Font.Size := 9;

  FBtnClearLog := CreateButton(FTabLog, 'Limpar log', 12, 450, 100, 30, @BtnClearLogClick);
end;

procedure TfrmMain.BuildUI;
begin
  BuildHeader;
  BuildTabs;
  BuildOperationTab;
  BuildBackendsTab;
  BuildConfigTab;
  BuildResultTab;
  BuildLogTab;

  FTimer := TTimer.Create(Self);
  FTimer.Interval := 500;
  FTimer.OnTimer := @TimerTick;
  FTimer.Enabled := True;
end;

function TfrmMain.BackendTitle(const ABackend: TAISpeechBackend): string;
begin
  case ABackend of
    sbAuto: Result := 'Auto';
    sbWhisperCpp: Result := 'offline.whispercpp';
    sbSherpaOnnx: Result := 'offline.sherpaonnx';
    sbOpenAI: Result := 'online.openai';
    sbAzure: Result := 'online.azure';
  else
    Result := 'Auto';
  end;
end;

function TfrmMain.SelectedBackend: TAISpeechBackend;
begin
  case FBackendCombo.ItemIndex of
    1: Result := sbWhisperCpp;
    2: Result := sbSherpaOnnx;
    3: Result := sbOpenAI;
    4: Result := sbAzure;
  else
    Result := sbAuto;
  end;
end;

function TfrmMain.SelectedBackendName: string;
begin
  Result := BackendTitle(SelectedBackend);
end;

function TfrmMain.IsOnlineBackend(const ABackend: TAISpeechBackend): Boolean;
begin
  Result := ABackend in [sbOpenAI, sbAzure];
end;

function TfrmMain.BackendDescription(const ABackend: TAISpeechBackend): string;
begin
  Result := CBackendDescriptions[ABackend];
end;

function TfrmMain.BuildNewFileName: string;
var
  Dir, Prefix: string;
begin
  Dir := Trim(FEditRecordFolder.Text);
  if Dir = '' then
    Dir := 'output';
  Prefix := Trim(FEditFilePrefix.Text);
  if Prefix = '' then
    Prefix := 'speech_recognizer_demo';
  if not DirectoryExists(Dir) then
    ForceDirectories(Dir);
  Result := IncludeTrailingPathDelimiter(Dir) + Prefix + '_' + FormatDateTime('yyyymmdd_hhnnss', Now) + '.wav';
end;

function TfrmMain.CurrentOutputFolder: string;
begin
  Result := ExtractFilePath(FEditFile.Text);
  if Result = '' then
    Result := Trim(FEditRecordFolder.Text);
end;

function TfrmMain.StateText: string;
begin
  case FState of
    sdsIdle: Result := 'idle';
    sdsRecording: Result := 'gravando';
    sdsReady: Result := 'pronto';
    sdsTranscribing: Result := 'transcrevendo';
    sdsSuccess: Result := 'sucesso';
    sdsError: Result := 'erro';
    sdsCancelled: Result := 'cancelado';
  else
    Result := 'idle';
  end;
end;

procedure TfrmMain.SetState(const AState: TSpeechDemoState; const AMessage: string);
begin
  FState := AState;
  UpdateStatus(AMessage);
  UpdateOperationControls;
end;

procedure TfrmMain.UpdateStatus(const AMessage: string);
begin
  FStatusLabel.Caption := 'Status: ' + AMessage;
  case FState of
    sdsSuccess: FStatusLabel.Font.Color := clGreen;
    sdsError: FStatusLabel.Font.Color := clRed;
    sdsCancelled: FStatusLabel.Font.Color := clGrayText;
  else
    FStatusLabel.Font.Color := clDefault;
  end;
  FLblOpState.Caption := 'Estado: ' + StateText;
end;

procedure TfrmMain.UpdateOperationControls;
begin
  FBtnRecord.Enabled := FState <> sdsRecording;
  FBtnStop.Enabled := FState = sdsRecording;
  FBtnPushToTalk.Enabled := FState <> sdsTranscribing;
  FBtnTranscribe.Enabled := (FState <> sdsRecording) and (Trim(FEditFile.Text) <> '');
  FBtnCancel.Enabled := FState in [sdsRecording, sdsTranscribing];
  FBtnOpenFile.Enabled := FileExists(FEditFile.Text);
  FBtnOpenFolder.Enabled := Trim(CurrentOutputFolder) <> '';
end;

procedure TfrmMain.UpdateBackendHint;
var
  Backend: TAISpeechBackend;
begin
  Backend := SelectedBackend;
  FMemoBackendInfo.Clear;
  FMemoBackendInfo.Lines.Add('Backend selecionado: ' + BackendTitle(Backend));
  FMemoBackendInfo.Lines.Add('');
  FMemoBackendInfo.Lines.Add(BackendDescription(Backend));
  FMemoBackendInfo.Lines.Add('');
  if FChkOnlineConsent.Checked then
    FMemoBackendInfo.Lines.Add('Consentimento online: marcado')
  else
    FMemoBackendInfo.Lines.Add('Consentimento online: nao marcado');

  if FChkStrictWav.Checked then
    FMemoBackendInfo.Lines.Add('Validacao WAV estrita: sim')
  else
    FMemoBackendInfo.Lines.Add('Validacao WAV estrita: nao');

  if FChkAutoFallback.Checked then
    FMemoBackendInfo.Lines.Add('Fallback automatico: sim')
  else
    FMemoBackendInfo.Lines.Add('Fallback automatico: nao');
end;

procedure TfrmMain.UpdateResultPanel;
begin
  FEditResultFile.Text := FCurrentFile;
  FEditResultBackend.Text := SelectedBackendName;
  FEditTranscriptFile.Text := FCurrentFile;
  UpdateOperationControls;
end;

procedure TfrmMain.SetResultTranscript(const AText: string);
begin
  FMemoTranscript.Lines.Text := AText;
end;

procedure TfrmMain.LoadComponentValuesToUI;
begin
  FEditRecordFolder.Text := 'output';
  FEditFilePrefix.Text := 'speech_recognizer_demo';
  FEditSampleRate.Text := '16000';
  FEditChannels.Text := '1';
  FEditDurationLimit.Text := '30';
  FEditWhisperExec.Text := 'main';
  FEditWhisperModel.Text := '';
  FEditWhisperThreads.Text := '4';
  FEditWhisperArgs.Text := '';
  FEditSherpaLib.Text := '';
  FEditSherpaEncoder.Text := '';
  FEditSherpaDecoder.Text := '';
  FEditSherpaTokens.Text := '';
  FEditSherpaProvider.Text := 'cpu';
  FEditSherpaThreads.Text := '1';
  FEditSherpaTask.Text := 'transcribe';
  FEditOpenAIToken.Text := '';
  FEditOpenAIModel.Text := 'whisper-1';
  FEditOpenAIEndpoint.Text := 'https://api.openai.com/v1/audio/transcriptions';
  FEditOpenAIResponseFormat.Text := 'json';
  FEditAzureKey.Text := '';
  FEditAzureRegion.Text := '';
  FEditAzureEndpoint.Text := '';
  FEditAzureFormat.Text := 'simple';
  FBackendCombo.ItemIndex := 0;
  FChkOnlineConsent.Checked := False;
  FChkStrictWav.Checked := True;
  FChkAutoFallback.Checked := True;
  FChkAutoTranscribe.Checked := True;
end;

procedure TfrmMain.ApplyUIToComponents;
begin
  FAudio.SampleRate := StrToIntDef(FEditSampleRate.Text, 16000);
  FAudio.Channels := StrToIntDef(FEditChannels.Text, 1);
  FAudio.DurationLimit := StrToIntDef(FEditDurationLimit.Text, 30);
  FRecognizer.Backend := SelectedBackend;
  FRecognizer.InputFile := Trim(FEditFile.Text);
  FRecognizer.Language := 'pt-BR';
  FRecognizer.PromptText := '';
  FRecognizer.StrictWavValidation := FChkStrictWav.Checked;
  FRecognizer.WhisperCppExecutable := Trim(FEditWhisperExec.Text);
  FRecognizer.WhisperCppModel := Trim(FEditWhisperModel.Text);
  FRecognizer.WhisperCppThreads := StrToIntDef(FEditWhisperThreads.Text, 4);
  FRecognizer.WhisperCppExtraArgs := Trim(FEditWhisperArgs.Text);
  FRecognizer.SherpaLibraryPath := Trim(FEditSherpaLib.Text);
  FRecognizer.SherpaEncoderFile := Trim(FEditSherpaEncoder.Text);
  FRecognizer.SherpaDecoderFile := Trim(FEditSherpaDecoder.Text);
  FRecognizer.SherpaTokensFile := Trim(FEditSherpaTokens.Text);
  FRecognizer.SherpaProvider := Trim(FEditSherpaProvider.Text);
  FRecognizer.SherpaNumThreads := StrToIntDef(FEditSherpaThreads.Text, 1);
  FRecognizer.SherpaTask := Trim(FEditSherpaTask.Text);
  FRecognizer.OpenAIToken := Trim(FEditOpenAIToken.Text);
  FRecognizer.OpenAIModel := Trim(FEditOpenAIModel.Text);
  FRecognizer.OpenAIEndpoint := Trim(FEditOpenAIEndpoint.Text);
  FRecognizer.OpenAIResponseFormat := Trim(FEditOpenAIResponseFormat.Text);
  FRecognizer.AzureSubscriptionKey := Trim(FEditAzureKey.Text);
  FRecognizer.AzureRegion := Trim(FEditAzureRegion.Text);
  FRecognizer.AzureEndpoint := Trim(FEditAzureEndpoint.Text);
  FRecognizer.AzureFormat := Trim(FEditAzureFormat.Text);
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  FMemoLog.Lines.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' - ' + AMsg);
  if FMemoLog.Lines.Count > 1000 then
    FMemoLog.Lines.Delete(0);
  FMemoLog.SelStart := Length(FMemoLog.Text);
  FMemoLog.SelLength := 0;
end;

procedure TfrmMain.ValidateRecordingFile;
var
  Err: string;
  IsValid: Boolean;
begin
  if Trim(FEditFile.Text) = '' then
  begin
    FLabelValidation.Caption := 'FAIL - arquivo vazio';
    FLabelValidation.Font.Color := clRed;
    Exit;
  end;

  IsValid := FAudio.ValidateWavFile(FEditFile.Text, Err);
  if IsValid then
  begin
    FLabelValidation.Caption := 'PENDING - WAV válido, aguardando transcrição real';
    FLabelValidation.Font.Color := clBlue;
    SetState(sdsReady, 'WAV validado, aguardando transcrição.');
    AddLog('WAV validado com sucesso: ' + FEditFile.Text);
  end
  else
  begin
    FLabelValidation.Caption := 'FAIL - ' + Err;
    FLabelValidation.Font.Color := clRed;
    SetState(sdsError, Err);
    AddLog('Falha na validação do WAV: ' + Err);
  end;
  UpdateResultPanel;
end;

procedure TfrmMain.RefreshProgress;
var
  ElapsedSecs: Integer;
begin
  if FState = sdsRecording then
  begin
    ElapsedSecs := SecondsBetween(Now, FRecordingStartedAt);
    FLblElapsed.Caption := Format('Tempo: %.2d:%.2d', [ElapsedSecs div 60, ElapsedSecs mod 60]);
    if FAudio.DurationLimit > 0 then
      FProgress.Position := Min(FProgress.Max, Round((ElapsedSecs / FAudio.DurationLimit) * FProgress.Max))
    else
      FProgress.Position := (FProgress.Position + 1) mod (FProgress.Max + 1);
  end
  else
  begin
    FLblElapsed.Caption := 'Tempo: 00:00';
    if FState = sdsSuccess then
      FProgress.Position := FProgress.Max
    else
      FProgress.Position := 0;
  end;
end;

procedure TfrmMain.StartRecording(const AAutoTranscribeAfterStop: Boolean);
begin
  if FAudio.Recording then
    Exit;

  ApplyUIToComponents;
  if Trim(FEditFile.Text) = '' then
    FEditFile.Text := BuildNewFileName;

  if ExtractFilePath(FEditFile.Text) <> '' then
    ForceDirectories(ExtractFilePath(FEditFile.Text));

  FCurrentFile := FEditFile.Text;
  UpdateResultPanel;

  if not FAudio.StartRecord(FCurrentFile) then
  begin
    SetState(sdsError, 'Falha ao iniciar gravação.');
    AddLog('Falha ao iniciar gravação: ' + FAudio.LastError);
    Exit;
  end;

  FRecordingStartedAt := Now;
  FCancelRequested := False;
  SetState(sdsRecording, 'gravando');
  AddLog('Gravação iniciada: ' + FCurrentFile);
  if AAutoTranscribeAfterStop then
    AddLog('Push-to-talk ativo: ao soltar, o arquivo será validado e transcrito.');
end;

procedure TfrmMain.StopRecording(const AAutoTranscribeAfterStop: Boolean);
begin
  if not FAudio.Recording then
    Exit;

  FAudio.StopRecord;
  AddLog('Gravação finalizada.');
  if AAutoTranscribeAfterStop and FChkAutoTranscribe.Checked then
    ValidateRecordingFile
  else
  begin
    SetState(sdsReady, 'gravação parada, aguardando validação/transcrição.');
    ValidateRecordingFile;
  end;
end;

procedure TfrmMain.RequestCancel;
begin
  if FAudio.Recording then
  begin
    FAudio.StopRecord;
    FCancelRequested := True;
    SetState(sdsCancelled, 'gravação cancelada.');
    AddLog('Cancelamento solicitado durante a gravação.');
    Exit;
  end;

  if FState = sdsTranscribing then
  begin
    FCancelRequested := True;
    SetState(sdsCancelled, 'cancelamento solicitado durante a transcrição.');
    AddLog('Cancelamento solicitado durante a transcrição. O backend em execução não é interrompido, mas o resultado será descartado.');
  end;
end;

procedure TfrmMain.TranscribeSelectedFile;
var
  Transcript: string;
  WasSuccess: Boolean;
begin
  ApplyUIToComponents;
  if Trim(FEditFile.Text) = '' then
  begin
    SetState(sdsError, 'arquivo WAV vazio.');
    Exit;
  end;

  if IsOnlineBackend(SelectedBackend) and not FChkOnlineConsent.Checked then
  begin
    SetState(sdsError, 'consentimento online não marcado.');
    AddLog('Bloqueio: backend online sem consentimento.');
    Exit;
  end;

  if not FileExists(FEditFile.Text) then
  begin
    SetState(sdsError, 'arquivo WAV não encontrado.');
    AddLog('Arquivo não encontrado para transcrição: ' + FEditFile.Text);
    Exit;
  end;

  FRecognizer.Backend := SelectedBackend;
  FRecognizer.InputFile := FEditFile.Text;
  FRecognizer.StrictWavValidation := FChkStrictWav.Checked;
  FRecognizer.WhisperCppExecutable := Trim(FEditWhisperExec.Text);
  FRecognizer.WhisperCppModel := Trim(FEditWhisperModel.Text);
  FRecognizer.WhisperCppThreads := StrToIntDef(FEditWhisperThreads.Text, 4);
  FRecognizer.WhisperCppExtraArgs := Trim(FEditWhisperArgs.Text);
  FRecognizer.SherpaLibraryPath := Trim(FEditSherpaLib.Text);
  FRecognizer.SherpaEncoderFile := Trim(FEditSherpaEncoder.Text);
  FRecognizer.SherpaDecoderFile := Trim(FEditSherpaDecoder.Text);
  FRecognizer.SherpaTokensFile := Trim(FEditSherpaTokens.Text);
  FRecognizer.SherpaProvider := Trim(FEditSherpaProvider.Text);
  FRecognizer.SherpaNumThreads := StrToIntDef(FEditSherpaThreads.Text, 1);
  FRecognizer.SherpaTask := Trim(FEditSherpaTask.Text);
  FRecognizer.OpenAIToken := Trim(FEditOpenAIToken.Text);
  FRecognizer.OpenAIModel := Trim(FEditOpenAIModel.Text);
  FRecognizer.OpenAIEndpoint := Trim(FEditOpenAIEndpoint.Text);
  FRecognizer.OpenAIResponseFormat := Trim(FEditOpenAIResponseFormat.Text);
  FRecognizer.AzureSubscriptionKey := Trim(FEditAzureKey.Text);
  FRecognizer.AzureRegion := Trim(FEditAzureRegion.Text);
  FRecognizer.AzureEndpoint := Trim(FEditAzureEndpoint.Text);
  FRecognizer.AzureFormat := Trim(FEditAzureFormat.Text);

  if not FRecognizer.ValidateInputFile(FEditFile.Text) then
  begin
    SetState(sdsError, FRecognizer.LastError);
    AddLog('Falha na validação do arquivo: ' + FRecognizer.LastError);
    Exit;
  end;

  SetState(sdsTranscribing, 'transcrevendo');
  AddLog('Transcrição iniciada com backend ' + SelectedBackendName + '.');
  FCancelRequested := False;
  WasSuccess := FRecognizer.RecognizeFile(FEditFile.Text);
  if FCancelRequested then
  begin
    SetState(sdsCancelled, 'resultado descartado por cancelamento.');
    AddLog('Resultado descartado após cancelamento.');
    Exit;
  end;

  if WasSuccess and FRecognizer.LastSuccess and (Trim(FRecognizer.LastResult) <> '') then
  begin
    Transcript := Trim(FRecognizer.LastResult);
    SetResultTranscript(Transcript);
    FEditTranscriptFile.Text := FEditFile.Text;
    FEditResultFile.Text := FEditFile.Text;
    FEditResultBackend.Text := SelectedBackendName;
    FLabelValidation.Caption := 'PASS - WAV validado e transcrição real concluída';
    FLabelValidation.Font.Color := clGreen;
    FMemoResultInfo.Clear;
    FMemoResultInfo.Lines.Add('Backend: ' + SelectedBackendName);
    FMemoResultInfo.Lines.Add('Arquivo: ' + FEditFile.Text);
    FMemoResultInfo.Lines.Add('Texto não vazio confirmado.');
    SetState(sdsSuccess, 'transcrição concluída com sucesso.');
    AddLog('Transcrição concluída com sucesso.');
  end
  else
  begin
    SetResultTranscript('');
    FLabelValidation.Caption := 'FAIL - ' + FRecognizer.LastError;
    FLabelValidation.Font.Color := clRed;
    FMemoResultInfo.Clear;
    FMemoResultInfo.Lines.Add('Backend: ' + SelectedBackendName);
    FMemoResultInfo.Lines.Add('Arquivo: ' + FEditFile.Text);
    FMemoResultInfo.Lines.Add('Erro: ' + FRecognizer.LastError);
    SetState(sdsError, FRecognizer.LastError);
    AddLog('Falha na transcrição: ' + FRecognizer.LastError);
  end;
  UpdateResultPanel;
end;

procedure TfrmMain.CopyTranscriptToClipboard;
begin
  Clipboard.AsText := FMemoTranscript.Lines.Text;
  AddLog('Texto da transcrição copiado para a área de transferência.');
end;

procedure TfrmMain.OpenCurrentFile;
begin
  if FileExists(FEditFile.Text) then
    OpenDocument(FEditFile.Text)
  else
    ShowMessage('Arquivo WAV não encontrado.');
end;

procedure TfrmMain.OpenCurrentFolder;
var
  Dir: string;
begin
  Dir := CurrentOutputFolder;
  if (Dir = '') or not DirectoryExists(Dir) then
  begin
    ShowMessage('Pasta de saída não encontrada.');
    Exit;
  end;
  OpenDocument(Dir);
end;

procedure TfrmMain.BtnBrowseFileClick(Sender: TObject);
begin
  with TOpenDialog.Create(Self) do
  try
    Filter := 'WAV Audio (*.wav)|*.wav|All files (*.*)|*.*';
    if FileExists(FEditFile.Text) then
      FileName := FEditFile.Text;
    if Execute then
    begin
      FEditFile.Text := FileName;
      FCurrentFile := FileName;
      AddLog('Arquivo WAV selecionado: ' + FileName);
      UpdateResultPanel;
    end;
  finally
    Free;
  end;
end;

procedure TfrmMain.BtnRecordClick(Sender: TObject);
begin
  StartRecording(False);
end;

procedure TfrmMain.BtnStopClick(Sender: TObject);
begin
  StopRecording(False);
end;

procedure TfrmMain.BtnPushToTalkMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
    StartRecording(True);
end;

procedure TfrmMain.BtnPushToTalkMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    StopRecording(True);
    if FChkAutoTranscribe.Checked and (not FCancelRequested) then
      TranscribeSelectedFile;
  end;
end;

procedure TfrmMain.BtnTranscribeClick(Sender: TObject);
begin
  TranscribeSelectedFile;
end;

procedure TfrmMain.BtnCancelClick(Sender: TObject);
begin
  RequestCancel;
end;

procedure TfrmMain.BtnOpenFileClick(Sender: TObject);
begin
  OpenCurrentFile;
end;

procedure TfrmMain.BtnOpenFolderClick(Sender: TObject);
begin
  OpenCurrentFolder;
end;

procedure TfrmMain.BtnValidateBackendClick(Sender: TObject);
begin
  ApplyUIToComponents;
  UpdateBackendHint;
  if SelectedBackend = sbAuto then
    AddLog('Backend automático selecionado.')
  else
    AddLog('Backend selecionado: ' + SelectedBackendName);
  if IsOnlineBackend(SelectedBackend) and not FChkOnlineConsent.Checked then
    AddLog('Aviso: backend online selecionado sem consentimento marcado.');
end;

procedure TfrmMain.BtnRefreshHintClick(Sender: TObject);
begin
  UpdateBackendHint;
end;

procedure TfrmMain.BtnApplyConfigClick(Sender: TObject);
begin
  ApplyUIToComponents;
  UpdateBackendHint;
  SetState(FState, 'configuração aplicada');
  AddLog('Configuração aplicada às propriedades dos componentes.');
end;

procedure TfrmMain.BtnLoadDefaultsClick(Sender: TObject);
begin
  LoadComponentValuesToUI;
  UpdateBackendHint;
  AddLog('Padrões carregados.');
end;

procedure TfrmMain.BtnCopyTranscriptClick(Sender: TObject);
begin
  CopyTranscriptToClipboard;
end;

procedure TfrmMain.BtnClearResultClick(Sender: TObject);
begin
  FMemoTranscript.Clear;
  FMemoResultInfo.Clear;
  FLabelValidation.Caption := 'N/A';
  FLabelValidation.Font.Color := clDefault;
  AddLog('Resultado limpo.');
end;

procedure TfrmMain.BtnClearLogClick(Sender: TObject);
begin
  FMemoLog.Clear;
end;

procedure TfrmMain.TimerTick(Sender: TObject);
begin
  RefreshProgress;
end;

procedure TfrmMain.BackendComboChange(Sender: TObject);
begin
  UpdateBackendHint;
  UpdateOperationControls;
end;

end.
