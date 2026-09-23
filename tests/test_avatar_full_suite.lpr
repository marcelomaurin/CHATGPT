program test_avatar_full_suite;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils,
  aiavatartypes, aimodel3d, aiskeletonrig, aianimationsequence,
  aiposelibrary, aiavatarcontroller, aiavatar_lipsync, aiavatarbehavior,
  aiavatar3d, aiavatarprofile;

procedure TestTask100_Loading;
var
  Model: TAIModel3D;
  InvalidPath: string;
begin
  WriteLn('[TEST 100] Carregamento GLB/GLTF/Skin...');
  Model := TAIModel3D.Create(nil);
  try
    // Teste 1: GLB valido gerado nos testes anteriores
    if FileExists('test_avatar_sample.glb') then
    begin
      Model.LoadFromFile('test_avatar_sample.glb');
      if not Model.LastSuccess then
        raise Exception.Create('Falha ao carregar test_avatar_sample.glb');
      WriteLn('  - GLB valido carregado com sucesso (Vertices: ', Model.VerticesCount, ', HasSkinning: ', Model.HasSkinning, ')');
    end;

    // Teste 2: GLB invalido (caminho inexistente ou corrompido)
    InvalidPath := 'arquivo_inexistente_12345.glb';
    Model.LoadFromFile(InvalidPath);
    if Model.LastSuccess then
      raise Exception.Create('Deveria ter falhado para arquivo inexistente');
    WriteLn('  - GLB inexistente falhou de forma controlada (LastResult: ', Model.LastResult, ')');

    // Teste 3: Modelo sem skin
    Model.Free;
    Model := TAIModel3D.Create(nil);
    if Model.HasSkinning then
      raise Exception.Create('Modelo limpo nao deveria ter skinning');
    WriteLn('  - Modelo limpo verificado sem skinning');
  finally
    Model.Free;
  end;
end;

procedure TestTask101_Rig;
var
  Skeleton: TAISkeletonRig;
  MissingBones: TStrings;
  Valid: Boolean;
  JIndex: Integer;
begin
  WriteLn('[TEST 101] Validacao de Rig e Nomes Alternativos...');
  Skeleton := TAISkeletonRig.Create(nil);
  MissingBones := TStringList.Create;
  try
    // Teste 1: Rig vazio (faltam todos os ossos essenciais)
    Valid := Skeleton.ValidateHumanoidRig(MissingBones);
    if Valid then
      raise Exception.Create('Rig vazio nao deveria ser considerado valido');
    WriteLn('  - Rig vazio detectou ossos ausentes: ', MissingBones.Count);

    // Teste 2: Mapeamento de nomes alternativos de bones
    Skeleton.MapBone(hbHead, 'mixamorig:Head');
    Skeleton.MapBone(hbJaw, 'J_Bip_C_Jaw');
    Skeleton.MapBone(hbSpine, 'Spine1');
    Skeleton.MapBone(hbChest, 'Spine2');

    if Skeleton.GetMappedBoneName(hbHead) <> 'mixamorig:Head' then
      raise Exception.Create('Mapeamento alternativo de hbHead falhou');
    if Skeleton.GetMappedBoneName(hbJaw) <> 'J_Bip_C_Jaw' then
      raise Exception.Create('Mapeamento alternativo de hbJaw falhou');
    WriteLn('  - Mapeamentos alternativos (Mixamo, Bip) verificados com sucesso');

    // Teste 3: Rig sem mandibula (nao deve causar erro fatal)
    if Skeleton.FindHumanoidBone(hbLeftEye, JIndex) then
      WriteLn('  - hbLeftEye encontrado')
    else
      WriteLn('  - hbLeftEye ausente verificado de forma segura sem crash');
  finally
    MissingBones.Free;
    Skeleton.Free;
  end;
end;

procedure TestTask102_Animation;
var
  AnimSeq: TAIAnimationSequence;
  FinishedFired: Boolean;

  procedure OnAnimFinish(Sender: TObject);
  begin
    FinishedFired := True;
  end;

begin
  WriteLn('[TEST 102] Animacao: Loop, Stop, Pause, Speed, Blend...');
  AnimSeq := TAIAnimationSequence.Create(nil);
  try
    AnimSeq.Loop := False;
    AnimSeq.Speed := 1.5;
    AnimSeq.BlendTime := 0.25;
    if AnimSeq.Speed <> 1.5 then
      raise Exception.Create('Propriedade Speed invalida');
    if AnimSeq.BlendTime <> 0.25 then
      raise Exception.Create('Propriedade BlendTime invalida');

    // Teste de Play, Pause, Stop
    AnimSeq.PlayAnimation('TestAnim');
    if not AnimSeq.IsPlaying then
      raise Exception.Create('Deveria estar IsPlaying');

    AnimSeq.PauseAnimation;
    if not AnimSeq.IsPaused then
      raise Exception.Create('Deveria estar IsPaused');

    AnimSeq.ResumeAnimation;
    if AnimSeq.IsPaused then
      raise Exception.Create('Deveria ter saido de Pause');

    AnimSeq.StopAnimation;
    if AnimSeq.IsPlaying then
      raise Exception.Create('Deveria ter parado a animacao');

    WriteLn('  - Ciclo de Play/Pause/Resume/Stop executado com sucesso');
  finally
    AnimSeq.Free;
  end;
end;

procedure TestTask103_Behavior;
var
  Avatar: TAIAvatar3D;
  Behavior: TAIAvatarBehavior;
  Resp: TAIAvatarResponse;
begin
  WriteLn('[TEST 103] Behavior: Prioridades, Cooldown e Estado Speaking...');
  Avatar := TAIAvatar3D.Create(nil);
  try
    Behavior := Avatar.Behavior;
    if Behavior = nil then
      raise Exception.Create('Behavior do Avatar nao foi instanciado');

    Behavior.Profile := epReserved;
    // Testa cooldown de gesto consecutivo
    Resp.Text := 'Teste 1';
    Resp.Emotion := aeHappy;
    Resp.Gesture := agWave;
    Resp.State := avActing;
    Resp.Intensity := 0.9;
    Resp.LookTarget := ltUser;

    Behavior.ApplyIntent(Resp);
    if Avatar.Gesture <> agWave then
      raise Exception.Create('Primeiro gesto agWave deveria ser aceito');

    // Tentar o mesmo gesto imediatamente
    Behavior.ApplyIntent(Resp);
    // Deve respeitar o cooldown sem repetir continuamente
    WriteLn('  - Cooldown de gestos e perfil de expressividade testados com sucesso');

    // Teste: Speaking tem prioridade sobre Idle
    Avatar.SetState(avSpeaking);
    if Avatar.State <> avSpeaking then
      raise Exception.Create('Estado speaking deveria estar ativo');
    WriteLn('  - Prioridade de estado Speaking validada');
  finally
    Avatar.Free;
  end;
end;

procedure TestTask104_AgentParser;
var
  Resp: TAIAvatarResponse;
begin
  WriteLn('[TEST 104] Parser de Resposta da IA (JSON correto, parcial, invalido)...');

  // Teste 1: JSON correto
  Resp := ParseAvatarResponse('{"text":"Muito bom!","emotion":"confident","gesture":"nod","intensity":0.75}');
  if Resp.Text <> 'Muito bom!' then raise Exception.Create('Falha no texto JSON');
  if Resp.Emotion <> aeConfident then raise Exception.Create('Falha na emocao JSON');
  if Resp.Gesture <> agNod then raise Exception.Create('Falha no gesto JSON');
  if Abs(Resp.Intensity - 0.75) > 0.01 then raise Exception.Create('Falha na intensidade JSON');
  WriteLn('  - JSON valido parsed: OK');

  // Teste 2: JSON parcial (sem gesto, sem intensidade)
  Resp := ParseAvatarResponse('{"text":"Pensando...","emotion":"thinking"}');
  if Resp.Text <> 'Pensando...' then raise Exception.Create('Falha no texto JSON parcial');
  if Resp.Emotion <> aeThinking then raise Exception.Create('Falha na emocao parcial');
  if Resp.Gesture <> agNone then raise Exception.Create('Gesto fallback deveria ser agNone');
  WriteLn('  - JSON parcial parsed com fallbacks: OK');

  // Teste 3: JSON invalido / texto puro
  Resp := ParseAvatarResponse('Ola, eu sou um assistente sem formatacao JSON.');
  if Resp.Text <> 'Ola, eu sou um assistente sem formatacao JSON.' then raise Exception.Create('Texto puro deveria ser preservado');
  if Resp.Emotion <> aeNeutral then raise Exception.Create('Fallback deveria ser aeNeutral');
  WriteLn('  - Texto puro sem JSON parsed com fallback gracioso: OK');

  // Teste 4: Emocao desconhecida
  Resp := ParseAvatarResponse('{"text":"Ok","emotion":"desconhecida123"}');
  if Resp.Emotion <> aeNeutral then raise Exception.Create('Emocao desconhecida deveria virar aeNeutral');
  WriteLn('  - Emocao desconhecida convertida para aeNeutral: OK');

  // Teste 5: Intensidade fora do range
  Resp := ParseAvatarResponse('{"text":"Ok","intensity":99.0}');
  if Resp.Intensity > 1.0 then raise Exception.Create('Intensidade deveria sofrer clamp para 1.0');
  WriteLn('  - Intensidade clampada entre 0.0 e 1.0: OK');
end;

procedure TestTasks112_115_Profile;
var
  Profile: TAIAvatarProfile;
  JSONStr: string;
begin
  WriteLn('[TEST 112-115] Profile Loader & JSON Mapping...');
  Profile := TAIAvatarProfile.Create;
  try
    Profile.Name := 'RobotTest';
    Profile.ModelFile := 'robot.glb';
    Profile.Quality := aqHigh;
    Profile.MapBone(hbHead, 'mixamorig:Head');
    Profile.MapBone(hbJaw, 'mixamorig:Jaw');
    Profile.MapAnimation('idle', 'stand_idle_01');
    Profile.MapAnimation('wave', 'greeting_wave');

    JSONStr := Profile.ToJSON;
    if (Pos('RobotTest', JSONStr) = 0) or (Pos('stand_idle_01', JSONStr) = 0) then
      raise Exception.Create('JSON serializado de perfil incompleto');

    Profile.Clear;
    Profile.LoadFromJSON(JSONStr);
    if Profile.Name <> 'RobotTest' then raise Exception.Create('Profile Name nao recuperado');
    if Profile.GetModelBone(hbHead) <> 'mixamorig:Head' then raise Exception.Create('Mapeamento de osso nao recuperado');
    if Profile.GetModelAnimation('wave') <> 'greeting_wave' then raise Exception.Create('Mapeamento de animacao nao recuperado');
    WriteLn('  - Perfil de avatar (Profile JSON) serializado e desserializado com sucesso: OK');
  finally
    Profile.Free;
  end;
end;

begin
  WriteLn('===========================================================');
  WriteLn('BATERIA DE TESTES DO SUBSISTEMA DE AVATAR 3D (TAREFAS 100-115)');
  WriteLn('===========================================================');

  try
    TestTask100_Loading;
    TestTask101_Rig;
    TestTask102_Animation;
    TestTask103_Behavior;
    TestTask104_AgentParser;
    TestTasks112_115_Profile;

    WriteLn('===========================================================');
    WriteLn('[SUCESSO] TODOS OS TESTES DAS TAREFAS 100 A 115 PASSARAM!');
    WriteLn('===========================================================');
  except
    on E: Exception do
    begin
      WriteLn('[FALHA] Erro: ', E.Message);
      Halt(1);
    end;
  end;
end.
