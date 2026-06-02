unit aivoicesynthesizer;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  {$IFDEF MSWINDOWS}
  ComObj, ActiveX, Variants,
  {$ENDIF}
  DynLibs, aibase, LResources;

type
  TSpeechEngine = (seSystemDefault, seSAPI, seEspeak);

  Pespeak_VOICE = ^Tespeak_VOICE;
  Tespeak_VOICE = record
    name       : PAnsiChar;
    languages  : PAnsiChar;
    identifier : PAnsiChar;
    gender     : Byte;
    age        : Byte;
    variant    : Byte;
    xx1        : Byte;
    score      : Integer;
    spare      : Pointer;
  end;
  PPespeak_VOICE = ^Pespeak_VOICE;

  { eSpeak C API function pointer signatures }
  Tespeak_Initialize = function(output: Integer; buf_length: Integer; path: PAnsiChar; options: Integer): Integer; cdecl;
  Tespeak_SetVoiceByName = function(name: PAnsiChar): Integer; cdecl;
  Tespeak_SetVolume = function(volume: Integer): Integer; cdecl;
  Tespeak_SetRate = function(rate: Integer): Integer; cdecl;
  Tespeak_Synth = function(text: PAnsiChar; size: SizeInt; position: Cardinal; position_type: Integer; end_position: Cardinal; flags: Cardinal; unique_identifier: PCardinal; user_data: Pointer): Integer; cdecl;
  Tespeak_Terminate = function: Integer; cdecl;
  Tespeak_ListVoices = function(voice_selector: Pointer): PPespeak_VOICE; cdecl;

  { TAIVoiceSynthesizer }

  TAIVoiceSynthesizer = class(TAIBaseComponent)
  private
    FText         : string;
    FVolume       : Integer;
    FRate         : Integer;
    FVoiceName    : string;
    FAsynchronous : Boolean;
    FEngine       : TSpeechEngine;

    {$IFDEF MSWINDOWS}
    FSpVoice      : OleVariant;
    FSpVoiceCreated: Boolean;
    {$ENDIF}

    // eSpeak dynamically loaded fields (both Windows and Linux)
    FLibHandle    : TLibHandle;
    FInitialized  : Boolean;

    espeak_Initialize     : Tespeak_Initialize;
    espeak_SetVoiceByName : Tespeak_SetVoiceByName;
    espeak_SetVolume      : Tespeak_SetVolume;
    espeak_SetRate        : Tespeak_SetRate;
    espeak_Synth          : Tespeak_Synth;
    espeak_Terminate      : Tespeak_Terminate;
    espeak_ListVoices     : Tespeak_ListVoices;

    function InitEspeak: Boolean;
    procedure UnloadEspeak;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Say(const AText: string = '');
    procedure GetAvailableVoices(AList: TStrings);

  published
    property Text: string read FText write FText;
    property Volume: Integer read FVolume write FVolume default 100;
    property Rate: Integer read FRate write FRate default 0; // SAPI: -10 to 10; eSpeak: scales mapped
    property VoiceName: string read FVoiceName write FVoiceName;
    property Asynchronous: Boolean read FAsynchronous write FAsynchronous default True;
    property Engine: TSpeechEngine read FEngine write FEngine default seSystemDefault;
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
  FPrompt := 'Component TAIVoiceSynthesizer is an AI text-to-speech component. Properties: Text, Volume, Rate, VoiceName, Asynchronous, Engine. Methods: Say(const AText), GetAvailableVoices(AList). AI Agent: Use this to speak responses, alerts or telemetry data to the user.';
  FText := '';
  FVolume := 100;
  FRate := 0;
  FVoiceName := '';
  FAsynchronous := True;
  FEngine := seSystemDefault;

  {$IFDEF MSWINDOWS}
  FSpVoiceCreated := False;
  {$ENDIF}

  FLibHandle := NilHandle;
  FInitialized := False;
  espeak_Initialize := nil;
  espeak_SetVoiceByName := nil;
  espeak_SetVolume := nil;
  espeak_SetRate := nil;
  espeak_Synth := nil;
  espeak_Terminate := nil;
  espeak_ListVoices := nil;
end;

destructor TAIVoiceSynthesizer.Destroy;
begin
  UnloadEspeak;
  {$IFDEF MSWINDOWS}
  if FSpVoiceCreated then
  begin
    try
      FSpVoice := Unassigned;
      ActiveX.CoUninitialize();
    except
    end;
  end;
  {$ENDIF}
  inherited Destroy;
end;

function TAIVoiceSynthesizer.InitEspeak: Boolean;
var
  Candidates: array[0..3] of string;
  I: Integer;
begin
  Result := False;
  if FInitialized then Exit(True);

  FLibHandle := NilHandle;

  {$IFDEF MSWINDOWS}
  Candidates[0] := 'libespeak-ng.dll';
  Candidates[1] := 'espeak.dll';
  Candidates[2] := 'libespeak.dll';
  Candidates[3] := 'espeak-ng.dll';
  {$ELSE}
  Candidates[0] := 'libespeak-ng.so.1';
  Candidates[1] := 'libespeak.so.1';
  Candidates[2] := 'libespeak-ng.so';
  Candidates[3] := 'libespeak.so';
  {$ENDIF}

  for I := 0 to 3 do
  begin
    FLibHandle := SafeLoadLibrary(Candidates[I]);
    if FLibHandle <> NilHandle then
      Break;
  end;

  if FLibHandle = NilHandle then
  begin
    SetError('Falha ao carregar biblioteca eSpeak. Certifique-se de que eSpeak/eSpeak-NG está instalado no sistema.');
    Exit;
  end;

  espeak_Initialize := Tespeak_Initialize(GetProcedureAddress(FLibHandle, 'espeak_Initialize'));
  espeak_SetVoiceByName := Tespeak_SetVoiceByName(GetProcedureAddress(FLibHandle, 'espeak_SetVoiceByName'));
  espeak_SetVolume := Tespeak_SetVolume(GetProcedureAddress(FLibHandle, 'espeak_SetVolume'));
  espeak_SetRate := Tespeak_SetRate(GetProcedureAddress(FLibHandle, 'espeak_SetRate'));
  espeak_Synth := Tespeak_Synth(GetProcedureAddress(FLibHandle, 'espeak_Synth'));
  espeak_Terminate := Tespeak_Terminate(GetProcedureAddress(FLibHandle, 'espeak_Terminate'));
  espeak_ListVoices := Tespeak_ListVoices(GetProcedureAddress(FLibHandle, 'espeak_ListVoices'));

  if not Assigned(espeak_Initialize) or not Assigned(espeak_Synth) then
  begin
    SetError('Funções essenciais do eSpeak não foram encontradas na biblioteca carregada.');
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
      SetError('Erro na inicialização do eSpeak: ' + E.Message);
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
  espeak_ListVoices := nil;
end;

procedure TAIVoiceSynthesizer.Say(const AText: string);
var
  SpeakText: string;
  {$IFDEF MSWINDOWS}
  Flags: Integer;
  {$ENDIF}
begin
  ClearError;
  if AText <> '' then
    FText := AText;

  SpeakText := FText;
  if SpeakText = '' then Exit;

  // Check if we use Windows SAPI
  if (FEngine = seSAPI) or ((FEngine = seSystemDefault) and
     {$IFDEF MSWINDOWS}True{$ELSE}False{$ENDIF}) then
  begin
    {$IFDEF MSWINDOWS}
    try
      if not FSpVoiceCreated then
      begin
        ActiveX.CoInitialize(nil);
        FSpVoice := CreateOleObject('SAPI.SpVoice');
        FSpVoiceCreated := True;
      end;
      
      // Set Volume (0 to 100)
      if FVolume < 0 then FVolume := 0;
      if FVolume > 100 then FVolume := 100;
      FSpVoice.Volume := FVolume;

      // Set Rate (-10 to 10)
      if FRate < -10 then FRate := -10;
      if FRate > 10 then FRate := 10;
      FSpVoice.Rate := FRate;

      // Set Voice by Name if specified
      if FVoiceName <> '' then
      begin
        try
          FSpVoice.Voice := FSpVoice.GetVoices('Name=' + FVoiceName).Item(0);
        except
          // Fallback to default
        end;
      end;

      // SVSFlagsAsync = 1, SVSFDefault = 0
      if FAsynchronous then
        Flags := 1
      else
        Flags := 0;

      FSpVoice.Speak(SpeakText, Flags);
      FLastResult := 'Speech synthesis completed (SAPI)';
      FLastSuccess := True;
    except
      on E: Exception do
        SetError('Exceção ao sintetizar voz via SAPI: ' + E.Message);
    end;
    {$ELSE}
    SetError('SAPI é suportado apenas no sistema operacional Windows.');
    {$ENDIF}
  end
  else
  begin
    // eSpeak implementation
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
        FLastResult := 'Speech synthesis completed (eSpeak)';
        FLastSuccess := True;
      except
        on E: Exception do
          SetError('Exceção ao sintetizar voz via eSpeak: ' + E.Message);
      end;
    end;
  end;
end;

procedure TAIVoiceSynthesizer.GetAvailableVoices(AList: TStrings);
var
  {$IFDEF MSWINDOWS}
  Voices: OleVariant;
  I: Integer;
  {$ENDIF}
  VoiceList: PPespeak_VOICE;
  VoicePtr: Pespeak_VOICE;
  Idx: Integer;
begin
  AList.Clear;
  ClearError;

  if (FEngine = seSAPI) or ((FEngine = seSystemDefault) and
     {$IFDEF MSWINDOWS}True{$ELSE}False{$ENDIF}) then
  begin
    {$IFDEF MSWINDOWS}
    try
      if not FSpVoiceCreated then
      begin
        ActiveX.CoInitialize(nil);
        FSpVoice := CreateOleObject('SAPI.SpVoice');
        FSpVoiceCreated := True;
      end;
      Voices := FSpVoice.GetVoices;
      for I := 0 to Voices.Count - 1 do
      begin
        try
          AList.Add(Voices.Item(I).GetAttribute('Name'));
        except
          try
            AList.Add(Voices.Item(I).GetDescription);
          except
          end;
        end;
      end;
      FLastResult := 'SAPI voices retrieved successfully';
      FLastSuccess := True;
    except
      on E: Exception do
        SetError('Exceção ao listar vozes via SAPI: ' + E.Message);
    end;
    {$ELSE}
    SetError('SAPI é suportado apenas no sistema operacional Windows.');
    {$ENDIF}
  end
  else
  begin
    // eSpeak
    if not FInitialized then
    begin
      if not InitEspeak then Exit;
    end;

    if FInitialized and Assigned(espeak_ListVoices) then
    begin
      try
        VoiceList := espeak_ListVoices(nil);
        if Assigned(VoiceList) then
        begin
          Idx := 0;
          while Assigned(VoiceList[Idx]) do
          begin
            VoicePtr := VoiceList[Idx];
            if Assigned(VoicePtr^.name) then
            begin
              AList.Add(string(VoicePtr^.name));
            end;
            Inc(Idx);
          end;
        end;
        FLastResult := 'eSpeak voices retrieved successfully';
        FLastSuccess := True;
      except
        on E: Exception do
          SetError('Exceção ao listar vozes via eSpeak: ' + E.Message);
      end;
    end;
  end;
end;

initialization
  {$I aivoicesynthesizer_icon.lrs}

end.
