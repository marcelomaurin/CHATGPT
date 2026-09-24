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
    Values: TDoubleDynArray;
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
    FEnableRotationNormalization: Boolean;
  public
    constructor Create;
    function GetAlgorithmName: string;
    function GetVersion: Integer;
    function ValidateFaceQuality(const AObject: TYoloObject; out AError: string): Boolean;
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
    property EnableRotationNormalization: Boolean read FEnableRotationNormalization write FEnableRotationNormalization default True;
  end;

implementation

const
  DESCRIPTOR_VERSION = 1;
  DESCRIPTOR_ALGORITHM = 'yolo_landmarks_geometry';

{ TAIFaceDescriptorBuilder }

constructor TAIFaceDescriptorBuilder.Create;
begin
  inherited Create;
  FMinConfidence := 0.50;
  FMinFaceWidth := 30;
  FMinFaceHeight := 30;
  FMinKeyPoints := 5;
  FEnableRotationNormalization := True;
end;

function TAIFaceDescriptorBuilder.GetAlgorithmName: string;
begin
  Result := DESCRIPTOR_ALGORITHM;
end;

function TAIFaceDescriptorBuilder.GetVersion: Integer;
begin
  Result := DESCRIPTOR_VERSION;
end;

function TAIFaceDescriptorBuilder.ValidateFaceQuality(const AObject: TYoloObject; out AError: string): Boolean;
var
  FaceW, FaceH: Integer;
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

  if Length(AObject.KeyPoints) < FMinKeyPoints then
  begin
    AError := Format('Landmarks insuficientes para geração de descriptor (%d < %d)',
      [Length(AObject.KeyPoints), FMinKeyPoints]);
    Exit;
  end;

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
  SumConf: Double;

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
  SetLength(AData.Values, 0);
  AData.Quality := 0.0;
  AData.IsValid := False;
  AData.ErrorMessage := '';

  if not ValidateFaceQuality(AObject, ValidationErr) then
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

  // Calcula inclinação dos olhos para compensação de rotação
  EyeAngle := 0.0;
  EyeCenterX := (AObject.X1 + AObject.X2) / 2.0;
  EyeCenterY := (AObject.Y1 + AObject.Y2) / 2.0;

  if HasEyes then
  begin
    EyeAngle := ArcTan2(RightEye.Y - LeftEye.Y, RightEye.X - LeftEye.X);
    EyeCenterX := (LeftEye.X + RightEye.X) / 2.0;
    EyeCenterY := (LeftEye.Y + RightEye.Y) / 2.0;
    EyeDist := Max(1.0, Hypot(RightEye.X - LeftEye.X, RightEye.Y - LeftEye.Y));
  end
  else
    EyeDist := FaceW * 0.35; // estimativa padrão caso não haja olhos mapeados

  if FEnableRotationNormalization and HasEyes then
  begin
    CosA := Cos(-EyeAngle);
    SinA := Sin(-EyeAngle);
  end
  else
  begin
    CosA := 1.0;
    SinA := 0.0;
  end;

  // Rotaciona keypoints em torno do centro dos olhos
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

  ValCount := 0;
  SetLength(ValuesList, 0);

  // 1. Proporção do Bounding Box
  AddVal(FaceW / FaceH);

  // 2. Distância entre olhos normalizada pela largura da face
  AddVal(EyeDist / FaceW);

  // 3. Ângulo dos olhos normalizado em [-1..1]
  AddVal(EyeAngle / Pi);

  // 4. Medidas relativas do nariz (se disponível)
  if HasNose and HasEyes then
  begin
    AddVal(Hypot(Nose.X - LeftEye.X, Nose.Y - LeftEye.Y) / EyeDist);
    AddVal(Hypot(Nose.X - RightEye.X, Nose.Y - RightEye.Y) / EyeDist);
    AddVal((Nose.X - AObject.X1) / FaceW);
    AddVal((Nose.Y - AObject.Y1) / FaceH);
  end
  else
  begin
    AddVal(0.0);
    AddVal(0.0);
    AddVal(0.5);
    AddVal(0.5);
  end;

  // 5. Medidas relativas da boca (se disponível)
  if HasMouth then
  begin
    MouthWidth := Max(0.0, Hypot(MouthRight.X - MouthLeft.X, MouthRight.Y - MouthLeft.Y));
    MouthCenterX := (MouthLeft.X + MouthRight.X) / 2.0;
    MouthCenterY := (MouthLeft.Y + MouthRight.Y) / 2.0;

    AddVal(MouthWidth / EyeDist);
    AddVal((MouthCenterX - AObject.X1) / FaceW);
    AddVal((MouthCenterY - AObject.Y1) / FaceH);

    if HasNose then
      AddVal(Hypot(MouthCenterX - Nose.X, MouthCenterY - Nose.Y) / EyeDist)
    else
      AddVal(0.0);

    if HasEyes then
    begin
      AddVal(Hypot(MouthLeft.X - LeftEye.X, MouthLeft.Y - LeftEye.Y) / EyeDist);
      AddVal(Hypot(MouthRight.X - RightEye.X, MouthRight.Y - RightEye.Y) / EyeDist);
    end
    else
    begin
      AddVal(0.0);
      AddVal(0.0);
    end;
  end
  else
  begin
    AddVal(0.0);
    AddVal(0.5);
    AddVal(0.75);
    AddVal(0.0);
    AddVal(0.0);
    AddVal(0.0);
  end;

  // 6. Coordenadas rotacionadas e normalizadas ao bbox da face para cada landmark
  for i := 0 to KpCount - 1 do
  begin
    AddVal((RotPts[i].X - AObject.X1) / FaceW);
    AddVal((RotPts[i].Y - AObject.Y1) / FaceH);
  end;

  AData.Values := ValuesList;
  if KpCount > 0 then
    AData.Quality := (AObject.Confidence * 0.5) + ((SumConf / KpCount) * 0.5)
  else
    AData.Quality := AObject.Confidence;

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

  ASample := TAIFaceSample.Create;
  ASample.ImageFile := AImageFile;
  ASample.DescriptorVersion := Data.Version;
  ASample.Algorithm := Data.Algorithm;
  ASample.Vector := Data.Values;
  ASample.CreatedAt := Now;
  ASample.DetectionConfidence := AObject.Confidence;
  ASample.QualityScore := Data.Quality;
  Result := True;
end;

end.
