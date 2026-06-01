unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, aivoicesynthesizer;

type

  { TfrmVoiceDemo }

  TfrmVoiceDemo = class(TForm)
    pnlConfig: TPanel;
    lblVolume: TLabel;
    tbVolume: TTrackBar;
    lblVolumeVal: TLabel;
    
    lblRate: TLabel;
    tbRate: TTrackBar;
    lblRateVal: TLabel;
    
    cbAsynchronous: TCheckBox;
    
    lblVoiceName: TLabel;
    lbVoices: TListBox;
    
    pnlSpeak: TPanel;
    lblSpeakTitle: TLabel;
    meText: TMemo;
    btnSpeak: TButton;
    
    lblStatus: TLabel;
    meLogs: TMemo;
    lblLogs: TLabel;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnSpeakClick(Sender: TObject);
    procedure tbVolumeChange(Sender: TObject);
    procedure tbRateChange(Sender: TObject);
  private
    FAIVoice: TAIVoiceSynthesizer;
    procedure LogMsg(const AMsg: string);
    procedure UpdateStatusUI;
  public

  end;

var
  frmVoiceDemo: TfrmVoiceDemo;

implementation

{$R *.lfm}

{ TfrmVoiceDemo }

procedure TfrmVoiceDemo.FormCreate(Sender: TObject);
var
  SysName: string;
begin
  FAIVoice := TAIVoiceSynthesizer.Create(Self);

  // Set default initial values to match component defaults
  tbVolume.Position := 100;
  tbRate.Position := 0;
  cbAsynchronous.Checked := True;
  
  {$IFDEF MSWINDOWS}
  SysName := 'Windows (SAPI Nativo)';
  {$ELSE}
  SysName := 'Linux (eSpeak/eSpeak-NG)';
  {$ENDIF}

  // Populate ListBox with native system voices
  LogMsg('Buscando vozes disponíveis no sistema operacional...');
  FAIVoice.GetAvailableVoices(lbVoices.Items);
  
  if lbVoices.Items.Count > 0 then
    lbVoices.ItemIndex := 0
  else
    LogMsg('Nenhuma voz encontrada. O sistema usará a voz padrão.');

  UpdateStatusUI;
  
  LogMsg('Demonstração do Componente TAIVoiceSynthesizer Iniciada.');
  LogMsg('Sistema de Voz detectado: ' + SysName);
  LogMsg('Ajuste o volume, velocidade e selecione uma voz para falar!');
end;

procedure TfrmVoiceDemo.FormDestroy(Sender: TObject);
begin
  // O componente FAIVoice será liberado automaticamente pois tem Self como Owner
end;

procedure TfrmVoiceDemo.LogMsg(const AMsg: string);
begin
  meLogs.Lines.Append('[' + FormatDateTime('hh:nn:ss', Now) + '] ' + AMsg);
end;

procedure TfrmVoiceDemo.UpdateStatusUI;
begin
  lblStatus.Caption := Format('Volume: %d%% | Velocidade: %d | Assíncrono: %s', 
    [tbVolume.Position, tbRate.Position, BoolToStr(cbAsynchronous.Checked, 'Sim', 'Não')]);
end;

procedure TfrmVoiceDemo.tbVolumeChange(Sender: TObject);
begin
  lblVolumeVal.Caption := IntToStr(tbVolume.Position) + '%';
  UpdateStatusUI;
end;

procedure TfrmVoiceDemo.tbRateChange(Sender: TObject);
begin
  lblRateVal.Caption := IntToStr(tbRate.Position);
  UpdateStatusUI;
end;

procedure TfrmVoiceDemo.btnSpeakClick(Sender: TObject);
var
  Txt: string;
begin
  Txt := Trim(meText.Text);
  if Txt = '' then
  begin
    ShowMessage('Por favor, insira o texto que você deseja falar!');
    Exit;
  end;

  LogMsg('Configurando propriedades do componente...');
  FAIVoice.Volume := tbVolume.Position;
  FAIVoice.Rate := tbRate.Position;
  FAIVoice.Asynchronous := cbAsynchronous.Checked;
  
  if lbVoices.ItemIndex >= 0 then
    FAIVoice.VoiceName := lbVoices.Items[lbVoices.ItemIndex]
  else
    FAIVoice.VoiceName := '';

  LogMsg(Format('Sintetizando voz: "%s"', [Txt]));
  if FAIVoice.VoiceName <> '' then
    LogMsg('Voz Selecionada: ' + FAIVoice.VoiceName)
  else
    LogMsg('Voz Selecionada: Padrão do Sistema');

  FAIVoice.Say(Txt);

  if FAIVoice.LastError <> '' then
  begin
    LogMsg('ERRO na sintetização: ' + FAIVoice.LastError);
    ShowMessage('Erro na sintetização de voz: ' + FAIVoice.LastError);
  end
  else
  begin
    LogMsg('Comando de sintetização enviado com sucesso.');
  end;
end;

end.
