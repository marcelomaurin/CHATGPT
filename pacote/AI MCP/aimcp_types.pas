unit aimcp_types;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Contnrs, fpjson, jsonparser;

const
  AIMCP_PROTOCOL_VERSION = '2025-11-25';

type
  TAIMCPError = class
  public
    Code: Integer;
    MessageText: string;
    DataJSON: string;
    procedure Clear;
  end;

  TAIMCPTool = class
  public
    Name: string;
    Title: string;
    Description: string;
    InputSchema: string;
    ReadOnlyHint: Boolean;
    DestructiveHint: Boolean;
  end;

  TAIMCPResource = class
  public
    URI: string;
    Name: string;
    Title: string;
    Description: string;
    MimeType: string;
    Text: string;
    Size: Int64;
  end;

  TAIMCPPrompt = class
  public
    Name: string;
    Title: string;
    Description: string;
    ArgumentsSchema: string;
  end;

  TAIMCPRequest = class
  public
    ID: string;
    Method: string;
    ParamsJSON: string;
    function ToJSON: string;
    function Parse(const AJSON: string; out AError: string): Boolean;
  end;

  TAIMCPResponse = class
  public
    ID: string;
    ResultJSON: string;
    Error: TAIMCPError;
    constructor Create;
    destructor Destroy; override;
    function Parse(const AJSON: string; out AParseError: string): Boolean;
  end;

  TAIMCPToolList = class(TObjectList)
  public
    constructor Create;
    function AddTool: TAIMCPTool;
    function ToolAt(AIndex: Integer): TAIMCPTool;
  end;

  TAIMCPResourceList = class(TObjectList)
  public
    constructor Create;
    function AddResource: TAIMCPResource;
    function ResourceAt(AIndex: Integer): TAIMCPResource;
    function FindURI(const AURI: string): TAIMCPResource;
  end;

implementation

procedure TAIMCPError.Clear;
begin
  Code := 0;
  MessageText := '';
  DataJSON := '';
end;

function TAIMCPRequest.ToJSON: string;
var
  Obj: TJSONObject;
begin
  Obj := TJSONObject.Create;
  try
    Obj.Add('jsonrpc', '2.0');
    Obj.Add('id', ID);
    Obj.Add('method', Method);
    if Trim(ParamsJSON) = '' then Obj.Add('params', TJSONObject.Create)
    else Obj.Add('params', GetJSON(ParamsJSON));
    Result := Obj.AsJSON;
  finally
    Obj.Free;
  end;
end;

function TAIMCPRequest.Parse(const AJSON: string; out AError: string): Boolean;
var
  Data, Params: TJSONData;
  Obj: TJSONObject;
begin
  Result := False;
  AError := '';
  try Data := GetJSON(AJSON);
  except on E: Exception do begin AError := E.Message; Exit; end; end;
  try
    if not (Data is TJSONObject) then begin AError := 'Request nao e objeto.'; Exit; end;
    Obj := TJSONObject(Data);
    if Obj.Get('jsonrpc', '') <> '2.0' then begin AError := 'jsonrpc deve ser 2.0.'; Exit; end;
    ID := Obj.Get('id', '');
    Method := Obj.Get('method', '');
    Params := Obj.Find('params');
    if Params = nil then ParamsJSON := '{}' else ParamsJSON := Params.AsJSON;
    if Method = '' then begin AError := 'Metodo ausente.'; Exit; end;
    Result := True;
  finally
    Data.Free;
  end;
end;

constructor TAIMCPResponse.Create;
begin
  inherited Create;
  Error := TAIMCPError.Create;
end;

destructor TAIMCPResponse.Destroy;
begin
  Error.Free;
  inherited Destroy;
end;

function TAIMCPResponse.Parse(const AJSON: string;
  out AParseError: string): Boolean;
var
  Data, ResultData, ErrorData, ExtraData: TJSONData;
  Obj, ErrorObj: TJSONObject;
begin
  Result := False;
  AParseError := '';
  Error.Clear;
  ResultJSON := '';
  try Data := GetJSON(AJSON);
  except on E: Exception do begin AParseError := E.Message; Exit; end; end;
  try
    if not (Data is TJSONObject) then begin AParseError := 'Response nao e objeto.'; Exit; end;
    Obj := TJSONObject(Data);
    if Obj.Get('jsonrpc', '') <> '2.0' then begin AParseError := 'jsonrpc deve ser 2.0.'; Exit; end;
    ID := Obj.Get('id', '');
    ErrorData := Obj.Find('error');
    if Assigned(ErrorData) and (ErrorData is TJSONObject) then
    begin
      ErrorObj := TJSONObject(ErrorData);
      Error.Code := ErrorObj.Get('code', -32603);
      Error.MessageText := ErrorObj.Get('message', 'Erro MCP');
      ExtraData := ErrorObj.Find('data');
      if Assigned(ExtraData) then Error.DataJSON := ExtraData.AsJSON;
      Exit(True);
    end;
    ResultData := Obj.Find('result');
    if ResultData = nil then begin AParseError := 'Response sem result/error.'; Exit; end;
    ResultJSON := ResultData.AsJSON;
    Result := True;
  finally
    Data.Free;
  end;
end;

constructor TAIMCPToolList.Create;
begin
  inherited Create(True);
end;

function TAIMCPToolList.AddTool: TAIMCPTool;
begin
  Result := TAIMCPTool.Create;
  Add(Result);
end;

function TAIMCPToolList.ToolAt(AIndex: Integer): TAIMCPTool;
begin
  Result := TAIMCPTool(Items[AIndex]);
end;

constructor TAIMCPResourceList.Create;
begin
  inherited Create(True);
end;

function TAIMCPResourceList.AddResource: TAIMCPResource;
begin
  Result := TAIMCPResource.Create;
  Add(Result);
end;

function TAIMCPResourceList.ResourceAt(AIndex: Integer): TAIMCPResource;
begin
  Result := TAIMCPResource(Items[AIndex]);
end;

function TAIMCPResourceList.FindURI(const AURI: string): TAIMCPResource;
var I: Integer;
begin
  for I := 0 to Count - 1 do
    if SameText(ResourceAt(I).URI, AURI) then Exit(ResourceAt(I));
  Result := nil;
end;

end.
