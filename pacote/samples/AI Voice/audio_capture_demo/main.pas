unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, DateUtils, Math, Forms, Controls, Graphics, Dialogs, ExtCtrls, StdCtrls,
  ComCtrls, LCLIntf,
  {$IFDEF MSWINDOWS}
  mmsystem,
  {$ENDIF}
  aibase, aiaudio;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblSubtitle: TLabel;
    pnlStatus: TPanel;
    lblStatus: TLabel;
    pcMain: TPageControl;
    
    // Configuration tab
    tsConfiguration: TTabSheet;
    lblInputSource: TLabel;
    cbInputSource: TComboBox;
    lblSampleRate: TLabel;
    cbSampleRate: TComboBox;
    lblChannels: TLabel;
    cbChannels: TComboBox;
    lblDurationLimit: TLabel;
    edtDurationLimit: TEdit;
    lblOutputFile: TLabel;
    edtOutputFile: TEdit;
    btnSelectOutputFile: TButton;
    btnApplyConfig: TButton;
    btnTestBackend: TButton;
    
    // Recording tab
    tsRecording: TTabSheet;
    btnStartRecording: TButton;
    btnStopRecording: TButton;
    btnPlayRecording: TButton;
    lblRecordingState: TLabel;
    lblElapsedTime: TLabel;
    pbRecordingTime: TProgressBar;
    memoRecordingInfo: TMemo;
    
    // Result tab
    tsResult: TTabSheet;
    lblGeneratedFile: TLabel;
    edtGeneratedFile: TEdit;
    lblValidationResultLabel: TLabel;
    lblValidationResult: TLabel;
    memoResult: TMemo;
    
    // Log tab
    tsLog: TTabSheet;
    memoLog: TMemo;
    btnClearLog: TButton;
    
    SaveDialog1: TSaveDialog;
    TimerRecording: TTimer;

    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnSelectOutputFileClick(Sender: TObject);
    procedure btnApplyConfigClick(Sender: TObject);
    procedure btnTestBackendClick(Sender: TObject);
    procedure btnStartRecordingClick(Sender: TObject);
    procedure btnStopRecordingClick(Sender: TObject);
    procedure btnPlayRecordingClick(Sender: TObject);
    procedure TimerRecordingTimer(Sender: TObject);
    procedure btnClearLogClick(Sender: TObject);
  private
    FAIAudio: TAIAudioInput;
    FRecordingStart: TDateTime;

    procedure AddLog(const AMsg: string);
    procedure ApplyConfiguration;
    procedure ValidateGeneratedFile;
    function GetOutputFileName: string;
  public

  end;

var
  frmMain: TfrmMain;

implementation

{$R *.lfm}

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  FAIAudio := TAIAudioInput.Create(Self);
  AddLog('Audio Capture Demo initialized.');
  lblStatus.Caption := 'Status: Ready';
  
  // Set initial default visual choices
  cbInputSource.ItemIndex := 0;
  cbSampleRate.ItemIndex := 1; // 16000
  cbChannels.ItemIndex := 0; // Mono
  edtDurationLimit.Text := '5';
  edtOutputFile.Text := 'output/voice_rec.wav';
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  // Handled by LCL Owner auto-free.
end;

procedure TfrmMain.btnSelectOutputFileClick(Sender: TObject);
begin
  if SaveDialog1.Execute then
  begin
    edtOutputFile.Text := SaveDialog1.FileName;
    AddLog('Output file selected: ' + edtOutputFile.Text);
  end;
end;

procedure TfrmMain.btnApplyConfigClick(Sender: TObject);
begin
  ApplyConfiguration;
  ShowMessage('Configuration applied.');
end;

procedure TfrmMain.ApplyConfiguration;
begin
  FAIAudio.InputSource := asMic;
  FAIAudio.SampleRate := StrToIntDef(cbSampleRate.Text, 16000);
  
  if Pos('2', cbChannels.Text) = 1 then
    FAIAudio.Channels := 2
  else
    FAIAudio.Channels := 1;

  FAIAudio.DurationLimit := StrToIntDef(edtDurationLimit.Text, 5);
  
  AddLog('Configuration applied:');
  AddLog('  Sample Rate: ' + IntToStr(FAIAudio.SampleRate) + ' Hz');
  AddLog('  Channels: ' + IntToStr(FAIAudio.Channels));
  AddLog('  Duration Limit: ' + IntToStr(FAIAudio.DurationLimit) + ' s');
  AddLog('  Output File: ' + edtOutputFile.Text);
end;

procedure TfrmMain.btnTestBackendClick(Sender: TObject);
{$IFDEF MSWINDOWS}
var
  MciError: Cardinal;
  Buffer: array[0..255] of Char;
begin
  AddLog('Audio backend test started.');
  MciError := mciSendString('open new type waveaudio alias testdevice', nil, 0, 0);
  if MciError = 0 then
  begin
    mciSendString('close testdevice', nil, 0, 0);
    AddLog('Audio backend: PASS - Windows MCI waveaudio is available.');
    ShowMessage('Audio backend: PASS - Windows MCI waveaudio is available.');
  end
  else
  begin
    mciGetErrorString(MciError, Buffer, SizeOf(Buffer));
    AddLog('Audio backend: FAIL - ' + string(Buffer));
    ShowMessage('Audio backend: FAIL - ' + string(Buffer));
  end;
end;
{$ELSE}
begin
  AddLog('Audio backend test started.');
  if (FileSearch('arecord', GetEnvironmentVariable('PATH')) <> '') or FileExists('arecord') then
  begin
    AddLog('Audio backend: PASS - ALSA arecord is available.');
    ShowMessage('Audio backend: PASS - ALSA arecord is available.');
  end
  else
  begin
    AddLog('Audio backend: FAIL - ALSA arecord was not found. Install alsa-utils.');
    ShowMessage('Audio backend: FAIL - ALSA arecord was not found. Install alsa-utils.');
  end;
end;
{$ENDIF}

procedure TfrmMain.btnStartRecordingClick(Sender: TObject);
var
  OutFile: string;
begin
  ApplyConfiguration;
  OutFile := GetOutputFileName;
  if OutFile = '' then
  begin
    ShowMessage('Output file is required.');
    Exit;
  end;

  memoResult.Clear;
  edtGeneratedFile.Clear;
  lblValidationResult.Caption := 'N/A';
  btnStartRecording.Enabled := False;
  btnStopRecording.Enabled := True;
  btnPlayRecording.Enabled := False;
  
  if not FAIAudio.StartRecord(OutFile) then
  begin
    ShowMessage('Failed to start recording: ' + FAIAudio.LastError);
    btnStartRecording.Enabled := True;
    btnStopRecording.Enabled := False;
    lblStatus.Caption := 'Status: Error';
    AddLog('Failed to start recording: ' + FAIAudio.LastError);
    Exit;
  end;

  FRecordingStart := Now;
  TimerRecording.Enabled := True;
  lblRecordingState.Caption := 'Recording state: recording';
  lblStatus.Caption := 'Status: Recording...';
  AddLog('Recording started. Output file: ' + OutFile);
  
  pbRecordingTime.Min := 0;
  if FAIAudio.DurationLimit > 0 then
    pbRecordingTime.Max := FAIAudio.DurationLimit * 2
  else
    pbRecordingTime.Max := 100;
  pbRecordingTime.Position := 0;
end;

procedure TfrmMain.btnStopRecordingClick(Sender: TObject);
begin
  FAIAudio.StopRecord;
  TimerRecording.Enabled := False;
  btnStartRecording.Enabled := True;
  btnStopRecording.Enabled := False;
  lblRecordingState.Caption := 'Recording state: stopped';
  lblStatus.Caption := 'Status: Completed Successfully';
  AddLog('Recording stopped.');

  ValidateGeneratedFile;
  pcMain.ActivePage := tsResult;
end;

procedure TfrmMain.ValidateGeneratedFile;
var
  OutFile, ErrMsg: string;
  IsValid: Boolean;
  Info: TStringList;
  FSize: Int64;
begin
  OutFile := GetOutputFileName;
  edtGeneratedFile.Text := OutFile;
  
  IsValid := FAIAudio.ValidateWavFile(OutFile, ErrMsg);
  
  Info := TStringList.Create;
  try
    Info.Add('Output file: ' + OutFile);
    if FileExists(OutFile) then
    begin
      Info.Add('File exists: yes');
      FSize := 0;
      try
        with TFileStream.Create(OutFile, fmOpenRead or fmShareDenyNone) do
        begin
          FSize := Size;
          Free;
        end;
      except
      end;
      Info.Add('File size: ' + IntToStr(FSize) + ' bytes');
    end
    else
    begin
      Info.Add('File exists: no');
      Info.Add('File size: 0 bytes');
    end;
    
    if IsValid then
    begin
      Info.Add('WAV header: valid');
      lblValidationResult.Caption := 'PASS - Real WAV file was created.';
      lblValidationResult.Font.Color := clGreen;
      btnPlayRecording.Enabled := True;
      AddLog('WAV validation passed.');
    end
    else
    begin
      Info.Add('WAV header: invalid (' + ErrMsg + ')');
      lblValidationResult.Caption := 'FAIL - ' + ErrMsg;
      lblValidationResult.Font.Color := clRed;
      btnPlayRecording.Enabled := False;
      AddLog('WAV validation failed: ' + ErrMsg);
    end;
    
    Info.Add('Sample rate: ' + IntToStr(FAIAudio.SampleRate) + ' Hz');
    Info.Add('Channels: ' + IntToStr(FAIAudio.Channels));
    Info.Add('Duration limit: ' + IntToStr(FAIAudio.DurationLimit) + ' seconds');
    
    memoResult.Text := Info.Text;
    memoRecordingInfo.Text := Info.Text;
  finally
    Info.Free;
  end;
end;

procedure TfrmMain.TimerRecordingTimer(Sender: TObject);
var
  ElapsedSecs: Integer;
  MinStr, SecStr: string;
begin
  ElapsedSecs := SecondsBetween(Now, FRecordingStart);
  
  MinStr := IntToStr(ElapsedSecs div 60);
  if Length(MinStr) < 2 then MinStr := '0' + MinStr;
  
  SecStr := IntToStr(ElapsedSecs mod 60);
  if Length(SecStr) < 2 then SecStr := '0' + SecStr;
  
  lblElapsedTime.Caption := 'Elapsed time: ' + MinStr + ':' + SecStr;
  
  if FAIAudio.DurationLimit > 0 then
  begin
    pbRecordingTime.Position := Min(pbRecordingTime.Max, ElapsedSecs * 2);
    if ElapsedSecs >= FAIAudio.DurationLimit then
    begin
      btnStopRecordingClick(nil);
    end;
  end
  else
  begin
    pbRecordingTime.Position := (pbRecordingTime.Position + 10) mod (pbRecordingTime.Max + 1);
  end;
end;

procedure TfrmMain.btnPlayRecordingClick(Sender: TObject);
begin
  if FileExists(edtOutputFile.Text) then
    OpenDocument(edtOutputFile.Text)
  else
    ShowMessage('Recorded WAV file was not found.');
end;

function TfrmMain.GetOutputFileName: string;
begin
  Result := Trim(edtOutputFile.Text);
end;

procedure TfrmMain.btnClearLogClick(Sender: TObject);
begin
  memoLog.Clear;
end;

procedure TfrmMain.AddLog(const AMsg: string);
begin
  memoLog.Lines.Add(FormatDateTime('hh:nn:ss', Now) + ' - ' + AMsg);
end;

end.
