unit aifacejson;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DateUtils, fpjson, jsonparser, aifaceprofile;

{ Centralização de serialização e desserialização JSON de perfis faciais }
function ProfileToJSON(AProfile: TAIFaceProfile): string;
function JSONToProfile(const AJSON: string; AProfile: TAIFaceProfile; out AWarning: string): Boolean;
function SaveProfileToFile(AProfile: TAIFaceProfile; const AFileName: string): Boolean;
function LoadProfileFromFile(const AFileName: string; AProfile: TAIFaceProfile; out AWarning: string): Boolean;
function SanitizeProfileID(const AName: string): string;

implementation

function SanitizeProfileID(const AName: string): string;
var
  i: Integer;
  Ch: Char;
  LName: string;
begin
  LName := LowerCase(Trim(AName));
  LName := StringReplace(LName, 'á', 'a', [rfReplaceAll]);
  LName := StringReplace(LName, 'à', 'a', [rfReplaceAll]);
  LName := StringReplace(LName, 'ã', 'a', [rfReplaceAll]);
  LName := StringReplace(LName, 'â', 'a', [rfReplaceAll]);
  LName := StringReplace(LName, 'ä', 'a', [rfReplaceAll]);
  LName := StringReplace(LName, 'é', 'e', [rfReplaceAll]);
  LName := StringReplace(LName, 'è', 'e', [rfReplaceAll]);
  LName := StringReplace(LName, 'ê', 'e', [rfReplaceAll]);
  LName := StringReplace(LName, 'ë', 'e', [rfReplaceAll]);
  LName := StringReplace(LName, 'í', 'i', [rfReplaceAll]);
  LName := StringReplace(LName, 'ì', 'i', [rfReplaceAll]);
  LName := StringReplace(LName, 'î', 'i', [rfReplaceAll]);
  LName := StringReplace(LName, 'ï', 'i', [rfReplaceAll]);
  LName := StringReplace(LName, 'ó', 'o', [rfReplaceAll]);
  LName := StringReplace(LName, 'ò', 'o', [rfReplaceAll]);
  LName := StringReplace(LName, 'õ', 'o', [rfReplaceAll]);
  LName := StringReplace(LName, 'ô', 'o', [rfReplaceAll]);
  LName := StringReplace(LName, 'ö', 'o', [rfReplaceAll]);
  LName := StringReplace(LName, 'ú', 'u', [rfReplaceAll]);
  LName := StringReplace(LName, 'ù', 'u', [rfReplaceAll]);
  LName := StringReplace(LName, 'û', 'u', [rfReplaceAll]);
  LName := StringReplace(LName, 'ü', 'u', [rfReplaceAll]);
  LName := StringReplace(LName, 'ç', 'c', [rfReplaceAll]);
  LName := StringReplace(LName, 'ñ', 'n', [rfReplaceAll]);

  Result := '';
  for i := 1 to Length(LName) do
  begin
    Ch := LName[i];
    case Ch of
      'a'..'z', '0'..'9': Result := Result + Ch;
      ' ', '-', '.', '/', '\': Result := Result + '_';
      '_':
        if (Length(Result) = 0) or (Result[Length(Result)] <> '_') then
          Result := Result + '_';
      else
        // ignora outros caracteres desconhecidos
        ;
    end;
  end;

  while (Length(Result) > 0) and (Result[1] = '_') do
    Delete(Result, 1, 1);
  while (Length(Result) > 0) and (Result[Length(Result)] = '_') do
    Delete(Result, Length(Result), 1);

  if Result = '' then
    Result := 'profile_' + FormatDateTime('yyyymmdd_hhnnss', Now);
end;

function ProfileToJSON(AProfile: TAIFaceProfile): string;
var
  RootObj, SampleObj: TJSONObject;
  ImgArr, TrigArr, SampArr, VecArr: TJSONArray;
  i, j: Integer;
  Sample: TAIFaceSample;
begin
  Result := '{}';
  if AProfile = nil then Exit;

  RootObj := TJSONObject.Create;
  try
    RootObj.Add('id', AProfile.ID);
    RootObj.Add('name', AProfile.Name);
    RootObj.Add('role', AProfile.Role);
    RootObj.Add('profile_text', AProfile.ProfileText);
    RootObj.Add('enabled', AProfile.Enabled);

    // Lista de Imagens
    ImgArr := TJSONArray.Create;
    for i := 0 to AProfile.Images.Count - 1 do
      ImgArr.Add(AProfile.Images[i]);
    RootObj.Add('images', ImgArr);

    // Lista de Gatilhos (Triggers)
    TrigArr := TJSONArray.Create;
    for i := 0 to AProfile.Triggers.Count - 1 do
      TrigArr.Add(AProfile.Triggers[i]);
    RootObj.Add('triggers', TrigArr);

    // Lista de Amostras / Descritores
    SampArr := TJSONArray.Create;
    for i := 0 to AProfile.Samples.Count - 1 do
    begin
      Sample := AProfile.Samples[i];
      SampleObj := TJSONObject.Create;
      SampleObj.Add('sample_id', Sample.SampleID);
      SampleObj.Add('image_file', Sample.ImageFile);
      SampleObj.Add('descriptor_version', Sample.DescriptorVersion);
      SampleObj.Add('algorithm', Sample.Algorithm);
      SampleObj.Add('created_at', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Sample.CreatedAt));
      SampleObj.Add('detection_confidence', Sample.DetectionConfidence);
      SampleObj.Add('quality_score', Sample.QualityScore);

      VecArr := TJSONArray.Create;
      for j := 0 to High(Sample.Vector) do
        VecArr.Add(Sample.Vector[j]);
      SampleObj.Add('vector', VecArr);

      SampArr.Add(SampleObj);
    end;
    RootObj.Add('samples', SampArr);

    Result := RootObj.FormatJSON;
  finally
    RootObj.Free;
  end;
end;

function JSONToProfile(const AJSON: string; AProfile: TAIFaceProfile; out AWarning: string): Boolean;
var
  Data: TJSONData;
  RootObj, SampleObj: TJSONObject;
  ImgArr, TrigArr, SampArr, VecArr: TJSONArray;
  i, j, DescrVer: Integer;
  Sample: TAIFaceSample;
  Vec: TDoubleDynArray;
  DateStr: string;
begin
  Result := False;
  AWarning := '';
  if (AProfile = nil) or (Trim(AJSON) = '') then Exit;

  try
    Data := GetJSON(AJSON);
    if Data = nil then Exit;
    try
      if Data.JSONType <> jtObject then Exit;
      RootObj := TJSONObject(Data);

      AProfile.ID := RootObj.Get('id', AProfile.ID);
      AProfile.Name := RootObj.Get('name', AProfile.Name);
      AProfile.Role := RootObj.Get('role', '');
      AProfile.ProfileText := RootObj.Get('profile_text', '');
      AProfile.Enabled := RootObj.Get('enabled', True);

      AProfile.Images.Clear;
      if RootObj.Find('images') <> nil then
      begin
        ImgArr := RootObj.Arrays['images'];
        for i := 0 to ImgArr.Count - 1 do
          AProfile.Images.Add(ImgArr.Strings[i]);
      end;

      AProfile.Triggers.Clear;
      if RootObj.Find('triggers') <> nil then
      begin
        TrigArr := RootObj.Arrays['triggers'];
        for i := 0 to TrigArr.Count - 1 do
          AProfile.Triggers.Add(TrigArr.Strings[i]);
      end;

      AProfile.Samples.Clear;
      if RootObj.Find('samples') <> nil then
      begin
        SampArr := RootObj.Arrays['samples'];
        for i := 0 to SampArr.Count - 1 do
        begin
          if SampArr.Types[i] = jtObject then
          begin
            SampleObj := TJSONObject(SampArr.Items[i]);
            DescrVer := SampleObj.Get('descriptor_version', 1);

            // Tolerância a versões desconhecidas do descriptor (Regra 25 e 60)
            if DescrVer > 1 then
            begin
              AWarning := AWarning + Format('Amostra %d ignorada: versão de descritor %d não suportada. Reconstrução necessária. ',
                [i, DescrVer]);
              Continue;
            end;

            Sample := TAIFaceSample.Create;
            Sample.SampleID := SampleObj.Get('sample_id', '');
            Sample.ImageFile := SampleObj.Get('image_file', '');
            Sample.DescriptorVersion := DescrVer;
            Sample.Algorithm := SampleObj.Get('algorithm', 'yolo_landmarks_geometry');
            Sample.DetectionConfidence := SampleObj.Get('detection_confidence', 0.0);
            Sample.QualityScore := SampleObj.Get('quality_score', 0.0);

            DateStr := SampleObj.Get('created_at', '');
            if DateStr <> '' then
            begin
              try
                Sample.CreatedAt := ISO8601ToDate(DateStr);
              except
                Sample.CreatedAt := Now;
              end;
            end
            else
              Sample.CreatedAt := Now;

            if SampleObj.Find('vector') <> nil then
            begin
              VecArr := SampleObj.Arrays['vector'];
              SetLength(Vec, VecArr.Count);
              for j := 0 to VecArr.Count - 1 do
                Vec[j] := VecArr.Floats[j];
              Sample.Vector := Vec;
            end;

            AProfile.Samples.Add(Sample);
          end;
        end;
      end;

      Result := True;
    finally
      Data.Free;
    end;
  except
    on E: Exception do
    begin
      AWarning := 'Erro ao carregar JSON de perfil: ' + E.Message;
      Result := False;
    end;
  end;
end;

function SaveProfileToFile(AProfile: TAIFaceProfile; const AFileName: string): Boolean;
var
  JsonStr: string;
  FS: TFileStream;
begin
  Result := False;
  if AProfile = nil then Exit;
  JsonStr := ProfileToJSON(AProfile);
  try
    ForceDirectories(ExtractFileDir(AFileName));
    FS := TFileStream.Create(AFileName, fmCreate);
    try
      if Length(JsonStr) > 0 then
        FS.WriteBuffer(JsonStr[1], Length(JsonStr));
      Result := True;
    finally
      FS.Free;
    end;
  except
    Result := False;
  end;
end;

function LoadProfileFromFile(const AFileName: string; AProfile: TAIFaceProfile; out AWarning: string): Boolean;
var
  SL: TStringList;
begin
  Result := False;
  AWarning := '';
  if not FileExists(AFileName) then
  begin
    AWarning := 'Arquivo não encontrado: ' + AFileName;
    Exit;
  end;

  SL := TStringList.Create;
  try
    try
      SL.LoadFromFile(AFileName);
      Result := JSONToProfile(SL.Text, AProfile, AWarning);
    except
      on E: Exception do
      begin
        AWarning := 'Falha ao ler arquivo ' + AFileName + ': ' + E.Message;
        Result := False;
      end;
    end;
  finally
    SL.Free;
  end;
end;

end.
