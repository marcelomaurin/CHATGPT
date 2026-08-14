unit main;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,
  Dialogs,
  ExtCtrls,
  Forms,
  StdCtrls,
  SysUtils,
  aillamacppinference,
  aillamacppmodel,
  aillamacppruntime;

type
  TfrmMain = class(TForm)
    btnCancel: TButton;
    btnGenerate: TButton;
    btnSelectModel: TButton;
    edtModelFile: TEdit;
    edtPrompt: TEdit;
    lblModel: TLabel;
    lblPrompt: TLabel;
    lblStatus: TLabel;
    LlamaInference: TAILlamaCppInference;
    LlamaModel: TAILlamaCppModel;
    LlamaRuntime: TAILlamaCppRuntime;
    memOutput: TMemo;
    OpenGGUFDialog: TOpenDialog;
    SelfTestTimer: TTimer;
    procedure btnCancelClick(Sender: TObject);
    procedure btnGenerateClick(Sender: TObject);
    procedure btnSelectModelClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure LlamaInferenceError(Sender: TObject;
      const ErrorMessage: string);
    procedure LlamaInferenceFinish(Sender: TObject);
    procedure LlamaInferenceStart(Sender: TObject);
    procedure LlamaInferenceToken(Sender: TObject; const Token: string);
    procedure SelfTestTimerTimer(Sender: TObject);
  private
    FReportFile: string;
    FSelfTest: Boolean;
    FStarted: Boolean;
    FTokenCount: Integer;
    procedure ConfigureDevelopmentRuntime;
    procedure SaveSelfTestReport(APassed: Boolean;
      const AError: string = '');
    procedure StartGeneration;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

procedure TfrmMain.ConfigureDevelopmentRuntime;
var
  LRuntimeRoot: string;
begin
  LRuntimeRoot := ExpandFileName(IncludeTrailingPathDelimiter(
    ExtractFilePath(Application.ExeName)) + '..\..\..\..\runtime\windows-x64');
  LlamaRuntime.RuntimeRoot := LRuntimeRoot;
  LlamaRuntime.BinPath := IncludeTrailingPathDelimiter(LRuntimeRoot) + 'bin';
  LlamaRuntime.LibraryPath := IncludeTrailingPathDelimiter(LRuntimeRoot) + 'dll';
end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  LDefaultModel: string;
begin
  ConfigureDevelopmentRuntime;
  LDefaultModel := IncludeTrailingPathDelimiter(
    GetEnvironmentVariable('LOCALAPPDATA')) +
    'Maurinsoft\CHATGPT\models\qwen2-0_5b-instruct-q2_k.gguf';
  if FileExists(LDefaultModel) then
    edtModelFile.Text := LDefaultModel;

  FSelfTest := (ParamCount >= 3) and
    SameText(ParamStr(1), '--self-test');
  if FSelfTest then
  begin
    edtModelFile.Text := ParamStr(2);
    FReportFile := ParamStr(3);
    edtPrompt.Text := 'Escreva os numeros de 1 a 5, separados por virgula.';
    SelfTestTimer.Enabled := True;
    StartGeneration;
  end;
end;

procedure TfrmMain.StartGeneration;
begin
  LlamaModel.ModelFile := edtModelFile.Text;
  memOutput.Clear;
  FStarted := False;
  FTokenCount := 0;
  lblStatus.Caption := 'Preparando...';
  btnGenerate.Enabled := False;
  btnCancel.Enabled := True;
  if not LlamaInference.GenerateAsync(edtPrompt.Text) then
    LlamaInferenceError(LlamaInference, LlamaInference.LastError);
end;

procedure TfrmMain.btnGenerateClick(Sender: TObject);
begin
  StartGeneration;
end;

procedure TfrmMain.btnCancelClick(Sender: TObject);
begin
  LlamaInference.Cancel;
  lblStatus.Caption := 'Cancelando...';
end;

procedure TfrmMain.btnSelectModelClick(Sender: TObject);
begin
  if OpenGGUFDialog.Execute then
    edtModelFile.Text := OpenGGUFDialog.FileName;
end;

procedure TfrmMain.LlamaInferenceStart(Sender: TObject);
begin
  FStarted := True;
  lblStatus.Caption := 'Gerando...';
end;

procedure TfrmMain.LlamaInferenceToken(Sender: TObject;
  const Token: string);
begin
  Inc(FTokenCount);
  memOutput.SelStart := Length(memOutput.Text);
  memOutput.SelText := Token;
end;

procedure TfrmMain.LlamaInferenceFinish(Sender: TObject);
begin
  SelfTestTimer.Enabled := False;
  lblStatus.Caption := 'Concluido';
  btnGenerate.Enabled := True;
  btnCancel.Enabled := False;
  if FSelfTest then
  begin
    SaveSelfTestReport(FStarted and (FTokenCount > 0) and
      (LlamaInference.LastResult <> ''));
    Application.Terminate;
  end;
end;

procedure TfrmMain.LlamaInferenceError(Sender: TObject;
  const ErrorMessage: string);
begin
  SelfTestTimer.Enabled := False;
  lblStatus.Caption := 'Erro: ' + ErrorMessage;
  btnGenerate.Enabled := True;
  btnCancel.Enabled := False;
  if FSelfTest then
  begin
    SaveSelfTestReport(False, ErrorMessage);
    Application.Terminate;
  end
  else
    MessageDlg('llama.cpp', ErrorMessage, mtError, [mbOK], 0);
end;

procedure TfrmMain.SelfTestTimerTimer(Sender: TObject);
begin
  LlamaInference.Cancel;
  SaveSelfTestReport(False, 'Streaming self-test timeout.');
  Application.Terminate;
end;

procedure TfrmMain.SaveSelfTestReport(APassed: Boolean;
  const AError: string);
var
  LReport: TStringList;
begin
  LReport := TStringList.Create;
  try
    LReport.Add('Model: ' + edtModelFile.Text);
    LReport.Add('Prompt: ' + edtPrompt.Text);
    LReport.Add('OnStart: ' + BoolToStr(FStarted, True));
    LReport.Add('Token callbacks: ' + IntToStr(FTokenCount));
    LReport.Add('Response: ' + LlamaInference.LastResult);
    LReport.Add('Memo matches response: ' + BoolToStr(
      memOutput.Text = LlamaInference.LastResult, True));
    if AError <> '' then
      LReport.Add('Error: ' + AError);
    LReport.Add('Passed: ' + BoolToStr(APassed, True));
    LReport.SaveToFile(FReportFile);
  finally
    LReport.Free;
  end;
end;

end.
