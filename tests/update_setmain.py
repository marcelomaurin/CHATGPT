import os

path = r'P:\maurinsoft\Assistente\src\setmain.pas'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Add fields before property declarations
fields_target = 'FKinectTargetCenter : string;'
fields_repl = '''FKinectTargetCenter : string;

        { Escuta Continua & VAD (TAIContinuousListener) }
        FContinuousListening : Boolean;
        FVoiceThreshold : Double;
        FSilenceTimeoutMs : Integer;
        FMinSpeechMs : Integer;
        FMaxSpeechMs : Integer;
        FEchoSuppressionEnabled : Boolean;
        FSelfAudioCorrelationThreshold : Double;

        { STT Separado }
        FSTTToken : String;
        FSTTModel : String;
        FSTTEndpoint : String;'''

if fields_target in text:
    text = text.replace(fields_target, fields_repl, 1)
    print('Added fields')

# 2. Add properties before end; of TSetMain
props_target = 'property KinectTargetCenter : string read FKinectTargetCenter write FKinectTargetCenter;'
props_repl = '''property KinectTargetCenter : string read FKinectTargetCenter write FKinectTargetCenter;

        { Escuta Continua & VAD }
        property ContinuousListening : Boolean read FContinuousListening write FContinuousListening;
        property VoiceThreshold : Double read FVoiceThreshold write FVoiceThreshold;
        property SilenceTimeoutMs : Integer read FSilenceTimeoutMs write FSilenceTimeoutMs;
        property MinSpeechMs : Integer read FMinSpeechMs write FMinSpeechMs;
        property MaxSpeechMs : Integer read FMaxSpeechMs write FMaxSpeechMs;
        property EchoSuppressionEnabled : Boolean read FEchoSuppressionEnabled write FEchoSuppressionEnabled;
        property SelfAudioCorrelationThreshold : Double read FSelfAudioCorrelationThreshold write FSelfAudioCorrelationThreshold;

        { STT }
        property STTToken : String read FSTTToken write FSTTToken;
        property STTModel : String read FSTTModel write FSTTModel;
        property STTEndpoint : String read FSTTEndpoint write FSTTEndpoint;'''

if props_target in text:
    text = text.replace(props_target, props_repl, 1)
    print('Added properties')

# 3. Add defaults in Default()
def_target = "FKinectTargetCenter := 'Robotinics';"
def_repl = '''FKinectTargetCenter := 'Robotinics';

    FContinuousListening := True;
    FVoiceThreshold := 0.015;
    FSilenceTimeoutMs := 900;
    FMinSpeechMs := 250;
    FMaxSpeechMs := 15000;
    FEchoSuppressionEnabled := True;
    FSelfAudioCorrelationThreshold := 0.70;
    FSTTToken := '';
    FSTTModel := 'whisper-1';
    FSTTEndpoint := 'https://api.openai.com/v1/audio/transcriptions';'''

if def_target in text:
    text = text.replace(def_target, def_repl, 1)
    print('Added defaults')

# 4. Add reading in CarregaContexto
read_target = '''    if  BuscaChave(arquivo,'AUDIOCHANNELS:',posicao) then
    begin
      FAudioChannels := strtointdef(RetiraInfo(arquivo.Strings[posicao]), 1);
    end;'''

read_repl = '''    if  BuscaChave(arquivo,'AUDIOCHANNELS:',posicao) then
    begin
      FAudioChannels := strtointdef(RetiraInfo(arquivo.Strings[posicao]), 1);
    end;

    if BuscaChave(arquivo,'CONTINUOUS_LISTENING:',posicao) then
      FContinuousListening := (RetiraInfo(arquivo.Strings[posicao]) <> '0');
    if BuscaChave(arquivo,'VOICE_THRESHOLD:',posicao) then
      FVoiceThreshold := strtofloatdef(StringReplace(RetiraInfo(arquivo.Strings[posicao]), ',', '.', []), 0.015);
    if BuscaChave(arquivo,'SILENCE_TIMEOUT_MS:',posicao) then
      FSilenceTimeoutMs := strtointdef(RetiraInfo(arquivo.Strings[posicao]), 900);
    if BuscaChave(arquivo,'MIN_SPEECH_MS:',posicao) then
      FMinSpeechMs := strtointdef(RetiraInfo(arquivo.Strings[posicao]), 250);
    if BuscaChave(arquivo,'MAX_SPEECH_MS:',posicao) then
      FMaxSpeechMs := strtointdef(RetiraInfo(arquivo.Strings[posicao]), 15000);
    if BuscaChave(arquivo,'ECHO_SUPPRESSION:',posicao) then
      FEchoSuppressionEnabled := (RetiraInfo(arquivo.Strings[posicao]) <> '0');
    if BuscaChave(arquivo,'SELF_AUDIO_CORR_THRESH:',posicao) then
      FSelfAudioCorrelationThreshold := strtofloatdef(StringReplace(RetiraInfo(arquivo.Strings[posicao]), ',', '.', []), 0.70);

    if BuscaChave(arquivo,'STT_TOKEN:',posicao) then
      FSTTToken := TVoiceCredentialStore.UnprotectToken(RetiraInfo(arquivo.Strings[posicao]));
    if BuscaChave(arquivo,'STT_MODEL:',posicao) then
      FSTTModel := RetiraInfo(arquivo.Strings[posicao]);
    if BuscaChave(arquivo,'STT_ENDPOINT:',posicao) then
      FSTTEndpoint := RetiraInfo(arquivo.Strings[posicao]);

    // Fallback: se STTToken vazio, reaproveita FCHATGPT
    if (Trim(FSTTToken) = '') and (Trim(FCHATGPT) <> '') then
      FSTTToken := FCHATGPT;'''

if read_target in text:
    text = text.replace(read_target, read_repl, 1)
    print('Added read params')

# 5. Add writing in SalvaContexto
write_target = "arquivo.Append('KINECT_TARGET_CENTER:'+FKinectTargetCenter);"
write_repl = '''arquivo.Append('KINECT_TARGET_CENTER:'+FKinectTargetCenter);

  arquivo.Append('CONTINUOUS_LISTENING:'+iif(FContinuousListening, '1', '0'));
  arquivo.Append('VOICE_THRESHOLD:'+FloatToStr(FVoiceThreshold));
  arquivo.Append('SILENCE_TIMEOUT_MS:'+inttostr(FSilenceTimeoutMs));
  arquivo.Append('MIN_SPEECH_MS:'+inttostr(FMinSpeechMs));
  arquivo.Append('MAX_SPEECH_MS:'+inttostr(FMaxSpeechMs));
  arquivo.Append('ECHO_SUPPRESSION:'+iif(FEchoSuppressionEnabled, '1', '0'));
  arquivo.Append('SELF_AUDIO_CORR_THRESH:'+FloatToStr(FSelfAudioCorrelationThreshold));

  arquivo.Append('STT_TOKEN:'+TVoiceCredentialStore.ProtectToken(FSTTToken));
  arquivo.Append('STT_MODEL:'+FSTTModel);
  arquivo.Append('STT_ENDPOINT:'+FSTTEndpoint);'''

if write_target in text:
    text = text.replace(write_target, write_repl, 1)
    print('Added save params')

with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
print('Updated setmain.pas successfully!')
