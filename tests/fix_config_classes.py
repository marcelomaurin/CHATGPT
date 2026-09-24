# -*- coding: utf-8 -*-
"""
Script para corrigir o erro ao abrir as configurações (frmconfig):
1. Adiciona os 9 componentes do Kinect (chkKinectEnabled, chkKinectSeated,
   lblKinectDist, edKinectMinDist, edKinectMaxDist, lblKinectTargets,
   edKinectTargetLeft, edKinectTargetRight, edKinectTargetCenter) ao frmconfig.lfm.
2. Adiciona proteções defensivas (Assigned) e tratamento de exceção em btAbrirConfigClick
   no main.pas para prevenir qualquer falha de ponteiro nulo.
"""

import os
import re

assistente_dir = r"P:\maurinsoft\Assistente"
frmconfig_lfm_path = os.path.join(assistente_dir, "src", "frmconfig.lfm")
main_pas_path = os.path.join(assistente_dir, "src", "main.pas")

print("Iniciando correção das classes do frmconfig...")

# -------------------------------------------------------------
# 1. Atualizar frmconfig.lfm
# -------------------------------------------------------------
with open(frmconfig_lfm_path, "r", encoding="latin1") as f:
    lfm_text = f.read()

old_ts_visao = """    object tsVisao: TTabSheet
      Caption = 'Visão'
      ClientHeight = 412
      ClientWidth = 382
      object lblVer: TLabel
        Left = 10
        Height = 15
        Top = 15
        Width = 124
        Caption = 'Visão - Servidor (IP / Porta):'
        ParentColor = False
      end
      object edVerIP: TEdit
        Left = 10
        Height = 23
        Top = 35
        Width = 160
        TabOrder = 0
        Text = '127.0.0.1'
      end
      object edVerPort: TEdit
        Left = 180
        Height = 23
        Top = 35
        Width = 70
        TabOrder = 1
        Text = '8097'
      end
    end"""

new_ts_visao = """    object tsVisao: TTabSheet
      Caption = 'Visão / Kinect'
      ClientHeight = 412
      ClientWidth = 382
      object lblVer: TLabel
        Left = 10
        Height = 15
        Top = 12
        Width = 145
        Caption = 'Servidor de Visão Legado (IP / Porta):'
        ParentColor = False
      end
      object edVerIP: TEdit
        Left = 10
        Height = 23
        Top = 30
        Width = 150
        TabOrder = 0
        Text = '127.0.0.1'
      end
      object edVerPort: TEdit
        Left = 168
        Height = 23
        Top = 30
        Width = 60
        TabOrder = 1
        Text = '8097'
      end
      object chkKinectEnabled: TCheckBox
        Left = 10
        Height = 19
        Top = 64
        Width = 180
        Caption = 'Habilitar Sensor Kinect v1'
        TabOrder = 2
      end
      object chkKinectSeated: TCheckBox
        Left = 10
        Height = 19
        Top = 88
        Width = 200
        Caption = 'Modo Sentado (Seated Mode)'
        TabOrder = 3
      end
      object lblKinectDist: TLabel
        Left = 10
        Height = 15
        Top = 118
        Width = 240
        Caption = 'Distância Operacional Mín / Máx (metros):'
        ParentColor = False
      end
      object edKinectMinDist: TEdit
        Left = 10
        Height = 23
        Top = 136
        Width = 75
        TabOrder = 4
        Text = '0.8'
      end
      object edKinectMaxDist: TEdit
        Left = 95
        Height = 23
        Top = 136
        Width = 75
        TabOrder = 5
        Text = '3.5'
      end
      object lblKinectTargets: TLabel
        Left = 10
        Height = 15
        Top = 170
        Width = 270
        Caption = 'Alvos de Apontamento (Esquerda / Direita / Centro):'
        ParentColor = False
      end
      object edKinectTargetLeft: TEdit
        Left = 10
        Height = 23
        Top = 188
        Width = 85
        TabOrder = 6
        Text = 'ecg'
      end
      object edKinectTargetRight: TEdit
        Left = 102
        Height = 23
        Top = 188
        Width = 85
        TabOrder = 7
        Text = 'robotinics'
      end
      object edKinectTargetCenter: TEdit
        Left = 194
        Height = 23
        Top = 188
        Width = 85
        TabOrder = 8
        Text = 'hemacias'
      end
    end"""

if old_ts_visao in lfm_text:
    lfm_text = lfm_text.replace(old_ts_visao, new_ts_visao)
    with open(frmconfig_lfm_path, "w", encoding="latin1") as f:
        f.write(lfm_text)
    print("frmconfig.lfm atualizado com sucesso com todos os componentes do Kinect.")
else:
    print("Aviso: bloco tsVisao não encontrado exatamente; verificando...")
    # Tenta substituição por regex
    lfm_text = re.sub(
        r"object tsVisao: TTabSheet.*?Caption = 'Visão'.*?end",
        new_ts_visao.strip(),
        lfm_text,
        flags=re.DOTALL
    )
    with open(frmconfig_lfm_path, "w", encoding="latin1") as f:
        f.write(lfm_text)
    print("frmconfig.lfm atualizado via regex.")

# -------------------------------------------------------------
# 2. Atualizar main.pas com proteções defensivas
# -------------------------------------------------------------
with open(main_pas_path, "r", encoding="utf-8") as f:
    pas_text = f.read()

# Substituir btAbrirConfigClick por versão robusta e defensiva
old_proc_regex = re.compile(r"procedure Tfrmmain\.btAbrirConfigClick\(Sender: TObject\);.*?procedure Tfrmmain\.", re.DOTALL)
m = old_proc_regex.search(pas_text)

new_proc = """procedure Tfrmmain.btAbrirConfigClick(Sender: TObject);
var
  FormCfg: TfrmConfig;
begin
  if FSetMain = nil then
    FSetMain := TSetMain.create();

  FormCfg := TfrmConfig.Create(Self);
  try
    try
      // Abrir diretamente a primeira aba (Geral)
      if Assigned(FormCfg.pcConfig) then
        FormCfg.pcConfig.ActivePageIndex := 0;

      // Aba JARVIS
      if Assigned(FormCfg.edJarvisURL) then
        FormCfg.edJarvisURL.Text := FSetMain.JarvisURL;
      if Assigned(FormCfg.edJarvisKey) then
        FormCfg.edJarvisKey.Text := FSetMain.JarvisAPIKey;
      if Assigned(FormCfg.cbJarvisMode) then
      begin
        if FSetMain.JarvisIAMode = 'local_only' then
          FormCfg.cbJarvisMode.ItemIndex := 1
        else if FSetMain.JarvisIAMode = 'cloud_only' then
          FormCfg.cbJarvisMode.ItemIndex := 2
        else
          FormCfg.cbJarvisMode.ItemIndex := 0;
      end;
      if Assigned(FormCfg.chkMinimizeTray) then
        FormCfg.chkMinimizeTray.Checked := FSetMain.MinimizeToTray;
      if Assigned(FormCfg.chkAutoSpeak) then
        FormCfg.chkAutoSpeak.Checked := FSetMain.AutoSpeak;

      // Aba IA Legada
      if Assigned(FormCfg.cbProvider) then
      begin
        FormCfg.cbProvider.ItemIndex := FSetMain.ChatGPTProvider;
        if (FormCfg.cbProvider.ItemIndex < 0) or (FormCfg.cbProvider.ItemIndex >= FormCfg.cbProvider.Items.Count) then
          FormCfg.cbProvider.ItemIndex := 0;
      end;
      FormCfg.CarregaModelosDoProvedor;
      if Assigned(FormCfg.cbModel) and (Trim(FSetMain.ChatGPTModel) <> '') then
        FormCfg.cbModel.Text := FSetMain.ChatGPTModel;
      if Assigned(FormCfg.edTokenGPT) then
        FormCfg.edTokenGPT.Text := FSetMain.CHATGPT;
      if Assigned(FormCfg.edURL) then
        FormCfg.edURL.Text := FSetMain.ChatGPTURL;

      // Aba Output Voice
      if Assigned(FormCfg.cbSynthEngine) then
      begin
        FormCfg.cbSynthEngine.ItemIndex := FSetMain.SynthEngine;
        if (FormCfg.cbSynthEngine.ItemIndex < 0) or (FormCfg.cbSynthEngine.ItemIndex >= FormCfg.cbSynthEngine.Items.Count) then
          FormCfg.cbSynthEngine.ItemIndex := 1;
      end;
      FormCfg.CarregaVozesDoSintetizador;
      if Assigned(FormCfg.cbSynthVoice) and (Trim(FSetMain.SynthVoice) <> '') then
        FormCfg.cbSynthVoice.Text := FSetMain.SynthVoice;
      if Assigned(FormCfg.tbSynthVolume) then
      begin
        FormCfg.tbSynthVolume.Position := FSetMain.SynthVolume;
        FormCfg.tbSynthVolumeChange(Self);
      end;
      if Assigned(FormCfg.tbSynthRate) then
      begin
        FormCfg.tbSynthRate.Position := FSetMain.SynthRate;
        FormCfg.tbSynthRateChange(Self);
      end;
      if Assigned(FormCfg.chkSynthAsync) then
        FormCfg.chkSynthAsync.Checked := FSetMain.SynthAsync;

      // Aba Reconhecimento de Voz / Microfone (CHATGPT)
      if Assigned(FormCfg.cbRecogEngine) then
        FormCfg.cbRecogEngine.ItemIndex := FSetMain.RecogEngine;
      if Assigned(FormCfg.edRecogLanguage) then
        FormCfg.edRecogLanguage.Text := FSetMain.RecogLanguage;
      if Assigned(FormCfg.cbAudioSampleRate) then
      begin
        if FSetMain.AudioSampleRate = 44100 then
          FormCfg.cbAudioSampleRate.ItemIndex := 1
        else
          FormCfg.cbAudioSampleRate.ItemIndex := 0;
      end;
      if Assigned(FormCfg.cbAudioChannels) then
      begin
        if FSetMain.AudioChannels = 2 then
          FormCfg.cbAudioChannels.ItemIndex := 1
        else
          FormCfg.cbAudioChannels.ItemIndex := 0;
      end;

      // Aba Avatar 3D
      if Assigned(FormCfg.edAvatarModel) then
        FormCfg.edAvatarModel.Text := FSetMain.Avatar3DModel;
      if Assigned(FormCfg.chkAvatarAutoIdle) then
        FormCfg.chkAvatarAutoIdle.Checked := FSetMain.Avatar3DAutoIdle;
      if Assigned(FormCfg.chkAvatarAutoBlink) then
        FormCfg.chkAvatarAutoBlink.Checked := FSetMain.Avatar3DAutoBlink;
      if Assigned(FormCfg.chkAvatarLipSync) then
        FormCfg.chkAvatarLipSync.Checked := FSetMain.Avatar3DLipSync;
      if Assigned(FormCfg.cbAvatarQuality) then
        FormCfg.cbAvatarQuality.Text := FSetMain.Avatar3DQuality;

      // Aba Banco
      if Assigned(FormCfg.edMyHost) then FormCfg.edMyHost.Text := FSetMain.HostnameMy;
      if Assigned(FormCfg.edMyDb) then FormCfg.edMyDb.Text := FSetMain.BancoMy;
      if Assigned(FormCfg.edMyUser) then FormCfg.edMyUser.Text := FSetMain.UsernameMy;
      if Assigned(FormCfg.edMyPass) then FormCfg.edMyPass.Text := FSetMain.PasswordMy;
      if Assigned(FormCfg.edPostHost) then FormCfg.edPostHost.Text := FSetMain.HostnamePost;
      if Assigned(FormCfg.edPostDb) then FormCfg.edPostDb.Text := FSetMain.BancoPOST;
      if Assigned(FormCfg.edPostUser) then FormCfg.edPostUser.Text := FSetMain.UsernamePost;
      if Assigned(FormCfg.edPostPass) then FormCfg.edPostPass.Text := FSetMain.PasswordPost;
      if Assigned(FormCfg.edPostSchema) then FormCfg.edPostSchema.Text := FSetMain.SchemaPost;

      // Aba Visao / Kinect
      if Assigned(FormCfg.chkKinectEnabled) then
        FormCfg.chkKinectEnabled.Checked := FSetMain.KinectEnabled;
      if Assigned(FormCfg.chkKinectSeated) then
        FormCfg.chkKinectSeated.Checked := FSetMain.KinectSeatedMode;
      if Assigned(FormCfg.edKinectMinDist) then
        FormCfg.edKinectMinDist.Text := FloatToStr(FSetMain.KinectMinDistance);
      if Assigned(FormCfg.edKinectMaxDist) then
        FormCfg.edKinectMaxDist.Text := FloatToStr(FSetMain.KinectMaxDistance);
      if Assigned(FormCfg.edKinectTargetLeft) then
        FormCfg.edKinectTargetLeft.Text := FSetMain.KinectTargetLeft;
      if Assigned(FormCfg.edKinectTargetRight) then
        FormCfg.edKinectTargetRight.Text := FSetMain.KinectTargetRight;
      if Assigned(FormCfg.edKinectTargetCenter) then
        FormCfg.edKinectTargetCenter.Text := FSetMain.KinectTargetCenter;

      if FormCfg.ShowModal = mrOk then
      begin
        // Salva JARVIS
        if Assigned(FormCfg.edJarvisURL) then
          FSetMain.JarvisURL := Trim(FormCfg.edJarvisURL.Text);
        if Assigned(FormCfg.edJarvisKey) then
          FSetMain.JarvisAPIKey := Trim(FormCfg.edJarvisKey.Text);
        if Assigned(FormCfg.cbJarvisMode) then
        begin
          case FormCfg.cbJarvisMode.ItemIndex of
            1: FSetMain.JarvisIAMode := 'local_only';
            2: FSetMain.JarvisIAMode := 'cloud_only';
          else
            FSetMain.JarvisIAMode := 'auto';
          end;
        end;
        if Assigned(FormCfg.chkMinimizeTray) then
          FSetMain.MinimizeToTray := FormCfg.chkMinimizeTray.Checked;
        if Assigned(FormCfg.chkAutoSpeak) then
          FSetMain.AutoSpeak := FormCfg.chkAutoSpeak.Checked;

        // Salva IA
        if Assigned(FormCfg.cbProvider) then
          FSetMain.ChatGPTProvider := FormCfg.cbProvider.ItemIndex;
        if Assigned(FormCfg.cbModel) then
          FSetMain.ChatGPTModel := Trim(FormCfg.cbModel.Text);
        if Assigned(FormCfg.edTokenGPT) then
          FSetMain.CHATGPT := Trim(FormCfg.edTokenGPT.Text);
        if Assigned(FormCfg.edURL) then
          FSetMain.ChatGPTURL := Trim(FormCfg.edURL.Text);

        // Salva Output Voice
        if Assigned(FormCfg.cbSynthEngine) then
          FSetMain.SynthEngine := FormCfg.cbSynthEngine.ItemIndex;
        if Assigned(FormCfg.cbSynthVoice) then
          FSetMain.SynthVoice := Trim(FormCfg.cbSynthVoice.Text);
        if Assigned(FormCfg.tbSynthVolume) then
          FSetMain.SynthVolume := FormCfg.tbSynthVolume.Position;
        if Assigned(FormCfg.tbSynthRate) then
          FSetMain.SynthRate := FormCfg.tbSynthRate.Position;
        if Assigned(FormCfg.chkSynthAsync) then
          FSetMain.SynthAsync := FormCfg.chkSynthAsync.Checked;

        // Salva Reconhecimento de Voz
        if Assigned(FormCfg.cbRecogEngine) then
          FSetMain.RecogEngine := FormCfg.cbRecogEngine.ItemIndex;
        if Assigned(FormCfg.edRecogLanguage) then
          FSetMain.RecogLanguage := Trim(FormCfg.edRecogLanguage.Text);
        if Assigned(FormCfg.cbAudioSampleRate) then
        begin
          if FormCfg.cbAudioSampleRate.ItemIndex = 1 then
            FSetMain.AudioSampleRate := 44100
          else
            FSetMain.AudioSampleRate := 16000;
        end;
        if Assigned(FormCfg.cbAudioChannels) then
        begin
          if FormCfg.cbAudioChannels.ItemIndex = 1 then
            FSetMain.AudioChannels := 2
          else
            FSetMain.AudioChannels := 1;
        end;

        // Salva Banco
        if Assigned(FormCfg.edMyHost) then FSetMain.HostnameMy := Trim(FormCfg.edMyHost.Text);
        if Assigned(FormCfg.edMyDb) then FSetMain.BancoMy := Trim(FormCfg.edMyDb.Text);
        if Assigned(FormCfg.edMyUser) then FSetMain.UsernameMy := Trim(FormCfg.edMyUser.Text);
        if Assigned(FormCfg.edMyPass) then FSetMain.PasswordMy := Trim(FormCfg.edMyPass.Text);
        if Assigned(FormCfg.edPostHost) then FSetMain.HostnamePost := Trim(FormCfg.edPostHost.Text);
        if Assigned(FormCfg.edPostDb) then FSetMain.BancoPOST := Trim(FormCfg.edPostDb.Text);
        if Assigned(FormCfg.edPostUser) then FSetMain.UsernamePost := Trim(FormCfg.edPostUser.Text);
        if Assigned(FormCfg.edPostPass) then FSetMain.PasswordPost := Trim(FormCfg.edPostPass.Text);
        if Assigned(FormCfg.edPostSchema) then FSetMain.SchemaPost := Trim(FormCfg.edPostSchema.Text);

        // Salva Visao / Kinect
        if Assigned(FormCfg.chkKinectEnabled) then
          FSetMain.KinectEnabled := FormCfg.chkKinectEnabled.Checked;
        if Assigned(FormCfg.chkKinectSeated) then
          FSetMain.KinectSeatedMode := FormCfg.chkKinectSeated.Checked;
        if Assigned(FormCfg.edKinectMinDist) then
          FSetMain.KinectMinDistance := StrToFloatDef(Trim(FormCfg.edKinectMinDist.Text), 0.8);
        if Assigned(FormCfg.edKinectMaxDist) then
          FSetMain.KinectMaxDistance := StrToFloatDef(Trim(FormCfg.edKinectMaxDist.Text), 3.5);
        if Assigned(FormCfg.edKinectTargetLeft) then
          FSetMain.KinectTargetLeft := Trim(FormCfg.edKinectTargetLeft.Text);
        if Assigned(FormCfg.edKinectTargetRight) then
          FSetMain.KinectTargetRight := Trim(FormCfg.edKinectTargetRight.Text);
        if Assigned(FormCfg.edKinectTargetCenter) then
          FSetMain.KinectTargetCenter := Trim(FormCfg.edKinectTargetCenter.Text);

        // Salva Avatar 3D
        if Assigned(FormCfg.edAvatarModel) then
          FSetMain.Avatar3DModel := Trim(FormCfg.edAvatarModel.Text);
        if Assigned(FormCfg.chkAvatarAutoIdle) then
          FSetMain.Avatar3DAutoIdle := FormCfg.chkAvatarAutoIdle.Checked;
        if Assigned(FormCfg.chkAvatarAutoBlink) then
          FSetMain.Avatar3DAutoBlink := FormCfg.chkAvatarAutoBlink.Checked;
        if Assigned(FormCfg.chkAvatarLipSync) then
          FSetMain.Avatar3DLipSync := FormCfg.chkAvatarLipSync.Checked;
        if Assigned(FormCfg.cbAvatarQuality) then
          FSetMain.Avatar3DQuality := Trim(FormCfg.cbAvatarQuality.Text);

        FSetMain.SalvaContexto(False);
        AplicaConfiguracoes();
        CarregaIcones();
        AdicionaMensagemHistorico('Configurações', 'Configurações salvas e aplicadas.');
      end;
    except
      on E: Exception do
        ShowMessage('Erro ao carregar formulário de configurações: ' + E.Message);
    end;
  finally
    FormCfg.Free;
  end;
end;

procedure Tfrmmain."""

if m:
    pas_text = pas_text[:m.start()] + new_proc + pas_text[m.end():]
    with open(main_pas_path, "w", encoding="utf-8") as f:
        f.write(pas_text)
    print("main.pas btAbrirConfigClick atualizado com proteções defensivas completas.")
else:
    print("Erro: não foi possível localizar btAbrirConfigClick em main.pas.")

print("Concluído.")
