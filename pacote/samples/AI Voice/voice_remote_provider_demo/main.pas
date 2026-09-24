unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  aivoiceprovider_types, aivoicesynthesizer;

type

  { TfrmVoiceRemoteDemo }

  TfrmVoiceRemoteDemo = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlConfig: TPanel;
    lblProvider: TLabel;
    cbProvider: TComboBox;
    lblEndpoint: TLabel;
    edtEndpoint: TEdit;
    lblToken: TLabel;
    edtToken: TEdit;
    btnToggleToken: TButton;
    lblModel: TLabel;
    edtModel: TEdit;
    lblVoice: TLabel;
    edtVoice: TEdit;
    lblLanguage: TLabel;
    cbLanguage: TComboBox;
    lblFormat: TLabel;
    cbFormat: TComboBox;
    lblSpeed: TLabel;
    edtSpeed: TEdit;
    btnTestConfig: TButton;
    btnSpeak: TButton;
    btnStop: TButton;
    lblTextPrompt: TLabel;
    edtText: TEdit;
    pnlLogs: TPanel;
    lblLogs: TLabel;
    memoLog: TMemo;
    btnClearLog: TButton;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cbProviderChange(Sender: TObject);
    procedure btnToggleTokenClick(Sender: TObject);
    procedure btnTestConfigClick(Sender: TObject);
    procedure btnSpeakClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
  private
    FAIVoice: TAIVoiceSynthesizer;
    FTokenMasked: Boolean;
    procedure AddLog(const AMsg: string);
    procedure ApplyFieldsToVoice;
    procedure OnSynthesisStartEvent(Sender: TObject);
    procedure OnSynthesisEndEvent(Sender: TObject);
    procedure OnSpeechStartEvent(Sender: TObject);
    procedure OnSpeechEndEvent(Sender: TObject);
  public

  end;

var
  frmVoiceRemoteDemo: TfrmVoiceRemoteDemo;

implementation

{$R *.lfm}

{ TfrmVoiceRemoteDemo }

procedure TfrmVoiceRemoteDemo.FormCreate(Sender: TObject);
begin
  FTokenMasked := True;
  FAIVoice := TAIVoiceSynthesizer.Create(Self);
  FAIVoice.OnSynthesisStart := @OnSynthesisStartEvent;
  FAIVoice.OnSynthesisEnd := @OnSynthesisEndEvent;
  FAIVoice.OnSpeechStart := @OnSpeechStartEvent;
  FAIVoice.OnSpeechEnd := @OnSpeechEndEvent;

  cbProvider.Items.Clear;
  cbProvider.Items.Add('OpenAI');
  cbProvider.Items.Add('OpenAI-Compatible');
  cbProvider.Items.Add('Custom HTTP');
  cbProvider.ItemIndex := 0;

  cbLanguage.Items.Clear;
  cbLanguage.Items.Add('pt-BR');
  cbLanguage.Items.Add('en-US');
  cbLanguage.Items.Add('es-ES');
  cbLanguage.Items.Add('fr-FR');
  cbLanguage.ItemIndex := 0;

  cbFormat.Items.Clear;
  cbFormat.Items.Add('mp3');
  cbFormat.Items.Add('wav');
  cbFormat.ItemIndex := 0;

  edtEndpoint.Text := 'https://api.openai.com/v1/audio/speech';
  edtModel.Text := 'gpt-4o-mini-tts';
  edtVoice.Text := 'alloy';
  edtSpeed.Text := '1.0';

  AddLog('Voice Remote Provider Demo inicializado.');
  AddLog('Selecione o provedor, preencha as credenciais e clique em Testar ou Falar.');
end;

procedure TfrmVoiceRemoteDemo.FormDestroy(Sender: TObject);
begin
  // Handled by LCL Owner
end;

procedure TfrmVoiceRemoteDemo.cbProviderChange(Sender: TObject);
begin
  case cbProvider.ItemIndex of
    0: // OpenAI
    begin
      edtEndpoint.Text := 'https://api.openai.com/v1/audio/speech';
      edtModel.Text := 'gpt-4o-mini-tts';
      edtVoice.Text := 'alloy';
    end;
    1: // OpenAI-Compatible
    begin
      edtEndpoint.Text := 'http://localhost:8000/v1/audio/speech';
      edtModel.Text := 'tts-1';
      edtVoice.Text := 'default';
    end;
    2: // Custom HTTP
    begin
      edtEndpoint.Text := 'http://localhost:5000/api/tts';
      edtModel.Text := 'custom-model';
      edtVoice.Text := 'speaker-0';
    end;
  end;
  AddLog('Provedor alterado para: ' + cbProvider.Text);
end;

procedure TfrmVoiceRemoteDemo.btnToggleTokenClick(Sender: TObject);
begin
  FTokenMasked := not FTokenMasked;
  if FTokenMasked then
  begin
    edtToken.EchoMode := emPassword;
    edtToken.PasswordChar := '*';
    btnToggleToken.Caption := 'Mostrar';
  end
  else
  begin
    edtToken.EchoMode := emNormal;
    btnToggleToken.Caption := 'Ocultar';
  end;
end;

procedure TfrmVoiceRemoteDemo.ApplyFieldsToVoice;
begin
  case cbProvider.ItemIndex of
    0: FAIVoice.Provider := vpOpenAI;
    1: FAIVoice.Provider := vpOpenAICompatible;
    2: FAIVoice.Provider := vpCustomHTTP;
  else
    FAIVoice.Provider := vpNone;
  end;

  FAIVoice.APIToken := Trim(edtToken.Text);
  FAIVoice.Endpoint := Trim(edtEndpoint.Text);
  FAIVoice.Model := Trim(edtModel.Text);
  FAIVoice.RemoteVoice := Trim(edtVoice.Text);
  FAIVoice.Language := cbLanguage.Text;
  FAIVoice.OutputFormat := cbFormat.Text;
  try
    FAIVoice.Speed := StrToFloatDef(StringReplace(edtSpeed.Text, ',', '.', []), 1.0);
  except
    FAIVoice.Speed := 1.0;
  end;
end;

procedure TfrmVoiceRemoteDemo.btnTestConfigClick(Sender: TObject);
var
  Msg: string;
begin
  ApplyFieldsToVoice;
  AddLog('Validando configurações do provedor ' + cbProvider.Text + '...');

  if FAIVoice.TestConfiguration(Msg) then
  begin
    AddLog('[SUCESSO] Configuração válida: ' + Msg);
    ShowMessage('Configuração OK!' + LineEnding + Msg);
  end
  else
  begin
    AddLog('[ERRO] ' + Msg);
    ShowMessage('Falha na validação:' + LineEnding + Msg);
  end;
end;

procedure TfrmVoiceRemoteDemo.btnSpeakClick(Sender: TObject);
var
  Txt: string;
begin
  Txt := Trim(edtText.Text);
  if Txt = '' then
  begin
    ShowMessage('Por favor digite um texto para falar.');
    Exit;
  end;

  ApplyFieldsToVoice;
  AddLog(Format('Solicitando síntese para [%s] texto: "%s"', [cbProvider.Text, Txt]));
  FAIVoice.Say(Txt);

  if FAIVoice.LastError <> '' then
    AddLog('[ERRO] ' + FAIVoice.LastError);
end;

procedure TfrmVoiceRemoteDemo.btnStopClick(Sender: TObject);
begin
  FAIVoice.Stop;
  AddLog('Comando Stop enviado ao sintetizador.');
end;

procedure TfrmVoiceRemoteDemo.btnClearLogClick(Sender: TObject);
begin
  memoLog.Clear;
end;

procedure TfrmVoiceRemoteDemo.AddLog(const AMsg: string);
begin
  memoLog.Lines.Append('[' + FormatDateTime('hh:nn:ss', Now) + '] ' + AMsg);
end;

procedure TfrmVoiceRemoteDemo.OnSynthesisStartEvent(Sender: TObject);
begin
  AddLog('>> Evento OnSynthesisStart disparado (requisitando áudio ao provedor)...');
end;

procedure TfrmVoiceRemoteDemo.OnSynthesisEndEvent(Sender: TObject);
begin
  AddLog('>> Evento OnSynthesisEnd disparado (áudio recebido com sucesso).');
end;

procedure TfrmVoiceRemoteDemo.OnSpeechStartEvent(Sender: TObject);
begin
  AddLog('>> Evento OnSpeechStart disparado (iniciando reprodução do áudio).');
end;

procedure TfrmVoiceRemoteDemo.OnSpeechEndEvent(Sender: TObject);
begin
  AddLog('>> Evento OnSpeechEnd disparado (fala finalizada).');
end;

end.
