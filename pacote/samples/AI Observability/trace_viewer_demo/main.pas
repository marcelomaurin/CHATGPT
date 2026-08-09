unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, ComCtrls, StdCtrls, ExtCtrls, aitrace;

type
  TTraceViewerForm = class(TForm)
  private
    FTrace: TAITrace;
    FTree: TTreeView;
    FDetails: TMemo;
    procedure SelectionChanged(Sender: TObject; Node: TTreeNode);
    procedure Populate;
  public
    constructor Create(AOwner: TComponent); override;
  end;

var TraceViewerForm: TTraceViewerForm;

implementation

constructor TTraceViewerForm.Create(AOwner: TComponent);
var Root, AgentSpan, RAGSpan, ToolSpan: string;
begin
  inherited CreateNew(AOwner, 1);
  Caption := 'Lazarus AI Trace Viewer';
  Width := 980;
  Height := 620;
  Position := poScreenCenter;

  FTree := TTreeView.Create(Self);
  FTree.Parent := Self;
  FTree.Align := alLeft;
  FTree.Width := 360;
  FTree.OnChange := @SelectionChanged;

  with TSplitter.Create(Self) do begin Parent := Self; Align := alLeft; end;
  FDetails := TMemo.Create(Self);
  FDetails.Parent := Self;
  FDetails.Align := alClient;
  FDetails.ReadOnly := True;
  FDetails.ScrollBars := ssAutoBoth;

  FTrace := TAITrace.Create(Self);
  FTrace.StartTrace;
  Root := FTrace.BeginSpan('workflow', 'Pergunta ate resposta', '', '{}');
  AgentSpan := FTrace.BeginSpan('agent', 'Planejar resposta', Root,
    '{"input_chars":42}');
  RAGSpan := FTrace.BeginSpan('rag', 'Recuperar contexto', AgentSpan,
    '{"top_k":4}');
  FTrace.AddEvent(RAGSpan, 'chunk_selected', '{"source":"manual.pdf","score":0.91}');
  FTrace.EndSpan(RAGSpan, '', '{"returned":1}');
  ToolSpan := FTrace.BeginSpan('tool', 'consultar_status', AgentSpan, '{}');
  FTrace.EndSpan(ToolSpan, '', '{"success":true}');
  FTrace.EndSpan(AgentSpan, '', '{"action":"respond"}');
  FTrace.EndSpan(Root, '', '{"success":true}');
  Populate;
end;

procedure TTraceViewerForm.Populate;
var
  Root, Node, ParentNode: TTreeNode;
  I, J: Integer;
begin
  FTree.Items.Clear;
  Root := FTree.Items.Add(nil, 'Trace ' + FTrace.TraceID);
  for I := 0 to FTrace.Count - 1 do
  begin
    ParentNode := Root;
    if FTrace[I].ParentSpanID <> '' then
      for J := 0 to FTree.Items.Count - 1 do
        if (FTree.Items[J].Data <> nil) and
          (TAITraceSpan(FTree.Items[J].Data).SpanID = FTrace[I].ParentSpanID) then
        begin ParentNode := FTree.Items[J]; Break; end;
    Node := FTree.Items.AddChildObject(ParentNode,
      FTrace[I].Kind + ': ' + FTrace[I].Name, FTrace[I]);
    if FTrace[I].ErrorMessage <> '' then Node.ImageIndex := 1;
  end;
  Root.Expand(True);
  FDetails.Lines.Text := FTrace.ToJSON;
end;

procedure TTraceViewerForm.SelectionChanged(Sender: TObject; Node: TTreeNode);
var Span: TAITraceSpan;
begin
  if (Node = nil) or (Node.Data = nil) then
  begin FDetails.Lines.Text := FTrace.ToJSON; Exit; end;
  Span := TAITraceSpan(Node.Data);
  FDetails.Lines.Text := 'SpanID: ' + Span.SpanID + LineEnding +
    'Parent: ' + Span.ParentSpanID + LineEnding +
    'Kind: ' + Span.Kind + LineEnding + 'Name: ' + Span.Name + LineEnding +
    'Duration: ' + IntToStr(Span.DurationMs) + ' ms' + LineEnding +
    'Error: ' + Span.ErrorMessage + LineEnding + LineEnding +
    'Start metadata:' + LineEnding + Span.StartMetadataJSON + LineEnding +
    'End metadata:' + LineEnding + Span.EndMetadataJSON + LineEnding +
    'Events:' + LineEnding + Span.Events.Text;
end;

end.
