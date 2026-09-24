unit aifacerecognition;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Math,
  yolodetect, facedetection, aifacetracker,
  aifaceprofile, aifacedescriptor, aifacematcher, aifaceregistry;

type
  { Modos de detecção }
  TFaceRecognitionDetectorMode = (
    frmAuto,
    frmYOLO,
    frmOpenCVFallback
  );

  { Estados de reconhecimento }
  TFaceRecognitionState = (
    frsIdle,
    frsDetected,
    frsTracked,
    frsRecognized,
    frsLost
  );

  { Eventos de alto nível }
  TOnFaceDetectedEvent = procedure(Sender: TObject; const AFaceRect: TRect; Confidence: Double) of object;
  TOnFaceRecognizedEvent = procedure(Sender: TObject; const AResult: TFaceMatchResult) of object;
  TOnFaceUnknownEvent = procedure(Sender: TObject; const AResult: TFaceMatchResult) of object;
  TOnFaceAmbiguousEvent = procedure(Sender: TObject; const AResult: TFaceMatchResult) of object;
  TOnFaceLostEvent = procedure(Sender: TObject) of object;

  { TAIFaceRecognition }
  TAIFaceRecognition = class(TComponent)
  private
    FYolo: TYOLO;
    FFaceDetection: TFaceDetection;
    FFaceTracker: TAIFaceTracker;
    FRegistry: TAIFaceRegistry;
    FDescriptorBuilder: TAIFaceDescriptorBuilder;
    FMatcher: TAIFaceMatcher;

    FOwnsRegistry: Boolean;
    FOwnsDescriptorBuilder: Boolean;
    FOwnsMatcher: Boolean;

    FDetectorMode: TFaceRecognitionDetectorMode;
    FEnableTracking: Boolean;
    FDebugLogging: Boolean;
    FLastState: TFaceRecognitionState;
    FLastError: string;

    FOnFaceDetected: TOnFaceDetectedEvent;
    FOnFaceRecognized: TOnFaceRecognizedEvent;
    FOnFaceUnknown: TOnFaceUnknownEvent;
    FOnFaceAmbiguous: TOnFaceAmbiguousEvent;
    FOnFaceLost: TOnFaceLostEvent;

    procedure SetYolo(const AValue: TYOLO);
    procedure SetFaceDetection(const AValue: TFaceDetection);
    procedure SetFaceTracker(const AValue: TAIFaceTracker);
    procedure SetRegistry(const AValue: TAIFaceRegistry);
    procedure LogDebug(const AMsg: string);
    function GetProfilesArray: TAIFaceProfileArray;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function RecognizeFile(const AImageFile: string; out AResults: TFaceMatchResultArray): Boolean;
    function RecognizeBitmap(ABitmap: TCustomBitmap; out AResults: TFaceMatchResultArray): Boolean;
    function EnrollSample(const AProfileID, AImageFile: string; out AError: string): Boolean;

    property DescriptorBuilder: TAIFaceDescriptorBuilder read FDescriptorBuilder;
    property Matcher: TAIFaceMatcher read FMatcher;
    property LastState: TFaceRecognitionState read FLastState;
    property LastError: string read FLastError;
  published
    property Yolo: TYOLO read FYolo write SetYolo;
    property FaceDetection: TFaceDetection read FFaceDetection write SetFaceDetection;
    property FaceTracker: TAIFaceTracker read FFaceTracker write SetFaceTracker;
    property Registry: TAIFaceRegistry read FRegistry write SetRegistry;
    property DetectorMode: TFaceRecognitionDetectorMode read FDetectorMode write FDetectorMode default frmAuto;
    property EnableTracking: Boolean read FEnableTracking write FEnableTracking default False;
    property DebugLogging: Boolean read FDebugLogging write FDebugLogging default False;

    property OnFaceDetected: TOnFaceDetectedEvent read FOnFaceDetected write FOnFaceDetected;
    property OnFaceRecognized: TOnFaceRecognizedEvent read FOnFaceRecognized write FOnFaceRecognized;
    property OnFaceUnknown: TOnFaceUnknownEvent read FOnFaceUnknown write FOnFaceUnknown;
    property OnFaceAmbiguous: TOnFaceAmbiguousEvent read FOnFaceAmbiguous write FOnFaceAmbiguous;
    property OnFaceLost: TOnFaceLostEvent read FOnFaceLost write FOnFaceLost;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('AI Machine Learning', [TAIFaceRecognition]);
end;

{ TAIFaceRecognition }

constructor TAIFaceRecognition.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FYolo := nil;
  FFaceDetection := nil;
  FFaceTracker := nil;
  FRegistry := TAIFaceRegistry.Create;
  FOwnsRegistry := True;
  FDescriptorBuilder := TAIFaceDescriptorBuilder.Create;
  FOwnsDescriptorBuilder := True;
  FMatcher := TAIFaceMatcher.Create;
  FOwnsMatcher := True;

  FDetectorMode := frmAuto;
  FEnableTracking := False;
  FDebugLogging := False;
  FLastState := frsIdle;
  FLastError := '';
end;

destructor TAIFaceRecognition.Destroy;
begin
  if FOwnsRegistry then
    FreeAndNil(FRegistry);
  if FOwnsDescriptorBuilder then
    FreeAndNil(FDescriptorBuilder);
  if FOwnsMatcher then
    FreeAndNil(FMatcher);
  inherited Destroy;
end;

procedure TAIFaceRecognition.LogDebug(const AMsg: string);
begin
  if FDebugLogging then
  begin
    Writeln('[TAIFaceRecognition Debug] ', FormatDateTime('hh:nn:ss.zzz', Now), ' - ', AMsg);
  end;
end;

procedure TAIFaceRecognition.SetYolo(const AValue: TYOLO);
begin
  if FYolo = AValue then Exit;
  FYolo := AValue;
  if FYolo <> nil then
    FYolo.FreeNotification(Self);
end;

procedure TAIFaceRecognition.SetFaceDetection(const AValue: TFaceDetection);
begin
  if FFaceDetection = AValue then Exit;
  FFaceDetection := AValue;
  if FFaceDetection <> nil then
    FFaceDetection.FreeNotification(Self);
end;

procedure TAIFaceRecognition.SetFaceTracker(const AValue: TAIFaceTracker);
begin
  if FFaceTracker = AValue then Exit;
  FFaceTracker := AValue;
  if FFaceTracker <> nil then
    FFaceTracker.FreeNotification(Self);
end;

procedure TAIFaceRecognition.SetRegistry(const AValue: TAIFaceRegistry);
begin
  if FRegistry = AValue then Exit;
  if FOwnsRegistry and (FRegistry <> nil) then
  begin
    FRegistry.Free;
    FOwnsRegistry := False;
  end;
  FRegistry := AValue;
end;

procedure TAIFaceRecognition.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FYolo then FYolo := nil;
    if AComponent = FFaceDetection then FFaceDetection := nil;
    if AComponent = FFaceTracker then FFaceTracker := nil;
  end;
end;

function TAIFaceRecognition.GetProfilesArray: TAIFaceProfileArray;
var
  i: Integer;
begin
  if FRegistry = nil then
  begin
    SetLength(Result, 0);
    Exit;
  end;
  SetLength(Result, FRegistry.ProfileCount);
  for i := 0 to FRegistry.ProfileCount - 1 do
    Result[i] := FRegistry.Profiles[i];
end;

function TAIFaceRecognition.RecognizeFile(const AImageFile: string; out AResults: TFaceMatchResultArray): Boolean;
var
  Objects: TYoloObjectArray;
  OpenCVFaces: TFaceRectArray;
  UseYolo: Boolean;
  i: Integer;
  DescData: TAIFaceDescriptorData;
  MatchRes: TFaceMatchResult;
  StartTime, InfTime, MatchTime: QWord;
  FaceRect: TRect;
  ResCount: Integer;
begin
  Result := False;
  SetLength(AResults, 0);
  FLastError := '';
  StartTime := GetTickCount64;

  if not FileExists(AImageFile) then
  begin
    FLastError := 'Arquivo de imagem não encontrado: ' + AImageFile;
    Exit;
  end;

  UseYolo := False;
  if (FDetectorMode = frmYOLO) or (FDetectorMode = frmAuto) then
  begin
    if FYolo <> nil then
      UseYolo := True
    else if FDetectorMode = frmYOLO then
    begin
      FLastError := 'Componente TYOLO não foi configurado.';
      Exit;
    end;
  end;

  if UseYolo then
  begin
    LogDebug(Format('Iniciando inferência YOLO no arquivo "%s" (Modelo: %s)', [AImageFile, FYolo.ModelPath]));
    if not FYolo.DetectObjects(AImageFile, Objects) then
    begin
      FLastError := 'Falha na detecção YOLO: ' + FYolo.LastError;
      Exit;
    end;
    InfTime := GetTickCount64 - StartTime;
    LogDebug(Format('Inferência YOLO concluída em %d ms. Detecções: %d', [InfTime, Length(Objects)]));

    ResCount := 0;
    SetLength(AResults, Length(Objects));

    for i := 0 to High(Objects) do
    begin
      FaceRect := Rect(Objects[i].X1, Objects[i].Y1, Objects[i].X2, Objects[i].Y2);
      FLastState := frsDetected;
      if Assigned(FOnFaceDetected) then
        FOnFaceDetected(Self, FaceRect, Objects[i].Confidence);

      if not FYolo.HasKeyPoints(Objects[i]) then
      begin
        LogDebug(Format('Aviso: Modelo YOLO "%s" não retornou keypoints/landmarks para objeto %d (%s).',
          [FYolo.ModelPath, i, Objects[i].ClassName]));
      end;

      // Gera descritor geométrico da face
      if FDescriptorBuilder.BuildDescriptor(Objects[i], FYolo.KeyPointMapping, DescData) then
      begin
        StartTime := GetTickCount64;
        FMatcher.MatchProfiles(DescData.Values, GetProfilesArray, MatchRes);
        MatchTime := GetTickCount64 - StartTime;

        LogDebug(Format('Matching face %d: Score=%.3f, Dist=%.3f, Status=%d, Perfil=%s (Tempo=%d ms)',
          [i, MatchRes.Score, MatchRes.Distance, Ord(MatchRes.Status), MatchRes.ProfileName, MatchTime]));

        AResults[ResCount] := MatchRes;
        Inc(ResCount);

        case MatchRes.Status of
          fmsMatched:
          begin
            FLastState := frsRecognized;
            if Assigned(FOnFaceRecognized) then
              FOnFaceRecognized(Self, MatchRes);
          end;
          fmsAmbiguous:
          begin
            if Assigned(FOnFaceAmbiguous) then
              FOnFaceAmbiguous(Self, MatchRes);
          end;
          fmsUnknown:
          begin
            if Assigned(FOnFaceUnknown) then
              FOnFaceUnknown(Self, MatchRes);
          end;
          else ;
        end;
      end
      else
      begin
        LogDebug(Format('Descriptor não gerado para objeto %d: %s', [i, DescData.ErrorMessage]));
        MatchRes.Status := fmsError;
        MatchRes.ProfileID := '';
        MatchRes.ProfileName := '';
        MatchRes.Score := 0.0;
        MatchRes.Distance := 0.0;
        MatchRes.SampleIndex := -1;
        MatchRes.ErrorMessage := DescData.ErrorMessage;
        AResults[ResCount] := MatchRes;
        Inc(ResCount);
      end;
    end;

    SetLength(AResults, ResCount);
    if ResCount = 0 then
    begin
      FLastState := frsLost;
      if Assigned(FOnFaceLost) then
        FOnFaceLost(Self);
    end;

    Result := True;
  end
  else if (FDetectorMode = frmOpenCVFallback) or ((FDetectorMode = frmAuto) and (FFaceDetection <> nil)) then
  begin
    // Fallback OpenCV (Haar Cascade) - apenas localiza, sem reconhecimento de landmarks
    LogDebug('Usando fallback Haar Cascade (OpenCV)...');
    if FFaceDetection = nil then
    begin
      FLastError := 'Componente TFaceDetection não foi configurado para fallback.';
      Exit;
    end;

    if not FFaceDetection.DetectFaces(AImageFile, OpenCVFaces) then
    begin
      FLastError := 'Falha na detecção Haar Cascade: ' + FFaceDetection.LastError;
      Exit;
    end;

    SetLength(AResults, Length(OpenCVFaces));
    for i := 0 to High(OpenCVFaces) do
    begin
      FaceRect := Rect(OpenCVFaces[i].X, OpenCVFaces[i].Y,
                       OpenCVFaces[i].X + OpenCVFaces[i].Width,
                       OpenCVFaces[i].Y + OpenCVFaces[i].Height);
      FLastState := frsDetected;
      if Assigned(FOnFaceDetected) then
        FOnFaceDetected(Self, FaceRect, 1.0);

      AResults[i].Status := fmsUnknown;
      AResults[i].ProfileID := '';
      AResults[i].ProfileName := '';
      AResults[i].Score := 0.0;
      AResults[i].Distance := 0.0;
      AResults[i].SampleIndex := -1;
      AResults[i].ErrorMessage := 'Fallback OpenCV Haar Cascade não fornece landmarks para identificação facial.';

      if Assigned(FOnFaceUnknown) then
        FOnFaceUnknown(Self, AResults[i]);
    end;

    if Length(OpenCVFaces) = 0 then
    begin
      FLastState := frsLost;
      if Assigned(FOnFaceLost) then
        FOnFaceLost(Self);
    end;

    Result := True;
  end
  else
  begin
    FLastError := 'Nenhum detector de faces configurado (nem TYOLO nem TFaceDetection).';
    Result := False;
  end;
end;

function TAIFaceRecognition.RecognizeBitmap(ABitmap: TCustomBitmap; out AResults: TFaceMatchResultArray): Boolean;
var
  TempFile: string;
begin
  Result := False;
  SetLength(AResults, 0);
  FLastError := '';

  if ABitmap = nil then
  begin
    FLastError := 'Bitmap nulo fornecido para RecognizeBitmap.';
    Exit;
  end;

  TempFile := IncludeTrailingPathDelimiter(GetTempDir) + Format('aiface_%d.bmp', [GetTickCount64]);
  try
    try
      ABitmap.SaveToFile(TempFile);
      Result := RecognizeFile(TempFile, AResults);
    except
      on E: Exception do
      begin
        FLastError := 'Falha ao salvar bitmap temporário para reconhecimento: ' + E.Message;
        Result := False;
      end;
    end;
  finally
    if FileExists(TempFile) then
      DeleteFile(TempFile);
  end;
end;

function TAIFaceRecognition.EnrollSample(const AProfileID, AImageFile: string; out AError: string): Boolean;
begin
  Result := False;
  AError := '';
  if FRegistry = nil then
  begin
    AError := 'Registry não associado ao TAIFaceRecognition.';
    Exit;
  end;

  if FYolo = nil then
  begin
    AError := 'TYOLO não associado ao TAIFaceRecognition para cadastro de amostras.';
    Exit;
  end;

  Result := FRegistry.AddSampleFromFile(AProfileID, AImageFile, FYolo, FDescriptorBuilder, AError);
end;

end.
