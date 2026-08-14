unit aitrace;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Contnrs, DateUtils, fpjson, jsonparser, aibase,
  aitracebridge, LResources;

type
  TAITraceSpan = class
  private
    FEvents: TStringList;
  public
    SpanID: string;
    ParentSpanID: string;
    Kind: string;
    Name: string;
    StartedAt: TDateTime;
    EndedAt: TDateTime;
    DurationMs: Int64;
    ErrorMessage: string;
    StartMetadataJSON: string;
    EndMetadataJSON: string;
    constructor Create;
    destructor Destroy; override;
    property Events: TStringList read FEvents;
  end;

  TAITrace = class(TAIBaseComponent, IAITraceSink)
  private
    FTraceID: string;
    FSpans: TObjectList;
    FIncludeSensitiveContent: Boolean;
    FSequence: QWord;
    function GetCount: Integer;
    function GetSpan(AIndex: Integer): TAITraceSpan;
    function FindSpan(const ASpanID: string): TAITraceSpan;
    function NewID(const APrefix: string): string;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Clear;
    procedure StartTrace(const ATraceID: string = '');
    function EnsureTraceID: string;
    function BeginSpan(const AKind, AName, AParentSpanID,
      AMetadataJSON: string): string;
    procedure AddEvent(const ASpanID, AName, AMetadataJSON: string);
    procedure EndSpan(const ASpanID, AError, AMetadataJSON: string);
    function SensitiveContentEnabled: Boolean;
    function ToJSON: string;
    procedure SaveToFile(const AFileName: string);
    property Count: Integer read GetCount;
    property Spans[AIndex: Integer]: TAITraceSpan read GetSpan; default;
  published
    property TraceID: string read FTraceID;
    property IncludeSensitiveContent: Boolean read FIncludeSensitiveContent
      write FIncludeSensitiveContent default False;
  end;

procedure Register;

implementation

function ISOTime(AValue: TDateTime): string;
begin
  if AValue = 0 then Exit('');
  Result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz', AValue);
end;

function SafeJSON(const AJSON: string): TJSONData;
begin
  if Trim(AJSON) = '' then Exit(TJSONObject.Create);
  try
    Result := GetJSON(AJSON);
  except
    Result := TJSONObject.Create(['raw', AJSON]);
  end;
end;

procedure Register;
begin RegisterComponents('AI Observability', [TAITrace]); end;

constructor TAITraceSpan.Create;
begin inherited Create; FEvents := TStringList.Create; end;

destructor TAITraceSpan.Destroy;
begin FEvents.Free; inherited Destroy; end;

constructor TAITrace.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccOther;
  FSpans := TObjectList.Create(True);
  FIncludeSensitiveContent := False;
end;

destructor TAITrace.Destroy;
begin FSpans.Free; inherited Destroy; end;

procedure TAITrace.Clear;
begin
  FSpans.Clear;
  FTraceID := '';
  FSequence := 0;
end;

function TAITrace.NewID(const APrefix: string): string;
begin
  Inc(FSequence);
  Result := APrefix + '-' + IntToHex(GetTickCount64, 12) + '-' +
    IntToHex(FSequence, 8);
end;

procedure TAITrace.StartTrace(const ATraceID: string);
begin
  FSpans.Clear;
  FSequence := 0;
  if Trim(ATraceID) <> '' then FTraceID := ATraceID
  else FTraceID := NewID('trace');
end;

function TAITrace.EnsureTraceID: string;
begin
  if FTraceID = '' then StartTrace;
  Result := FTraceID;
end;

function TAITrace.GetCount: Integer;
begin Result := FSpans.Count; end;

function TAITrace.GetSpan(AIndex: Integer): TAITraceSpan;
begin Result := TAITraceSpan(FSpans[AIndex]); end;

function TAITrace.FindSpan(const ASpanID: string): TAITraceSpan;
var I: Integer;
begin
  Result := nil;
  for I := 0 to FSpans.Count - 1 do
    if SameText(Spans[I].SpanID, ASpanID) then Exit(Spans[I]);
end;

function TAITrace.BeginSpan(const AKind, AName, AParentSpanID,
  AMetadataJSON: string): string;
var Span: TAITraceSpan;
begin
  EnsureTraceID;
  Span := TAITraceSpan.Create;
  Span.SpanID := NewID('span');
  Span.ParentSpanID := AParentSpanID;
  Span.Kind := AKind;
  Span.Name := AName;
  Span.StartedAt := Now;
  Span.StartMetadataJSON := AMetadataJSON;
  FSpans.Add(Span);
  Result := Span.SpanID;
end;

procedure TAITrace.AddEvent(const ASpanID, AName, AMetadataJSON: string);
var
  Span: TAITraceSpan;
  Obj: TJSONObject;
begin
  Span := FindSpan(ASpanID);
  if Span = nil then Exit;
  Obj := TJSONObject.Create;
  try
    Obj.Add('timestamp', ISOTime(Now));
    Obj.Add('name', AName);
    Obj.Add('metadata', SafeJSON(AMetadataJSON));
    Span.Events.Add(Obj.AsJSON);
  finally Obj.Free; end;
end;

procedure TAITrace.EndSpan(const ASpanID, AError, AMetadataJSON: string);
var Span: TAITraceSpan;
begin
  Span := FindSpan(ASpanID);
  if Span = nil then Exit;
  Span.EndedAt := Now;
  Span.DurationMs := MilliSecondsBetween(Span.EndedAt, Span.StartedAt);
  Span.ErrorMessage := AError;
  Span.EndMetadataJSON := AMetadataJSON;
end;

function TAITrace.SensitiveContentEnabled: Boolean;
begin Result := FIncludeSensitiveContent; end;

function TAITrace.ToJSON: string;
var
  Root, Obj: TJSONObject;
  Arr, EventArr: TJSONArray;
  I, J: Integer;
begin
  Root := TJSONObject.Create;
  try
    Root.Add('trace_id', EnsureTraceID);
    Root.Add('include_sensitive_content', FIncludeSensitiveContent);
    Arr := TJSONArray.Create;
    Root.Add('spans', Arr);
    for I := 0 to Count - 1 do
    begin
      Obj := TJSONObject.Create;
      Obj.Add('span_id', Spans[I].SpanID);
      Obj.Add('parent_span_id', Spans[I].ParentSpanID);
      Obj.Add('kind', Spans[I].Kind);
      Obj.Add('name', Spans[I].Name);
      Obj.Add('started_at', ISOTime(Spans[I].StartedAt));
      Obj.Add('ended_at', ISOTime(Spans[I].EndedAt));
      Obj.Add('duration_ms', Spans[I].DurationMs);
      if Spans[I].ErrorMessage <> '' then
        Obj.Add('error', Spans[I].ErrorMessage);
      Obj.Add('start_metadata', SafeJSON(Spans[I].StartMetadataJSON));
      Obj.Add('end_metadata', SafeJSON(Spans[I].EndMetadataJSON));
      EventArr := TJSONArray.Create;
      Obj.Add('events', EventArr);
      for J := 0 to Spans[I].Events.Count - 1 do
        EventArr.Add(SafeJSON(Spans[I].Events[J]));
      Arr.Add(Obj);
    end;
    Result := Root.FormatJSON;
  finally Root.Free; end;
end;

procedure TAITrace.SaveToFile(const AFileName: string);
var S: TStringList;
begin
  ForceDirectories(ExtractFileDir(ExpandFileName(AFileName)));
  S := TStringList.Create;
  try S.Text := ToJSON; S.SaveToFile(AFileName); finally S.Free; end;
end;

initialization
  {$I aitrace_icon.lrs}

end.
