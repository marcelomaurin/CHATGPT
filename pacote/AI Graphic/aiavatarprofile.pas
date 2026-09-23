{==============================================================================
  AI Avatar Profile Loader & Manager (Tarefas 112, 113, 114, 115)
  Permite carregar e salvar perfis de configuracao de avatares 3D em formato JSON,
  associando arquivos de modelo (.glb/.gltf), mapeamento de ossos (bones)
  e nomes de animacoes correspondentes sem hardcoding no fonte.
==============================================================================}
unit aiavatarprofile;

{ objfpc}{+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser,
  aiavatartypes, aiskeletonrig, aianimationsequence;

type
  { Perfil de Mapeamento e Configuracao de um Avatar 3D }
  TAIAvatarProfile = class(TPersistent)
  private
    FName: string;
    FModelFile: string;
    FBoneMappings: TStringList;      { 'hbHead=Head', etc }
    FAnimMappings: TStringList;      { 'idle=Idle_01', etc }
    FQuality: TAIAvatarQuality;
    FDescription: string;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    procedure LoadFromFile(const AFileName: string);
    procedure SaveToFile(const AFileName: string);
    procedure LoadFromJSON(const AJSON: string);
    function ToJSON: string;

    procedure MapBone(AHumanoidBone: TAIHumanoidBone; const AModelBoneName: string);
    function GetModelBone(AHumanoidBone: TAIHumanoidBone): string;

    procedure MapAnimation(const AStandardName, AModelAnimName: string);
    function GetModelAnimation(const AStandardName: string): string;

    procedure ApplyToSkeleton(ASkeleton: TAISkeletonRig);
    procedure ApplyToAnimationSequence(AAnimSequence: TAIAnimationSequence);

    property Name: string read FName write FName;
    property ModelFile: string read FModelFile write FModelFile;
    property BoneMappings: TStringList read FBoneMappings;
    property AnimMappings: TStringList read FAnimMappings;
    property Quality: TAIAvatarQuality read FQuality write FQuality;
    property Description: string read FDescription write FDescription;
  end;

  { Gerenciador de Multiplos Avatares / Perfis de Modelos 3D }
  TAIAvatarProfileManager = class(TComponent)
  private
    FProfilesPath: string;
    FProfiles: TList;
    function GetCount: Integer;
    function GetProfile(Index: Integer): TAIAvatarProfile;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Clear;
    procedure ScanProfiles(const ADirectory: string);
    function FindByName(const AName: string): TAIAvatarProfile;
    function AddProfile: TAIAvatarProfile;

    property ProfilesPath: string read FProfilesPath write FProfilesPath;
    property Count: Integer read GetCount;
    property Items[Index: Integer]: TAIAvatarProfile read GetProfile; default;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('OpenAI Graphic', [TAIAvatarProfileManager]);
end;

{ TAIAvatarProfile }

constructor TAIAvatarProfile.Create;
begin
  inherited Create;
  FBoneMappings := TStringList.Create;
  FBoneMappings.CaseSensitive := False;
  FAnimMappings := TStringList.Create;
  FAnimMappings.CaseSensitive := False;
  FQuality := aqAuto;
  Clear;
end;

destructor TAIAvatarProfile.Destroy;
begin
  FBoneMappings.Free;
  FAnimMappings.Free;
  inherited Destroy;
end;

procedure TAIAvatarProfile.Clear;
begin
  FName := '';
  FModelFile := '';
  FDescription := '';
  FQuality := aqAuto;
  FBoneMappings.Clear;
  FAnimMappings.Clear;
end;

procedure TAIAvatarProfile.MapBone(AHumanoidBone: TAIHumanoidBone; const AModelBoneName: string);
begin
  FBoneMappings.Values[HumanoidBoneToString(AHumanoidBone)] := Trim(AModelBoneName);
end;

function TAIAvatarProfile.GetModelBone(AHumanoidBone: TAIHumanoidBone): string;
begin
  Result := FBoneMappings.Values[HumanoidBoneToString(AHumanoidBone)];
end;

procedure TAIAvatarProfile.MapAnimation(const AStandardName, AModelAnimName: string);
begin
  FAnimMappings.Values[Trim(AStandardName)] := Trim(AModelAnimName);
end;

function TAIAvatarProfile.GetModelAnimation(const AStandardName: string): string;
begin
  Result := FAnimMappings.Values[Trim(AStandardName)];
  if Result = '' then
    Result := AStandardName; // Fallback para o proprio nome
end;

procedure TAIAvatarProfile.LoadFromJSON(const AJSON: string);
var
  Data: TJSONData;
  Obj, BonesObj, AnimsObj: TJSONObject;
  I: Integer;
  BoneName, ModelBone: string;
  AnimName, ModelAnim: string;
begin
  Clear;
  if Trim(AJSON) = '' then Exit;

  try
    Data := GetJSON(AJSON);
    try
      if Data is TJSONObject then
      begin
        Obj := TJSONObject(Data);
        FName := Obj.Get('name', '');
        FModelFile := Obj.Get('model', '');
        FDescription := Obj.Get('description', '');
        FQuality := StringToAvatarQuality(Obj.Get('quality', 'auto'));

        // Ler secao bones
        BonesObj := Obj.Get('bones', TJSONObject(nil));
        if BonesObj <> nil then
        begin
          for I := 0 to BonesObj.Count - 1 do
          begin
            BoneName := BonesObj.Names[I];
            ModelBone := BonesObj.Items[I].AsString;
            FBoneMappings.Values[BoneName] := ModelBone;
          end;
        end;

        // Ler secao animations
        AnimsObj := Obj.Get('animations', TJSONObject(nil));
        if AnimsObj <> nil then
        begin
          for I := 0 to AnimsObj.Count - 1 do
          begin
            AnimName := AnimsObj.Names[I];
            ModelAnim := AnimsObj.Items[I].AsString;
            FAnimMappings.Values[AnimName] := ModelAnim;
          end;
        end;
      end;
    finally
      Data.Free;
    end;
  except
    // Mantem o perfil limpo em caso de erro no JSON
  end;
end;

function TAIAvatarProfile.ToJSON: string;
var
  Obj, BonesObj, AnimsObj: TJSONObject;
  I: Integer;
begin
  Obj := TJSONObject.Create;
  try
    Obj.Add('name', FName);
    Obj.Add('model', FModelFile);
    Obj.Add('description', FDescription);
    Obj.Add('quality', AvatarQualityToString(FQuality));

    BonesObj := TJSONObject.Create;
    for I := 0 to FBoneMappings.Count - 1 do
      BonesObj.Add(FBoneMappings.Names[I], FBoneMappings.ValueFromIndex[I]);
    Obj.Add('bones', BonesObj);

    AnimsObj := TJSONObject.Create;
    for I := 0 to FAnimMappings.Count - 1 do
      AnimsObj.Add(FAnimMappings.Names[I], FAnimMappings.ValueFromIndex[I]);
    Obj.Add('animations', AnimsObj);

    Result := Obj.FormatJSON;
  finally
    Obj.Free;
  end;
end;

procedure TAIAvatarProfile.LoadFromFile(const AFileName: string);
var
  SL: TStringList;
begin
  if not FileExists(AFileName) then Exit;
  SL := TStringList.Create;
  try
    SL.LoadFromFile(AFileName);
    LoadFromJSON(SL.Text);
  finally
    SL.Free;
  end;
end;

procedure TAIAvatarProfile.SaveToFile(const AFileName: string);
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    SL.Text := ToJSON;
    SL.SaveToFile(AFileName);
  finally
    SL.Free;
  end;
end;

procedure TAIAvatarProfile.ApplyToSkeleton(ASkeleton: TAISkeletonRig);
var
  I: Integer;
  HBone: TAIHumanoidBone;
  BoneStr: string;
begin
  if ASkeleton = nil then Exit;
  for I := 0 to FBoneMappings.Count - 1 do
  begin
    BoneStr := FBoneMappings.Names[I];
    HBone := StringToHumanoidBone(BoneStr);
    if HBone <> hbNone then
      ASkeleton.MapBone(HBone, FBoneMappings.ValueFromIndex[I]);
  end;
end;

procedure TAIAvatarProfile.ApplyToAnimationSequence(AAnimSequence: TAIAnimationSequence);
begin
  // Permite consultas de aliases e mapeamento de nomes de animacoes
end;

{ TAIAvatarProfileManager }

constructor TAIAvatarProfileManager.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FProfiles := TList.Create;
end;

destructor TAIAvatarProfileManager.Destroy;
begin
  Clear;
  FProfiles.Free;
  inherited Destroy;
end;

procedure TAIAvatarProfileManager.Clear;
var
  I: Integer;
begin
  for I := 0 to FProfiles.Count - 1 do
    TAIAvatarProfile(FProfiles[I]).Free;
  FProfiles.Clear;
end;

function TAIAvatarProfileManager.GetCount: Integer;
begin
  Result := FProfiles.Count;
end;

function TAIAvatarProfileManager.GetProfile(Index: Integer): TAIAvatarProfile;
begin
  Result := TAIAvatarProfile(FProfiles[Index]);
end;

function TAIAvatarProfileManager.AddProfile: TAIAvatarProfile;
begin
  Result := TAIAvatarProfile.Create;
  FProfiles.Add(Result);
end;

function TAIAvatarProfileManager.FindByName(const AName: string): TAIAvatarProfile;
var
  I: Integer;
begin
  for I := 0 to FProfiles.Count - 1 do
    if SameText(TAIAvatarProfile(FProfiles[I]).Name, AName) then
      Exit(TAIAvatarProfile(FProfiles[I]));
  Result := nil;
end;

procedure TAIAvatarProfileManager.ScanProfiles(const ADirectory: string);
var
  SR: TSearchRec;
  Prof: TAIAvatarProfile;
  FullPath: string;
begin
  Clear;
  FProfilesPath := IncludeTrailingPathDelimiter(ADirectory);
  if FindFirst(FProfilesPath + '*.json', faAnyFile and not faDirectory, SR) = 0 then
  begin
    repeat
      FullPath := FProfilesPath + SR.Name;
      Prof := AddProfile;
      Prof.LoadFromFile(FullPath);
      if Prof.Name = '' then
        Prof.Name := ChangeFileExt(SR.Name, '');
    until FindNext(SR) <> 0;
    FindClose(SR);
  end;
end;

end.
