unit aispeechrecognizer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, aibase, aispeechtypes, aiaudio, LResources;

type
  TAISpeechRecognizer = class(TAIBaseComponent)
  private
    FLanguage: string;
    FModelPath: string;
    FUseGPU: Boolean;
    FThreads: Integer;
    FEngine: TComponent;
    FAudioInput: TAIAudioInput;
    FState: TAISpeechState;
    FLastText: string;
    FContinuous: Boolean;
    FChunkDurationSeconds: Integer;
    FListeningFile: string;
    FCancelled: Boolean;
    FOnStart: TNotifyEvent;
    FOnText: TAISpeechTextEvent;
    FOnPartialText: TAISpeechTextEvent;
    FOnError: TAISpeechErrorEvent;
    FOnFinish: TAISpeechFinishEvent;
    procedure SetEngine(AValue: TComponent);
    procedure SetAudioInput(AValue: TAIAudioInput);
    function GetBusy: Boolean;
    procedure Fail(const AMessage: string);
    function TranscribeOne(const AFileName: string; out AText: string): Boolean;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    function TranscribeFile(const AFileName: string): Boolean;
    function TranscribeFiles(AFiles: TStrings): Boolean;
    procedure Cancel;
    function StartListening(const AOutputWavFile: string = ''): Boolean;
    function StopListening: Boolean;
    function SplitWavIntoChunks(const AFileName: string; AChunkSeconds: Integer;
      AFiles: TStrings; out AError: string): Boolean;
    class function MergeTranscripts(const APrevious, ANext: string): string; static;
  published
    property Language: string read FLanguage write FLanguage;
    property ModelPath: string read FModelPath write FModelPath;
    property UseGPU: Boolean read FUseGPU write FUseGPU default False;
    property Threads: Integer read FThreads write FThreads default 0;
    property Engine: TComponent read FEngine write SetEngine;
    property AudioInput: TAIAudioInput read FAudioInput write SetAudioInput;
    property State: TAISpeechState read FState;
    property LastText: string read FLastText;
    property Busy: Boolean read GetBusy;
    property Continuous: Boolean read FContinuous write FContinuous default False;
    property ChunkDurationSeconds: Integer read FChunkDurationSeconds
      write FChunkDurationSeconds default 15;
    property OnStart: TNotifyEvent read FOnStart write FOnStart;
    property OnText: TAISpeechTextEvent read FOnText write FOnText;
    property OnPartialText: TAISpeechTextEvent read FOnPartialText write FOnPartialText;
    property OnError: TAISpeechErrorEvent read FOnError write FOnError;
    property OnFinish: TAISpeechFinishEvent read FOnFinish write FOnFinish;
  end;

procedure Register;

implementation

procedure Register;
begin RegisterComponents('AI Voice', [TAISpeechRecognizer]); end;

constructor TAISpeechRecognizer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FCategory := ccInput;
  FLanguage := 'pt';
  FUseGPU := False;
  FThreads := 0;
  FState := ssStopped;
  FContinuous := False;
  FChunkDurationSeconds := 15;
end;

procedure TAISpeechRecognizer.SetEngine(AValue: TComponent);
begin
  if FEngine = AValue then Exit;
  if Assigned(FEngine) then FEngine.RemoveFreeNotification(Self);
  FEngine := AValue;
  if Assigned(FEngine) then FEngine.FreeNotification(Self);
end;

procedure TAISpeechRecognizer.SetAudioInput(AValue: TAIAudioInput);
begin
  if FAudioInput = AValue then Exit;
  if Assigned(FAudioInput) then FAudioInput.RemoveFreeNotification(Self);
  FAudioInput := AValue;
  if Assigned(FAudioInput) then FAudioInput.FreeNotification(Self);
end;

procedure TAISpeechRecognizer.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited Notification(AComponent, Operation);
  if Operation = opRemove then
  begin
    if AComponent = FEngine then FEngine := nil;
    if AComponent = FAudioInput then FAudioInput := nil;
  end;
end;

function TAISpeechRecognizer.GetBusy: Boolean;
begin Result := FState in [ssListening, ssProcessing]; end;

procedure TAISpeechRecognizer.Fail(const AMessage: string);
begin
  FState := ssError;
  SetError(AMessage);
  if Assigned(FOnError) then FOnError(Self, AMessage);
end;

function TAISpeechRecognizer.TranscribeOne(const AFileName: string;
  out AText: string): Boolean;
var
  SpeechEngine: IAISpeechRecognitionEngine;
  Err: string;
begin
  Result := False;
  AText := '';
  if not FileExists(AFileName) then begin Fail('Arquivo de audio nao encontrado: ' + AFileName); Exit; end;
  if not Assigned(FEngine) or not Supports(FEngine,
    IAISpeechRecognitionEngine, SpeechEngine) then
  begin Fail('Engine de reconhecimento nao associado ou incompativel.'); Exit; end;
  if not SpeechEngine.LoadModel(FModelPath, FUseGPU, FThreads, Err) then
  begin Fail(Err); Exit; end;
  Result := SpeechEngine.TranscribeFile(AFileName, FLanguage, AText, Err);
  if not Result then Fail(Err);
end;

function TAISpeechRecognizer.TranscribeFile(const AFileName: string): Boolean;
var Text: string;
begin
  ClearError;
  FLastText := '';
  FCancelled := False;
  FState := ssProcessing;
  if Assigned(FOnStart) then FOnStart(Self);
  Result := TranscribeOne(AFileName, Text);
  if Result and not FCancelled then
  begin
    FLastText := Text;
    FLastResult := Text;
    FLastSuccess := True;
    FState := ssStopped;
    if Assigned(FOnText) then FOnText(Self, Text);
  end;
  if Assigned(FOnFinish) then FOnFinish(Self, Result and not FCancelled);
end;

class function TAISpeechRecognizer.MergeTranscripts(const APrevious,
  ANext: string): string;
var
  A, B: TStringList;
  Overlap, MaxOverlap, I: Integer;
begin
  if Trim(APrevious) = '' then Exit(Trim(ANext));
  if Trim(ANext) = '' then Exit(Trim(APrevious));
  A := TStringList.Create;
  B := TStringList.Create;
  try
    A.StrictDelimiter := True; A.Delimiter := ' '; A.DelimitedText := Trim(APrevious);
    B.StrictDelimiter := True; B.Delimiter := ' '; B.DelimitedText := Trim(ANext);
    MaxOverlap := Min(A.Count, B.Count);
    Overlap := 0;
    while MaxOverlap > 0 do
    begin
      for I := 0 to MaxOverlap - 1 do
        if not SameText(A[A.Count - MaxOverlap + I], B[I]) then Break;
      if I = MaxOverlap - 1 then begin Overlap := MaxOverlap; Break; end;
      Dec(MaxOverlap);
    end;
    Result := Trim(APrevious);
    for I := Overlap to B.Count - 1 do Result := Result + ' ' + B[I];
    Result := Trim(Result);
  finally B.Free; A.Free; end;
end;

function TAISpeechRecognizer.TranscribeFiles(AFiles: TStrings): Boolean;
var I: Integer; Text, Merged: string;
begin
  Result := False;
  ClearError;
  FCancelled := False;
  FLastText := '';
  FState := ssProcessing;
  if Assigned(FOnStart) then FOnStart(Self);
  if (AFiles = nil) or (AFiles.Count = 0) then
  begin Fail('Fila de blocos de audio vazia.'); if Assigned(FOnFinish) then FOnFinish(Self, False); Exit; end;
  Merged := '';
  for I := 0 to AFiles.Count - 1 do
  begin
    if FCancelled then Break;
    if not TranscribeOne(AFiles[I], Text) then Break;
    Merged := MergeTranscripts(Merged, Text);
    FLastText := Merged;
    if Assigned(FOnPartialText) then FOnPartialText(Self, Merged);
  end;
  Result := (not FCancelled) and (I = AFiles.Count - 1) and (FLastError = '');
  if Result then
  begin
    FState := ssStopped;
    FLastResult := FLastText;
    FLastSuccess := True;
    if Assigned(FOnText) then FOnText(Self, FLastText);
  end;
  if Assigned(FOnFinish) then FOnFinish(Self, Result);
end;

procedure TAISpeechRecognizer.Cancel;
var SpeechEngine: IAISpeechRecognitionEngine;
begin
  FCancelled := True;
  if Assigned(FEngine) and Supports(FEngine, IAISpeechRecognitionEngine,
    SpeechEngine) then SpeechEngine.Cancel;
  if Assigned(FAudioInput) and FAudioInput.Recording then FAudioInput.StopRecord;
  FState := ssStopped;
end;

function TAISpeechRecognizer.StartListening(const AOutputWavFile: string): Boolean;
begin
  ClearError;
  Result := False;
  if not Assigned(FAudioInput) then begin Fail('AudioInput nao associado.'); Exit; end;
  if Trim(AOutputWavFile) <> '' then FListeningFile := ExpandFileName(AOutputWavFile)
  else FListeningFile := IncludeTrailingPathDelimiter(GetTempDir) + 'lazarus_ai_speech.wav';
  ForceDirectories(ExtractFileDir(FListeningFile));
  Result := FAudioInput.StartRecord(FListeningFile);
  if Result then
  begin FState := ssListening; FCancelled := False; if Assigned(FOnStart) then FOnStart(Self); end
  else Fail(FAudioInput.LastError);
end;

function TAISpeechRecognizer.StopListening: Boolean;
var Files: TStringList; Err: string; I: Integer;
begin
  Result := False;
  if not Assigned(FAudioInput) then begin Fail('AudioInput nao associado.'); Exit; end;
  FAudioInput.StopRecord;
  if not FileExists(FListeningFile) then begin Fail('Captura nao gerou WAV: ' + FListeningFile); Exit; end;
  if not FContinuous then Exit(TranscribeFile(FListeningFile));
  Files := TStringList.Create;
  try
    if not SplitWavIntoChunks(FListeningFile, FChunkDurationSeconds, Files, Err) then
    begin Fail(Err); Exit; end;
    Result := TranscribeFiles(Files);
    for I := 0 to Files.Count - 1 do if FileExists(Files[I]) then DeleteFile(Files[I]);
  finally Files.Free; end;
end;

function TAISpeechRecognizer.SplitWavIntoChunks(const AFileName: string;
  AChunkSeconds: Integer; AFiles: TStrings; out AError: string): Boolean;
var
  Input, Output: TFileStream;
  Header: array[0..43] of Byte;
  Buffer: array[0..8191] of Byte;
  BytesPerSecond, ChunkBytes, Remaining, PartBytes, ReadNow: LongInt;
  RiffSize, DataSize: LongWord;
  Part, I: Integer;
  PartName: string;
begin
  Result := False; AError := '';
  if AFiles = nil then begin AError := 'Lista de chunks nula.'; Exit; end;
  AFiles.Clear;
  if AChunkSeconds <= 0 then begin AError := 'ChunkDurationSeconds deve ser maior que zero.'; Exit; end;
  if not FileExists(AFileName) then begin AError := 'WAV nao encontrado: ' + AFileName; Exit; end;
  Input := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    if Input.Size < 44 then begin AError := 'WAV menor que o cabecalho minimo.'; Exit; end;
    Input.ReadBuffer(Header, SizeOf(Header));
    if (PAnsiChar(@Header[0])^ <> 'R') or (PAnsiChar(@Header[8])^ <> 'W') then
    begin AError := 'Cabecalho WAV RIFF/WAVE invalido.'; Exit; end;
    Move(Header[28], BytesPerSecond, SizeOf(BytesPerSecond));
    if BytesPerSecond <= 0 then begin AError := 'WAV sem byte rate valido.'; Exit; end;
    ChunkBytes := BytesPerSecond * AChunkSeconds;
    Remaining := Input.Size - 44;
    Part := 0;
    while Remaining > 0 do
    begin
      Inc(Part);
      PartBytes := Min(Remaining, ChunkBytes);
      PartName := ChangeFileExt(AFileName, '') + Format('_part_%3.3d.wav', [Part]);
      Output := TFileStream.Create(PartName, fmCreate);
      try
        RiffSize := PartBytes + 36; DataSize := PartBytes;
        Move(RiffSize, Header[4], SizeOf(RiffSize));
        Move(DataSize, Header[40], SizeOf(DataSize));
        Output.WriteBuffer(Header, SizeOf(Header));
        I := PartBytes;
        while I > 0 do
        begin
          ReadNow := Input.Read(Buffer, Min(I, SizeOf(Buffer)));
          if ReadNow <= 0 then Break;
          Output.WriteBuffer(Buffer, ReadNow);
          Dec(I, ReadNow);
        end;
      finally Output.Free; end;
      AFiles.Add(PartName);
      Dec(Remaining, PartBytes);
    end;
    Result := AFiles.Count > 0;
  finally Input.Free; end;
end;

end.
