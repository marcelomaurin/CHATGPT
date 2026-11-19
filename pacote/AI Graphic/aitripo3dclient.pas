unit aitripo3dclient;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpclient, opensslsockets, fpjson, jsonparser, aibase, LResources;

const
  Tripo3DV3BaseURL = 'https://openapi.tripo3d.ai/v3';
  Tripo3DV3TextPath = '/generation/text-to-model';
  Tripo3DV3ImagePath = '/generation/image-to-model';
  Tripo3DV3FilesPath = '/files';
  Tripo3DV3TaskPath = '/tasks/';

type
  TTripoMode = (tmImageTo3D, tmMultiViewTo3D, tmTextTo3D);
  TTripoFormat = (tfSTL, tfOBJ, tfGLB, tfFBX);

  TNotifyProgressEvent = procedure(Sender: TObject; AProgress: Integer) of object;
  TNotifyErrorEvent = procedure(Sender: TObject; const AError: string) of object;
  TNotifyFileEvent = procedure(Sender: TObject; const AFileName: string) of object;

  { TAITripo3DClient }

  TAITripo3DClient = class(TAIBaseComponent)
  private
    FAPIKey: string;
    FBaseURL: string;
    FModelVersion: string;
    FGenerationMode: TTripoMode;
    FOutputFormat: TTripoFormat;
    FLastTaskId: string;
    FPollingInterval: Integer;
    FOnTaskCreated: TNotifyEvent;
    FOnProgressChanged: TNotifyProgressEvent;
    FOnGenerationCompleted: TNotifyEvent;
    FOnGenerationFailed: TNotifyErrorEvent;
    FOnModelReady: TNotifyFileEvent;

    function GetAPIKey: string;
    procedure SetAPIKey(const AValue: string);
    function ExecuteRequest(const AEndpoint: string; const APayload: string): string;
  public
    constructor Create(AOwner: TComponent); override;
    function GenerateFromImage(const AImagePath: string): Boolean;
    function GenerateFromMultiView(AImages: TStrings): Boolean;
    function GenerateFromText(const APrompt: string): Boolean;
    function CheckStatus(const ATaskId: string; var AProgress: Integer; var ADownloadURL: string): string;
    function DownloadModel(const AURL, AOutputFileName: string): Boolean;
  published
    property APIKey: string read GetAPIKey write SetAPIKey stored False;
    property BaseURL: string read FBaseURL write FBaseURL;
    property ModelVersion: string read FModelVersion write FModelVersion;
    property GenerationMode: TTripoMode read FGenerationMode write FGenerationMode default tmTextTo3D;
    property OutputFormat: TTripoFormat read FOutputFormat write FOutputFormat default tfSTL;
    property LastTaskId: string read FLastTaskId write FLastTaskId;
    property PollingInterval: Integer read FPollingInterval write FPollingInterval default 5000;
    
    property OnTaskCreated: TNotifyEvent read FOnTaskCreated write FOnTaskCreated;
    property OnProgressChanged: TNotifyProgressEvent read FOnProgressChanged write FOnProgressChanged;
    property OnGenerationCompleted: TNotifyEvent read FOnGenerationCompleted write FOnGenerationCompleted;
    property OnGenerationFailed: TNotifyErrorEvent read FOnGenerationFailed write FOnGenerationFailed;
    property OnModelReady: TNotifyFileEvent read FOnModelReady write FOnModelReady;
  end;

  TTripoTransport = procedure(const URL, Token, Payload: string;
    Destination: TStream; MaxBytes: Int64) of object;

  TTripoUploadTransport = procedure(const URL, Token, ContentType: string;
    const Payload: RawByteString; Destination: TStream; MaxBytes: Int64) of object;

  { Text and image to 3D on the current Tripo API. The legacy client remains available
    for callers of the older image and multiview endpoints. }
  TAITripo3DV3Client = class(TAIBaseComponent)
  private
    FTransport: TTripoTransport;
    FUploadTransport: TTripoUploadTransport;
    FAPIKey, FBaseURL, FModelVersion, FLastTaskId: string;
    function GetAPIKey: string;
    function RequestData(const Endpoint: string; const Payload: RawByteString;
      const ContentType: string = ''): TJSONObject;
    function Submit(const SourceField, SourceValue, Endpoint: string): string;
    procedure Request(const URL, Token, Payload: string;
      Destination: TStream; MaxBytes: Int64);
  public
    constructor Create(AOwner: TComponent); override;
    function SubmitText(const APrompt: string): string;
    function UploadImage(Image: TStream): string;
    function SubmitImage(const FileToken: string): string;
    function PollTask(const ATaskId: string; out ADownloadURL: string): string;
    procedure FetchGLB(const AURL: string; Destination: TStream; MaxBytes: Int64);
    { The caller supplies a TLS transport appropriate to its platform. }
    property Transport: TTripoTransport read FTransport write FTransport;
    property UploadTransport: TTripoUploadTransport read FUploadTransport write FUploadTransport;
    property LastTaskId: string read FLastTaskId;
  published
    property APIKey: string read GetAPIKey write FAPIKey stored False;
    property BaseURL: string read FBaseURL write FBaseURL;
    property ModelVersion: string read FModelVersion write FModelVersion;
  end;

procedure GetTripo3DGenerationModels(AList: TStrings);
procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graphic', [TAITripo3DClient, TAITripo3DV3Client]);
end;

{ TAITripo3DClient }

constructor TAITripo3DClient.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FPrompt := 'Component TAITripo3DClient connects to Tripo3D API for 3D model generation from text, single image, or multiple images. Properties: APIKey, BaseURL, ModelVersion, GenerationMode, OutputFormat, PollingInterval. Methods: GenerateFromImage, GenerateFromMultiView, GenerateFromText, CheckStatus, DownloadModel.';
  FBaseURL := 'https://api.tripo3d.ai';
  FModelVersion := 'v2.0';
  FGenerationMode := tmTextTo3D;
  FOutputFormat := tfSTL;
  FAPIKey := '';
  FLastTaskId := '';
  FPollingInterval := 5000;
  ClearError;
end;

function TAITripo3DClient.GetAPIKey: string;
begin
  if FAPIKey <> '' then
    Result := FAPIKey
  else
    Result := GetEnvironmentVariable('TRIPO3D_API_KEY');
end;

procedure TAITripo3DClient.SetAPIKey(const AValue: string);
begin
  FAPIKey := AValue;
end;

function TAITripo3DClient.ExecuteRequest(const AEndpoint: string; const APayload: string): string;
var
  Client: TFPHttpClient;
  RequestBody: TStringStream;
  LURL: string;
  LKey: string;
begin
  Result := '';
  LKey := GetAPIKey;
  if LKey = '' then
  begin
    SetError('Tripo3D API Key is empty.');
    Exit;
  end;

  Client := TFPHttpClient.Create(nil);
  RequestBody := TStringStream.Create(APayload);
  try
    Client.AddHeader('Content-Type', 'application/json');
    Client.AddHeader('Authorization', 'Bearer ' + LKey);
    Client.RequestBody := RequestBody;
    
    LURL := FBaseURL + AEndpoint;
    Log(llInfo, 'Requesting Tripo3D API: ' + LURL);
    try
      Result := Client.Post(LURL);
    except
      on E: Exception do
      begin
        SetError('Tripo3D API request failed: ' + E.Message);
        if Assigned(FOnGenerationFailed) then
          FOnGenerationFailed(Self, E.Message);
      end;
    end;
  finally
    RequestBody.Free;
    Client.Free;
  end;
end;

function TAITripo3DClient.GenerateFromImage(const AImagePath: string): Boolean;
var
  Payload: TJSONObject;
  ResponseStr: string;
  JSONData: TJSONData;
  JSONObj, DataObj: TJSONObject;
begin
  Result := False;
  ClearError;
  Log(llInfo, 'Generating 3D model from image: ' + AImagePath);

  Payload := TJSONObject.Create;
  try
    Payload.Add('type', 'image_to_model');
    // In practice, we upload the file or pass a public URL. Here we pass image path.
    Payload.Add('file_path', AImagePath);
    Payload.Add('model_version', FModelVersion);
    
    ResponseStr := ExecuteRequest('/v2/openapi/task', Payload.AsJSON);
    if ResponseStr = '' then Exit;

    JSONData := GetJSON(ResponseStr);
    try
      if JSONData.JSONType = jtObject then
      begin
        JSONObj := TJSONObject(JSONData);
        if JSONObj.IndexOfName('data') >= 0 then
        begin
          DataObj := JSONObj.Objects['data'];
          FLastTaskId := DataObj.Strings['task_id'];
          Log(llInfo, 'Task created successfully. Task ID: ' + FLastTaskId);
          Result := True;
          if Assigned(FOnTaskCreated) then
            FOnTaskCreated(Self);
        end
        else if JSONObj.IndexOfName('error') >= 0 then
        begin
          SetError('Tripo3D Error: ' + JSONObj.Strings['error']);
        end;
      end;
    finally
      JSONData.Free;
    end;
  finally
    Payload.Free;
  end;
end;

function TAITripo3DClient.GenerateFromMultiView(AImages: TStrings): Boolean;
var
  Payload: TJSONObject;
  ImagesArr: TJSONArray;
  ResponseStr: string;
  JSONData: TJSONData;
  JSONObj, DataObj: TJSONObject;
  I: Integer;
begin
  Result := False;
  ClearError;
  Log(llInfo, 'Generating 3D model from multi-view images.');

  Payload := TJSONObject.Create;
  ImagesArr := TJSONArray.Create;
  try
    Payload.Add('type', 'multiview_to_model');
    for I := 0 to AImages.Count - 1 do
      ImagesArr.Add(AImages[I]);
    Payload.Add('images', ImagesArr);
    Payload.Add('model_version', FModelVersion);
    
    ResponseStr := ExecuteRequest('/v2/openapi/task', Payload.AsJSON);
    if ResponseStr = '' then Exit;

    JSONData := GetJSON(ResponseStr);
    try
      if JSONData.JSONType = jtObject then
      begin
        JSONObj := TJSONObject(JSONData);
        if JSONObj.IndexOfName('data') >= 0 then
        begin
          DataObj := JSONObj.Objects['data'];
          FLastTaskId := DataObj.Strings['task_id'];
          Log(llInfo, 'Multi-view task created. Task ID: ' + FLastTaskId);
          Result := True;
          if Assigned(FOnTaskCreated) then
            FOnTaskCreated(Self);
        end
        else if JSONObj.IndexOfName('error') >= 0 then
        begin
          SetError('Tripo3D Error: ' + JSONObj.Strings['error']);
        end;
      end;
    finally
      JSONData.Free;
    end;
  finally
    Payload.Free;
  end;
end;

function TAITripo3DClient.GenerateFromText(const APrompt: string): Boolean;
var
  Payload: TJSONObject;
  ResponseStr: string;
  JSONData: TJSONData;
  JSONObj, DataObj: TJSONObject;
begin
  Result := False;
  ClearError;
  Log(llInfo, 'Generating 3D model from prompt: ' + APrompt);

  Payload := TJSONObject.Create;
  try
    Payload.Add('type', 'text_to_model');
    Payload.Add('prompt', APrompt);
    Payload.Add('model_version', FModelVersion);
    
    ResponseStr := ExecuteRequest('/v2/openapi/task', Payload.AsJSON);
    if ResponseStr = '' then Exit;

    JSONData := GetJSON(ResponseStr);
    try
      if JSONData.JSONType = jtObject then
      begin
        JSONObj := TJSONObject(JSONData);
        if JSONObj.IndexOfName('data') >= 0 then
        begin
          DataObj := JSONObj.Objects['data'];
          FLastTaskId := DataObj.Strings['task_id'];
          Log(llInfo, 'Text task created. Task ID: ' + FLastTaskId);
          Result := True;
          if Assigned(FOnTaskCreated) then
            FOnTaskCreated(Self);
        end
        else if JSONObj.IndexOfName('error') >= 0 then
        begin
          SetError('Tripo3D Error: ' + JSONObj.Strings['error']);
        end;
      end;
    finally
      JSONData.Free;
    end;
  finally
    Payload.Free;
  end;
end;

function TAITripo3DClient.CheckStatus(const ATaskId: string; var AProgress: Integer; var ADownloadURL: string): string;
var
  ResponseStr: string;
  JSONData: TJSONData;
  JSONObj, DataObj: TJSONObject;
begin
  Result := 'failed';
  AProgress := 0;
  ADownloadURL := '';
  ClearError;

  ResponseStr := ExecuteRequest('/v2/openapi/task/' + ATaskId, '');
  if ResponseStr = '' then Exit;

  JSONData := GetJSON(ResponseStr);
  try
    if JSONData.JSONType = jtObject then
    begin
      JSONObj := TJSONObject(JSONData);
      if JSONObj.IndexOfName('data') >= 0 then
      begin
        DataObj := JSONObj.Objects['data'];
        Result := DataObj.Strings['status']; // 'queued', 'running', 'success', 'failed'
        AProgress := DataObj.Integers['progress'];
        
        Log(llInfo, Format('Task %s status: %s (Progress: %d%%)', [ATaskId, Result, AProgress]));
        
        if Assigned(FOnProgressChanged) then
          FOnProgressChanged(Self, AProgress);
          
        if Result = 'success' then
        begin
          if DataObj.IndexOfName('result') >= 0 then
          begin
            // Typically Result format mapping
            ADownloadURL := DataObj.Objects['result'].Strings['model'];
            if Assigned(FOnGenerationCompleted) then
              FOnGenerationCompleted(Self);
          end;
        end
        else if Result = 'failed' then
        begin
          SetError('Tripo3D task failed.');
        end;
      end;
    end;
  finally
    JSONData.Free;
  end;
end;

function TAITripo3DClient.DownloadModel(const AURL, AOutputFileName: string): Boolean;
var
  Client: TFPHttpClient;
  FileStream: TFileStream;
begin
  Result := False;
  ClearError;
  Log(llInfo, 'Downloading model from: ' + AURL);
  
  Client := TFPHttpClient.Create(nil);
  FileStream := TFileStream.Create(AOutputFileName, fmCreate);
  try
    try
      Client.Get(AURL, FileStream);
      Result := True;
      Log(llInfo, 'Model downloaded successfully to: ' + AOutputFileName);
      if Assigned(FOnModelReady) then
        FOnModelReady(Self, AOutputFileName);
    except
      on E: Exception do
      begin
        SetError('Failed to download model: ' + E.Message);
      end;
    end;
  finally
    FileStream.Free;
    Client.Free;
  end;
end;

const
  Tripo3DGeometryModels: array[0..4] of string = ('v3.1-20260211',
    'v3.0-20250812', 'v2.5-20250123', 'P2-20260801', 'P1-20260311');

procedure GetTripo3DGenerationModels(AList: TStrings);
var
  ModelID: string;
begin
  AList.Clear;
  for ModelID in Tripo3DGeometryModels do AList.Add(ModelID);
end;

constructor TAITripo3DV3Client.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BaseURL := Tripo3DV3BaseURL;
  ModelVersion := Tripo3DGeometryModels[0];
  FCategory := ccOther;
end;

function TAITripo3DV3Client.GetAPIKey: string;
begin
  Result := FAPIKey;
  if Result = '' then Result := GetEnvironmentVariable('TRIPO3D_API_KEY');
end;

procedure TAITripo3DV3Client.Request(const URL, Token, Payload: string;
  Destination: TStream; MaxBytes: Int64);
begin
  if not SameText(Copy(URL, 1, 8), 'https://') then
    raise Exception.Create('Tripo requires an HTTPS URL.');
  if not Assigned(FTransport) then
    raise Exception.Create('Configure an HTTPS transport for Tripo API v3.');
  FTransport(URL, Token, Payload, Destination, MaxBytes);
end;

function TAITripo3DV3Client.RequestData(const Endpoint: string;
  const Payload: RawByteString; const ContentType: string): TJSONObject;
var
  Response: TStringStream;
  JSON: TJSONData;
  Data: TJSONObject;
  Token: string;
begin
  Token := APIKey;
  if Token = '' then raise Exception.Create('Tripo API key is missing.');
  if (Pos(#13, Token) > 0) or (Pos(#10, Token) > 0) then
    raise Exception.Create('Invalid Tripo API key.');
  Response := TStringStream.Create('');
  try
    if ContentType <> '' then
    begin
      if not SameText(Copy(BaseURL, 1, 8), 'https://') then
        raise Exception.Create('Tripo requires an HTTPS URL.');
      if not Assigned(FUploadTransport) then
        raise Exception.Create('Configure an HTTPS upload transport for Tripo API v3.');
      FUploadTransport(BaseURL + Endpoint, Token, ContentType, Payload, Response, 1024 * 1024);
    end
    else
      Request(BaseURL + Endpoint, Token, Payload, Response, 1024 * 1024);
    JSON := GetJSON(Response.DataString, True);
    try
      if not (JSON is TJSONObject) or (TJSONObject(JSON).Get('code', -1) <> 0) then
        raise Exception.Create('Tripo rejected the request.');
      Data := TJSONObject(JSON).Get('data', TJSONObject(nil));
      if Data = nil then raise Exception.Create('Tripo did not return task data.');
      Result := TJSONObject(Data.Clone);
    finally
      JSON.Free;
    end;
  finally
    Response.Free;
  end;
end;

function TAITripo3DV3Client.Submit(const SourceField, SourceValue,
  Endpoint: string): string;
var
  Payload, Data: TJSONObject;
begin
  Payload := TJSONObject.Create;
  try
    Payload.Add(SourceField, SourceValue);
    Payload.Add('model', ModelVersion);
    Payload.Add('texture', True);
    Payload.Add('pbr', True);
    Payload.Add('face_limit', 10000);
    if SameText(ModelVersion, 'P2-20260801') then Payload.Add('quad', False);
    Data := RequestData(Endpoint, Payload.AsJSON);
    try
      Result := Data.Get('task_id', '');
      if Result = '' then raise Exception.Create('Tripo did not return a task ID.');
      FLastTaskId := Result;
    finally
      Data.Free;
    end;
  finally
    Payload.Free;
  end;
end;

function TAITripo3DV3Client.SubmitText(const APrompt: string): string;
begin
  Result := Submit('prompt', APrompt, Tripo3DV3TextPath);
end;

function TAITripo3DV3Client.SubmitImage(const FileToken: string): string;
begin
  if Copy(FileToken, 1, 5) <> 'file_' then
    raise Exception.Create('Invalid Tripo image token.');
  Result := Submit('input', FileToken, Tripo3DV3ImagePath);
end;

function TAITripo3DV3Client.UploadImage(Image: TStream): string;
const
  MaxImageBytes = 20000000;
  CRLF = #13#10;
var
  Header, Tail, Payload: RawByteString;
  Boundary, UploadName, MimeType: string;
  Signature: array[0..7] of Byte;
  ID: TGuid;
  Data: TJSONObject;
  ImageSize, Offset: Integer;
begin
  if (Image.Size < SizeOf(Signature)) or (Image.Size > MaxImageBytes) then
    raise Exception.Create('Tripo accepts PNG or JPEG images up to 20 MB.');
  ImageSize := Image.Size;
  Image.Position := 0;
  Image.ReadBuffer(Signature, SizeOf(Signature));
  if (Signature[0] = $89) and (Signature[1] = $50) and
    (Signature[2] = $4E) and (Signature[3] = $47) and
    (Signature[4] = $0D) and (Signature[5] = $0A) and
    (Signature[6] = $1A) and (Signature[7] = $0A) then
  begin
    UploadName := 'reference.png';
    MimeType := 'image/png';
  end
  else if (Signature[0] = $FF) and (Signature[1] = $D8) and (Signature[2] = $FF) then
  begin
    UploadName := 'reference.jpg';
    MimeType := 'image/jpeg';
  end
  else
    raise Exception.Create('Tripo accepts PNG or JPEG images.');
  if CreateGUID(ID) <> 0 then raise Exception.Create('Could not create upload boundary.');
  Boundary := 'Tripo-' + Copy(GUIDToString(ID), 2, 36);
  Header := '--' + Boundary + CRLF +
    'Content-Disposition: form-data; name="file"; filename="' + UploadName + '"' + CRLF +
    'Content-Type: ' + MimeType + CRLF + CRLF;
  Tail := CRLF + '--' + Boundary + '--' + CRLF;
  SetLength(Payload, Length(Header) + ImageSize + Length(Tail));
  Move(Header[1], Payload[1], Length(Header));
  Offset := Length(Header) + 1;
  Image.Position := 0;
  Image.ReadBuffer(Payload[Offset], ImageSize);
  Move(Tail[1], Payload[Offset + ImageSize], Length(Tail));
  Data := RequestData(Tripo3DV3FilesPath, Payload, 'multipart/form-data; boundary=' + Boundary);
  try
    Result := Data.Get('file_token', '');
    if Copy(Result, 1, 5) <> 'file_' then
      raise Exception.Create('Tripo did not return a valid file token.');
  finally
    Data.Free;
  end;
end;

function TAITripo3DV3Client.PollTask(const ATaskId: string;
  out ADownloadURL: string): string;
var
  Data, Output: TJSONObject;
  C: Char;
begin
  if ATaskId = '' then raise Exception.Create('Tripo task ID is missing.');
  for C in ATaskId do
    if not (C in ['A'..'Z', 'a'..'z', '0'..'9', '-', '_']) then
      raise Exception.Create('Invalid Tripo task ID.');
  ADownloadURL := '';
  Data := RequestData(Tripo3DV3TaskPath + ATaskId, '');
  try
    Result := LowerCase(Data.Get('status', ''));
    if Result = 'success' then
    begin
      Output := Data.Get('output', TJSONObject(nil));
      if Output <> nil then ADownloadURL := Output.Get('model_url', '');
      if ADownloadURL = '' then raise Exception.Create('Tripo did not return a GLB.');
    end;
  finally
    Data.Free;
  end;
end;

procedure TAITripo3DV3Client.FetchGLB(const AURL: string; Destination: TStream;
  MaxBytes: Int64);
begin
  Request(AURL, '', '', Destination, MaxBytes);
end;

initialization
  {$I aitripo3dclient_icon.lrs}

end.
