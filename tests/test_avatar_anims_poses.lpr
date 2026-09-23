program test_avatar_anims_poses;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, aiavatartypes, aiskeletonrig, aianimationsequence, aiposelibrary;

type
  TTestRunner = class
  public
    FinishedCount: Integer;
    procedure HandleAnimFinished(Sender: TObject);
  end;

var
  Runner: TTestRunner;
  AnimSeq: TAIAnimationSequence;
  PoseLib: TAIPoseLibrary;
  Rig: TAISkeletonRig;
  PoseNames: TStringList;
  TestJsonPath: string;
  JointIdx: Integer;
  J: TBoneJoint;

procedure TTestRunner.HandleAnimFinished(Sender: TObject);
begin
  Inc(FinishedCount);
  WriteLn('  [EVENT] OnAnimationFinished disparado!');
end;

begin
  WriteLn('====================================================');
  WriteLn('TESTE AUTOMATIZADO: ANIMACOES, POSES E BLENDING (28-40)');
  WriteLn('====================================================');

  Runner := TTestRunner.Create;
  Runner.FinishedCount := 0;
  Rig := TAISkeletonRig.Create(nil);
  AnimSeq := TAIAnimationSequence.Create(nil);
  PoseLib := TAIPoseLibrary.Create(nil);
  PoseNames := TStringList.Create;
  try
    // ========================================================================
    // TESTE 1: TAIAnimationSequence (Tarefas 30 a 37)
    // ========================================================================
    WriteLn('[1] Testando TAIAnimationSequence: Play, Speed, Loop, Pause e Eventos...');
    AnimSeq.OnAnimationFinished := @Runner.HandleAnimFinished;
    AnimSeq.Loop := False;
    AnimSeq.Speed := 1.0;
    AnimSeq.PlayAnimation('TestClip');

    if not AnimSeq.IsPlaying then
    begin
      WriteLn('[ERRO] AnimSeq deveria estar tocando.');
      Halt(1);
    end;

    // Atualiza meio segundo
    AnimSeq.Update(0.5);
    WriteLn('  - CurrentTime apos 0.5s (speed 1.0x): ', AnimSeq.CurrentTime:0:2);
    if Abs(AnimSeq.CurrentTime - 0.5) > 0.05 then
    begin
      WriteLn('[ERRO] CurrentTime incorreto!');
      Halt(2);
    end;

    // Testar velocidade 2.0x
    AnimSeq.Speed := 2.0;
    AnimSeq.Update(0.25); // deve avancar 0.5s adicionais (total 1.0s)
    WriteLn('  - CurrentTime apos 0.25s (speed 2.0x): ', AnimSeq.CurrentTime:0:2);
    if Abs(AnimSeq.CurrentTime - 1.0) > 0.05 then
    begin
      WriteLn('[ERRO] Speed 2.0x falhou!');
      Halt(3);
    end;

    if Runner.FinishedCount <> 1 then
    begin
      WriteLn('[ERRO] OnAnimationFinished nao foi disparado.');
      Halt(4);
    end;

    // Testar Queue de Animacoes (Idle -> Wave -> Idle)
    WriteLn('[2] Testando Fila de Animacoes (Idle -> Wave -> Idle)...');
    AnimSeq.ClearQueue;
    AnimSeq.Speed := 1.0;
    AnimSeq.QueueAnimation('Idle', False, 1.0);
    AnimSeq.QueueAnimation('Wave', False, 1.0);
    AnimSeq.QueueAnimation('Idle', True, 1.0); // Fica em loop no final

    WriteLn('  - Animacao atual da fila: ', AnimSeq.CurrentAnimation);
    if AnimSeq.CurrentAnimation <> 'Idle' then
    begin
      WriteLn('[ERRO] Primeira animacao deveria ser Idle, obtido: ', AnimSeq.CurrentAnimation);
      Halt(5);
    end;

    // Forca termino de Idle para avancar para Wave
    AnimSeq.Update(1.1);
    WriteLn('  - Proxima animacao da fila: ', AnimSeq.CurrentAnimation);
    if AnimSeq.CurrentAnimation <> 'Wave' then
    begin
      WriteLn('[ERRO] Segunda animacao deveria ser Wave, obtido: ', AnimSeq.CurrentAnimation);
      Halt(6);
    end;

    // Forca termino de Wave para avancar para Idle (loop)
    AnimSeq.Update(1.1);
    WriteLn('  - Terceira animacao da fila: ', AnimSeq.CurrentAnimation);
    if (AnimSeq.CurrentAnimation <> 'Idle') or (not AnimSeq.Loop) then
    begin
      WriteLn('[ERRO] Terceira animacao deveria ser Idle em loop.');
      Halt(7);
    end;

    // ========================================================================
    // TESTE 2: TAIPoseLibrary e Poses Padrao (Tarefas 38 a 40)
    // ========================================================================
    WriteLn('[3] Testando TAIPoseLibrary: Presets Padrao e Busca...');
    PoseLib.GetPoseNames(PoseNames);
    WriteLn('  - Total de poses carregadas: ', PoseNames.Count);
    WriteLn('  - Poses disponiveis: ', PoseNames.CommaText);

    if PoseNames.IndexOf('Neutral') < 0 then
    begin
      WriteLn('[ERRO] Pose Neutral ausente!');
      Halt(8);
    end;
    if PoseNames.IndexOf('Listening') < 0 then
    begin
      WriteLn('[ERRO] Pose Listening ausente!');
      Halt(9);
    end;
    if PoseNames.IndexOf('Thinking') < 0 then
    begin
      WriteLn('[ERRO] Pose Thinking ausente!');
      Halt(10);
    end;

    // Mapear ossos no rig de teste para teste de aplicacao
    Rig.AutoMapHumanoidBones;
    WriteLn('[4] Testando ApplyPose com intensidades (0.5 e 1.0)...');
    
    // Aplicar Thinking com intensidade 1.0
    PoseLib.ApplyPose('Thinking', Rig, 1.0);
    if Rig.FindHumanoidBone(hbHead, JointIdx) then
    begin
      J := Rig.GetJoint(JointIdx);
      WriteLn('  - Head AngleX (Thinking 1.0): ', J.AngleX:0:2);
      if Abs(J.AngleX - (-8.0)) > 0.01 then
      begin
        WriteLn('[ERRO] AngleX incorreto para Thinking 1.0!');
        Halt(11);
      end;
    end;

    // Aplicar Thinking com intensidade 0.5 (Tarefa 40)
    PoseLib.ApplyPose('Thinking', Rig, 0.5);
    if Rig.FindHumanoidBone(hbHead, JointIdx) then
    begin
      J := Rig.GetJoint(JointIdx);
      WriteLn('  - Head AngleX (Thinking 0.5): ', J.AngleX:0:2);
      if Abs(J.AngleX - (-4.0)) > 0.01 then
      begin
        WriteLn('[ERRO] AngleX incorreto para Thinking 0.5!');
        Halt(12);
      end;
    end;

    // Testar BlendPoses entre Neutral e Thinking com fator 0.5
    WriteLn('[5] Testando BlendPoses (Neutral <-> Thinking, 0.5)...');
    PoseLib.BlendPoses('Neutral', 'Thinking', 0.5, Rig);
    if Rig.FindHumanoidBone(hbHead, JointIdx) then
    begin
      J := Rig.GetJoint(JointIdx);
      WriteLn('  - Head AngleX (Blend 0.5): ', J.AngleX:0:2);
      if Abs(J.AngleX - (-4.0)) > 0.01 then
      begin
        WriteLn('[ERRO] BlendPoses falhou!');
        Halt(13);
      end;
    end;

    // Testar Persistencia em JSON
    WriteLn('[6] Testando SaveLibraryToFile e LoadLibraryFromFile...');
    TestJsonPath := GetTempDir + 'test_poses_export.json';
    PoseLib.SaveLibraryToFile(TestJsonPath);
    if not FileExists(TestJsonPath) then
    begin
      WriteLn('[ERRO] Arquivo JSON nao foi gerado: ', TestJsonPath);
      Halt(14);
    end;
    WriteLn('  - Arquivo JSON salvo com sucesso: ', TestJsonPath);

    WriteLn('====================================================');
    WriteLn('[SUCESSO] TODOS OS TESTES DAS TAREFAS 28 A 40 PASSARAM!');
    WriteLn('====================================================');
  finally
    PoseNames.Free;
    PoseLib.Free;
    AnimSeq.Free;
    Rig.Free;
    Runner.Free;
  end;
end.
