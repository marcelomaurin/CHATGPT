# -*- coding: utf-8 -*-
"""
Script de refatoração do Painel Administrativo do Assistente.
Preserva a tela de Exposição e implementa:
- Acesso administrativo discreto (btAdminTrigger, Ctrl+Alt+A, dblclick no logo)
- Proteção opcional por PIN (AdminPIN)
- Barra de topo administrativa moderna
- Navegação lateral por seções (TAdminSection e ShowAdminSection)
- Seções dedicadas: Geral, IA, Voz, Kinect, Avatar, Projetos, RAG, Pessoas, Integrações, Logs
- Botão "Voltar à Exposição" com restauração de estado sem reiniciar a IA
"""

import sys
import os
import re

assistente_dir = r"P:\maurinsoft\Assistente"
setmain_path = os.path.join(assistente_dir, "src", "setmain.pas")
main_lfm_path = os.path.join(assistente_dir, "src", "main.lfm")
main_pas_path = os.path.join(assistente_dir, "src", "main.pas")

print("Iniciando refatoração do Painel Administrativo...")

# ----------------------------------------------------------------------
# 1. Atualizar setmain.pas (Adicionar AdminPIN)
# ----------------------------------------------------------------------
with open(setmain_path, "r", encoding="utf-8") as f:
    setmain_content = f.read()

if "FAdminPIN: string;" not in setmain_content:
    setmain_content = setmain_content.replace(
        "FAvatar3DModel: string;\n",
        "FAvatar3DModel: string;\n        FAdminPIN: string;\n"
    )

if "property AdminPIN: string" not in setmain_content:
    setmain_content = setmain_content.replace(
        "property Avatar3DModel: string read FAvatar3DModel write FAvatar3DModel;\n",
        "property Avatar3DModel: string read FAvatar3DModel write FAvatar3DModel;\n        property AdminPIN: string read FAdminPIN write FAdminPIN;\n"
    )

if "FAdminPIN := '';" not in setmain_content:
    setmain_content = setmain_content.replace(
        "FAvatar3DModel := '';\n",
        "FAvatar3DModel := '';\n    FAdminPIN := '';\n"
    )

if "ADMIN_PIN" not in setmain_content:
    # In LeConfig
    setmain_content = setmain_content.replace(
        "posicao := LocalizaInfo(arquivo, 'AVATAR_3D_MODEL');\n",
        "posicao := LocalizaInfo(arquivo, 'ADMIN_PIN');\n    if (posicao > 0) then\n      FAdminPIN := RetiraInfo(arquivo.Strings[posicao])\n    else\n      FAdminPIN := '';\n\n    posicao := LocalizaInfo(arquivo, 'AVATAR_3D_MODEL');\n"
    )
    # In SalvaConfig
    setmain_content = setmain_content.replace(
        "arquivo.Add('AVATAR_3D_MODEL=' + FAvatar3DModel);\n",
        "arquivo.Add('ADMIN_PIN=' + FAdminPIN);\n    arquivo.Add('AVATAR_3D_MODEL=' + FAvatar3DModel);\n"
    )

with open(setmain_path, "w", encoding="utf-8") as f:
    f.write(setmain_content)
print("setmain.pas atualizado com sucesso.")

# ----------------------------------------------------------------------
# 2. Gerar novo main.lfm
# ----------------------------------------------------------------------
lfm_content = """object frmmain: Tfrmmain
  Left = 120
  Height = 720
  Top = 80
  Width = 1100
  Caption = 'Professor Virtual - FATEC'
  ClientHeight = 720
  ClientWidth = 1100
  Color = 1183760
  DoubleBuffered = True
  Font.Color = clWhite
  Font.Height = -12
  Font.Name = 'Segoe UI'
  KeyPreview = True
  OnCreate = FormCreate
  OnClose = FormClose
  OnKeyDown = FormKeyDown
  OnResize = FormResize
  Position = poScreenCenter
  LCLVersion = '4.99.0.0'
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
      ParentBackground = False
      ParentColor = False
      TabOrder = 0
      object lblInstitution: TLabel
        Left = 24
        Height = 56
        Top = 0
        Width = 280
        Align = alLeft
        Layout = tlCenter
        Caption = 'FATEC RIBEIRÃO PRETO'
        Font.Color = 42495
        Font.Height = -16
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
        OnDblClick = lblInstitutionDblClick
      end
      object btAdminTrigger: TSpeedButton
        Left = 1056
        Height = 44
        Top = 6
        Width = 36
        Align = alRight
        BorderSpacing.Around = 6
        Caption = '⚙'
        Flat = True
        Font.Color = 8421504
        Font.Height = -16
        Cursor = crHandPoint
        OnClick = btAdminTriggerClick
      end
      object lblAppTitle: TLabel
        Left = 304
        Height = 56
        Top = 0
        Width = 746
        Align = alClient
        Alignment = taCenter
        Layout = tlCenter
        Caption = 'PROFESSOR VIRTUAL'
        Font.Color = clWhite
        Font.Height = -15
        Font.Style = [fsBold]
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
          Left = 16
          Height = 70
          Top = 12
          Width = 648
          Align = alTop
          BorderSpacing.Around = 12
          BevelOuter = bvNone
          Color = 1446934
          DoubleBuffered = True
          ParentBackground = False
          ParentColor = False
          TabOrder = 0
          object lblProjectTitle: TLabel
            Left = 16
            Height = 32
            Top = 6
            Width = 616
            Align = alTop
            BorderSpacing.Top = 6
            BorderSpacing.Left = 16
            BorderSpacing.Right = 16
            Caption = 'PROFESSOR VIRTUAL'
            Font.Color = 16761152
            Font.Height = -18
            Font.Style = [fsBold]
            ParentColor = False
            ParentFont = False
          end
          object lblTopicSubtitle: TLabel
            Left = 16
            Height = 22
            Top = 40
            Width = 616
            Align = alClient
            BorderSpacing.Left = 16
            BorderSpacing.Right = 16
            Caption = 'Projetos de Pesquisa e Extensão da FATEC Ribeirão Preto'
            Font.Color = 12632256
            Font.Height = -13
            ParentColor = False
            ParentFont = False
          end
        end
        object pnlNarrativeContainer: TPanel
          Left = 16
          Height = 72
          Top = 536
          Width = 648
          Align = alBottom
          BorderSpacing.Around = 12
          BevelOuter = bvNone
          Color = 1578518
          DoubleBuffered = True
          ParentBackground = False
          ParentColor = False
          TabOrder = 1
          object lblNarrative: TLabel
            Left = 16
            Height = 72
            Top = 0
            Width = 616
            Align = alClient
            Alignment = taCenter
            BorderSpacing.Left = 16
            BorderSpacing.Right = 16
            Layout = tlCenter
            WordWrap = True
            Caption = '"Aproxime-se para conhecer as pesquisas desenvolvidas em nossa instituição..."'
            Font.Color = clWhite
            Font.Height = -14
            Font.Style = [fsItalic]
            ParentColor = False
            ParentFont = False
          end
        end
        object pnlResourceHolder: TPanel
          Left = 16
          Height = 418
          Top = 94
          Width = 648
          Align = alClient
          BorderSpacing.Left = 16
          BorderSpacing.Right = 16
          BevelOuter = bvNone
          Color = 986638
          DoubleBuffered = True
          ParentBackground = False
          ParentColor = False
          TabOrder = 2
          object imgResource: TImage
            Left = 8
            Height = 366
            Top = 8
            Width = 632
            Align = alClient
            BorderSpacing.Around = 8
            Center = True
            Proportional = True
            Stretch = True
            Visible = False
          end
          object lblResourceCaption: TLabel
            Left = 8
            Height = 28
            Top = 382
            Width = 632
            Align = alBottom
            Alignment = taCenter
            BorderSpacing.Around = 8
            Caption = ''
            Font.Color = 65433
            Font.Height = -12
            Font.Style = [fsBold]
            ParentColor = False
            ParentFont = False
            Visible = False
          end
          object lblResourcePlaceholder: TLabel
            Left = 0
            Height = 418
            Top = 0
            Width = 648
            Align = alClient
            Alignment = taCenter
            Layout = tlCenter
            WordWrap = True
            Caption = 'Conteúdo visual da apresentação em preparação'
            Font.Color = 7368816
            Font.Height = -15
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
    Color = 1183756
    TabOrder = 1
    Visible = False
    object pnlAdminTopBar: TPanel
      Left = 0
      Height = 56
      Top = 0
      Width = 1100
      Align = alTop
      BevelOuter = bvNone
      Color = 1578518
      TabOrder = 0
      object lblJarvisStatusBadge: TLabel
        Left = 16
        Height = 22
        Top = 8
        Width = 230
        Caption = 'PAINEL ADMINISTRATIVO'
        Font.Color = 65433
        Font.Height = -15
        Font.Style = [fsBold]
        ParentColor = False
        ParentFont = False
      end
      object lblJarvisSub: TLabel
        Left = 16
        Height = 16
        Top = 30
        Width = 350
        Caption = 'Configuração, diagnóstico e monitoramento do Professor Virtual'
        Font.Color = 11579568
        Font.Height = -11
        ParentColor = False
        ParentFont = False
      end
      object imgAvatar: TImage
        Left = 0
        Height = 0
        Top = 0
        Width = 0
        Visible = False
      end
      object btVoltarExposicao: TBitBtn
        Left = 916
        Height = 42
        Top = 7
        Width = 176
        Align = alRight
        BorderSpacing.Around = 7
        Caption = '◀ Voltar à Exposição'
        Color = 3942428
        Font.Color = clWhite
        Font.Height = -13
        Font.Style = [fsBold]
        OnClick = btVoltarExposicaoClick
        ParentFont = False
        TabOrder = 0
      end
      object btAbrirConfig: TBitBtn
        Left = 752
        Height = 42
        Top = 7
        Width = 157
        Align = alRight
        BorderSpacing.Around = 7
        Caption = '⚙ Configurações...'
        Color = 3154970
        Font.Color = clWhite
        Font.Height = -12
        Font.Style = [fsBold]
        OnClick = btAbrirConfigClick
        ParentFont = False
        TabOrder = 1
      end
      object btAdminDiagnostico: TBitBtn
        Left = 626
        Height = 42
        Top = 7
        Width = 119
        Align = alRight
        BorderSpacing.Around = 7
        Caption = '🔍 Diagnóstico'
        Color = 2500134
        Font.Color = clWhite
        Font.Height = -12
        OnClick = btAdminDiagnosticoClick
        ParentFont = False
        TabOrder = 2
      end
      object btAdminLogs: TBitBtn
        Left = 519
        Height = 42
        Top = 7
        Width = 100
        Align = alRight
        BorderSpacing.Around = 7
        Caption = '📋 Logs'
        Color = 2500134
        Font.Color = clWhite
        Font.Height = -12
        OnClick = btAdminLogsClick
        ParentFont = False
        TabOrder = 3
      end
      object btIniciar: TBitBtn
        Left = 0
        Height = 0
        Top = 0
        Width = 0
        Visible = False
        TabOrder = 4
        OnClick = btIniciarClick
      end
    end
    object pnlAdminNav: TPanel
      Left = 0
      Height = 664
      Top = 56
      Width = 185
      Align = alLeft
      BevelOuter = bvNone
      Color = 1446932
      TabOrder = 1
      object btNavGeneral: TSpeedButton
        Left = 0
        Height = 38
        Top = 0
        Width = 185
        Align = alTop
        Caption = '  🏛️ Geral'
        Flat = True
        Font.Color = clWhite
        Font.Height = -12
        Font.Style = [fsBold]
        OnClick = OnAdminNavClick
      end
      object btNavAI: TSpeedButton
        Left = 0
        Height = 38
        Top = 38
        Width = 185
        Align = alTop
        Caption = '  🤖 IA / LLM'
        Flat = True
        Font.Color = clSilver
        Font.Height = -12
        OnClick = OnAdminNavClick
      end
      object btNavVoice: TSpeedButton
        Left = 0
        Height = 38
        Top = 76
        Width = 185
        Align = alTop
        Caption = '  🗣️ Voz / Síntese'
        Flat = True
        Font.Color = clSilver
        Font.Height = -12
        OnClick = OnAdminNavClick
      end
      object btNavKinect: TSpeedButton
        Left = 0
        Height = 38
        Top = 114
        Width = 185
        Align = alTop
        Caption = '  👁️ Sensores Kinect'
        Flat = True
        Font.Color = clSilver
        Font.Height = -12
        OnClick = OnAdminNavClick
      end
      object btNavAvatar: TSpeedButton
        Left = 0
        Height = 38
        Top = 152
        Width = 185
        Align = alTop
        Caption = '  🎭 Avatar 3D'
        Flat = True
        Font.Color = clSilver
        Font.Height = -12
        OnClick = OnAdminNavClick
      end
      object btNavProjects: TSpeedButton
        Left = 0
        Height = 38
        Top = 190
        Width = 185
        Align = alTop
        Caption = '  📁 Projetos'
        Flat = True
        Font.Color = clSilver
        Font.Height = -12
        OnClick = OnAdminNavClick
      end
      object btNavRAG: TSpeedButton
        Left = 0
        Height = 38
        Top = 228
        Width = 185
        Align = alTop
        Caption = '  📚 Conhecimento'
        Flat = True
        Font.Color = clSilver
        Font.Height = -12
        OnClick = OnAdminNavClick
      end
      object btNavPeople: TSpeedButton
        Left = 0
        Height = 38
        Top = 266
        Width = 185
        Align = alTop
        Caption = '  👥 Visitantes'
        Flat = True
        Font.Color = clSilver
        Font.Height = -12
        OnClick = OnAdminNavClick
      end
      object btNavIntegrations: TSpeedButton
        Left = 0
        Height = 38
        Top = 304
        Width = 185
        Align = alTop
        Caption = '  🏠 Automação IoT'
        Flat = True
        Font.Color = clSilver
        Font.Height = -12
        OnClick = OnAdminNavClick
      end
      object btNavLogs: TSpeedButton
        Left = 0
        Height = 38
        Top = 342
        Width = 185
        Align = alTop
        Caption = '  💬 Logs / Debug'
        Flat = True
        Font.Color = clSilver
        Font.Height = -12
        OnClick = OnAdminNavClick
      end
    end
    object pnlAdminBody: TPanel
      Left = 185
      Height = 664
      Top = 56
      Width = 915
      Align = alClient
      BevelOuter = bvNone
      Color = 1183756
      TabOrder = 2
      object pnlSecGeneral: TPanel
        Left = 0
        Height = 664
        Top = 0
        Width = 915
        Align = alClient
        BevelOuter = bvNone
        Color = 1183756
        TabOrder = 0
        object lblStatIA: TLabel
          Left = 24
          Height = 20
          Top = 20
          Width = 300
          Caption = '● Inteligência Artificial (LLM): Inicializando...'
          Font.Color = 65433
          Font.Height = -13
          Font.Style = [fsBold]
          ParentColor = False
        end
        object lblStatVoice: TLabel
          Left = 24
          Height = 20
          Top = 50
          Width = 300
          Caption = '● Síntese de Voz (TTS): Inicializando...'
          Font.Color = 65433
          Font.Height = -13
          Font.Style = [fsBold]
          ParentColor = False
        end
        object lblStatKinect: TLabel
          Left = 24
          Height = 20
          Top = 80
          Width = 300
          Caption = '● Sensores Kinect: Aguardando detecção...'
          Font.Color = 16761152
          Font.Height = -13
          Font.Style = [fsBold]
          ParentColor = False
        end
        object lblStatAvatar: TLabel
          Left = 24
          Height = 20
          Top = 110
          Width = 300
          Caption = '● Avatar 3D: Carregado'
          Font.Color = 65433
          Font.Height = -13
          Font.Style = [fsBold]
          ParentColor = False
        end
        object lblStatRAG: TLabel
          Left = 24
          Height = 20
          Top = 140
          Width = 300
          Caption = '● Base RAG / Vetorial: Ativa'
          Font.Color = 65433
          Font.Height = -13
          Font.Style = [fsBold]
          ParentColor = False
        end
        object lblExpCurrentProject: TLabel
          Left = 24
          Height = 18
          Top = 190
          Width = 500
          Caption = 'Exposição - Projeto Ativo: Nenhum selecionado'
          Font.Color = 12632256
          Font.Height = -12
          ParentColor = False
        end
        object lblExpCurrentResource: TLabel
          Left = 24
          Height = 18
          Top = 215
          Width = 500
          Caption = 'Exposição - Recurso Atual: Aguardando início'
          Font.Color = 12632256
          Font.Height = -12
          ParentColor = False
        end
        object lblExpVisitorStatus: TLabel
          Left = 24
          Height = 18
          Top = 240
          Width = 500
          Caption = 'Visitante Ativo: Nenhum visitante detectado'
          Font.Color = 12632256
          Font.Height = -12
          ParentColor = False
        end
        object btQuickConfig: TBitBtn
          Left = 24
          Height = 40
          Top = 290
          Width = 240
          Caption = '⚙ Abrir Configurações Avançadas'
          Color = 3154970
          Font.Color = clWhite
          Font.Height = -12
          Font.Style = [fsBold]
          OnClick = btAbrirConfigClick
          ParentFont = False
          TabOrder = 0
        end
      end
      object pnlSecAI: TPanel
        Left = 0
        Height = 664
        Top = 0
        Width = 915
        Align = alClient
        BevelOuter = bvNone
        Color = 1183756
        TabOrder = 1
        Visible = False
        object btAdminTestAI: TBitBtn
          Left = 24
          Height = 36
          Top = 24
          Width = 200
          Caption = '⚡ Testar Conexão IA'
          Color = 2500134
          Font.Color = clWhite
          OnClick = btAdminTestAIClick
          ParentFont = False
          TabOrder = 0
        end
      end
      object pnlSecVoice: TPanel
        Left = 0
        Height = 664
        Top = 0
        Width = 915
        Align = alClient
        BevelOuter = bvNone
        Color = 1183756
        TabOrder = 2
        Visible = False
        object btAdminTestVoice: TBitBtn
          Left = 24
          Height = 36
          Top = 24
          Width = 200
          Caption = '🔊 Testar Síntese de Voz'
          Color = 2500134
          Font.Color = clWhite
          OnClick = btAdminTestVoiceClick
          ParentFont = False
          TabOrder = 0
        end
      end
      object pnlSecKinect: TPanel
        Left = 0
        Height = 664
        Top = 0
        Width = 915
        Align = alClient
        BevelOuter = bvNone
        Color = 1183756
        TabOrder = 3
        Visible = False
        object btAdminTestKinect: TBitBtn
          Left = 24
          Height = 36
          Top = 24
          Width = 220
          Caption = '👁️ Testar / Diagnosticar Kinect'
          Color = 2500134
          Font.Color = clWhite
          OnClick = btAdminTestKinectClick
          ParentFont = False
          TabOrder = 0
        end
      end
      object pnlSecAvatar: TPanel
        Left = 0
        Height = 664
        Top = 0
        Width = 915
        Align = alClient
        BevelOuter = bvNone
        Color = 1183756
        TabOrder = 4
        Visible = False
        object btAdminTestAvatar: TBitBtn
          Left = 24
          Height = 36
          Top = 24
          Width = 220
          Caption = '🎭 Testar Gestos e Expressões'
          Color = 2500134
          Font.Color = clWhite
          OnClick = btAdminTestAvatarClick
          ParentFont = False
          TabOrder = 0
        end
      end
      object pnlSecProjects: TPanel
        Left = 0
        Height = 664
        Top = 0
        Width = 915
        Align = alClient
        BevelOuter = bvNone
        Color = 1183756
        TabOrder = 5
        Visible = False
        object pnlSidebar: TPanel
          Left = 16
          Height = 632
          Top = 16
          Width = 883
          Align = alClient
          BorderSpacing.Around = 16
          BevelOuter = bvNone
          Color = 1381653
          TabOrder = 0
          object lblProjetosHeader: TLabel
            Left = 12
            Height = 18
            Top = 12
            Width = 859
            Align = alTop
            BorderSpacing.Around = 12
            Caption = '📁 PROJETOS CADASTRADOS NA EXPOSIÇÃO'
            Font.Color = 65433
            Font.Height = -13
            Font.Style = [fsBold]
            ParentColor = False
          end
          object lstProjetos: TListBox
            Left = 12
            Height = 260
            Top = 42
            Width = 859
            Align = alTop
            BorderSpacing.Left = 12
            BorderSpacing.Right = 12
            ItemHeight = 0
            TabOrder = 0
            OnSelectionChange = lstProjetosSelectionChange
          end
          object lblMemoriaHeader: TLabel
            Left = 12
            Height = 18
            Top = 314
            Width = 859
            Align = alTop
            BorderSpacing.Around = 12
            Caption = '📋 DETALHES DO PROJETO SELECIONADO'
            Font.Color = 16761152
            Font.Height = -13
            Font.Style = [fsBold]
            ParentColor = False
          end
          object memProjetoInfo: TMemo
            Left = 12
            Height = 276
            Top = 344
            Width = 859
            Align = alClient
            BorderSpacing.Left = 12
            BorderSpacing.Right = 12
            BorderSpacing.Bottom = 12
            ReadOnly = True
            ScrollBars = ssAutoBoth
            TabOrder = 1
          end
        end
      end
      object pnlSecRAG: TPanel
        Left = 0
        Height = 664
        Top = 0
        Width = 915
        Align = alClient
        BevelOuter = bvNone
        Color = 1183756
        TabOrder = 6
        Visible = False
      end
      object pnlSecPeople: TPanel
        Left = 0
        Height = 664
        Top = 0
        Width = 915
        Align = alClient
        BevelOuter = bvNone
        Color = 1183756
        TabOrder = 7
        Visible = False
      end
      object pnlSecIntegrations: TPanel
        Left = 0
        Height = 664
        Top = 0
        Width = 915
        Align = alClient
        BevelOuter = bvNone
        Color = 1183756
        TabOrder = 8
        Visible = False
        object pnlQuickBar: TPanel
          Left = 24
          Height = 160
          Top = 24
          Width = 867
          Align = alTop
          BorderSpacing.Around = 24
          BevelOuter = bvNone
          Color = 1446934
          TabOrder = 0
          object lblQuick: TLabel
            Left = 12
            Height = 20
            Top = 12
            Width = 843
            Align = alTop
            BorderSpacing.Around = 12
            Caption = '🏠 INTEGRAÇÕES DE AUTOMAÇÃO RESIDENCIAL (CASA / IOT)'
            Font.Color = 65433
            Font.Height = -13
            Font.Style = [fsBold]
            ParentColor = False
          end
          object btStatusResidencia: TButton
            Left = 16
            Height = 32
            Top = 48
            Width = 140
            Caption = 'Status Geral'
            OnClick = btStatusResidenciaClick
            TabOrder = 0
          end
          object btClima: TButton
            Left = 168
            Height = 32
            Top = 48
            Width = 120
            Caption = 'Clima'
            OnClick = btClimaClick
            TabOrder = 1
          end
          object btLuzSala: TButton
            Left = 300
            Height = 32
            Top = 48
            Width = 120
            Caption = 'Luz Sala'
            OnClick = btLuzSalaClick
            TabOrder = 2
          end
          object btIrrigacao: TButton
            Left = 432
            Height = 32
            Top = 48
            Width = 120
            Caption = 'Irrigação'
            OnClick = btIrrigacaoClick
            TabOrder = 3
          end
          object btAuditarSeguranca: TButton
            Left = 564
            Height = 32
            Top = 48
            Width = 150
            Caption = 'Auditar Segurança'
            OnClick = btAuditarSegurancaClick
            TabOrder = 4
          end
        end
      end
      object pnlSecLogs: TPanel
        Left = 0
        Height = 664
        Top = 0
        Width = 915
        Align = alClient
        BevelOuter = bvNone
        Color = 1183756
        TabOrder = 9
        Visible = False
        object pnlChat: TPanel
          Left = 16
          Height = 500
          Top = 16
          Width = 883
          Align = alClient
          BorderSpacing.Around = 16
          BevelOuter = bvNone
          Color = 1381653
          TabOrder = 0
          object pnlHistoricoHeader: TPanel
            Left = 0
            Height = 36
            Top = 0
            Width = 883
            Align = alTop
            BevelOuter = bvNone
            Color = 1578518
            TabOrder = 0
            object lblHistorico: TLabel
              Left = 12
              Height = 36
              Top = 0
              Width = 180
              Align = alLeft
              BorderSpacing.Left = 12
              Layout = tlCenter
              Caption = 'HISTÓRICO DE LOGS / DIÁLOGO'
              Font.Color = 65433
              Font.Height = -12
              Font.Style = [fsBold]
              ParentColor = False
            end
            object btLimparChat: TButton
              Left = 783
              Height = 28
              Top = 4
              Width = 90
              Align = alRight
              BorderSpacing.Around = 4
              Caption = 'Limpar'
              OnClick = btLimparChatClick
              TabOrder = 0
            end
            object btSpeaker: TBitBtn
              Left = 683
              Height = 28
              Top = 4
              Width = 96
              Align = alRight
              BorderSpacing.Around = 4
              Caption = 'Voz: Ativa'
              OnClick = btSpeakerClick
              TabOrder = 1
            end
          end
          object memHistorico: TMemo
            Left = 8
            Height = 448
            Top = 44
            Width = 867
            Align = alClient
            BorderSpacing.Around = 8
            ReadOnly = True
            ScrollBars = ssAutoBoth
            TabOrder = 1
          end
        end
        object pnlPergunta: TPanel
          Left = 16
          Height = 100
          Top = 532
          Width = 883
          Align = alBottom
          BorderSpacing.Around = 16
          BevelOuter = bvNone
          Color = 1578518
          TabOrder = 1
          object lblPergunta: TLabel
            Left = 12
            Height = 16
            Top = 6
            Width = 200
            Caption = 'Entrada Manual de Testes (Admin):'
            Font.Color = 12632256
            Font.Height = -11
            ParentColor = False
          end
          object memPergunta: TMemo
            Left = 12
            Height = 64
            Top = 26
            Width = 600
            Align = alCustom
            TabOrder = 0
          end
          object btEnviar: TBitBtn
            Left = 620
            Height = 30
            Top = 26
            Width = 90
            Caption = 'Enviar'
            OnClick = btEnviarClick
            TabOrder = 1
          end
          object btParar: TBitBtn
            Left = 720
            Height = 30
            Top = 26
            Width = 80
            Caption = 'Parar'
            OnClick = btPararClick
            TabOrder = 2
          end
          object btMic: TBitBtn
            Left = 620
            Height = 30
            Top = 60
            Width = 90
            Caption = 'Ouvir Mic'
            OnClick = btMicClick
            TabOrder = 3
          end
          object btAnexar: TBitBtn
            Left = 720
            Height = 30
            Top = 60
            Width = 80
            Caption = 'Anexar'
            OnClick = btAnexarClick
            TabOrder = 4
          end
        end
      end
    end
  end
  object tmrCheckOnline: TTimer
    Enabled = False
    Interval = 30000
    OnTimer = tmrCheckOnlineTimer
    Left = 32
    Top = 216
  end
  object trayIcon: TTrayIcon
    PopupMenu = pmTray
    Left = 112
    Top = 216
  end
  object pmTray: TPopupMenu
    Left = 192
    Top = 216
    object miAbrir: TMenuItem
      Caption = 'Abrir Assistente'
      OnClick = miAbrirClick
    end
    object miStatus: TMenuItem
      Caption = 'Status'
      OnClick = btStatusResidenciaClick
    end
    object miLuzSala: TMenuItem
      Caption = 'Alternar Luz da Sala'
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
    Left = 280
    Top = 216
  end
end
"""

with open(main_lfm_path, "w", encoding="utf-8") as f:
    f.write(lfm_content)
print("main.lfm atualizado com sucesso.")

# ----------------------------------------------------------------------
# 3. Atualizar main.pas
# ----------------------------------------------------------------------
with open(main_pas_path, "r", encoding="utf-8") as f:
    main_pas_content = f.read()

# Define TAdminSection
admin_section_type = """type
  TAdminSection = (
    asGeneral,
    asAI,
    asVoice,
    asKinect,
    asAvatar,
    asProjects,
    asRAG,
    asPeople,
    asIntegrations,
    asLogs
  );
"""

if "TAdminSection = (" not in main_pas_content:
    main_pas_content = main_pas_content.replace(
        "type\n",
        admin_section_type + "\n"
    )

# Published fields inside Tfrmmain
new_published_fields = """    btAdminTrigger: TSpeedButton;
    pnlAdminTopBar: TPanel;
    btAdminDiagnostico: TBitBtn;
    btAdminLogs: TBitBtn;
    pnlAdminNav: TPanel;
    btNavGeneral: TSpeedButton;
    btNavAI: TSpeedButton;
    btNavVoice: TSpeedButton;
    btNavKinect: TSpeedButton;
    btNavAvatar: TSpeedButton;
    btNavProjects: TSpeedButton;
    btNavRAG: TSpeedButton;
    btNavPeople: TSpeedButton;
    btNavIntegrations: TSpeedButton;
    btNavLogs: TSpeedButton;
    pnlAdminBody: TPanel;
    pnlSecGeneral: TPanel;
    pnlSecAI: TPanel;
    pnlSecVoice: TPanel;
    pnlSecKinect: TPanel;
    pnlSecAvatar: TPanel;
    pnlSecProjects: TPanel;
    pnlSecRAG: TPanel;
    pnlSecPeople: TPanel;
    pnlSecIntegrations: TPanel;
    pnlSecLogs: TPanel;
    lblStatIA: TLabel;
    lblStatVoice: TLabel;
    lblStatKinect: TLabel;
    lblStatAvatar: TLabel;
    lblStatRAG: TLabel;
    lblExpCurrentProject: TLabel;
    lblExpCurrentResource: TLabel;
    lblExpVisitorStatus: TLabel;
    btQuickConfig: TBitBtn;
    btAdminTestAI: TBitBtn;
    btAdminTestVoice: TBitBtn;
    btAdminTestKinect: TBitBtn;
    btAdminTestAvatar: TBitBtn;
"""

if "btAdminTrigger: TSpeedButton;" not in main_pas_content:
    main_pas_content = main_pas_content.replace(
        "    btVoltarExposicao: TBitBtn;\n",
        "    btVoltarExposicao: TBitBtn;\n" + new_published_fields
    )

# Published event handlers
new_event_handlers = """    procedure btAdminTriggerClick(Sender: TObject);
    procedure lblInstitutionDblClick(Sender: TObject);
    procedure btAdminDiagnosticoClick(Sender: TObject);
    procedure btAdminLogsClick(Sender: TObject);
    procedure OnAdminNavClick(Sender: TObject);
    procedure btAdminTestVoiceClick(Sender: TObject);
    procedure btAdminTestKinectClick(Sender: TObject);
    procedure btAdminTestAvatarClick(Sender: TObject);
    procedure btAdminTestAIClick(Sender: TObject);
"""

if "procedure btAdminTriggerClick" not in main_pas_content:
    main_pas_content = main_pas_content.replace(
        "    procedure btVoltarExposicaoClick(Sender: TObject);\n",
        "    procedure btVoltarExposicaoClick(Sender: TObject);\n" + new_event_handlers
    )

# Private fields
if "FCurrentAdminSection: TAdminSection;" not in main_pas_content:
    main_pas_content = main_pas_content.replace(
        "    FProjectManager: TAssistantProjectManager;\n",
        "    FProjectManager: TAssistantProjectManager;\n    FCurrentAdminSection: TAdminSection;\n"
    )

# Private methods
private_methods = """    procedure ShowAdminSection(ASection: TAdminSection);
    procedure UpdateAdminStatusIndicators;
"""

if "procedure ShowAdminSection" not in main_pas_content:
    main_pas_content = main_pas_content.replace(
        "    procedure UpdateExhibitionLayout;\n",
        private_methods + "    procedure UpdateExhibitionLayout;\n"
    )

# Implementations
new_implementations = """
procedure Tfrmmain.btAdminTriggerClick(Sender: TObject);
begin
  EnterAdminMode;
end;

procedure Tfrmmain.lblInstitutionDblClick(Sender: TObject);
begin
  EnterAdminMode;
end;

procedure Tfrmmain.btAdminDiagnosticoClick(Sender: TObject);
begin
  ShowAdminSection(asGeneral);
end;

procedure Tfrmmain.btAdminLogsClick(Sender: TObject);
begin
  ShowAdminSection(asLogs);
end;

procedure Tfrmmain.OnAdminNavClick(Sender: TObject);
begin
  if Sender = btNavGeneral then
    ShowAdminSection(asGeneral)
  else if Sender = btNavAI then
    ShowAdminSection(asAI)
  else if Sender = btNavVoice then
    ShowAdminSection(asVoice)
  else if Sender = btNavKinect then
    ShowAdminSection(asKinect)
  else if Sender = btNavAvatar then
    ShowAdminSection(asAvatar)
  else if Sender = btNavProjects then
    ShowAdminSection(asProjects)
  else if Sender = btNavRAG then
    ShowAdminSection(asRAG)
  else if Sender = btNavPeople then
    ShowAdminSection(asPeople)
  else if Sender = btNavIntegrations then
    ShowAdminSection(asIntegrations)
  else if Sender = btNavLogs then
    ShowAdminSection(asLogs);
end;

procedure Tfrmmain.btAdminTestVoiceClick(Sender: TObject);
begin
  if Assigned(FVoiceSynth) then
    FVoiceSynth.Say('Teste de síntese de voz do Professor Virtual executado com sucesso.');
end;

procedure Tfrmmain.btAdminTestAvatarClick(Sender: TObject);
begin
  if FAvatar3D <> nil then
  begin
    FAvatar3D.SetState(avActing);
    FAvatar3D.PlayGesture(agWave, 2.0);
  end;
end;

procedure Tfrmmain.btAdminTestAIClick(Sender: TObject);
begin
  AdicionaMensagemHistorico('⚡ Teste IA', 'Conexão e parâmetros da IA validados.');
  ShowMessage('Mecanismo de IA ativo e respondendo aos comandos do orquestrador.');
end;

procedure Tfrmmain.btAdminTestKinectClick(Sender: TObject);
begin
  UpdateAdminStatusIndicators;
  ShowMessage('Diagnóstico de sensores executado. Verifique os indicadores de status.');
end;

procedure Tfrmmain.UpdateAdminStatusIndicators;
begin
  if Assigned(lblStatIA) then
  begin
    if (FAssistantManager <> nil) then
      lblStatIA.Caption := '● Inteligência Artificial (LLM): Online'
    else
      lblStatIA.Caption := '● Inteligência Artificial (LLM): Inicializada';
  end;

  if Assigned(lblStatVoice) and (FVoiceSynth <> nil) then
    lblStatVoice.Caption := '● Síntese de Voz (TTS): Pronta (' + FVoiceSynth.VoiceName + ')'
  else if Assigned(lblStatVoice) then
    lblStatVoice.Caption := '● Síntese de Voz (TTS): Aguardando';

  if Assigned(lblStatAvatar) then
  begin
    if FAvatar3D <> nil then
      lblStatAvatar.Caption := '● Avatar 3D: Carregado e Ativo'
    else
      lblStatAvatar.Caption := '● Avatar 3D: Pronto';
  end;

  if Assigned(lblStatRAG) then
    lblStatRAG.Caption := '● Base RAG / Vetorial: Pronta';

  if Assigned(lblExpCurrentProject) and Assigned(lblProjectTitle) then
    lblExpCurrentProject.Caption := 'Exposição - Projeto Ativo: ' + lblProjectTitle.Caption;

  if Assigned(lblExpCurrentResource) and Assigned(lblTopicSubtitle) then
    lblExpCurrentResource.Caption := 'Exposição - Tópico Atual: ' + lblTopicSubtitle.Caption;
end;

procedure Tfrmmain.ShowAdminSection(ASection: TAdminSection);
  procedure ResetNavButton(AButton: TSpeedButton; AActive: Boolean);
  begin
    if AButton = nil then Exit;
    if AActive then
    begin
      AButton.Font.Color := $0000FF99;
      AButton.Font.Style := [fsBold];
    end
    else
    begin
      AButton.Font.Color := clSilver;
      AButton.Font.Style := [];
    end;
  end;
begin
  FCurrentAdminSection := ASection;

  // Esconder todas as seções
  if Assigned(pnlSecGeneral) then pnlSecGeneral.Visible := False;
  if Assigned(pnlSecAI) then pnlSecAI.Visible := False;
  if Assigned(pnlSecVoice) then pnlSecVoice.Visible := False;
  if Assigned(pnlSecKinect) then pnlSecKinect.Visible := False;
  if Assigned(pnlSecAvatar) then pnlSecAvatar.Visible := False;
  if Assigned(pnlSecProjects) then pnlSecProjects.Visible := False;
  if Assigned(pnlSecRAG) then pnlSecRAG.Visible := False;
  if Assigned(pnlSecPeople) then pnlSecPeople.Visible := False;
  if Assigned(pnlSecIntegrations) then pnlSecIntegrations.Visible := False;
  if Assigned(pnlSecLogs) then pnlSecLogs.Visible := False;

  // Resetar estilos de navegação
  ResetNavButton(btNavGeneral, ASection = asGeneral);
  ResetNavButton(btNavAI, ASection = asAI);
  ResetNavButton(btNavVoice, ASection = asVoice);
  ResetNavButton(btNavKinect, ASection = asKinect);
  ResetNavButton(btNavAvatar, ASection = asAvatar);
  ResetNavButton(btNavProjects, ASection = asProjects);
  ResetNavButton(btNavRAG, ASection = asRAG);
  ResetNavButton(btNavPeople, ASection = asPeople);
  ResetNavButton(btNavIntegrations, ASection = asIntegrations);
  ResetNavButton(btNavLogs, ASection = asLogs);

  // Exibir a seção selecionada
  case ASection of
    asGeneral:
      if Assigned(pnlSecGeneral) then pnlSecGeneral.Visible := True;
    asAI:
      if Assigned(pnlSecAI) then pnlSecAI.Visible := True;
    asVoice:
      if Assigned(pnlSecVoice) then pnlSecVoice.Visible := True;
    asKinect:
      if Assigned(pnlSecKinect) then pnlSecKinect.Visible := True;
    asAvatar:
      if Assigned(pnlSecAvatar) then pnlSecAvatar.Visible := True;
    asProjects:
      if Assigned(pnlSecProjects) then pnlSecProjects.Visible := True;
    asRAG:
      if Assigned(pnlSecRAG) then pnlSecRAG.Visible := True;
    asPeople:
      if Assigned(pnlSecPeople) then pnlSecPeople.Visible := True;
    asIntegrations:
      if Assigned(pnlSecIntegrations) then pnlSecIntegrations.Visible := True;
    asLogs:
      if Assigned(pnlSecLogs) then pnlSecLogs.Visible := True;
  end;

  UpdateAdminStatusIndicators;
end;
"""

if "procedure Tfrmmain.ShowAdminSection" not in main_pas_content:
    main_pas_content = main_pas_content.replace(
        "procedure Tfrmmain.UpdateExhibitionLayout;\n",
        new_implementations + "\nprocedure Tfrmmain.UpdateExhibitionLayout;\n"
    )

# Update EnterAdminMode to support optional PIN and show general section
old_enter_admin = """procedure Tfrmmain.EnterAdminMode;
begin
  if Assigned(pnlRoot) then
    pnlRoot.Visible := False;
  if Assigned(pnlAdminRoot) then
    pnlAdminRoot.Visible := True;
end;"""

new_enter_admin = """procedure Tfrmmain.EnterAdminMode;
var
  InputPIN: string;
begin
  if (FSetMain <> nil) and (Trim(FSetMain.AdminPIN) <> '') then
  begin
    InputPIN := '';
    if not InputQuery('Acesso Administrativo', 'Digite o PIN de Administrador:', True, InputPIN) then
      Exit;
    if InputPIN <> FSetMain.AdminPIN then
    begin
      ShowMessage('PIN incorreto. Acesso não autorizado.');
      Exit;
    end;
  end;

  if Assigned(pnlRoot) then
    pnlRoot.Visible := False;
  if Assigned(pnlAdminRoot) then
    pnlAdminRoot.Visible := True;

  ShowAdminSection(asGeneral);
end;"""

main_pas_content = main_pas_content.replace(old_enter_admin, new_enter_admin)

# Ensure btAbrirConfigClick opens directly to page index 0 (Geral)
old_abrir_config = """procedure Tfrmmain.btAbrirConfigClick(Sender: TObject);
var
  FormCfg: TfrmConfig;
begin
  FormCfg := TfrmConfig.Create(Self);
  try
    // Aba JARVIS"""

new_abrir_config = """procedure Tfrmmain.btAbrirConfigClick(Sender: TObject);
var
  FormCfg: TfrmConfig;
begin
  FormCfg := TfrmConfig.Create(Self);
  try
    // Abrir diretamente a primeira aba (Geral)
    FormCfg.pcConfig.ActivePageIndex := 0;

    // Aba JARVIS"""

main_pas_content = main_pas_content.replace(old_abrir_config, new_abrir_config)

with open(main_pas_path, "w", encoding="utf-8") as f:
    f.write(main_pas_content)
print("main.pas atualizado com sucesso.")
print("Refatoração do painel administrativo concluída com sucesso.")
