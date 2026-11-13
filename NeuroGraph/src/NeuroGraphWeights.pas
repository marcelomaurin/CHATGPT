unit NeuroGraphWeights;

{$mode objfpc}{$H+}

interface

uses Classes, SysUtils;

type
  TNGWeight = Single;
  TNGWeightArray = array of TNGWeight;
  TNGEdgeWeight = packed record
    SourceID: LongWord;
    TargetID: LongWord;
    Weight: TNGWeight;
  end;
  TNGEdgeWeightArray = array of TNGEdgeWeight;

  { Binary snapshot of neural weights and directed graph edge weights.
    Node/token mapping is a separate concern. }
  TNGWeights = class
  public
    Neural: TNGWeightArray;
    Edges: TNGEdgeWeightArray;
    procedure SaveToFile(const FileName: string);
    procedure LoadFromFile(const FileName: string);
  end;

implementation

const
  MAGIC: array[0..7] of AnsiChar = ('N','G','W','G','H','T','0','1');
  VERSION = LongWord(1);
  MAX_ITEMS = 100000000;

procedure WriteU32(S: TStream; V: LongWord);
begin S.WriteBuffer(V, SizeOf(V)); end;

function ReadU32(S: TStream): LongWord;
begin S.ReadBuffer(Result, SizeOf(Result)); end;

procedure TNGWeights.SaveToFile(const FileName: string);
var S: TFileStream; I: SizeInt; W: Single; Tmp: string;
begin
  if (Length(Neural) > MAX_ITEMS) or (Length(Edges) > MAX_ITEMS) then
    raise Exception.Create('Too many weights');
  Tmp := FileName + '.tmp';
  S := TFileStream.Create(Tmp, fmCreate);
  try
    S.WriteBuffer(MAGIC, SizeOf(MAGIC));
    WriteU32(S, VERSION);
    WriteU32(S, LongWord(Length(Neural)));
    WriteU32(S, LongWord(Length(Edges)));
    for I := 0 to High(Neural) do
    begin
      W := Neural[I];
      S.WriteBuffer(W, SizeOf(W));
    end;
    for I := 0 to High(Edges) do
    begin
      WriteU32(S, Edges[I].SourceID);
      WriteU32(S, Edges[I].TargetID);
      W := Edges[I].Weight;
      S.WriteBuffer(W, SizeOf(W));
    end;
  finally S.Free; end;
  if FileExists(FileName) and (not DeleteFile(FileName)) then
    raise Exception.Create('Cannot replace old weights file');
  if not RenameFile(Tmp, FileName) then
    raise Exception.Create('Cannot finalize weights file');
end;

procedure TNGWeights.LoadFromFile(const FileName: string);
var S: TFileStream; Header: array[0..7] of AnsiChar;
    Version, NC, EC: LongWord; I: SizeInt;
    NewNeural: TNGWeightArray; NewEdges: TNGEdgeWeightArray;
begin
  S := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    S.ReadBuffer(Header, SizeOf(Header));
    if not CompareMem(@Header[0], @MAGIC[0], SizeOf(MAGIC)) then
      raise Exception.Create('Invalid NeuroGraph weights header');
    Version := ReadU32(S);
    if Version <> VERSION then raise Exception.Create('Unsupported weights version');
    NC := ReadU32(S);
    EC := ReadU32(S);
    if (NC > MAX_ITEMS) or (EC > MAX_ITEMS) or
      (Int64(NC)*SizeOf(Single) + Int64(EC)*12 > S.Size-S.Position) then
      raise Exception.Create('Invalid weights file length');
    SetLength(NewNeural, NC);
    SetLength(NewEdges, EC);
    for I := 0 to High(NewNeural) do
      S.ReadBuffer(NewNeural[I], SizeOf(Single));
    for I := 0 to High(NewEdges) do
    begin
      NewEdges[I].SourceID := ReadU32(S);
      NewEdges[I].TargetID := ReadU32(S);
      S.ReadBuffer(NewEdges[I].Weight, SizeOf(Single));
    end;
    Neural := NewNeural;
    Edges := NewEdges;
  finally S.Free; end;
end;

end.
