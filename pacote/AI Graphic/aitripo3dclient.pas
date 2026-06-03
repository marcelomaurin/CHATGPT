unit aitripo3dclient;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fphttpclient, opensslsockets, fpjson, jsonparser, aibase, LResources;

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
    property APIKey: string read GetAPIKey write SetAPIKey;
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

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Graphic', [TAITripo3DClient]);
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

initialization
  {$I aitripo3dclient_icon.lrs}

end.
