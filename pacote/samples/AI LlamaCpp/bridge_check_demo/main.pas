unit main;

{$mode ObjFPC}{$H+}

interface

uses
  Classes,
  Forms,
  StdCtrls,
  SysUtils,
  aillamacppapi,
  aillamacppruntime;

type
  TfrmMain = class(TForm)
    LlamaRuntime: TAILlamaCppRuntime;
    memResult: TMemo;
    procedure FormCreate(Sender: TObject);
  private
    FAPI: TAILlamaCppAPI;
    procedure CheckBridge;
    procedure ConfigureDevelopmentRuntime;
  public
    destructor Destroy; override;
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

procedure TfrmMain.CheckBridge;
begin
  memResult.Clear;
  memResult.Lines.Add('DLL path: ' + LlamaRuntime.LibraryPath);
  if FAPI.Load(LlamaRuntime.LibraryPath) then
  begin
    memResult.Lines.Add('Load: True');
    memResult.Lines.Add('Bridge API version: ' + FAPI.Version);
  end
  else
  begin
    memResult.Lines.Add('Load: False');
    memResult.Lines.Add('Error: ' + FAPI.LastError);
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  ConfigureDevelopmentRuntime;
  FAPI := TAILlamaCppAPI.Create;
  CheckBridge;
  if (ParamCount >= 2) and SameText(ParamStr(1), '--self-test') then
  begin
    memResult.Lines.SaveToFile(ParamStr(2));
    Application.Terminate;
  end;
end;

destructor TfrmMain.Destroy;
begin
  FAPI.Free;
  inherited Destroy;
end;

end.
