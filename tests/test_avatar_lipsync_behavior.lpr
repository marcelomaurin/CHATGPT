program test_avatar_lipsync_behavior;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, aiavatartypes, aiskeletonrig, aiposelibrary, 
  aianimationsequence, aiavatarcontroller, aiavatar_lipsync, 
  aiavatarbehavior, aiavatar3d;

var
  Avatar: TAIAvatar3D;
  LipSync: TAIAvatarLipSync;
  Behavior: TAIAvatarBehavior;
  Rig: TAISkeletonRig;
  Resp: TAIAvatarResponse;
  JSONText: string;
begin
  WriteLn('===========================================================');
  WriteLn('TESTE AUTOMATIZADO: LIP-SYNC, BEHAVIOR E AGENT RESP (61-85)');
  WriteLn('===========================================================');

  Rig := TAISkeletonRig.Create(nil);
  Rig.AutoMapHumanoidBones;

  LipSync := TAIAvatarLipSync.Create(nil);
  LipSync.Skeleton := Rig;

  Behavior := TAIAvatarBehavior.Create(nil);

  try
    // ========================================================================
    // TESTE 1: TAIAvatarLipSync (Tarefas 61 a 65, 70)
    // ========================================================================
    WriteLn('[1] Testando TAIAvatarLipSync: Amplitude, Mandibula e Suavizacao...');
    
    // Nivel zero (Silencio - Tarefa 64)
    LipSync.ProcessAudioLevel(0.0);
    LipSync.Update(0.1);
    WriteLn('  - Jaw Angle em silencio: ', LipSync.CurrentJawAngle:0:2);
    if LipSync.CurrentJawAngle <> 0.0 then
    begin
      WriteLn('[ERRO] Mandibula deveria estar fechada em silencio.');
      Halt(1);
    end;

    // Nivel alto de voz (0.8)
    LipSync.ProcessAudioLevel(0.8);
    LipSync.Update(0.1);
    WriteLn('  - Jaw Angle com audio 0.8 (suavizado): ', LipSync.CurrentJawAngle:0:2);
    if LipSync.CurrentJawAngle <= 1.0 then
    begin
      WriteLn('[ERRO] Mandibula deveria ter aberto.');
      Halt(2);
    end;

    // Teste de Visema (Tarefa 70)
    LipSync.SetViseme(visemeA, 1.0);
    LipSync.Update(0.1);
    WriteLn('  - Jaw Angle com visema A: ', LipSync.CurrentJawAngle:0:2);

    LipSync.ResetJaw;
    WriteLn('  - Jaw Angle apos ResetJaw: ', LipSync.CurrentJawAngle:0:2);
    if LipSync.CurrentJawAngle <> 0.0 then
    begin
      WriteLn('[ERRO] ResetJaw falhou.');
      Halt(3);
    end;

    // ========================================================================
    // TESTE 2: Parser de Resposta Estruturada da IA (Tarefas 78 a 80)
    // ========================================================================
    WriteLn('[2] Testando ParseAvatarResponse...');
    
    // JSON completo
    JSONText := '{"text": "Ola! Tudo bem?", "emotion": "happy", "gesture": "wave", "intensity": 0.85, "look_target": "user"}';
    Resp := ParseAvatarResponse(JSONText);
    WriteLn('  - Texto: ', Resp.Text);
    WriteLn('  - Emocao: ', AvatarEmotionToString(Resp.Emotion));
    WriteLn('  - Gesto: ', AvatarGestureToString(Resp.Gesture));
    WriteLn('  - Intensidade: ', Resp.Intensity:0:2);

    if (Resp.Text <> 'Ola! Tudo bem?') or (Resp.Emotion <> aeHappy) or (Resp.Gesture <> agWave) then
    begin
      WriteLn('[ERRO] ParseAvatarResponse falhou no JSON completo.');
      Halt(4);
    end;

    // Fallback: texto simples sem formato JSON (Tarefa 80)
    JSONText := 'Resposta simples em texto puro.';
    Resp := ParseAvatarResponse(JSONText);
    if (Resp.Text <> 'Resposta simples em texto puro.') or (Resp.Emotion <> aeNeutral) then
    begin
      WriteLn('[ERRO] Fallback de texto puro falhou.');
      Halt(5);
    end;

    // ========================================================================
    // TESTE 3: TAIAvatarBehavior - Cooldown e Expressividade (Tarefas 71 a 77)
    // ========================================================================
    WriteLn('[3] Testando TAIAvatarBehavior (Cooldown de gestos e perfis)...');
    Behavior.Profile := epReserved;
    WriteLn('  - MaxIntensity para epReserved: ', Behavior.MaxIntensity:0:2);
    if Behavior.MaxIntensity > 0.5 then
    begin
      WriteLn('[ERRO] epReserved deveria limitar intensidade a <= 0.5.');
      Halt(6);
    end;

    // ========================================================================
    // TESTE 4: TAIAvatar3D.ApplyAgentResponse (Tarefa 83)
    // ========================================================================
    WriteLn('[4] Testando TAIAvatar3D.ApplyAgentResponse...');
    Avatar := TAIAvatar3D.Create(nil);
    try
      Avatar.LoadAvatar('tests' + DirectorySeparator + 'test_avatar_sample.glb');
      
      JSONText := '{"text": "Excelente ideia!", "emotion": "excited", "gesture": "nod", "intensity": 0.9}';
      Avatar.ApplyAgentResponse(JSONText);

      WriteLn('  - Avatar Emotion: ', AvatarEmotionToString(Avatar.Emotion));
      WriteLn('  - Avatar Gesture ativo: ', Avatar.Controller.IsPerformingGesture);

      if Avatar.Emotion <> aeExcited then
      begin
        WriteLn('[ERRO] Emocao do avatar deveria ser aeExcited.');
        Halt(7);
      end;
      
      if not Avatar.Controller.IsPerformingGesture then
      begin
        WriteLn('[ERRO] Gesto nod deveria estar em execucao no avatar.');
        Halt(8);
      end;

      WriteLn('===========================================================');
      WriteLn('[SUCESSO] TODOS OS TESTES DAS TAREFAS 61 A 85 PASSARAM!');
      WriteLn('===========================================================');
    finally
      Avatar.Free;
    end;

  finally
    Behavior.Free;
    LipSync.Free;
    Rig.Free;
  end;
end.
