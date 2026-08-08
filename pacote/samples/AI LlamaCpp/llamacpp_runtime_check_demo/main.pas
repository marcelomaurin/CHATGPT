unit main;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, StdCtrls, aillamacppruntime, aillamacpptypes;

type
  TfrmMain = class(TForm)
    btnValidateRuntime: TButton;
    LlamaRuntime: TAILlamaCppRuntime;
    memDiagnostics: TMemo;
    procedure btnValidateRuntimeClick(Sender: TObject);
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

procedure TfrmMain.btnValidateRuntimeClick(Sender: TObject);
const
  REQUIRED_LIBRARIES: array[0..3] of string = (
    AI_LLAMA_LIBRARY_FILENAME,
    AI_GGML_LIBRARY_FILENAME,
    AI_GGML_BASE_LIBRARY_FILENAME,
    AI_GGML_CPU_LIBRARY_FILENAME
  );
var
  I: Integer;
  LFileName: string;
  LVersion: string;
  LValid: Boolean;
begin
  LValid := LlamaRuntime.ValidateRuntime;

  memDiagnostics.Clear;
  memDiagnostics.Lines.Add('RuntimeRoot: ' + LlamaRuntime.RuntimeRoot);
  memDiagnostics.Lines.Add('BinPath: ' + LlamaRuntime.BinPath);
  memDiagnostics.Lines.Add('LibraryPath: ' + LlamaRuntime.LibraryPath);
  memDiagnostics.Lines.Add('CLI: ' + LlamaRuntime.GetCliPath + ' | Exists=' +
    BoolToStr(LlamaRuntime.IsCliAvailable, True));
  memDiagnostics.Lines.Add('Server: ' + LlamaRuntime.GetServerPath + ' | Exists=' +
    BoolToStr(LlamaRuntime.IsServerAvailable, True));
  memDiagnostics.Lines.Add('DLLs:');
  for I := Low(REQUIRED_LIBRARIES) to High(REQUIRED_LIBRARIES) do
  begin
    LFileName := IncludeTrailingPathDelimiter(LlamaRuntime.LibraryPath) +
      REQUIRED_LIBRARIES[I];
    memDiagnostics.Lines.Add('  ' + LFileName + ' | Exists=' +
      BoolToStr(FileExists(LFileName), True));
  end;
  memDiagnostics.Lines.Add('Result: ' + BoolToStr(LValid, True));
  if not LValid then
    memDiagnostics.Lines.Add('Error: ' + LlamaRuntime.LastRuntimeError);

  memDiagnostics.Lines.Add('llama.cpp version:');
  LVersion := LlamaRuntime.GetVersion;
  if LVersion <> '' then
    memDiagnostics.Lines.Add(LVersion)
  else
    memDiagnostics.Lines.Add('N/A - ' + LlamaRuntime.LastRuntimeError);
end;

end.
