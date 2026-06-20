unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, LCLIntf, Clipbrd, aibase, aivoicesynthesizer;

type

  { TfrmMain }

  TfrmMain = class(TForm)
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
    btnSpeak: TButton;
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
    procedure btnSpeakClick(Sender: TObject);
    procedure btnClearTextClick(Sender: TObject);
    procedure btnLoadExampleClick(Sender: TObject);
    procedure btnPlayAudioClick(Sender: TObject);
    procedure btnOpenOutputFolderClick(Sender: TObject);
    procedure btnCopyPathClick(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
  private
    FAIVoice: TAIVoiceSynthesizer;
    procedure AddLog(const AMsg: string);
    procedure ApplyConfiguration;
    procedure PlayAudioFile(const AFileName: string);
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

function ExtractLanguageCode(const ALangStr: string): string;
var
  P: Integer;
begin
  P := Pos(' - ', ALangStr);
  if P > 0 then
    Result := Copy(ALangStr, 1, P - 1)
  else
    Result := Trim(ALangStr);
end;

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  Randomize;
  FAIVoice := TAIVoiceSynthesizer.Create(Self);
  AddLog('Voice Synthesizer Complete Demo initialized.');
  
  // Set default sample speech text
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
  if cbSpeechEngine.ItemIndex = 0 then
    FAIVoice.Engine := seSystemDefault
  else
    FAIVoice.Engine := seOpenAI;

  FAIVoice.OpenAIToken := Trim(edtOpenAIToken.Text);
  FAIVoice.OpenAIModel := cbOpenAIModel.Text;
  FAIVoice.OpenAIVoice := cbOpenAIVoice.Text;
  FAIVoice.Language := ExtractLanguageCode(cbLanguage.Text);
  FAIVoice.OpenAIOutputFormat := cbOutputFormat.Text;
  FAIVoice.OpenAIOutputFile := edtOutputFile.Text;
  FAIVoice.Speed := StrToFloatDef(edtSpeed.Text, 1.0);
  
  AddLog('Configuration applied successfully.');
end;

procedure TfrmMain.btnApplyConfigClick(Sender: TObject);
begin
  ApplyConfiguration;
  ShowMessage('Configuration applied to component properties.');
end;

procedure TfrmMain.btnTestConfigClick(Sender: TObject);
begin
  ApplyConfiguration;
  if FAIVoice.Engine = seOpenAI then
  begin
    if FAIVoice.OpenAIToken = '' then
    begin
      ShowMessage('Error: API token is required for OpenAI Voice API.');
      AddLog('Error: OpenAI API token validation failed.');
    end
    else
    begin
      ShowMessage('OpenAI Voice API configured. Token entered (Length: ' + IntToStr(Length(FAIVoice.OpenAIToken)) + ').');
      AddLog('Test Configuration: OpenAI Voice API is configured.');
    end;
  end
  else
  begin
    ShowMessage('Local System Voice configured.');
    AddLog('Test Configuration: Local System Voice selected.');
  end;
end;

procedure TfrmMain.btnSpeakClick(Sender: TObject);
var
  TextToSpeak: string;
  FSize: Int64;
  F: TFileStream;
begin
  TextToSpeak := Trim(memoSpeechText.Text);
  if TextToSpeak = '' then
  begin
    ShowMessage('Text is empty.');
    Exit;
  end;

  AddLog('Starting speech generation...');
  try
    ApplyConfiguration;
    
    if FAIVoice.Engine = seOpenAI then
    begin
      if FAIVoice.OpenAIToken = '' then
      begin
        ShowMessage('API token is required for OpenAI Voice API.');
        AddLog('Error: OpenAI API token is empty.');
        Exit;
      end;
      if FAIVoice.OpenAIOutputFile = '' then
      begin
        ShowMessage('Output file is empty.');
        AddLog('Error: OpenAI output file path is empty.');
        Exit;
      end;
      
      AddLog('Synthesizing speech via OpenAI API...');
    end
    else
    begin
      AddLog('Synthesizing speech via Local System Voice...');
    end;
    
    FAIVoice.Say(TextToSpeak);
    
    if FAIVoice.LastSuccess then
    begin
      AddLog('Speech generated successfully.');
      
      if FAIVoice.Engine = seOpenAI then
      begin
        edtGeneratedFile.Text := FAIVoice.OpenAIOutputFile;
        memoLastResult.Clear;
        memoLastResult.Lines.Add('Model: ' + FAIVoice.OpenAIModel);
        memoLastResult.Lines.Add('Voice: ' + FAIVoice.OpenAIVoice);
        memoLastResult.Lines.Add('Language: ' + FAIVoice.Language);
        memoLastResult.Lines.Add('Output Format: ' + FAIVoice.OpenAIOutputFormat);
        
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
        memoLastResult.Lines.Add('File Size: ' + IntToStr(FSize) + ' bytes');
        memoLastResult.Lines.Add('Result Message: ' + FAIVoice.LastResult);
        
        AddLog('OpenAI Speech file saved to ' + FAIVoice.OpenAIOutputFile + ' (Size: ' + IntToStr(FSize) + ' bytes).');
        pgcMain.ActivePage := tsOutput;
      end;
    end
    else
    begin
      AddLog('Speech synthesis failed: ' + FAIVoice.LastError);
      ShowMessage('Speech synthesis failed: ' + FAIVoice.LastError);
    end;
  except
    on E: Exception do
    begin
      AddLog('Critical Error: ' + E.Message);
      ShowMessage('Critical Error: ' + E.Message);
    end;
  end;
end;

procedure TfrmMain.btnClearTextClick(Sender: TObject);
begin
  memoSpeechText.Clear;
end;

procedure TfrmMain.btnLoadExampleClick(Sender: TObject);
const
  Examples: array[0..3] of string = (
    'Welcome to the Lazarus AI Voice Synthesizer demo using the OpenAI Voice API.',
    'This sample generates real speech audio using OpenAI text-to-speech models.',
    'Este exemplo gera áudio real em português do Brasil usando a API de voz da OpenAI.',
    'This voice demo supports local system voices and cloud-based OpenAI voices.'
  );
var
  Idx: Integer;
begin
  Idx := Random(4);
  memoSpeechText.Text := Examples[Idx];
  AddLog('Loaded sample text index ' + IntToStr(Idx));
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
  PlayAudioFile(edtGeneratedFile.Text);
end;

procedure TfrmMain.btnOpenOutputFolderClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := ExtractFileDir(edtGeneratedFile.Text);
  if Dir = '' then
    Dir := GetCurrentDir;
  AddLog('Opening folder: ' + Dir);
  LCLIntf.OpenDocument(Dir);
end;

procedure TfrmMain.btnCopyPathClick(Sender: TObject);
begin
  if edtGeneratedFile.Text <> '' then
  begin
    Clipboard.AsText := edtGeneratedFile.Text;
    ShowMessage('File path copied to clipboard.');
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
