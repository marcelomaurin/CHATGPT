unit aiimageproviders;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpclient, fpjson, jsonparser, base64, opensslsockets;

type
  TAIImageProviderKind = (
    imgOpenAI,
    imgOpenAICompatible,
    imgGemini,
    imgStability,
    imgBlackForestLabs,
    imgComfyUI,
    imgAutomatic1111,
    imgHuggingFace
  );

  TAIImageProviderConfig = record
    Endpoint: string;
    Token: string;
    Model: string;
    Prompt: string;
    NegativePrompt: string;
    Width: Integer;
    Height: Integer;
    Steps: Integer;
    Seed: Int64;
    Quality: string;
    Style: string;
    OutputFile: string;
    UseGPU: Boolean;
    Timeout: Integer;
  end;

  IAIImageProvider = interface
    ['{A9130A74-2D8F-4A2E-9F60-2E31D944C120}']
    function GetProviderID: string;
    function GetProviderName: string;
    function GetDefaultEndpoint: string;
    function GetLastError: string;
    function Generate(const AConfig: TAIImageProviderConfig;
      out AOutputFile: string): Boolean;
    procedure Cancel;
  end;

  TAIImageProviderBase = class(TInterfacedObject, IAIImageProvider)
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
    function DecodeBase64ToFile(const AB64, AFileName: string): Boolean;
    function SaveBytesToFile(const ARaw: RawByteString; const AFileName: string): Boolean;
  public
    constructor Create; virtual;
    destructor Destroy; override;
    function GetProviderID: string;
    function GetProviderName: string;
    function GetDefaultEndpoint: string;
    function GetLastError: string;
    function Generate(const AConfig: TAIImageProviderConfig;
      out AOutputFile: string): Boolean; virtual; abstract;
    procedure Cancel; virtual;
  end;

  TAIImageOpenAICompatibleProvider = class(TAIImageProviderBase)
  public
    constructor Create; override;
    function Generate(const AConfig: TAIImageProviderConfig;
      out AOutputFile: string): Boolean; override;
  end;

  TAIImageOpenAIProvider = class(TAIImageOpenAICompatibleProvider)
  public
    constructor Create; override;
  end;

  TAIImageAutomatic1111Provider = class(TAIImageProviderBase)
  public
    constructor Create; override;
    function Generate(const AConfig: TAIImageProviderConfig;
      out AOutputFile: string): Boolean; override;
  end;

  TAIImageComfyUIProvider = class(TAIImageProviderBase)
  public
    constructor Create; override;
    function Generate(const AConfig: TAIImageProviderConfig;
      out AOutputFile: string): Boolean; override;
  end;

  TAIImageGeminiProvider = class(TAIImageProviderBase)
  public
    constructor Create; override;
    function Generate(const AConfig: TAIImageProviderConfig;
      out AOutputFile: string): Boolean; override;
  end;

  TAIImageStabilityProvider = class(TAIImageProviderBase)
  public
    constructor Create; override;
    function Generate(const AConfig: TAIImageProviderConfig;
      out AOutputFile: string): Boolean; override;
  end;

  TAIImageBFLProvider = class(TAIImageProviderBase)
  public
    constructor Create; override;
    function Generate(const AConfig: TAIImageProviderConfig;
      out AOutputFile: string): Boolean; override;
  end;

  TAIImageHuggingFaceProvider = class(TAIImageProviderBase)
  public
    constructor Create; override;
    function Generate(const AConfig: TAIImageProviderConfig;
      out AOutputFile: string): Boolean; override;
  end;

  TAIImageProviderFactory = class
  public
    class function CreateProvider(AKind: TAIImageProviderKind): IAIImageProvider; static;
    class function KindFromName(const AName: string): TAIImageProviderKind; static;
  end;

procedure InitAIImageProviderConfig(out AConfig: TAIImageProviderConfig);
function AIImageProviderKindName(AKind: TAIImageProviderKind): string;

implementation

procedure InitAIImageProviderConfig(out AConfig: TAIImageProviderConfig);
begin
  FillChar(AConfig, SizeOf(AConfig), 0);
  AConfig.Width := 1024;
  AConfig.Height := 1024;
  AConfig.Steps := 20;
  AConfig.Seed := -1;
  AConfig.Quality := 'standard';
  AConfig.Timeout := 180000;
end;

function AIImageProviderKindName(AKind: TAIImageProviderKind): string;
begin
  case AKind of
    imgOpenAI: Result := 'OpenAI';
    imgOpenAICompatible: Result := 'OpenAI-compatible';
    imgGemini: Result := 'Gemini';
    imgStability: Result := 'Stability';
    imgBlackForestLabs: Result := 'BlackForestLabs';
    imgComfyUI: Result := 'ComfyUI';
    imgAutomatic1111: Result := 'Automatic1111';
    imgHuggingFace: Result := 'HuggingFace';
  end;
end;

function TrimBaseUrl(const AUrl: string): string;
begin
  Result := Trim(AUrl);
  while (Result <> '') and (Result[Length(Result)] = '/') do
    Delete(Result, Length(Result), 1);
end;

{ TAIImageProviderBase }

constructor TAIImageProviderBase.Create;
begin
  inherited Create;
  InitCriticalSection(FLock);
end;

destructor TAIImageProviderBase.Destroy;
begin
  DoneCriticalSection(FLock);
  inherited Destroy;
end;

procedure TAIImageProviderBase.SetIdentity(const AID, AName, AEndpoint: string);
begin
  FProviderID := AID;
  FProviderName := AName;
  FDefaultEndpoint := AEndpoint;
end;

procedure TAIImageProviderBase.SetLastError(const Msg: string);
begin
  FLastError := Msg;
end;

function TAIImageProviderBase.IsCancelled: Boolean;
begin
  EnterCriticalSection(FLock);
  try
    Result := FCancelled;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TAIImageProviderBase.GetProviderID: string; begin Result := FProviderID; end;
function TAIImageProviderBase.GetProviderName: string; begin Result := FProviderName; end;
function TAIImageProviderBase.GetDefaultEndpoint: string; begin Result := FDefaultEndpoint; end;
function TAIImageProviderBase.GetLastError: string; begin Result := FLastError; end;

procedure TAIImageProviderBase.Cancel;
begin
  EnterCriticalSection(FLock);
  try
    FCancelled := True;
    if FActiveHTTP <> nil then
      FActiveHTTP.Terminate;
  finally
    LeaveCriticalSection(FLock);
  end;
end;

function TAIImageProviderBase.HttpPostJsonRaw(const AUrl, ABody: string;
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
    if ATimeoutMs > 0 then
      Client.IOTimeout := ATimeoutMs;
    Client.AddHeader('Content-Type', 'application/json');
    if AHeaders <> nil then
      for I := 0 to AHeaders.Count - 1 do
        Client.AddHeader(AHeaders.Names[I], AHeaders.ValueFromIndex[I]);

    EnterCriticalSection(FLock);
    try
      FActiveHTTP := Client;
    finally
      LeaveCriticalSection(FLock);
    end;

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
    try
      FActiveHTTP := nil;
    finally
      LeaveCriticalSection(FLock);
    end;
    RespStream.Free;
    ReqStream.Free;
    Client.Free;
  end;
end;

function TAIImageProviderBase.HttpGetRaw(const AUrl: string; AHeaders: TStrings;
  ATimeoutMs: Integer; out ARawBytes: RawByteString; out AHttpCode: Integer): Boolean;
var
  Client: TFPHTTPClient;
  RespStream: TStringStream;
  I: Integer;
begin
  Result := False;
  ARawBytes := '';
  AHttpCode := 0;
  if IsCancelled then begin SetLastError('Operacao cancelada.'); Exit; end;

  Client := TFPHTTPClient.Create(nil);
  RespStream := TStringStream.Create('');
  try
    Client.AllowRedirect := True;
    Client.ConnectTimeout := 15000;
    if ATimeoutMs > 0 then
      Client.IOTimeout := ATimeoutMs;
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

function TAIImageProviderBase.SaveBytesToFile(const ARaw: RawByteString;
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

function TAIImageProviderBase.DecodeBase64ToFile(const AB64, AFileName: string): Boolean;
var
  Clean, Decoded: string;
  P: Integer;
begin
  Result := False;
  Clean := Trim(AB64);
  P := Pos(',', Clean);
  if (P > 0) and (Pos('data:', LowerCase(Copy(Clean, 1, P))) = 1) then
    Clean := Copy(Clean, P + 1, Length(Clean));
  if Clean = '' then Exit;
  try
    Decoded := DecodeStringBase64(Clean);
    Result := SaveBytesToFile(Decoded, AFileName);
  except
    on E: Exception do
      SetLastError('Falha ao decodificar imagem base64: ' + E.Message);
  end;
end;

{ TAIImageOpenAICompatibleProvider }

constructor TAIImageOpenAICompatibleProvider.Create;
begin
  inherited Create;
  SetIdentity('openai-compatible', 'OpenAI-Compatible Images',
    'http://127.0.0.1:8080/v1/images/generations');
end;

function TAIImageOpenAICompatibleProvider.Generate(const AConfig: TAIImageProviderConfig;
  out AOutputFile: string): Boolean;
var
  Url, ModelName: string;
  ReqObj, ItemObj: TJSONObject;
  Headers: TStringList;
  Raw, DlBytes: RawByteString;
  Code: Integer;
  Data: TJSONData;
  Arr: TJSONArray;
  B64, ImgUrl: string;
begin
  Result := False;
  AOutputFile := AConfig.OutputFile;
  Url := Trim(AConfig.Endpoint);
  if Url = '' then Url := FDefaultEndpoint;
  if Pos('/images/generations', LowerCase(Url)) = 0 then
    Url := TrimBaseUrl(Url) + '/v1/images/generations';

  ModelName := Trim(AConfig.Model);
  if ModelName = '' then ModelName := 'gpt-image-1';

  ReqObj := TJSONObject.Create;
  Headers := TStringList.Create;
  try
    ReqObj.Add('model', ModelName);
    ReqObj.Add('prompt', AConfig.Prompt);
    ReqObj.Add('n', 1);
    ReqObj.Add('size', Format('%dx%d', [AConfig.Width, AConfig.Height]));
    if Pos('dall-e', LowerCase(ModelName)) > 0 then
      ReqObj.Add('response_format', 'b64_json');
    if AConfig.Token <> '' then
      Headers.Add('Authorization=Bearer ' + AConfig.Token);

    if not HttpPostJsonRaw(Url, ReqObj.AsJSON, Headers, AConfig.Timeout, Raw, Code) then
      Exit;

    Data := GetJSON(Raw);
    try
      if (Data is TJSONObject) and (TJSONObject(Data).Find('data') is TJSONArray) then
      begin
        Arr := TJSONArray(TJSONObject(Data).Find('data'));
        if (Arr.Count > 0) and (Arr.Items[0] is TJSONObject) then
        begin
          ItemObj := TJSONObject(Arr.Items[0]);
          B64 := ItemObj.Get('b64_json', '');
          if B64 <> '' then
          begin
            Result := DecodeBase64ToFile(B64, AOutputFile);
            Exit;
          end;
          ImgUrl := ItemObj.Get('url', '');
          if ImgUrl <> '' then
          begin
            if HttpGetRaw(ImgUrl, nil, AConfig.Timeout, DlBytes, Code) then
              Result := SaveBytesToFile(DlBytes, AOutputFile);
            Exit;
          end;
        end;
      end;
      SetLastError('Resposta inesperada do servidor de imagem: ' + Copy(Raw, 1, 240));
    finally
      Data.Free;
    end;
  finally
    Headers.Free;
    ReqObj.Free;
  end;
end;

{ TAIImageOpenAIProvider }

constructor TAIImageOpenAIProvider.Create;
begin
  inherited Create;
  SetIdentity('openai', 'OpenAI Images', 'https://api.openai.com/v1/images/generations');
end;

{ TAIImageAutomatic1111Provider }

constructor TAIImageAutomatic1111Provider.Create;
begin
  inherited Create;
  SetIdentity('automatic1111', 'Automatic1111 / SD Forge WebUI',
    'http://127.0.0.1:7860/sdapi/v1/txt2img');
end;

function TAIImageAutomatic1111Provider.Generate(const AConfig: TAIImageProviderConfig;
  out AOutputFile: string): Boolean;
var
  Url: string;
  ReqObj: TJSONObject;
  Raw: RawByteString;
  Code: Integer;
  Data: TJSONData;
  Arr: TJSONArray;
begin
  Result := False;
  AOutputFile := AConfig.OutputFile;
  Url := Trim(AConfig.Endpoint);
  if Url = '' then Url := FDefaultEndpoint;
  if Pos('txt2img', LowerCase(Url)) = 0 then
    Url := TrimBaseUrl(Url) + '/sdapi/v1/txt2img';

  ReqObj := TJSONObject.Create;
  try
    ReqObj.Add('prompt', AConfig.Prompt);
    if AConfig.NegativePrompt <> '' then
      ReqObj.Add('negative_prompt', AConfig.NegativePrompt);
    ReqObj.Add('width', AConfig.Width);
    ReqObj.Add('height', AConfig.Height);
    ReqObj.Add('steps', AConfig.Steps);
    if AConfig.Seed >= 0 then
      ReqObj.Add('seed', AConfig.Seed);

    if not HttpPostJsonRaw(Url, ReqObj.AsJSON, nil, AConfig.Timeout, Raw, Code) then
      Exit;

    Data := GetJSON(Raw);
    try
      if (Data is TJSONObject) and (TJSONObject(Data).Find('images') is TJSONArray) then
      begin
        Arr := TJSONArray(TJSONObject(Data).Find('images'));
        if Arr.Count > 0 then
        begin
          Result := DecodeBase64ToFile(Arr.Strings[0], AOutputFile);
          Exit;
        end;
      end;
      SetLastError('Automatic1111 nao retornou imagens: ' + Copy(Raw, 1, 240));
    finally
      Data.Free;
    end;
  finally
    ReqObj.Free;
  end;
end;

{ TAIImageComfyUIProvider }

constructor TAIImageComfyUIProvider.Create;
begin
  inherited Create;
  SetIdentity('comfyui', 'ComfyUI Local Server', 'http://127.0.0.1:8188/prompt');
end;

function TAIImageComfyUIProvider.Generate(const AConfig: TAIImageProviderConfig;
  out AOutputFile: string): Boolean;
var
  BaseUrl, PromptUrl, HistUrl, ViewUrl, PromptId, CkptName, FileName, SubFolder, ImgType: string;
  Workflow, Node3, Node4, Node5, Node6, Node7, Node8, Node9, Inputs, Payload, HistObj, OutObj: TJSONObject;
  Arr: TJSONArray;
  Raw, ImgBytes: RawByteString;
  Code, Tries: Integer;
  Data, HistData: TJSONData;
  SeedVal: Int64;
begin
  Result := False;
  AOutputFile := AConfig.OutputFile;
  BaseUrl := TrimBaseUrl(AConfig.Endpoint);
  if BaseUrl = '' then BaseUrl := 'http://127.0.0.1:8188';
  if Copy(LowerCase(BaseUrl), Length(BaseUrl) - 6, 7) = '/prompt' then
    Delete(BaseUrl, Length(BaseUrl) - 6, 7);
  PromptUrl := BaseUrl + '/prompt';

  CkptName := Trim(AConfig.Model);
  if CkptName = '' then CkptName := 'v1-5-pruned-emaonly.safetensors';
  SeedVal := AConfig.Seed;
  if SeedVal < 0 then SeedVal := Random(999999999);

  // Workflow padrao KSampler txt2img ComfyUI
  Workflow := TJSONObject.Create;
  Payload := TJSONObject.Create;
  try
    Node4 := TJSONObject.Create; Node4.Add('class_type', 'CheckpointLoaderSimple');
    Inputs := TJSONObject.Create; Inputs.Add('ckpt_name', CkptName);
    Node4.Add('inputs', Inputs); Workflow.Add('4', Node4);

    Node5 := TJSONObject.Create; Node5.Add('class_type', 'EmptyLatentImage');
    Inputs := TJSONObject.Create;
    Inputs.Add('width', AConfig.Width); Inputs.Add('height', AConfig.Height); Inputs.Add('batch_size', 1);
    Node5.Add('inputs', Inputs); Workflow.Add('5', Node5);

    Node6 := TJSONObject.Create; Node6.Add('class_type', 'CLIPTextEncode');
    Inputs := TJSONObject.Create; Inputs.Add('text', AConfig.Prompt);
    Arr := TJSONArray.Create; Arr.Add('4'); Arr.Add(1); Inputs.Add('clip', Arr);
    Node6.Add('inputs', Inputs); Workflow.Add('6', Node6);

    Node7 := TJSONObject.Create; Node7.Add('class_type', 'CLIPTextEncode');
    Inputs := TJSONObject.Create; Inputs.Add('text', AConfig.NegativePrompt);
    Arr := TJSONArray.Create; Arr.Add('4'); Arr.Add(1); Inputs.Add('clip', Arr);
    Node7.Add('inputs', Inputs); Workflow.Add('7', Node7);

    Node3 := TJSONObject.Create; Node3.Add('class_type', 'KSampler');
    Inputs := TJSONObject.Create;
    Inputs.Add('seed', SeedVal); Inputs.Add('steps', AConfig.Steps);
    Inputs.Add('cfg', 7.0); Inputs.Add('sampler_name', 'euler');
    Inputs.Add('scheduler', 'normal'); Inputs.Add('denoise', 1.0);
    Arr := TJSONArray.Create; Arr.Add('4'); Arr.Add(0); Inputs.Add('model', Arr);
    Arr := TJSONArray.Create; Arr.Add('6'); Arr.Add(0); Inputs.Add('positive', Arr);
    Arr := TJSONArray.Create; Arr.Add('7'); Arr.Add(0); Inputs.Add('negative', Arr);
    Arr := TJSONArray.Create; Arr.Add('5'); Arr.Add(0); Inputs.Add('latent_image', Arr);
    Node3.Add('inputs', Inputs); Workflow.Add('3', Node3);

    Node8 := TJSONObject.Create; Node8.Add('class_type', 'VAEDecode');
    Inputs := TJSONObject.Create;
    Arr := TJSONArray.Create; Arr.Add('3'); Arr.Add(0); Inputs.Add('samples', Arr);
    Arr := TJSONArray.Create; Arr.Add('4'); Arr.Add(2); Inputs.Add('vae', Arr);
    Node8.Add('inputs', Inputs); Workflow.Add('8', Node8);

    Node9 := TJSONObject.Create; Node9.Add('class_type', 'SaveImage');
    Inputs := TJSONObject.Create; Inputs.Add('filename_prefix', 'maurinmovie');
    Arr := TJSONArray.Create; Arr.Add('8'); Arr.Add(0); Inputs.Add('images', Arr);
    Node9.Add('inputs', Inputs); Workflow.Add('9', Node9);

    Payload.Add('prompt', Workflow);
    if not HttpPostJsonRaw(PromptUrl, Payload.AsJSON, nil, AConfig.Timeout, Raw, Code) then
      Exit;

    Data := GetJSON(Raw);
    try
      if not (Data is TJSONObject) then Exit;
      PromptId := TJSONObject(Data).Get('prompt_id', '');
    finally
      Data.Free;
    end;
    if PromptId = '' then
    begin
      SetLastError('ComfyUI nao retornou prompt_id.');
      Exit;
    end;

    HistUrl := BaseUrl + '/history/' + PromptId;
    for Tries := 1 to 120 do
    begin
      if IsCancelled then Exit;
      Sleep(500);
      if not HttpGetRaw(HistUrl, nil, AConfig.Timeout, Raw, Code) then Continue;
      HistData := GetJSON(Raw);
      try
        if (HistData is TJSONObject) and (TJSONObject(HistData).Find(PromptId) is TJSONObject) then
        begin
          HistObj := TJSONObject(TJSONObject(HistData).Find(PromptId));
          if (HistObj.Find('outputs') is TJSONObject) and
             (TJSONObject(HistObj.Find('outputs')).Find('9') is TJSONObject) then
          begin
            OutObj := TJSONObject(TJSONObject(HistObj.Find('outputs')).Find('9'));
            if (OutObj.Find('images') is TJSONArray) and (TJSONArray(OutObj.Find('images')).Count > 0) then
            begin
              OutObj := TJSONObject(TJSONArray(OutObj.Find('images')).Items[0]);
              FileName := OutObj.Get('filename', '');
              SubFolder := OutObj.Get('subfolder', '');
              ImgType := OutObj.Get('type', 'output');
              ViewUrl := BaseUrl + '/view?filename=' + FileName + '&subfolder=' + SubFolder + '&type=' + ImgType;
              if HttpGetRaw(ViewUrl, nil, AConfig.Timeout, ImgBytes, Code) then
                Result := SaveBytesToFile(ImgBytes, AOutputFile);
              Exit;
            end;
          end;
        end;
      finally
        HistData.Free;
      end;
    end;
    SetLastError('Timeout aguardando geracao ComfyUI (' + PromptId + ').');
  finally
    Payload.Free;
  end;
end;

{ TAIImageGeminiProvider }

constructor TAIImageGeminiProvider.Create;
begin
  inherited Create;
  SetIdentity('gemini', 'Google Gemini / Imagen',
    'https://generativelanguage.googleapis.com/v1beta/models/');
end;

function TAIImageGeminiProvider.Generate(const AConfig: TAIImageProviderConfig;
  out AOutputFile: string): Boolean;
var
  BaseUrl, ModelName, Url: string;
  ReqObj, InstObj, ParamObj: TJSONObject;
  InstArr: TJSONArray;
  Raw: RawByteString;
  Code: Integer;
  Data: TJSONData;
  PredArr: TJSONArray;
  B64: string;
begin
  Result := False;
  AOutputFile := AConfig.OutputFile;
  BaseUrl := TrimBaseUrl(AConfig.Endpoint);
  if BaseUrl = '' then BaseUrl := TrimBaseUrl(FDefaultEndpoint);
  ModelName := Trim(AConfig.Model);
  if ModelName = '' then ModelName := 'imagen-3.0-generate-002';

  if Pos(':predict', LowerCase(BaseUrl)) > 0 then
    Url := BaseUrl + '?key=' + AConfig.Token
  else
    Url := BaseUrl + '/' + ModelName + ':predict?key=' + AConfig.Token;

  ReqObj := TJSONObject.Create;
  try
    InstArr := TJSONArray.Create;
    InstObj := TJSONObject.Create;
    InstObj.Add('prompt', AConfig.Prompt);
    InstArr.Add(InstObj);
    ReqObj.Add('instances', InstArr);

    ParamObj := TJSONObject.Create;
    ParamObj.Add('sampleCount', 1);
    ReqObj.Add('parameters', ParamObj);

    if not HttpPostJsonRaw(Url, ReqObj.AsJSON, nil, AConfig.Timeout, Raw, Code) then
      Exit;

    Data := GetJSON(Raw);
    try
      if (Data is TJSONObject) and (TJSONObject(Data).Find('predictions') is TJSONArray) then
      begin
        PredArr := TJSONArray(TJSONObject(Data).Find('predictions'));
        if (PredArr.Count > 0) and (PredArr.Items[0] is TJSONObject) then
        begin
          B64 := TJSONObject(PredArr.Items[0]).Get('bytesBase64Encoded', '');
          if B64 <> '' then
          begin
            Result := DecodeBase64ToFile(B64, AOutputFile);
            Exit;
          end;
        end;
      end;
      SetLastError('Gemini/Imagen nao retornou bytesBase64Encoded.');
    finally
      Data.Free;
    end;
  finally
    ReqObj.Free;
  end;
end;

{ TAIImageStabilityProvider }

constructor TAIImageStabilityProvider.Create;
begin
  inherited Create;
  SetIdentity('stability', 'Stability AI',
    'https://api.stability.ai/v2beta/stable-image/generate/sd3');
end;

function TAIImageStabilityProvider.Generate(const AConfig: TAIImageProviderConfig;
  out AOutputFile: string): Boolean;
var
  Url: string;
  ReqObj: TJSONObject;
  Headers: TStringList;
  Raw: RawByteString;
  Code: Integer;
  Data: TJSONData;
  B64: string;
begin
  Result := False;
  AOutputFile := AConfig.OutputFile;
  Url := Trim(AConfig.Endpoint);
  if Url = '' then Url := FDefaultEndpoint;

  ReqObj := TJSONObject.Create;
  Headers := TStringList.Create;
  try
    ReqObj.Add('prompt', AConfig.Prompt);
    if AConfig.NegativePrompt <> '' then
      ReqObj.Add('negative_prompt', AConfig.NegativePrompt);
    if AConfig.Model <> '' then
      ReqObj.Add('model', AConfig.Model);
    ReqObj.Add('output_format', 'png');
    if AConfig.Token <> '' then
      Headers.Add('Authorization=Bearer ' + AConfig.Token);
    Headers.Add('Accept=application/json');

    if not HttpPostJsonRaw(Url, ReqObj.AsJSON, Headers, AConfig.Timeout, Raw, Code) then
      Exit;

    Data := GetJSON(Raw);
    try
      if Data is TJSONObject then
      begin
        B64 := TJSONObject(Data).Get('image', '');
        if B64 <> '' then
        begin
          Result := DecodeBase64ToFile(B64, AOutputFile);
          Exit;
        end;
      end;
      SetLastError('Stability AI nao retornou imagem.');
    finally
      Data.Free;
    end;
  finally
    Headers.Free;
    ReqObj.Free;
  end;
end;

{ TAIImageBFLProvider }

constructor TAIImageBFLProvider.Create;
begin
  inherited Create;
  SetIdentity('bfl-flux', 'Black Forest Labs (Flux)', 'https://api.bfl.ml/v1/flux-pro-1.1');
end;

function TAIImageBFLProvider.Generate(const AConfig: TAIImageProviderConfig;
  out AOutputFile: string): Boolean;
var
  Url, PollUrl, ImgUrl, StatusStr: string;
  ReqObj: TJSONObject;
  Headers: TStringList;
  Raw, ImgBytes: RawByteString;
  Code, Tries: Integer;
  Data, PollData: TJSONData;
begin
  Result := False;
  AOutputFile := AConfig.OutputFile;
  Url := Trim(AConfig.Endpoint);
  if Url = '' then Url := FDefaultEndpoint;

  ReqObj := TJSONObject.Create;
  Headers := TStringList.Create;
  try
    ReqObj.Add('prompt', AConfig.Prompt);
    ReqObj.Add('width', AConfig.Width);
    ReqObj.Add('height', AConfig.Height);
    if AConfig.Token <> '' then
      Headers.Add('x-key=' + AConfig.Token);

    if not HttpPostJsonRaw(Url, ReqObj.AsJSON, Headers, AConfig.Timeout, Raw, Code) then
      Exit;

    Data := GetJSON(Raw);
    try
      if not (Data is TJSONObject) then Exit;
      PollUrl := TJSONObject(Data).Get('polling_url', '');
    finally
      Data.Free;
    end;

    if PollUrl = '' then
    begin
      SetLastError('BFL Flux nao retornou polling_url.');
      Exit;
    end;

    for Tries := 1 to 90 do
    begin
      if IsCancelled then Exit;
      Sleep(1000);
      if not HttpGetRaw(PollUrl, Headers, AConfig.Timeout, Raw, Code) then Continue;
      PollData := GetJSON(Raw);
      try
        if PollData is TJSONObject then
        begin
          StatusStr := TJSONObject(PollData).Get('status', '');
          if SameText(StatusStr, 'Ready') and (TJSONObject(PollData).Find('result') is TJSONObject) then
          begin
            ImgUrl := TJSONObject(TJSONObject(PollData).Find('result')).Get('sample', '');
            if (ImgUrl <> '') and HttpGetRaw(ImgUrl, nil, AConfig.Timeout, ImgBytes, Code) then
              Result := SaveBytesToFile(ImgBytes, AOutputFile);
            Exit;
          end;
          if SameText(StatusStr, 'Error') or SameText(StatusStr, 'Failed') then
          begin
            SetLastError('BFL Flux falhou: ' + Copy(Raw, 1, 200));
            Exit;
          end;
        end;
      finally
        PollData.Free;
      end;
    end;
    SetLastError('Timeout aguardando BFL Flux.');
  finally
    Headers.Free;
    ReqObj.Free;
  end;
end;

{ TAIImageHuggingFaceProvider }

constructor TAIImageHuggingFaceProvider.Create;
begin
  inherited Create;
  SetIdentity('huggingface', 'HuggingFace Inference Images',
    'https://api-inference.huggingface.co/models/');
end;

function TAIImageHuggingFaceProvider.Generate(const AConfig: TAIImageProviderConfig;
  out AOutputFile: string): Boolean;
var
  Url, ModelName: string;
  ReqObj: TJSONObject;
  Headers: TStringList;
  Raw: RawByteString;
  Code: Integer;
begin
  Result := False;
  AOutputFile := AConfig.OutputFile;
  Url := TrimBaseUrl(AConfig.Endpoint);
  if Url = '' then Url := TrimBaseUrl(FDefaultEndpoint);
  ModelName := Trim(AConfig.Model);
  if ModelName = '' then ModelName := 'black-forest-labs/FLUX.1-schnell';
  if Pos('/models/', LowerCase(Url)) = Length(Url) - 7 then
    Url := Url + '/' + ModelName
  else if (Pos('huggingface.co', LowerCase(Url)) > 0) and (Pos(LowerCase(ModelName), LowerCase(Url)) = 0) then
    Url := Url + '/' + ModelName;

  ReqObj := TJSONObject.Create;
  Headers := TStringList.Create;
  try
    ReqObj.Add('inputs', AConfig.Prompt);
    if AConfig.Token <> '' then
      Headers.Add('Authorization=Bearer ' + AConfig.Token);
    if HttpPostJsonRaw(Url, ReqObj.AsJSON, Headers, AConfig.Timeout, Raw, Code) then
      Result := SaveBytesToFile(Raw, AOutputFile);
  finally
    Headers.Free;
    ReqObj.Free;
  end;
end;

{ TAIImageProviderFactory }

class function TAIImageProviderFactory.CreateProvider(
  AKind: TAIImageProviderKind): IAIImageProvider;
begin
  case AKind of
    imgOpenAI: Result := TAIImageOpenAIProvider.Create;
    imgOpenAICompatible: Result := TAIImageOpenAICompatibleProvider.Create;
    imgGemini: Result := TAIImageGeminiProvider.Create;
    imgStability: Result := TAIImageStabilityProvider.Create;
    imgBlackForestLabs: Result := TAIImageBFLProvider.Create;
    imgComfyUI: Result := TAIImageComfyUIProvider.Create;
    imgAutomatic1111: Result := TAIImageAutomatic1111Provider.Create;
    imgHuggingFace: Result := TAIImageHuggingFaceProvider.Create;
  else
    Result := TAIImageOpenAICompatibleProvider.Create;
  end;
end;

class function TAIImageProviderFactory.KindFromName(
  const AName: string): TAIImageProviderKind;
var
  S: string;
begin
  S := LowerCase(Trim(AName));
  if (Pos('comfy', S) > 0) then Result := imgComfyUI
  else if (Pos('automatic', S) > 0) or (Pos('a1111', S) > 0) or (Pos('forge', S) > 0) then Result := imgAutomatic1111
  else if (Pos('stability', S) > 0) or (Pos('sd3', S) > 0) then Result := imgStability
  else if (Pos('bfl', S) > 0) or (Pos('flux', S) > 0) then Result := imgBlackForestLabs
  else if (Pos('gemini', S) > 0) or (Pos('imagen', S) > 0) then Result := imgGemini
  else if (Pos('hugging', S) > 0) then Result := imgHuggingFace
  else if SameText(S, 'openai') then Result := imgOpenAI
  else Result := imgOpenAICompatible;
end;

end.
