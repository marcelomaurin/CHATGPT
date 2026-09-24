unit aifacerecognition;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Math, aibase,
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

    // Configuração de classes faciais (Tarefas 1 e 2)
    FFaceClassName: string;
    FFaceClasses: TStringList;

    // Configurações temporais de tracking e confirmação (Tarefas 17, 18, 20, 22, 24)
    FYoloRefreshIntervalMs: Integer;
    FRecognitionIntervalMs: Integer;
    FRequiredConfirmations: Integer;
    FConfirmationWindowMs: Integer;
    FRecognitionCooldownMs: Integer;
    FFaceLostTimeoutMs: Integer;
    FUnknownCooldownMs: Integer;

    // Estados temporais internos
    FLastYoloTick: QWord;
    FLastRecognitionTick: QWord;
    FLastFaceSeenTick: QWord;
    FLastRecognizedTick: QWord;
    FLastUnknownTick: QWord;
    FLastCandidateTick: QWord;

    FTrackedFaceRect: TRect;
    FIsTracking: Boolean;
    FTempIDCounter: Integer;
    FTemporaryFaceID: string;

    FConfirmationCount: Integer;
    FCurrentCandidateID: string;
    FLastConfirmedProfileID: string;
    FLastConfirmedScore: Double;
    FProfileCooldowns: TStringList;

    // Diagnosticos de runtime
    FLastInferenceMs: Integer;
    FLastMatchMs: Integer;
    FLastFaceCount: Integer;
    FLastRecognitionStatus: string;
    FTrackingMaxScore: Double;
    FCancelRequested: Boolean;
    FOnLog: TAILogEvent;

    // Contadores de diagnóstico para comprovar tracking (Tarefa 66)
    FYoloInferenceCount: Integer;
    FTrackedFrameCount: Integer;

    FOnFaceDetected: TOnFaceDetectedEvent;
    FOnFaceRecognized: TOnFaceRecognizedEvent;
    FOnFaceUnknown: TOnFaceUnknownEvent;
    FOnFaceAmbiguous: TOnFaceAmbiguousEvent;
    FOnFaceLost: TOnFaceLostEvent;

    procedure SetYolo(const AValue: TYOLO);
    procedure SetFaceDetection(const AValue: TFaceDetection);
    procedure SetFaceTracker(const AValue: TAIFaceTracker);
    procedure SetRegistry(const AValue: TAIFaceRegistry);
    procedure SetFaceClasses(const AValue: TStringList);
    procedure LogDebug(const AMsg: string);
    function GetProfilesArray: TAIFaceProfileArray;
    function IsFaceObject(const AObject: TYoloObject): Boolean;
    procedure ResetTrackingState;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    function RecognizeFile(const AImageFile: string; out AResults: TFaceMatchResultArray): Boolean;
    function RecognizeBitmap(ABitmap: TCustomBitmap; out AResults: TFaceMatchResultArray): Boolean;
    function ProcessFrame(ABitmap: TBitmap; out AResults: TFaceMatchResultArray): Boolean;
    function EnrollSample(const AProfileID, AImageFile: string; out AError: string): Boolean;
    function ValidateRecognitionModel(out AMessage: string): Boolean;
    function SelfTestRecognitionModel(const ATestImage: string; out AMessage: string): Boolean;
    procedure StopProcessing;
    function CanRecognizeProfile(const AProfileID: string; ANowTick: QWord): Boolean;
    procedure RecordRecognizedProfile(const AProfileID: string; ANowTick: QWord);

    property DescriptorBuilder: TAIFaceDescriptorBuilder read FDescriptorBuilder;
    property Matcher: TAIFaceMatcher read FMatcher;
    property LastState: TFaceRecognitionState read FLastState;
    property LastError: string read FLastError;

    // Propriedades somente leitura de estado reconhecido (Tarefa 25)
    property LastRecognizedProfileID: string read FLastConfirmedProfileID;
    property LastRecognitionScore: Double read FLastConfirmedScore;
    property LastRecognitionTick: QWord read FLastRecognizedTick;
    property TemporaryFaceID: string read FTemporaryFaceID;
    property YoloInferenceCount: Integer read FYoloInferenceCount;
    property TrackedFrameCount: Integer read FTrackedFrameCount;
    property LastInferenceMs: Integer read FLastInferenceMs;
    property LastMatchMs: Integer read FLastMatchMs;
    property LastFaceCount: Integer read FLastFaceCount;
    property LastRecognitionStatus: string read FLastRecognitionStatus;
  published
    property TrackingMaxScore: Double read FTrackingMaxScore write FTrackingMaxScore;
    property OnLog: TAILogEvent read FOnLog write FOnLog;
    property Yolo: TYOLO read FYolo write SetYolo;
    property FaceDetection: TFaceDetection read FFaceDetection write SetFaceDetection;
    property FaceTracker: TAIFaceTracker read FFaceTracker write SetFaceTracker;
    property Registry: TAIFaceRegistry read FRegistry write SetRegistry;
    property DetectorMode: TFaceRecognitionDetectorMode read FDetectorMode write FDetectorMode default frmAuto;
    property EnableTracking: Boolean read FEnableTracking write FEnableTracking default False;
    property DebugLogging: Boolean read FDebugLogging write FDebugLogging default False;

    // Classes faciais
    property FaceClassName: string read FFaceClassName write FFaceClassName;
    property FaceClasses: TStringList read FFaceClasses write SetFaceClasses;

    // Parâmetros temporais
    property YoloRefreshIntervalMs: Integer read FYoloRefreshIntervalMs write FYoloRefreshIntervalMs default 1500;
    property RecognitionIntervalMs: Integer read FRecognitionIntervalMs write FRecognitionIntervalMs default 300;
    property RequiredConfirmations: Integer read FRequiredConfirmations write FRequiredConfirmations default 3;
    property ConfirmationWindowMs: Integer read FConfirmationWindowMs write FConfirmationWindowMs default 2000;
    property RecognitionCooldownMs: Integer read FRecognitionCooldownMs write FRecognitionCooldownMs default 30000;
    property FaceLostTimeoutMs: Integer read FFaceLostTimeoutMs write FFaceLostTimeoutMs default 2000;
    property UnknownCooldownMs: Integer read FUnknownCooldownMs write FUnknownCooldownMs default 5000;

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

  FFaceClassName := 'face';
  FFaceClasses := TStringList.Create;
  FFaceClasses.Duplicates := dupIgnore;
  FFaceClasses.Add('face');
  FFaceClasses.Add('human_face');

  FProfileCooldowns := TStringList.Create;
  FProfileCooldowns.Duplicates := dupIgnore;
  FTrackingMaxScore := 0.85;
  FCancelRequested := False;
  FLastInferenceMs := 0;
  FLastMatchMs := 0;
  FLastFaceCount := 0;
  FLastRecognitionStatus := 'Idle';

  FYoloRefreshIntervalMs := 1500;
  FRecognitionIntervalMs := 300;
  FRequiredConfirmations := 3;
  FConfirmationWindowMs := 2000;
  FRecognitionCooldownMs := 30000;
  FFaceLostTimeoutMs := 2000;
  FUnknownCooldownMs := 5000;

  FLastYoloTick := 0;
  FLastRecognitionTick := 0;
  FLastFaceSeenTick := 0;
  FLastRecognizedTick := 0;
  FLastUnknownTick := 0;
  FLastCandidateTick := 0;

  FIsTracking := False;
  FTempIDCounter := 0;
  FTemporaryFaceID := '';
  FConfirmationCount := 0;
  FCurrentCandidateID := '';
  FLastConfirmedProfileID := '';
  FLastConfirmedScore := 0.0;

  FYoloInferenceCount := 0;
  FTrackedFrameCount := 0;
end;

destructor TAIFaceRecognition.Destroy;
begin
  // Correção de ownership: apenas destrói objetos que foram criados internamente (Tarefa 52)
  if FOwnsRegistry and (FRegistry <> nil) then
    FreeAndNil(FRegistry);
  if FOwnsDescriptorBuilder and (FDescriptorBuilder <> nil) then
    FreeAndNil(FDescriptorBuilder);
  if FOwnsMatcher and (FMatcher <> nil) then
    FreeAndNil(FMatcher);

  FreeAndNil(FFaceClasses);
  FreeAndNil(FProfileCooldowns);
  inherited Destroy;
end;

procedure TAIFaceRecognition.LogDebug(const AMsg: string);
begin
  if Assigned(FOnLog) then
    FOnLog(Self, llDebug, AMsg)
  else if FDebugLogging and IsConsole then
    Writeln('[TAIFaceRecognition Debug] ', FormatDateTime('hh:nn:ss.zzz', Now), ' - ', AMsg);
end;

procedure TAIFaceRecognition.StopProcessing;
begin
  FCancelRequested := True;
end;

function TAIFaceRecognition.CanRecognizeProfile(const AProfileID: string; ANowTick: QWord): Boolean;
var
  Idx: Integer;
  LastTick: QWord;
begin
  if (AProfileID = '') or (AProfileID = 'unknown') then
  begin
    if (FLastUnknownTick > 0) and (ANowTick - FLastUnknownTick < QWord(FUnknownCooldownMs)) then
      Exit(False);
    Exit(True);
  end;

  Idx := FProfileCooldowns.IndexOf(AProfileID);
  if Idx >= 0 then
  begin
    LastTick := QWord(PtrUInt(FProfileCooldowns.Objects[Idx]));
    if (LastTick > 0) and (ANowTick - LastTick < QWord(FRecognitionCooldownMs)) then
      Exit(False);
  end;

  Result := True;
end;

procedure TAIFaceRecognition.RecordRecognizedProfile(const AProfileID: string; ANowTick: QWord);
var
  Idx: Integer;
begin
  if (AProfileID = '') or (AProfileID = 'unknown') then
  begin
    FLastUnknownTick := ANowTick;
    Exit;
  end;

  Idx := FProfileCooldowns.IndexOf(AProfileID);
  if Idx >= 0 then
    FProfileCooldowns.Objects[Idx] := TObject(PtrUInt(ANowTick))
  else
    FProfileCooldowns.AddObject(AProfileID, TObject(PtrUInt(ANowTick)));
end;

procedure TAIFaceRecognition.SetFaceClasses(const AValue: TStringList);
begin
  if AValue <> nil then
    FFaceClasses.Assign(AValue);
end;

function TAIFaceRecognition.IsFaceObject(const AObject: TYoloObject): Boolean;
begin
  Result := IsYoloFaceObject(AObject, FFaceClasses);
end;

procedure TAIFaceRecognition.ResetTrackingState;
begin
  FIsTracking := False;
  FTrackedFaceRect := Rect(0, 0, 0, 0);
  if FFaceTracker <> nil then
    FFaceTracker.ClearTemplate;
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
  // Se o componente gerenciava um registry interno, libera-o com segurança uma única vez
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

function TAIFaceRecognition.ValidateRecognitionModel(out AMessage: string): Boolean;
begin
  Result := False;
  AMessage := '';

  if FYolo = nil then
  begin
    AMessage := 'Componente TYOLO nao associado ao TAIFaceRecognition.';
    Exit;
  end;

  if Trim(FYolo.ModelPath) = '' then
  begin
    AMessage := 'ModelPath nao foi informado no componente TYOLO.';
    Exit;
  end;

  if (Pos('/', FYolo.ModelPath) > 0) or (Pos('\', FYolo.ModelPath) > 0) or (ExtractFileExt(FYolo.ModelPath) <> '') then
  begin
    if not FileExists(FYolo.ModelPath) then
    begin
      AMessage := 'Arquivo de modelo nao encontrado no caminho especificado: ' + FYolo.ModelPath;
      Exit;
    end;
  end;

  if (FYolo.KeyPointMapping = nil) or (FYolo.KeyPointMapping.LeftEyeIndex < 0) or
     (FYolo.KeyPointMapping.RightEyeIndex < 0) or (FYolo.KeyPointMapping.NoseIndex < 0) then
  begin
    AMessage := 'Mapeamento de keypoints faciais incompleto no TYOLO. O modelo precisa fornecer keypoints/landmarks.';
    Exit;
  end;

  AMessage := 'Modelo e mapeamento configurados corretamente.';
  Result := True;
end;

function TAIFaceRecognition.SelfTestRecognitionModel(const ATestImage: string; out AMessage: string): Boolean;
var
  Objects: TYoloObjectArray;
  DescData: TAIFaceDescriptorData;
  Score, Dist: Double;
  FaceIdx, i: Integer;
begin
  Result := False;
  AMessage := '';

  // 1. Valida configuracao basica de modelo e mapeamento
  if not ValidateRecognitionModel(AMessage) then
    Exit;

  // 2. Valida presenca da imagem de teste
  if not FileExists(ATestImage) then
  begin
    AMessage := 'Imagem de teste para auto-diagnostico nao encontrada: ' + ATestImage;
    Exit;
  end;

  // 3. Executa inferencia real com o TYOLO
  if not FYolo.DetectObjects(ATestImage, Objects) then
  begin
    AMessage := 'Falha na execucao do TYOLO: ' + FYolo.LastError;
    Exit;
  end;

  // 4. Procura por face valida
  FaceIdx := -1;
  for i := 0 to High(Objects) do
  begin
    if IsFaceObject(Objects[i]) then
    begin
      FaceIdx := i;
      Break;
    end;
  end;

  if FaceIdx < 0 then
  begin
    AMessage := Format('Inferencia executada com sucesso, mas nenhuma face foi detectada (objetos retornados: %d).', [Length(Objects)]);
    Exit;
  end;

  // 5. Verifica quantidade de keypoints retornados pelo modelo
  if Length(Objects[FaceIdx].KeyPoints) < 5 then
  begin
    AMessage := Format('Modelo detecta face, mas retornou apenas %d keypoints. Nao serve para identificacao por descritor geometrico (necessario >= 5).',
      [Length(Objects[FaceIdx].KeyPoints)]);
    Exit;
  end;

  // 6. Constroi descritor geometrico
  if not FDescriptorBuilder.BuildDescriptor(Objects[FaceIdx], FYolo.KeyPointMapping, DescData) then
  begin
    AMessage := 'Falha ao construir descritor facial: ' + DescData.ErrorMessage;
    Exit;
  end;

  // 7. Auto-teste de matching (consigo mesmo)
  if not FMatcher.CompareVectors(DescData.Values, DescData.Values, Score, Dist) or (Score < 0.95) then
  begin
    AMessage := 'Falha no teste de autoconsistencia do matcher.';
    Exit;
  end;

  AMessage := Format('Auto-teste bem-sucedido: Modelo "%s" funcional. Face detectada com %d landmarks, confianca %.2f%%, descritor valido (score auto-match=%.4f).',
    [ExtractFileName(FYolo.ModelPath), Length(Objects[FaceIdx].KeyPoints), Objects[FaceIdx].Confidence * 100.0, Score]);
  Result := True;
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
  NowTick: QWord;
begin
  Result := False;
  SetLength(AResults, 0);
  FLastError := '';
  StartTime := GetTickCount64;
  FCancelRequested := False;

  if not FileExists(AImageFile) then
  begin
    FLastError := 'Arquivo de imagem não encontrado: ' + AImageFile;
    Exit(False);
  end;

  UseYolo := False;
  if (FDetectorMode = frmYOLO) or (FDetectorMode = frmAuto) then
  begin
    if FYolo <> nil then
      UseYolo := True
    else if FDetectorMode = frmYOLO then
    begin
      FLastError := 'Componente TYOLO não foi configurado.';
      Exit(False);
    end;
  end;

  if UseYolo then
  begin
    Inc(FYoloInferenceCount);
    LogDebug(Format('Iniciando inferência YOLO no arquivo "%s" (Modelo: %s)', [AImageFile, FYolo.ModelPath]));

    // Diferencia falha técnica de inferência (Tarefa 7)
    if not FYolo.DetectObjects(AImageFile, Objects) then
    begin
      FLastError := 'Falha na detecção YOLO: ' + FYolo.LastError;
      Exit(False);
    end;

    InfTime := GetTickCount64 - StartTime;
    FLastInferenceMs := InfTime;
    FLastFaceCount := Length(Objects);
    LogDebug(Format('Inferência YOLO concluída em %d ms. Objetos detectados: %d', [InfTime, Length(Objects)]));

    ResCount := 0;
    SetLength(AResults, Length(Objects));

    for i := 0 to High(Objects) do
    begin
      // Tarefa 1: Processar somente classes faciais ('face', etc.). Ignora 'person', 'chair', etc.
      if not IsFaceObject(Objects[i]) then
      begin
        LogDebug(Format('Objeto %d ignorado (classe "%s" não pertence a FaceClasses).', [i, Objects[i].ClassName]));
        Continue;
      end;

      FaceRect := Rect(Objects[i].X1, Objects[i].Y1, Objects[i].X2, Objects[i].Y2);
      FLastState := frsDetected;
      FLastFaceSeenTick := GetTickCount64;

      if Assigned(FOnFaceDetected) then
        FOnFaceDetected(Self, FaceRect, Objects[i].Confidence);

      // Gera descritor facial geométrico
      if FDescriptorBuilder.BuildDescriptor(Objects[i], FYolo.KeyPointMapping, DescData) then
      begin
        StartTime := GetTickCount64;
        FMatcher.MatchProfiles(DescData, GetProfilesArray, MatchRes);
        MatchTime := GetTickCount64 - StartTime;
        FLastMatchMs := MatchTime;

        LogDebug(Format('Matching face %d: Score=%.3f, Dist=%.3f, Status=%d, Perfil=%s (Tempo=%d ms)',
          [i, MatchRes.Score, MatchRes.Distance, Ord(MatchRes.Status), MatchRes.ProfileName, MatchTime]));

        AResults[ResCount] := MatchRes;
        Inc(ResCount);

        NowTick := GetTickCount64;

        case MatchRes.Status of
          fmsMatched:
          begin
            // Confirmação temporal de identidade (Tarefas 19, 20, 21)
            if (NowTick - FLastCandidateTick <= FConfirmationWindowMs) and (MatchRes.ProfileID = FCurrentCandidateID) then
              Inc(FConfirmationCount)
            else
            begin
              FCurrentCandidateID := MatchRes.ProfileID;
              FConfirmationCount := 1;
            end;
            FLastCandidateTick := NowTick;

            if FConfirmationCount >= FRequiredConfirmations then
            begin
              FLastState := frsRecognized;
              FLastConfirmedProfileID := MatchRes.ProfileID;
              FLastConfirmedScore := MatchRes.Score;

              // Cooldown por ProfileID (permite reconhecimento imediato de outra pessoa)
              if CanRecognizeProfile(MatchRes.ProfileID, NowTick) then
              begin
                RecordRecognizedProfile(MatchRes.ProfileID, NowTick);
                if Assigned(FOnFaceRecognized) then
                  FOnFaceRecognized(Self, MatchRes);
              end;
            end;
          end;

          fmsAmbiguous:
          begin
            FConfirmationCount := 0;
            FCurrentCandidateID := '';
            if Assigned(FOnFaceAmbiguous) then
              FOnFaceAmbiguous(Self, MatchRes);
          end;

          fmsUnknown:
          begin
            FConfirmationCount := 0;
            FCurrentCandidateID := '';
            // Identificador temporário para continuidade de tracking (Tarefa 28)
            if FTemporaryFaceID = '' then
            begin
              Inc(FTempIDCounter);
              FTemporaryFaceID := Format('unknown_%d', [FTempIDCounter]);
            end;
            MatchRes.ProfileID := FTemporaryFaceID;

            // Cooldown de OnFaceUnknown (Tarefa 27)
            if (NowTick - FLastUnknownTick >= FUnknownCooldownMs) or (FLastUnknownTick = 0) then
            begin
              FLastUnknownTick := NowTick;
              if Assigned(FOnFaceUnknown) then
                FOnFaceUnknown(Self, MatchRes);
            end;
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

    // Tarefa 6: Se YOLO executou mas nenhuma face foi encontrada
    if ResCount = 0 then
    begin
      FLastState := frsIdle;
      FTemporaryFaceID := '';
      FLastRecognitionStatus := 'Nenhuma face encontrada';
    end
    else
      FLastRecognitionStatus := Format('OK: %d face(s) identificada(s)', [ResCount]);

    Result := True;
  end
  else if (FDetectorMode = frmOpenCVFallback) or ((FDetectorMode = frmAuto) and (FFaceDetection <> nil)) then
  begin
    LogDebug('Usando fallback Haar Cascade (OpenCV)...');
    if FFaceDetection = nil then
    begin
      FLastError := 'Componente TFaceDetection não foi configurado para fallback.';
      Exit(False);
    end;

    if not FFaceDetection.DetectFaces(AImageFile, OpenCVFaces) then
    begin
      FLastError := 'Falha na detecção Haar Cascade: ' + FFaceDetection.LastError;
      Exit(False);
    end;

    SetLength(AResults, Length(OpenCVFaces));
    for i := 0 to High(OpenCVFaces) do
    begin
      FaceRect := Rect(OpenCVFaces[i].X, OpenCVFaces[i].Y,
                       OpenCVFaces[i].X + OpenCVFaces[i].Width,
                       OpenCVFaces[i].Y + OpenCVFaces[i].Height);
      FLastState := frsDetected;
      FLastFaceSeenTick := GetTickCount64;

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
      FLastState := frsIdle;

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

function TAIFaceRecognition.ProcessFrame(ABitmap: TBitmap; out AResults: TFaceMatchResultArray): Boolean;
var
  NowTick: QWord;
  NeedYolo: Boolean;
  TrackX, TrackY: Integer;
begin
  Result := False;
  SetLength(AResults, 0);
  FLastError := '';

  if ABitmap = nil then
  begin
    FLastError := 'Bitmap de frame não pode ser nulo.';
    Exit(False);
  end;

  NowTick := GetTickCount64;
  NeedYolo := True;

  // Integração real com TAIFaceTracker (Tarefas 14, 15, 16, 17)
  if FEnableTracking and (FFaceTracker <> nil) and FIsTracking then
  begin
    // Se o intervalo de renovação do YOLO ainda não expirou, tenta rastrear nativamente
    if (NowTick - FLastYoloTick < FYoloRefreshIntervalMs) then
    begin
      TrackX := FTrackedFaceRect.Left;
      TrackY := FTrackedFaceRect.Top;

      if FFaceTracker.TrackInBitmap(ABitmap, TrackX, TrackY) then
      begin
        // Frame rastreado com sucesso nativamente sem executar YOLO
        Inc(FTrackedFrameCount);
        FTrackedFaceRect := Rect(TrackX, TrackY,
          TrackX + (FTrackedFaceRect.Right - FTrackedFaceRect.Left),
          TrackY + (FTrackedFaceRect.Bottom - FTrackedFaceRect.Top));

        FLastState := frsTracked;
        FLastFaceSeenTick := NowTick;
        NeedYolo := False;

        if Assigned(FOnFaceDetected) then
          FOnFaceDetected(Self, FTrackedFaceRect, 1.0);

        // Se houver identidade confirmada, mantém o estado de reconhecimento
        if FLastConfirmedProfileID <> '' then
          FLastState := frsRecognized;

        Result := True;
        Exit;
      end
      else
      begin
        // Tracking falhou/perdeu template -> força reexecução do YOLO
        LogDebug('Tracking perdeu a face. Reinferindo com YOLO...');
        ResetTrackingState;
        NeedYolo := True;
      end;
    end;
  end;

  if NeedYolo then
  begin
    FLastYoloTick := NowTick;
    Result := RecognizeBitmap(ABitmap, AResults);

    if Result and (Length(AResults) > 0) and FEnableTracking and (FFaceTracker <> nil) then
    begin
      // Inicializa template do tracker com a primeira face detectada (Tarefa 14)
      if (AResults[0].Status in [fmsMatched, fmsUnknown, fmsAmbiguous]) then
      begin
        FTrackedFaceRect := Rect(FFaceTracker.LastX, FFaceTracker.LastY,
          FFaceTracker.LastX + FFaceTracker.LastWidth,
          FFaceTracker.LastY + FFaceTracker.LastHeight);

        if (FTrackedFaceRect.Right > FTrackedFaceRect.Left) and
           (FTrackedFaceRect.Bottom > FTrackedFaceRect.Top) then
        begin
          FFaceTracker.SetTemplateFromBitmap(ABitmap,
            FTrackedFaceRect.Left, FTrackedFaceRect.Top,
            FTrackedFaceRect.Right - FTrackedFaceRect.Left,
            FTrackedFaceRect.Bottom - FTrackedFaceRect.Top);
          FIsTracking := True;
        end;
      end;
    end;
  end;

  // Verificação de timeout de perda de face (Tarefas 22 e 23)
  if (Length(AResults) = 0) and (not FIsTracking) then
  begin
    if (FLastFaceSeenTick > 0) and (NowTick - FLastFaceSeenTick >= FFaceLostTimeoutMs) then
    begin
      FLastState := frsLost;
      FLastFaceSeenTick := 0;
      FConfirmationCount := 0;
      FCurrentCandidateID := '';
      FLastConfirmedProfileID := '';
      FTemporaryFaceID := '';
      if FProfileCooldowns <> nil then
        FProfileCooldowns.Clear; // Permite novo reconhecimento quando a pessoa retornar
      ResetTrackingState;

      if Assigned(FOnFaceLost) then
        FOnFaceLost(Self);
    end;
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

  Result := FRegistry.AddSampleFromFile(AProfileID, AImageFile, FYolo, FDescriptorBuilder, AError, FFaceClasses);
end;

end.
