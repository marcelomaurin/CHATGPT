program test_sip_voice_http;
{$mode objfpc}{$H+}
uses {$IFDEF UNIX}cthreads,{$ENDIF}
  SysUtils, aisip_types, aisipvoiceaudio, aisipvoicehttp;

procedure Require(Value: Boolean; const Message: string);
begin if not Value then raise Exception.Create(Message); end;

var B: TAISIPVoiceHTTPBackend; Samples: TAISIPAudioSamples;
    Base, Answer: string; Failed: Boolean;
begin
  Require(ParamCount = 1, 'Usage: test_sip_voice_http http://127.0.0.1:port');
  Base := ParamStr(1); B := TAISIPVoiceHTTPBackend.Create(nil);
  try
    B.STTURL := Base+'/stt'; B.ReplyURL := Base+'/ai'; B.TTSURL := Base+'/tts';
    B.AudioBaseURL := Base+'/audio/'; B.ReplyToken := 'fixture-token'; B.TimeoutMs := 2000;
    SetLength(Samples, 160); Samples[0] := -32768;
    Require(B.Transcribe(SIPVoiceWAV(Samples)) = 'fixture utterance', 'HTTP STT contract failed');
    Answer := B.Reply('session-fixture', 'fixture utterance', '[{"role":"assistant","content":"previous"}]');
    Require(Answer = 'fixture response', 'Casa reply contract failed');
    Samples := B.Synthesize(Answer);
    Require(Length(Samples) = 4000, 'TTS JSON/download/resampling contract failed');
    B.TTSURL := Base+'/tts-direct'; Samples := B.Synthesize(Answer);
    Require(Length(Samples) = 4000, 'Direct WAV response failed');
    B.ReplyFormat := vrOpenAICompatible; B.Model := 'fixture-model'; B.ReplyURL := Base+'/chat';
    Require(B.Reply('session-fixture', 'fixture utterance', '[]') = 'fixture response', 'Compatible chat failed');
    B.STTURL := Base+'/stt-stub'; Failed := False;
    try B.Transcribe(SIPVoiceWAV(Samples)); except on E: Exception do Failed := True; end;
    Require(Failed, 'Demonstration STT was accepted');
    B.STTURL := Base+'/unavailable'; Failed := False;
    try B.Transcribe(SIPVoiceWAV(Samples)); except on E: Exception do Failed := True; end;
    Require(Failed, 'HTTP service failure was accepted');
    B.ReplyURL := Base+'/redirect'; Failed := False;
    try B.Reply('fixture', 'fixture', '[]'); except on E: Exception do Failed := True; end;
    Require(Failed, 'HTTP redirect was followed');
    B.TTSURL := Base+'/tts-unsafe'; Failed := False;
    try B.Synthesize('fixture'); except on E: Exception do Failed := True; end;
    Require(Failed, 'Unsafe TTS filename was accepted');
    B.STTURL := Base+'/slow'; B.TimeoutMs := 100; Failed := False;
    try B.Transcribe(SIPVoiceWAV(Samples)); except on E: Exception do Failed := True; end;
    Require(Failed, 'HTTP deadline was not enforced');
    WriteLn('PASS: HTTP STT, Casa/chat history, WAV download/resampling, placeholder rejection, HTTP errors, redirects, unsafe filenames and timeout');
  finally B.Free; end;
end.
