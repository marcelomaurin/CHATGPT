unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ComCtrls,
  ExtCtrls, StdCtrls, LCLIntf, Clipbrd,
  aibase, aivoicesynthesizer;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    lblStatus: TLabel;
    pgcMain: TPageControl;
    tsConfiguration: TTabSheet;
    tsSpeech: TTabSheet;
    tsOutput: TTabSheet;
    tsLog: TTabSheet;
    
    // Configuration controls
    lblEngine: TLabel;
    cbSpeechEngine: TComboBox;
    lblToken: TLabel;
    edtOpenAIToken: TEdit;
    lblModel: TLabel;
    cbOpenAIModel: TComboBox;
    lblVoice: TLabel;
    cbOpenAIVoice: TComboBox;
    lblLanguage: TLabel;
    cbLanguage: TComboBox;
    lblFormat: TLabel;
    cbOutputFormat: TComboBox;
    lblSpeed: TLabel;
    edtSpeed: TEdit;
    lblOutputFile: TLabel;
    edtOutputFile: TEdit;
    btnSelectOutputFile: TButton;
    btnApplyConfig: TButton;
    btnTestConfig: TButton;
    
    // Speech controls
    lblSpeechText: TLabel;
    memoSpeechText: TMemo;
    btnGenerateSpeech: TButton;
    btnClearText: TButton;
    btnLoadExample: TButton;
    
    // Output controls
    lblGeneratedFile: TLabel;
    edtGeneratedFile: TEdit;
    btnPlayAudio: TButton;
    btnOpenOutputFolder: TButton;
    btnCopyPath: TButton;
    lblLastResult: TLabel;
    memoLastResult: TMemo;
    
    // Log controls
    memoLog: TMemo;
    pnlLogButtons: TPanel;
    btnClearLog: TButton;
    
    // Dialogs
    dlgSaveAudio: TSaveDialog;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnSelectOutputFileClick(Sender: TObject);
    procedure btnApplyConfigClick(Sender: TObject);
    procedure btnTestConfigClick(Sender: TObject);
    procedure btnGenerateSpeechClick(Sender: TObject);
    procedure btnClearTextClick(Sender: TObject);
    procedure btnLoadExampleClick(Sender: TObject);
    procedure btnPlayAudioClick(Sender: TObject);
    procedure btnOpenOutputFolderClick(Sender: TObject);
    procedure btnCopyPathClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
  private
    FAIVoice: TAIVoiceSynthesizer;
    FExampleIndex: Integer;
    procedure AddLog(const AMsg: string);
    procedure ApplyConfiguration;
    procedure PlayAudioFile(const AFileName: string);
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

function ExtractLanguageCode(const AText: string): string;
var
  P: Integer;
begin
  P := Pos(' - ', AText);
  if P > 0 then
    Result := Copy(AText, 1, P - 1)
  else
    Result := Trim(AText);
    
  if Result = '' then
    Result := 'en-US';
end;

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FExampleIndex := 0;
  FAIVoice := TAIVoiceSynthesizer.Create(Self);
  AddLog('Voice Synthesizer Complete Demo initialized.');
  
  // Fill Configuration dropdowns
  cbSpeechEngine.Clear;
  cbSpeechEngine.Items.Add('OpenAI Voice API');
  cbSpeechEngine.Items.Add('Local System Voice');
  cbSpeechEngine.ItemIndex := 0;
  
  cbOpenAIModel.Clear;
  cbOpenAIModel.Items.Add('gpt-4o-mini-tts');
  cbOpenAIModel.Items.Add('tts-1');
  cbOpenAIModel.Items.Add('tts-1-hd');
  cbOpenAIModel.ItemIndex := 0;
  
  cbOpenAIVoice.Clear;
  cbOpenAIVoice.Items.Add('alloy');
  cbOpenAIVoice.Items.Add('ash');
  cbOpenAIVoice.Items.Add('ballad');
  cbOpenAIVoice.Items.Add('coral');
  cbOpenAIVoice.Items.Add('echo');
  cbOpenAIVoice.Items.Add('fable');
  cbOpenAIVoice.Items.Add('nova');
  cbOpenAIVoice.Items.Add('onyx');
  cbOpenAIVoice.Items.Add('sage');
  cbOpenAIVoice.Items.Add('shimmer');
  cbOpenAIVoice.Items.Add('verse');
  cbOpenAIVoice.Items.Add('marin');
  cbOpenAIVoice.Items.Add('cedar');
  cbOpenAIVoice.ItemIndex := 0;
  
  cbLanguage.Clear;
  cbLanguage.Items.Add('en-US - English (United States)');
  cbLanguage.Items.Add('en-GB - English (United Kingdom)');
  cbLanguage.Items.Add('pt-BR - Portuguese (Brazil)');
  cbLanguage.Items.Add('es-ES - Spanish (Spain)');
  cbLanguage.Items.Add('fr-FR - French (France)');
  cbLanguage.Items.Add('it-IT - Italian (Italy)');
  cbLanguage.Items.Add('de-DE - German (Germany)');
  cbLanguage.Items.Add('ja-JP - Japanese (Japan)');
  cbLanguage.Items.Add('zh-CN - Chinese (Simplified)');
  cbLanguage.ItemIndex := 0;
  
  cbOutputFormat.Clear;
  cbOutputFormat.Items.Add('mp3');
  cbOutputFormat.Items.Add('wav');
  cbOutputFormat.Items.Add('opus');
  cbOutputFormat.Items.Add('aac');
  cbOutputFormat.Items.Add('flac');
  cbOutputFormat.Items.Add('pcm');
  cbOutputFormat.ItemIndex := 0;

  memoSpeechText.Text := 'Welcome to the Lazarus AI Voice Synthesizer demo using the OpenAI Voice API.';
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Managed by LCL owner auto-free.
end;

procedure TfrmMain.btnSelectOutputFileClick(Sender: TObject);
begin
  dlgSaveAudio.FileName := edtOutputFile.Text;
  if dlgSaveAudio.Execute then
  begin
    edtOutputFile.Text := dlgSaveAudio.FileName;
    AddLog('Output file destination updated: ' + dlgSaveAudio.FileName);
  end;
end;

procedure TfrmMain.ApplyConfiguration;
begin
  if cbSpeechEngine.Text = 'OpenAI Voice API' then
    FAIVoice.Engine := seOpenAI
  else
    FAIVoice.Engine := seSystemDefault;

  FAIVoice.OpenAIToken := Trim(edtOpenAIToken.Text);
  FAIVoice.OpenAIModel := cbOpenAIModel.Text;
  FAIVoice.OpenAIVoice := cbOpenAIVoice.Text;
  FAIVoice.Language := ExtractLanguageCode(cbLanguage.Text);
  FAIVoice.OpenAIOutputFormat := cbOutputFormat.Text;
  FAIVoice.OpenAIOutputFile := edtOutputFile.Text;
  FAIVoice.Speed := StrToFloatDef(StringReplace(edtSpeed.Text, ',', '.', []), 1.0);
  
  lblStatus.Caption := 'Status: Configuration applied';
  AddLog('Configuration applied.');
end;

procedure TfrmMain.btnApplyConfigClick(Sender: TObject);
begin
  ApplyConfiguration;
  ShowMessage('Configuration applied to component properties.');
end;

procedure TfrmMain.btnTestConfigClick(Sender: TObject);
var
  LocalList: TStringList;
begin
  ApplyConfiguration;
  if FAIVoice.Engine = seOpenAI then
  begin
    if FAIVoice.ValidateOpenAIConfig('test') then
    begin
      ShowMessage('OpenAI configuration is valid.');
      AddLog('Test Configuration: OpenAI configuration is valid.');
    end
    else
    begin
      ShowMessage('OpenAI configuration is invalid: ' + FAIVoice.LastError);
      AddLog('Test Configuration: OpenAI validation failed: ' + FAIVoice.LastError);
    end;
  end
  else
  begin
    LocalList := TStringList.Create;
    try
      FAIVoice.GetAvailableVoices(LocalList);
      ShowMessage('Local voice configuration is valid. Available voices count: ' + IntToStr(LocalList.Count));
      AddLog('Test Configuration: Local voice configuration is valid. Voices count: ' + IntToStr(LocalList.Count));
    finally
      LocalList.Free;
    end;
  end;
end;

procedure TfrmMain.btnGenerateSpeechClick(Sender: TObject);
var
  TextToSpeak: string;
  FSize: Int64;
  F: TFileStream;
begin
  ApplyConfiguration;
  TextToSpeak := Trim(memoSpeechText.Text);
  if TextToSpeak = '' then
  begin
    ShowMessage('Text is empty.');
    Exit;
  end;

  lblStatus.Caption := 'Status: Generating speech...';
  btnGenerateSpeech.Enabled := False;
  AddLog('Starting real speech generation...');
  try
    FAIVoice.Say(TextToSpeak);
    
    if FAIVoice.LastSuccess then
    begin
      lblStatus.Caption := 'Status: Speech generated successfully';
      ShowMessage('Speech generated successfully.');
      AddLog('Speech generated successfully.');
      
      if FAIVoice.Engine = seOpenAI then
      begin
        edtGeneratedFile.Text := FAIVoice.OpenAIOutputFile;
        memoLastResult.Clear;
        memoLastResult.Lines.Add('Engine: OpenAI Voice API');
        memoLastResult.Lines.Add('Model: ' + FAIVoice.OpenAIModel);
        memoLastResult.Lines.Add('Voice: ' + FAIVoice.OpenAIVoice);
        memoLastResult.Lines.Add('Language: ' + FAIVoice.Language);
        memoLastResult.Lines.Add('Output format: ' + FAIVoice.OpenAIOutputFormat);
        memoLastResult.Lines.Add('Speed: ' + Format('%0.2f', [FAIVoice.Speed]));
        memoLastResult.Lines.Add('Generated file: ' + FAIVoice.OpenAIOutputFile);
        
        FSize := 0;
        if FileExists(FAIVoice.OpenAIOutputFile) then
        begin
          try
            F := TFileStream.Create(FAIVoice.OpenAIOutputFile, fmOpenRead or fmShareDenyNone);
            try
              FSize := F.Size;
            finally
              F.Free;
            end;
          except
          end;
        end;
        memoLastResult.Lines.Add('File size: ' + IntToStr(FSize) + ' bytes');
        AddLog('OpenAI Speech file generated: ' + FAIVoice.OpenAIOutputFile + ' (' + IntToStr(FSize) + ' bytes)');
      end
      else
      begin
        edtGeneratedFile.Text := '';
        memoLastResult.Clear;
        memoLastResult.Lines.Add('Engine: Local System Voice');
        memoLastResult.Lines.Add('Voice: ' + FAIVoice.VoiceName);
        memoLastResult.Lines.Add('Rate: ' + IntToStr(FAIVoice.Rate));
        memoLastResult.Lines.Add('Volume: ' + IntToStr(FAIVoice.Volume));
        memoLastResult.Lines.Add('Result: ' + FAIVoice.LastResult);
        AddLog('Local system voice synthesis output completed.');
      end;
      
      pgcMain.ActivePage := tsOutput;
    end
    else
    begin
      lblStatus.Caption := 'Status: Speech synthesis failed';
      AddLog('Speech synthesis failed: ' + FAIVoice.LastError);
      ShowMessage('Speech synthesis failed: ' + FAIVoice.LastError);
    end;
  finally
    btnGenerateSpeech.Enabled := True;
  end;
end;

procedure TfrmMain.btnClearTextClick(Sender: TObject);
begin
  memoSpeechText.Clear;
end;

procedure TfrmMain.btnLoadExampleClick(Sender: TObject);
const
  Examples: array[0..4] of string = (
    'Welcome to the Lazarus AI Voice Synthesizer demo using the OpenAI Voice API.',
    'This sample generates real speech audio using OpenAI text-to-speech models.',
    'Este exemplo gera áudio real em português do Brasil usando a API de voz da OpenAI.',
    'This voice demo supports local system voices and cloud-based OpenAI voices.',
    'Use this component to add spoken responses, alerts and accessibility features to Lazarus applications.'
  );
begin
  Inc(FExampleIndex);
  if FExampleIndex > 4 then
    FExampleIndex := 0;
    
  memoSpeechText.Text := Examples[FExampleIndex];
  AddLog('Loaded sample text index ' + IntToStr(FExampleIndex));
end;

procedure TfrmMain.PlayAudioFile(const AFileName: string);
begin
  if AFileName = '' then Exit;
  if not FileExists(AFileName) then
  begin
    ShowMessage('File does not exist: ' + AFileName);
    Exit;
  end;
  AddLog('Playing generated audio file: ' + AFileName);
  LCLIntf.OpenDocument(AFileName);
end;

procedure TfrmMain.btnPlayAudioClick(Sender: TObject);
begin
  if (edtGeneratedFile.Text = '') or not FileExists(edtGeneratedFile.Text) then
  begin
    ShowMessage('Generated audio file was not found.');
    Exit;
  end;
  PlayAudioFile(edtGeneratedFile.Text);
end;

procedure TfrmMain.btnOpenOutputFolderClick(Sender: TObject);
var
  Dir: string;
begin
  if edtGeneratedFile.Text = '' then
  begin
    ShowMessage('Generated audio file was not found.');
    Exit;
  end;
  Dir := ExtractFilePath(edtGeneratedFile.Text);
  if Dir = '' then
    Dir := GetCurrentDir;
  if not DirectoryExists(Dir) then
  begin
    ShowMessage('Generated audio file was not found.');
    Exit;
  end;
  AddLog('Opening folder: ' + Dir);
  LCLIntf.OpenDocument(Dir);
end;

procedure TfrmMain.btnCopyPathClick(Sender: TObject);
begin
  if edtGeneratedFile.Text <> '' then
  begin
    Clipboard.AsText := edtGeneratedFile.Text;
    ShowMessage('Generated file path copied to clipboard.');
    AddLog('Copied file path to clipboard.');
  end;
end;

procedure TfrmMain.btnClearLogClick(Sender: TObject);
begin
  memoLog.Clear;
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  memoLog.Lines.Add(FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) + ' - ' + AMsg);
end;

end.
