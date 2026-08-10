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
  aillamacppruntime,
  aillamacppmodel,
  aillamacppserver;

type
  TfrmMain = class(TForm)
    btnSelectModel: TButton;
    btnShowParameters: TButton;
    edtModelFile: TEdit;
    memValidation: TMemo;
    LlamaModel: TAILlamaCppModel;
    LlamaRuntime: TAILlamaCppRuntime;
    LlamaServer: TAILlamaCppServer;
    OpenGGUFDialog: TOpenDialog;
    procedure btnSelectModelClick(Sender: TObject);
    procedure btnShowParametersClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    procedure ConfigureDevelopmentRuntime;
    procedure RunLoadCycleSelfTest(const AModelFile, AReportFile: string);
    procedure ShowModelValidation;
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

procedure TfrmMain.RunLoadCycleSelfTest(const AModelFile,
  AReportFile: string);
const
  LOAD_CYCLES = 5;
var
  I: Integer;
  LLoadResult: Boolean;
  LPassed: Boolean;
  LReport: TStringList;
begin
  LReport := TStringList.Create;
  try
    LPassed := True;
    LlamaModel.ModelFile := AModelFile;
    LReport.Add('Model: ' + AModelFile);
    LReport.Add('Runtime: ' + LlamaRuntime.RuntimeRoot);
    LReport.Add('Cycles requested: ' + IntToStr(LOAD_CYCLES));
    for I := 1 to LOAD_CYCLES do
    begin
      LLoadResult := LlamaModel.Load;
      LReport.Add(Format('Cycle %d load: %s',
        [I, BoolToStr(LLoadResult, True)]));
      LReport.Add(Format('Cycle %d Loaded after load: %s',
        [I, BoolToStr(LlamaModel.Loaded, True)]));
      if not LLoadResult then
      begin
        LReport.Add('Error: ' + LlamaModel.LastError);
        LPassed := False;
        Break;
      end;
      LlamaModel.Unload;
      LReport.Add(Format('Cycle %d Loaded after unload: %s',
        [I, BoolToStr(LlamaModel.Loaded, True)]));
      if LlamaModel.Loaded then
      begin
        LPassed := False;
        Break;
      end;
    end;
    LlamaModel.Unload;
    LReport.Add('Passed: ' + BoolToStr(LPassed, True));
    LReport.SaveToFile(AReportFile);
  finally
    LReport.Free;
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  ConfigureDevelopmentRuntime;
  if (ParamCount >= 3) and SameText(ParamStr(1), '--self-test') then
  begin
    RunLoadCycleSelfTest(ParamStr(2), ParamStr(3));
    Application.Terminate;
  end;
end;

procedure TfrmMain.btnSelectModelClick(Sender: TObject);
begin
  if not OpenGGUFDialog.Execute then
    Exit;
  edtModelFile.Text := OpenGGUFDialog.FileName;
  LlamaModel.ModelFile := OpenGGUFDialog.FileName;
  ShowModelValidation;
end;

procedure TfrmMain.ShowModelValidation;
var
  LExists: Boolean;
  LSize: Int64;
  LStream: TFileStream;
begin
  LExists := FileExists(LlamaModel.ModelFile);
  LSize := 0;
  if LExists then
  begin
    LStream := TFileStream.Create(LlamaModel.ModelFile, fmOpenRead or fmShareDenyNone);
    try
      LSize := LStream.Size;
    finally
      LStream.Free;
    end;
  end;

  memValidation.Clear;
  memValidation.Lines.Add('Arquivo: ' + LlamaModel.ModelFile);
  memValidation.Lines.Add(Format('Tamanho: %d bytes', [LSize]));
  memValidation.Lines.Add('Existe: ' + BoolToStr(LExists, True));
  memValidation.Lines.Add('Extensao: ' + ExtractFileExt(LlamaModel.ModelFile));
  if LlamaModel.ValidateModelFile then
    memValidation.Lines.Add('Validacao: valida')
  else
    memValidation.Lines.Add('Validacao: ' + LlamaModel.LastError);
end;

procedure TfrmMain.btnShowParametersClick(Sender: TObject);
var
  I: Integer;
  LCommandLine: string;
  LParameters: TStringList;
  LValue: string;
begin
  LParameters := TStringList.Create;
  try
    LlamaServer.BuildParameters(LParameters);
    LCommandLine := LlamaRuntime.GetServerPath;
    for I := 0 to LParameters.Count - 1 do
    begin
      LValue := LParameters[I];
      if Pos(' ', LValue) > 0 then
        LValue := '"' + LValue + '"';
      LCommandLine := LCommandLine + ' ' + LValue;
    end;
    memValidation.Lines.Add('');
    memValidation.Lines.Add('Linha do servidor:');
    memValidation.Lines.Add(LCommandLine);
  finally
    LParameters.Free;
  end;
end;

end.
