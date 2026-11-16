unit aivideoproviders;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, StrUtils, fphttpclient, fpjson, jsonparser, base64, opensslsockets,
  aiprocessrunner;

type
  TAIVideoProviderKind = (
    vidOpenAISora,
    vidOpenAICompatible,
    vidGoogleVeo,
    vidRunway,
    vidKling,
    vidLuma,
    vidComfyUIVideo,
    vidLocalFFmpegCPU
  );

  TAIVideoProviderConfig = record
    Endpoint: string;
    Token: string;
    Model: string;
    Prompt: string;
    SourceImageFile: string;
    AudioFile: string;
    OutputFile: string;
    FfmpegPath: string;
    Width: Integer;
    Height: Integer;
    FPS: Integer;
    DurationSec: Integer;
    UseGPU: Boolean;
    Timeout: Integer;
  end;

  IAIVideoProvider = interface
    ['{7E11C6A8-8432-4C94-9C43-8A1F5B78D031}']
    function GetProviderID: string;
    function GetProviderName: string;
    function GetDefaultEndpoint: string;
    function GetLastError: string;
    function Generate(const AConfig: TAIVideoProviderConfig;
      out AOutputFile: string): Boolean;
    procedure Cancel;
  end;

  TAIVideoProviderBase = class(TInterfacedObject, IAIVideoProvider)
  private
    FProviderID: string;
    FProviderName: string;
    FDefaultEndpoint: string;
    FLastError: string;
    FCancelled: Boolean;
    FActiveHTTP: TFPHTTPClient;
    FLock: TRTLCriticalSection;
  protected
    procedure SetIdentity(const AID, AName, AEndpoint: string);
    procedure SetLastError(const Msg: string);
    function IsCancelled: Boolean;
    function HttpPostJsonRaw(const AUrl, ABody: string; AHeaders: TStrings;
      ATimeoutMs: Integer; out ARawBytes: RawByteString; out AHttpCode: Integer): Boolean;
    function HttpGetRaw(const AUrl: string; AHeaders: TStrings;
      ATimeoutMs: Integer; out ARawBytes: RawByteString; out AHttpCode: Integer): Boolean;
    function SaveBytesToFile(const ARaw: RawByteString; const AFileName: string): Boolean;
    function FileToDataUri(const AFileName: string): string;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    function GetProviderID: string;
    function GetProviderName: string;
    function GetDefaultEndpoint: string;
    function GetLastError: string;
    function Generate(const AConfig: TAIVideoProviderConfig;
      out AOutputFile: string): Boolean; virtual; abstract;
    procedure Cancel; virtual;
  end;

  TAIVideoOpenAICompatibleProvider = class(TAIVideoProviderBase)
  public
    constructor CreateWithMeta(const AID, AName, AEndpoint: string);
    constructor Create; override;
    function Generate(const AConfig: TAIVideoProviderConfig;
      out AOutputFile: string): Boolean; override;
  end;

  TAIVideoGoogleVeoProvider = class(TAIVideoProviderBase)
  public
    constructor Create; override;
    function Generate(const AConfig: TAIVideoProviderConfig;
      out AOutputFile: string): Boolean; override;
  end;

  TAIVideoRunwayProvider = class(TAIVideoProviderBase)
  public
    constructor Create; override;
    function Generate(const AConfig: TAIVideoProviderConfig;
      out AOutputFile: string): Boolean; override;
  end;

  TAIVideoLumaProvider = class(TAIVideoProviderBase)
  public
    constructor Create; override;
    function Generate(const AConfig: TAIVideoProviderConfig;
      out AOutputFile: string): Boolean; override;
  end;

  TAIVideoKlingProvider = class(TAIVideoProviderBase)
  public
    constructor Create; override;
    function Generate(const AConfig: TAIVideoProviderConfig;
      out AOutputFile: string): Boolean; override;
  end;

  TAIVideoComfyUIProvider = class(TAIVideoProviderBase)
  public
    constructor Create; override;
    function Generate(const AConfig: TAIVideoProviderConfig;
      out AOutputFile: string): Boolean; override;
  end;

  TAIVideoFFmpegCPUProvider = class(TAIVideoProviderBase)
  private
    FRunner: TAIProcessRunner;
  public
    constructor Create; override;
    destructor Destroy; override;
    function Generate(const AConfig: TAIVideoProviderConfig;
      out AOutputFile: string): Boolean; override;
    procedure Cancel; override;
  end;

  TAIVideoProviderFactory = class
  public
    class function CreateProvider(AKind: TAIVideoProviderKind): IAIVideoProvider; static;
    class function KindFromName(const AName: string): TAIVideoProviderKind; static;
  end;

procedure InitAIVideoProviderConfig(out AConfig: TAIVideoProviderConfig);
function AIVideoProviderKindName(AKind: TAIVideoProviderKind): string;

implementation

procedure InitAIVideoProviderConfig(out AConfig: TAIVideoProviderConfig);
begin
  FillChar(AConfig, SizeOf(AConfig), 0);
  AConfig.Width := 1280;
  AConfig.Height := 720;
  AConfig.FPS := 24;
  AConfig.DurationSec := 5;
  AConfig.UseGPU := False;
  AConfig.Timeout := 300000;
end;

function AIVideoProviderKindName(AKind: TAIVideoProviderKind): string;
begin
  case AKind of
    vidOpenAISora: Result := 'OpenAI-Sora';
    vidOpenAICompatible: Result := 'OpenAI-compatible';
    vidGoogleVeo: Result := 'Google-Veo';
    vidRunway: Result := 'Runway';
    vidKling: Result := 'Kling';
    vidLuma: Result := 'Luma';
    vidComfyUIVideo: Result := 'ComfyUI-Video';
    vidLocalFFmpegCPU: Result := 'FFmpeg-CPU';
  end;
end;

function TrimBaseUrl(const AUrl: string): string;
begin
  Result := Trim(AUrl);
  while (Result <> '') and (Result[Length(Result)] = '/') do
    Delete(Result, Length(Result), 1);
end;

{ TAIVideoProviderBase }

constructor TAIVideoProviderBase.Create;
begin
  inherited Create;
  InitCriticalSection(FLock);
end;

destructor TAIVideoProviderBase.Destroy;
begin
  DoneCriticalSection(FLock);
  inherited Destroy;
end;

procedure TAIVideoProviderBase.SetIdentity(const AID, AName, AEndpoint: string);
begin
  FProviderID := AID;
  FProviderName := AName;
  FDefaultEndpoint := AEndpoint;
end;

procedure TAIVideoProviderBase.SetLastError(const Msg: string);
begin
  FLastError := Msg;
end;

function TAIVideoProviderBase.IsCancelled: Boolean;
begin
  EnterCriticalSection(FLock);
  try Result := FCancelled; finally LeaveCriticalSection(FLock); end;
end;

function TAIVideoProviderBase.GetProviderID: string; begin Result := FProviderID; end;
function TAIVideoProviderBase.GetProviderName: string; begin Result := FProviderName; end;
function TAIVideoProviderBase.GetDefaultEndpoint: string; begin Result := FDefaultEndpoint; end;
function TAIVideoProviderBase.GetLastError: string; begin Result := FLastError; end;

procedure TAIVideoProviderBase.Cancel;
begin
  EnterCriticalSection(FLock);
  try
    FCancelled := True;
    if FActiveHTTP <> nil then FActiveHTTP.Terminate;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TAIVideoProviderBase.HttpPostJsonRaw(const AUrl, ABody: string;
  AHeaders: TStrings; ATimeoutMs: Integer; out ARawBytes: RawByteString;
  out AHttpCode: Integer): Boolean;
var
  Client: TFPHTTPClient;
  ReqStream, RespStream: TStringStream;
  I: Integer;
begin
  Result := False;
  ARawBytes := '';
  AHttpCode := 0;
  if IsCancelled then begin SetLastError('Operacao cancelada.'); Exit; end;

  Client := TFPHTTPClient.Create(nil);
  ReqStream := TStringStream.Create(ABody, TEncoding.UTF8);
  RespStream := TStringStream.Create('');
  try
    Client.AllowRedirect := True;
    Client.ConnectTimeout := 15000;
    if ATimeoutMs > 0 then Client.IOTimeout := ATimeoutMs;
    Client.AddHeader('Content-Type', 'application/json');
    if AHeaders <> nil then
      for I := 0 to AHeaders.Count - 1 do
        Client.AddHeader(AHeaders.Names[I], AHeaders.ValueFromIndex[I]);

    EnterCriticalSection(FLock);
    try FActiveHTTP := Client; finally LeaveCriticalSection(FLock); end;
    try
      Client.RequestBody := ReqStream;
      Client.Post(AUrl, RespStream);
      AHttpCode := Client.ResponseStatusCode;
      ARawBytes := RespStream.DataString;
      Result := (AHttpCode >= 200) and (AHttpCode < 300);
      if not Result then
        SetLastError(Format('HTTP %d: %s', [AHttpCode, Copy(ARawBytes, 1, 300)]));
    except
      on E: Exception do
        SetLastError('Erro HTTP (' + AUrl + '): ' + E.Message);
    end;
  finally
    EnterCriticalSection(FLock);
    try FActiveHTTP := nil; finally LeaveCriticalSection(FLock); end;
    RespStream.Free;
    ReqStream.Free;
    Client.Free;
  end;
end;

function TAIVideoProviderBase.HttpGetRaw(const AUrl: string; AHeaders: TStrings;
  ATimeoutMs: Integer; out ARawBytes: RawByteString; out AHttpCode: Integer): Boolean;
var
  Client: TFPHTTPClient;
  RespStream: TStringStream;
  I: Integer;
begin
  Result := False;
  ARawBytes := '';
  AHttpCode := 0;
  Client := TFPHTTPClient.Create(nil);
  RespStream := TStringStream.Create('');
  try
    Client.AllowRedirect := True;
    Client.ConnectTimeout := 15000;
    if ATimeoutMs > 0 then Client.IOTimeout := ATimeoutMs;
    if AHeaders <> nil then
      for I := 0 to AHeaders.Count - 1 do
        Client.AddHeader(AHeaders.Names[I], AHeaders.ValueFromIndex[I]);
    try
      Client.Get(AUrl, RespStream);
      AHttpCode := Client.ResponseStatusCode;
      ARawBytes := RespStream.DataString;
      Result := (AHttpCode >= 200) and (AHttpCode < 300);
      if not Result then
        SetLastError(Format('HTTP %d: %s', [AHttpCode, Copy(ARawBytes, 1, 300)]));
    except
      on E: Exception do
        SetLastError('Erro HTTP GET (' + AUrl + '): ' + E.Message);
    end;
  finally
    RespStream.Free;
    Client.Free;
  end;
end;

function TAIVideoProviderBase.SaveBytesToFile(const ARaw: RawByteString;
  const AFileName: string): Boolean;
var
  FS: TFileStream;
begin
  Result := False;
  if (AFileName = '') or (Length(ARaw) = 0) then Exit;
  ForceDirectories(ExtractFileDir(ExpandFileName(AFileName)));
  FS := TFileStream.Create(AFileName, fmCreate);
  try
    FS.WriteBuffer(ARaw[1], Length(ARaw));
    Result := True;
  finally
    FS.Free;
  end;
end;

function TAIVideoProviderBase.FileToDataUri(const AFileName: string): string;
var
  FS: TFileStream;
  Raw: RawByteString;
  Ext, Mime: string;
begin
  Result := '';
  if not FileExists(AFileName) then Exit;
  Ext := LowerCase(ExtractFileExt(AFileName));
  if Ext = '.png' then Mime := 'image/png'
  else if (Ext = '.jpg') or (Ext = '.jpeg') then Mime := 'image/jpeg'
  else Mime := 'image/bmp';
  FS := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    SetLength(Raw, FS.Size);
    if FS.Size > 0 then FS.ReadBuffer(Raw[1], FS.Size);
    Result := 'data:' + Mime + ';base64,' + EncodeStringBase64(Raw);
  finally
    FS.Free;
  end;
end;

{ TAIVideoOpenAICompatibleProvider }

constructor TAIVideoOpenAICompatibleProvider.CreateWithMeta(const AID, AName,
  AEndpoint: string);
begin
  inherited Create;
  SetIdentity(AID, AName, AEndpoint);
end;

constructor TAIVideoOpenAICompatibleProvider.Create;
begin
  CreateWithMeta('openai-compatible', 'OpenAI-Compatible Video',
    'http://127.0.0.1:8080/v1/videos');
end;

function TAIVideoOpenAICompatibleProvider.Generate(const AConfig: TAIVideoProviderConfig;
  out AOutputFile: string): Boolean;
var
  Url, JobId, StatusStr, VideoUrl, ModelName: string;
  ReqObj: TJSONObject;
  Headers: TStringList;
  Raw, VidBytes: RawByteString;
  Code, Tries: Integer;
  Data: TJSONData;
begin
  Result := False;
  AOutputFile := AConfig.OutputFile;
  Url := TrimBaseUrl(AConfig.Endpoint);
  if Url = '' then Url := TrimBaseUrl(FDefaultEndpoint);
  ModelName := Trim(AConfig.Model);
  if ModelName = '' then ModelName := 'sora-2';

  ReqObj := TJSONObject.Create;
  Headers := TStringList.Create;
  try
    ReqObj.Add('model', ModelName);
    ReqObj.Add('prompt', AConfig.Prompt);
    ReqObj.Add('seconds', IntToStr(AConfig.DurationSec));
    ReqObj.Add('size', Format('%dx%d', [AConfig.Width, AConfig.Height]));
    if AConfig.Token <> '' then
      Headers.Add('Authorization=Bearer ' + AConfig.Token);

    if not HttpPostJsonRaw(Url, ReqObj.AsJSON, Headers, AConfig.Timeout, Raw, Code) then
      Exit;

    Data := GetJSON(Raw);
    try
      if Data is TJSONObject then
      begin
        VideoUrl := TJSONObject(Data).Get('url', '');
        if VideoUrl <> '' then
        begin
          if HttpGetRaw(VideoUrl, Headers, AConfig.Timeout, VidBytes, Code) then
            Result := SaveBytesToFile(VidBytes, AOutputFile);
          Exit;
        end;
        JobId := TJSONObject(Data).Get('id', '');
      end
      else
        JobId := '';
    finally
      Data.Free;
    end;

    if JobId = '' then
    begin
      SetLastError('Servidor de video nao retornou id ou url.');
      Exit;
    end;

    for Tries := 1 to 120 do
    begin
      if IsCancelled then Exit;
      Sleep(2000);
      if not HttpGetRaw(Url + '/' + JobId, Headers, AConfig.Timeout, Raw, Code) then Continue;
      Data := GetJSON(Raw);
      try
        if Data is TJSONObject then
        begin
          StatusStr := LowerCase(TJSONObject(Data).Get('status', ''));
          if (StatusStr = 'completed') or (StatusStr = 'succeeded') then
          begin
            if HttpGetRaw(Url + '/' + JobId + '/content', Headers, AConfig.Timeout, VidBytes, Code) then
              Result := SaveBytesToFile(VidBytes, AOutputFile);
            Exit;
          end;
          if StatusStr = 'failed' then
          begin
            SetLastError('Geracao de video falhou: ' + Copy(Raw, 1, 240));
            Exit;
          end;
        end;
      finally
        Data.Free;
      end;
    end;
    SetLastError('Timeout aguardando geracao de video (' + JobId + ').');
  finally
    Headers.Free;
    ReqObj.Free;
  end;
end;

{ TAIVideoGoogleVeoProvider }

constructor TAIVideoGoogleVeoProvider.Create;
begin
  inherited Create;
  SetIdentity('google-veo', 'Google Veo',
    'https://generativelanguage.googleapis.com/v1beta/models/');
end;

function TAIVideoGoogleVeoProvider.Generate(const AConfig: TAIVideoProviderConfig;
  out AOutputFile: string): Boolean;
var
  BaseUrl, ModelName, Url, OpName, PollUrl, VidUri: string;
  ReqObj, InstObj, ParamObj, RespObj: TJSONObject;
  InstArr, VidArr: TJSONArray;
  Raw, VidBytes: RawByteString;
  Code, Tries: Integer;
  Data: TJSONData;
  DoneFlag: Boolean;
begin
  Result := False;
  AOutputFile := AConfig.OutputFile;
  BaseUrl := TrimBaseUrl(AConfig.Endpoint);
  if BaseUrl = '' then BaseUrl := TrimBaseUrl(FDefaultEndpoint);
  ModelName := Trim(AConfig.Model);
  if ModelName = '' then ModelName := 'veo-2.0-generate-001';
  Url := BaseUrl + '/' + ModelName + ':predictLongRunning?key=' + AConfig.Token;

  ReqObj := TJSONObject.Create;
  try
    InstArr := TJSONArray.Create;
    InstObj := TJSONObject.Create;
    InstObj.Add('prompt', AConfig.Prompt);
    InstArr.Add(InstObj);
    ReqObj.Add('instances', InstArr);
    ParamObj := TJSONObject.Create;
    ParamObj.Add('durationSeconds', AConfig.DurationSec);
    ReqObj.Add('parameters', ParamObj);

    if not HttpPostJsonRaw(Url, ReqObj.AsJSON, nil, AConfig.Timeout, Raw, Code) then Exit;
    Data := GetJSON(Raw);
    try
      OpName := '';
      if Data is TJSONObject then OpName := TJSONObject(Data).Get('name', '');
    finally
      Data.Free;
    end;
    if OpName = '' then begin SetLastError('Veo nao retornou operation name.'); Exit; end;

    PollUrl := 'https://generativelanguage.googleapis.com/v1beta/' + OpName + '?key=' + AConfig.Token;
    for Tries := 1 to 120 do
    begin
      if IsCancelled then Exit;
      Sleep(2500);
      if not HttpGetRaw(PollUrl, nil, AConfig.Timeout, Raw, Code) then Continue;
      Data := GetJSON(Raw);
      try
        if Data is TJSONObject then
        begin
          DoneFlag := TJSONObject(Data).Get('done', False);
          if DoneFlag and (TJSONObject(Data).Find('response') is TJSONObject) then
          begin
            RespObj := TJSONObject(TJSONObject(Data).Find('response'));
            if (RespObj.Find('generateVideoResponse') is TJSONObject) then
              RespObj := TJSONObject(RespObj.Find('generateVideoResponse'));
            if (RespObj.Find('generatedSamples') is TJSONArray) then
            begin
              VidArr := TJSONArray(RespObj.Find('generatedSamples'));
              if (VidArr.Count > 0) and (VidArr.Items[0] is TJSONObject) and
                 (TJSONObject(VidArr.Items[0]).Find('video') is TJSONObject) then
              begin
                VidUri := TJSONObject(TJSONObject(VidArr.Items[0]).Find('video')).Get('uri', '');
                if (VidUri <> '') and HttpGetRaw(VidUri + '&key=' + AConfig.Token, nil, AConfig.Timeout, VidBytes, Code) then
                  Result := SaveBytesToFile(VidBytes, AOutputFile);
                Exit;
              end;
            end;
          end;
        end;
      finally
        Data.Free;
      end;
    end;
    SetLastError('Timeout aguardando Veo.');
  finally
    ReqObj.Free;
  end;
end;

{ TAIVideoRunwayProvider }

constructor TAIVideoRunwayProvider.Create;
begin
  inherited Create;
  SetIdentity('runway', 'Runway Gen-3 / Gen-4',
    'https://api.dev.runwayml.com/v1/image_to_video');
end;

function TAIVideoRunwayProvider.Generate(const AConfig: TAIVideoProviderConfig;
  out AOutputFile: string): Boolean;
var
  Url, TaskId, StatusStr, VidUrl: string;
  ReqObj: TJSONObject;
  Headers: TStringList;
  Raw, VidBytes: RawByteString;
  Code, Tries: Integer;
  Data: TJSONData;
begin
  Result := False;
  AOutputFile := AConfig.OutputFile;
  Url := Trim(AConfig.Endpoint);
  if Url = '' then Url := FDefaultEndpoint;

  ReqObj := TJSONObject.Create;
  Headers := TStringList.Create;
  try
    ReqObj.Add('model', IfThen(AConfig.Model <> '', AConfig.Model, 'gen4_turbo'));
    ReqObj.Add('promptText', AConfig.Prompt);
    ReqObj.Add('duration', AConfig.DurationSec);
    if (AConfig.SourceImageFile <> '') and FileExists(AConfig.SourceImageFile) then
      ReqObj.Add('promptImage', FileToDataUri(AConfig.SourceImageFile));
    if AConfig.Token <> '' then
      Headers.Add('Authorization=Bearer ' + AConfig.Token);
    Headers.Add('X-Runway-Version=2024-11-06');

    if not HttpPostJsonRaw(Url, ReqObj.AsJSON, Headers, AConfig.Timeout, Raw, Code) then Exit;
    Data := GetJSON(Raw);
    try
      TaskId := '';
      if Data is TJSONObject then TaskId := TJSONObject(Data).Get('id', '');
    finally
      Data.Free;
    end;
    if TaskId = '' then begin SetLastError('Runway nao retornou task id.'); Exit; end;

    for Tries := 1 to 120 do
    begin
      if IsCancelled then Exit;
      Sleep(2000);
      if not HttpGetRaw('https://api.dev.runwayml.com/v1/tasks/' + TaskId, Headers, AConfig.Timeout, Raw, Code) then Continue;
      Data := GetJSON(Raw);
      try
        if Data is TJSONObject then
        begin
          StatusStr := UpperCase(TJSONObject(Data).Get('status', ''));
          if (StatusStr = 'SUCCEEDED') and (TJSONObject(Data).Find('output') is TJSONArray) and
             (TJSONArray(TJSONObject(Data).Find('output')).Count > 0) then
          begin
            VidUrl := TJSONArray(TJSONObject(Data).Find('output')).Strings[0];
            if HttpGetRaw(VidUrl, nil, AConfig.Timeout, VidBytes, Code) then
              Result := SaveBytesToFile(VidBytes, AOutputFile);
            Exit;
          end;
          if StatusStr = 'FAILED' then
          begin
            SetLastError('Runway falhou: ' + Copy(Raw, 1, 200));
            Exit;
          end;
        end;
      finally
        Data.Free;
      end;
    end;
    SetLastError('Timeout aguardando Runway.');
  finally
    Headers.Free;
    ReqObj.Free;
  end;
end;

{ TAIVideoLumaProvider }

constructor TAIVideoLumaProvider.Create;
begin
  inherited Create;
  SetIdentity('luma', 'Luma Dream Machine',
    'https://api.lumalabs.ai/dream-machine/v1/generations');
end;

function TAIVideoLumaProvider.Generate(const AConfig: TAIVideoProviderConfig;
  out AOutputFile: string): Boolean;
var
  Url, GenId, StateStr, VidUrl: string;
  ReqObj: TJSONObject;
  Headers: TStringList;
  Raw, VidBytes: RawByteString;
  Code, Tries: Integer;
  Data: TJSONData;
begin
  Result := False;
  AOutputFile := AConfig.OutputFile;
  Url := Trim(AConfig.Endpoint);
  if Url = '' then Url := FDefaultEndpoint;

  ReqObj := TJSONObject.Create;
  Headers := TStringList.Create;
  try
    ReqObj.Add('prompt', AConfig.Prompt);
    ReqObj.Add('model', IfThen(AConfig.Model <> '', AConfig.Model, 'ray-2'));
    if AConfig.Token <> '' then Headers.Add('Authorization=Bearer ' + AConfig.Token);

    if not HttpPostJsonRaw(Url, ReqObj.AsJSON, Headers, AConfig.Timeout, Raw, Code) then Exit;
    Data := GetJSON(Raw);
    try
      GenId := '';
      if Data is TJSONObject then GenId := TJSONObject(Data).Get('id', '');
    finally
      Data.Free;
    end;
    if GenId = '' then begin SetLastError('Luma nao retornou generation id.'); Exit; end;

    for Tries := 1 to 120 do
    begin
      if IsCancelled then Exit;
      Sleep(2000);
      if not HttpGetRaw(TrimBaseUrl(Url) + '/' + GenId, Headers, AConfig.Timeout, Raw, Code) then Continue;
      Data := GetJSON(Raw);
      try
        if Data is TJSONObject then
        begin
          StateStr := LowerCase(TJSONObject(Data).Get('state', ''));
          if (StateStr = 'completed') and (TJSONObject(Data).Find('assets') is TJSONObject) then
          begin
            VidUrl := TJSONObject(TJSONObject(Data).Find('assets')).Get('video', '');
            if (VidUrl <> '') and HttpGetRaw(VidUrl, nil, AConfig.Timeout, VidBytes, Code) then
              Result := SaveBytesToFile(VidBytes, AOutputFile);
            Exit;
          end;
          if StateStr = 'failed' then
          begin
            SetLastError('Luma falhou: ' + Copy(Raw, 1, 200));
            Exit;
          end;
        end;
      finally
        Data.Free;
      end;
    end;
    SetLastError('Timeout aguardando Luma.');
  finally
    Headers.Free;
    ReqObj.Free;
  end;
end;

{ TAIVideoKlingProvider }

constructor TAIVideoKlingProvider.Create;
begin
  inherited Create;
  SetIdentity('kling', 'Kling AI', 'https://api.klingai.com/v1/videos/text2video');
end;

function TAIVideoKlingProvider.Generate(const AConfig: TAIVideoProviderConfig;
  out AOutputFile: string): Boolean;
var
  Url, TaskId, StatusStr, VidUrl: string;
  ReqObj, DataObj: TJSONObject;
  VidArr: TJSONArray;
  Headers: TStringList;
  Raw, VidBytes: RawByteString;
  Code, Tries: Integer;
  Data: TJSONData;
begin
  Result := False;
  AOutputFile := AConfig.OutputFile;
  Url := Trim(AConfig.Endpoint);
  if Url = '' then Url := FDefaultEndpoint;

  ReqObj := TJSONObject.Create;
  Headers := TStringList.Create;
  try
    ReqObj.Add('model_name', IfThen(AConfig.Model <> '', AConfig.Model, 'kling-v2-master'));
    ReqObj.Add('prompt', AConfig.Prompt);
    ReqObj.Add('duration', IntToStr(AConfig.DurationSec));
    if AConfig.Token <> '' then Headers.Add('Authorization=Bearer ' + AConfig.Token);

    if not HttpPostJsonRaw(Url, ReqObj.AsJSON, Headers, AConfig.Timeout, Raw, Code) then Exit;
    Data := GetJSON(Raw);
    try
      TaskId := '';
      if (Data is TJSONObject) and (TJSONObject(Data).Find('data') is TJSONObject) then
        TaskId := TJSONObject(TJSONObject(Data).Find('data')).Get('task_id', '');
    finally
      Data.Free;
    end;
    if TaskId = '' then begin SetLastError('Kling nao retornou task_id.'); Exit; end;

    for Tries := 1 to 120 do
    begin
      if IsCancelled then Exit;
      Sleep(2500);
      if not HttpGetRaw(TrimBaseUrl(Url) + '/' + TaskId, Headers, AConfig.Timeout, Raw, Code) then Continue;
      Data := GetJSON(Raw);
      try
        if (Data is TJSONObject) and (TJSONObject(Data).Find('data') is TJSONObject) then
        begin
          DataObj := TJSONObject(TJSONObject(Data).Find('data'));
          StatusStr := LowerCase(DataObj.Get('task_status', ''));
          if (StatusStr = 'succeed') and (DataObj.Find('task_result') is TJSONObject) and
             (TJSONObject(DataObj.Find('task_result')).Find('videos') is TJSONArray) then
          begin
            VidArr := TJSONArray(TJSONObject(DataObj.Find('task_result')).Find('videos'));
            if (VidArr.Count > 0) and (VidArr.Items[0] is TJSONObject) then
            begin
              VidUrl := TJSONObject(VidArr.Items[0]).Get('url', '');
              if (VidUrl <> '') and HttpGetRaw(VidUrl, nil, AConfig.Timeout, VidBytes, Code) then
                Result := SaveBytesToFile(VidBytes, AOutputFile);
              Exit;
            end;
          end;
          if StatusStr = 'failed' then
          begin
            SetLastError('Kling falhou: ' + Copy(Raw, 1, 200));
            Exit;
          end;
        end;
      finally
        Data.Free;
      end;
    end;
    SetLastError('Timeout aguardando Kling.');
  finally
    Headers.Free;
    ReqObj.Free;
  end;
end;

{ TAIVideoComfyUIProvider }

constructor TAIVideoComfyUIProvider.Create;
begin
  inherited Create;
  SetIdentity('comfyui-video', 'ComfyUI Video Server', 'http://127.0.0.1:8188/prompt');
end;

function TAIVideoComfyUIProvider.Generate(const AConfig: TAIVideoProviderConfig;
  out AOutputFile: string): Boolean;
begin
  // ComfyUI video workflows variam por modelo (Wan/LTX/AnimateDiff); exige endpoint valido
  Result := False;
  AOutputFile := AConfig.OutputFile;
  SetLastError('Para ComfyUI Video, envie workflow via servidor local em ' +
    IfThen(AConfig.Endpoint <> '', AConfig.Endpoint, FDefaultEndpoint) +
    ' ou use FFmpeg-CPU para geracao sem GPU.');
end;

{ TAIVideoFFmpegCPUProvider }

constructor TAIVideoFFmpegCPUProvider.Create;
begin
  inherited Create;
  SetIdentity('ffmpeg-cpu', 'FFmpeg CPU Storyboard / Motion (sem GPU)', 'local://ffmpeg');
  FRunner := TAIProcessRunner.Create(nil);
end;

destructor TAIVideoFFmpegCPUProvider.Destroy;
begin
  FRunner.Free;
  inherited Destroy;
end;

procedure TAIVideoFFmpegCPUProvider.Cancel;
begin
  inherited Cancel;
  if FRunner <> nil then FRunner.Stop;
end;

function TAIVideoFFmpegCPUProvider.Generate(const AConfig: TAIVideoProviderConfig;
  out AOutputFile: string): Boolean;
var
  Exe, DurStr, VfStr: string;
  Args: TStringList;
  Params: array of string;
  I, Dur, FPS, W, H: Integer;
  HasImg, HasAud: Boolean;
begin
  Result := False;
  AOutputFile := ExpandFileName(AConfig.OutputFile);
  ForceDirectories(ExtractFileDir(AOutputFile));

  Exe := Trim(AConfig.FfmpegPath);
  if Exe = '' then Exe := 'ffmpeg';
  Dur := AConfig.DurationSec; if Dur <= 0 then Dur := 4;
  FPS := AConfig.FPS; if FPS <= 0 then FPS := 24;
  W := AConfig.Width; if W <= 0 then W := 1280;
  H := AConfig.Height; if H <= 0 then H := 720;
  DurStr := IntToStr(Dur);

  HasImg := (AConfig.SourceImageFile <> '') and FileExists(AConfig.SourceImageFile);
  HasAud := (AConfig.AudioFile <> '') and FileExists(AConfig.AudioFile);

  Args := TStringList.Create;
  try
    Args.Add('-y');
    if HasImg then
    begin
      Args.Add('-loop'); Args.Add('1');
      Args.Add('-i'); Args.Add(AConfig.SourceImageFile);
    end
    else
    begin
      Args.Add('-f'); Args.Add('lavfi');
      Args.Add('-i'); Args.Add(Format('color=c=0x163B6E:s=%dx%d:r=%d:d=%d', [W, H, FPS, Dur]));
    end;

    if HasAud then
    begin
      Args.Add('-i'); Args.Add(AConfig.AudioFile);
    end;

    if HasImg then
    begin
      VfStr := Format('scale=%d:%d:force_original_aspect_ratio=decrease,pad=%d:%d:(ow-iw)/2:(oh-ih)/2,format=yuv420p',
        [W, H, W, H]);
      Args.Add('-vf'); Args.Add(VfStr);
    end;

    Args.Add('-t'); Args.Add(DurStr);
    Args.Add('-c:v'); Args.Add('libx264');
    Args.Add('-pix_fmt'); Args.Add('yuv420p');
    if HasAud then
    begin
      Args.Add('-c:a'); Args.Add('aac');
      Args.Add('-shortest');
    end;
    Args.Add(AOutputFile);

    SetLength(Params, Args.Count);
    for I := 0 to Args.Count - 1 do Params[I] := Args[I];

    FRunner.Executable := Exe;
    FRunner.TimeoutMs := AConfig.Timeout;
    Result := FRunner.Execute(Params) and FileExists(AOutputFile);
    if not Result then
      SetLastError(Trim(FRunner.LastError + ' ' + FRunner.StdErrText));
  finally
    Args.Free;
  end;
end;

{ TAIVideoProviderFactory }

class function TAIVideoProviderFactory.CreateProvider(
  AKind: TAIVideoProviderKind): IAIVideoProvider;
begin
  case AKind of
    vidOpenAISora: Result := TAIVideoOpenAICompatibleProvider.CreateWithMeta('openai-sora', 'OpenAI Sora', 'https://api.openai.com/v1/videos');
    vidOpenAICompatible: Result := TAIVideoOpenAICompatibleProvider.Create;
    vidGoogleVeo: Result := TAIVideoGoogleVeoProvider.Create;
    vidRunway: Result := TAIVideoRunwayProvider.Create;
    vidKling: Result := TAIVideoKlingProvider.Create;
    vidLuma: Result := TAIVideoLumaProvider.Create;
    vidComfyUIVideo: Result := TAIVideoComfyUIProvider.Create;
    vidLocalFFmpegCPU: Result := TAIVideoFFmpegCPUProvider.Create;
  else
    Result := TAIVideoFFmpegCPUProvider.Create;
  end;
end;

class function TAIVideoProviderFactory.KindFromName(
  const AName: string): TAIVideoProviderKind;
var
  S: string;
begin
  S := LowerCase(Trim(AName));
  if (Pos('ffmpeg', S) > 0) or (Pos('cpu', S) > 0) then Result := vidLocalFFmpegCPU
  else if Pos('veo', S) > 0 then Result := vidGoogleVeo
  else if Pos('runway', S) > 0 then Result := vidRunway
  else if Pos('kling', S) > 0 then Result := vidKling
  else if Pos('luma', S) > 0 then Result := vidLuma
  else if Pos('comfy', S) > 0 then Result := vidComfyUIVideo
  else if Pos('sora', S) > 0 then Result := vidOpenAISora
  else Result := vidOpenAICompatible;
end;

end.
