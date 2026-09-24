program test_kinect_agent_adapter;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, fpjson, jsonparser,
  aikinect_types, aikinectperception, aikinectadapter,
  aiinteractioncontext, aiconversationorchestrator;

type
  TTestAgentAdapter = class
  public
    EnteredCalled: Boolean;
    LeftCalled: Boolean;
    ResolvedGesture: string;
    ResolvedTarget: string;

    procedure HandlePersonEntered(Sender: TObject; ATrackingID: Integer;
      ADistance: Single; const APosition: string);
    procedure HandlePersonLeft(Sender: TObject; ATrackingID: Integer);
    procedure HandleDeicticResolved(Sender: TObject; const AGesture, ATarget: string);
    procedure Run;
  end;

procedure TTestAgentAdapter.HandlePersonEntered(Sender: TObject; ATrackingID: Integer;
  ADistance: Single; const APosition: string);
begin
  EnteredCalled := True;
  WriteLn('  [TESTE EVENTO] Adapter.OnPersonEntered: ID=', ATrackingID, ' Dist=', Format('%.2f', [ADistance]), ' Pos=', APosition);
end;

procedure TTestAgentAdapter.HandlePersonLeft(Sender: TObject; ATrackingID: Integer);
begin
  LeftCalled := True;
  WriteLn('  [TESTE EVENTO] Adapter.OnPersonLeft: ID=', ATrackingID);
end;

procedure TTestAgentAdapter.HandleDeicticResolved(Sender: TObject; const AGesture, ATarget: string);
begin
  ResolvedGesture := AGesture;
  ResolvedTarget := ATarget;
  WriteLn('  [TESTE EVENTO] Adapter.OnDeicticTargetResolved: Gesto=', AGesture, ' Alvo=', ATarget);
end;

function MakeSimBody(ATrackingID: Integer; AX, AY, AZ: Single): TAIKinectBody;
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
  Result.Joints[kjHead].Y := AY + 0.65;
  Result.Joints[kjShoulderCenter].Y := AY + 0.45;
  Result.Joints[kjSpine].Y := AY + 0.20;
  Result.Joints[kjHipCenter].Y := AY;

  Result.Joints[kjShoulderLeft].X := AX - 0.20;
  Result.Joints[kjShoulderLeft].Y := AY + 0.45;
  Result.Joints[kjHandLeft].X := AX - 0.32;
  Result.Joints[kjHandLeft].Y := AY - 0.05;

  Result.Joints[kjShoulderRight].X := AX + 0.20;
  Result.Joints[kjShoulderRight].Y := AY + 0.45;
  Result.Joints[kjHandRight].X := AX + 0.32;
  Result.Joints[kjHandRight].Y := AY - 0.05;
end;

procedure TTestAgentAdapter.Run;
var
  Perception: TAIKinectPerception;
  Adapter: TAIKinectInteractionAdapter;
  Orchestrator: TAIConversationOrchestrator;
  Bodies: TAIKinectBodies;
  I: Integer;
  Prompt: string;
begin
  WriteLn('======================================================================');
  WriteLn('TESTE: INTEGRACAO TAIKINECTINTERACTIONADAPTER + ORCHESTRATOR');
  WriteLn('======================================================================');

  EnteredCalled := False;
  LeftCalled := False;
  ResolvedGesture := '';
  ResolvedTarget := '';

  Perception := TAIKinectPerception.Create(nil);
  Adapter := TAIKinectInteractionAdapter.Create(nil);
  Orchestrator := TAIConversationOrchestrator.Create(nil);
  try
    Adapter.Perception := Perception;
    Adapter.Orchestrator := Orchestrator;
    Adapter.TargetLeft := 'ECG';
    Adapter.TargetRight := 'Hemacias';
    Adapter.TargetCenter := 'Robotinics';
    Perception.ExitTimeoutMS := 50;

    Adapter.OnPersonEntered := @HandlePersonEntered;
    Adapter.OnPersonLeft := @HandlePersonLeft;
    Adapter.OnDeicticTargetResolved := @HandleDeicticResolved;

    WriteLn('[1] Simulando visitante entrando a 1.8m...');
    SetLength(Bodies, 1);
    Bodies[0] := MakeSimBody(202, 0.0, 0.0, 1.8);
    for I := 1 to 3 do
      Perception.FeedSimulatedSkeleton(Bodies);

    if not EnteredCalled then
      raise Exception.Create('Falha: Adapter.OnPersonEntered nao foi chamado!');
    if not Orchestrator.Context.PersonPresent then
      raise Exception.Create('Falha: Orchestrator.Context.PersonPresent nao e True!');
    if Orchestrator.Context.BodyTrackingID <> 202 then
      raise Exception.Create('Falha: TrackingID incorreto no Contexto!');

    WriteLn('  -> OK: Visitante detectado e registrado no Contexto de Interacao.');

    WriteLn('[2] Simulando visitante apontando para a direita (alvo: Hemacias)...');
    Bodies[0].Joints[kjElbowRight].X := 0.45;
    Bodies[0].Joints[kjElbowRight].Y := Bodies[0].Joints[kjShoulderRight].Y;
    Bodies[0].Joints[kjHandRight].X := 0.70;
    Bodies[0].Joints[kjHandRight].Y := Bodies[0].Joints[kjShoulderRight].Y;

    for I := 1 to 3 do
      Perception.FeedSimulatedSkeleton(Bodies);

    if ResolvedTarget <> 'Hemacias' then
      raise Exception.Create('Falha: Gesto de apontar nao resolveu alvo Hemacias!');
    if Orchestrator.Context.ObjectPointed <> 'Hemacias' then
      raise Exception.Create('Falha: ObjectPointed no Contexto nao e Hemacias!');

    WriteLn('  -> OK: Gesto de apontar resolveu alvo: ', ResolvedTarget);

    WriteLn('[3] Testando resolucao de referencia deitica no Prompt Enriquecido...');
    Prompt := Orchestrator.Context.BuildEnrichedPrompt('Como funciona esse projeto?');
    WriteLn('  Trecho do Prompt Enriquecido:');
    WriteLn('  --------------------------------------------------');
    WriteLn('  ', Copy(Prompt, 1, 350));
    WriteLn('  --------------------------------------------------');

    if Pos('Hemacias', Prompt) = 0 then
      raise Exception.Create('Falha: Prompt enriquecido nao resolveu deitico "esse" para Hemacias!');
    if Pos('Percepção Física: Interlocutor a', Prompt) = 0 then
      raise Exception.Create('Falha: Prompt enriquecido nao contem contexto perceptivo fisico!');

    WriteLn('  -> OK: Resolucao deitica e percepcao fisica validadas no Prompt do LLM!');

    WriteLn('[4] Simulando visitante saindo da zona...');
    SetLength(Bodies, 0);
    Sleep(70);
    Perception.FeedSimulatedSkeleton(Bodies);

    if not LeftCalled then
      raise Exception.Create('Falha: Adapter.OnPersonLeft nao foi chamado!');
    if Orchestrator.Context.PersonPresent then
      raise Exception.Create('Falha: Context.PersonPresent ainda esta True apos saida!');

    WriteLn('  -> OK: Saida do visitante processada e contexto resetado com sucesso.');

    WriteLn('');
    WriteLn('======================================================================');
    WriteLn('TODOS OS TESTES DO ADAPTADOR KINECT-AGENT PASSARAM COM SUCESSO!');
    WriteLn('======================================================================');
  finally
    Orchestrator.Free;
    Adapter.Free;
    Perception.Free;
  end;
end;

var
  Suite: TTestAgentAdapter;
begin
  Suite := TTestAgentAdapter.Create;
  try
    Suite.Run;
  finally
    Suite.Free;
  end;
end.
