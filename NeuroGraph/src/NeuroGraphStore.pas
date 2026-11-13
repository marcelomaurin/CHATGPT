unit NeuroGraphStore;
{$mode objfpc}{$H+}
interface
uses Classes, SysUtils, Contnrs, Math;
type
  TNGStoredEdge = packed record
    SourceID, TargetID: LongWord;
    Weight: Single;
  end;
  TNGStoredEdges = array of TNGStoredEdge;
  { Single portable-ish binary format, UTF-8 tokens and directed weighted edges.
    Integers and floats are little-endian IEEE754 on target platforms.
    Indexed with O(1) hash tables for fast token and edge lookup. }
  TNeuroGraphStore = class
  private
    FTokens: TStringList;
    FTokenHash: TFPHashList;
    FEdgeHash: TFPHashList;
    FEdges: TNGStoredEdges;
    function FindEdge(A,B: LongWord): Integer;
    function MakeEdgeKey(A,B: LongWord): ShortString; inline;
  public
    constructor Create;
    destructor Destroy; override;
    function AddToken(const Token: UTF8String): LongWord;
    function FindToken(const Token: UTF8String): Integer;
    function TokenAt(ID: LongWord): UTF8String;
    procedure SetRelation(A,B: LongWord; Weight: Single);
    function TokenCount: Integer;
    function EdgeCount: Integer;
    function EdgeAt(Index: Integer): TNGStoredEdge;
    procedure SaveToFile(const FileName: string);
    procedure LoadFromFile(const FileName: string);
  end;
implementation
const MAGIC: array[0..7] of AnsiChar = ('N','G','M','A','P','0','0','1');
function Clamp(V: Single): Single;
begin
  if V < -16.0 then Exit(-16.0);
  if V > 16.0 then Exit(16.0);
  Result := V;
end;
constructor TNeuroGraphStore.Create;
begin
  inherited Create;
  FTokens := TStringList.Create;
  FTokens.CaseSensitive := True;
  FTokenHash := TFPHashList.Create;
  FEdgeHash := TFPHashList.Create;
end;
destructor TNeuroGraphStore.Destroy;
begin
  FEdgeHash.Free;
  FTokenHash.Free;
  FTokens.Free;
  inherited Destroy;
end;
function TNeuroGraphStore.MakeEdgeKey(A,B: LongWord): ShortString;
begin
  Result := IntToStr(A) + ':' + IntToStr(B);
end;
function TNeuroGraphStore.FindToken(const Token: UTF8String): Integer;
var P: Pointer;
begin
  if Token = '' then Exit(-1);
  P := FTokenHash.Find(string(Token));
  if P = nil then Exit(-1);
  Result := PtrInt(P) - 1;
end;
function TNeuroGraphStore.AddToken(const Token: UTF8String): LongWord;
var I: Integer; S: string;
begin
  if Token='' then raise Exception.Create('Token vazio');
  I:=FindToken(Token);
  if I<0 then
  begin
    S := string(Token);
    I := FTokens.Add(S);
    FTokenHash.Add(S, Pointer(PtrInt(I + 1)));
  end;
  Result:=LongWord(I);
end;
function TNeuroGraphStore.TokenAt(ID: LongWord): UTF8String;
begin
  if ID>=LongWord(FTokens.Count) then raise Exception.Create('Token ID invalido');
  Result:=UTF8String(FTokens[ID]);
end;
function TNeuroGraphStore.FindEdge(A,B: LongWord): Integer;
var P: Pointer;
begin
  P := FEdgeHash.Find(MakeEdgeKey(A, B));
  if P = nil then Exit(-1);
  Result := PtrInt(P) - 1;
end;
procedure TNeuroGraphStore.SetRelation(A,B: LongWord; Weight: Single);
var I: Integer;
begin
  if (A>=LongWord(TokenCount)) or (B>=LongWord(TokenCount)) then
    raise Exception.Create('Relacao com token inexistente');
  if IsNan(Weight) or IsInfinite(Weight) then raise Exception.Create('Peso invalido');
  I:=FindEdge(A,B);
  if I<0 then
  begin
    I:=Length(FEdges);
    SetLength(FEdges,I+1);
    FEdges[I].SourceID:=A;
    FEdges[I].TargetID:=B;
    FEdgeHash.Add(MakeEdgeKey(A, B), Pointer(PtrInt(I + 1)));
  end;
  FEdges[I].Weight:=Clamp(Weight);
end;
function TNeuroGraphStore.TokenCount: Integer;
begin Result:=FTokens.Count; end;
function TNeuroGraphStore.EdgeCount: Integer;
begin Result:=Length(FEdges); end;
function TNeuroGraphStore.EdgeAt(Index: Integer): TNGStoredEdge;
begin
  if (Index<0) or (Index>=EdgeCount) then raise Exception.Create('Indice invalido');
  Result:=FEdges[Index];
end;
procedure WriteU32(S:TStream; V:LongWord);
begin S.WriteBuffer(V,4); end;
function ReadU32(S:TStream):LongWord;
begin S.ReadBuffer(Result,4); end;
procedure TNeuroGraphStore.SaveToFile(const FileName:string);
var S:TFileStream; I:Integer; T:UTF8String; L:LongWord;
begin
  S:=TFileStream.Create(FileName,fmCreate);
  try
    S.WriteBuffer(MAGIC,SizeOf(MAGIC));
    WriteU32(S,LongWord(TokenCount)); WriteU32(S,LongWord(EdgeCount));
    for I:=0 to TokenCount-1 do begin
      T:=UTF8String(FTokens[I]); L:=Length(T); WriteU32(S,L);
      if L>0 then S.WriteBuffer(T[1],L);
    end;
    for I:=0 to EdgeCount-1 do begin
      WriteU32(S,FEdges[I].SourceID); WriteU32(S,FEdges[I].TargetID);
      S.WriteBuffer(FEdges[I].Weight,SizeOf(Single));
    end;
  finally S.Free; end;
end;
procedure TNeuroGraphStore.LoadFromFile(const FileName:string);
var S:TFileStream; Header:array[0..7] of AnsiChar;
    N,M,L,A,B:LongWord; I:LongWord; T:UTF8String; W:Single;
    Tmp:TNeuroGraphStore;
    J:Integer;
begin
  S:=TFileStream.Create(FileName,fmOpenRead or fmShareDenyWrite);
  Tmp:=TNeuroGraphStore.Create;
  try
    S.ReadBuffer(Header,8);
    if not CompareMem(@Header[0],@MAGIC[0],8) then
      raise Exception.Create('Formato de mapa invalido');
    N:=ReadU32(S); M:=ReadU32(S);
    if (N>10000000) or (M>100000000) then
      raise Exception.Create('Mapa excede limites');
    for I:=1 to N do begin
      L:=ReadU32(S);
      if (L=0) or (L>1048576) or (Int64(L)>S.Size-S.Position) then
        raise Exception.Create('Comprimento de token invalido');
      SetLength(T,L); S.ReadBuffer(T[1],L);
      if Tmp.FindToken(T)>=0 then raise Exception.Create('Token duplicado');
      Tmp.AddToken(T);
    end;
    for I:=1 to M do begin
      A:=ReadU32(S); B:=ReadU32(S); S.ReadBuffer(W,4);
      Tmp.SetRelation(A,B,W);
    end;
    FTokens.Assign(Tmp.FTokens);
    FEdges:=Copy(Tmp.FEdges,0,Length(Tmp.FEdges));
    FTokenHash.Clear;
    for J:=0 to FTokens.Count-1 do
      FTokenHash.Add(FTokens[J], Pointer(PtrInt(J + 1)));
    FEdgeHash.Clear;
    for J:=0 to High(FEdges) do
      FEdgeHash.Add(MakeEdgeKey(FEdges[J].SourceID, FEdges[J].TargetID), Pointer(PtrInt(J + 1)));
  finally Tmp.Free; S.Free; end;
end;
end.
