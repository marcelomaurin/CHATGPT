unit aivoicesynthesizer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  {$IFDEF MSWINDOWS}
  ComObj, ActiveX, Variants
  {$ELSE}
  DynLibs
  {$ENDIF};

type
  {$IFNDEF MSWINDOWS}
  { eSpeak C API function pointer signatures }
  Tespeak_Initialize = function(output: Integer; buf_length: Integer; path: PAnsiChar; options: Integer): Integer; cdecl;
  Tespeak_SetVoiceByName = function(name: PAnsiChar): Integer; cdecl;
  Tespeak_SetVolume = function(volume: Integer): Integer; cdecl;
  Tespeak_SetRate = function(rate: Integer): Integer; cdecl;
  Tespeak_Synth = function(text: PAnsiChar; size: SizeInt; position: Cardinal; position_type: Integer; end_position: Cardinal; flags: Cardinal; unique_identifier: PCardinal; user_data: Pointer): Integer; cdecl;
  Tespeak_Terminate = function: Integer; cdecl;
  {$ENDIF}

  { TAIVoiceSynthesizer }

  TAIVoiceSynthesizer = class(TComponent)
  private
    FText         : string;
    FVolume       : Integer;
    FRate         : Integer;
    FVoiceName    : string;
    FAsynchronous : Boolean;
    FLastError    : string;

    {$IFNDEF MSWINDOWS}
    FLibHandle    : TLibHandle;
    FInitialized  : Boolean;

    espeak_Initialize     : Tespeak_Initialize;
    espeak_SetVoiceByName : Tespeak_SetVoiceByName;
    espeak_SetVolume      : Tespeak_SetVolume;
    espeak_SetRate        : Tespeak_SetRate;
    espeak_Synth          : Tespeak_Synth;
    espeak_Terminate      : Tespeak_Terminate;

    function InitEspeak: Boolean;
    procedure UnloadEspeak;
    {$ENDIF}

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Say(const AText: string = '');

  published
    property Text: string read FText write FText;
    property Volume: Integer read FVolume write FVolume default 100;
    property Rate: Integer read FRate write FRate default 0; // Windows SAPI: -10 to 10; Linux maps -10..10 to 55..295 words/min
    property VoiceName: string read FVoiceName write FVoiceName;
    property Asynchronous: Boolean read FAsynchronous write FAsynchronous default True;
    property LastError: string read FLastError;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('IA Voice', [TAIVoiceSynthesizer]);
end;

{ TAIVoiceSynthesizer }

constructor TAIVoiceSynthesizer.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FText := '';
  FVolume := 100;
  FRate := 0;
  FVoiceName := '';
  FAsynchronous := True;
  FLastError := '';

  {$IFNDEF MSWINDOWS}
  FLibHandle := NilHandle;
  FInitialized := False;
  espeak_Initialize := nil;
  espeak_SetVoiceByName := nil;
  espeak_SetVolume := nil;
  espeak_SetRate := nil;
  espeak_Synth := nil;
  espeak_Terminate := nil;
  {$ENDIF}
end;

destructor TAIVoiceSynthesizer.Destroy;
begin
  {$IFNDEF MSWINDOWS}
  UnloadEspeak;
  {$ENDIF}
  inherited Destroy;
end;

{$IFNDEF MSWINDOWS}
function TAIVoiceSynthesizer.InitEspeak: Boolean;
var
  Candidates: array[0..3] of string;
  I: Integer;
begin
  Result := False;
  if FInitialized then Exit(True);

  FLibHandle := NilHandle;

  Candidates[0] := 'libespeak-ng.so.1';
  Candidates[1] := 'libespeak.so.1';
  Candidates[2] := 'libespeak-ng.so';
  Candidates[3] := 'libespeak.so';

  for I := 0 to 3 do
  begin
    FLibHandle := SafeLoadLibrary(Candidates[I]);
    if FLibHandle <> NilHandle then
      Break;
  end;

  if FLibHandle = NilHandle then
  begin
    FLastError := 'Falha ao carregar libespeak. Certifique-se de que espeak ou espeak-ng está instalado no sistema Linux.';
    Exit;
  end;

  espeak_Initialize := Tespeak_Initialize(GetProcedureAddress(FLibHandle, 'espeak_Initialize'));
  espeak_SetVoiceByName := Tespeak_SetVoiceByName(GetProcedureAddress(FLibHandle, 'espeak_SetVoiceByName'));
  espeak_SetVolume := Tespeak_SetVolume(GetProcedureAddress(FLibHandle, 'espeak_SetVolume'));
  espeak_SetRate := Tespeak_SetRate(GetProcedureAddress(FLibHandle, 'espeak_SetRate'));
  espeak_Synth := Tespeak_Synth(GetProcedureAddress(FLibHandle, 'espeak_Synth'));
  espeak_Terminate := Tespeak_Terminate(GetProcedureAddress(FLibHandle, 'espeak_Terminate'));

  if not Assigned(espeak_Initialize) or not Assigned(espeak_Synth) then
  begin
    FLastError := 'Funções essenciais do eSpeak não foram encontradas na biblioteca carregada.';
    FreeLibrary(FLibHandle);
    FLibHandle := NilHandle;
    Exit;
  end;

  try
    // AUDIO_OUTPUT_PLAYBACK = 0 (asynchronous)
    // AUDIO_OUTPUT_SYNCHRONOUS = 2 (synchronous)
    if FAsynchronous then
      espeak_Initialize(0, 0, nil, 0)
    else
      espeak_Initialize(2, 0, nil, 0);

    FInitialized := True;
    Result := True;
  except
    on E: Exception do
    begin
      FLastError := 'Erro na inicialização do eSpeak: ' + E.Message;
      FreeLibrary(FLibHandle);
      FLibHandle := NilHandle;
    end;
  end;
end;

procedure TAIVoiceSynthesizer.UnloadEspeak;
begin
  if FInitialized then
  begin
    if Assigned(espeak_Terminate) then
    begin
      try
        espeak_Terminate();
      except
      end;
    end;
    FInitialized := False;
  end;

  if FLibHandle <> NilHandle then
  begin
    FreeLibrary(FLibHandle);
    FLibHandle := NilHandle;
  end;

  espeak_Initialize := nil;
  espeak_SetVoiceByName := nil;
  espeak_SetVolume := nil;
  espeak_SetRate := nil;
  espeak_Synth := nil;
  espeak_Terminate := nil;
end;
{$ENDIF}

procedure TAIVoiceSynthesizer.Say(const AText: string);
var
  SpeakText: string;
  {$IFDEF MSWINDOWS}
  SpVoice: OleVariant;
  Flags: Integer;
  {$ENDIF}
begin
  if AText <> '' then
    FText := AText;

  SpeakText := FText;
  if SpeakText = '' then Exit;

  FLastError := '';

  {$IFDEF MSWINDOWS}
  try
    // SAPI instantiation
    ActiveX.CoInitialize(nil);
    SpVoice := CreateOleObject('SAPI.SpVoice');
    
    // Set Volume (0 to 100)
    if FVolume < 0 then FVolume := 0;
    if FVolume > 100 then FVolume := 100;
    SpVoice.Volume := FVolume;

    // Set Rate (-10 to 10)
    if FRate < -10 then FRate := -10;
    if FRate > 10 then FRate := 10;
    SpVoice.Rate := FRate;

    // Set Voice by Name if specified
    if FVoiceName <> '' then
    begin
      try
        SpVoice.Voice := SpVoice.GetVoices('Name=' + FVoiceName).Item(0);
      except
        // Ignore and fallback to default SAPI voice
      end;
    end;

    // SVSFlagsAsync = 1, SVSFDefault = 0
    if FAsynchronous then
      Flags := 1
    else
      Flags := 0;

    SpVoice.Speak(SpeakText, Flags);
  except
    on E: Exception do
      FLastError := 'Exceção ao sintetizar voz via SAPI: ' + E.Message;
  end;
  {$ELSE}
  // Linux eSpeak implementation
  if not FInitialized then
  begin
    if not InitEspeak then
      Exit;
  end;

  if FInitialized and Assigned(espeak_Synth) then
  begin
    try
      // Set Volume
      if FVolume < 0 then FVolume := 0;
      if FVolume > 100 then FVolume := 100;
      if Assigned(espeak_SetVolume) then
        espeak_SetVolume(FVolume);

      // Set Rate (Normal is 175 wpm. Map -10..10 to 55..295)
      if FRate < -10 then FRate := -10;
      if FRate > 10 then FRate := 10;
      if Assigned(espeak_SetRate) then
        espeak_SetRate(175 + (FRate * 12));

      // Set Voice by Name
      if (FVoiceName <> '') and Assigned(espeak_SetVoiceByName) then
        espeak_SetVoiceByName(PAnsiChar(AnsiString(FVoiceName)));

      // Call Synth (espeakCHARS_UTF8 = 1)
      espeak_Synth(PAnsiChar(AnsiString(SpeakText)), Length(SpeakText) + 1, 0, 0, 0, 1, nil, nil);
    except
      on E: Exception do
        FLastError := 'Exceção ao sintetizar voz via eSpeak: ' + E.Message;
    end;
  end;
  {$ENDIF}
end;

end.
