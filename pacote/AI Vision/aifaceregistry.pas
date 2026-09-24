unit aifaceregistry;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, yolodetect, aifaceprofile, aifacedescriptor, aifacejson;

type
  { TAIFaceRegistry }
  TAIFaceRegistry = class
  private
    FProfiles: TFPList;
    FLastError: string;
    FWarnings: TStringList;
    FFaceClasses: TStringList;
    function GetProfile(Index: Integer): TAIFaceProfile;
    procedure SetFaceClasses(const AValue: TStringList);
  public
    constructor Create;
    destructor Destroy; override;

    function AddProfile(AProfile: TAIFaceProfile): Boolean;
    function UpdateProfile(AProfile: TAIFaceProfile): Boolean;
    function DeleteProfile(const AID: string): Boolean;
    function FindByID(const AID: string): TAIFaceProfile;
    function FindByName(const AName: string): TAIFaceProfile;
    function ProfileCount: Integer;
    procedure Clear;

    function LoadFromFolder(const AFolderPath: string; ACreateIfMissing: Boolean = True): Integer;
    function SaveProfile(const AProfileID: string; const AFolderPath: string): Boolean;
    function SaveAll(const AFolderPath: string): Boolean;

    function BuildDescriptorFromFile(const AImageFile: string;
      AYolo: TYOLO;
      ABuilder: TAIFaceDescriptorBuilder;
      out ASample: TAIFaceSample;
      out AError: string;
      const AFaceClassesOverride: TStrings = nil): Boolean;

    function AddSampleFromFile(const AProfileID: string;
      const AImageFile: string;
      AYolo: TYOLO;
      ABuilder: TAIFaceDescriptorBuilder;
      out AError: string;
      const AFaceClassesOverride: TStrings = nil): Boolean;

    function RebuildProfileDescriptors(AProfile: TAIFaceProfile;
      AYolo: TYOLO;
      ABuilder: TAIFaceDescriptorBuilder): Integer;

    property Profiles[Index: Integer]: TAIFaceProfile read GetProfile; default;
    property LastError: string read FLastError;
    property Warnings: TStringList read FWarnings;
    property FaceClasses: TStringList read FFaceClasses write SetFaceClasses;
  end;

implementation

{ TAIFaceRegistry }

constructor TAIFaceRegistry.Create;
begin
  inherited Create;
  FProfiles := TFPList.Create;
  FLastError := '';
  FWarnings := TStringList.Create;
  FFaceClasses := TStringList.Create;
  FFaceClasses.Duplicates := dupIgnore;
  FFaceClasses.Add('face');
  FFaceClasses.Add('human_face');
end;

destructor TAIFaceRegistry.Destroy;
begin
  Clear;
  FreeAndNil(FProfiles);
  FreeAndNil(FWarnings);
  FreeAndNil(FFaceClasses);
  inherited Destroy;
end;

procedure TAIFaceRegistry.SetFaceClasses(const AValue: TStringList);
begin
  if AValue <> nil then
    FFaceClasses.Assign(AValue);
end;

procedure TAIFaceRegistry.Clear;
var
  i: Integer;
begin
  for i := 0 to FProfiles.Count - 1 do
    TAIFaceProfile(FProfiles[i]).Free;
  FProfiles.Clear;
  FWarnings.Clear;
end;

function TAIFaceRegistry.ProfileCount: Integer;
begin
  Result := FProfiles.Count;
end;

function TAIFaceRegistry.GetProfile(Index: Integer): TAIFaceProfile;
begin
  if (Index >= 0) and (Index < FProfiles.Count) then
    Result := TAIFaceProfile(FProfiles[Index])
  else
    Result := nil;
end;

function TAIFaceRegistry.FindByID(const AID: string): TAIFaceProfile;
var
  i: Integer;
  P: TAIFaceProfile;
  TargetID: string;
begin
  Result := nil;
  TargetID := LowerCase(Trim(AID));
  for i := 0 to FProfiles.Count - 1 do
  begin
    P := TAIFaceProfile(FProfiles[i]);
    if LowerCase(Trim(P.ID)) = TargetID then
      Exit(P);
  end;
end;

function TAIFaceRegistry.FindByName(const AName: string): TAIFaceProfile;
var
  i: Integer;
  P: TAIFaceProfile;
  TargetName: string;
begin
  Result := nil;
  TargetName := LowerCase(Trim(AName));
  for i := 0 to FProfiles.Count - 1 do
  begin
    P := TAIFaceProfile(FProfiles[i]);
    if LowerCase(Trim(P.Name)) = TargetName then
      Exit(P);
  end;
end;

function TAIFaceRegistry.AddProfile(AProfile: TAIFaceProfile): Boolean;
begin
  Result := False;
  FLastError := '';
  if AProfile = nil then
  begin
    FLastError := 'Perfil nulo não pode ser adicionado.';
    Exit;
  end;

  if Trim(AProfile.ID) = '' then
    AProfile.ID := SanitizeProfileID(AProfile.Name);

  if FindByID(AProfile.ID) <> nil then
  begin
    FLastError := 'Já existe um perfil cadastrado com o ID: ' + AProfile.ID;
    Exit;
  end;

  FProfiles.Add(AProfile);
  Result := True;
end;

function TAIFaceRegistry.UpdateProfile(AProfile: TAIFaceProfile): Boolean;
var
  Existing: TAIFaceProfile;
begin
  Result := False;
  FLastError := '';
  if AProfile = nil then Exit;

  Existing := FindByID(AProfile.ID);
  if Existing = nil then
  begin
    FLastError := 'Perfil não encontrado para atualização: ' + AProfile.ID;
    Exit;
  end;

  if Existing <> AProfile then
    Existing.Assign(AProfile);
  Result := True;
end;

function TAIFaceRegistry.DeleteProfile(const AID: string): Boolean;
var
  i: Integer;
  P: TAIFaceProfile;
begin
  Result := False;
  for i := 0 to FProfiles.Count - 1 do
  begin
    P := TAIFaceProfile(FProfiles[i]);
    if LowerCase(Trim(P.ID)) = LowerCase(Trim(AID)) then
    begin
      P.Free;
      FProfiles.Delete(i);
      Result := True;
      Exit;
    end;
  end;
end;

function TAIFaceRegistry.LoadFromFolder(const AFolderPath: string; ACreateIfMissing: Boolean): Integer;
var
  SR: TSearchRec;
  FilePath, WarningMsg: string;
  P: TAIFaceProfile;
  SuccessCount: Integer;
begin
  SuccessCount := 0;
  FLastError := '';
  FWarnings.Clear;

  if not DirectoryExists(AFolderPath) then
  begin
    if ACreateIfMissing then
      ForceDirectories(AFolderPath)
    else
    begin
      FLastError := 'Diretório não encontrado: ' + AFolderPath;
      Exit(0);
    end;
  end;

  if FindFirst(IncludeTrailingPathDelimiter(AFolderPath) + '*.json', faAnyFile, SR) = 0 then
  begin
    try
      repeat
        if (SR.Attr and faDirectory) = 0 then
        begin
          FilePath := IncludeTrailingPathDelimiter(AFolderPath) + SR.Name;
          P := TAIFaceProfile.Create;
          if LoadProfileFromFile(FilePath, P, WarningMsg) then
          begin
            if Trim(P.ID) = '' then
              P.ID := ChangeFileExt(SR.Name, '');

            if WarningMsg <> '' then
              FWarnings.Add(Format('[Aviso %s]: %s', [SR.Name, WarningMsg]));

            if FindByID(P.ID) <> nil then
              UpdateProfile(P)
            else
              FProfiles.Add(P);

            Inc(SuccessCount);
          end
          else
          begin
            // JSON corrompido ou inválido não impede o carregamento dos outros perfis (Task 56)
            FWarnings.Add(Format('[Erro %s]: %s', [SR.Name, WarningMsg]));
            P.Free;
          end;
        end;
      until FindNext(SR) <> 0;
    finally
      FindClose(SR);
    end;
  end;

  Result := SuccessCount;
end;

function TAIFaceRegistry.SaveProfile(const AProfileID: string; const AFolderPath: string): Boolean;
var
  P: TAIFaceProfile;
  FilePath: string;
begin
  Result := False;
  FLastError := '';
  P := FindByID(AProfileID);
  if P = nil then
  begin
    FLastError := 'Perfil não encontrado: ' + AProfileID;
    Exit;
  end;

  FilePath := IncludeTrailingPathDelimiter(AFolderPath) + P.ID + '.json';
  Result := SaveProfileToFile(P, FilePath);
  if not Result then
    FLastError := 'Falha ao salvar perfil no arquivo: ' + FilePath;
end;

function TAIFaceRegistry.SaveAll(const AFolderPath: string): Boolean;
var
  i: Integer;
  P: TAIFaceProfile;
begin
  Result := True;
  for i := 0 to FProfiles.Count - 1 do
  begin
    P := TAIFaceProfile(FProfiles[i]);
    if not SaveProfile(P.ID, AFolderPath) then
      Result := False;
  end;
end;

function TAIFaceRegistry.BuildDescriptorFromFile(const AImageFile: string;
  AYolo: TYOLO;
  ABuilder: TAIFaceDescriptorBuilder;
  out ASample: TAIFaceSample;
  out AError: string;
  const AFaceClassesOverride: TStrings): Boolean;
var
  Objects: TYoloObjectArray;
  FaceCount, FaceIdx, i: Integer;
  FilterClasses: TStrings;
begin
  Result := False;
  ASample := nil;
  AError := '';

  if AYolo = nil then
  begin
    AError := 'Componente TYOLO não fornecido.';
    Exit;
  end;

  if ABuilder = nil then
  begin
    AError := 'TAIFaceDescriptorBuilder não fornecido.';
    Exit;
  end;

  if not FileExists(AImageFile) then
  begin
    AError := 'Arquivo de imagem não encontrado: ' + AImageFile;
    Exit;
  end;

  if not AYolo.DetectObjects(AImageFile, Objects) then
  begin
    AError := 'Falha na detecção YOLO: ' + AYolo.LastError;
    Exit;
  end;

  FilterClasses := AFaceClassesOverride;
  if FilterClasses = nil then
    FilterClasses := FFaceClasses;

  // Conta estritamente faces com IsYoloFaceObject (Tarefas 3, 4 e 5)
  // Remove Length(Objects) = 1 e 'person' como face padrão
  FaceCount := 0;
  FaceIdx := -1;
  for i := 0 to High(Objects) do
  begin
    if IsYoloFaceObject(Objects[i], FilterClasses) then
    begin
      Inc(FaceCount);
      FaceIdx := i;
    end;
  end;

  if FaceCount = 0 then
  begin
    AError := 'Nenhuma face encontrada';
    Exit;
  end;

  if FaceCount > 1 then
  begin
    AError := 'A imagem deve conter somente uma pessoa';
    Exit;
  end;

  Result := ABuilder.CreateSampleFromObject(Objects[FaceIdx], AYolo.KeyPointMapping, AImageFile, ASample, AError);
end;

function TAIFaceRegistry.AddSampleFromFile(const AProfileID: string;
  const AImageFile: string;
  AYolo: TYOLO;
  ABuilder: TAIFaceDescriptorBuilder;
  out AError: string;
  const AFaceClassesOverride: TStrings): Boolean;
var
  P: TAIFaceProfile;
  Sample: TAIFaceSample;
begin
  Result := False;
  AError := '';
  P := FindByID(AProfileID);
  if P = nil then
  begin
    AError := 'Perfil não encontrado: ' + AProfileID;
    Exit;
  end;

  if not BuildDescriptorFromFile(AImageFile, AYolo, ABuilder, Sample, AError, AFaceClassesOverride) then
    Exit;

  Sample.SampleID := Format('%s_s%d', [P.ID, P.SampleCount + 1]);
  P.AddSample(Sample);
  P.AddImage(AImageFile);
  Result := True;
end;

function TAIFaceRegistry.RebuildProfileDescriptors(AProfile: TAIFaceProfile;
  AYolo: TYOLO;
  ABuilder: TAIFaceDescriptorBuilder): Integer;
var
  i: Integer;
  ImgPath, ErrMsg: string;
  Sample: TAIFaceSample;
  RebuiltCount: Integer;
begin
  RebuiltCount := 0;
  if (AProfile = nil) or (AYolo = nil) or (ABuilder = nil) then Exit(0);

  AProfile.ClearSamples;
  for i := 0 to AProfile.Images.Count - 1 do
  begin
    ImgPath := AProfile.Images[i];
    if FileExists(ImgPath) then
    begin
      if BuildDescriptorFromFile(ImgPath, AYolo, ABuilder, Sample, ErrMsg) then
      begin
        Sample.SampleID := Format('%s_s%d', [AProfile.ID, RebuiltCount + 1]);
        AProfile.AddSample(Sample);
        Inc(RebuiltCount);
      end;
    end;
  end;

  Result := RebuiltCount;
end;

end.
