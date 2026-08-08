unit main;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,
  Controls,
  Dialogs,
  Forms,
  StdCtrls,
  SysUtils,
  chatgpt,
  aillamacppruntime,
  aillamacppmodel,
  aillamacppserver;

type
  TfrmMain = class(TForm)
    btnAsk: TButton;
    ChatGPT: TCHATGPT;
    LlamaModel: TAILlamaCppModel;
    LlamaRuntime: TAILlamaCppRuntime;
    LlamaServer: TAILlamaCppServer;
    memResult: TMemo;
    OpenGGUFDialog: TOpenDialog;
    procedure btnAskClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ServerStarted(Sender: TObject);
  private
    FQuestionSent: Boolean;
    FSelfTestMode: Boolean;
    FSelfTestReport: string;
    procedure ConfigureDevelopmentRuntime;
    procedure SaveSelfTestReport(ASuccess: Boolean; const AResponse,
      AError: string; AElapsedMs: QWord);
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
  FQuestionSent := False;
  FSelfTestMode := (ParamCount >= 3) and
    SameText(ParamStr(1), '--self-test');
  if FSelfTestMode then
  begin
    LlamaModel.ModelFile := ParamStr(2);
    FSelfTestReport := ParamStr(3);
    LlamaServer.Port := 18081;
    if not LlamaServer.Start then
    begin
      SaveSelfTestReport(False, '', LlamaServer.LastError, 0);
      Application.Terminate;
    end;
  end;
end;

procedure TfrmMain.SaveSelfTestReport(ASuccess: Boolean;
  const AResponse, AError: string; AElapsedMs: QWord);
const
  QUESTION = 'Responda apenas: OK';
var
  LReport: TStringList;
begin
  if not FSelfTestMode then
    Exit;
  LReport := TStringList.Create;
  try
    LReport.Add('Sucesso=' + BoolToStr(ASuccess, True));
    LReport.Add('Prompt enviado=' + QUESTION);
    LReport.Add('Resposta recebida=' + AResponse);
    LReport.Add('TempoMs=' + IntToStr(AElapsedMs));
    LReport.Add('Modelo GGUF=' + LlamaModel.ModelFile);
    LReport.Add('Modelo API=' + UTF8Encode(ChatGPT.TipoModelo));
    LReport.Add('Endpoint=' + UTF8Encode(ChatGPT.LastURL));
    LReport.Add('Erro=' + AError);
    LReport.SaveToFile(FSelfTestReport);
  finally
    LReport.Free;
  end;
end;

procedure TfrmMain.btnAskClick(Sender: TObject);
begin
  if LlamaServer.Running then
  begin
    memResult.Lines.Add('O servidor ja esta em execucao.');
    Exit;
  end;
  if not OpenGGUFDialog.Execute then
    Exit;
  LlamaModel.ModelFile := OpenGGUFDialog.FileName;
  FQuestionSent := False;
  memResult.Lines.Add('Iniciando servidor...');
  if not LlamaServer.Start then
    memResult.Lines.Add('Falha: ' + LlamaServer.LastError);
end;

procedure TfrmMain.ServerStarted(Sender: TObject);
const
  QUESTION = 'Responda apenas: OK';
var
  LElapsedMs: QWord;
  LStartedAt: QWord;
  LSuccess: Boolean;
begin
  if FQuestionSent then
    Exit;
  FQuestionSent := True;
  LlamaServer.ConfigureChatGPT(ChatGPT);
  memResult.Lines.Add('Pergunta: ' + QUESTION);
  LStartedAt := GetTickCount64;
  LSuccess := ChatGPT.SendQuestion(QUESTION);
  LElapsedMs := GetTickCount64 - LStartedAt;
  if LSuccess then
    memResult.Lines.Add('Resposta: ' + UTF8Encode(ChatGPT.Response))
  else
    memResult.Lines.Add('Falha: ' + ChatGPT.LastError);
  if FSelfTestMode then
  begin
    SaveSelfTestReport(LSuccess, UTF8Encode(ChatGPT.Response),
      ChatGPT.LastError, LElapsedMs);
    Application.Terminate;
  end;
end;

end.
