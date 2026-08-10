unit main;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,
  Controls,
  Dialogs,
  ExtCtrls,
  Forms,
  StdCtrls,
  SysUtils,
  aibase,
  aillamacppruntime,
  aillamacppmodel,
  aillamacppserver;

type
  TfrmMain = class(TForm)
    btnStart: TButton;
    btnStop: TButton;
    LlamaModel: TAILlamaCppModel;
    LlamaRuntime: TAILlamaCppRuntime;
    LlamaServer: TAILlamaCppServer;
    lblBaseURL: TLabel;
    lblRunning: TLabel;
    memLog: TMemo;
    OpenGGUFDialog: TOpenDialog;
    StatusTimer: TTimer;
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ServerError(Sender: TObject; const Message: string);
    procedure ServerLog(Sender: TObject; Level: TAILogLevel;
      const Message: string);
    procedure ServerStarted(Sender: TObject);
    procedure StatusTimerTimer(Sender: TObject);
  private
    FSelfTestMode: Boolean;
    FSelfTestReport: string;
    FSelfTestStartedAt: QWord;
    procedure ConfigureDevelopmentRuntime;
    procedure FinishSelfTest(ARunning, AHealth: Boolean;
      const AError: string);
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
  if not DirectoryExists(LRuntimeRoot) then
    Exit;
  LlamaRuntime.RuntimeRoot := LRuntimeRoot;
  LlamaRuntime.BinPath := IncludeTrailingPathDelimiter(LRuntimeRoot) + 'bin';
  LlamaRuntime.LibraryPath := IncludeTrailingPathDelimiter(LRuntimeRoot) + 'dll';
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  ConfigureDevelopmentRuntime;
  lblBaseURL.Caption := 'BaseURL: ' + LlamaServer.BaseURL;
  FSelfTestMode := (ParamCount >= 3) and
    SameText(ParamStr(1), '--self-test');
  if FSelfTestMode then
  begin
    LlamaModel.ModelFile := ParamStr(2);
    FSelfTestReport := ParamStr(3);
    LlamaServer.Port := 18080;
    FSelfTestStartedAt := GetTickCount64;
    if not LlamaServer.Start then
      FinishSelfTest(False, False, LlamaServer.LastError);
  end;
end;

procedure TfrmMain.FinishSelfTest(ARunning, AHealth: Boolean;
  const AError: string);
var
  LReport: TStringList;
begin
  if not FSelfTestMode then
    Exit;
  FSelfTestMode := False;
  LReport := TStringList.Create;
  try
    LReport.Add('Server Running=' + BoolToStr(ARunning, True));
    LReport.Add('HealthCheck=' + BoolToStr(AHealth, True));
    LReport.Add('BaseURL=' + LlamaServer.BaseURL);
    LReport.Add('Model=' + LlamaModel.ModelFile);
    LReport.Add('LastError=' + AError);
    LReport.SaveToFile(FSelfTestReport);
  finally
    LReport.Free;
  end;
  LlamaServer.Stop;
  Application.Terminate;
end;

procedure TfrmMain.btnStartClick(Sender: TObject);
begin
  if LlamaModel.ModelFile = '' then
  begin
    if not OpenGGUFDialog.Execute then
      Exit;
    LlamaModel.ModelFile := OpenGGUFDialog.FileName;
  end;
  memLog.Lines.Add('Iniciando ' + LlamaServer.BaseURL + '...');
  if not LlamaServer.Start then
    memLog.Lines.Add('Falha: ' + LlamaServer.LastError);
end;

procedure TfrmMain.btnStopClick(Sender: TObject);
begin
  memLog.Lines.Add('Encerrando servidor...');
  LlamaServer.Stop;
end;

procedure TfrmMain.ServerLog(Sender: TObject; Level: TAILogLevel;
  const Message: string);
const
  LOG_LEVEL_NAMES: array[TAILogLevel] of string =
    ('DEBUG', 'INFO', 'AVISO', 'ERRO');
begin
  memLog.Lines.Add('[' + LOG_LEVEL_NAMES[Level] + '] ' + Message);
end;

procedure TfrmMain.ServerError(Sender: TObject; const Message: string);
begin
  memLog.Lines.Add('[STDERR] ' + Message);
end;

procedure TfrmMain.ServerStarted(Sender: TObject);
begin
  memLog.Lines.Add('Servidor pronto.');
end;

procedure TfrmMain.StatusTimerTimer(Sender: TObject);
var
  LHealth: Boolean;
begin
  lblRunning.Caption := 'Running: ' + BoolToStr(LlamaServer.Running, True);
  lblBaseURL.Caption := 'BaseURL: ' + LlamaServer.BaseURL;
  if FSelfTestMode then
  begin
    if not LlamaServer.Running then
      FinishSelfTest(False, False, LlamaServer.LastError)
    else
    begin
      LHealth := LlamaServer.HealthCheck;
      if LHealth then
        FinishSelfTest(True, True, '')
      else if GetTickCount64 - FSelfTestStartedAt >= 120000 then
        FinishSelfTest(True, False, LlamaServer.LastError);
    end;
  end;
end;

end.
