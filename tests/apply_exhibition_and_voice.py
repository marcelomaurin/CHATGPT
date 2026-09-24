import os
import re

print("Starting layout and voice integration in Assistente...")

setmain_path = r"P:\maurinsoft\Assistente\src\setmain.pas"
main_lfm_path = r"P:\maurinsoft\Assistente\src\main.lfm"
main_pas_path = r"P:\maurinsoft\Assistente\src\main.pas"

# -------------------------------------------------------------
# 1. Update setmain.pas
# -------------------------------------------------------------
with open(setmain_path, "r", encoding="latin1") as f:
    setmain_content = f.read()

# Add aivoicecredentialstore to uses if not present
if "aivoicecredentialstore" not in setmain_content:
    setmain_content = setmain_content.replace(
        "uses\n  Classes, SysUtils, funcoes, graphics;",
        "uses\n  Classes, SysUtils, funcoes, graphics, aivoicecredentialstore;"
    )

# Add voice fields if not present
if "FVoiceAPIToken" not in setmain_content:
    fields_target = "        FSynthAsync : boolean;"
    fields_addition = """        FSynthAsync : boolean;

        // Provedor Remoto de Voz (TAIVoiceSynthesizer)
        FVoiceProvider : integer;
        FVoiceAPIToken : String;
        FVoiceModel : String;
        FVoiceEndpoint : String;
        FVoiceRemoteVoice : String;
        FVoiceLanguage : String;
        FVoiceOutputFormat : String;
        FVoiceSpeed : Double;"""
    setmain_content = setmain_content.replace(fields_target, fields_addition)

# Add voice properties if not present
if "property VoiceAPIToken" not in setmain_content:
    prop_target = "        property SynthAsync : boolean read FSynthAsync write FSynthAsync;"
    prop_addition = """        property SynthAsync : boolean read FSynthAsync write FSynthAsync;

        property VoiceProvider : integer read FVoiceProvider write FVoiceProvider;
        property VoiceAPIToken : String read FVoiceAPIToken write FVoiceAPIToken;
        property VoiceModel : String read FVoiceModel write FVoiceModel;
        property VoiceEndpoint : String read FVoiceEndpoint write FVoiceEndpoint;
        property VoiceRemoteVoice : String read FVoiceRemoteVoice write FVoiceRemoteVoice;
        property VoiceLanguage : String read FVoiceLanguage write FVoiceLanguage;
        property VoiceOutputFormat : String read FVoiceOutputFormat write FVoiceOutputFormat;
        property VoiceSpeed : Double read FVoiceSpeed write FVoiceSpeed;"""
    setmain_content = setmain_content.replace(prop_target, prop_addition)

# Constructor defaults
if "FVoiceProvider := 0;" not in setmain_content:
    ctor_target = "    FSynthAsync := true;"
    ctor_addition = """    FSynthAsync := true;

    FVoiceProvider := 0;
    FVoiceAPIToken := '';
    FVoiceModel := 'gpt-4o-mini-tts';
    FVoiceEndpoint := 'https://api.openai.com/v1/audio/speech';
    FVoiceRemoteVoice := 'alloy';
    FVoiceLanguage := 'pt-BR';
    FVoiceOutputFormat := 'mp3';
    FVoiceSpeed := 1.0;"""
    setmain_content = setmain_content.replace(ctor_target, ctor_addition)

# CarregaContexto
if "BuscaChave(arquivo,'VOICEAPITOKEN:'" not in setmain_content:
    carrega_target = "    if  BuscaChave(arquivo,'SYNTHASYNC:',posicao) then\n    begin\n      FSynthAsync := (RetiraInfo(arquivo.Strings[posicao]) <> '0');\n    end;"
    carrega_addition = """    if  BuscaChave(arquivo,'SYNTHASYNC:',posicao) then
    begin
      FSynthAsync := (RetiraInfo(arquivo.Strings[posicao]) <> '0');
    end;

    if  BuscaChave(arquivo,'VOICEPROVIDER:',posicao) then
      FVoiceProvider := strtointdef(RetiraInfo(arquivo.Strings[posicao]), 0);
    if  BuscaChave(arquivo,'VOICEAPITOKEN:',posicao) then
      FVoiceAPIToken := TVoiceCredentialStore.UnprotectToken(RetiraInfo(arquivo.Strings[posicao]));
    if  BuscaChave(arquivo,'VOICEMODEL:',posicao) then
      FVoiceModel := RetiraInfo(arquivo.Strings[posicao]);
    if  BuscaChave(arquivo,'VOICEENDPOINT:',posicao) then
      FVoiceEndpoint := RetiraInfo(arquivo.Strings[posicao]);
    if  BuscaChave(arquivo,'VOICEREMOTEVOICE:',posicao) then
      FVoiceRemoteVoice := RetiraInfo(arquivo.Strings[posicao]);
    if  BuscaChave(arquivo,'VOICELANGUAGE:',posicao) then
      FVoiceLanguage := RetiraInfo(arquivo.Strings[posicao]);
    if  BuscaChave(arquivo,'VOICEOUTPUTFORMAT:',posicao) then
      FVoiceOutputFormat := RetiraInfo(arquivo.Strings[posicao]);
    if  BuscaChave(arquivo,'VOICESPEED:',posicao) then
      FVoiceSpeed := strtofloatdef(StringReplace(RetiraInfo(arquivo.Strings[posicao]), ',', '.', []), 1.0);

    // Migracao/fallback de configuracao antiga (tarefa 27)
    if (Trim(FVoiceAPIToken) = '') and (FSynthEngine = 3) and (Trim(FCHATGPT) <> '') then
    begin
      FVoiceAPIToken := FCHATGPT;
      FVoiceProvider := 1;
    end;"""
    setmain_content = setmain_content.replace(carrega_target, carrega_addition)

# SalvaContexto
if "'VOICEAPITOKEN:'" not in setmain_content:
    salva_target = "  arquivo.Append('SYNTHASYNC:'+iif(FSynthAsync, '1', '0'));"
    salva_addition = """  arquivo.Append('SYNTHASYNC:'+iif(FSynthAsync, '1', '0'));
  arquivo.Append('VOICEPROVIDER:'+inttostr(FVoiceProvider));
  arquivo.Append('VOICEAPITOKEN:'+TVoiceCredentialStore.ProtectToken(FVoiceAPIToken));
  arquivo.Append('VOICEMODEL:'+FVoiceModel);
  arquivo.Append('VOICEENDPOINT:'+FVoiceEndpoint);
  arquivo.Append('VOICEREMOTEVOICE:'+FVoiceRemoteVoice);
  arquivo.Append('VOICELANGUAGE:'+FVoiceLanguage);
  arquivo.Append('VOICEOUTPUTFORMAT:'+FVoiceOutputFormat);
  arquivo.Append('VOICESPEED:'+floattostr(FVoiceSpeed));"""
    setmain_content = setmain_content.replace(salva_target, salva_addition)

with open(setmain_path, "w", encoding="latin1") as f:
    f.write(setmain_content)
print("setmain.pas updated successfully.")

# -------------------------------------------------------------
# 2. Update main.lfm
# -------------------------------------------------------------
# We rewrite main.lfm to cleanly contain pnlRoot (Exhibition) and pnlAdminRoot (Hidden Admin)
lfm_content = """object frmmain: Tfrmmain
  Left = 250
  Height = 720
  Top = 80
  Width = 1100
  Caption = 'Professor Virtual - FATEC Ribeirão Preto'
  ClientHeight = 720
  ClientWidth = 1100
  Color = 1183760
  KeyPreview = True
  LCLVersion = '4.4.0.0'
  OnClose = FormClose
  OnCreate = FormCreate
  OnKeyDown = FormKeyDown
  OnResize = FormResize
  Position = poScreenCenter
  object pnlRoot: TPanel
    Left = 0
    Height = 720
    Top = 0
    Width = 1100
    Align = alClient
    BevelOuter = bvNone
    Color = 1183760
    DoubleBuffered = True
    ParentBackground = False
    ParentColor = False
    TabOrder = 0
    object pnlHeader: TPanel
      Left = 0
      Height = 56
      Top = 0
      Width = 1100
      Align = alTop
      BevelOuter = bvNone
      Color = 1446934
      DoubleBuffered = True
      OnDblClick = pnlHeaderDblClick
      ParentBackground = False
      ParentColor = False
      TabOrder = 0
      object lblInstitution: TLabel
        Left = 24
        Height = 25
        Top = 15
        Width = 240
        Caption = 'FATEC RIBEIRÃO PRETO'
        Font.Color = 4243711
        Font.Height = -18
        Font.Style = [fsBold]
        OnDblClick = pnlHeaderDblClick
        ParentColor = False
        ParentFont = False
      end
      object lblAppTitle: TLabel
        Left = 870
        Height = 25
        Top = 15
        Width = 206
        Alignment = taRightJustify
        Anchors = [akTop, akRight]
        Caption = 'PROFESSOR VIRTUAL'
        Font.Color = clWhite
        Font.Height = -18
        Font.Style = [fsBold]
        OnDblClick = pnlHeaderDblClick
        ParentColor = False
        ParentFont = False
      end
    end
    object pnlFooter: TPanel
      Left = 0
      Height = 44
      Top = 676
      Width = 1100
      Align = alBottom
      BevelOuter = bvNone
      Color = 1446934
      DoubleBuffered = True
      ParentBackground = False
      ParentColor = False
      TabOrder = 1
      object lblProfessorStatus: TLabel
        Left = 0
        Height = 44
        Top = 0
        Width = 1100
        Align = alClient
        Alignment = taCenter
        Layout = tlCenter
        Caption = '● Pronto para conversar'
        Font.Color = 65433
        Font.Height = -14
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
      end
    end
    object pnlMain: TPanel
      Left = 0
      Height = 620
      Top = 56
      Width = 1100
      Align = alClient
      BevelOuter = bvNone
      Color = 1183760
      DoubleBuffered = True
      ParentBackground = False
      ParentColor = False
      TabOrder = 2
      object pnlAvatarStage: TPanel
        Left = 0
        Height = 620
        Top = 0
        Width = 420
        Align = alLeft
        BevelOuter = bvNone
        Color = 1315348
        DoubleBuffered = True
        ParentBackground = False
        ParentColor = False
        TabOrder = 0
        object imgAvatarStage: TImage
          Left = 0
          Height = 620
          Top = 0
          Width = 420
          Align = alClient
          Center = True
          Proportional = True
          Stretch = True
        end
      end
      object pnlPresentationArea: TPanel
        Left = 420
        Height = 620
        Top = 0
        Width = 680
        Align = alClient
        BevelOuter = bvNone
        Color = 1183760
        DoubleBuffered = True
        ParentBackground = False
        ParentColor = False
        TabOrder = 1
        object pnlProjectHeader: TPanel
          Left = 0
          Height = 72
          Top = 0
          Width = 680
          Align = alTop
          BevelOuter = bvNone
          Color = 1183760
          DoubleBuffered = True
          ParentBackground = False
          ParentColor = False
          TabOrder = 0
          object lblProjectTitle: TLabel
            Left = 24
            Height = 32
            Top = 8
            Width = 630
            Anchors = [akTop, akLeft, akRight]
            Caption = 'PROJETO ECG'
            Font.Color = clWhite
            Font.Height = -24
            Font.Style = [fsBold]
            ParentColor = False
            ParentFont = False
          end
          object lblTopicSubtitle: TLabel
            Left = 24
            Height = 20
            Top = 44
            Width = 630
            Anchors = [akTop, akLeft, akRight]
            Caption = 'Aquisição do sinal cardíaco e inteligência artificial'
            Font.Color = 13421772
            Font.Height = -14
            ParentColor = False
            ParentFont = False
          end
        end
        object pnlNarrativeContainer: TPanel
          Left = 0
          Height = 88
          Top = 532
          Width = 680
          Align = alBottom
          BevelOuter = bvNone
          Color = 1446934
          DoubleBuffered = True
          ParentBackground = False
          ParentColor = False
          TabOrder = 1
          object lblNarrative: TLabel
            Left = 20
            Height = 68
            Top = 10
            Width = 640
            Align = alClient
            BorderSpacing.Around = 10
            Caption = '"Aproxime-se para conhecer os projetos desenvolvidos pelos nossos pesquisadores..."'
            Font.Color = clWhite
            Font.Height = -16
            Layout = tlCenter
            ParentColor = False
            ParentFont = False
            WordWrap = True
          end
        end
        object pnlResourceHolder: TPanel
          Left = 0
          Height = 460
          Top = 72
          Width = 680
          Align = alClient
          BevelOuter = bvNone
          Color = 1052688
          DoubleBuffered = True
          BorderSpacing.Around = 12
          ParentBackground = False
          ParentColor = False
          TabOrder = 2
          object imgResource: TImage
            Left = 0
            Height = 428
            Top = 0
            Width = 656
            Align = alClient
            Center = True
            Proportional = True
            Stretch = True
          end
          object lblResourceCaption: TLabel
            Left = 0
            Height = 28
            Top = 428
            Width = 656
            Align = alBottom
            Alignment = taCenter
            Layout = tlCenter
            Caption = ''
            Font.Color = 10066329
            Font.Height = -13
            ParentColor = False
            ParentFont = False
          end
          object lblResourcePlaceholder: TLabel
            Left = 0
            Height = 428
            Top = 0
            Width = 656
            Align = alClient
            Alignment = taCenter
            Layout = tlCenter
            Caption = 'Professor Virtual FATEC Ribeirão Preto'#13#10'Aproxime-se para interagir'
            Font.Color = 4473924
            Font.Height = -20
            Font.Style = [fsBold]
            ParentColor = False
            ParentFont = False
          end
        end
      end
    end
  end
  object pnlAdminRoot: TPanel
    Left = 0
    Height = 720
    Top = 0
    Width = 1100
    Align = alClient
    BevelOuter = bvNone
    Color = 1052688
    TabOrder = 1
    Visible = False
    object pnlSidebar: TPanel
      Left = 0
      Height = 720
      Top = 0
      Width = 240
      Align = alLeft
      BevelOuter = bvNone
      Color = 1381653
      ClientHeight = 720
      ClientWidth = 240
      ParentBackground = False
      ParentColor = False
      TabOrder = 0
      object lblProjetosHeader: TLabel
        Left = 12
        Height = 16
        Top = 12
        Width = 216
        AutoSize = False
        Caption = '📁 PROJETOS ATIVOS'
        Font.Color = clWhite
        Font.Height = -12
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
      end
      object lstProjetos: TListBox
        Left = 10
        Height = 220
        Top = 36
        Width = 220
        Color = 1052688
        Font.Color = clWhite
        Font.Height = -12
        ItemHeight = 26
        OnSelectionChange = lstProjetosSelectionChange
        ParentFont = False
        TabOrder = 0
      end
      object lblMemoriaHeader: TLabel
        Left = 12
        Height = 16
        Top = 270
        Width = 216
        AutoSize = False
        Caption = '🧠 CONTEXTO & MEMÓRIA'
        Font.Color = clWhite
        Font.Height = -12
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
      end
      object memProjetoInfo: TMemo
        Left = 10
        Height = 420
        Top = 292
        Width = 220
        Align = alCustom
        Color = 1052688
        Font.Color = 13421772
        Font.Height = -11
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 1
      end
    end
    object pnlTop: TPanel
      Left = 240
      Height = 150
      Top = 0
      Width = 860
      Align = alTop
      BevelOuter = bvNone
      Color = 1579032
      ClientHeight = 150
      ClientWidth = 860
      ParentBackground = False
      ParentColor = False
      TabOrder = 1
      object imgAvatar: TImage
        Left = 14
        Height = 122
        Top = 14
        Width = 122
        Center = True
        Proportional = True
        Stretch = True
      end
      object pnlTopControls: TPanel
        Left = 150
        Height = 150
        Top = 0
        Width = 710
        Align = alClient
        BevelOuter = bvNone
        ClientHeight = 150
        ClientWidth = 710
        TabOrder = 0
        object lblJarvisStatusBadge: TLabel
          Left = 10
          Height = 18
          Top = 14
          Width = 450
          AutoSize = False
          Caption = '● PAINEL ADMINISTRATIVO & DEBUG'
          Font.Color = 3407616
          Font.Height = -12
          Font.Style = [fsBold]
          ParentColor = False
          ParentFont = False
        end
        object lblJarvisSub: TLabel
          Left = 10
          Height = 16
          Top = 34
          Width = 450
          AutoSize = False
          Caption = 'Configurações Técnicas e Logs'
          Font.Color = 11184810
          Font.Height = -11
          ParentColor = False
          ParentFont = False
        end
        object btIniciar: TBitBtn
          Left = 10
          Height = 32
          Top = 58
          Width = 120
          Caption = '▶ Ouvir Voz'
          Font.Style = [fsBold]
          OnClick = btIniciarClick
          ParentFont = False
          TabOrder = 0
        end
        object btAbrirConfig: TBitBtn
          Left = 140
          Height = 32
          Top = 58
          Width = 120
          Caption = '⚙ Configurar'
          OnClick = btAbrirConfigClick
          TabOrder = 1
        end
        object btVoltarExposicao: TBitBtn
          Left = 270
          Height = 32
          Top = 58
          Width = 160
          Caption = '🖥 Voltar à Exposição'
          Font.Style = [fsBold]
          OnClick = btVoltarExposicaoClick
          TabOrder = 2
        end
        object btStatusResidencia: TButton
          Left = 10
          Height = 28
          Top = 98
          Width = 120
          Caption = '🛡️ Status Geral'
          OnClick = btStatusResidenciaClick
          TabOrder = 3
        end
        object btClima: TButton
          Left = 140
          Height = 28
          Top = 98
          Width = 120
          Caption = '☀️ Clima & Chuva'
          OnClick = btClimaClick
          TabOrder = 4
        end
      end
    end
    object pnlQuickBar: TPanel
      Left = 240
      Height = 38
      Top = 150
      Width = 860
      Align = alTop
      BevelOuter = bvNone
      Color = 2368548
      ClientHeight = 38
      ClientWidth = 860
      ParentBackground = False
      ParentColor = False
      TabOrder = 2
      object lblQuick: TLabel
        Left = 12
        Height = 14
        Top = 12
        Width = 85
        Caption = 'Atalhos Rápidos:'
        Font.Color = 13421772
        Font.Height = -11
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
      end
      object btLuzSala: TButton
        Left = 105
        Height = 26
        Top = 6
        Width = 105
        Caption = '💡 Luz Sala'
        OnClick = btLuzSalaClick
        TabOrder = 0
      end
      object btIrrigacao: TButton
        Left = 216
        Height = 26
        Top = 6
        Width = 115
        Caption = '💧 Piscina'
        OnClick = btIrrigacaoClick
        TabOrder = 1
      end
      object btAuditarSeguranca: TButton
        Left = 337
        Height = 26
        Top = 6
        Width = 112
        Caption = '🔒 Firewall'
        OnClick = btAuditarSegurancaClick
        TabOrder = 2
      end
    end
    object pnlChat: TPanel
      Left = 240
      Height = 392
      Top = 188
      Width = 860
      Align = alClient
      BevelOuter = bvNone
      ClientHeight = 392
      ClientWidth = 860
      Color = 1381653
      ParentBackground = False
      ParentColor = False
      TabOrder = 3
      object pnlHistoricoHeader: TPanel
        Left = 0
        Height = 32
        Top = 0
        Width = 860
        Align = alTop
        BevelOuter = bvNone
        Color = 1710618
        ClientHeight = 32
        ClientWidth = 860
        ParentBackground = False
        ParentColor = False
        TabOrder = 0
        object lblHistorico: TLabel
          Left = 12
          Height = 15
          Top = 8
          Width = 133
          Caption = 'Histórico de Interação:'
          Font.Color = clWhite
          Font.Style = [fsBold]
          ParentColor = False
          ParentFont = False
        end
        object btSpeaker: TBitBtn
          Left = 740
          Height = 24
          Top = 4
          Width = 105
          Anchors = [akTop, akRight]
          Caption = '🔊 Voz ON'
          OnClick = btSpeakerClick
          TabOrder = 0
        end
        object btLimparChat: TButton
          Left = 650
          Height = 24
          Top = 4
          Width = 80
          Anchors = [akTop, akRight]
          Caption = 'Limpar'
          OnClick = btLimparChatClick
          TabOrder = 1
        end
      end
      object memHistorico: TMemo
        Left = 0
        Height = 360
        Top = 32
        Width = 860
        Align = alClient
        Color = 1052688
        Font.Color = 15724527
        Font.Height = -12
        Font.Name = 'Segoe UI'
        ParentFont = False
        ReadOnly = True
        ScrollBars = ssVertical
        TabOrder = 1
      end
    end
    object pnlPergunta: TPanel
      Left = 240
      Height = 140
      Top = 580
      Width = 860
      Align = alBottom
      BevelOuter = bvNone
      Color = 1579032
      ClientHeight = 140
      ClientWidth = 860
      ParentBackground = False
      ParentColor = False
      TabOrder = 4
      object lblPergunta: TLabel
        Left = 12
        Height = 15
        Top = 8
        Width = 175
        Caption = 'Comando em Linguagem Natural:'
        Font.Color = 13421772
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
      end
      object memPergunta: TMemo
        Left = 12
        Height = 90
        Top = 28
        Width = 670
        Anchors = [akTop, akLeft, akRight, akBottom]
        Color = 1052688
        Font.Color = clWhite
        Font.Height = -12
        OnKeyPress = memPerguntaKeyPress
        ParentFont = False
        ScrollBars = ssVertical
        TabOrder = 0
      end
      object btEnviar: TBitBtn
        Left = 690
        Height = 42
        Top = 28
        Width = 75
        Anchors = [akTop, akRight]
        Caption = '✈ Enviar'
        Font.Color = clWhite
        Font.Style = [fsBold]
        OnClick = btEnviarClick
        ParentFont = False
        TabOrder = 1
      end
      object btParar: TBitBtn
        Left = 770
        Height = 42
        Top = 28
        Width = 75
        Anchors = [akTop, akRight]
        Caption = '■ Parar'
        Font.Color = clRed
        Font.Style = [fsBold]
        OnClick = btPararClick
        ParentFont = False
        TabOrder = 2
      end
      object btAnexar: TBitBtn
        Left = 690
        Height = 42
        Top = 76
        Width = 75
        Anchors = [akTop, akRight]
        Caption = '📎 Anexar'
        OnClick = btAnexarClick
        TabOrder = 3
      end
      object btMic: TBitBtn
        Left = 770
        Height = 42
        Top = 76
        Width = 75
        Anchors = [akTop, akRight]
        Caption = '🎤 Falar'
        OnClick = btMicClick
        TabOrder = 4
      end
    end
  end
  object tmrCheckOnline: TTimer
    Enabled = True
    Interval = 30000
    OnTimer = tmrCheckOnlineTimer
    Left = 270
    Top = 216
  end
  object trayIcon: TTrayIcon
    Hint = 'Maurinsoft Assistente'
    PopupMenu = pmTray
    OnClick = trayIconClick
    Left = 330
    Top = 216
  end
  object pmTray: TPopupMenu
    Left = 390
    Top = 216
    object miAbrir: TMenuItem
      Caption = 'Abrir Painel'
      Default = True
      OnClick = miAbrirClick
    end
    object miStatus: TMenuItem
      Caption = 'Status da Casa'
      OnClick = btStatusResidenciaClick
    end
    object miLuzSala: TMenuItem
      Caption = 'Ligar/Desligar Luz Sala'
      OnClick = btLuzSalaClick
    end
    object miSep1: TMenuItem
      Caption = '-'
    end
    object miConfig: TMenuItem
      Caption = 'Configurações...'
      OnClick = btAbrirConfigClick
    end
    object miSep2: TMenuItem
      Caption = '-'
    end
    object miSair: TMenuItem
      Caption = 'Sair'
      OnClick = miSairClick
    end
  end
  object OpenDialogFiles: TOpenDialog
    Title = 'Vincular Arquivo ao Projeto'
    Filter = 'Todos os Arquivos (*.*)|*.*|Documentos (*.pdf;*.docx;*.txt;*.csv;*.json;*.log)|*.pdf;*.docx;*.txt;*.csv;*.json;*.log|Código-Fonte (*.pas;*.cpp;*.py;*.sql)|*.pas;*.cpp;*.py;*.sql'
    Left = 450
    Top = 216
  end
end
"""
with open(main_lfm_path, "w", encoding="utf-8") as f:
    f.write(lfm_content)
print("main.lfm updated successfully.")

# -------------------------------------------------------------
# 3. Update main.pas
# -------------------------------------------------------------
with open(main_pas_path, "r", encoding="utf-8") as f:
    main_pas_content = f.read()

# Add LCLType, aivoiceprovider_types to uses
if "LCLType" not in main_pas_content:
    main_pas_content = main_pas_content.replace(
        "uses\n  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,",
        "uses\n  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls, LCLType,"
    )
if "aivoiceprovider_types" not in main_pas_content:
    main_pas_content = main_pas_content.replace(
        "aivoicesynthesizer,",
        "aivoiceprovider_types, aivoicesynthesizer,"
    )

# Published fields in Tfrmmain
published_components = """    { Modo Exposicao / Professor Virtual (Publico) }
    pnlRoot: TPanel;
    pnlHeader: TPanel;
    lblInstitution: TLabel;
    lblAppTitle: TLabel;
    pnlFooter: TPanel;
    lblProfessorStatus: TLabel;
    pnlMain: TPanel;
    pnlAvatarStage: TPanel;
    imgAvatarStage: TImage;
    pnlPresentationArea: TPanel;
    pnlProjectHeader: TPanel;
    lblProjectTitle: TLabel;
    lblTopicSubtitle: TLabel;
    pnlNarrativeContainer: TPanel;
    lblNarrative: TLabel;
    pnlResourceHolder: TPanel;
    imgResource: TImage;
    lblResourceCaption: TLabel;
    lblResourcePlaceholder: TLabel;

    { Modo Administrativo (Oculto) }
    pnlAdminRoot: TPanel;
    btVoltarExposicao: TBitBtn;
"""

if "pnlRoot: TPanel;" not in main_pas_content:
    main_pas_content = main_pas_content.replace(
        "  Tfrmmain = class(TForm)\n",
        "  Tfrmmain = class(TForm)\n" + published_components
    )

# Published procedures
published_procs = """    procedure FormResize(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure pnlHeaderDblClick(Sender: TObject);
    procedure btVoltarExposicaoClick(Sender: TObject);
"""
if "procedure FormResize" not in main_pas_content:
    main_pas_content = main_pas_content.replace(
        "    procedure FormCreate(Sender: TObject);\n",
        "    procedure FormCreate(Sender: TObject);\n" + published_procs
    )

# Private methods
private_methods = """    procedure UpdateExhibitionLayout;
    procedure EnterExhibitionMode;
    procedure EnterAdminMode;
    procedure ExitAdminMode;
    procedure ShowPresentationResource(const ATitle, ASubtitle, AImagePath, ANarrative: string);
    procedure ClearPresentationResource;
    procedure SetProfessorState(const AState: string);
    procedure SetNarrativeText(const AText: string);
    procedure OnVoiceSpeechStart(Sender: TObject);
    procedure OnVoiceSpeechEnd(Sender: TObject);
"""
if "procedure UpdateExhibitionLayout;" not in main_pas_content:
    main_pas_content = main_pas_content.replace(
        "    procedure InitExposicaoUI;\n",
        "    procedure InitExposicaoUI;\n" + private_methods
    )

# Implementation methods to inject
methods_impl = """
procedure Tfrmmain.FormResize(Sender: TObject);
begin
  UpdateExhibitionLayout;
end;

procedure Tfrmmain.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  // Atalho secreto Ctrl+Alt+A para alternar entre Exposição e Administração
  if (ssCtrl in Shift) and (ssAlt in Shift) and ((Key = VK_A) or (Key = ord('A')) or (Key = ord('a'))) then
  begin
    if Assigned(pnlAdminRoot) and pnlAdminRoot.Visible then
      ExitAdminMode
    else
      EnterAdminMode;
    Key := 0;
  end;
end;

procedure Tfrmmain.pnlHeaderDblClick(Sender: TObject);
begin
  if Assigned(pnlAdminRoot) and pnlAdminRoot.Visible then
    ExitAdminMode
  else
    EnterAdminMode;
end;

procedure Tfrmmain.btVoltarExposicaoClick(Sender: TObject);
begin
  ExitAdminMode;
end;

procedure Tfrmmain.UpdateExhibitionLayout;
var
  AvWidth: Integer;
begin
  if not Assigned(pnlMain) or not Assigned(pnlAvatarStage) then Exit;
  // Avatar ocupa ~38% da tela, conteúdo ocupa ~62%
  AvWidth := Round(pnlMain.ClientWidth * 0.38);
  if AvWidth < 280 then AvWidth := 280;
  if AvWidth > 620 then AvWidth := 620;
  pnlAvatarStage.Width := AvWidth;
end;

procedure Tfrmmain.EnterExhibitionMode;
begin
  if Assigned(pnlAdminRoot) then
    pnlAdminRoot.Visible := False;
  if Assigned(pnlRoot) then
    pnlRoot.Visible := True;
  UpdateExhibitionLayout;
  SetProfessorState('idle');
end;

procedure Tfrmmain.EnterAdminMode;
begin
  if Assigned(pnlRoot) then
    pnlRoot.Visible := False;
  if Assigned(pnlAdminRoot) then
    pnlAdminRoot.Visible := True;
end;

procedure Tfrmmain.ExitAdminMode;
begin
  EnterExhibitionMode;
end;

procedure Tfrmmain.SetNarrativeText(const AText: string);
var
  CleanText: string;
begin
  CleanText := Trim(AText);
  if not Assigned(lblNarrative) then Exit;
  if CleanText = '' then
    lblNarrative.Caption := ''
  else
  begin
    if Length(CleanText) > 240 then
      CleanText := Copy(CleanText, 1, 237) + '...';
    lblNarrative.Caption := '"' + CleanText + '"';
  end;
end;

procedure Tfrmmain.SetProfessorState(const AState: string);
var
  S: string;
begin
  if not Assigned(lblProfessorStatus) then Exit;
  S := LowerCase(Trim(AState));
  if (S = 'listening') or (S = 'ouvir') or (S = 'ouvindo') then
  begin
    lblProfessorStatus.Font.Color := $0000FF99;
    lblProfessorStatus.Caption := '🎤 Ouvindo o visitante...';
    if FAvatar3D <> nil then
      FAvatar3D.SetState(avListening);
  end
  else if (S = 'thinking') or (S = 'pensando') then
  begin
    lblProfessorStatus.Font.Color := $00FFC040;
    lblProfessorStatus.Caption := '🧠 Pensando na resposta...';
    if FAvatar3D <> nil then
      FAvatar3D.SetState(avThinking);
  end
  else if (S = 'presenting') or (S = 'apresentando') or (S = 'speaking') or (S = 'falando') then
  begin
    lblProfessorStatus.Font.Color := $0000D4FF;
    lblProfessorStatus.Caption := '🗣️ Apresentando conteúdo...';
    if FAvatar3D <> nil then
      FAvatar3D.SetState(avSpeaking);
  end
  else if (S = 'greeting') or (S = 'saudacao') then
  begin
    lblProfessorStatus.Font.Color := $00FFAA00;
    lblProfessorStatus.Caption := '👋 Boas-vindas ao visitante!';
    if FAvatar3D <> nil then
    begin
      FAvatar3D.SetState(avActing);
      FAvatar3D.PlayGesture(agWave, 2.0);
    end;
  end
  else if (S = 'error') or (S = 'erro') then
  begin
    lblProfessorStatus.Font.Color := $005050FF;
    lblProfessorStatus.Caption := '⚠️ Aguardando interação...';
  end
  else
  begin
    lblProfessorStatus.Font.Color := $0000FF99;
    lblProfessorStatus.Caption := '● Pronto para conversar';
    if FAvatar3D <> nil then
      FAvatar3D.SetState(avIdle);
  end;
end;

procedure Tfrmmain.ShowPresentationResource(const ATitle, ASubtitle, AImagePath, ANarrative: string);
begin
  if Assigned(lblProjectTitle) and (Trim(ATitle) <> '') then
  begin
    lblProjectTitle.Caption := UpperCase(Trim(ATitle));
    lblProjectTitle.Visible := True;
  end;
  if Assigned(lblTopicSubtitle) and (Trim(ASubtitle) <> '') then
  begin
    lblTopicSubtitle.Caption := Trim(ASubtitle);
    lblTopicSubtitle.Visible := True;
  end;
  if Trim(ANarrative) <> '' then
    SetNarrativeText(ANarrative);

  if Assigned(imgResource) and (Trim(AImagePath) <> '') and FileExists(AImagePath) then
  begin
    try
      imgResource.Picture.LoadFromFile(AImagePath);
      imgResource.Visible := True;
      if Assigned(lblResourcePlaceholder) then
        lblResourcePlaceholder.Visible := False;
      if Assigned(lblResourceCaption) then
      begin
        lblResourceCaption.Caption := Trim(ATitle) + ' - ' + Trim(ASubtitle);
        lblResourceCaption.Visible := True;
      end;
    except
      imgResource.Visible := False;
      if Assigned(lblResourcePlaceholder) then
        lblResourcePlaceholder.Visible := True;
      if Assigned(lblResourceCaption) then
        lblResourceCaption.Visible := False;
    end;
  end
  else
  begin
    if Assigned(imgResource) then
      imgResource.Visible := False;
    if Assigned(lblResourcePlaceholder) then
      lblResourcePlaceholder.Visible := True;
    if Assigned(lblResourceCaption) then
      lblResourceCaption.Visible := False;
  end;
end;

procedure Tfrmmain.ClearPresentationResource;
begin
  if Assigned(imgResource) then
  begin
    imgResource.Picture.Clear;
    imgResource.Visible := False;
  end;
  if Assigned(lblResourcePlaceholder) then
    lblResourcePlaceholder.Visible := True;
  if Assigned(lblResourceCaption) then
  begin
    lblResourceCaption.Caption := '';
    lblResourceCaption.Visible := False;
  end;
  if Assigned(lblProjectTitle) then
    lblProjectTitle.Caption := 'PROFESSOR VIRTUAL';
  if Assigned(lblTopicSubtitle) then
    lblTopicSubtitle.Caption := 'Projetos desenvolvidos na FATEC Ribeirão Preto';
  SetNarrativeText('Aproxime-se para conhecer os projetos desenvolvidos pelos nossos pesquisadores...');
end;

procedure Tfrmmain.OnVoiceSpeechStart(Sender: TObject);
begin
  if FAvatar3D <> nil then
    FAvatar3D.SetState(avSpeaking);
  SetProfessorState('presenting');
end;

procedure Tfrmmain.OnVoiceSpeechEnd(Sender: TObject);
begin
  if FAvatar3D <> nil then
    FAvatar3D.SetState(avIdle);
  SetProfessorState('idle');
end;
"""

if "procedure Tfrmmain.UpdateExhibitionLayout;" not in main_pas_content:
    # Inject before Tfrmmain.InitExposicaoUI
    main_pas_content = main_pas_content.replace(
        "procedure Tfrmmain.InitExposicaoUI;\n",
        methods_impl + "\nprocedure Tfrmmain.InitExposicaoUI;\n"
    )

# Update OnPresentationResourceSelected to use ShowPresentationResource
old_on_resource = """procedure Tfrmmain.OnPresentationResourceSelected(Sender: TObject; AResource: TPresentationResource);
var
  ImgFile: string;
begin
  if AResource = nil then Exit;
  lblRecursoDescricao.Caption := 'Recurso Selecionado: ' + AResource.Title + ' - ' + AResource.Description;

  ImgFile := AResource.FilePath;
  if not FileExists(ImgFile) then
    ImgFile := ExtractFilePath(Application.ExeName) + AResource.FilePath;
  if not FileExists(ImgFile) then
    ImgFile := ExtractFilePath(Application.ExeName) + 'img' + PathDelim + ExtractFileName(AResource.FilePath);
  if not FileExists(ImgFile) then
    ImgFile := 'D:\\projetos\\maurinsoft\\Assistente\\img\\' + ExtractFileName(AResource.FilePath);

  if FileExists(ImgFile) and (imgRecursoExposicao <> nil) then
  begin
    try
      imgRecursoExposicao.Picture.LoadFromFile(ImgFile);
    except
    end;
  end;
end;"""

new_on_resource = """procedure Tfrmmain.OnPresentationResourceSelected(Sender: TObject; AResource: TPresentationResource);
var
  ImgFile: string;
begin
  if AResource = nil then Exit;
  if Assigned(lblRecursoDescricao) then
    lblRecursoDescricao.Caption := 'Recurso Selecionado: ' + AResource.Title + ' - ' + AResource.Description;

  ImgFile := AResource.FilePath;
  if not FileExists(ImgFile) then
    ImgFile := ExtractFilePath(Application.ExeName) + AResource.FilePath;
  if not FileExists(ImgFile) then
    ImgFile := ExtractFilePath(Application.ExeName) + 'img' + PathDelim + ExtractFileName(AResource.FilePath);
  if not FileExists(ImgFile) then
    ImgFile := 'D:\\projetos\\maurinsoft\\Assistente\\img\\' + ExtractFileName(AResource.FilePath);

  ShowPresentationResource(AResource.Title, AResource.Description, ImgFile, '');
end;"""

main_pas_content = main_pas_content.replace(old_on_resource, new_on_resource)

# Update OnPresentationNarrativeSpoken
old_on_narrative = """procedure Tfrmmain.OnPresentationNarrativeSpoken(Sender: TObject; const ANarrative, AEmotion, AGesture: string);
begin
  if lblNarrativaExposicao <> nil then
    lblNarrativaExposicao.Caption := '"' + ANarrative + '"';

  AdicionaMensagemHistorico('🎓 Professor Virtual', ANarrative);

  if FAvatar3D <> nil then
  begin
    if AEmotion = 'alegria' then
      FAvatar3D.SetEmotion(aeHappy, 1.0)
    else
      FAvatar3D.SetEmotion(aeNeutral, 1.0);

    if AGesture = 'agWave' then
      FAvatar3D.PlayGesture(agWave, 2.0)
    else if AGesture = 'agPoint' then
      FAvatar3D.PlayGesture(agPoint, 2.0)
    else if AGesture = 'agNod' then
      FAvatar3D.PlayGesture(agNod, 1.8)
    else
      FAvatar3D.PlayGesture(agExplain, 2.2);
  end;

  if (FSetMain <> nil) and FSetMain.AutoSpeak then
    FalaTexto(ANarrative);
end;"""

new_on_narrative = """procedure Tfrmmain.OnPresentationNarrativeSpoken(Sender: TObject; const ANarrative, AEmotion, AGesture: string);
begin
  SetNarrativeText(ANarrative);
  SetProfessorState('presenting');

  if lblNarrativaExposicao <> nil then
    lblNarrativaExposicao.Caption := '"' + ANarrative + '"';

  AdicionaMensagemHistorico('🎓 Professor Virtual', ANarrative);

  if FAvatar3D <> nil then
  begin
    if AEmotion = 'alegria' then
      FAvatar3D.SetEmotion(aeHappy, 1.0)
    else
      FAvatar3D.SetEmotion(aeNeutral, 1.0);

    if AGesture = 'agWave' then
      FAvatar3D.PlayGesture(agWave, 2.0)
    else if AGesture = 'agPoint' then
      FAvatar3D.PlayGesture(agPoint, 2.0)
    else if AGesture = 'agNod' then
      FAvatar3D.PlayGesture(agNod, 1.8)
    else
      FAvatar3D.PlayGesture(agExplain, 2.2);
  end;

  if (FSetMain <> nil) and FSetMain.AutoSpeak then
    FalaTexto(ANarrative);
end;"""

main_pas_content = main_pas_content.replace(old_on_narrative, new_on_narrative)

# Update OnPresentationProjectChanged
old_on_project = """procedure Tfrmmain.OnPresentationProjectChanged(Sender: TObject; APackage: TPresentationPackage);
begin
  if APackage = nil then Exit;
  lblJarvisStatusBadge.Caption := '● EXPOSIÇÃO: ' + UpperCase(APackage.ProjectCode);
  lblJarvisSub.Caption := APackage.Title;
  if FAssistantManager <> nil then
    FAssistantManager.ActiveProject := APackage.ProjectCode;
end;"""

new_on_project = """procedure Tfrmmain.OnPresentationProjectChanged(Sender: TObject; APackage: TPresentationPackage);
begin
  if APackage = nil then Exit;
  if Assigned(lblProjectTitle) then
  begin
    lblProjectTitle.Caption := 'PROJETO ' + UpperCase(APackage.ProjectCode);
    lblProjectTitle.Visible := True;
  end;
  if Assigned(lblTopicSubtitle) then
  begin
    lblTopicSubtitle.Caption := APackage.Title;
    lblTopicSubtitle.Visible := True;
  end;
  lblJarvisStatusBadge.Caption := '● EXPOSIÇÃO: ' + UpperCase(APackage.ProjectCode);
  lblJarvisSub.Caption := APackage.Title;
  if FAssistantManager <> nil then
    FAssistantManager.ActiveProject := APackage.ProjectCode;
end;"""

main_pas_content = main_pas_content.replace(old_on_project, new_on_project)

# Update FormCreate to set up exhibition mode & load avatar into imgAvatarStage
old_avatar_load = """  if FileExists(ImgPath) then
  begin
    try
      imgAvatar.Picture.LoadFromFile(ImgPath);
    except
    end;
  end;"""

new_avatar_load = """  if FileExists(ImgPath) then
  begin
    try
      imgAvatar.Picture.LoadFromFile(ImgPath);
      if Assigned(imgAvatarStage) then
        imgAvatarStage.Picture.LoadFromFile(ImgPath);
    except
    end;
  end;
  EnterExhibitionMode;"""

main_pas_content = main_pas_content.replace(old_avatar_load, new_avatar_load)

# Connect voice synth events to avatar
old_voice_create = """  FVoiceSynth := TAIVoiceSynthesizer.Create(Self);"""
new_voice_create = """  FVoiceSynth := TAIVoiceSynthesizer.Create(Self);
  FVoiceSynth.OnSpeechStart := @OnVoiceSpeechStart;
  FVoiceSynth.OnSpeechEnd := @OnVoiceSpeechEnd;"""

main_pas_content = main_pas_content.replace(old_voice_create, new_voice_create)

# Update FalaTexto to simply call Say(TextoLimpo) as required by item 50
old_falatexto = """  if Assigned(FVoiceSynth) and (TextoLimpo <> '') then
  begin
    Log('Voz: Sintetizando resposta...');
    if Assigned(FAvatar3D) then
      FAvatar3D.StartSpeaking;
    try
      FVoiceSynth.Say(TextoLimpo);
    finally
      if Assigned(FAvatar3D) then
        FAvatar3D.StopSpeaking;
    end;
  end;"""

new_falatexto = """  if Assigned(FVoiceSynth) and (TextoLimpo <> '') then
  begin
    Log('Voz: Sintetizando resposta...');
    FVoiceSynth.Say(TextoLimpo);
  end;"""

main_pas_content = main_pas_content.replace(old_falatexto, new_falatexto)

# Update AplicaConfiguracoes to use new voice provider properties
old_aplica_synth = """    FVoiceSynth.VoiceName := FSetMain.SynthVoice;
    FVoiceSynth.Volume := FSetMain.SynthVolume;
    FVoiceSynth.Rate := FSetMain.SynthRate;
    FVoiceSynth.Asynchronous := FSetMain.SynthAsync;
    FVoiceSynth.OpenAIToken := FSetMain.CHATGPT;"""

new_aplica_synth = """    FVoiceSynth.VoiceName := FSetMain.SynthVoice;
    FVoiceSynth.Volume := FSetMain.SynthVolume;
    FVoiceSynth.Rate := FSetMain.SynthRate;
    FVoiceSynth.Asynchronous := FSetMain.SynthAsync;

    // Provedor Remoto Independente
    FVoiceSynth.Provider := TAIVoiceProvider(FSetMain.VoiceProvider);
    FVoiceSynth.APIToken := FSetMain.VoiceAPIToken;
    FVoiceSynth.Model := FSetMain.VoiceModel;
    FVoiceSynth.Endpoint := FSetMain.VoiceEndpoint;
    FVoiceSynth.RemoteVoice := FSetMain.VoiceRemoteVoice;
    FVoiceSynth.Language := FSetMain.VoiceLanguage;
    FVoiceSynth.OutputFormat := FSetMain.VoiceOutputFormat;
    FVoiceSynth.Speed := FSetMain.VoiceSpeed;"""

main_pas_content = main_pas_content.replace(old_aplica_synth, new_aplica_synth)

# Clean up InitExposicaoUI so it doesn't create duplicate widgets inside pnlChat
old_init_exposicao = """procedure Tfrmmain.InitExposicaoUI;
begin
  pnlExposicao := TPanel.Create(Self);
  pnlExposicao.Parent := pnlChat;
  pnlExposicao.Align := alClient;
  pnlExposicao.BevelOuter := bvNone;
  pnlExposicao.Color := $001A1816;
  pnlExposicao.Visible := True;

  lblFatecHeader := TLabel.Create(Self);
  lblFatecHeader.Parent := pnlExposicao;
  lblFatecHeader.Align := alTop;
  lblFatecHeader.Alignment := taCenter;
  lblFatecHeader.Caption := '🎓 FATEC RIBEIRÃO PRETO - EXPOSIÇÃO CIENTÍFICA & TECNOLÓGICA';
  lblFatecHeader.Font.Color := $00FFC040;
  lblFatecHeader.Font.Height := -14;
  lblFatecHeader.Font.Style := [fsBold];
  lblFatecHeader.BorderSpacing.Top := 8;
  lblFatecHeader.BorderSpacing.Bottom := 4;

  lblNarrativaExposicao := TLabel.Create(Self);
  lblNarrativaExposicao.Parent := pnlExposicao;
  lblNarrativaExposicao.Align := alTop;
  lblNarrativaExposicao.Alignment := taCenter;
  lblNarrativaExposicao.WordWrap := True;
  lblNarrativaExposicao.Caption := '"Aproxime-se para conhecer os projetos desenvolvidos pelos nossos pesquisadores..."';
  lblNarrativaExposicao.Font.Color := clWhite;
  lblNarrativaExposicao.Font.Height := -13;
  lblNarrativaExposicao.BorderSpacing.Around := 8;

  pnlExposicaoFooter := TPanel.Create(Self);
  pnlExposicaoFooter.Parent := pnlExposicao;
  pnlExposicaoFooter.Align := alBottom;
  pnlExposicaoFooter.Height := 38;
  pnlExposicaoFooter.BevelOuter := bvNone;
  pnlExposicaoFooter.Color := $00242220;

  btExposicaoContinuar := TBitBtn.Create(Self);
  btExposicaoContinuar.Parent := pnlExposicaoFooter;
  btExposicaoContinuar.Left := 10;
  btExposicaoContinuar.Top := 4;
  btExposicaoContinuar.Width := 150;
  btExposicaoContinuar.Height := 30;
  btExposicaoContinuar.Caption := '▶ Continuar Tópico';
  btExposicaoContinuar.OnClick := @btExposicaoContinuarClick;

  btExposicaoProximo := TBitBtn.Create(Self);
  btExposicaoProximo.Parent := pnlExposicaoFooter;
  btExposicaoProximo.Left := 170;
  btExposicaoProximo.Top := 4;
  btExposicaoProximo.Width := 150;
  btExposicaoProximo.Height := 30;
  btExposicaoProximo.Caption := '⏭ Próximo Projeto';
  btExposicaoProximo.OnClick := @btExposicaoProximoClick;

  btAdminToggle := TBitBtn.Create(Self);
  btAdminToggle.Parent := pnlExposicaoFooter;
  btAdminToggle.Align := alRight;
  btAdminToggle.Width := 120;
  btAdminToggle.Caption := '⚙ Admin / Logs';
  btAdminToggle.OnClick := @btAdminToggleClick;

  lblRecursoDescricao := TLabel.Create(Self);
  lblRecursoDescricao.Parent := pnlExposicao;
  lblRecursoDescricao.Align := alBottom;
  lblRecursoDescricao.Alignment := taCenter;
  lblRecursoDescricao.Caption := 'Recurso Selecionado: Aguardando início...';
  lblRecursoDescricao.Font.Color := $0000FF99;
  lblRecursoDescricao.Font.Height := -11;
  lblRecursoDescricao.Font.Style := [fsBold];
  lblRecursoDescricao.BorderSpacing.Bottom := 6;

  pnlRecursoMoldura := TPanel.Create(Self);
  pnlRecursoMoldura.Parent := pnlExposicao;
  pnlRecursoMoldura.Align := alClient;
  pnlRecursoMoldura.BevelOuter := bvNone;
  pnlRecursoMoldura.Color := $00101010;
  pnlRecursoMoldura.BorderSpacing.Around := 8;

  imgRecursoExposicao := TImage.Create(Self);
  imgRecursoExposicao.Parent := pnlRecursoMoldura;
  imgRecursoExposicao.Align := alClient;
  imgRecursoExposicao.Center := True;
  imgRecursoExposicao.Proportional := True;
  imgRecursoExposicao.Stretch := True;
end;"""

new_init_exposicao = """procedure Tfrmmain.InitExposicaoUI;
begin
  // Estrutura declarada nativamente no form (pnlRoot)
  EnterExhibitionMode;
end;"""

main_pas_content = main_pas_content.replace(old_init_exposicao, new_init_exposicao)

with open(main_pas_path, "w", encoding="utf-8") as f:
    f.write(main_pas_content)
print("main.pas updated successfully.")
print("All files updated successfully.")
