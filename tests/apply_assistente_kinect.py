#!/usr/bin/env python3
"""
Applies Kinect perception & adapter integration to P:\maurinsoft\Assistente.
"""

import sys
from pathlib import Path

SRC_DIR = Path(r"P:\maurinsoft\Assistente\src")
LPI_FILE = SRC_DIR / "assistente.lpi"
SETMAIN_FILE = SRC_DIR / "setmain.pas"
MAIN_FILE = SRC_DIR / "main.pas"

def patch_lpi():
    print("[1] Atualizando assistente.lpi com busca em AIKinect...")
    txt = LPI_FILE.read_text(encoding="utf-8")
    
    kinect_path = r";..\..\CHATGPT\pacote\AI Input\AIKinect"
    if kinect_path not in txt:
        old_inc = 'AIInput"/>'
        new_inc = 'AIInput' + kinect_path + '"/>'
        txt = txt.replace(old_inc, new_inc)

        LPI_FILE.write_text(txt, encoding="utf-8")
        print("  OK: assistente.lpi atualizado.")
    else:
        print("  OK: assistente.lpi ja possui AIKinect no SearchPath.")

def patch_setmain():
    print("[2] Atualizando setmain.pas com suporte a persistencia do Kinect...")
    txt = SETMAIN_FILE.read_text(encoding="utf-8")

    if "FKinectEnabled" not in txt:
        # 1. Private fields
        old_priv = "FAudioChannels : integer;"
        new_priv = """FAudioChannels : integer;

        { Kinect v1 / Percepcao }
        FKinectEnabled : Boolean;
        FKinectMinDistance : Double;
        FKinectMaxDistance : Double;
        FKinectSeatedMode : Boolean;
        FKinectTargetLeft : string;
        FKinectTargetRight : string;
        FKinectTargetCenter : string;"""
        txt = txt.replace(old_priv, new_priv, 1)

        # 2. Public properties
        old_prop = "property Avatar3DQuality: string read FAvatar3DQuality write FAvatar3DQuality;"
        new_prop = """property Avatar3DQuality: string read FAvatar3DQuality write FAvatar3DQuality;

        { Kinect v1 / Percepcao }
        property KinectEnabled : Boolean read FKinectEnabled write FKinectEnabled;
        property KinectMinDistance : Double read FKinectMinDistance write FKinectMinDistance;
        property KinectMaxDistance : Double read FKinectMaxDistance write FKinectMaxDistance;
        property KinectSeatedMode : Boolean read FKinectSeatedMode write FKinectSeatedMode;
        property KinectTargetLeft : string read FKinectTargetLeft write FKinectTargetLeft;
        property KinectTargetRight : string read FKinectTargetRight write FKinectTargetRight;
        property KinectTargetCenter : string read FKinectTargetCenter write FKinectTargetCenter;"""
        txt = txt.replace(old_prop, new_prop, 1)

        # 3. Default values
        old_def = "FAvatar3DQuality := 'auto';"
        new_def = """FAvatar3DQuality := 'auto';

    FKinectEnabled := True;
    FKinectMinDistance := 0.8;
    FKinectMaxDistance := 2.5;
    FKinectSeatedMode := True;
    FKinectTargetLeft := 'ECG';
    FKinectTargetRight := 'Hemacias';
    FKinectTargetCenter := 'Robotinics';"""
        txt = txt.replace(old_def, new_def, 1)

        # 4. CarregaContexto
        old_load = "FAvatar3DQuality := RetiraInfo(arquivo.Strings[posicao]);\n    end;"
        new_load = """FAvatar3DQuality := RetiraInfo(arquivo.Strings[posicao]);
    end;

    if BuscaChave(arquivo, 'KINECT_ENABLED:', posicao) then
      FKinectEnabled := (RetiraInfo(arquivo.Strings[posicao]) = '1') or (UpperCase(RetiraInfo(arquivo.Strings[posicao])) = 'TRUE');
    if BuscaChave(arquivo, 'KINECT_MINDIST:', posicao) then
      FKinectMinDistance := StrToFloatDef(RetiraInfo(arquivo.Strings[posicao]), 0.8);
    if BuscaChave(arquivo, 'KINECT_MAXDIST:', posicao) then
      FKinectMaxDistance := StrToFloatDef(RetiraInfo(arquivo.Strings[posicao]), 2.5);
    if BuscaChave(arquivo, 'KINECT_SEATED:', posicao) then
      FKinectSeatedMode := (RetiraInfo(arquivo.Strings[posicao]) = '1') or (UpperCase(RetiraInfo(arquivo.Strings[posicao])) = 'TRUE');
    if BuscaChave(arquivo, 'KINECT_TARGET_LEFT:', posicao) then
      FKinectTargetLeft := RetiraInfo(arquivo.Strings[posicao]);
    if BuscaChave(arquivo, 'KINECT_TARGET_RIGHT:', posicao) then
      FKinectTargetRight := RetiraInfo(arquivo.Strings[posicao]);
    if BuscaChave(arquivo, 'KINECT_TARGET_CENTER:', posicao) then
      FKinectTargetCenter := RetiraInfo(arquivo.Strings[posicao]);"""
        txt = txt.replace(old_load, new_load, 1)

        # 5. SalvaContexto
        old_save = "arquivo.Append('AUDIOCHANNELS:'+inttostr(FAudioChannels));"
        new_save = """arquivo.Append('AUDIOCHANNELS:'+inttostr(FAudioChannels));

  arquivo.Append('KINECT_ENABLED:'+iif(FKinectEnabled, '1', '0'));
  arquivo.Append('KINECT_MINDIST:'+FloatToStr(FKinectMinDistance));
  arquivo.Append('KINECT_MAXDIST:'+FloatToStr(FKinectMaxDistance));
  arquivo.Append('KINECT_SEATED:'+iif(FKinectSeatedMode, '1', '0'));
  arquivo.Append('KINECT_TARGET_LEFT:'+FKinectTargetLeft);
  arquivo.Append('KINECT_TARGET_RIGHT:'+FKinectTargetRight);
  arquivo.Append('KINECT_TARGET_CENTER:'+FKinectTargetCenter);"""
        txt = txt.replace(old_save, new_save, 1)

        SETMAIN_FILE.write_text(txt, encoding="utf-8")
        print("  OK: setmain.pas atualizado com sucesso.")
    else:
        print("  OK: setmain.pas ja possui configuracoes do Kinect.")

def patch_main():
    print("[3] Atualizando main.pas com percepcao e adaptador do Kinect...")
    txt = MAIN_FILE.read_text(encoding="utf-8")

    if "FKinectPerception" not in txt:
        # 1. uses clause
        old_uses = "aipresentation, jarvis_api,"
        new_uses = "aipresentation, aikinect_types, aikinectsensor, aikinectskeleton, aikinectperception, aikinectadapter, jarvis_api,"
        txt = txt.replace(old_uses, new_uses, 1)

        # 2. Private fields
        old_fields = "FProjectManager: TAssistantProjectManager;"
        new_fields = """FProjectManager: TAssistantProjectManager;

    { Percepcao Kinect v1 }
    FKinectSensor: TAIKinectSensor;
    FKinectSkeleton: TAIKinectSkeleton;
    FKinectPerception: TAIKinectPerception;
    FKinectAdapter: TAIKinectInteractionAdapter;"""
        txt = txt.replace(old_fields, new_fields, 1)

        # 3. Private method declarations
        old_decl = "procedure OnSpeechInterruption(Sender: TObject);"
        new_decl = """procedure InitKinect;
    procedure ShutdownKinect;
    procedure OnKinectPersonEntered(Sender: TObject; ATrackingID: Integer; ADistance: Single; const APosition: string);
    procedure OnKinectPersonLeft(Sender: TObject; ATrackingID: Integer);
    procedure OnKinectDeicticResolved(Sender: TObject; const AGesture, ATarget: string);
    procedure OnKinectGestureDetected(Sender: TObject; const AGestureName, ATargetObject: string);

    procedure OnSpeechInterruption(Sender: TObject);"""
        txt = txt.replace(old_decl, new_decl, 1)

        # 4. Method implementations
        impl_block = """{ Kinect Perception & Multi-Modal Adapter Implementation }

procedure Tfrmmain.InitKinect;
var
  DevList: TStringList;
begin
  FKinectSensor := TAIKinectSensor.Create(Self);
  FKinectSkeleton := TAIKinectSkeleton.Create(Self);
  FKinectPerception := TAIKinectPerception.Create(Self);
  FKinectAdapter := TAIKinectInteractionAdapter.Create(Self);

  FKinectSkeleton.Sensor := FKinectSensor;
  FKinectPerception.Sensor := FKinectSensor;
  FKinectPerception.Skeleton := FKinectSkeleton;

  if FSetMain <> nil then
  begin
    FKinectPerception.MinDistanceMeters := FSetMain.KinectMinDistance;
    FKinectPerception.MaxDistanceMeters := FSetMain.KinectMaxDistance;
  end;

  FKinectAdapter.Perception := FKinectPerception;
  FKinectAdapter.Orchestrator := FConversationOrchestrator;

  if FSetMain <> nil then
  begin
    FKinectAdapter.TargetLeft := FSetMain.KinectTargetLeft;
    FKinectAdapter.TargetRight := FSetMain.KinectTargetRight;
    FKinectAdapter.TargetCenter := FSetMain.KinectTargetCenter;
  end;

  FKinectAdapter.OnPersonEntered := @OnKinectPersonEntered;
  FKinectAdapter.OnPersonLeft := @OnKinectPersonLeft;
  FKinectAdapter.OnDeicticTargetResolved := @OnKinectDeicticResolved;

  if FConversationOrchestrator <> nil then
    FConversationOrchestrator.OnGestureDetected := @OnKinectGestureDetected;

  // Deteccao nao-bloqueante de hardware fisico
  DevList := FKinectSensor.ListDevices;
  try
    if (DevList.Count > 0) and ((FSetMain = nil) or FSetMain.KinectEnabled) then
    begin
      FKinectSensor.DeviceIndex := 0;
      FKinectSensor.Backend := kbKinectSDK10;
      FKinectSensor.KinectModel := kmXbox360;
      if FKinectSensor.Open then
      begin
        if FSetMain <> nil then
          FKinectSkeleton.SeatedMode := FSetMain.KinectSeatedMode;
        FKinectSkeleton.Active := True;
        AdicionaMensagemHistorico('Sensor Visual', 'Kinect v1 online: sensor primario de presenca e gestos ativado.');
      end
      else
        AdicionaMensagemHistorico('Sensor Visual', 'Falha ao conectar Kinect v1: ' + FKinectSensor.LastError);
    end
    else
    begin
      AdicionaMensagemHistorico('Sensor Visual', 'Kinect v1 offline (sem hardware fisico). Percepcao em modo prontidao/simulacao.');
    end;
  finally
    DevList.Free;
  end;
end;

procedure Tfrmmain.ShutdownKinect;
begin
  if Assigned(FKinectSkeleton) then
    FKinectSkeleton.Active := False;
  if Assigned(FKinectSensor) and FKinectSensor.IsConnected then
    FKinectSensor.Close;
end;

procedure Tfrmmain.OnKinectPersonEntered(Sender: TObject; ATrackingID: Integer;
  ADistance: Single; const APosition: string);
begin
  AdicionaMensagemHistorico('Sensor Visual', Format('Visitante aproximou-se (ID #%d, %.2fm, %s).', [ATrackingID, ADistance, APosition]));

  // Orientacao do Olhar (Gaze) e Saudacao do Avatar 3D
  if FAvatar3D <> nil then
  begin
    if APosition = 'left' then
      FAvatar3D.LookAt(ltLeft)
    else if APosition = 'right' then
      FAvatar3D.LookAt(ltRight)
    else
    begin
      FAvatar3D.LookAt(ltCenter);
      FAvatar3D.PlayGesture(agWave, 2.0);
    end;
  end;

  // Inicia ou resume apresentacao autonoma caso o professor esteja ocioso
  if (FPresentationAgent <> nil) and (FPresentationAgent.State = psIdle) then
  begin
    FPresentationAgent.StartPresentation(IntToStr(ATrackingID), 'Visitante');
  end;
end;

procedure Tfrmmain.OnKinectPersonLeft(Sender: TObject; ATrackingID: Integer);
begin
  AdicionaMensagemHistorico('Sensor Visual', Format('Visitante #%d afastou-se da zona de apresentacao.', [ATrackingID]));

  if FAvatar3D <> nil then
  begin
    FAvatar3D.LookAt(ltCenter);
    FAvatar3D.SetState(avIdle);
  end;
end;

procedure Tfrmmain.OnKinectDeicticResolved(Sender: TObject; const AGesture, ATarget: string);
begin
  AdicionaMensagemHistorico('Gesto Fisico', Format('Visitante apontou para %s (%s).', [ATarget, AGesture]));

  // Avatar confirma o apontamento e orienta o olhar para o projeto alvo
  if FAvatar3D <> nil then
  begin
    if AGesture = 'point_left' then
      FAvatar3D.LookAt(ltLeft)
    else if AGesture = 'point_right' then
      FAvatar3D.LookAt(ltRight)
    else
      FAvatar3D.LookAt(ltCenter);

    FAvatar3D.PlayGesture(agPoint, 2.0);
  end;

  // Apresentacao autonoma migra diretamente para o projeto apontado
  if FPresentationAgent <> nil then
  begin
    FPresentationAgent.StartPresentation('visitante', 'Visitante', ATarget);
  end;
end;

procedure Tfrmmain.OnKinectGestureDetected(Sender: TObject; const AGestureName, ATargetObject: string);
begin
  // Reconhecimento de mao levantada (Aluno quer fazer pergunta)
  if (AGestureName = 'raise_hand') or (AGestureName = 'raise_right_hand') or (AGestureName = 'raise_left_hand') then
  begin
    AdicionaMensagemHistorico('Percepcao', 'Visitante levantou a mao para perguntar.');
    if FPresentationAgent <> nil then
    begin
      FPresentationAgent.PausePresentation;
    end;
    if FAvatar3D <> nil then
    begin
      FAvatar3D.PlayGesture(agNod, 1.5);
    end;
    if (FSetMain <> nil) and FSetMain.AutoSpeak then
      FalaTexto('Pode fazer sua pergunta! Estou ouvindo.');
  end;
end;

"""
        # Insert before OnSpeechInterruption
        target_marker = "procedure Tfrmmain.OnSpeechInterruption(Sender: TObject);"
        txt = txt.replace(target_marker, impl_block + target_marker, 1)

        # 5. Call InitKinect in FormCreate
        target_create = "FPresentationAgent.StartPresentation('', 'Visitante');"
        new_create = """FPresentationAgent.StartPresentation('', 'Visitante');

  // Inicializa Percepcao Semantica Kinect v1
  InitKinect;"""
        txt = txt.replace(target_create, new_create, 1)

        # 6. Call ShutdownKinect in FormClose
        old_close = "procedure Tfrmmain.FormClose(Sender: TObject; var CloseAction: TCloseAction);\nbegin"
        new_close = """procedure Tfrmmain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  ShutdownKinect;"""
        txt = txt.replace(old_close, new_close, 1)

        MAIN_FILE.write_text(txt, encoding="utf-8")
        print("  OK: main.pas atualizado com suporte completo ao Kinect.")
    else:
        if "AcknowledgeQuestion" in txt:
            txt = txt.replace("FPresentationAgent.AcknowledgeQuestion;", "FPresentationAgent.PausePresentation;")
            MAIN_FILE.write_text(txt, encoding="utf-8")
            print("  OK: main.pas corrigido AcknowledgeQuestion -> PausePresentation.")
        print("  OK: main.pas ja possui suporte ao Kinect.")

def main():
    patch_lpi()
    patch_setmain()
    patch_main()
    print("\nTodos os arquivos do Assistente foram atualizados com sucesso!")

if __name__ == "__main__":
    main()
