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
    
    lblSynthesizer: TLabel;
    lbSynthesizers: TListBox;
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
    procedure lbSynthesizersClick(Sender: TObject);
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
begin
  FAIVoice := TAIVoiceSynthesizer.Create(Self);

  // Set default initial values to match component defaults
  tbVolume.Position := 100;
  tbRate.Position := 0;
  cbAsynchronous.Checked := True;

  LogMsg('Preenchendo lista de sintetizadores disponíveis...');
  lbSynthesizers.Items.Clear;
  {$IFDEF MSWINDOWS}
  lbSynthesizers.Items.Add('SAPI (Windows)');
  lbSynthesizers.Items.Add('eSpeak');
  {$ELSE}
  lbSynthesizers.Items.Add('eSpeak');
  {$ENDIF}

  // Select the first synthesizer by default
  if lbSynthesizers.Items.Count > 0 then
  begin
    lbSynthesizers.ItemIndex := 0;
    lbSynthesizersClick(nil);
  end;

  LogMsg('Demonstração do Componente TAIVoiceSynthesizer Iniciada.');
  LogMsg('Selecione o sintetizador, regule os controles e fale!');
end;

procedure TfrmVoiceDemo.lbSynthesizersClick(Sender: TObject);
var
  SelectedEngine: string;
begin
  if lbSynthesizers.ItemIndex < 0 then Exit;
  
  SelectedEngine := lbSynthesizers.Items[lbSynthesizers.ItemIndex];
  LogMsg('Sintetizador selecionado: ' + SelectedEngine);

  if SelectedEngine = 'SAPI (Windows)' then
    FAIVoice.Engine := seSAPI
  else
    FAIVoice.Engine := seEspeak;

  LogMsg('Carregando vozes correspondentes...');
  FAIVoice.GetAvailableVoices(lbVoices.Items);

  if lbVoices.Items.Count > 0 then
  begin
    lbVoices.ItemIndex := 0;
    LogMsg(Format('Encontradas %d vozes disponíveis.', [lbVoices.Items.Count]));
  end
  else
  begin
    lbVoices.ItemIndex := -1;
    LogMsg('Nenhuma voz encontrada para este sintetizador. O sistema usará a voz padrão.');
  end;

  UpdateStatusUI;
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
