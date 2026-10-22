unit aispeakersignature;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, fpjson, jsonparser;

type
  TAISpeakerDecision = (sdSame, sdDifferent, sdInconclusive);
  TAISpeakerSignature = array of Double;

  { Profile persistido de um locutor cadastrado no sistema }
  TAISpeakerProfile = record
    SpeakerID   : string;
    SpeakerName : string;
    CreatedAt   : string;
    Signature   : TAISpeakerSignature;
  end;
  TAISpeakerProfiles = array of TAISpeakerProfile;

  { Sessão de comparação de locutor em tempo de execução }
  TAISpeakerSession = class
  private
    FReference: TAISpeakerSignature;
    FActive: Boolean;
    FSameThreshold: Double;
    FDifferentThreshold: Double;
    function Similarity(const A, B: TAISpeakerSignature): Double;
  public
    constructor Create;
    procedure Reset;
    function Evaluate(const ASignature: TAISpeakerSignature;
      out ADecision: TAISpeakerDecision): Boolean;

    { Métodos para persistência e recuperação de assinaturas vocais em disco }
    function SaveToFile(const AFileName: string; const ASpeakerID, ASpeakerName: string): Boolean;
    function LoadFromFile(const AFileName: string; out ASpeakerID, ASpeakerName: string): Boolean;

    { Serialização em JSON para integração com APIs / SQLite }
    function ToJSON(const ASpeakerID, ASpeakerName: string): string;
    function FromJSON(const AJSONStr: string; out ASpeakerID, ASpeakerName: string): Boolean;

    { Carregamento direto de uma assinatura como referência }
    procedure SetReference(const ASignature: TAISpeakerSignature);
    function GetReference: TAISpeakerSignature;

    property Active: Boolean read FActive;
    property SameThreshold: Double read FSameThreshold write FSameThreshold;
    property DifferentThreshold: Double read FDifferentThreshold write FDifferentThreshold;
  end;

  { Gerenciador de catálogo de assinaturas de múltiplos locutores em disco }
  TAISpeakerRegistry = class
  private
    FProfiles: TAISpeakerProfiles;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function AddOrUpdate(const ASpeakerID, ASpeakerName: string; const ASig: TAISpeakerSignature): Boolean;
    function Remove(const ASpeakerID: string): Boolean;
    function Find(const ASpeakerID: string; out AProfile: TAISpeakerProfile): Boolean;
    
    { Identifica o locutor mais provável em uma base persistida }
    function IdentifySpeaker(const ASig: TAISpeakerSignature; out AIdentifiedID, AIdentifiedName: string;
      out AMaxScore: Double; AThreshold: Double = 0.82): Boolean;

    { Persistência de todo o catálogo em arquivo JSON }
    function SaveToFile(const AFileName: string): Boolean;
    function LoadFromFile(const AFileName: string): Boolean;

    function GetCount: Integer;
    property Count: Integer read GetCount;
    property Profiles: TAISpeakerProfiles read FProfiles;
  end;

implementation

{ TAISpeakerSession }

constructor TAISpeakerSession.Create;
begin
  inherited Create;
  FSameThreshold := 0.82;
  FDifferentThreshold := 0.58;
end;

procedure TAISpeakerSession.Reset;
begin
  FActive := False;
  SetLength(FReference, 0);
end;

procedure TAISpeakerSession.SetReference(const ASignature: TAISpeakerSignature);
begin
  if Length(ASignature) > 0 then
  begin
    FReference := Copy(ASignature, 0, Length(ASignature));
    FActive := True;
  end
  else
    Reset;
end;

function TAISpeakerSession.GetReference: TAISpeakerSignature;
begin
  Result := Copy(FReference, 0, Length(FReference));
end;

function TAISpeakerSession.Similarity(const A, B: TAISpeakerSignature): Double;
var
  I: Integer;
  Dot, NormA, NormB: Double;
begin
  Result := NaN;
  if (Length(A) = 0) or (Length(A) <> Length(B)) then Exit;
  Dot := 0; NormA := 0; NormB := 0;
  for I := 0 to High(A) do
  begin
    if IsNan(A[I]) or IsInfinite(A[I]) or IsNan(B[I]) or IsInfinite(B[I]) then Exit;
    Dot := Dot + A[I] * B[I];
    NormA := NormA + Sqr(A[I]);
    NormB := NormB + Sqr(B[I]);
  end;
  if (NormA <= 0) or (NormB <= 0) then Exit;
  Result := Dot / Sqrt(NormA * NormB);
end;

function TAISpeakerSession.Evaluate(const ASignature: TAISpeakerSignature;
  out ADecision: TAISpeakerDecision): Boolean;
var
  Score: Double;
begin
  ADecision := sdInconclusive;
  if not FActive then
  begin
    if Length(ASignature) > 0 then
    begin
      Score := Similarity(ASignature, ASignature);
      if not IsNan(Score) then
      begin
        FReference := Copy(ASignature, 0, Length(ASignature));
        FActive := True;
      end;
    end;
    Result := True;
    Exit;
  end;
  Score := Similarity(FReference, ASignature);
  if not IsNan(Score) then
  begin
    if Score >= FSameThreshold then ADecision := sdSame
    else if Score <= FDifferentThreshold then ADecision := sdDifferent;
  end;
  { Inconclusive é aceito sem alterar a referência. Apenas locutor comprovadamente diferente é rejeitado. }
  Result := ADecision <> sdDifferent;
end;

function TAISpeakerSession.ToJSON(const ASpeakerID, ASpeakerName: string): string;
var
  Root: TJSONObject;
  SigArr: TJSONArray;
  I: Integer;
begin
  Root := TJSONObject.Create;
  try
    Root.Add('speaker_id', ASpeakerID);
    Root.Add('speaker_name', ASpeakerName);
    Root.Add('created_at', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss"Z"', Now));
    Root.Add('dimension', Length(FReference));
    SigArr := TJSONArray.Create;
    for I := 0 to High(FReference) do
      SigArr.Add(FReference[I]);
    Root.Add('signature', SigArr);
    Result := Root.AsJSON;
  finally
    Root.Free;
  end;
end;

function TAISpeakerSession.FromJSON(const AJSONStr: string; out ASpeakerID, ASpeakerName: string): Boolean;
var
  Data: TJSONData;
  Root: TJSONObject;
  SigArr: TJSONArray;
  I: Integer;
begin
  Result := False;
  ASpeakerID := '';
  ASpeakerName := '';
  if Trim(AJSONStr) = '' then Exit;
  try
    Data := GetJSON(AJSONStr);
    try
      if not (Data is TJSONObject) then Exit;
      Root := TJSONObject(Data);
      ASpeakerID := Root.Get('speaker_id', '');
      ASpeakerName := Root.Get('speaker_name', '');
      SigArr := Root.Get('signature', TJSONArray(nil));
      if Assigned(SigArr) and (SigArr.Count > 0) then
      begin
        SetLength(FReference, SigArr.Count);
        for I := 0 to SigArr.Count - 1 do
          FReference[I] := SigArr.Floats[I];
        FActive := True;
        Result := True;
      end;
    finally
      Data.Free;
    end;
  except
    Result := False;
  end;
end;

function TAISpeakerSession.SaveToFile(const AFileName: string; const ASpeakerID, ASpeakerName: string): Boolean;
var
  S: TStringList;
begin
  Result := False;
  if not FActive or (Length(FReference) = 0) then Exit;
  S := TStringList.Create;
  try
    S.Text := ToJSON(ASpeakerID, ASpeakerName);
    try
      ForceDirectories(ExtractFileDir(AFileName));
      S.SaveToFile(AFileName);
      Result := True;
    except
      Result := False;
    end;
  finally
    S.Free;
  end;
end;

function TAISpeakerSession.LoadFromFile(const AFileName: string; out ASpeakerID, ASpeakerName: string): Boolean;
var
  S: TStringList;
begin
  Result := False;
  ASpeakerID := '';
  ASpeakerName := '';
  if not FileExists(AFileName) then Exit;
  S := TStringList.Create;
  try
    S.LoadFromFile(AFileName);
    Result := FromJSON(S.Text, ASpeakerID, ASpeakerName);
  finally
    S.Free;
  end;
end;

{ TAISpeakerRegistry }

function TAISpeakerRegistry.GetCount: Integer;
begin
  Result := Length(FProfiles);
end;

constructor TAISpeakerRegistry.Create;
begin
  inherited Create;
  SetLength(FProfiles, 0);
end;

destructor TAISpeakerRegistry.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TAISpeakerRegistry.Clear;
begin
  SetLength(FProfiles, 0);
end;

function TAISpeakerRegistry.AddOrUpdate(const ASpeakerID, ASpeakerName: string; const ASig: TAISpeakerSignature): Boolean;
var
  I, N: Integer;
begin
  Result := False;
  if (ASpeakerID = '') or (Length(ASig) = 0) then Exit;
  for I := 0 to High(FProfiles) do
  begin
    if SameText(FProfiles[I].SpeakerID, ASpeakerID) then
    begin
      FProfiles[I].SpeakerName := ASpeakerName;
      FProfiles[I].Signature := Copy(ASig, 0, Length(ASig));
      FProfiles[I].CreatedAt := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss"Z"', Now);
      Exit(True);
    end;
  end;
  N := Length(FProfiles);
  SetLength(FProfiles, N + 1);
  FProfiles[N].SpeakerID := ASpeakerID;
  FProfiles[N].SpeakerName := ASpeakerName;
  FProfiles[N].CreatedAt := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss"Z"', Now);
  FProfiles[N].Signature := Copy(ASig, 0, Length(ASig));
  Result := True;
end;

function TAISpeakerRegistry.Remove(const ASpeakerID: string): Boolean;
var
  I, J: Integer;
begin
  Result := False;
  for I := 0 to High(FProfiles) do
  begin
    if SameText(FProfiles[I].SpeakerID, ASpeakerID) then
    begin
      for J := I to High(FProfiles) - 1 do
        FProfiles[J] := FProfiles[J + 1];
      SetLength(FProfiles, Length(FProfiles) - 1);
      Exit(True);
    end;
  end;
end;

function TAISpeakerRegistry.Find(const ASpeakerID: string; out AProfile: TAISpeakerProfile): Boolean;
var
  I: Integer;
begin
  Result := False;
  for I := 0 to High(FProfiles) do
  begin
    if SameText(FProfiles[I].SpeakerID, ASpeakerID) then
    begin
      AProfile := FProfiles[I];
      Exit(True);
    end;
  end;
end;

function TAISpeakerRegistry.IdentifySpeaker(const ASig: TAISpeakerSignature;
  out AIdentifiedID, AIdentifiedName: string; out AMaxScore: Double; AThreshold: Double): Boolean;
var
  I, BestIdx: Integer;
  Session: TAISpeakerSession;
  Score: Double;
begin
  Result := False;
  AIdentifiedID := '';
  AIdentifiedName := '';
  AMaxScore := -1.0;
  BestIdx := -1;
  if (Length(FProfiles) = 0) or (Length(ASig) = 0) then Exit;

  Session := TAISpeakerSession.Create;
  try
    for I := 0 to High(FProfiles) do
    begin
      Session.SetReference(FProfiles[I].Signature);
      Score := Session.Similarity(Session.GetReference, ASig);
      if (not IsNan(Score)) and (Score > AMaxScore) then
      begin
        AMaxScore := Score;
        BestIdx := I;
      end;
    end;
  finally
    Session.Free;
  end;

  if (BestIdx >= 0) and (AMaxScore >= AThreshold) then
  begin
    AIdentifiedID := FProfiles[BestIdx].SpeakerID;
    AIdentifiedName := FProfiles[BestIdx].SpeakerName;
    Result := True;
  end;
end;

function TAISpeakerRegistry.SaveToFile(const AFileName: string): Boolean;
var
  Root, Item: TJSONObject;
  List: TJSONArray;
  SigArr: TJSONArray;
  I, J: Integer;
  S: TStringList;
begin
  Result := False;
  Root := TJSONObject.Create;
  S := TStringList.Create;
  try
    List := TJSONArray.Create;
    for I := 0 to High(FProfiles) do
    begin
      Item := TJSONObject.Create;
      Item.Add('speaker_id', FProfiles[I].SpeakerID);
      Item.Add('speaker_name', FProfiles[I].SpeakerName);
      Item.Add('created_at', FProfiles[I].CreatedAt);
      SigArr := TJSONArray.Create;
      for J := 0 to High(FProfiles[I].Signature) do
        SigArr.Add(FProfiles[I].Signature[J]);
      Item.Add('signature', SigArr);
      List.Add(Item);
    end;
    Root.Add('profiles', List);
    S.Text := Root.AsJSON;
    ForceDirectories(ExtractFileDir(AFileName));
    S.SaveToFile(AFileName);
    Result := True;
  finally
    S.Free;
    Root.Free;
  end;
end;

function TAISpeakerRegistry.LoadFromFile(const AFileName: string): Boolean;
var
  S: TStringList;
  Data: TJSONData;
  Root, Item: TJSONObject;
  List, SigArr: TJSONArray;
  I, J: Integer;
begin
  Result := False;
  Clear;
  if not FileExists(AFileName) then Exit;
  S := TStringList.Create;
  try
    S.LoadFromFile(AFileName);
    Data := GetJSON(S.Text);
    try
      if not (Data is TJSONObject) then Exit;
      Root := TJSONObject(Data);
      List := Root.Get('profiles', TJSONArray(nil));
      if not Assigned(List) then Exit;
      SetLength(FProfiles, List.Count);
      for I := 0 to List.Count - 1 do
      begin
        Item := List.Objects[I];
        FProfiles[I].SpeakerID := Item.Get('speaker_id', '');
        FProfiles[I].SpeakerName := Item.Get('speaker_name', '');
        FProfiles[I].CreatedAt := Item.Get('created_at', '');
        SigArr := Item.Get('signature', TJSONArray(nil));
        if Assigned(SigArr) then
        begin
          SetLength(FProfiles[I].Signature, SigArr.Count);
          for J := 0 to SigArr.Count - 1 do
            FProfiles[I].Signature[J] := SigArr.Floats[J];
        end;
      end;
      Result := True;
    finally
      Data.Free;
    end;
  finally
    S.Free;
  end;
end;

end.
