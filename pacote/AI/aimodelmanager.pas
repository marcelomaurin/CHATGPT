unit aimodelmanager;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpclient, opensslsockets, fpjson, jsonparser, aibase, airuntimepaths;

type
  TAIModelInfo = record
    Name: string;
    Version: string;
    Language: string;
    Description: string;
    URL: string;
    FileName: string;
    SizeBytes: Int64;
    IsDownloaded: Boolean;
  end;

  TAIModelInfoArray = array of TAIModelInfo;

  TAIModelProgressEvent = procedure(
    Sender: TObject;
    const AModelName: string;
    const ABytesDownloaded, ATotalBytes: Int64
  ) of object;

  { TAIModelManager }

  TAIModelManager = class(TAIBaseComponent)
  private
    FRegistryURL: string;
    FModelsDir: string;
    FModels: TAIModelInfoArray;
    FOnProgress: TAIModelProgressEvent;
    procedure SetModelsDir(const AValue: string);
    function GetModelCount: Integer;
    function GetModel(AIndex: Integer): TAIModelInfo;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function GetDefaultModelsDir: string;
    function FetchRegistry(const AURL: string = ''): Boolean;
    function ParseRegistryJSON(const AJSONText: string): Boolean;
    function DownloadModel(const AModelName: string): Boolean;
    function IsModelInstalled(const AModelName: string): Boolean;
    function GetModelPath(const AModelName: string): string;
    function FindModel(const AModelName: string; out AInfo: TAIModelInfo): Boolean;

    property RegistryURL: string read FRegistryURL write FRegistryURL;
    property ModelsDir: string read FModelsDir write SetModelsDir;
    property ModelCount: Integer read GetModelCount;
    property Models[AIndex: Integer]: TAIModelInfo read GetModel;
    property OnProgress: TAIModelProgressEvent read FOnProgress write FOnProgress;
  end;

implementation

constructor TAIModelManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FRegistryURL := 'https://raw.githubusercontent.com/marcelomaurin/CHATGPT/main/dicionario/models_registry.json';
  FModelsDir := GetDefaultModelsDir;
  SetLength(FModels, 0);
end;

destructor TAIModelManager.Destroy;
begin
  SetLength(FModels, 0);
  inherited Destroy;
end;

function TAIModelManager.GetDefaultModelsDir: string;
begin
  Result := IncludeTrailingPathDelimiter(GetAppConfigDir(False)) + 'models' + PathDelim;
  if not DirectoryExists(Result) then
    ForceDirectories(Result);
end;

procedure TAIModelManager.SetModelsDir(const AValue: string);
begin
  if FModelsDir = AValue then
    Exit;

  FModelsDir := AValue;
  if (FModelsDir <> '') and not DirectoryExists(FModelsDir) then
    ForceDirectories(FModelsDir);
end;

function TAIModelManager.GetModelCount: Integer;
begin
  Result := Length(FModels);
end;

function TAIModelManager.GetModel(AIndex: Integer): TAIModelInfo;
begin
  if (AIndex >= 0) and (AIndex < Length(FModels)) then
    Result := FModels[AIndex]
  else
  begin
    FillChar(Result, SizeOf(Result), 0);
  end;
end;

function TAIModelManager.ParseRegistryJSON(const AJSONText: string): Boolean;
var
  Data: TJSONData;
  Obj: TJSONObject;
  Arr: TJSONArray;
  I: Integer;
  ItemObj: TJSONObject;
begin
  Result := False;
  SetLength(FModels, 0);
  if Trim(AJSONText) = '' then
    Exit;

  try
    Data := GetJSON(AJSONText);
    try
      if Data is TJSONObject then
      begin
        Obj := TJSONObject(Data);
        if Obj.Find('models') is TJSONArray then
        begin
          Arr := TJSONArray(Obj.Find('models'));
          SetLength(FModels, Arr.Count);
          for I := 0 to Arr.Count - 1 do
          begin
            if Arr.Items[I] is TJSONObject then
            begin
              ItemObj := TJSONObject(Arr.Items[I]);
              FModels[I].Name := ItemObj.Get('name', '');
              FModels[I].Version := ItemObj.Get('version', '');
              FModels[I].Language := ItemObj.Get('language', '');
              FModels[I].Description := ItemObj.Get('description', '');
              FModels[I].URL := ItemObj.Get('url', '');
              FModels[I].FileName := ItemObj.Get('file_name', '');
              FModels[I].SizeBytes := ItemObj.Get('size_bytes', Int64(0));
              FModels[I].IsDownloaded := IsModelInstalled(FModels[I].Name);
            end;
          end;
          Result := True;
        end;
      end;
    finally
      Data.Free;
    end;
  except
    on E: Exception do
      SetError('Erro ao interpretar JSON de modelos: ' + E.Message);
  end;
end;

function TAIModelManager.FetchRegistry(const AURL: string): Boolean;
var
  TargetURL: string;
  Client: TFPHTTPClient;
  ResponseText: string;
begin
  Result := False;
  ClearError;

  if Trim(AURL) <> '' then
    TargetURL := AURL
  else
    TargetURL := FRegistryURL;

  Client := TFPHTTPClient.Create(nil);
  try
    try
      ResponseText := Client.Get(TargetURL);
      Result := ParseRegistryJSON(ResponseText);
    except
      on E: Exception do
      begin
        SetError('Erro ao baixar catalogo de modelos: ' + E.Message);
        Result := False;
      end;
    end;
  finally
    Client.Free;
  end;
end;

function TAIModelManager.IsModelInstalled(const AModelName: string): Boolean;
var
  FilePath: string;
begin
  FilePath := GetModelPath(AModelName);
  Result := (FilePath <> '') and FileExists(FilePath);
end;

function TAIModelManager.GetModelPath(const AModelName: string): string;
var
  I: Integer;
begin
  Result := '';
  for I := 0 to Length(FModels) - 1 do
  begin
    if SameText(FModels[I].Name, AModelName) then
    begin
      if FModels[I].FileName <> '' then
        Result := FModelsDir + FModels[I].FileName
      else
        Result := FModelsDir + AModelName + '.bin';
      Exit;
    end;
  end;
  if AModelName <> '' then
    Result := FModelsDir + AModelName + '.bin';
end;

function TAIModelManager.FindModel(const AModelName: string; out AInfo: TAIModelInfo): Boolean;
var
  I: Integer;
begin
  Result := False;
  FillChar(AInfo, SizeOf(AInfo), 0);
  for I := 0 to Length(FModels) - 1 do
  begin
    if SameText(FModels[I].Name, AModelName) then
    begin
      AInfo := FModels[I];
      Exit(True);
    end;
  end;
end;

function TAIModelManager.DownloadModel(const AModelName: string): Boolean;
var
  Info: TAIModelInfo;
  Client: TFPHTTPClient;
  TargetFile: string;
  FileStream: TFileStream;
begin
  Result := False;
  ClearError;

  FillChar(Info, SizeOf(Info), 0);
  if not FindModel(AModelName, Info) then
  begin
    SetError('Modelo nao encontrado no registro: ' + AModelName);
    Exit;
  end;

  TargetFile := GetModelPath(AModelName);
  if not DirectoryExists(ExtractFilePath(TargetFile)) then
    ForceDirectories(ExtractFilePath(TargetFile));

  Client := TFPHTTPClient.Create(nil);
  FileStream := TFileStream.Create(TargetFile, fmCreate);
  try
    try
      Client.Get(Info.URL, FileStream);
      Result := FileExists(TargetFile) and (FileStream.Size > 0);
      if Result then
      begin
        Log(llInfo, 'Modelo baixado com sucesso: ' + TargetFile);
      end;
    except
      on E: Exception do
      begin
        SetError('Erro ao baixar modelo ' + AModelName + ': ' + E.Message);
        Result := False;
      end;
    end;
  finally
    FileStream.Free;
    Client.Free;
  end;
end;

end.
