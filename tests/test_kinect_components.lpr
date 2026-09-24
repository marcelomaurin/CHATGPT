program test_kinect_components;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, fpjson, jsonparser,
  aibase, aikinect_types, aikinectsensor, aikinectcolor,
  aikinectdepth, aikinectskeleton, aikinectaudio, aikinectperception;


type
  TTestKinectSuite = class
  public
    EnteredCount: Integer;
    LastGestureReceived: TAIKinectGesture;
    LastTrackingID: Integer;
    LastConfidence: Single;
    LastSemanticEventCount: Integer;

    procedure HandlePersonEntered(Sender: TObject; const APerson: TAIKinectPersonState);
    procedure HandleGesture(Sender: TObject; AGesture: TAIKinectGesture; ATrackingID: Integer; AConfidence: Single);
    procedure HandleSemanticEvent(Sender: TObject; const AEvent: TAIKinectSemanticEvent);
    procedure Run;
  end;

procedure TTestKinectSuite.HandlePersonEntered(Sender: TObject; const APerson: TAIKinectPersonState);
begin
  Inc(EnteredCount);
  WriteLn('  [EVENTO] Pessoa entrou na zona de interacao: ID=', APerson.TrackingID,
          ' Distancia=', Format('%.2fm', [APerson.DistanceMeters]),
          ' Posicao=', APerson.PositionName);
end;

procedure TTestKinectSuite.HandleGesture(Sender: TObject; AGesture: TAIKinectGesture;
  ATrackingID: Integer; AConfidence: Single);
begin
  LastGestureReceived := AGesture;
  LastTrackingID := ATrackingID;
  LastConfidence := AConfidence;
  WriteLn('  [EVENTO] Gesto detectado: ', AGesture, ' (ID=', ATrackingID,
          ' Conf=', Format('%.2f', [AConfidence]), ')');
end;

procedure TTestKinectSuite.HandleSemanticEvent(Sender: TObject; const AEvent: TAIKinectSemanticEvent);
begin
  Inc(LastSemanticEventCount);
  WriteLn('  [SEMANTICO] Evento=', AEvent.EventTypeName, ' Gesto=', AEvent.GestureName,
          ' Dist=', Format('%.2f', [AEvent.DistanceMeters]), ' Pos=', AEvent.PositionName);
end;

function CreateBody(ATrackingID: Integer; AX, AY, AZ: Single): TAIKinectBody;
var
  JT: TAIKinectJointType;
begin
  Result.TrackingId := ATrackingID;
  Result.Tracked := True;
  for JT := Low(TAIKinectJointType) to High(TAIKinectJointType) do
  begin
    Result.Joints[JT].JointType := JT;
    Result.Joints[JT].State := ktTracked;
    Result.Joints[JT].X := AX;
    Result.Joints[JT].Y := AY;
    Result.Joints[JT].Z := AZ;
    Result.Joints[JT].ScreenX := 320;
    Result.Joints[JT].ScreenY := 240;
  end;
  // Posicionamento anatomico basico em metros
  Result.Joints[kjHead].Y := AY + 0.65;
  Result.Joints[kjShoulderCenter].Y := AY + 0.45;
  Result.Joints[kjSpine].Y := AY + 0.20;
  Result.Joints[kjHipCenter].Y := AY;

  Result.Joints[kjShoulderLeft].X := AX - 0.20;
  Result.Joints[kjShoulderLeft].Y := AY + 0.45;
  Result.Joints[kjElbowLeft].X := AX - 0.25;
  Result.Joints[kjElbowLeft].Y := AY + 0.20;
  Result.Joints[kjHandLeft].X := AX - 0.25;
  Result.Joints[kjHandLeft].Y := AY - 0.05;

  Result.Joints[kjShoulderRight].X := AX + 0.20;
  Result.Joints[kjShoulderRight].Y := AY + 0.45;
  Result.Joints[kjElbowRight].X := AX + 0.25;
  Result.Joints[kjElbowRight].Y := AY + 0.20;
  Result.Joints[kjHandRight].X := AX + 0.25;
  Result.Joints[kjHandRight].Y := AY - 0.05;
end;

procedure TTestKinectSuite.Run;
var
  Sensor: TAIKinectSensor;
  Color: TAIKinectColorStream;
  Depth: TAIKinectDepthStream;
  Skeleton: TAIKinectSkeleton;
  Audio: TAIKinectAudio;
  Perception: TAIKinectPerception;
  Bodies: TAIKinectBodies;
  DevList: TStringList;
  I: Integer;
  JSONOut: string;
  JSONParser: TJSONParser;
  JSONData: TJSONData;
begin
  WriteLn('======================================================================');
  WriteLn('TESTE AUTOMATIZADO: FAMILIA AIKINECT E TAIKINECTPERCEPTION');
  WriteLn('======================================================================');

  EnteredCount := 0;
  LastGestureReceived := kgNone;
  LastSemanticEventCount := 0;

  { 1. Teste de instanciacao e seguranca sem hardware }
  WriteLn('[1] Instanciando componentes e testando seguranca...');
  Sensor := TAIKinectSensor.Create(nil);
  Color := TAIKinectColorStream.Create(nil);
  Depth := TAIKinectDepthStream.Create(nil);
  Skeleton := TAIKinectSkeleton.Create(nil);
  Audio := TAIKinectAudio.Create(nil);
  Perception := TAIKinectPerception.Create(nil);
  try
    Color.Sensor := Sensor;
    Depth.Sensor := Sensor;
    Skeleton.Sensor := Sensor;
    Audio.Sensor := Sensor;

    Perception.Sensor := Sensor;
    Perception.Skeleton := Skeleton;
    Perception.Depth := Depth;
    Perception.Color := Color;

    Perception.OnPersonEntered := @HandlePersonEntered;
    Perception.OnGesture := @HandleGesture;
    Perception.OnSemanticEvent := @HandleSemanticEvent;

    WriteLn('  - Backend padrao detectado: ', Sensor.BackendName);
    WriteLn('  - Suporta Color: ', Sensor.SupportsColor);
    WriteLn('  - Suporta Depth: ', Sensor.SupportsDepth);
    WriteLn('  - Suporta Skeleton: ', Sensor.SupportsSkeleton);
    WriteLn('  - Suporta Audio: ', Sensor.SupportsAudio);
    WriteLn('  - Suporta Tilt: ', Sensor.SupportsTilt);

    DevList := Sensor.ListDevices;
    try
      WriteLn('  - Dispositivos fisicos encontrados: ', DevList.Count);
      for I := 0 to DevList.Count - 1 do
        WriteLn('    * ', DevList[I]);
    finally
      DevList.Free;
    end;

    // Chamadas sem hardware nao podem gerar AV
    if Sensor.IsConnected then
      WriteLn('  - Kinect fisico conectado!')
    else
      WriteLn('  - Sensor offline (comportamento correto sem hardware fisico).');

    { 2. Validacao do TAIKinectPerception com Poses Simuladas }
    WriteLn('');
    WriteLn('[2] Testando simulador e maquina de estados de percepcao...');

    // Cenario A: Pessoa entra a 1.8 metros (neutro, maos baixas)
    WriteLn('  --> Cenario A: Pessoa entrando a 1.8m (postura neutra)');
    SetLength(Bodies, 1);
    Bodies[0] := CreateBody(101, 0.0, 0.0, 1.8);

    // Envia 3 frames para estabilizacao de presenca
    for I := 1 to 3 do
      Perception.FeedSimulatedSkeleton(Bodies);

    if not Perception.PersonPresent then
      raise Exception.Create('Falha: Pessoa deveria ter sido reconhecida como presente!');
    if Perception.ActiveTrackingID <> 101 then
      raise Exception.Create('Falha: ActiveTrackingID incorreto!');
    if Perception.Position <> 'center' then
      raise Exception.Create('Falha: Posicao lateral deveria ser center!');

    WriteLn('  -> OK: Pessoa presente, TrackingID=', Perception.ActiveTrackingID,
            ' Dist=', Format('%.2fm', [Perception.DistanceMeters]),
            ' Pos=', Perception.Position);

    // Cenario B: Mao direita levantada
    WriteLn('');
    WriteLn('  --> Cenario B: Levantando mao direita (HandRight.Y > ShoulderRight.Y)');
    Bodies[0].Joints[kjHandRight].Y := Bodies[0].Joints[kjShoulderRight].Y + 0.30;
    Perception.FeedSimulatedSkeleton(Bodies);

    if Perception.LastGesture <> kgRaiseRightHand then
      raise Exception.Create('Falha: Gesto esperado kgRaiseRightHand, obtido: ' + Perception.GestureToString(Perception.LastGesture));
    WriteLn('  -> OK: Gesto detectado com sucesso: ', Perception.GestureToString(Perception.LastGesture));

    // Cenario C: Mao esquerda levantada
    WriteLn('');
    WriteLn('  --> Cenario C: Levantando mao esquerda (HandLeft.Y > ShoulderLeft.Y)');
    Bodies[0].Joints[kjHandRight].Y := Bodies[0].Joints[kjHipCenter].Y; // baixa direita
    Bodies[0].Joints[kjHandLeft].Y := Bodies[0].Joints[kjShoulderLeft].Y + 0.30; // sobe esquerda
    Perception.FeedSimulatedSkeleton(Bodies);

    if Perception.LastGesture <> kgRaiseLeftHand then
      raise Exception.Create('Falha: Gesto esperado kgRaiseLeftHand, obtido: ' + Perception.GestureToString(Perception.LastGesture));
    WriteLn('  -> OK: Gesto detectado com sucesso: ', Perception.GestureToString(Perception.LastGesture));

    // Cenario D: Ambas as maos levantadas
    WriteLn('');
    WriteLn('  --> Cenario D: Ambas as maos levantadas');
    Bodies[0].Joints[kjHandRight].Y := Bodies[0].Joints[kjShoulderRight].Y + 0.30;
    Bodies[0].Joints[kjHandLeft].Y := Bodies[0].Joints[kjShoulderLeft].Y + 0.30;
    Perception.FeedSimulatedSkeleton(Bodies);

    if Perception.LastGesture <> kgRaiseBothHands then
      raise Exception.Create('Falha: Gesto esperado kgRaiseBothHands, obtido: ' + Perception.GestureToString(Perception.LastGesture));
    WriteLn('  -> OK: Gesto detectado com sucesso: ', Perception.GestureToString(Perception.LastGesture));

    // Cenario E: Apontar para a direita
    WriteLn('');
    WriteLn('  --> Cenario E: Apontando para a direita (braco direito esticado para o lado)');
    Bodies[0].Joints[kjHandLeft].Y := Bodies[0].Joints[kjHipCenter].Y; // baixa esquerda
    Bodies[0].Joints[kjShoulderRight].X := 0.20;
    Bodies[0].Joints[kjShoulderRight].Y := 0.45;
    Bodies[0].Joints[kjElbowRight].X := 0.45;
    Bodies[0].Joints[kjElbowRight].Y := 0.45;
    Bodies[0].Joints[kjHandRight].X := 0.70; // X bem a direita
    Bodies[0].Joints[kjHandRight].Y := 0.45; // mesma altura do ombro
    Perception.FeedSimulatedSkeleton(Bodies);

    if Perception.LastGesture <> kgPointRight then
      raise Exception.Create('Falha: Gesto esperado kgPointRight, obtido: ' + Perception.GestureToString(Perception.LastGesture));
    WriteLn('  -> OK: Gesto detectado com sucesso: ', Perception.GestureToString(Perception.LastGesture));

    // Cenario F: Bracos abertos (Open Arms)
    WriteLn('');
    WriteLn('  --> Cenario F: Bracos abertos (Open Arms)');
    Bodies[0].Joints[kjHandLeft].X := -0.65;
    Bodies[0].Joints[kjHandLeft].Y := 0.45;
    Bodies[0].Joints[kjHandRight].X := 0.65;
    Bodies[0].Joints[kjHandRight].Y := 0.45;
    Perception.FeedSimulatedSkeleton(Bodies);

    if Perception.LastGesture <> kgOpenArms then
      raise Exception.Create('Falha: Gesto esperado kgOpenArms, obtido: ' + Perception.GestureToString(Perception.LastGesture));
    WriteLn('  -> OK: Gesto detectado com sucesso: ', Perception.GestureToString(Perception.LastGesture));

    // Cenario G: Validacao do JSON Semantico
    WriteLn('');
    WriteLn('[3] Validando geracao de JSON semantico para o Orchestrator / LLM...');
    JSONOut := Perception.ToSemanticJSON;
    WriteLn('  Payload JSON gerado:');
    WriteLn('  ', JSONOut);

    JSONParser := TJSONParser.Create(JSONOut);
    try
      JSONData := JSONParser.Parse;
      try
        if not (JSONData is TJSONObject) then
          raise Exception.Create('Falha: JSON semantico raiz nao e um objeto');
        if not TJSONObject(JSONData).Get('person_present', False) then
          raise Exception.Create('Falha: JSON semantico person_present nao e true');
        if TJSONObject(JSONData).Get('tracking_id', 0) <> 101 then
          raise Exception.Create('Falha: JSON semantico tracking_id nao e 101');
        if TJSONObject(JSONData).Get('gesture', '') <> 'open_arms' then
          raise Exception.Create('Falha: JSON semantico gesture nao e open_arms');
      finally
        JSONData.Free;
      end;
    finally
      JSONParser.Free;
    end;

    WriteLn('');
    WriteLn('======================================================================');
    WriteLn('TODOS OS TESTES DA FAMILIA AIKINECT PASSARAM COM 100% DE SUCESSO!');
    WriteLn('======================================================================');
  finally
    Perception.Free;
    Audio.Free;
    Skeleton.Free;
    Depth.Free;
    Color.Free;
    Sensor.Free;
  end;
end;

var
  Suite: TTestKinectSuite;
begin
  Suite := TTestKinectSuite.Create;
  try
    Suite.Run;
  finally
    Suite.Free;
  end;
end.
