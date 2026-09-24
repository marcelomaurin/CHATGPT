# -*- coding: utf-8 -*-
"""
Script de implementação dos Modos Visuais Públicos do Professor Virtual:
- TPublicViewMode: pvmIdle, pvmConversation, pvmContent, pvmPresentation
- Startup neutro: sem ECG ou apresentação automática
- SetPublicViewMode centralizando as transições
- ShowConversationAnswer vs ShowContentAnswer
- TAIPresentationAgent e Kinect desacoplados de disparo forçado
- Remoção definitiva de campos e handlers legados mortos
"""

import os
import re

assistente_dir = r"P:\maurinsoft\Assistente"
main_lfm_path = os.path.join(assistente_dir, "src", "main.lfm")
main_pas_path = os.path.join(assistente_dir, "src", "main.pas")

print("Iniciando implementação dos modos visuais e neutralidade inicial...")

# -------------------------------------------------------------
# 1. Atualizar main.lfm (Valores iniciais neutros)
# -------------------------------------------------------------
with open(main_lfm_path, "r", encoding="utf-8") as f:
    lfm_text = f.read()

# pnlProjectHeader não visível no startup
lfm_text = lfm_text.replace(
    """        object pnlProjectHeader: TPanel
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
          TabOrder = 0""",
    """        object pnlProjectHeader: TPanel
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
          Visible = False"""
)

# lblProjectTitle: 'Como posso ajudar?'
lfm_text = lfm_text.replace(
    "Caption = 'PROFESSOR VIRTUAL'\n            Font.Color = 16761152\n            Font.Height = -18\n            Font.Style = [fsBold]",
    "Caption = 'Como posso ajudar?'\n            Font.Color = 16761152\n            Font.Height = -18\n            Font.Style = [fsBold]"
)

# lblTopicSubtitle: vazio no startup
lfm_text = lfm_text.replace(
    "Caption = 'Projetos de Pesquisa e Extensão da FATEC Ribeirão Preto'",
    "Caption = ''\n            Visible = False"
)

# lblResourcePlaceholder: neutro
lfm_text = lfm_text.replace(
    "Caption = 'Conteúdo visual da apresentação em preparação'",
    "Caption = 'Pergunte sobre os projetos, tecnologias ou demonstrações disponíveis.'"
)

# lblNarrative: neutro
lfm_text = lfm_text.replace(
    """Caption = '"Aproxime-se para conhecer as pesquisas desenvolvidas em nossa instituição..."'""",
    """Caption = '"Olá! Sou o Professor Virtual da FATEC Ribeirão Preto. Como posso ajudar?"'"""
)

with open(main_lfm_path, "w", encoding="utf-8") as f:
    f.write(lfm_text)
print("main.lfm atualizado com estado inicial neutro.")

# -------------------------------------------------------------
# 2. Atualizar main.pas
# -------------------------------------------------------------
with open(main_pas_path, "r", encoding="utf-8") as f:
    pas_text = f.read()

# 2.1 Adicionar fpjson e jsonparser no uses
if "fpjson" not in pas_text:
    pas_text = pas_text.replace(
        "uses\n  Classes, SysUtils,",
        "uses\n  Classes, SysUtils, fpjson, jsonparser,"
    )

# 2.2 Definir TPublicViewMode e TAssistantVisualAction
visual_mode_types = """type
  TPublicViewMode = (
    pvmIdle,
    pvmConversation,
    pvmContent,
    pvmPresentation
  );

  TAssistantVisualAction = (
    avaNone,
    avaShowText,
    avaShowResource,
    avaStartPresentation
  );
"""

if "TPublicViewMode = (" not in pas_text:
    pas_text = pas_text.replace(
        "type\n",
        visual_mode_types + "\n"
    )

# 2.3 Remover campos mortos antigos do layout
dead_fields_block = """    { Controles da Interface de Exposicao / Professor Virtual }
    pnlExposicao: TPanel;
    pnlRecursoMoldura: TPanel;
    pnlExposicaoFooter: TPanel;
    imgRecursoExposicao: TImage;
    lblFatecHeader: TLabel;
    lblNarrativaExposicao: TLabel;
    lblRecursoDescricao: TLabel;
    btExposicaoContinuar: TBitBtn;
    btExposicaoProximo: TBitBtn;
    btAdminToggle: TBitBtn;
"""
if dead_fields_block in pas_text:
    pas_text = pas_text.replace(dead_fields_block, "")

# Remover declarações antigas de métodos mortos
for dead_proc in [
    "    procedure btExposicaoContinuarClick(Sender: TObject);\n",
    "    procedure btExposicaoProximoClick(Sender: TObject);\n",
    "    procedure btAdminToggleClick(Sender: TObject);\n",
    "    procedure InitExposicaoUI;\n"
]:
    if dead_proc in pas_text:
        pas_text = pas_text.replace(dead_proc, "")

# 2.4 Declarar novos campos e métodos no private
new_private_fields = """    FPublicViewMode: TPublicViewMode;
    FAllowVisualResource: Boolean;
    FDisplayedProject: string;
    FDisplayedResourceID: string;
"""
if "FPublicViewMode: TPublicViewMode;" not in pas_text:
    pas_text = pas_text.replace(
        "    FCurrentAdminSection: TAdminSection;\n",
        "    FCurrentAdminSection: TAdminSection;\n" + new_private_fields
    )

new_private_methods = """    procedure SetPublicViewMode(AMode: TPublicViewMode);
    procedure ShowConversationAnswer(const AText: string);
    procedure ShowContentAnswer(const ATitle, ASubtitle, AImagePath, AText: string);
"""
if "procedure SetPublicViewMode" not in pas_text:
    pas_text = pas_text.replace(
        "    procedure UpdateExhibitionLayout;\n",
        new_private_methods + "    procedure UpdateExhibitionLayout;\n"
    )

# 2.5 Remover implementações antigas mortas (btExposicaoContinuarClick, etc.)
dead_impl_pattern = re.compile(
    r"procedure Tfrmmain\.btExposicaoContinuarClick\(Sender: TObject\);.*?procedure Tfrmmain\.OnPresentationResourceSelected",
    re.DOTALL
)
if dead_impl_pattern.search(pas_text):
    pas_text = dead_impl_pattern.sub("procedure Tfrmmain.OnPresentationResourceSelected", pas_text)

dead_init_ui = re.compile(
    r"procedure Tfrmmain\.InitExposicaoUI;.*?end;\n",
    re.DOTALL
)
if dead_init_ui.search(pas_text):
    pas_text = dead_init_ui.sub("", pas_text)

# 2.6 Implementar SetPublicViewMode, ShowConversationAnswer, ShowContentAnswer
methods_impl = """
procedure Tfrmmain.SetPublicViewMode(AMode: TPublicViewMode);
begin
  FPublicViewMode := AMode;

  case AMode of
    pvmIdle:
    begin
      if Assigned(pnlRoot) then pnlRoot.Visible := True;
      if Assigned(pnlAdminRoot) then pnlAdminRoot.Visible := False;
      if Assigned(pnlProjectHeader) then pnlProjectHeader.Visible := False;
      if Assigned(imgResource) then
      begin
        imgResource.Picture.Clear;
        imgResource.Visible := False;
      end;
      if Assigned(lblResourceCaption) then
      begin
        lblResourceCaption.Caption := '';
        lblResourceCaption.Visible := False;
      end;
      if Assigned(lblResourcePlaceholder) then
      begin
        lblResourcePlaceholder.Caption := 'Pergunte sobre os projetos, tecnologias ou demonstrações disponíveis.';
        lblResourcePlaceholder.Visible := True;
      end;
      if Assigned(pnlNarrativeContainer) then pnlNarrativeContainer.Visible := True;
      if Assigned(lblProjectTitle) then lblProjectTitle.Caption := 'Como posso ajudar?';
      if Assigned(lblTopicSubtitle) then
      begin
        lblTopicSubtitle.Caption := '';
        lblTopicSubtitle.Visible := False;
      end;
      SetNarrativeText('Olá! Sou o Professor Virtual da FATEC Ribeirão Preto. Como posso ajudar?');
      SetProfessorState('idle');
      FAllowVisualResource := False;
    end;

    pvmConversation:
    begin
      if Assigned(pnlProjectHeader) then pnlProjectHeader.Visible := False;
      if Assigned(imgResource) then imgResource.Visible := False;
      if Assigned(lblResourceCaption) then lblResourceCaption.Visible := False;
      if Assigned(lblResourcePlaceholder) then
      begin
        lblResourcePlaceholder.Caption := 'Como posso ajudar? Faça uma pergunta para começar.';
        lblResourcePlaceholder.Visible := True;
      end;
      if Assigned(pnlNarrativeContainer) then pnlNarrativeContainer.Visible := True;
      FAllowVisualResource := False;
    end;

    pvmContent:
    begin
      if Assigned(pnlProjectHeader) then pnlProjectHeader.Visible := True;
      if Assigned(pnlNarrativeContainer) then pnlNarrativeContainer.Visible := True;
      FAllowVisualResource := True;
      SetProfessorState('showing_content');
    end;

    pvmPresentation:
    begin
      if Assigned(pnlProjectHeader) then pnlProjectHeader.Visible := True;
      if Assigned(pnlNarrativeContainer) then pnlNarrativeContainer.Visible := True;
      FAllowVisualResource := True;
      SetProfessorState('presenting');
    end;
  end;
end;

procedure Tfrmmain.ShowConversationAnswer(const AText: string);
begin
  SetPublicViewMode(pvmConversation);
  SetNarrativeText(AText);
end;

procedure Tfrmmain.ShowContentAnswer(const ATitle, ASubtitle, AImagePath, AText: string);
begin
  ShowPresentationResource(ATitle, ASubtitle, AImagePath, AText);
end;
"""

if "procedure Tfrmmain.SetPublicViewMode" not in pas_text:
    pas_text = pas_text.replace(
        "procedure Tfrmmain.UpdateExhibitionLayout;\n",
        methods_impl + "\nprocedure Tfrmmain.UpdateExhibitionLayout;\n"
    )

# 2.7 Atualizar ClearPresentationResource
new_clear_resource = """procedure Tfrmmain.ClearPresentationResource;
begin
  if Assigned(imgResource) then
  begin
    imgResource.Picture.Clear;
    imgResource.Visible := False;
  end;

  if Assigned(lblResourceCaption) then
  begin
    lblResourceCaption.Caption := '';
    lblResourceCaption.Visible := False;
  end;

  if Assigned(lblTopicSubtitle) then
  begin
    lblTopicSubtitle.Caption := '';
    lblTopicSubtitle.Visible := False;
  end;

  SetPublicViewMode(pvmIdle);
end;"""

old_clear_pattern = re.compile(r"procedure Tfrmmain\.ClearPresentationResource;.*?end;", re.DOTALL)
pas_text = old_clear_pattern.sub(lambda m: new_clear_resource, pas_text)

# 2.8 Atualizar ShowPresentationResource
new_show_resource = """procedure Tfrmmain.ShowPresentationResource(const ATitle, ASubtitle, AImagePath, ANarrative: string);
begin
  SetPublicViewMode(pvmContent);

  if Assigned(lblProjectTitle) then
  begin
    if Trim(ATitle) <> '' then
    begin
      lblProjectTitle.Caption := UpperCase(Trim(ATitle));
      FDisplayedProject := Trim(ATitle);
    end
    else
      lblProjectTitle.Caption := 'PROJETO';
    lblProjectTitle.Visible := True;
  end;

  if Assigned(lblTopicSubtitle) then
  begin
    lblTopicSubtitle.Caption := Trim(ASubtitle);
    lblTopicSubtitle.Visible := (Trim(ASubtitle) <> '');
  end;

  if Trim(ANarrative) <> '' then
    SetNarrativeText(ANarrative);

  if Assigned(imgResource) and (Trim(AImagePath) <> '') and FileExists(AImagePath) then
  begin
    try
      imgResource.Picture.LoadFromFile(AImagePath);
      imgResource.Visible := True;
      FDisplayedResourceID := AImagePath;
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
end;"""

old_show_pattern = re.compile(r"procedure Tfrmmain\.ShowPresentationResource\(const ATitle.*?;.*?end;", re.DOTALL)
pas_text = old_show_pattern.sub(lambda m: new_show_resource, pas_text)

# 2.9 Atualizar SetProfessorState
new_professor_state = """procedure Tfrmmain.SetProfessorState(const AState: string);
var
  S: string;
begin
  if not Assigned(lblProfessorStatus) then Exit;
  S := LowerCase(Trim(AState));
  if (S = 'listening') or (S = 'ouvir') or (S = 'ouvindo') then
  begin
    lblProfessorStatus.Font.Color := $0000FF99;
    lblProfessorStatus.Caption := '🎤 Ouvindo...';
    if FAvatar3D <> nil then
      FAvatar3D.SetState(avListening);
  end
  else if (S = 'thinking') or (S = 'pensando') then
  begin
    lblProfessorStatus.Font.Color := $00FFC040;
    lblProfessorStatus.Caption := '🧠 Pensando...';
    if FAvatar3D <> nil then
      FAvatar3D.SetState(avThinking);
  end
  else if (S = 'speaking') or (S = 'falando') or (S = 'respondendo') then
  begin
    lblProfessorStatus.Font.Color := $0000D4FF;
    lblProfessorStatus.Caption := '🗣️ Respondendo...';
    if FAvatar3D <> nil then
      FAvatar3D.SetState(avSpeaking);
  end
  else if (S = 'showing_content') or (S = 'mostrando_conteudo') or (S = 'conteudo') then
  begin
    lblProfessorStatus.Font.Color := $0000D4FF;
    lblProfessorStatus.Caption := '📖 Mostrando conteúdo';
    if FAvatar3D <> nil then
      FAvatar3D.SetState(avIdle);
  end
  else if (S = 'presenting') or (S = 'apresentando') then
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
end;"""

old_state_pattern = re.compile(r"procedure Tfrmmain\.SetProfessorState\(const AState: string\);.*?end;", re.DOTALL)
pas_text = old_state_pattern.sub(lambda m: new_professor_state, pas_text)

# 2.10 Atualizar OnVoiceSpeechStart e OnVoiceSpeechEnd
new_voice_events = """procedure Tfrmmain.OnVoiceSpeechStart(Sender: TObject);
begin
  if FAvatar3D <> nil then
    FAvatar3D.SetState(avSpeaking);
  if FPublicViewMode = pvmPresentation then
    SetProfessorState('presenting')
  else
    SetProfessorState('speaking');
end;

procedure Tfrmmain.OnVoiceSpeechEnd(Sender: TObject);
begin
  if FAvatar3D <> nil then
    FAvatar3D.SetState(avIdle);
  if FPublicViewMode = pvmPresentation then
    SetProfessorState('presenting')
  else if FPublicViewMode = pvmContent then
    SetProfessorState('showing_content')
  else
    SetProfessorState('idle');
end;"""

old_voice_pattern = re.compile(r"procedure Tfrmmain\.OnVoiceSpeechStart.*?procedure Tfrmmain\.OnVoiceSpeechEnd.*?end;", re.DOTALL)
pas_text = old_voice_pattern.sub(lambda m: new_voice_events, pas_text)

# 2.11 Atualizar FormCreate: Remover StartPresentation automático e colocar pvmIdle
old_formcreate_call = """  // Inicia exposicao autonoma do primeiro projeto de destaque
  FPresentationAgent.StartPresentation('', 'Visitante');"""

new_formcreate_call = """  // Modo inicial neutro e receptivo (aguarda pergunta do usuario)
  SetPublicViewMode(pvmIdle);
  SetProfessorState('idle');"""

if old_formcreate_call in pas_text:
    pas_text = pas_text.replace(old_formcreate_call, new_formcreate_call)
elif "FPresentationAgent.StartPresentation('', 'Visitante');" in pas_text:
    pas_text = pas_text.replace("FPresentationAgent.StartPresentation('', 'Visitante');", new_formcreate_call)

# Remover chamada a InitExposicaoUI no FormCreate se houver
pas_text = pas_text.replace("  InitExposicaoUI;\n", "")

# 2.12 Atualizar OnKinectPersonEntered: Não iniciar apresentação, apenas saudar
old_person_entered = """  // Inicia ou resume apresentacao autonoma caso o professor esteja ocioso
  if (FPresentationAgent <> nil) and (FPresentationAgent.State = psIdle) then
  begin
    FPresentationAgent.StartPresentation(IntToStr(ATrackingID), 'Visitante');
  end;"""

new_person_entered = """  // Apenas saúda o visitante e aguarda perguntas (não inicia apresentação automática)
  SetPublicViewMode(pvmIdle);
  SetProfessorState('greeting');
  if (FSetMain <> nil) and FSetMain.AutoSpeak then
    FalaTexto('Olá! Sou o Professor Virtual. Como posso ajudar você hoje?');"""

if old_person_entered in pas_text:
    pas_text = pas_text.replace(old_person_entered, new_person_entered)

# 2.13 Atualizar OnKinectDeicticResolved: Não trocar de projeto diretamente
old_deictic = """  // Apresentacao autonoma migra diretamente para o projeto apontado
  if FPresentationAgent <> nil then
  begin
    FPresentationAgent.StartPresentation('visitante', 'Visitante', ATarget);
  end;"""

new_deictic = """  // Atualiza apenas contexto sem forçar troca imediata de tela
  if FConversationOrchestrator <> nil then
    FConversationOrchestrator.Context.CurrentProject := ATarget;"""

if old_deictic in pas_text:
    pas_text = pas_text.replace(old_deictic, new_deictic)

# 2.14 Atualizar OnPresentationResourceSelected (respeitar FAllowVisualResource e pvmPresentation)
new_on_resource = """procedure Tfrmmain.OnPresentationResourceSelected(Sender: TObject; AResource: TPresentationResource);
var
  ImgFile: string;
begin
  if AResource = nil then Exit;
  // Só exibe recurso visual se a exibição for autorizada ou se estiver apresentando
  if (FPublicViewMode <> pvmPresentation) and (not FAllowVisualResource) then Exit;

  ImgFile := AResource.FilePath;
  if not FileExists(ImgFile) then
    ImgFile := ExtractFilePath(Application.ExeName) + AResource.FilePath;
  if not FileExists(ImgFile) then
    ImgFile := ExtractFilePath(Application.ExeName) + 'img' + PathDelim + ExtractFileName(AResource.FilePath);
  if not FileExists(ImgFile) then
    ImgFile := 'D:\\projetos\\maurinsoft\\Assistente\\img\\' + ExtractFileName(AResource.FilePath);

  ShowPresentationResource(AResource.Title, AResource.Description, ImgFile, '');
end;"""

old_resource_pattern = re.compile(r"procedure Tfrmmain\.OnPresentationResourceSelected\(Sender: TObject; AResource: TPresentationResource\);.*?end;", re.DOTALL)
pas_text = old_resource_pattern.sub(lambda m: new_on_resource, pas_text)

# 2.15 Atualizar OnPresentationProjectChanged (atualizar tela somente se pvmPresentation ou pvmContent)
new_on_project = """procedure Tfrmmain.OnPresentationProjectChanged(Sender: TObject; APackage: TPresentationPackage);
begin
  if APackage = nil then Exit;
  if FAssistantManager <> nil then
    FAssistantManager.ActiveProject := APackage.ProjectCode;

  // Atualiza a tela pública somente se a apresentação ou conteúdo visual estiverem ativos
  if FPublicViewMode in [pvmPresentation, pvmContent] then
  begin
    FDisplayedProject := APackage.ProjectCode;
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
  end;

  lblJarvisStatusBadge.Caption := '● EXPOSIÇÃO: ' + UpperCase(APackage.ProjectCode);
  lblJarvisSub.Caption := APackage.Title;
end;"""

old_project_pattern = re.compile(r"procedure Tfrmmain\.OnPresentationProjectChanged\(Sender: TObject; APackage: TPresentationPackage\);.*?end;", re.DOTALL)
pas_text = old_project_pattern.sub(lambda m: new_on_project, pas_text)

# 2.16 Atualizar OnAgentComplete para decidir a ação visual conforme Tarefas 20-24
new_agent_complete = """procedure Tfrmmain.OnAgentComplete(Sender: TObject; const AResponseText, AProvider: string; ASuccess: Boolean);
var
  JData: TJSONData;
  JObj: TJSONObject;
  VisualActStr: string;
  VisualAction: TAssistantVisualAction;
  ProjStr, SubtitleStr, ImgPathStr, SpokenText: string;
begin
  AdicionaMensagemHistorico('Assistente (' + AProvider + ')', AResponseText);

  // Registra no histórico da sessão da pessoa ativa
  if (FConversationOrchestrator <> nil) and (FConversationOrchestrator.SessionManager.ActiveSession <> nil) then
  begin
    FConversationOrchestrator.SessionManager.ActiveSession.AddMessage('assistant', AResponseText);
    if FConversationOrchestrator.Context.CurrentProject <> '' then
      FConversationOrchestrator.SessionManager.ActiveSession.CurrentProject := FConversationOrchestrator.Context.CurrentProject;
  end;

  // Aplica resposta estruturada ou texto no avatar
  if FAvatar3D <> nil then
  begin
    if ASuccess then
      FAvatar3D.ApplyAgentResponse(AResponseText)
    else
      FAvatar3D.SetState(avError);
  end;

  // Default da ação visual: avaNone (não mostrar conteúdo obrigatório)
  VisualAction := avaNone;
  SpokenText := AResponseText;
  ProjStr := '';
  SubtitleStr := '';
  ImgPathStr := '';

  // Tenta extrair ação visual caso a IA retorne instrução estruturada
  if (Pos('{', AResponseText) > 0) and (Pos('}', AResponseText) > 0) then
  begin
    try
      JData := GetJSON(AResponseText);
      if JData is TJSONObject then
      begin
        JObj := TJSONObject(JData);
        if JObj.Find('visual_action') <> nil then
        begin
          VisualActStr := LowerCase(Trim(JObj.Get('visual_action', '')));
          if (VisualActStr = 'show_resource') or (VisualActStr = 'show_content') then
            VisualAction := avaShowResource
          else if VisualActStr = 'start_presentation' then
            VisualAction := avaStartPresentation
          else if VisualActStr = 'show_text' then
            VisualAction := avaShowText;
        end;

        if JObj.Find('project') <> nil then
          ProjStr := JObj.Get('project', '');
        if JObj.Find('title') <> nil then
          ProjStr := JObj.Get('title', ProjStr);
        if JObj.Find('subtitle') <> nil then
          SubtitleStr := JObj.Get('subtitle', '');
        if JObj.Find('resource') <> nil then
          ImgPathStr := JObj.Get('resource', '');
        if JObj.Find('image') <> nil then
          ImgPathStr := JObj.Get('image', ImgPathStr);
        if JObj.Find('speech') <> nil then
          SpokenText := JObj.Get('speech', SpokenText)
        else if JObj.Find('message') <> nil then
          SpokenText := JObj.Get('message', SpokenText);
      end;
      JData.Free;
    except
      VisualAction := avaNone;
    end;
  end;

  // Executa decisão visual
  case VisualAction of
    avaShowResource:
    begin
      FAllowVisualResource := True;
      ShowContentAnswer(ProjStr, SubtitleStr, ImgPathStr, SpokenText);
    end;
    avaStartPresentation:
    begin
      FAllowVisualResource := True;
      SetPublicViewMode(pvmPresentation);
      SetNarrativeText(SpokenText);
      if FPresentationAgent <> nil then
        FPresentationAgent.StartPresentation('visitante', 'Visitante', ProjStr);
    end;
  else
    // Default: resposta apenas em modo conversa, mantendo neutralidade visual
    ShowConversationAnswer(SpokenText);
  end;

  if (FSetMain <> nil) and FSetMain.AutoSpeak then
    FalaTexto(SpokenText);

  FAguardandoResposta := False;
  btEnviar.Enabled := True;
  lblJarvisSub.Caption := 'Central de Automação & Multi-IA';
end;"""

old_agent_complete_pattern = re.compile(r"procedure Tfrmmain\.OnAgentComplete\(Sender: TObject; const AResponseText.*?;.*?end;", re.DOTALL)
pas_text = old_agent_complete_pattern.sub(lambda m: new_agent_complete, pas_text)

with open(main_pas_path, "w", encoding="utf-8") as f:
    f.write(pas_text)
print("main.pas atualizado com sucesso.")
print("Implementação dos modos visuais concluída.")
