unit NeuroGraphMemoryMap;

{$mode objfpc}{$H+}

{ Token-to-node map and directed weighted graph persistence.
  Optimized with O(1) hash indices and a persistent TNeuroGraph instance. }

interface

uses
  Classes, SysUtils, Contnrs, fpjson, jsonparser, NeuroGraphCore;

type
  TNGMemoryMap = class
  private
    FTokens: TStringList;
    FTokenHash: TFPHashList;
    FLinkHash: TFPHashList;
    FGraph: TNeuroGraph;
    FLinks: array of record
      Source, Target: Integer;
      Weight: Single;
    end;
    function NormalizeToken(const S: string): string;
    function FindLink(const A, B: Integer): Integer;
    function MakeLinkKey(const A, B: Integer): ShortString; inline;
  public
    constructor Create;
    destructor Destroy; override;
    function EnsureToken(const Token: string): Integer;
    function TokenID(const Token: string): Integer;
    function TokenText(const ID: Integer): string;
    procedure Associate(const FromToken, ToToken: string; const Weight: Single);
    procedure LearnOutput(const OutputTokens: array of string;
      const Confidence: Single = 0.8; const Rate: Single = 0.1);
    function Activate(const InputTokens: array of string;
      const Decay: array of Single): TNGActivations;
    procedure SaveJSON(const FileName: string);
    procedure LoadJSON(const FileName: string);
    function TokenCount: Integer;
    function LinkCount: Integer;
  end;

implementation

function ClampWeight(const V: Single): Single;
begin
  if V < -NG_MAX_WEIGHT then Result := -NG_MAX_WEIGHT
  else if V > NG_MAX_WEIGHT then Result := NG_MAX_WEIGHT
  else Result := V;
end;

constructor TNGMemoryMap.Create;
begin
  inherited Create;
  FTokens := TStringList.Create;
  FTokens.CaseSensitive := True;
  FTokenHash := TFPHashList.Create;
  FLinkHash := TFPHashList.Create;
  FGraph := TNeuroGraph.Create(True);
end;

destructor TNGMemoryMap.Destroy;
begin
  FGraph.Free;
  FLinkHash.Free;
  FTokenHash.Free;
  FTokens.Free;
  inherited Destroy;
end;

function TNGMemoryMap.NormalizeToken(const S: string): string;
begin
  Result := UTF8Encode(UTF8Decode(Trim(S)));
  { Preserve spelling/case: no linguistic classification is imposed. }
end;

function TNGMemoryMap.MakeLinkKey(const A, B: Integer): ShortString;
begin
  Result := IntToStr(A) + ':' + IntToStr(B);
end;

function TNGMemoryMap.TokenID(const Token: string): Integer;
var
  S: string;
  P: Pointer;
begin
  S := NormalizeToken(Token);
  if S = '' then Exit(-1);
  P := FTokenHash.Find(S);
  if P = nil then Exit(-1);
  Result := PtrInt(P) - 1;
end;

function TNGMemoryMap.EnsureToken(const Token: string): Integer;
var
  S: string;
  P: Pointer;
begin
  S := NormalizeToken(Token);
  if S = '' then raise Exception.Create('Empty token');
  P := FTokenHash.Find(S);
  if P <> nil then
    Exit(PtrInt(P) - 1);
  Result := FTokens.Add(S);
  FTokenHash.Add(S, Pointer(PtrInt(Result + 1)));
end;

function TNGMemoryMap.TokenText(const ID: Integer): string;
begin
  if (ID < 0) or (ID >= FTokens.Count) then
    raise Exception.Create('Invalid token ID');
  Result := FTokens[ID];
end;

function TNGMemoryMap.FindLink(const A, B: Integer): Integer;
var
  P: Pointer;
begin
  P := FLinkHash.Find(MakeLinkKey(A, B));
  if P = nil then Exit(-1);
  Result := PtrInt(P) - 1;
end;

procedure TNGMemoryMap.Associate(const FromToken, ToToken: string;
  const Weight: Single);
var
  A, B, I: Integer;
  W: Single;
begin
  A := EnsureToken(FromToken);
  B := EnsureToken(ToToken);
  W := ClampWeight(Weight);
  I := FindLink(A, B);
  if I < 0 then
  begin
    I := Length(FLinks);
    SetLength(FLinks, I + 1);
    FLinks[I].Source := A;
    FLinks[I].Target := B;
    FLinkHash.Add(MakeLinkKey(A, B), Pointer(PtrInt(I + 1)));
  end;
  FLinks[I].Weight := W;
  FGraph.Link(A, B, W);
end;

procedure TNGMemoryMap.LearnOutput(const OutputTokens: array of string;
  const Confidence: Single; const Rate: Single);
var
  I, A, B, K: Integer;
  W: Single;
begin
  for I := Low(OutputTokens) to High(OutputTokens) - 1 do
  begin
    A := EnsureToken(OutputTokens[I]);
    B := EnsureToken(OutputTokens[I + 1]);
    K := FindLink(A, B);
    W := 0;
    if K >= 0 then W := FLinks[K].Weight;
    Associate(OutputTokens[I], OutputTokens[I + 1],
      ClampWeight(0.999 * W + ClampWeight(Rate) * ClampWeight(Confidence)));
  end;
end;

function TNGMemoryMap.Activate(const InputTokens: array of string;
  const Decay: array of Single): TNGActivations;
var
  Seeds: TNGActivations;
  I, N: Integer;
begin
  SetLength(Seeds, 0);
  for I := Low(InputTokens) to High(InputTokens) do
  begin
    N := TokenID(InputTokens[I]);
    if N < 0 then Continue;
    SetLength(Seeds, Length(Seeds) + 1);
    Seeds[High(Seeds)].Node := N;
    Seeds[High(Seeds)].Signal := 1;
  end;
  Result := FGraph.Propagate(Seeds, Decay);
end;

procedure TNGMemoryMap.SaveJSON(const FileName: string);
var
  Root: TJSONObject;
  Tokens, Edges: TJSONArray;
  E: TJSONObject;
  I: Integer;
  S: TStringList;
begin
  Root := TJSONObject.Create;
  try
    Root.Add('version', 1);
    Tokens := TJSONArray.Create;
    for I := 0 to FTokens.Count - 1 do Tokens.Add(FTokens[I]);
    Root.Add('tokens', Tokens);
    Edges := TJSONArray.Create;
    for I := 0 to High(FLinks) do
    begin
      E := TJSONObject.Create;
      E.Add('source', FLinks[I].Source);
      E.Add('target', FLinks[I].Target);
      E.Add('weight', Double(FLinks[I].Weight));
      Edges.Add(E);
    end;
    Root.Add('edges', Edges);
    S := TStringList.Create;
    try
      S.Text := Root.FormatJSON;
      S.SaveToFile(FileName);
    finally S.Free; end;
  finally Root.Free; end;
end;

procedure TNGMemoryMap.LoadJSON(const FileName: string);
var
  Root: TJSONData;
  Tokens, Edges: TJSONArray;
  E: TJSONData;
  S: TStringList;
  I, A, B: Integer;
  W: Single;
begin
  S := TStringList.Create;
  try
    S.LoadFromFile(FileName);
    Root := GetJSON(S.Text);
  finally S.Free; end;
  try
    if Root.FindPath('version').AsInteger <> 1 then
      raise Exception.Create('Unsupported map version');
    Tokens := TJSONArray(Root.FindPath('tokens'));
    Edges := TJSONArray(Root.FindPath('edges'));
    if (Tokens = nil) or (Edges = nil) then
      raise Exception.Create('Invalid graph map');
    FTokens.Clear;
    FTokenHash.Clear;
    FLinkHash.Clear;
    FGraph.Clear;
    SetLength(FLinks, 0);
    for I := 0 to Tokens.Count - 1 do EnsureToken(Tokens.Strings[I]);
    for I := 0 to Edges.Count - 1 do
    begin
      E := Edges.Items[I];
      A := E.FindPath('source').AsInteger;
      B := E.FindPath('target').AsInteger;
      W := E.FindPath('weight').AsFloat;
      if (A < 0) or (B < 0) or (A >= TokenCount) or (B >= TokenCount) then
        raise Exception.Create('Invalid edge endpoint');
      Associate(TokenText(A), TokenText(B), W);
    end;
  finally Root.Free; end;
end;

function TNGMemoryMap.TokenCount: Integer;
begin Result := FTokens.Count; end;

function TNGMemoryMap.LinkCount: Integer;
begin Result := Length(FLinks); end;

end.
