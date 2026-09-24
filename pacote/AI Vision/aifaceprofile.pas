unit aifaceprofile;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils;

type
  TDoubleDynArray = array of Double;

  { TAIFaceSample }
  TAIFaceSample = class
  private
    FSampleID: string;
    FImageFile: string;
    FDescriptorVersion: Integer;
    FAlgorithm: string;
    FVector: TDoubleDynArray;
    FCreatedAt: TDateTime;
    FDetectionConfidence: Double;
    FQualityScore: Double;
  public
    constructor Create;
    function Clone: TAIFaceSample;
    function VectorLength: Integer;
    property SampleID: string read FSampleID write FSampleID;
    property ImageFile: string read FImageFile write FImageFile;
    property DescriptorVersion: Integer read FDescriptorVersion write FDescriptorVersion;
    property Algorithm: string read FAlgorithm write FAlgorithm;
    property Vector: TDoubleDynArray read FVector write FVector;
    property CreatedAt: TDateTime read FCreatedAt write FCreatedAt;
    property DetectionConfidence: Double read FDetectionConfidence write FDetectionConfidence;
    property QualityScore: Double read FQualityScore write FQualityScore;
  end;

  { TAIFaceSampleList }
  TAIFaceSampleList = class(TFPList)
  private
    function GetItem(Index: Integer): TAIFaceSample;
    procedure SetItem(Index: Integer; const AValue: TAIFaceSample);
  public
    destructor Destroy; override;
    procedure Clear;
    function Add(ASample: TAIFaceSample): Integer;
    procedure Delete(Index: Integer);
    property Items[Index: Integer]: TAIFaceSample read GetItem write SetItem; default;
  end;

  { TAIFaceProfile }
  TAIFaceProfile = class
  private
    FID: string;
    FName: string;
    FRole: string;
    FProfileText: string;
    FEnabled: Boolean;
    FImages: TStringList;
    FTriggers: TStringList;
    FSamples: TAIFaceSampleList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Assign(ASource: TAIFaceProfile);
    function AddSample(ASample: TAIFaceSample): Integer;
    function SampleCount: Integer;
    procedure ClearSamples;
    procedure AddImage(const AImagePath: string);
    procedure RemoveImage(const AImagePath: string);
    property ID: string read FID write FID;
    property Name: string read FName write FName;
    property Role: string read FRole write FRole;
    property ProfileText: string read FProfileText write FProfileText;
    property Enabled: Boolean read FEnabled write FEnabled default True;
    property Images: TStringList read FImages;
    property Triggers: TStringList read FTriggers;
    property Samples: TAIFaceSampleList read FSamples;
  end;

  TAIFaceProfileArray = array of TAIFaceProfile;

implementation

{ TAIFaceSample }

constructor TAIFaceSample.Create;
begin
  inherited Create;
  FSampleID := '';
  FImageFile := '';
  FDescriptorVersion := 1;
  FAlgorithm := 'yolo_landmarks_geometry';
  SetLength(FVector, 0);
  FCreatedAt := Now;
  FDetectionConfidence := 0.0;
  FQualityScore := 0.0;
end;

function TAIFaceSample.Clone: TAIFaceSample;
var
  i: Integer;
begin
  Result := TAIFaceSample.Create;
  Result.FSampleID := FSampleID;
  Result.FImageFile := FImageFile;
  Result.FDescriptorVersion := FDescriptorVersion;
  Result.FAlgorithm := FAlgorithm;
  Result.FCreatedAt := FCreatedAt;
  Result.FDetectionConfidence := FDetectionConfidence;
  Result.FQualityScore := FQualityScore;
  SetLength(Result.FVector, Length(FVector));
  for i := 0 to High(FVector) do
    Result.FVector[i] := FVector[i];
end;

function TAIFaceSample.VectorLength: Integer;
begin
  Result := Length(FVector);
end;

{ TAIFaceSampleList }

destructor TAIFaceSampleList.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TAIFaceSampleList.Clear;
var
  i: Integer;
begin
  for i := 0 to Count - 1 do
    TAIFaceSample(Items[i]).Free;
  inherited Clear;
end;

function TAIFaceSampleList.Add(ASample: TAIFaceSample): Integer;
begin
  Result := inherited Add(ASample);
end;

procedure TAIFaceSampleList.Delete(Index: Integer);
begin
  if (Index >= 0) and (Index < Count) then
  begin
    TAIFaceSample(Items[Index]).Free;
    inherited Delete(Index);
  end;
end;

function TAIFaceSampleList.GetItem(Index: Integer): TAIFaceSample;
begin
  Result := TAIFaceSample(inherited Items[Index]);
end;

procedure TAIFaceSampleList.SetItem(Index: Integer; const AValue: TAIFaceSample);
begin
  inherited Items[Index] := AValue;
end;

{ TAIFaceProfile }

constructor TAIFaceProfile.Create;
begin
  inherited Create;
  FID := '';
  FName := '';
  FRole := '';
  FProfileText := '';
  FEnabled := True;
  FImages := TStringList.Create;
  FImages.Duplicates := dupIgnore;
  FTriggers := TStringList.Create;
  FSamples := TAIFaceSampleList.Create;
end;

destructor TAIFaceProfile.Destroy;
begin
  FreeAndNil(FSamples);
  FreeAndNil(FTriggers);
  FreeAndNil(FImages);
  inherited Destroy;
end;

procedure TAIFaceProfile.Assign(ASource: TAIFaceProfile);
var
  i: Integer;
begin
  if ASource = nil then Exit;
  FID := ASource.ID;
  FName := ASource.Name;
  FRole := ASource.Role;
  FProfileText := ASource.ProfileText;
  FEnabled := ASource.Enabled;
  FImages.Assign(ASource.Images);
  FTriggers.Assign(ASource.Triggers);
  FSamples.Clear;
  for i := 0 to ASource.Samples.Count - 1 do
    FSamples.Add(ASource.Samples[i].Clone);
end;

function TAIFaceProfile.AddSample(ASample: TAIFaceSample): Integer;
begin
  Result := FSamples.Add(ASample);
end;

function TAIFaceProfile.SampleCount: Integer;
begin
  Result := FSamples.Count;
end;

procedure TAIFaceProfile.ClearSamples;
begin
  FSamples.Clear;
end;

procedure TAIFaceProfile.AddImage(const AImagePath: string);
begin
  if (Trim(AImagePath) <> '') and (FImages.IndexOf(AImagePath) < 0) then
    FImages.Add(AImagePath);
end;

procedure TAIFaceProfile.RemoveImage(const AImagePath: string);
var
  Idx, i: Integer;
begin
  Idx := FImages.IndexOf(AImagePath);
  if Idx >= 0 then
    FImages.Delete(Idx);

  // Remove também amostras associadas à imagem
  for i := FSamples.Count - 1 downto 0 do
  begin
    if FSamples[i].ImageFile = AImagePath then
      FSamples.Delete(i);
  end;
end;

end.
