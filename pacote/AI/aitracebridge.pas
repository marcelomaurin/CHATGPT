unit aitracebridge;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  IAITraceSink = interface
    ['{A038FA7D-9148-4462-8BF4-177265632478}']
    function EnsureTraceID: string;
    function BeginSpan(const AKind, AName, AParentSpanID,
      AMetadataJSON: string): string;
    procedure AddEvent(const ASpanID, AName, AMetadataJSON: string);
    procedure EndSpan(const ASpanID, AError, AMetadataJSON: string);
    function SensitiveContentEnabled: Boolean;
  end;

function AITraceID(ATrace: TComponent): string;
function AITraceBegin(ATrace: TComponent; const AKind, AName,
  AParentSpanID, AMetadataJSON: string): string;
procedure AITraceEvent(ATrace: TComponent; const ASpanID, AName,
  AMetadataJSON: string);
procedure AITraceEnd(ATrace: TComponent; const ASpanID, AError,
  AMetadataJSON: string);
function AITraceAllowsSensitiveContent(ATrace: TComponent): Boolean;

implementation

function GetSink(ATrace: TComponent; out ASink: IAITraceSink): Boolean;
begin
  ASink := nil;
  Result := Assigned(ATrace) and Supports(ATrace, IAITraceSink, ASink);
end;

function AITraceID(ATrace: TComponent): string;
var Sink: IAITraceSink;
begin
  Result := '';
  if GetSink(ATrace, Sink) then Result := Sink.EnsureTraceID;
end;

function AITraceBegin(ATrace: TComponent; const AKind, AName,
  AParentSpanID, AMetadataJSON: string): string;
var Sink: IAITraceSink;
begin
  Result := '';
  if GetSink(ATrace, Sink) then
    Result := Sink.BeginSpan(AKind, AName, AParentSpanID, AMetadataJSON);
end;

procedure AITraceEvent(ATrace: TComponent; const ASpanID, AName,
  AMetadataJSON: string);
var Sink: IAITraceSink;
begin
  if GetSink(ATrace, Sink) then Sink.AddEvent(ASpanID, AName, AMetadataJSON);
end;

procedure AITraceEnd(ATrace: TComponent; const ASpanID, AError,
  AMetadataJSON: string);
var Sink: IAITraceSink;
begin
  if GetSink(ATrace, Sink) then Sink.EndSpan(ASpanID, AError, AMetadataJSON);
end;

function AITraceAllowsSensitiveContent(ATrace: TComponent): Boolean;
var Sink: IAITraceSink;
begin
  Result := GetSink(ATrace, Sink) and Sink.SensitiveContentEnabled;
end;

end.
