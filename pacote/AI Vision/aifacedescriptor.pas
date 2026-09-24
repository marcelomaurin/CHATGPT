unit aifacedescriptor;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, yolodetect, aifaceprofile;

type
  { TAIFaceDescriptorData }
  TAIFaceDescriptorData = record
    Version: Integer;
    Algorithm: string;
    ModelID: string;
    Values: TDoubleDynArray;
    FaceConfidence: Double;
    LandmarkConfidence: Double;
    Quality: Double;
    IsValid: Boolean;
    ErrorMessage: string;
  end;

  { IAIFaceDescriptorProvider }
  IAIFaceDescriptorProvider = interface
    ['{6E7C4D9A-87A5-4BF3-A281-0675D890BF74}']
    function GetAlgorithmName: string;
    function GetVersion: Integer;
    function BuildDescriptor(const AObject: TYoloObject;
      const AMapping: TYoloKeyPointMapping;
      out AData: TAIFaceDescriptorData): Boolean;
  end;

  { TAIFaceDescriptorBuilder }
  TAIFaceDescriptorBuilder = class(TInterfacedObject, IAIFaceDescriptorProvider)
  private
    FMinConfidence: Double;
    FMinFaceWidth: Integer;
    FMinFaceHeight: Integer;
    FMinKeyPoints: Integer;
    FMinKeyPointConfidence: Double;
    FEnrollmentQualityThreshold: Double;
    FRecognitionQualityThreshold: Double;
    FEnableRotationNormalization: Boolean;
    FModelID: string;
  public
    constructor Create;
    function GetAlgorithmName: string;
    function GetVersion: Integer;
    function ValidateFaceQuality(const AObject: TYoloObject;
      const AMapping: TYoloKeyPointMapping;
      out AError: string): Boolean;
    function BuildDescriptor(const AObject: TYoloObject;
      const AMapping: TYoloKeyPointMapping;
      out AData: TAIFaceDescriptorData): Boolean;
    function CreateSampleFromObject(const AObject: TYoloObject;
      const AMapping: TYoloKeyPointMapping;
      const AImageFile: string;
      out ASample: TAIFaceSample;
      out AError: string): Boolean;

    property MinConfidence: Double read FMinConfidence write FMinConfidence;
    property MinFaceWidth: Integer read FMinFaceWidth write FMinFaceWidth default 30;
    property MinFaceHeight: Integer read FMinFaceHeight write FMinFaceHeight default 30;
    property MinKeyPoints: Integer read FMinKeyPoints write FMinKeyPoints default 5;
    property MinKeyPointConfidence: Double read FMinKeyPointConfidence write FMinKeyPointConfidence;
    property EnrollmentQualityThreshold: Double read FEnrollmentQualityThreshold write FEnrollmentQualityThreshold;
    property RecognitionQualityThreshold: Double read FRecognitionQualityThreshold write FRecognitionQualityThreshold;
    property EnableRotationNormalization: Boolean read FEnableRotationNormalization write FEnableRotationNormalization default True;
    property ModelID: string read FModelID write FModelID;
  end;

function IsDescriptorCompatible(const AAlgorithmA, AAlgorithmB: string;
  AVersionA, AVersionB: Integer;
  const AModelIDA, AModelIDB: string;
  AAllowCrossModel: Boolean = False): Boolean;

implementation

const
  DESCRIPTOR_VERSION = 1;
  DESCRIPTOR_ALGORITHM = 'yolo_landmarks_geometry';

function IsDescriptorCompatible(const AAlgorithmA, AAlgorithmB: string;
  AVersionA, AVersionB: Integer;
  const AModelIDA, AModelIDB: string;
  AAllowCrossModel: Boolean): Boolean;
begin
  if not SameText(AAlgorithmA, AAlgorithmB) then
    Exit(False);
  if AVersionA <> AVersionB then
    Exit(False);
  if not AAllowCrossModel then
  begin
    if (AModelIDA <> '') and (AModelIDB <> '') and not SameText(AModelIDA, AModelIDB) then
      Exit(False);
  end;
  Result := True;
end;

{ TAIFaceDescriptorBuilder }

constructor TAIFaceDescriptorBuilder.Create;
begin
  inherited Create;
  FMinConfidence := 0.50;
  FMinFaceWidth := 30;
  FMinFaceHeight := 30;
  FMinKeyPoints := 5;
  FMinKeyPointConfidence := 0.35;
  FEnrollmentQualityThreshold := 0.70;
  FRecognitionQualityThreshold := 0.50;
  FEnableRotationNormalization := True;
  FModelID := 'yolov8n-face';
end;

function TAIFaceDescriptorBuilder.GetAlgorithmName: string;
begin
  Result := DESCRIPTOR_ALGORITHM;
end;

function TAIFaceDescriptorBuilder.GetVersion: Integer;
begin
  Result := DESCRIPTOR_VERSION;
end;

function TAIFaceDescriptorBuilder.ValidateFaceQuality(const AObject: TYoloObject;
  const AMapping: TYoloKeyPointMapping;
  out AError: string): Boolean;
var
  FaceW, FaceH: Integer;
  KpLen: Integer;
  Idx: Integer;
  procedure CheckLandmark(const ASemantic: TYoloLandmarkSemantic; const AName: string);
  begin
    if AError <> '' then Exit;
    if AMapping <> nil then
    begin
      Idx := AMapping.GetIndex(ASemantic);
      if (Idx < 0) or (Idx >= KpLen) then
      begin
        AError := Format('Landmark facial obrigatório ausente: %s', [AName]);
        Exit;
      end;
      if AObject.KeyPoints[Idx].Confidence < FMinKeyPointConfidence then
      begin
        AError := Format('Landmark %s com confiança abaixo do mínimo (%.2f < %.2f)',
          [AName, AObject.KeyPoints[Idx].Confidence, FMinKeyPointConfidence]);
        Exit;
      end;
    end;
  end;

begin
  Result := False;
  AError := '';

  if AObject.Confidence < FMinConfidence then
  begin
    AError := Format('Confiança da detecção muito baixa (%.2f < %.2f)', [AObject.Confidence, FMinConfidence]);
    Exit;
  end;

  FaceW := AObject.X2 - AObject.X1;
  FaceH := AObject.Y2 - AObject.Y1;

  if (FaceW <= 0) or (FaceH <= 0) then
  begin
    AError := 'Bounding box da face inválido (dimensões nulas ou negativas)';
    Exit;
  end;

  if (FaceW < FMinFaceWidth) or (FaceH < FMinFaceHeight) then
  begin
    AError := Format('Bounding box muito pequeno (%dx%d < %dx%d)', [FaceW, FaceH, FMinFaceWidth, FMinFaceHeight]);
    Exit;
  end;

  KpLen := Length(AObject.KeyPoints);
  if KpLen < FMinKeyPoints then
  begin
    AError := Format('Landmarks insuficientes para geração de descriptor (%d < %d)', [KpLen, FMinKeyPoints]);
    Exit;
  end;

  // Validação semântica e de confiança individual dos 5 pontos
  CheckLandmark(ylsLeftEye, 'olho esquerdo');
  CheckLandmark(ylsRightEye, 'olho direito');
  CheckLandmark(ylsNose, 'nariz');
  CheckLandmark(ylsMouthLeft, 'canto esquerdo da boca');
  CheckLandmark(ylsMouthRight, 'canto direito da boca');

  if AError <> '' then Exit;

  Result := True;
end;

function TAIFaceDescriptorBuilder.BuildDescriptor(const AObject: TYoloObject;
  const AMapping: TYoloKeyPointMapping;
  out AData: TAIFaceDescriptorData): Boolean;
var
  FaceW, FaceH: Double;
  ValidationErr: string;
  LeftEye, RightEye, Nose, MouthLeft, MouthRight: TYoloKeyPoint;
  HasEyes, HasNose, HasMouth: Boolean;
  EyeAngle, EyeCenterX, EyeCenterY: Double;
  CosA, SinA: Double;
  EyeDist, MouthWidth: Double;
  MouthCenterX, MouthCenterY: Double;
  RotPts: array of record X, Y: Double; end;
  i, KpCount: Integer;
  CurX, CurY, RotX, RotY: Double;
  ValuesList: array of Double;
  ValCount: Integer;
  SumConf, LmConf, OverallQuality: Double;

  procedure AddVal(const V: Double);
  begin
    SetLength(ValuesList, ValCount + 1);
    ValuesList[ValCount] := V;
    Inc(ValCount);
  end;

begin
  Result := False;
  AData.Version := DESCRIPTOR_VERSION;
  AData.Algorithm := DESCRIPTOR_ALGORITHM;
  AData.ModelID := FModelID;
  SetLength(AData.Values, 0);
  AData.FaceConfidence := AObject.Confidence;
  AData.LandmarkConfidence := 0.0;
  AData.Quality := 0.0;
  AData.IsValid := False;
  AData.ErrorMessage := '';

  if not ValidateFaceQuality(AObject, AMapping, ValidationErr) then
  begin
    AData.ErrorMessage := ValidationErr;
    Exit;
  end;

  FaceW := Max(1.0, Double(AObject.X2 - AObject.X1));
  FaceH := Max(1.0, Double(AObject.Y2 - AObject.Y1));

  HasEyes := YoloFindLandmark(AObject, AMapping, ylsLeftEye, LeftEye) and
             YoloFindLandmark(AObject, AMapping, ylsRightEye, RightEye);
  HasNose := YoloFindLandmark(AObject, AMapping, ylsNose, Nose);
  HasMouth := YoloFindLandmark(AObject, AMapping, ylsMouthLeft, MouthLeft) and
              YoloFindLandmark(AObject, AMapping, ylsMouthRight, MouthRight);

  // Para reconhecimento de identidade, não estimar se landmarks essenciais faltarem
  if not (HasEyes and HasNose and HasMouth) then
  begin
    AData.ErrorMessage := 'Landmarks faciais obrigatórios incompletos para reconhecimento de identidade.';
    Exit;
  end;

  EyeAngle := ArcTan2(RightEye.Y - LeftEye.Y, RightEye.X - LeftEye.X);
  EyeCenterX := (LeftEye.X + RightEye.X) / 2.0;
  EyeCenterY := (LeftEye.Y + RightEye.Y) / 2.0;
  EyeDist := Max(1.0, Hypot(RightEye.X - LeftEye.X, RightEye.Y - LeftEye.Y));

  if FEnableRotationNormalization then
  begin
    CosA := Cos(-EyeAngle);
    SinA := Sin(-EyeAngle);
  end
  else
  begin
    CosA := 1.0;
    SinA := 0.0;
  end;

  KpCount := Length(AObject.KeyPoints);
  SetLength(RotPts, KpCount);
  SumConf := 0.0;
  for i := 0 to KpCount - 1 do
  begin
    CurX := AObject.KeyPoints[i].X - EyeCenterX;
    CurY := AObject.KeyPoints[i].Y - EyeCenterY;
    RotX := (CosA * CurX) - (SinA * CurY) + EyeCenterX;
    RotY := (SinA * CurX) + (CosA * CurY) + EyeCenterY;
    RotPts[i].X := RotX;
    RotPts[i].Y := RotY;
    SumConf := SumConf + AObject.KeyPoints[i].Confidence;
  end;

  LmConf := SumConf / KpCount;
  OverallQuality := (AObject.Confidence * 0.5) + (LmConf * 0.5);

  AData.LandmarkConfidence := LmConf;
  AData.Quality := OverallQuality;

  if OverallQuality < FRecognitionQualityThreshold then
  begin
    AData.ErrorMessage := Format('Qualidade facial insuficiente para reconhecimento (%.2f < %.2f)',
      [OverallQuality, FRecognitionQualityThreshold]);
    Exit;
  end;

  ValCount := 0;
  SetLength(ValuesList, 0);

  // 1. Razão do Bounding Box
  AddVal(FaceW / FaceH);

  // 2. Distância entre olhos normalizada pela largura da face
  AddVal(EyeDist / FaceW);

  // 3. Ângulo dos olhos normalizado em [-1..1]
  AddVal(EyeAngle / Pi);

  // 4. Medidas relativas do nariz
  AddVal(Hypot(Nose.X - LeftEye.X, Nose.Y - LeftEye.Y) / EyeDist);
  AddVal(Hypot(Nose.X - RightEye.X, Nose.Y - RightEye.Y) / EyeDist);
  AddVal((Nose.X - AObject.X1) / FaceW);
  AddVal((Nose.Y - AObject.Y1) / FaceH);

  // 5. Medidas relativas da boca
  MouthWidth := Max(0.0, Hypot(MouthRight.X - MouthLeft.X, MouthRight.Y - MouthLeft.Y));
  MouthCenterX := (MouthLeft.X + MouthRight.X) / 2.0;
  MouthCenterY := (MouthLeft.Y + MouthRight.Y) / 2.0;

  AddVal(MouthWidth / EyeDist);
  AddVal((MouthCenterX - AObject.X1) / FaceW);
  AddVal((MouthCenterY - AObject.Y1) / FaceH);
  AddVal(Hypot(MouthCenterX - Nose.X, MouthCenterY - Nose.Y) / EyeDist);
  AddVal(Hypot(MouthLeft.X - LeftEye.X, MouthLeft.Y - LeftEye.Y) / EyeDist);
  AddVal(Hypot(MouthRight.X - RightEye.X, MouthRight.Y - RightEye.Y) / EyeDist);

  // 6. Coordenadas rotacionadas e normalizadas ao bbox da face para cada landmark
  for i := 0 to KpCount - 1 do
  begin
    AddVal((RotPts[i].X - AObject.X1) / FaceW);
    AddVal((RotPts[i].Y - AObject.Y1) / FaceH);
  end;

  AData.Values := ValuesList;
  AData.IsValid := True;
  Result := True;
end;

function TAIFaceDescriptorBuilder.CreateSampleFromObject(const AObject: TYoloObject;
  const AMapping: TYoloKeyPointMapping;
  const AImageFile: string;
  out ASample: TAIFaceSample;
  out AError: string): Boolean;
var
  Data: TAIFaceDescriptorData;
begin
  Result := False;
  ASample := nil;
  AError := '';

  if not BuildDescriptor(AObject, AMapping, Data) then
  begin
    AError := Data.ErrorMessage;
    Exit;
  end;

  // Limiar mais rigoroso para cadastro (Task 12)
  if Data.Quality < FEnrollmentQualityThreshold then
  begin
    AError := Format('A face foi detectada, mas a qualidade é insuficiente para cadastro (%.2f < %.2f).',
      [Data.Quality, FEnrollmentQualityThreshold]);
    Exit;
  end;

  ASample := TAIFaceSample.Create;
  ASample.ImageFile := AImageFile;
  ASample.DescriptorVersion := Data.Version;
  ASample.Algorithm := Data.Algorithm;
  ASample.ModelID := Data.ModelID;
  ASample.Vector := Data.Values;
  ASample.CreatedAt := Now;
  ASample.DetectionConfidence := Data.FaceConfidence;
  ASample.QualityScore := Data.Quality;
  Result := True;
end;

end.
