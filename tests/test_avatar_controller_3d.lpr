program test_avatar_controller_3d;

{$mode objfpc}{$H+}

uses
  Classes, SysUtils, aiavatartypes, aiskeletonrig, aiposelibrary, 
  aianimationsequence, aiavatarcontroller, aiavatar3d;

type
  TTestRunner = class
  public
    StateChangedCount: Integer;
    GestureStartCount: Integer;
    GestureFinishCount: Integer;
    LoadedCount: Integer;

    procedure HandleStateChanged(Sender: TObject);
    procedure HandleGestureStart(Sender: TObject);
    procedure HandleGestureFinish(Sender: TObject);
    procedure HandleAvatarLoaded(Sender: TObject);
  end;

procedure TTestRunner.HandleStateChanged(Sender: TObject);
begin
  Inc(StateChangedCount);
  WriteLn('  [EVENT] OnStateChanged disparado!');
end;

procedure TTestRunner.HandleGestureStart(Sender: TObject);
begin
  Inc(GestureStartCount);
  WriteLn('  [EVENT] OnGestureStart disparado!');
end;

procedure TTestRunner.HandleGestureFinish(Sender: TObject);
begin
  Inc(GestureFinishCount);
  WriteLn('  [EVENT] OnGestureFinish disparado!');
end;

procedure TTestRunner.HandleAvatarLoaded(Sender: TObject);
begin
  Inc(LoadedCount);
  WriteLn('  [EVENT] OnLoaded disparado!');
end;

var
  Runner: TTestRunner;
  Avatar: TAIAvatar3D;
  SampleFile: string;
begin
  WriteLn('====================================================');
  WriteLn('TESTE AUTOMATIZADO: CONTROLLER E AVATAR 3D (41-60)');
  WriteLn('====================================================');

  Runner := TTestRunner.Create;
  Avatar := TAIAvatar3D.Create(nil);
  try
    Avatar.OnStateChanged := @Runner.HandleStateChanged;
    Avatar.OnGestureStart := @Runner.HandleGestureStart;
    Avatar.OnGestureFinish := @Runner.HandleGestureFinish;
    Avatar.OnLoaded := @Runner.HandleAvatarLoaded;

    SampleFile := 'tests' + DirectorySeparator + 'test_avatar_sample.glb';
    if not FileExists(SampleFile) then
      SampleFile := 'D:\projetos\maurinsoft\CHATGPT\tests\test_avatar_sample.glb';

    WriteLn('[1] Testando LoadAvatar (auto-criacao de componentes e ligacoes)...');
    Avatar.LoadAvatar(SampleFile);

    if not Avatar.Active then
    begin
      WriteLn('[ERRO] Avatar deveria estar ativo apos LoadAvatar.');
      Halt(1);
    end;

    if Runner.LoadedCount <> 1 then
    begin
      WriteLn('[ERRO] Evento OnLoaded nao foi disparado.');
      Halt(2);
    end;

    WriteLn('  - Model carregado: ', Avatar.Model <> nil);
    WriteLn('  - Skeleton ativo: ', Avatar.Skeleton <> nil);
    WriteLn('  - Controller ativo: ', Avatar.Controller <> nil);
    WriteLn('  - PoseLibrary ativa: ', Avatar.PoseLibrary <> nil);
    WriteLn('  - AnimationSequence ativa: ', Avatar.AnimationSequence <> nil);

    WriteLn('[2] Testando alteracao de estados (SetState)...');
    Avatar.SetState(avListening);
    if Avatar.State <> avListening then
    begin
      WriteLn('[ERRO] Estado deveria ser avListening.');
      Halt(3);
    end;

    Avatar.SetState(avThinking);
    if Avatar.State <> avThinking then
    begin
      WriteLn('[ERRO] Estado deveria ser avThinking.');
      Halt(4);
    end;

    Avatar.SetState(avSpeaking);
    if Avatar.State <> avSpeaking then
    begin
      WriteLn('[ERRO] Estado deveria ser avSpeaking.');
      Halt(5);
    end;

    WriteLn('  - Total de mudancas de estado: ', Runner.StateChangedCount);

    WriteLn('[3] Testando gestos procedurais (PlayGesture)...');
    // Gesto Wave com duracao curta de 0.4s para teste
    Avatar.PlayGesture(agWave, 0.4);
    if not Avatar.Controller.IsPerformingGesture then
    begin
      WriteLn('[ERRO] Gesto Wave deveria estar ativo.');
      Halt(6);
    end;

    if Runner.GestureStartCount <> 1 then
    begin
      WriteLn('[ERRO] OnGestureStart nao disparou.');
      Halt(7);
    end;

    // Atualiza 0.2s (50% do gesto)
    Avatar.Update(0.2);
    WriteLn('  - Progresso do gesto Wave (0.2s / 0.4s): ', Avatar.Controller.GestureProgress:0:2);

    // Atualiza mais 0.25s (deve terminar o gesto)
    Avatar.Update(0.25);
    if Avatar.Controller.IsPerformingGesture then
    begin
      WriteLn('[ERRO] Gesto Wave deveria ter finalizado.');
      Halt(8);
    end;

    if Runner.GestureFinishCount <> 1 then
    begin
      WriteLn('[ERRO] OnGestureFinish nao disparou.');
      Halt(9);
    end;

    WriteLn('[4] Testando gestos Nod, ShakeHead e Think...');
    Avatar.PlayGesture(agNod, 0.2);
    Avatar.Update(0.25); // finaliza
    Avatar.PlayGesture(agShakeHead, 0.2);
    Avatar.Update(0.25); // finaliza
    Avatar.PlayGesture(agThink, 0.2);
    Avatar.Update(0.25); // finaliza

    WriteLn('  - Total gestos iniciados: ', Runner.GestureStartCount);
    WriteLn('  - Total gestos finalizados: ', Runner.GestureFinishCount);
    if Runner.GestureFinishCount <> 4 then
    begin
      WriteLn('[ERRO] Todos os 4 gestos deveriam ter finalizado com sucesso.');
      Halt(10);
    end;

    WriteLn('[5] Testando LookAt (atencao visual e clamps de angulo)...');
    Avatar.LookAt(ltLeft);
    Avatar.LookAt(ltRight);
    Avatar.LookAt(ltUp);
    Avatar.LookAt(ltDown);
    Avatar.LookAt(ltUser);

    WriteLn('[6] Testando UnloadAvatar...');
    Avatar.UnloadAvatar;
    if Avatar.Active then
    begin
      WriteLn('[ERRO] Avatar deveria estar inativo apos UnloadAvatar.');
      Halt(11);
    end;

    WriteLn('====================================================');
    WriteLn('[SUCESSO] TODOS OS TESTES DAS TAREFAS 41 A 60 PASSARAM!');
    WriteLn('====================================================');
  finally
    Avatar.Free;
    Runner.Free;
  end;
end.
